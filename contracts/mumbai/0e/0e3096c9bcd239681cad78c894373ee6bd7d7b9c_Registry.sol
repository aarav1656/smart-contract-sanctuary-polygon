// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './CoreRegistry.sol';
import './PullPaymentConfig.sol';

/**
 * @title Registry - The core registry of pumapay ecosystem
 * @author The Pumapay Teams
 * @notice This core registry contains routes to varioud contracts of pumapay ecosystem.
 * @dev This Registry extends the features of core registry and pullpayment configs contracts.
 */
contract Registry is OwnableUpgradeable, CoreRegistry, PullPaymentConfig {
	/*
   	=======================================================================
   	======================== Constants ====================================
   	=======================================================================
 	*/
	bytes32 constant PMA_TOKEN_REGISTRY_ID = keccak256(abi.encodePacked('PMAToken'));
	bytes32 constant WBNB_TOKEN_REGISTRY_ID = keccak256(abi.encodePacked('WBNBToken'));
	bytes32 constant EXECUTOR_REGISTRY_ID = keccak256(abi.encodePacked('Executor'));
	bytes32 constant UNISWAP_FACTORY_REGISTRY_ID = keccak256(abi.encodePacked('UniswapFactory'));
	bytes32 constant UNISWAP_ROUTER_REGISTRY_ID = keccak256(abi.encodePacked('UniswapV2Router02'));
	bytes32 constant PULLPAYMENT_REGISTRY_ID = keccak256(abi.encodePacked('PullPaymentsRegistry'));
	bytes32 constant KEEPER_REGISTRY = keccak256(abi.encodePacked('KeeperRegistry'));
	bytes32 constant TOKEN_CONVERTER = keccak256(abi.encodePacked('TokenConverter'));

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @dev This initializes the core registry and the pullpayment contracts.
	 */
	function initialize(address _executionFeeReceiver, uint256 _executionFee)
		external
		virtual
		initializer
	{
		__Ownable_init();
		_init_coreRegistry();
		init_PullPaymentConfig(_executionFeeReceiver, _executionFee);
	}

	/*
   	=======================================================================
   	======================== Modifiers ====================================
 		=======================================================================
 	*/
	modifier onlyRegisteredContract(bytes32 identifierHash) {
		require(
			getAddressForOrDie(identifierHash) == msg.sender,
			'UsingRegistry: ONLY_REGISTERED_CONTRACT'
		);
		_;
	}

	modifier onlyRegisteredContracts(bytes32[] memory identifierHashes) {
		require(isOneOf(identifierHashes, msg.sender), 'UsingRegistry: ONLY_REGISTERED_CONTRACTS');
		_;
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice This method returns the address of the PMA token contract
	 */
	function getPMAToken() public view virtual returns (address) {
		return getAddressForOrDie(PMA_TOKEN_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the WBNB token contract
	 */
	function getWBNBToken() public view virtual returns (address) {
		return getAddressForOrDie(WBNB_TOKEN_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the Executor contract
	 */
	function getExecutor() public view virtual returns (address) {
		return getAddressForOrDie(EXECUTOR_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the uniswap/pancakeswap factory contract
	 */
	function getUniswapFactory() public view virtual returns (address) {
		return getAddressForOrDie(UNISWAP_FACTORY_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the uniswap/pancakeswap router contract
	 */
	function getUniswapRouter() public view virtual returns (address) {
		return getAddressForOrDie(UNISWAP_ROUTER_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the pullpayment registry contract
	 */
	function getPullPaymentRegistry() public view virtual returns (address) {
		return getAddressForOrDie(PULLPAYMENT_REGISTRY_ID);
	}

	/**
	 * @notice This method returns the address of the Keeper registry contract
	 */
	function getKeeperRegistry() public view virtual returns (address) {
		return getAddressForOrDie(KEEPER_REGISTRY);
	}

	/**
	 * @notice This method returns the address of the Token Converter contract
	 */
	function getTokenConverter() public view virtual returns (address) {
		return getAddressForOrDie(TOKEN_CONVERTER);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PullPaymentUtils - library for managing address arrays
 * @author The Pumapay Team
 */
library PullPaymentUtils {
	/**
	 * @notice This method allows admin to except the addresses to have multiple tokens of same NFT.
	 * @param _list 		- storage reference to address list
	 * @param _address 	- indicates the address to add.
	 */
	function addAddressInList(address[] storage _list, address _address) internal {
		require(_address != address(0), 'PullPaymentUtils: CANNOT_EXCEPT_ZERO_ADDRESS');

		(bool isExists, ) = isAddressExists(_list, _address);
		require(!isExists, 'PullPaymentUtils: ADDRESS_ALREADY_EXISTS');

		_list.push(_address);
	}

	/**
	 * @notice This method allows user to remove the particular address from the address list.
	 * @param _list 		- storage reference to address list
	 * @param _item 		- indicates the address to remove.
	 */
	function removeAddressFromList(address[] storage _list, address _item) internal {
		uint256 listItems = _list.length;
		require(listItems > 0, 'PullPaymentUtils: EMPTY_LIST');

		// check and remove if the last item is item to be removed.
		if (_list[listItems - 1] == _item) {
			_list.pop();
			return;
		}

		(bool isExists, uint256 index) = isAddressExists(_list, _item);
		require(isExists, 'PullPaymentUtils: ITEM_DOES_NOT_EXISTS');

		// move supported token to last
		if (listItems > 1) {
			address temp = _list[listItems - 1];
			_list[index] = temp;
		}

		//remove supported token
		_list.pop();
	}

	/**
	 * @notice This method allows to check if particular address exists in list or not
	 * @param _list - indicates list of addresses
	 * @param _item - indicates address to check in list
	 * @return isExists - returns true if item exists otherwise returns false. index - index of the existing item from the list.
	 */
	function isAddressExists(address[] storage _list, address _item)
		internal
		view
		returns (bool isExists, uint256 index)
	{
		for (uint256 i = 0; i < _list.length; i++) {
			if (_list[i] == _item) {
				isExists = true;
				index = i;
				break;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoreRegistry {
	function setAddressFor(string calldata, address) external;

	function getAddressForOrDie(bytes32) external view returns (address);

	function getAddressFor(bytes32) external view returns (address);

	function isOneOf(bytes32[] calldata, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './libraries/PullPaymentUtils.sol';

/**
 * @title PullPaymentConfig - contains all the configurations related with the pullpayments
 * @author The Pumapay Team
 * @notice This contracts contains configurations for the pullpayments i.e supported tokens, execution fee, execution fee receiver
 * @dev All the configurations can only be configured by owner only
 */
contract PullPaymentConfig is OwnableUpgradeable {
	/*
   	=======================================================================
   	======================== Public Variables ============================
   	=======================================================================
 	*/

	/// @notice Pullpayment Execution fee receiver address
	address public executionFeeReceiver;

	/// @notice Executopm fee percentage. 1 - 100%
	uint256 public executionFee;

	/// @notice list of supported tokens for pullPayments
	address[] public supportedTokens;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @param _executionFeeReceiver - indiactes the execution fee receiver address
	 * @param _executionFee 				- indicates the execution fee percentage. 1% - 99%
	 */
	function init_PullPaymentConfig(address _executionFeeReceiver, uint256 _executionFee)
		public
		virtual
		initializer
	{
		require(_executionFeeReceiver != address(0), 'PullPaymentConfig: INVALID_FEE_RECEIVER');

		__Ownable_init();

		updateExecutionFeeReceiver(_executionFeeReceiver);
		updateExecutionFee(_executionFee);
	}

	/*
   	=======================================================================
   	======================== Events =======================================
 	  =======================================================================
 	*/
	event SupportedTokenAdded(address indexed _token);
	event SupportedTokenRemoved(address indexed _token);
	event UpdatedExecutionFeeReceiver(address indexed _newReceiver);
	event UpdatedExecutionFee(uint256 indexed _newFee);

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @dev Add a token to the supported token list. only owner can add the supported token.
	 * @param _tokenAddress - The address of the token to add.
	 */
	function addToken(address _tokenAddress) external virtual onlyOwner {
		PullPaymentUtils.addAddressInList(supportedTokens, _tokenAddress);
		emit SupportedTokenAdded(_tokenAddress);
	}

	/**
	 * @dev Remove a token from the supported token list. only owner can remove the supported token.
	 * @param _tokenAddress - The address of the token to remove.
	 */
	function removeToken(address _tokenAddress) external virtual onlyOwner {
		PullPaymentUtils.removeAddressFromList(supportedTokens, _tokenAddress);
		emit SupportedTokenRemoved(_tokenAddress);
	}

	/**
	 * @dev This method allows owner to update the execution fee receiver address. only owner can update this address.
	 * @param _newReceiver - address of new execution fee receiver
	 */
	function updateExecutionFeeReceiver(address _newReceiver) public virtual onlyOwner {
		require(_newReceiver != address(0), 'PullPaymentConfig: INVALID_FEE_RECEIVER');
		executionFeeReceiver = _newReceiver;
		emit UpdatedExecutionFeeReceiver(_newReceiver);
	}

	/**
	 * @notice This method allows owner to update the execution fee. only owner can update execution fee.
	 * @param _newFee - new execution fee. 1% - 99%
	 */
	function updateExecutionFee(uint256 _newFee) public virtual onlyOwner {
		// 0 < 100
		require(_newFee < 10000, 'PullPaymentConfig: INVALID_FEE_PERCENTAGE');
		executionFee = _newFee;
		emit UpdatedExecutionFee(_newFee);
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Get the list of supported tokens
	 */
	function getSupportedTokens() external view virtual returns (address[] memory) {
		return supportedTokens;
	}

	/**
	 * @notice Checks if given token is supported token or not. returns true if supported otherwise returns false.
	 * @param _tokenAddress - ERC20 token address.
	 */
	function isSupportedToken(address _tokenAddress) external view virtual returns (bool isExists) {
		(isExists, ) = PullPaymentUtils.isAddressExists(supportedTokens, _tokenAddress);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './interfaces/ICoreRegistry.sol';

/**
 * @title Registry - Routes identifiers to addresses.
 * @author - The Pumapay Team
 * @notice The core registry which stores routes for contracts
 */
contract CoreRegistry is OwnableUpgradeable, ICoreRegistry {
	using SafeMathUpgradeable for uint256;

	/*
   	=======================================================================
   	======================== Public Variables ============================
   	=======================================================================
 	*/
	/// @notice encoded contract name => contract name
	mapping(bytes32 => address) public mainRegistry;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 */
	function _init_coreRegistry() internal virtual onlyInitializing {
		__Ownable_init();
	}

	/*
   	=======================================================================
   	======================== Events =======================================
 		=======================================================================
 	*/
	event RegistryUpdated(
		string indexed identifier,
		bytes32 indexed identifierHash,
		address indexed addr
	);

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @notice Associates the given address with the given identifier.
	 * @param identifier - Identifier of contract whose address we want to set.
	 * @param addr 			 - Address of contract.
	 */
	function setAddressFor(string calldata identifier, address addr)
		public
		virtual
		override
		onlyOwner
	{
		bytes32 identifierHash = keccak256(abi.encodePacked(identifier));
		mainRegistry[identifierHash] = addr;
		emit RegistryUpdated(identifier, identifierHash, addr);
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Gets address associated with the given identifierHash.
	 * @param identifierHash - Identifier hash of contract whose address we want to look up.
	 * @dev Throws if address not set.
	 */
	function getAddressForOrDie(bytes32 identifierHash)
		public
		view
		virtual
		override
		returns (address)
	{
		require(mainRegistry[identifierHash] != address(0), 'identifier has no registry entry');
		return mainRegistry[identifierHash];
	}

	/**
	 * @notice Gets address associated with the given identifierHash.
	 * @param identifierHash - Identifier hash of contract whose address we want to look up.
	 */
	function getAddressFor(bytes32 identifierHash) public view virtual override returns (address) {
		return mainRegistry[identifierHash];
	}

	/**
	 * @notice Gets address associated with the given identifier.
	 * @param identifier - Identifier of contract whose address we want to look up.
	 * @dev Throws if address not set.
	 */
	function getAddressForStringOrDie(string calldata identifier)
		public
		view
		virtual
		returns (address)
	{
		bytes32 identifierHash = keccak256(abi.encodePacked(identifier));
		require(mainRegistry[identifierHash] != address(0), 'identifier has no registry entry');
		return mainRegistry[identifierHash];
	}

	/**
	 * @notice Gets address associated with the given identifier.
	 * @param identifier - Identifier of contract whose address we want to look up.
	 */
	function getAddressForString(string calldata identifier) public view virtual returns (address) {
		bytes32 identifierHash = keccak256(abi.encodePacked(identifier));
		return mainRegistry[identifierHash];
	}

	/**
	 * @notice Iterates over provided array of identifiers, getting the address for each.
	 *         Returns true if `sender` matches the address of one of the provided identifiers.
	 * @param identifierHashes - Array of hashes of approved identifiers.
	 * @param sender -  Address in question to verify membership.
	 * @return True if `sender` corresponds to the address of any of `identifiers`
	 *         registry entries.
	 */
	function isOneOf(bytes32[] memory identifierHashes, address sender)
		public
		view
		virtual
		override
		returns (bool)
	{
		for (uint256 i = 0; i < identifierHashes.length; i = i.add(1)) {
			if (mainRegistry[identifierHashes[i]] == sender) {
				return true;
			}
		}
		return false;
	}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}