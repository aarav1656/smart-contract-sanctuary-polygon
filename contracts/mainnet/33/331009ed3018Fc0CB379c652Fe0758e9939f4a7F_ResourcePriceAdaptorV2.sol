// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import './ResourcePriceAdaptor.sol';
import '../proxy/AdminWrapper.sol';

/// @author Alexandas
/// @dev Resource price adaptor contract
contract ResourcePriceAdaptorV2 is ResourcePriceAdaptor, AdminWrapper {
	using SafeMathUpgradeable for uint256;

	/// @dev return current price index blocks
	mapping(address => mapping(ResourceData.ResourceType => uint256)) public indexBlocks;

	function fixPriceIndex(address provider, uint256 index, PriceAdaptor[] memory adaptors) external onlyAdmin {
		priceIndexBlocks[provider] = index;
		_setPriceAdaptors(provider, adaptors);
	}

	/// @dev update price adaptors
	/// @param adaptors price adaptors
	function setPriceAdaptors(PriceAdaptor[] memory adaptors) external onlyProvider {
		_setPriceAdaptors(msg.sender, adaptors);
	}

	function _setPriceAdaptors(address provider, PriceAdaptor[] memory adaptors) internal {
		require(adaptors.length > 0, 'ResourcePriceAdaptor: invalid pricers');
		for (uint256 i = 0; i < adaptors.length; i++) {
			uint256 price = adaptors[i].price;
			require(price > 0, 'ResourcePriceAdaptor: invalid price');
			ResourceData.ResourceType resourceType = adaptors[i].resourceType;
			require(resourceType != ResourceData.ResourceType.Null, 'ResourcePriceAdaptor: invalid resource type');
			prices[provider][resourceType][block.number] = price;
			indexBlocks[provider][resourceType] = block.number;
		}
		emit PriceAdaptorsUpdated(provider, adaptors);
	}

	/// @dev get price for resource at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param priceIndexBlock block number
	/// @return price for resource at a specific block
	function priceAt(address provider, ResourceData.ResourceType resourceType, uint256 priceIndexBlock) public view override ValidateType(resourceType) returns (uint256) {
		require(router.ProviderRegistry().isProvider(provider), 'ResourcePriceAdaptor: nonexistent provider');
		require(prices[provider][resourceType][priceIndexBlock] != 0, 'ResourcePriceAdaptor: zero price');
		return prices[provider][resourceType][priceIndexBlock];
	}

	/// @dev get value for `amount` resource at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @param priceIndexBlock block number
	/// @return token value in resource decimals(18)
	function getValueAt(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 amount,
		uint256 priceIndexBlock
	) public view override returns (uint256) {
		return priceAt(provider, resourceType, priceIndexBlock).mul(amount);
	}

	/// @dev get amount resource with value at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param value token value
	/// @param priceIndexBlock block numer
	/// @return resource amount
	function getAmountAt(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 value,
		uint256 priceIndexBlock
	) public view override returns (uint256) {
		return value.div(priceAt(provider, resourceType, priceIndexBlock));
	}

	/// @dev return resource price
	/// @param provider provider address
	/// @param resourceType resource type
	/// @return resource price
	function priceOf(address provider, ResourceData.ResourceType resourceType) public view override returns (uint256) {
		return priceAt(provider, resourceType, indexBlocks[provider][resourceType]);
	}

	/// @dev return value of amount resource
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @return token value in resource decimals(18)
	function getValueOf(address provider, ResourceData.ResourceType resourceType, uint256 amount) public view override returns (uint256) {
		return priceOf(provider, resourceType).mul(amount);
	}

	/// @dev return resource amount with value
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param value token value in resource decimals(18)
	/// @return resource amount
	function getAmountOf(address provider, ResourceData.ResourceType resourceType, uint256 value) public view override returns (uint256) {
		return value.div(priceOf(provider, resourceType));
	}

}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

import '../govers/RouterWrapper.sol';

