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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        address owner;
        Modules modules;
        BadgePair delegateBadge;
        BadgePair maintainerBadge;
        BadgePair reputationBadge;
        ReputationParams reputationParams;
    }

    struct ReputationParams {
        uint256 rewardPool;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        uint256 submissionCount;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function setConfiguration(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface ReputationModuleInterface {
    struct MarketReputationConfig {
        address reputationToken;
        uint256 reputationTokenId;
    }

    struct DecayConfig {
        uint256 decayRate;
        uint256 decayInterval;
        uint256 decayStartEpoch;
    }

    struct ReputationAccountInfo {
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        external;
        
    function useReputation(
          address _account
        , uint256 _amount
    )
        external;

    function mintReputation(
          address _account
        , uint256 _amount
    )
        external;

    function freezeReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external; 


    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getMarketReputationConfig(
        address _laborMarket
    )
        external
        view
        returns (
            MarketReputationConfig memory
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketFactoryInterface } from "./interfaces/LaborMarketFactoryInterface.sol";
import { LaborMarketVersions } from "./LaborMarketVersions.sol";
import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";

/// @dev Helpers.
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";

contract LaborMarketFactory is
      LaborMarketFactoryInterface
    , LaborMarketVersions
{
    constructor(
          address _implementation
        , BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    ) 
        LaborMarketVersions(
              _implementation
            , _governorBadge
            , _creatorBadge
        )
    {}

    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket( 
          address _implementation
        , LaborMarketConfiguration calldata _configuration
    )
        override
        public
        virtual
        returns (
            address laborMarketAddress
        )
    {
        /// @dev MVP only allows creators to deploy new Labor Markets.
        require(
            _isCreator(_msgSender()),
            "LaborMarketFactory: Only creators can deploy new Labor Markets."
        );

        /// @dev Load the version.
        Version memory version = versions[_implementation];

        /// @dev Get the users license key to determine how much funding has been provided.
        /// @notice Can deploy for someone but must have the cost covered themselves.
        bytes32 licenseKey = getLicenseKey(
              version.licenseKey
            , _msgSender()
        );

        /// @dev Deploy the Labor Market contract for the deployer chosen.
        laborMarketAddress = _createLaborMarket(
              _implementation
            , licenseKey
            , version.amount
            , _configuration
        );
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Funds a new Labor Market when the license model is enabled and 
     *         the user has transfered their license to this contract. The license, is a 
     *         lifetime license.
     * @param _from The address of the account who owns the created Labor Market.
     * @return Selector response of the license token successful transfer.
     */
    function onERC1155Received(
          address 
        , address _from
        , uint256 _id
        , uint256 _amount
        , bytes memory _data
    ) 
        override 
        public 
        returns (
            bytes4
        ) 
    {
        /// @dev Return the typical ERC-1155 response if transfer is not intended to be a payment.
        if(bytes(_data).length == 0) {
            return this.onERC1155Received.selector;
        }
        
        /// @dev Recover the implementation address from `_data`.
        address implementation = abi.decode(
              _data
            , (address)
        );

        /// @dev Confirm that the token being transferred is the one expected.
        require(
              keccak256(
                  abi.encodePacked(
                        _msgSender()
                      , _id 
                  )
              ) == versions[implementation].licenseKey
            , "LaborMarketFactory::onERC1155Received: Invalid license key."
        );

        /// @dev Get the version license key to track the funding of the msg sender.
        bytes32 licenseKey = getLicenseKey(
              versions[implementation].licenseKey
            , _from
        );

        /// @dev Fund the deployment of the Labor Market contract to 
        ///      the account covering the cost of the payment (not the transaction sender).
        versionKeyToFunded[licenseKey] += _amount;

        /// @dev Return the ERC1155 success response.
        return this.onERC1155Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL PROTOCOL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows protocol Governors to execute protocol level transaction.
     * @dev This enables the ability to execute pre-built transfers without having to 
     *      explicitly define what tokens this contract can receive.
     * @param _to The address to execute the transaction on.
     * @param _data The data to pass to the receiver.
     * @param _value The amount of ETH to send with the transaction.
     * Requirements:
     * - Only protocol Governors can call this.
     */
    function execTransaction(
          address _to
        , bytes calldata _data
        , uint256 _value
    )
        external
        virtual
        payable
    {
        /// @dev Only allow protocol Governors to execute protocol level transactions.
        require(
            _isGovernor(_msgSender()),
            "LaborMarketFactory: Only Governors can call this."   
        );

        /// @dev Make the call.
        (
              bool success
            , bytes memory returnData
        ) = _to.call{value: _value}(_data);

        /// @dev Force that the transfer/transaction emits a successful response. 
        require(
              success
            , string(returnData)
        );
    }

    /**
     * @notice Signals to external callers that this is a Badger contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) 
        override
        public
        view
        returns (
            bool
        ) 
    {
        return (
               _interfaceId == type(LaborMarketFactoryInterface).interfaceId
            || super.supportsInterface(_interfaceId)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";
import { LaborMarketFactory } from "./LaborMarketFactory.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is
    LaborMarketNetworkInterface,
    LaborMarketFactory
{
    constructor(
          address _factoryImplementation
        , address _capacityImplementation
        , BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    ) 
        LaborMarketFactory(
              _factoryImplementation
            , _governorBadge
            , _creatorBadge
        ) 
    {
        capacityToken = IERC20(_capacityImplementation);
    }

    /**
     * @notice Allows the owner to set the Governor Badge.
     * @dev This is used to gate the ability to create and update Labor Markets.
     * @param _governorBadge The address and tokenId of the GovernorBadge.
     * @param _creatorBadge The address and tokenId of the CreatorBadge.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setNetworkRoles(
          BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    ) 
        external
        virtual
        override
        onlyOwner
    {
        _setNetworkRoles(_governorBadge, _creatorBadge);
    }

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setCapacityImplementation(address _implementation)
        external
        virtual
        override
    {
        require(
            _isGovernor(_msgSender()),
            "LaborMarketNetwork: Only a Governor can call this."
        );
        
        capacityToken = IERC20(_implementation);
    }

    /**
     * @notice Sets the reputation decay configuration for a token.
     * @param _reputationModule The address of the Reputation Module.
     * @param _reputationToken The address of the Reputation Token.
     * @param _reputationTokenId The token ID of the Reputation Token.
     * @param _decayRate The rate of decay.
     * @param _decayInterval The interval of decay.
     * @param _decayStartEpoch The epoch to start the decay.
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external
        virtual
        override
    {
        require(
            _isGovernor(_msgSender()), 
            "LaborMarketNetwork: Only a Governor can call this."
        );

        _setReputationDecay(
              _reputationModule
            , _reputationToken
            , _reputationTokenId
            , _decayRate
            , _decayInterval
            , _decayStartEpoch
        );
    }

    /**
     * @notice Checks if the sender is a Governor.
     * @param _sender The message sender address.
     * @return True if the sender is a Governor.
     */
    function isGovernor(address _sender)
        external
        view
        virtual
        override
        returns (
            bool
        )
    {
        return _isGovernor(_sender);
    }

    /**
     * @notice Checks if the sender is a Creator.
     * @param _sender The message sender address.
     * @return True if the sender is a Creator.
     */
    function isCreator(address _sender)
        external
        view
        virtual
        override
        returns (
            bool
        )
    {
        return _isCreator(_sender);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketVersionsInterface } from "./interfaces/LaborMarketVersionsInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev Helpers.
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { LaborMarketInterface } from "../LaborMarket/interfaces/LaborMarketInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";

/// @dev Supported interfaces.
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LaborMarketVersions is
    LaborMarketVersionsInterface,
    Ownable,
    ERC1155Holder
{
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                            PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/
    
    /// @dev The address interface of the Capacity Token.
    IERC20 public capacityToken;

    /// @dev The address interface of the Governor Badge.
    IERC1155 public governorBadge;

    /// @dev The address interface of the Creator Badge.
    IERC1155 creatorBadge;

    /// @dev The token ID of the Governor Badge.
    uint256 public governorTokenId;

    /// @dev The token ID of the Creator Badge.
    uint256 public creatorTokenId;

    /// @dev All of the versions that are actively running.
    ///      This also enables the ability to self-fork ones product.
    mapping(address => Version) public versions;

    /// @dev Tracking the versions of deployment that one has funded the cost for.
    mapping(bytes32 => uint256) public versionKeyToFunded;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Announces when a Version configuration is updated through the protocol Factory.
    event VersionUpdated(
          address indexed implementation
        , Version indexed version
    );

    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(
          address indexed marketAddress
        , address indexed owner
        , address indexed implementation
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
          address _implementation
        , BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    ) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(
            _implementation,
            _msgSender(),
            keccak256(abi.encodePacked(address(0), uint256(0))),
            0,
            false
        );

        /// @dev Set the network roles.
        _setNetworkRoles(
            _governorBadge, 
            _creatorBadge
        );
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows configuration to specific versions.
     * @dev This enables the ability to have Enterprise versions as well as public versions. None of this
     *      state is immutable as a license model may change in the future and updates here do not impact
     *      Labor Markets that are already running.
     * @param _implementation The implementation address.
     * @param _owner The owner of the version.
     * @param _tokenAddress The token address.
     * @param _tokenId The token ID.
     * @param _amount The amount that this user will have to pay.
     * @param _locked Whether or not this version has been made immutable.
     * Requirements:
     * - The caller must be the owner.
     * - If the caller is not the owner, cannot set a Payment Token as they cannot withdraw.
     */
    function setVersion(
          address _implementation
        , address _owner
        , address _tokenAddress
        , uint256 _tokenId
        , uint256 _amount
        , bool _locked
    ) 
        public 
        virtual 
        override 
    {
        /// @dev Load the existing Version object.
        Version memory version = versions[_implementation];

        /// @dev Prevent editing of a version once it has been locked.
        require(
            !version.locked,
            "LaborMarketVersions::_setVersion: Cannot update a locked version."
        );

        /// @dev Only the owner can set the version.
        require(
            version.owner == address(0) || version.owner == _msgSender(),
            "LaborMarketVersions::_setVersion: You do not have permission to edit this version."
        );

        /// @dev Make sure that no exogenous version controllers can set a payment
        ///      as there is not a mechanism for them to withdraw.
        if (_msgSender() != owner()) {
            require(
                _tokenAddress == address(0) && _tokenId == 0 && _amount == 0,
                "LaborMarketVersions::_setVersion: You do not have permission to set a payment token."
            );
        }

        /// @dev Set the version configuration.
        _setVersion(
            _implementation,
            _owner,
            keccak256(abi.encodePacked(_tokenAddress, _tokenId)),
            _amount,
            _locked
        );
    }

    function setMarketConfiguration(
          address _marketAddress
        , LaborMarketConfiguration memory _configuration
    )
        external
    {
        require(
            _isGovernor(_msgSender()),
            "LaborMarketVersions::setMarketConfiguration: Only governors can set market configurations from the network."
        );

        LaborMarketInterface(_marketAddress).setConfiguration(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Build the version key for a version and a sender.
     * @dev If the license for a version is updated, then the previous fundings
     *      will be lost and no longer active unless the version is reverted back
     *      to the previous configuration.
     * @param _implementation The implementation address.
     * @return The version key.
     */
    function getVersionKey(address _implementation)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return versions[_implementation].licenseKey;
    }

    /**
     * @notice Builds the license key for a version and a sender.
     * @param _versionKey The version key.
     * @param _sender The message sender address.
     * returns The license key for the message sender.
     */
    function getLicenseKey(
          bytes32 _versionKey
        , address _sender
    )
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_versionKey, _sender));
    }

    /**
     * @notice Gates permissions behind the Creator Badge.
     * @dev This is an internal function to allow gating Creator permissions
     *     within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     * @return Whether or not the sender is a Creator.
     */
    function _isCreator(address _sender)
        internal
        view
        returns (bool)
    {
        return creatorBadge.balanceOf(_sender, creatorTokenId) > 0;
    }

    /**
     * @notice Gates permissions behind the Governor Badge.
     * @dev This is an internal function to allow gating Governor permissions
     *     within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     * @return Whether or not the sender is a Governor.
     */
    function _isGovernor(address _sender) 
        internal
        view
        returns (bool)
    {
        return governorBadge.balanceOf(_sender, governorTokenId) > 0;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/
    /**
     * See {LaborMarketFactory.createLaborMarket}
     */
    function _createLaborMarket(
          address _implementation
        , bytes32 _licenseKey
        , uint256 _versionCost
        , LaborMarketConfiguration calldata _configuration
    )
        internal 
        returns (
            address
        ) 
    {
        /// @dev Deduct the amount of payment that is needed to cover deployment of this version.
        /// @notice This will revert if an individual has not funded it with at least the needed amount
        ///         to cover the cost of the version.
        /// @dev If deploying a free version or using an exogenous contract, the cost will be
        ///      zero and proceed normally.
        versionKeyToFunded[_licenseKey] -= _versionCost;

        /// @dev Get the address of the target.
        address marketAddress = _implementation.clone();

        /// @dev Interface with the newly created contract to initialize it.
        LaborMarketInterface laborMarket = LaborMarketInterface(marketAddress);

        /// @dev Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_configuration);

        /// @dev Register the Labor Market with the Reputation Module.
        ReputationModuleInterface(_configuration.modules.reputation).useReputationModule(
            marketAddress,
            _configuration.reputationBadge.token,
            _configuration.reputationBadge.tokenId
        );

        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _configuration.owner, _implementation);

        return marketAddress;
    }

    /**
     * See {LaborMarketVersionsInterface.setVersion}
     */
    function _setVersion(
          address _implementation
        , address _owner
        , bytes32 _licenseKey
        , uint256 _amount
        , bool _locked
    ) 
        internal 
    {
        /// @dev Set the version configuration.
        versions[_implementation] = Version({
            owner: _owner,
            licenseKey: _licenseKey,
            amount: _amount,
            locked: _locked
        });

        /// @dev Announce that the version has been updated to index it on the front-end.
        emit VersionUpdated(_implementation, versions[_implementation]);
    }

    /**
     * See {LaborMarketsNetwork.setNetworkRoles}
     */
    function _setNetworkRoles(
          BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    )
        internal
    {
        /// @dev Set the Governor Badge.
        governorBadge = IERC1155(_governorBadge.token);
        governorTokenId = _governorBadge.tokenId;

        /// @dev Set the Creator Badge.
        creatorBadge = IERC1155(_creatorBadge.token);
        creatorTokenId = _creatorBadge.tokenId;
    }

    /**
     * See {LaborMarketsNetwork.setReputationDecay}
     */
    function _setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        internal
    {
        ReputationModuleInterface(_reputationModule).setDecayConfig(
            _reputationToken,
            _reputationTokenId,
            _decayRate,
            _decayInterval,
            _decayStartEpoch
        );
    }

    /**
     * @notice Signals to external callers that this is a BadgerVersions contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return (_interfaceId ==
            type(LaborMarketVersionsInterface).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketVersionsInterface } from "./LaborMarketVersionsInterface.sol";
import { ReputationModuleInterface } from "../../Modules/Reputation/interfaces/ReputationModuleInterface.sol";


interface LaborMarketFactoryInterface is LaborMarketVersionsInterface {
    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket(
          address _implementation
        , LaborMarketConfiguration calldata _configuration
    ) 
        external 
        returns (
            address
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketNetworkInterface {

    function setCapacityImplementation(
        address _implementation
    )
        external;

    function setNetworkRoles(
          LaborMarketConfigurationInterface.BadgePair memory _governorBadge
        , LaborMarketConfigurationInterface.BadgePair memory _creatorBadge
    ) 
        external;

    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function isGovernor(address _sender) 
        external 
        view
        returns (
            bool
        );

    function isCreator(address _sender) 
        external 
        view
        returns (
            bool
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketConfigurationInterface} from "../../LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketVersionsInterface is LaborMarketConfigurationInterface {
    /*//////////////////////////////////////////////////////////////
                                SCHEMAS
    //////////////////////////////////////////////////////////////*/

    /// @dev The schema of a version.
    struct Version {
        address owner;
        bytes32 licenseKey;
        uint256 amount;
        bool locked;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setVersion(
        address _implementation,
        address _owner,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _locked
    ) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getVersionKey(address _implementation)
        external
        view
        returns (bytes32);

    function getLicenseKey(
          bytes32 _versionKey
        , address _sender
    )
        external
        pure
        returns (bytes32);
}