/// @author Alexandas
/// @dev Resource price adaptor contract
abstract contract ResourcePriceAdaptor is IResourcePriceAdaptor, RouterWrapper, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	/// @dev return current price index blocks
	mapping(address => uint256) public priceIndexBlocks;

	/// @dev return all resource price
	mapping(address => mapping(ResourceData.ResourceType => mapping(uint256 => uint256))) internal prices;

	modifier ValidateType(ResourceData.ResourceType resourceType) {
		require(
			resourceType == ResourceData.ResourceType.BuildingTime ||
			resourceType == ResourceData.ResourceType.Bandwidth ||
			resourceType == ResourceData.ResourceType.ARStorage ||
			resourceType == ResourceData.ResourceType.IPFSStorage, 
			'ResourcePriceAdaptor: invalid resource type'
		);
		_;
	}

	constructor() initializer {}

	/// @dev proxy initialize function
	/// @param owner contract owner
	/// @param router router contract address
	function initialize(address owner, IRouter router) external initializer {
		_transferOwnership(owner);
		__Init_Router(router);
	}

	// /// @dev update price adaptors
	// /// @param adaptors price adaptors
	// function setPriceAdaptors(PriceAdaptor[] memory adaptors) external onlyProvider {
	// 	_setPriceAdaptors(msg.sender, adaptors);
	// 	_setPriceIndexBlock(msg.sender, block.number);
	// }

	// function _setPriceAdaptors(address provider, PriceAdaptor[] memory adaptors) internal {
	// 	require(adaptors.length > 0, 'ResourcePriceAdaptor: invalid pricers');
	// 	for (uint256 i = 0; i < adaptors.length; i++) {
	// 		uint256 price = adaptors[i].price;
	// 		require(price > 0, 'ResourcePriceAdaptor: invalid price');
	// 		ResourceData.ResourceType resourceType = adaptors[i].resourceType;
	// 		require(resourceType != ResourceData.ResourceType.Null, 'ResourcePriceAdaptor: invalid resource type');
	// 		prices[provider][resourceType][block.number] = price;
	// 	}
	// 	emit PriceAdaptorsUpdated(provider, adaptors);
	// }

	// function _setPriceIndexBlock(address provider, uint256 indexBlock) internal {
	// 	priceIndexBlocks[provider] = indexBlock;
	// 	emit PriceIndexBlockUpdated(provider, indexBlock);
	// }

	// /// @dev get price for resource at a specific block
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @param priceIndexBlock block number
	// /// @return price for resource at a specific block
	// function priceAt(address provider, ResourceData.ResourceType resourceType, uint256 priceIndexBlock) public view override ValidateType(resourceType) returns (uint256) {
	// 	require(router.ProviderRegistry().isProvider(provider), 'ResourcePriceAdaptor: nonexistent provider');
	// 	require(prices[provider][resourceType][priceIndexBlock] != 0, 'ResourcePriceAdaptor: zero price');
	// 	return prices[provider][resourceType][priceIndexBlock];
	// }

	// /// @dev get value for `amount` resource at a specific block
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @param amount resource amount
	// /// @param priceIndexBlock block number
	// /// @return token value in resource decimals(18)
	// function getValueAt(
	// 	address provider,
	// 	ResourceData.ResourceType resourceType,
	// 	uint256 amount,
	// 	uint256 priceIndexBlock
	// ) public view override returns (uint256) {
	// 	return priceAt(provider, resourceType, priceIndexBlock).mul(amount);
	// }

	// /// @dev get amount resource with value at a specific block
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @param value token value
	// /// @param priceIndexBlock block numer
	// /// @return resource amount
	// function getAmountAt(
	// 	address provider,
	// 	ResourceData.ResourceType resourceType,
	// 	uint256 value,
	// 	uint256 priceIndexBlock
	// ) public view override returns (uint256) {
	// 	return value.div(priceAt(provider, resourceType, priceIndexBlock));
	// }

	// /// @dev return resource price
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @return resource price
	// function priceOf(address provider, ResourceData.ResourceType resourceType) public view override returns (uint256) {
	// 	return priceAt(provider, resourceType, priceIndexBlocks[provider]);
	// }

	// /// @dev return value of amount resource
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @param amount resource amount
	// /// @return token value in resource decimals(18)
	// function getValueOf(address provider, ResourceData.ResourceType resourceType, uint256 amount) public view override returns (uint256) {
	// 	return priceOf(provider, resourceType).mul(amount);
	// }

	// /// @dev return resource amount with value
	// /// @param provider provider address
	// /// @param resourceType resource type
	// /// @param value token value in resource decimals(18)
	// /// @return resource amount
	// function getAmountOf(address provider, ResourceData.ResourceType resourceType, uint256 value) public view override returns (uint256) {
	// 	return value.div(priceOf(provider, resourceType));
	// }

}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/StorageSlot.sol';

/// @author Alexandas
/// @dev proxy admin wrapper
contract AdminWrapper {
	/// @dev return admin address from storage slot
	/// @return admin admin contract address
	function _getAdmin() internal view returns (address) {
		// bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1))
		bytes32 _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
		return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
	}

	modifier onlyAdmin() {
		require(msg.sender == _getAdmin(), 'AdminWrapper: caller is not the admin');
		_;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IRouter.sol';

/// @author Alexandas
/// @dev Router wrapper contract
abstract contract RouterWrapper is Initializable {
	/// @dev router contract address
	IRouter public router;

	/// @dev emit when provider registry contract updated
	/// @param router contract address
	event RouterUpdated(IRouter router);

	modifier onlyGovernance() {
		IGovernance governance = router.Governance();
		require(msg.sender == address(governance), 'RouterWrapper: caller is not the governance');
		_;
	}

	modifier onlyProviderController() {
		IProviderController controller = router.ProviderController();
		require(msg.sender == address(controller), 'RouterWrapper: caller is not the provider controller');
		_;
	}

	modifier onlyProvider() {
		IProviderRegistry providerRegistry = router.ProviderRegistry();
		require(providerRegistry.isProvider(msg.sender), 'RouterWrapper: caller is not the provider');
		_;
	}

	modifier onlyMessageReceiver() {
		address messageReceiver = router.MessageReceiver();
		require(msg.sender == messageReceiver, 'RouterWrapper: caller is not message receiver');
		_;
	}

	modifier onlyDstChainPayment() {
		IDstChainPayment dstChainPayment = router.DstChainPayment();
		require(msg.sender == address(dstChainPayment), 'RouterWrapper: caller is not dst chain payment');
		_;
	}

	modifier onlyFundPool() {
		IFundPool pool = router.FundPool();
		require(msg.sender == address(pool), 'RouterWrapper: caller is not fund pool');
		_;
	}

	/// @dev initialize provider registry contract
	/// @param _router contract address
	function __Init_Router(IRouter _router) internal onlyInitializing {
		_setRouter(_router);
	}

	function _setRouter(IRouter _router) internal {
		require(address(_router) != address(0), 'RouterWrapper: zero address');
		router = _router;
		emit RouterUpdated(_router);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';

import '../interfaces/IGovernance.sol';
import '../interfaces/IProviderRegistry.sol';
import '../interfaces/IProviderController.sol';
import '../interfaces/IDstChainPayment.sol';
import '../interfaces/IBilling.sol';
import '../interfaces/IFundPool.sol';
import '../resources/interfaces/INormalResourceController.sol';
import '../resources/interfaces/IIPFSStorageController.sol';
import '../resources/interfaces/IResourcePriceAdaptor.sol';

/// @author Alexandas
/// @dev Router interface
interface IRouter {
	/// @dev emit when governance contract address updated
	/// @param governance governance contract address
	event GovernanceUpdated(IGovernance governance);

	/// @dev emit when message receiver updated
	/// @param messageReceiver message receiver contract address
	event MessageReceiverUpdated(address messageReceiver);

	/// @dev emit when provider registry contract updated
	/// @param _providerRegistry provider registry contract
	event ProviderRegistryUpdated(IProviderRegistry _providerRegistry);

	/// @dev emit when dst ProviderController contract address updated
	/// @param providerController ProviderController contract address
	event ProviderControllerUpdated(IProviderController providerController);

	/// @dev emit when token updated
	/// @param token token address
	event TokenUpdated(IERC20Upgradeable token);

	/// @dev emit when building time controller updated
	/// @param buildingTimeController building time controller contract
	event BuildingTimeControllerUpdated(INormalResourceController buildingTimeController);

	/// @dev emit when bandwidth controller updated
	/// @param bandwidthController bandwidth controller contract
	event BandwidthControllerUpdated(INormalResourceController bandwidthController);

	/// @dev emit when AR storage controller updated
	/// @param arStorageController AR storage controller contract
	event ARStorageControllerUpdated(INormalResourceController arStorageController);

	/// @dev emit when ipfs storage controller updated
	/// @param ipfsStorageController IPFS storage controller contract
	event IPFSStorageControllerUpdated(IIPFSStorageController ipfsStorageController);

	/// @dev emit when resource price adaptor updated
	/// @param resourcePriceAdaptor resource price adaptor contract
	event ResourcePriceAdaptorUpdated(IResourcePriceAdaptor resourcePriceAdaptor);

	/// @dev emit when dst chain payment contract address updated
	/// @param dstChainPayment dst chain payment contract address
	event DstChainPaymentUpdated(IDstChainPayment dstChainPayment);

	/// @dev emit when billing contract updated
	/// @param billing billing contract
	event BillingUpdated(IBilling billing);

	/// @dev emit when fund pool contract updated
	/// @param fundPool fund pool contract
	event FundPoolUpdated(IFundPool fundPool);

	/// @dev message receiver contract address
	function MessageReceiver() external view returns (address);

	/// @dev Governance contract address
	function Governance() external view returns (IGovernance);

	/// @dev providers contract address
	function ProviderRegistry() external view returns (IProviderRegistry);

	/// @dev provider controller contract address
	function ProviderController() external view returns (IProviderController);

	/// @dev token address
	function Token() external view returns (IERC20Upgradeable);

	/// @dev return building time controller
	function BuildingTimeController() external view returns (INormalResourceController);

	/// @dev return bandwidth controller
	function BandwidthController() external view returns (INormalResourceController);

	/// @dev return AR storage controller
	function ARStorageController() external view returns (INormalResourceController);

	/// @dev return ipfs storage controller
	function IPFSStorageController() external view returns (IIPFSStorageController);

	/// @dev return resource price adaptor contract address
	function ResourcePriceAdaptor() external view returns (IResourcePriceAdaptor);

	/// @dev dst chain payment contract address
	function DstChainPayment() external view returns (IDstChainPayment);

	/// @dev billing contract address
	function Billing() external view returns (IBilling);

	/// @dev fund pool contract address
	function FundPool() external view returns (IFundPool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import './IProviderRegistry.sol';
import '../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev Governance interface
interface IGovernance {
	/// @dev emit when governance drip resource to provider
	/// @param provider provider address
	event GovernanceDrip(address provider);

	/// @dev add a provider
	/// @param provider address
	function addProvider(address provider) external;

	/// @dev remove a provider
	/// @param provider address
	function removeProvider(address provider) external;

	/// @dev drip resource to provider
	/// @param provider provider address
	/// @param payloads resource payloads
	function drip(address provider, ResourceData.AmountPayload[] memory payloads) external;
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev provider registry interface
interface IProviderRegistry {
	/// @dev emit when provider is added
	/// @param provider provider address
	event AddProvider(address provider);

	/// @dev emit when provider removed
	/// @param provider provider address
	event RemoveProvider(address provider);

	event AddProivderWallet(address provider, address wallet);

	event RemoveProviderWallet(address provider, address wallet);

	/// @dev add a provider
	/// @param provider address
	function addProvider(address provider) external;

	/// @dev remove a provider
	/// @param provider address
	function removeProvider(address provider) external;

	/// @dev return whether address is a provider
	/// @param provider address
	function isProvider(address provider) external view returns (bool);

	/// @dev return provider wallet
	/// @param provider address
	/// @return provider wallet
	function providerWallet(address provider) external view returns (address);

	/// @dev return provider wallet exists
	/// @param provider address
	/// @return whether provider wallet exists
	function providerWalletExists(address provider) external view returns (bool);

	/// @dev return whether a valid signature
	/// @param provider address
	/// @param hash message hash
	/// @param signature provider signature for message hash
	/// @return is valid signature
	function isValidSignature(
		address provider,
		bytes32 hash,
		bytes memory signature
	) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev provider controller interface
interface IProviderController {
	/// @dev emit when account registered in provider
	/// @param provider provider address
	/// @param account user account
	event AccountRegistered(address provider, bytes32 account);

	/// @dev emit when provider drip resource to account
	/// @param provider provider address
	/// @param account user account
	event ProviderDripped(address provider, bytes32 account);

	/// @dev emit when provider drip resource to account
	/// @param provider provider address
	/// @param account user account
	event ProviderDripped(address provider, bytes32 account, uint256 nonce);

	/// @dev emit when wallet types hash updated
	/// @param hash wallet types hash
	event WalletTypesHashUpdated(bytes32 hash);

	/// @dev emit when wallet transferred
	/// @param provider provider address
	/// @param account user account
	/// @param from original wallet address
	/// @param to new wallet address
	event WalletTransferred(address provider, bytes32 account, address from, address to);

	/// @dev keccak256("Wallet(address provider,bytes32 account,address wallet)")
	function walletTypesHash() external view returns (bytes32);

	/// @dev register account
	/// @param account user account
	function registerAccount(bytes32 account) external;

	/// @dev register multiple account
	/// @param accounts user accounts
	function registerMult(bytes32[] memory accounts) external;

	/// @dev Explain to a developer any extra details
	/// @param provider provider address
	/// @param account user account
	/// @return whether account exists
	function accountExists(address provider, bytes32 account) external view returns (bool);

	/// @dev provider drip resource to multiple accounts
	/// @param accounts user accounts
	/// @param payloads resource amount payloads
	function dripMult(
		bytes32[] memory accounts,
		ResourceData.AmountPayload[][] memory payloads
	) external;

	/// @dev provider drip resource to user account
	/// @param account user account
	/// @param payloads resource amount payloads
	function drip(
		bytes32 account,
		ResourceData.AmountPayload[] memory payloads
	) external;

	/// @dev provider register and drip resource for multiple accounts
	/// @param accounts user accounts
	/// @param payloads resource amount payloads
	function registerAndDripMult(
		bytes32[] memory accounts,
		ResourceData.AmountPayload[][] memory payloads
	) external;

	/// @dev initialize wallet for the given account
	/// @param provider provider address
	/// @param account user account
	/// @param wallet account wallet
	/// @param signature provider signature
	function initWallet(
		address provider,
		bytes32 account,
		address wallet,
		bytes memory signature
	) external;

	/// @dev initialize wallet for the given account called by fund pool
	/// @param provider provider address
	/// @param account user account
	/// @param wallet account wallet
	/// @param signature provider signature
	function poolInitWallet(
		address provider,
		bytes32 account,
		address wallet,
		bytes memory signature
	) external;

	/// @dev transfer wallet for the account
	/// @param provider provider address
	/// @param account user account
	/// @param newWallet account wallet
	function transferWallet(
		address provider,
		bytes32 account,
		address newWallet
	) external;

	/// @dev return wallet for the account
	/// @param provider provider address
	/// @param account user account
	/// @return wallet for the account
	function walletOf(address provider, bytes32 account) external view returns (address);

	/// @dev return whether wallet exists
	/// @param provider provider address
	/// @param account user account
	/// @return whether wallet exists
	function walletExists(address provider, bytes32 account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev DstChainPayment interface
interface IDstChainPayment {
	struct PaymentPayload {
		address provider;
		uint64 nonce;
		bytes32 account;
		ResourceData.ValuePayload[] payloads;
	}

	// event PaidV2(address provider, bytes32 account, ResourceData.ValuePayload[] payloads);

	event Paid(address provider, bytes32 account, ResourceData.ValuePayload[] payloads, uint256 value, uint256 nonce, uint256 amount);

	/// @dev pay from source chain only called by message receiver
	/// @param message payment payload message bytes
	function celerExec(bytes calldata message) external;

	/// @dev pay on dst chain
	/// @param provider provider address
	/// @param account user account
	/// @param payloads payment payloads
	/// @param nonce voucher nonce
	/// @param amount voucher amount
	/// @param signature vourcher signature for provider
	/// @return value total token value
	function pay(address provider, bytes32 account, ResourceData.ValuePayload[] memory payloads, uint256 nonce, uint256 amount, bytes memory signature) external returns(uint256 value);

	/// @dev calculate fee for ipfs storage and expiration
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	/// @param expiration ipfs expiration(in seconds)
	/// @return storageFee ipfs storage fee
	/// @return expirationFee ipfs expiration fee
	function ipfsAlloctionsFee(
		address provider,
		bytes32 account,
		uint256 amount,
		uint256 expiration
	) external view returns (uint256 storageFee, uint256 expirationFee);

	/// @dev calculate ipfs storage and expiration with storage fee and expiration fee
	/// @param provider provider address
	/// @param account user account
	/// @param storageFee storage fee
	/// @param expirationFee expiration fee
	/// @return amount ipfs storage amount
	/// @return expiration ipfs expiration(in seconds)
	function ipfsAllocations(
		address provider,
		bytes32 account,
		uint256 storageFee,
		uint256 expirationFee
	) external view returns (uint256 amount, uint256 expiration);

	/// @dev return balance of provider
	/// @param provider provider address
	/// @return balance of provider
	function balanceOf(address provider) external view returns (uint256);

	/// @dev return resource price
	/// @param provider provider address
	/// @param resourceType resource type
	/// @return resource price
	function priceOf(address provider, ResourceData.ResourceType resourceType) external view returns (uint256);

	/// @dev return value of amount resource
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @return token value
	function getValueOf(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 amount
	) external view returns (uint256);

	/// @dev return resource amount with value
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param value token value
	/// @return resource amount
	function getAmountOf(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 value
	) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '../libraries/ResourceData.sol';
import '../resources/interfaces/IResourcePriceAdaptor.sol';

/// @author Alexandas
/// @dev Billing interface
interface IBilling {
	struct BillEntry {
		ResourceData.ResourceType resourceType;
		uint256 amount;
	}

	struct Bill {
		uint256 indexBlock;
		BillEntry[] entries;
	}

	/// @dev emit when billing types hash updated
	/// @param hash billing types Hash
	event BillingTypesHashUpdated(bytes32 hash);

	/// @dev emit when bills finalized
	/// @param provider provider address
	/// @param account user account
	/// @param bills bills data
	/// @param amount fee
	/// @param nonce nonce
	event Billing(address provider, bytes32 account, bytes bills, uint256 amount, uint64 nonce);

	/// @dev get billing types hash
	/// @return billing types hash
	function billingTypesHash() external view returns (bytes32);

	/// @dev spend bills
	/// @param provider provider address
	/// @param account user account
	/// @param bills billing data
	/// @param timeout tx timeout
	/// @param nonce billing nonce
	/// @param signature billing signature
	/// @return fee billing fee
	function spend(
		address provider,
		bytes32 account,
		bytes memory bills,
		uint256 timeout,
		uint64 nonce,
		bytes memory signature
	) external returns (uint256 fee);

	/// @dev return balance of provider
	/// @param provider provider address
	/// @return balance of provider
	function balanceOf(address provider) external view returns (uint256);

	/// @dev provider nonces for account
	/// @param provider provider address
	/// @param account user account
	/// @param nonce nonce
	/// @return whether nonce exists
	function nonceExists(
		address provider,
		bytes32 account,
		uint64 nonce
	) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev FundPool interface
interface IFundPool {

	/// @dev emit when bill spent
	/// @param provider provider address
	/// @param account user account
	/// @param amount token amount
	event Spent(address provider, bytes32 account, uint256 amount);

	/// @dev emit when account recharged
	/// @param provider provider address
	/// @param account user account
	/// @param amount token amount
	event Recharged(address provider, bytes32 account, uint256 amount);

	/// @dev emit when user withdrawn
	/// @param provider provider address
	/// @param account user account
	/// @param to token receiver
	/// @param amount token amount
	event Withdrawn(address provider, bytes32 account, address to, uint256 amount);

	/// @dev recharge for account
	/// @param provider provider address
	/// @param account user account
	/// @param amount token amount
	function recharge(
		address provider,
		bytes32 account,
		uint256 amount
	) external;

	function celerExec(uint256 amount, bytes memory message) external;

	/// @dev initialize wallet and recharge for account
	/// @param provider provider address
	/// @param account user account
	/// @param walletSig wallet signature
	/// @param bills billing data
	/// @param timeout tx timeout
	/// @param nonce billing nonce
	/// @param billSig bill signature
	/// @return fee bill fee
	/// @param to token receiver
	/// @param amount token amount
	function initWalletAndWithdraw(
		address provider,
		bytes32 account,
		bytes memory walletSig,
		bytes memory bills,
		uint256 timeout,
		uint64 nonce,
		bytes memory billSig,
		address to,
		uint256 amount
	) external returns (uint256 fee);

	/// @dev spend bills for account
	/// @param provider provider address
	/// @param account user account
	/// @param bills billing data
	/// @param timeout tx timeout
	/// @param nonce billing nonce
	/// @param signature provider signature
	/// @return fee bills fee
	function spend(
		address provider,
		bytes32 account,
		bytes memory bills,
		uint256 timeout,
		uint64 nonce,
		bytes memory signature
	) external returns (uint256 fee);

	/// @dev withdraw token for account
	/// @param provider provider address
	/// @param account user account
	/// @param bills billing data
	/// @param timeout tx timeout
	/// @param nonce billing nonce
	/// @param signature billing signature
	/// @param to token receiver
	/// @param amount token amount
	/// @param signature provider signature
	/// @return fee bill fee
	function withdraw(
		address provider,
		bytes32 account,
		bytes memory bills,
		uint256 timeout,
		uint64 nonce,
		bytes memory signature,
		address to,
		uint256 amount
	) external returns (uint256 fee);

	/// @dev return wallet of the account
	/// @param provider provider address
	/// @param account user account
	/// @return wallet of the account
	function walletOf(address provider, bytes32 account) external view returns (address);

	/// @dev return balance of account
	/// @param provider provider address
	/// @param account user account
	/// @return balance of account account
	function balanceOf(address provider, bytes32 account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev normal resource controller interface
interface INormalResourceController {

	/// @dev emit when resource allocated for the provider
	/// @param provider provider address
	/// @param amount ipfs storage amount
	event ProviderAllocated(address provider, uint256 amount);

	/// @dev emit when resource allocated for the account
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	event AccountAllocated(address provider, bytes32 account, uint256 amount);

	/// @dev allocate resource for the provider
	/// @param provider provider address
	/// @param amount resource amount
	function allocateProvider(address provider, uint256 amount) external;

	/// @dev allocate user's resource balance
	/// @param provider provider address
	/// @param account user account
	/// @param amount resource amount
	function paymentAllocate(address provider, bytes32 account, uint256 amount) external;

	/// @dev provider drip resource to account directly
	/// @param provider provider address
	/// @param account user account
	/// @param amount resource amount
	function drip(address provider, bytes32 account, uint256 amount) external;

	/// @dev resource balance
	/// @param provider provider address
	/// @param account user account
	/// @return balance of the account
	function balanceOf(address provider, bytes32 account) external view returns (uint256);

	/// @dev resource balance
	/// @param provider provider address
	/// @return balance of the account
	function providerBalanceOf(address provider) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

/// @author Alexandas
/// @dev IPFS storage controller interface
interface IIPFSStorageController {
	struct Storage {
		uint256 startTime;
		uint256 expiration;
		uint256 amount;
	}

	/// @dev emit when ipfs storage allocated for the provider
	/// @param provider provider address
	/// @param amount ipfs storage amount
	/// @param expiration ipfs storage expiration
	event ProviderAllocated(address provider, uint256 amount, uint256 expiration);

	/// @dev emit when ipfs storage allocated for the account
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	/// @param expiration ipfs storage expiration
	event AccountAllocated(address provider, bytes32 account, uint256 amount, uint256 expiration);

	/// @dev emit when provider recovered ipfs storage
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	event ProviderRecovered(address provider, bytes32 account, uint256 amount);

	/// @dev allocate user's normal resource balance
	/// @param provider provider address
	/// @param amount resource amount
	/// @param expiration ipfs expiration
	function allocateProvider(address provider, uint256 amount, uint256 expiration) external;

	/// @dev provider drip resource to account directly
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	/// @param expiration ipfs expiration
	function drip(address provider, bytes32 account, uint256 amount, uint256 expiration) external;

	/// @dev allocate user's resource balance
	/// @param provider provider address
	/// @param account user account
	/// @param amount ipfs storage amount
	/// @param expiration ipfs expiration
	function paymentAllocate(address provider, bytes32 account, uint256 amount, uint256 expiration) external;

	/// @dev recover provider storage
	/// @param provider provider address
	/// @param account user account
	function recoverStorage(address provider, bytes32 account) external;

	/// @dev return whether ipfs storage is expired for the provider
	/// @param provider provider address
	/// @return whether ipfs storage is expired for the provider
	function isProviderExpired(address provider) external view returns (bool);

	/// @dev return ipfs storage start time for the provider
	/// @param provider provider address
	/// @return start time for the provider
	function providerStartTime(address provider) external view returns (uint256);

	/// @dev return total expiration time for the provider
	/// @param provider provider address
	/// @return total expiration time for the provider
	function providerExpiration(address provider) external view returns (uint256);

	/// @dev return available expiration time for the provider
	/// @param provider provider address
	/// @return available expiration time for the provider
	function providerAvailableExpiration(address provider) external view returns (uint256);

	/// @dev return when the provider will expire
	/// @param provider provider address
	/// @return when the provider will expire
	function providerExpiredAt(address provider) external view returns (uint256);

	/// @dev return ipfs storage amount for the provider
	/// @param provider provider address
	/// @return ipfs storage amount for the provider
	function providerBalanceOf(address provider) external view returns (uint256);

	/// @dev return whether ipfs storage is expired for the account
	/// @param provider provider address
	/// @param account user account
	/// @return whether ipfs storage is expired for the account
	function isExpired(address provider, bytes32 account) external view returns (bool);

	/// @dev return available expiration time for the account
	/// @param provider provider address
	/// @param account user account
	/// @return available expiration time for the account
	function availableExpiration(address provider, bytes32 account) external view returns (uint256);

	/// @dev return when the account will expire
	/// @param provider provider address
	/// @param account user account
	/// @return when the account will expire
	function expiredAt(address provider, bytes32 account) external view returns (uint256);

	/// @dev return ipfs storage start time for the account
	/// @param provider provider address
	/// @param account user account
	/// @return start time for the account
	function startTime(address provider, bytes32 account) external view returns (uint256);

	/// @dev return total expiration time for the account
	/// @param provider provider address
	/// @param account user account
	/// @return total expiration time for the account
	function expiration(address provider, bytes32 account) external view returns (uint256);

	/// @dev return ipfs storage amount for the account
	/// @param provider provider address
	/// @param account user account
	/// @return ipfs storage amount for the account
	function balanceOf(address provider, bytes32 account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev resource adpator interface
interface IResourcePriceAdaptor {
	struct PriceAdaptor {
		ResourceData.ResourceType resourceType;
		uint256 price;
	}

	/// @dev emit when index block updated
	/// @param provider provider address
	/// @param priceIndexBlock price index block
	event PriceIndexBlockUpdated(address provider, uint256 priceIndexBlock);

	/// @dev emit when price updated
	/// @param provider provider address
	/// @param adaptors price adaptors
	event PriceAdaptorsUpdated(address provider, PriceAdaptor[] adaptors);

	/// @dev get price for resource at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param priceIndexBlock block number
	/// @return price for resource at a specific block
	function priceAt(address provider, ResourceData.ResourceType resourceType, uint256 priceIndexBlock) external view returns (uint256);

	/// @dev get value for `amount` resource at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @param priceIndexBlock block number
	/// @return token value in resource decimals(18)
	function getValueAt(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 amount,
		uint256 priceIndexBlock
	) external view returns (uint256);

	/// @dev get amount resource with value at a specific block
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param value token value
	/// @param priceIndexBlock block numer
	/// @return resource amount
	function getAmountAt(
		address provider,
		ResourceData.ResourceType resourceType,
		uint256 value,
		uint256 priceIndexBlock
	) external view returns (uint256);

	/// @dev return resource price
	/// @param provider provider address
	/// @param resourceType resource type
	/// @return resource price
	function priceOf(address provider, ResourceData.ResourceType resourceType) external view returns (uint256);

	/// @dev return value of amount resource
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @return token value in resource decimals(18)
	function getValueOf(address provider, ResourceData.ResourceType resourceType, uint256 amount) external view returns (uint256);

	/// @dev return resource amount with value
	/// @param provider provider address
	/// @param resourceType resource type
	/// @param value token value in resource decimals(18)
	/// @return resource amount
	function getAmountOf(address provider, ResourceData.ResourceType resourceType, uint256 value) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';

/// @author Alexandas
/// @dev resource data library
library ResourceData {
	using SafeMathUpgradeable for uint256;

	enum ResourceType {
		Null,
		BuildingTime,
		Bandwidth,
		ARStorage,
		IPFSStorage
	}

	struct ValuePayload {
		ResourceData.ResourceType resourceType;
		uint256[] values;
	}

	struct AmountPayload {
		ResourceData.ResourceType resourceType;
		uint256[] amounts;
	}

	struct ValuePayloads {
		ResourceData.ValuePayload[] payloads;
	}

	function convertSourceChainPayloads(ValuePayloads memory valuePayloads, uint256 dstAmount)
		internal
		pure
		returns (ResourceData.ValuePayload[] memory newPayloads)
	{
		ResourceData.ValuePayload[] memory payloads = valuePayloads.payloads;
		require(payloads.length > 0, 'ResourceData: invalid payload length');
		uint256 total = totalValue(payloads);
		require(total > 0, 'ResourceData: zero total value');
		for (uint256 i = 0; i < payloads.length; i++) {
			require(payloads[i].values.length > 0, 'ResourceData: invalid value length');
			for (uint256 j = 0; j < payloads[i].values.length; j++) {
				payloads[i].values[j] = payloads[i].values[j].mul(dstAmount).div(total);
			}
		}
		return payloads;
	}

	/// @dev payment payload total value
	/// @param payloads payment payloads
	/// @return value total value
	function totalValue(ResourceData.ValuePayload[] memory payloads) internal pure returns (uint256 value) {
		require(payloads.length > 0, 'ResourceData: invalid payloads length');
		for (uint256 i = 0; i < payloads.length; i++) {
			for (uint256 j = 0; j < payloads[i].values.length; j++) {
				value = value.add(payloads[i].values[j]);
			}
		}
	}

	/// @dev match token amount to resource decimals
	/// @param token token contract address
	/// @param value token amount with resource decimals
	/// @return resource value
	function matchTokenToResource(IERC20Upgradeable token, uint256 value) internal view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals(token);
		uint256 _resourceDecimals = decimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.mul(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.div(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev match value to token decimals
	/// @param token token contract address
	/// @param value resource value
	/// @return token value
	function matchResourceToToken(IERC20Upgradeable token, uint256 value) internal view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals(token);
		uint256 _resourceDecimals = decimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.div(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.mul(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev return resource decimals
	/// @return resource decimals
	function decimals() internal pure returns (uint256) {
		return 18;
	}

	/// @dev return token decimals
	/// @return token decimals
	function tokenDecimals(IERC20Upgradeable token) internal view returns (uint256) {
		// keccak256(bytes4('decimals()'))
		(bool success, bytes memory data) = address(token).staticcall(hex'313ce567');
		require(success, 'ResourceData: invalid token');
		return abi.decode(data, (uint256));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}