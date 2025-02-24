pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import '../Condition.sol';
import './INFTLock.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';

/**
 * @title NFT (ERC-721) Lock Condition
 * @author Nevermined
 *
 * @dev Implementation of the NFT Lock Condition for ERC-721 based NFTs 
 */
contract NFT721LockCondition is Condition, INFTLock, ReentrancyGuardUpgradeable, IERC721ReceiverUpgradeable {
    
    bytes32 constant public CONDITION_TYPE = keccak256('NFT721LockCondition');
    
   /**
    * @notice initialize init the  contract with the following parameters
    * @dev this function is called only once during the contract
    *       initialization.
    * @param _owner contract's owner account address
    * @param _conditionStoreManagerAddress condition store manager address
    */
    function initialize(
        address _owner,
        address _conditionStoreManagerAddress
    )
        external
        initializer()
    {
        require(
            _conditionStoreManagerAddress != address(0),
            'Invalid address'
        );
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        conditionStoreManager = ConditionStoreManager(
            _conditionStoreManagerAddress
        );
    }

   /**
    * @notice hashValues generates the hash of condition inputs 
    *        with the following parameters
    * @param _did the DID of the asset with NFTs attached to lock    
    * @param _lockAddress the contract address where the NFT will be locked
    * @param _amount is the amount of the locked tokens
    * @param _nftContractAddress Is the address of the NFT (ERC-721) contract to use         
    * @return bytes32 hash of all these values
    */
    function hashValues(
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _nftContractAddress
    )
        public
        override
        pure
        returns (bytes32)
    {
        return hashValuesMarked(_did, _lockAddress, _amount, address(0), _nftContractAddress);
    }

    function hashValuesMarked(
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _receiver,
        address _nftContractAddress
    )
        public
        override
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_did, _lockAddress, _amount, _receiver, _nftContractAddress));
    }

    /**
     * @notice fulfill the transfer NFT condition
     * @dev Fulfill method lock a NFT into the `_lockAddress`. 
     * @param _agreementId agreement identifier
     * @param _did refers to the DID in which secret store will issue the decryption keys
     * @param _lockAddress the contract address where the NFT will be locked
     * @param _amount is the amount of the locked tokens (1)
     * @param _nftContractAddress Is the address of the NFT (ERC-721) contract to use     
     * @return condition state (Fulfilled/Aborted)
     */
    function fulfillMarked(
        bytes32 _agreementId,
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _receiver,
        address _nftContractAddress
    )
        public
        override
        nonReentrant
        returns (ConditionStoreLibrary.ConditionState)
    {
        IERC721Upgradeable erc721 = IERC721Upgradeable(_nftContractAddress);

        require(
            _amount == 0 || (_amount == 1 && erc721.ownerOf(uint256(_did)) == msg.sender),
            'Sender does not have enough balance or is not the NFT owner.'
        );

        if (_amount == 1) {
            erc721.safeTransferFrom(msg.sender, _lockAddress, uint256(_did));
        }

        bytes32 _id = generateId(
            _agreementId,
            hashValuesMarked(_did, _lockAddress, _amount, _receiver, _nftContractAddress)
        );
        ConditionStoreLibrary.ConditionState state = super.fulfillWithProvenance(
            _id,
            ConditionStoreLibrary.ConditionState.Fulfilled,
            _did,
            'NFT721LockCondition',
            msg.sender
        );

        emit Fulfilled(
            _agreementId,
            _did,
            _lockAddress,
            _id,
            _amount,
            _receiver,
            _nftContractAddress
        );
        return state;
    }

    function fulfill(
        bytes32 _agreementId,
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _nftContractAddress
    )
        external
        override
        returns (ConditionStoreLibrary.ConditionState)
    {
        return fulfillMarked(_agreementId, _did, _lockAddress, _amount, address(0), _nftContractAddress);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }    
    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './ConditionStoreManager.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
/**
 * @title Condition
 * @author Nevermined
 *
 * @dev Implementation of the Condition
 *
 *      Each condition has a validation function that returns either FULFILLED, 
 *      ABORTED or UNFULFILLED. When a condition is successfully solved, we call 
 *      it FULFILLED. If a condition cannot be FULFILLED anymore due to a timeout 
 *      or other types of counter-proofs, the condition is ABORTED. UNFULFILLED 
 *      values imply that a condition has not been provably FULFILLED or ABORTED. 
 *      All initialized conditions start out as UNFULFILLED.
 */
contract Condition is OwnableUpgradeable {

    ConditionStoreManager internal conditionStoreManager;

   /**
    * @notice generateId condition Id from the following 
    *       parameters
    * @param _agreementId SEA agreement ID
    * @param _valueHash hash of all the condition input values
    */
    function generateId(
        bytes32 _agreementId,
        bytes32 _valueHash
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _agreementId,
                address(this),
                _valueHash
            )
        );
    }

   /**
    * @notice fulfill set the condition state to Fulfill | Abort
    * @param _id condition identifier
    * @param _newState new condition state (Fulfill/Abort)
    * @return the updated condition state 
    */
    function fulfill(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // _newState can be Fulfilled or Aborted
        return conditionStoreManager.updateConditionState(_id, _newState);
    }

    function fulfillWithProvenance(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState,
        bytes32 _did,
        string memory _name,
        address _user
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // _newState can be Fulfilled or Aborted
        return conditionStoreManager.updateConditionStateWithProvenance(_id, _did, _name, _user, _newState);
    }


    /**
    * @notice abortByTimeOut set condition state to Aborted 
    *         if the condition is timed out
    * @param _id condition identifier
    * @return the updated condition state
    */
    function abortByTimeOut(
        bytes32 _id
    )
        external
        returns (ConditionStoreLibrary.ConditionState)
    {
        require(
            conditionStoreManager.isConditionTimedOut(_id),
            'Condition needs to be timed out'
        );

        return conditionStoreManager.updateConditionState(
            _id,
            ConditionStoreLibrary.ConditionState.Aborted
        );
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../Condition.sol';


interface INFTLock {

    event Fulfilled(
        bytes32 indexed _agreementId,
        bytes32 indexed _did,
        address indexed _lockAddress,
        bytes32 _conditionId,
        uint256 _amount,
        address _receiver,
        address _nftContractAddress
    );

    /**
     * @notice hashValues generates the hash of condition inputs 
     *        with the following parameters
     * @param _did the DID of the asset with NFTs attached to lock    
     * @param _lockAddress the contract address where the NFT will be locked
     * @param _amount is the amount of the NFTs locked
     * @param _nftContractAddress Is the address of the NFT (ERC-721, ERC-1155) contract to use              
     * @return bytes32 hash of all these values 
     */
    function hashValues(
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _nftContractAddress
    )
    external
    pure
    returns (bytes32);

    function hashValuesMarked(
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _receiver,
        address _nftContractAddress
    )
    external
    pure
    returns (bytes32);

    /**
     * @notice fulfill the transfer NFT condition
     * @dev Fulfill method transfer a certain amount of NFTs 
     *       to the _nftReceiver address. 
     *       When true then fulfill the condition
     * @param _agreementId agreement identifier
     * @param _did refers to the DID in which secret store will issue the decryption keys
     * @param _lockAddress the contract address where the NFT will be locked
     * @param _amount is the amount of the locked tokens
     * @param _nftContractAddress Is the address of the NFT (ERC-721) contract to use              
     * @return condition state (Fulfilled/Aborted)
     */
    function fulfill(
        bytes32 _agreementId,
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _nftContractAddress
    )
    external
    returns (ConditionStoreLibrary.ConditionState);

    function fulfillMarked(
        bytes32 _agreementId,
        bytes32 _did,
        address _lockAddress,
        uint256 _amount,
        address _receiver,
        address _nftContractAddress
    )
    external
    returns (ConditionStoreLibrary.ConditionState);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import '../Common.sol';
import '../libraries/EpochLibrary.sol';
import './ConditionStoreLibrary.sol';
import '../registry/DIDRegistry.sol';
import '../governance/INVMConfig.sol';

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

/**
 * @title Condition Store Manager
 * @author Nevermined
 *
 * @dev Implementation of the Condition Store Manager.
 *
 *      Condition store manager is responsible for enforcing the 
 *      the business logic behind creating/updating the condition state
 *      based on the assigned role to each party. Only specific type of
 *      contracts are allowed to call this contract, therefore there are 
 *      two types of roles, create role that in which is able to create conditions.
 *      The second role is the update role, which is can update the condition state.
 *      Also, it support delegating the roles to other contract(s)/account(s).
 */
contract ConditionStoreManager is OwnableUpgradeable, AccessControlUpgradeable, Common {

    bytes32 private constant PROXY_ROLE = keccak256('PROXY_ROLE');

    using ConditionStoreLibrary for ConditionStoreLibrary.ConditionList;
    using EpochLibrary for EpochLibrary.EpochList;

    enum RoleType { Create, Update }
    address private createRole;
    ConditionStoreLibrary.ConditionList internal conditionList;
    EpochLibrary.EpochList internal epochList;

    address internal nvmConfigAddress;

    DIDRegistry public didRegistry;
    
    event ConditionCreated(
        bytes32 indexed _id,
        address indexed _typeRef,
        address indexed _who
    );

    event ConditionUpdated(
        bytes32 indexed _id,
        address indexed _typeRef,
        ConditionStoreLibrary.ConditionState indexed _state,
        address _who
    );

    modifier onlyCreateRole(){
        require(
            createRole == msg.sender,
            'Invalid CreateRole'
        );
        _;
    }

    modifier onlyUpdateRole(bytes32 _id)
    {
        require(
            conditionList.conditions[_id].typeRef != address(0),
            'Condition doesnt exist'
        );
        require(
            conditionList.conditions[_id].typeRef == msg.sender,
            'Invalid UpdateRole'
        );
        _;
    }

    modifier onlyValidType(address typeRef)
    {
        require(
            typeRef != address(0),
            'Invalid address'
        );
        require(
            isContract(typeRef),
            'Invalid contract address'
        );
        _;
    }


    /**
     * @dev initialize ConditionStoreManager Initializer
     *      Initialize Ownable. Only on contract creation,
     * @param _creator refers to the creator of the contract
     * @param _owner refers to the owner of the contract           
     * @param _nvmConfigAddress refers to the contract address of `NeverminedConfig`
     */
    function initialize(
        address _creator,
        address _owner,
        address _nvmConfigAddress
    )
        public
        initializer
    {
        require(
            _owner != address(0),
            'Invalid address'
        );
        require(
            createRole == address(0),
            'Role already assigned'
        );

        require(
            _nvmConfigAddress != address(0), 
                'Invalid Address'
        );
        
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        createRole = _creator;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        
        nvmConfigAddress= _nvmConfigAddress;
    }

    /**
     * @dev Set provenance registry
     * @param _didAddress did registry address. can be zero
     */
    function setProvenanceRegistry(address _didAddress) public {
        didRegistry = DIDRegistry(_didAddress);
    }

    /**
     * @dev getCreateRole get the address of contract
     *      which has the create role
     * @return create condition role address
     */
    function getCreateRole()
        external
        view
        returns (address)
    {
        return createRole;
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    external
    view
    returns (address)
    {
        return nvmConfigAddress;
    }    
    
    function setNvmConfigAddress(address _addr)
    external
    onlyOwner
    {
        nvmConfigAddress = _addr;
    }    
    
    /**
     * @dev delegateCreateRole only owner can delegate the 
     *      create condition role to a different address
     * @param delegatee delegatee address
     */
    function delegateCreateRole(
        address delegatee
    )
        external
        onlyOwner()
    {
        require(
            delegatee != address(0),
            'Invalid delegatee address'
        );
        createRole = delegatee;
    }

    /**
     * @dev delegateUpdateRole only owner can delegate 
     *      the update role to a different address for 
     *      specific condition Id which has the create role
     * @param delegatee delegatee address
     */
    function delegateUpdateRole(
        bytes32 _id,
        address delegatee
    )
        external
        onlyOwner()
    {
        require(
            delegatee != address(0),
            'Invalid delegatee address'
        );
        require(
            conditionList.conditions[_id].typeRef != address(0),
            'Invalid condition Id'
        );
        conditionList.conditions[_id].typeRef = delegatee;
    }

    function grantProxyRole(address _address) public onlyOwner {
        grantRole(PROXY_ROLE, _address);
    }

    function revokeProxyRole(address _address) public onlyOwner {
        revokeRole(PROXY_ROLE, _address);
    }

    /**
     * @dev createCondition only called by create role address 
     *      the condition should use a valid condition contract 
     *      address, valid time lock and timeout. Moreover, it 
     *      enforce the condition state transition from 
     *      Uninitialized to Unfulfilled.
     * @param _id unique condition identifier
     * @param _typeRef condition contract address
     */
    function createCondition(
        bytes32 _id,
        address _typeRef
    )
    external
    {
        createCondition(
            _id,
            _typeRef,
            uint(0),
            uint(0)
        );
    }
    
    function createCondition2(
        bytes32 _id,
        address _typeRef
    )
    external
    {
        createCondition(
            _id,
            _typeRef,
            uint(0),
            uint(0)
        );
    }
    
    /**
     * @dev createCondition only called by create role address 
     *      the condition should use a valid condition contract 
     *      address, valid time lock and timeout. Moreover, it 
     *      enforce the condition state transition from 
     *      Uninitialized to Unfulfilled.
     * @param _id unique condition identifier
     * @param _typeRef condition contract address
     * @param _timeLock start of the time window
     * @param _timeOut end of the time window
     */
    function createCondition(
        bytes32 _id,
        address _typeRef,
        uint _timeLock,
        uint _timeOut
    )
        public
        onlyCreateRole
        onlyValidType(_typeRef)
    {
        epochList.create(_id, _timeLock, _timeOut);

        conditionList.create(_id, _typeRef);

        emit ConditionCreated(
            _id,
            _typeRef,
            msg.sender
        );
    }

    /**
     * @dev updateConditionState only called by update role address. 
     *      It enforce the condition state transition to either 
     *      Fulfill or Aborted state
     * @param _id unique condition identifier
     * @return the current condition state 
     */
    function updateConditionState(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        external
        onlyUpdateRole(_id)
        returns (ConditionStoreLibrary.ConditionState)
    {
        return _updateConditionState(_id, _newState);
    }

    function _updateConditionState(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // no update before time lock
        require(
            !isConditionTimeLocked(_id),
            'TimeLock is not over yet'
        );

        ConditionStoreLibrary.ConditionState updateState = _newState;

        // auto abort after time out
        if (isConditionTimedOut(_id)) {
            updateState = ConditionStoreLibrary.ConditionState.Aborted;
        }

        conditionList.updateState(_id, updateState);

        emit ConditionUpdated(
            _id,
            conditionList.conditions[_id].typeRef,
            updateState,
            msg.sender
        );

        return updateState;
    }

    function updateConditionStateWithProvenance(
        bytes32 _id,
        bytes32 _did,
        string memory name,
        address user,
        ConditionStoreLibrary.ConditionState _newState
    )
        external
        onlyUpdateRole(_id)
        returns (ConditionStoreLibrary.ConditionState)
    {
        ConditionStoreLibrary.ConditionState state = _updateConditionState(_id, _newState);
        if (address(didRegistry) != address(0)) {
            didRegistry.condition(_did, _id, name, user);
        }
        return state;
    }

    function updateConditionMapping(
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    external
    onlyUpdateRole(_id)
    {
        conditionList.updateKeyValue(
            _id, 
            _key, 
            _value
        );
    }
    
    function updateConditionMappingProxy(
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    external
    {
        require(hasRole(PROXY_ROLE, msg.sender), 'Invalid access role');
        conditionList.updateKeyValue(
            _id, 
            _key, 
            _value
        );
    }
    
    /**
     * @dev getCondition  
     * @return typeRef the type reference
     * @return state condition state
     * @return timeLock the time lock
     * @return timeOut time out
     * @return blockNumber block number
     */
    function getCondition(bytes32 _id)
        external
        view
        returns (
            address typeRef,
            ConditionStoreLibrary.ConditionState state,
            uint timeLock,
            uint timeOut,
            uint blockNumber
        )
    {
        typeRef = conditionList.conditions[_id].typeRef;
        state = conditionList.conditions[_id].state;
        timeLock = epochList.epochs[_id].timeLock;
        timeOut = epochList.epochs[_id].timeOut;
        blockNumber = epochList.epochs[_id].blockNumber;
    }

    /**
     * @dev getConditionState  
     * @return condition state
     */
    function getConditionState(bytes32 _id)
        external
        view
        virtual
        returns (ConditionStoreLibrary.ConditionState)
    {
        return conditionList.conditions[_id].state;
    }

    /**
     * @dev getConditionTypeRef  
     * @return condition typeRef
     */
    function getConditionTypeRef(bytes32 _id)
    external
    view
    virtual
    returns (address)
    {
        return conditionList.conditions[_id].typeRef;
    }    

    /**
     * @dev getConditionState  
     * @return condition state
     */
    function getMappingValue(bytes32 _id, bytes32 _key)
    external
    view
    virtual
    returns (bytes32)
    {
        return conditionList.map[_id][_key];
    }    

    /**
     * @dev isConditionTimeLocked  
     * @return whether the condition is timedLock ended
     */
    function isConditionTimeLocked(bytes32 _id)
        public
        view
        returns (bool)
    {
        return epochList.isTimeLocked(_id);
    }

    /**
     * @dev isConditionTimedOut  
     * @return whether the condition is timed out 
     */
    function isConditionTimedOut(bytes32 _id)
        public
        view
        returns (bool)
    {
        return epochList.isTimedOut(_id);
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

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

/**
 * @title Common functions
 * @author Nevermined
 */
contract Common {

    using SafeMathUpgradeable for uint256;

   /**
    * @notice getCurrentBlockNumber get block number
    * @return the current block number
    */
    function getCurrentBlockNumber()
        external
        view
        returns (uint)
    {
        return block.number;
    }

    /**
     * @dev isContract detect whether the address is 
     *          is a contract address or externally owned account
     * @return true if it is a contract address
     */
    function isContract(address addr)
        public
        view
        returns (bool)
    {
        uint size;
        // solhint-disable-next-line
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
    * @param _agentId The address of the agent
    * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param _signature Signatures provided by the agent
    * @return true if the signature correspond to the agent address        
    */
    function provenanceSignatureIsCorrect(
        address _agentId,
        bytes32 _hash,
        bytes memory _signature
    )
    public
    pure
    returns(bool)
    {
        return ECDSAUpgradeable.recover(_hash, _signature) == _agentId;
    }

    /**
     * @dev Sum the total amount given an uint array
     * @return the total amount
     */
    function calculateTotalAmount(
        uint256[] memory _amounts
    )
    public
    pure
    returns (uint256)
    {
        uint256 _totalAmount;
        for(uint i; i < _amounts.length; i++)
            _totalAmount = _totalAmount.add(_amounts[i]);
        return _totalAmount;
    }

    function addressToBytes32(
        address _addr
    ) 
    public 
    pure 
    returns (bytes32) 
    {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(
        bytes32 _b32
    ) 
    public 
    pure 
    returns (address) 
    {
        return address(uint160(uint256(_b32)));
    }    
    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

/**
 * @title Epoch Library
 * @author Nevermined
 *
 * @dev Implementation of Epoch Library.
 *      For an arbitrary Epoch, this library manages the life
 *      cycle of an Epoch. Usually this library is used for 
 *      handling the time window between conditions in an agreement.
 */
library EpochLibrary {

    using SafeMathUpgradeable for uint256;

    struct Epoch {
        uint256 timeLock;
        uint256 timeOut;
        uint256 blockNumber;
    }

    struct EpochList {
        mapping(bytes32 => Epoch) epochs;
        bytes32[] epochIds; // UNUSED
    }

   /**
    * @notice create creates new Epoch
    * @param _self is the Epoch storage pointer
    * @param _timeLock value in block count (can not fulfill before)
    * @param _timeOut value in block count (can not fulfill after)
    */
    function create(
        EpochList storage _self,
        bytes32 _id,
        uint256 _timeLock,
        uint256 _timeOut
    )
        internal
    {
        require(
            _self.epochs[_id].blockNumber == 0,
            'Id already exists'
        );

        require(
            _timeLock.add(block.number) >= block.number &&
            _timeOut.add(block.number) >= block.number,
            'Indicating integer overflow/underflow'
        );

        if (_timeOut > 0 && _timeLock > 0) {
            require(
                _timeLock < _timeOut,
                'Invalid time margin'
            );
        }

        _self.epochs[_id] = Epoch({
            timeLock : _timeLock,
            timeOut : _timeOut,
            blockNumber : block.number
        });

        // _self.epochIds.push(_id);

    }

   /**
    * @notice isTimedOut means you cannot fulfill after
    * @param _self is the Epoch storage pointer
    * @return true if the current block number is gt timeOut
    */
    function isTimedOut(
        EpochList storage _self,
        bytes32 _id
    )
        external
        view
        returns (bool)
    {
        if (_self.epochs[_id].timeOut == 0) {
            return false;
        }

        return (block.number > getEpochTimeOut(_self.epochs[_id]));
    }

   /**
    * @notice isTimeLocked means you cannot fulfill before
    * @param _self is the Epoch storage pointer
    * @return true if the current block number is gt timeLock
    */
    function isTimeLocked(
        EpochList storage _self,
        bytes32 _id
    )
        external
        view
        returns (bool)
    {
        return (block.number < getEpochTimeLock(_self.epochs[_id]));
    }

   /**
    * @notice getEpochTimeOut
    * @param _self is the Epoch storage pointer
    */
    function getEpochTimeOut(
        Epoch storage _self
    )
        public
        view
        returns (uint256)
    {
        return _self.timeOut.add(_self.blockNumber);
    }

    /**
    * @notice getEpochTimeLock
    * @param _self is the Epoch storage pointer
    */
    function getEpochTimeLock(
        Epoch storage _self
    )
        public
        view
        returns (uint256)
    {
        return _self.timeLock.add(_self.blockNumber);
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @title Condition Store Library
 * @author Nevermined
 *
 * @dev Implementation of the Condition Store Library.
 *      
 *      Condition is a key component in the service execution agreement. 
 *      This library holds the logic for creating and updating condition 
 *      Any Condition has only four state transitions starts with Uninitialized,
 *      Unfulfilled, Fulfilled, and Aborted. Condition state transition goes only 
 *      forward from Unintialized -> Unfulfilled -> {Fulfilled || Aborted} 
 */
library ConditionStoreLibrary {

    enum ConditionState { Uninitialized, Unfulfilled, Fulfilled, Aborted }

    struct Condition {
        address typeRef;
        ConditionState state;
        address createdBy; // UNUSED
        address lastUpdatedBy; // UNUSED
        uint256 blockNumberUpdated; // UNUSED
    }

    struct ConditionList {
        mapping(bytes32 => Condition) conditions;
        mapping(bytes32 => mapping(bytes32 => bytes32)) map;
        bytes32[] conditionIds; // UNUSED
    }
    
    
   /**
    * @notice create new condition
    * @dev check whether the condition exists, assigns 
    *       condition type, condition state, last updated by, 
    *       and update at (which is the current block number)
    * @param _self is the ConditionList storage pointer
    * @param _id valid condition identifier
    * @param _typeRef condition contract address
    */
    function create(
        ConditionList storage _self,
        bytes32 _id,
        address _typeRef
    )
        internal
    {
        require(
            _self.conditions[_id].typeRef == address(0),
            'Id already exists'
        );

        _self.conditions[_id].typeRef = _typeRef;
        _self.conditions[_id].state = ConditionState.Unfulfilled;
    }

    /**
    * @notice updateState update the condition state
    * @dev check whether the condition state transition is right,
    *       assign the new state, update last updated by and
    *       updated at.
    * @param _self is the ConditionList storage pointer
    * @param _id condition identifier
    * @param _newState the new state of the condition
    */
    function updateState(
        ConditionList storage _self,
        bytes32 _id,
        ConditionState _newState
    )
        internal
    {
        require(
            _self.conditions[_id].state == ConditionState.Unfulfilled &&
            _newState > _self.conditions[_id].state,
            'Invalid state transition'
        );

        _self.conditions[_id].state = _newState;
    }
    
    function updateKeyValue(
        ConditionList storage _self,
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    internal
    {
        _self.map[_id][_key] = _value;
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './DIDFactory.sol';
import '../token/erc1155/NFTUpgradeable.sol';
import '../token/erc721/NFT721Upgradeable.sol';
import '../royalties/StandardRoyalties.sol';

/**
 * @title Mintable DID Registry
 * @author Nevermined
 *
 * @dev Implementation of a Mintable DID Registry.
 */
contract DIDRegistry is DIDFactory {

    using DIDRegistryLibrary for DIDRegistryLibrary.DIDRegisterList;

    NFTUpgradeable public erc1155;
    NFT721Upgradeable public erc721;

    mapping (address => bool) public royaltiesCheckers;
    StandardRoyalties public defaultRoyalties;

    INVMConfig public nvmConfig;
    address public conditionManager;

    modifier onlyConditionManager
    {
        require(
            msg.sender == conditionManager,
            'Only condition store manager'
        );
        _;
    }

    //////////////////////////////////////////////////////////////
    ////////  EVENTS  ////////////////////////////////////////////
    //////////////////////////////////////////////////////////////
    
    /**
     * @dev DIDRegistry Initializer
     *      Initialize Ownable. Only on contract creation.
     * @param _owner refers to the owner of the contract.
     */
    function initialize(
        address _owner,
        address _erc1155,
        address _erc721,
        address _config,
        address _royalties
    )
    public
    initializer
    {
        OwnableUpgradeable.__Ownable_init();
        erc1155 = NFTUpgradeable(_erc1155);
        erc721 = NFT721Upgradeable(_erc721);
        transferOwnership(_owner);
        manager = _owner;
        defaultRoyalties = StandardRoyalties(_royalties);
        nvmConfig = INVMConfig(_config);
    }

    function setDefaultRoyalties(address _royalties) public onlyOwner {
        defaultRoyalties = StandardRoyalties(_royalties);
    }

    function registerRoyaltiesChecker(address _addr) public onlyOwner {
        royaltiesCheckers[_addr] = true;
    }

    function setConditionManager(address _manager) public onlyOwner {
        conditionManager = _manager;
    }

    event DIDRoyaltiesAdded(bytes32 indexed did, address indexed addr);
    event DIDRoyaltyRecipientChanged(bytes32 indexed did, address indexed addr);

    function setDIDRoyalties(
        bytes32 _did,
        address _royalties
    )
    public
    {
        require(didRegisterList.didRegisters[_did].creator == msg.sender, 'Only creator can set royalties');
        require(address(didRegisterList.didRegisters[_did].royaltyScheme) == address(0), 'Cannot change royalties');
        didRegisterList.didRegisters[_did].royaltyScheme = IRoyaltyScheme(_royalties);

        emit DIDRoyaltiesAdded(
            _did,
            _royalties
        );
    }

    function setDIDRoyaltyRecipient(
        bytes32 _did,
        address _recipient
    )
    public
    {
        require(didRegisterList.didRegisters[_did].creator == msg.sender, 'Only creator can set royalties');
        didRegisterList.didRegisters[_did].royaltyRecipient = _recipient;

        emit DIDRoyaltyRecipientChanged(
            _did,
            _recipient
        );
    }

    /**
     * @notice Register a Mintable DID using NFTs based in the ERC-1155 standard.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if true it mints the ERC-1155 NFTs attached to the asset
     * @param _activityId refers to activity
     * @param _nftMetadata refers to the url providing the NFT Metadata     
     */
    function registerMintableDID(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _cap,
        uint256 _royalties,
        bool _mint,
        bytes32 _activityId,
        string memory _nftMetadata
    )
    public
    onlyValidAttributes(_nftMetadata)
    {
        registerDID(_didSeed, _checksum, _providers, _url, _activityId, '');
        enableAndMintDidNft(
            hashDID(_didSeed, msg.sender),
            _cap,
            _royalties,
            _mint,
            _nftMetadata
        );
    }

    /**
     * @notice Register a Mintable DID using NFTs based in the ERC-721 standard.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if true it mints the ERC-1155 NFTs attached to the asset
     * @param _activityId refers to activity
     * @param _nftMetadata refers to the url providing the NFT Metadata     
     */
    function registerMintableDID721(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _royalties,
        bool _mint,
        bytes32 _activityId,
        string memory _nftMetadata
    )
    public
    onlyValidAttributes(_nftMetadata)
    {
        registerDID(_didSeed, _checksum, _providers, _url, _activityId, '');
        enableAndMintDidNft721(
            hashDID(_didSeed, msg.sender),
            _royalties,
            _mint,
            _nftMetadata
        );
    }



    /**
     * @notice Register a Mintable DID.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _activityId refers to activity
     * @param _nftMetadata refers to the url providing the NFT Metadata     
     */
    function registerMintableDID(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _cap,
        uint256 _royalties,
        bytes32 _activityId,
        string memory _nftMetadata
    )
    public
    onlyValidAttributes(_nftMetadata)
    {
        registerMintableDID(
            _didSeed, _checksum, _providers, _url, _cap, _royalties, false, _activityId, _nftMetadata);
    }

    
    /**
     * @notice enableDidNft creates the initial setup of NFTs minting and royalties distribution for ERC-1155 NFTs.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created.
      
     * @dev update the DID registry providers list by adding the mintCap and royalties configuration
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if is true mint directly the amount capped tokens and lock in the _lockAddress
     * @param _nftMetadata refers to the url providing the NFT Metadata          
     */
    function enableAndMintDidNft(
        bytes32 _did,
        uint256 _cap,
        uint256 _royalties,
        bool _mint,
        string memory _nftMetadata
    )
    public
    onlyDIDOwner(_did)
    returns (bool success)
    {
        didRegisterList.initializeNftConfig(_did, _cap, _royalties > 0 ? defaultRoyalties : IRoyaltyScheme(address(0)));
        
        if (bytes(_nftMetadata).length > 0)
            erc1155.setNFTMetadata(uint256(_did), _nftMetadata);
        
        if (_royalties > 0) {
            erc1155.setTokenRoyalty(uint256(_did), msg.sender, _royalties);
            if (address(defaultRoyalties) != address(0)) defaultRoyalties.setRoyalty(_did, _royalties);
        }
        
        if (_mint)
            mint(_did, _cap);
        
        return super.used(
            keccak256(abi.encode(_did, _cap, _royalties, msg.sender)),
            _did, msg.sender, keccak256('enableNft'), '', 'nft initialization');
    }

    /**
     * @notice enableAndMintDidNft721 creates the initial setup of NFTs minting and royalties distribution for ERC-721 NFTs.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created.
      
     * @dev update the DID registry providers list by adding the mintCap and royalties configuration
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if is true mint directly the amount capped tokens and lock in the _lockAddress
     * @param _nftMetadata refers to the url providing the NFT Metadata          
     */    
    function enableAndMintDidNft721(
        bytes32 _did,
        uint256 _royalties,
        bool _mint,
        string memory _nftMetadata
    )
    public
    onlyDIDOwner(_did)
    returns (bool success)
    {
        didRegisterList.initializeNft721Config(_did, _royalties > 0 ? defaultRoyalties : IRoyaltyScheme(address(0)));

        if (bytes(_nftMetadata).length > 0)
            erc721.setNFTMetadata(uint256(_did), _nftMetadata);
        
        if (_royalties > 0) {
            if (address(defaultRoyalties) != address(0)) defaultRoyalties.setRoyalty(_did, _royalties);
            erc721.setTokenRoyalty(uint256(_did), msg.sender, _royalties);
        }

        if (_mint)
            mint721(_did, msg.sender);
        
        return super.used(
            keccak256(abi.encode(_did, 1, _royalties, msg.sender)),
            _did, msg.sender, keccak256('enableNft721'), '', 'nft initialization');
    }

    /**
     * @notice Mints a NFT associated to the DID
     *
     * @dev Because ERC-1155 uses uint256 and DID's are bytes32, there is a conversion between both
     *      Only the DID owner can mint NFTs associated to the DID
     *
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _amount amount to mint
     * @param _receiver the address that will receive the new nfts minted
     */    
    function mint(
        bytes32 _did,
        uint256 _amount,
        address _receiver
    )
    public
    onlyDIDOwner(_did)
    nftIsInitialized(_did)
    {
        if (didRegisterList.didRegisters[_did].mintCap > 0) {
            require(
                didRegisterList.didRegisters[_did].nftSupply + _amount <= didRegisterList.didRegisters[_did].mintCap,
                'Cap exceeded'
            );
        }
        
        didRegisterList.didRegisters[_did].nftSupply = didRegisterList.didRegisters[_did].nftSupply + _amount;
        
        super.used(
            keccak256(abi.encode(_did, msg.sender, 'mint', _amount, block.number)),
            _did, msg.sender, keccak256('mint'), '', 'mint');

        erc1155.mint(_receiver, uint256(_did), _amount, '');
    }

    function mint(
        bytes32 _did,
        uint256 _amount
    )
    public
    {
        mint(_did, _amount, msg.sender);
    }


    /**
     * @notice Mints a ERC-721 NFT associated to the DID
     *
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _receiver the address that will receive the new nfts minted
     */
    function mint721(
        bytes32 _did,
        address _receiver
    )
    public
    onlyDIDOwner(_did)
    nft721IsInitialized(_did)
    {
        super.used(
            keccak256(abi.encode(_did, msg.sender, 'mint721', 1, block.number)),
            _did, msg.sender, keccak256('mint721'), '', 'mint721');

        erc721.mint(_receiver, uint256(_did));
    }

    function mint721(
        bytes32 _did
    )
    public
    {
        mint721(_did, msg.sender);
    }
    
    
    /**
     * @notice Burns NFTs associated to the DID
     *
     * @dev Because ERC-1155 uses uint256 and DID's are bytes32, there is a conversion between both
     *      Only the DID owner can burn NFTs associated to the DID
     *
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _amount amount to burn
     */
    function burn(
        bytes32 _did,
        uint256 _amount
    )
    public
    nftIsInitialized(_did)
    {
        erc1155.burn(msg.sender, uint256(_did), _amount);
        didRegisterList.didRegisters[_did].nftSupply -= _amount;
        
        super._used(
            keccak256(abi.encode(_did, msg.sender, 'burn', _amount, block.number)),
            _did, msg.sender, keccak256('burn'), '', 'burn');
    }

    function burn721(
        bytes32 _did
    )
    public
    nft721IsInitialized(_did)
    {
        require(erc721.balanceOf(msg.sender) > 0, 'ERC721: burn amount exceeds balance');
        erc721.burn(uint256(_did));

        super._used(
            keccak256(abi.encode(_did, msg.sender, 'burn721', 1, block.number)),
            _did, msg.sender, keccak256('burn721'), '', 'burn721');
    }

    function _provenanceStorage() override internal view returns (bool) {
        return address(nvmConfig) == address(0) || nvmConfig.getProvenanceStorage();
    }

    function condition(bytes32 _did, bytes32 _cond, string memory name, address user) public onlyConditionManager {
        _used(_cond, _did, user, keccak256(bytes(name)), '', name);
    }

}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

abstract contract INVMConfig {

    bytes32 public constant GOVERNOR_ROLE = keccak256('NVM_GOVERNOR_ROLE');
    
    /**
    * @notice Event that is emitted when a parameter is changed
    * @param _whoChanged the address of the governor changing the parameter
    * @param _parameter the hash of the name of the parameter changed
    */
    event NeverminedConfigChange(
        address indexed _whoChanged,
        bytes32 indexed _parameter
    );

    /**
     * @notice The governor can update the Nevermined Marketplace fees
     * @param _marketplaceFee new marketplace fee 
     * @param _feeReceiver The address receiving the fee      
     */
    function setMarketplaceFees(
        uint256 _marketplaceFee,
        address _feeReceiver
    ) virtual external;

    /**
     * @notice Indicates if an address is a having the GOVERNOR role
     * @param _address The address to validate
     * @return true if is a governor 
     */    
    function isGovernor(
        address _address
    ) external view virtual returns (bool);

    /**
     * @notice Returns the marketplace fee
     * @return the marketplace fee
     */
    function getMarketplaceFee()
    external view virtual returns (uint256);

    /**
     * @notice Returns the receiver address of the marketplace fee
     * @return the receiver address
     */    
    function getFeeReceiver()
    external view virtual returns (address);

    /**
     * @notice Returns true if provenance should be stored in storage
     * @return true if provenance should be stored in storage
     */    
    function getProvenanceStorage()
    external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG\.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../interfaces/IRoyaltyScheme.sol';
import '../registry/DIDRegistry.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @title Standard royalty scheme.
 * @author Nevermined
 */

contract StandardRoyalties is IRoyaltyScheme, Initializable {

    DIDRegistry public registry;

    uint256 constant public DENOMINATOR = 1000000;

    mapping (bytes32 => uint256) public royalties;

    function initialize(address _registry) public initializer {
        registry = DIDRegistry(_registry);
    }

    /**
     * @notice Set royalties for a DID
     * @dev Can only be called by creator of the DID
     * @param _did DID for which the royalties are set
     * @param _royalty Royalty, the actual royalty will be _royalty / 10000 percent
     */
    function setRoyalty(bytes32 _did, uint256 _royalty) public {
        require(_royalty <= DENOMINATOR, 'royalty cannot be more than 100%');
        require(msg.sender == registry.getDIDCreator(_did) || msg.sender == address(registry), 'only owner can change');
        require(royalties[_did] == 0, 'royalties cannot be changed');
        royalties[_did] = _royalty;
    }

    function check(bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address)
    external view returns (bool)
    {
        // If there are no royalties everything is good
        uint256 rate = royalties[_did];
        if (rate == 0) {
            return true;
        }

        // If (sum(_amounts) == 0) - It means there is no payment so everything is valid
        // returns true;
        uint256 _totalAmount = 0;
        for(uint i = 0; i < _amounts.length; i++)
            _totalAmount = _totalAmount + _amounts[i];
        // If the amount to receive by the creator is lower than royalties the calculation is not valid
        // return false;
        uint256 _requiredRoyalties = _totalAmount * rate / DENOMINATOR;

        if (_requiredRoyalties == 0)
            return true;
        
        // If (_did.creator is not in _receivers) - It means the original creator is not included as part of the payment
        // return false;
        address recipient = registry.getDIDRoyaltyRecipient(_did);
        bool found = false;
        uint256 index;
        for (index = 0; index < _receivers.length; index++) {
            if (recipient == _receivers[index])  {
                found = true;
                break;
            }
        }

        // The creator royalties are not part of the rewards
        if (!found) {
            return false;
        }

        // Check if royalties are enough
        // Are we paying enough royalties in the secondary market to the original creator?
        return (_amounts[index] >= _requiredRoyalties);
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './DIDRegistryLibrary.sol';
import './ProvenanceRegistry.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

/**
 * @title DID Factory
 * @author Nevermined
 *
 * @dev Implementation of the DID Registry.
 */
abstract contract DIDFactory is OwnableUpgradeable, ProvenanceRegistry { 
    
    /**
     * @dev The DIDRegistry Library takes care of the basic DID storage functions.
     */
    using DIDRegistryLibrary for DIDRegistryLibrary.DIDRegisterList;

    /**
     * @dev state storage for the DID registry
     */
    DIDRegistryLibrary.DIDRegisterList internal didRegisterList;

    // DID -> Address -> Boolean Permission
    mapping(bytes32 => mapping(address => bool)) internal didPermissions;
    
    address public manager;

    //////////////////////////////////////////////////////////////
    ////////  MODIFIERS   ////////////////////////////////////////
    //////////////////////////////////////////////////////////////

    
    modifier onlyDIDOwner(bytes32 _did)
    {
        require(
            isDIDOwner(msg.sender, _did),
            'Only owner'
        );
        _;
    }

    modifier onlyManager
    {
        require(
            msg.sender == manager,
            'Only manager'
        );
        _;
    }

    modifier onlyOwnerProviderOrDelegated(bytes32 _did)
    {
        require(isOwnerProviderOrDelegate(_did),
            'Only owner, provider or delegated'
        );
        _;
    }

    modifier onlyValidAttributes(string memory _attributes)
    {
        require(
            bytes(_attributes).length <= 2048,
            'Invalid attributes size'
        );
        _;
    }

    modifier nftIsInitialized(bytes32 _did)
    {
        require(
            didRegisterList.didRegisters[_did].nftInitialized,
            'NFT not initialized'
        );
        _;
    }    
    
    modifier nft721IsInitialized(bytes32 _did)
    {
        require(
            didRegisterList.didRegisters[_did].nft721Initialized,
            'NFT721 not initialized'
        );
        _;
    }    
    
    //////////////////////////////////////////////////////////////
    ////////  EVENTS  ////////////////////////////////////////////
    //////////////////////////////////////////////////////////////

    /**
     * DID Events
     */
    event DIDAttributeRegistered(
        bytes32 indexed _did,
        address indexed _owner,
        bytes32 indexed _checksum,
        string _value,
        address _lastUpdatedBy,
        uint256 _blockNumberUpdated
    );

    event DIDProviderRemoved(
        bytes32 _did,
        address _provider,
        bool state
    );

    event DIDProviderAdded(
        bytes32 _did,
        address _provider
    );

    event DIDOwnershipTransferred(
        bytes32 _did,
        address _previousOwner,
        address _newOwner
    );

    event DIDPermissionGranted(
        bytes32 indexed _did,
        address indexed _owner,
        address indexed _grantee
    );

    event DIDPermissionRevoked(
        bytes32 indexed _did,
        address indexed _owner,
        address indexed _grantee
    );

    event DIDProvenanceDelegateRemoved(
        bytes32 _did,
        address _delegate,
        bool state
    );

    event DIDProvenanceDelegateAdded(
        bytes32 _did,
        address _delegate
    );

    /**
     * Sets the manager role. Should be the TransferCondition contract address
     */
    function setManager(address _addr) external onlyOwner {
        manager = _addr;
    }

    /**
     * @notice Register DID attributes.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID). 
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _url refers to the attribute value, limited to 2048 bytes.
     */
    function registerAttribute(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url
    )
    public
    virtual
    {
        registerDID(_didSeed, _checksum, _providers, _url, '', '');
    }


    /**
     * @notice Register DID attributes.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID). 
     *          The final DID will be calculated with the creator address using the `hashDID` function
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _providers list of DID providers addresses
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes     
     */
    function registerDID(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        bytes32 _activityId,
        string memory _attributes
    )
    public
    virtual
    onlyValidAttributes(_attributes)
    {
        bytes32 _did = hashDID(_didSeed, msg.sender);
        require(
            didRegisterList.didRegisters[_did].owner == address(0x0) ||
            didRegisterList.didRegisters[_did].owner == msg.sender,
            'Only DID Owners or not registered DID'
        );

        didRegisterList.update(_did, _checksum, _url);

        // push providers to storage
        for (uint256 i = 0; i < _providers.length; i++) {
            didRegisterList.addProvider(
                _did,
                _providers[i]
            );
        }

        emit DIDAttributeRegistered(
            _did,
            didRegisterList.didRegisters[_did].owner,
            _checksum,
            _url,
            msg.sender,
            block.number
        );
        
        _wasGeneratedBy(_did, _did, msg.sender, _activityId, _attributes);

    }

    /**
     * @notice It generates a DID using as seed a bytes32 and the address of the DID creator
     * @param _didSeed refers to DID Seed used as base to generate the final DID
     * @param _creator address of the creator of the DID     
     * @return the new DID created
    */
    function hashDID(
        bytes32 _didSeed, 
        address _creator
    ) 
    public 
    pure 
    returns (bytes32) 
    {
        return keccak256(abi.encode(_didSeed, _creator));
    }
    
    /**
     * @notice areRoyaltiesValid checks if for a given DID and rewards distribution, this allocate the  
     * original creator royalties properly
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _amounts refers to the amounts to reward
     * @param _receivers refers to the receivers of rewards
     * @return true if the rewards distribution respect the original creator royalties
     */
    function areRoyaltiesValid(     
        bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.areRoyaltiesValid(_did, _amounts, _receivers, _tokenAddress);
    }
    
    function wasGeneratedBy(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    onlyDIDOwner(_did)
    returns (bool)
    {
        return _wasGeneratedBy(_provId, _did, _agentId, _activityId, _attributes);
    }

    
    function used(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        bytes memory _signatureUsing,    
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    returns (bool success)
    {
        return _used(
            _provId, _did, _agentId, _activityId, _signatureUsing, _attributes);
    }
    
    
    function wasDerivedFrom(
        bytes32 _provId,
        bytes32 _newEntityDid,
        bytes32 _usedEntityDid,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_usedEntityDid)
    returns (bool success)
    {
        return _wasDerivedFrom(
            _provId, _newEntityDid, _usedEntityDid, _agentId, _activityId, _attributes);
    }

    
    function wasAssociatedWith(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    returns (bool success)
    {
        return _wasAssociatedWith(
            _provId, _did, _agentId, _activityId, _attributes);
    }

    
    /**
     * @notice Implements the W3C PROV Delegation action
     * Each party involved in this method (_delegateAgentId & _responsibleAgentId) must provide a valid signature.
     * The content to sign is a representation of the footprint of the event (_did + _delegateAgentId + _responsibleAgentId + _activityId) 
     *
     * @param _provId unique identifier referring to the provenance entry
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _delegateAgentId refers to address acting on behalf of the provenance record
     * @param _responsibleAgentId refers to address responsible of the provenance record
     * @param _activityId refers to activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate.     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function actedOnBehalf(
        bytes32 _provId,
        bytes32 _did,
        address _delegateAgentId,
        address _responsibleAgentId,
        bytes32 _activityId,
        bytes memory _signatureDelegate,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    returns (bool success)
    {
        _actedOnBehalf(
            _provId, _did, _delegateAgentId, _responsibleAgentId, _activityId, _signatureDelegate, _attributes);
        addDIDProvenanceDelegate(_did, _delegateAgentId);
        return true;
    }
    
    
    /**
     * @notice addDIDProvider add new DID provider.
     *
     * @dev it adds new DID provider to the providers list. A provider
     *      is any entity that can serve the registered asset
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function addDIDProvider(
        bytes32 _did,
        address _provider
    )
    external
    onlyDIDOwner(_did)
    {
        didRegisterList.addProvider(_did, _provider);

        emit DIDProviderAdded(
            _did,
            _provider
        );
    }

    /**
     * @notice removeDIDProvider delete an existing DID provider.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function removeDIDProvider(
        bytes32 _did,
        address _provider
    )
    external
    onlyDIDOwner(_did)
    {
        bool state = didRegisterList.removeProvider(_did, _provider);

        emit DIDProviderRemoved(
            _did,
            _provider,
            state
        );
    }

    /**
     * @notice addDIDProvenanceDelegate add new DID provenance delegate.
     *
     * @dev it adds new DID provenance delegate to the delegates list. 
     * A delegate is any entity that interact with the provenance entries of one DID
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegates's address.
     */
    function addDIDProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    {
        didRegisterList.addDelegate(_did, _delegate);

        emit DIDProvenanceDelegateAdded(
            _did,
            _delegate
        );
    }

    /**
     * @notice removeDIDProvenanceDelegate delete an existing DID delegate.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegate's address.
     */
    function removeDIDProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    external
    onlyOwnerProviderOrDelegated(_did)
    {
        bool state = didRegisterList.removeDelegate(_did, _delegate);

        emit DIDProvenanceDelegateRemoved(
            _did,
            _delegate,
            state
        );
    }


    /**
     * @notice transferDIDOwnership transfer DID ownership
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _newOwner new owner address
     */
    function transferDIDOwnership(bytes32 _did, address _newOwner)
    external
    {
        _transferDIDOwnership(msg.sender, _did, _newOwner);
    }

    /**
     * @notice transferDIDOwnershipManaged transfer DID ownership
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _newOwner new owner address
     */
    function transferDIDOwnershipManaged(address _sender, bytes32 _did, address _newOwner)
    external
    onlyManager
    {
        _transferDIDOwnership(_sender, _did, _newOwner);
    }

    function _transferDIDOwnership(address _sender, bytes32 _did, address _newOwner) internal
    {
        require(isDIDOwner(_sender, _did), 'Only owner');

        didRegisterList.updateDIDOwner(_did, _newOwner);

        _wasAssociatedWith(
            keccak256(abi.encode(_did, _sender, 'transferDID', _newOwner, block.number)),
            _did, _newOwner, keccak256('transferDID'), 'transferDID');
        
        emit DIDOwnershipTransferred(
            _did, 
            _sender,
            _newOwner
        );
    }

    /**
     * @dev grantPermission grants access permission to grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function grantPermission(
        bytes32 _did,
        address _grantee
    )
    external
    onlyDIDOwner(_did)
    {
        _grantPermission(_did, _grantee);
    }

    /**
     * @dev revokePermission revokes access permission from grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function revokePermission(
        bytes32 _did,
        address _grantee
    )
    external
    onlyDIDOwner(_did)
    {
        _revokePermission(_did, _grantee);
    }

    /**
     * @dev getPermission gets access permission of a grantee
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address
     * @return true if grantee has access permission to a DID
     */
    function getPermission(
        bytes32 _did,
        address _grantee
    )
    external
    view
    returns(bool)
    {
        return _getPermission(_did, _grantee);
    }

    /**
     * @notice isDIDProvider check whether a given DID provider exists
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function isDIDProvider(
        bytes32 _did,
        address _provider
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isProvider(_did, _provider);
    }

    function isDIDProviderOrOwner(
        bytes32 _did,
        address _provider
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isProvider(_did, _provider) || _provider == getDIDOwner(_did);
    }

    /**
    * @param _did refers to decentralized identifier (a bytes32 length ID).
    * @return owner the did owner
    * @return lastChecksum last checksum
    * @return url URL to the DID metadata
    * @return lastUpdatedBy who was the last updating the DID
    * @return blockNumberUpdated In which block was the DID updated
    * @return providers the list of providers
    * @return nftSupply the supply of nfts
    * @return mintCap the maximum number of nfts that can be minted
    * @return royalties the royalties amount
    */
    function getDIDRegister(
        bytes32 _did
    )
    public
    view
    returns (
        address owner,
        bytes32 lastChecksum,
        string memory url,
        address lastUpdatedBy,
        uint256 blockNumberUpdated,
        address[] memory providers,
        uint256 nftSupply,
        uint256 mintCap,
        uint256 royalties
    )
    {
        owner = didRegisterList.didRegisters[_did].owner;
        lastChecksum = didRegisterList.didRegisters[_did].lastChecksum;
        url = didRegisterList.didRegisters[_did].url;
        lastUpdatedBy = didRegisterList.didRegisters[_did].lastUpdatedBy;
        blockNumberUpdated = didRegisterList
            .didRegisters[_did].blockNumberUpdated;
        providers = didRegisterList.didRegisters[_did].providers;
        nftSupply = didRegisterList.didRegisters[_did].nftSupply;
        mintCap = didRegisterList.didRegisters[_did].mintCap;
        royalties = didRegisterList.didRegisters[_did].royalties;
    }

    function getDIDSupply(
        bytes32 _did
    )
    public
    view
    returns (
        uint256 nftSupply,
        uint256 mintCap
    )
    {
        nftSupply = didRegisterList.didRegisters[_did].nftSupply;
        mintCap = didRegisterList.didRegisters[_did].mintCap;
    }
    
    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return blockNumberUpdated last modified (update) block number of a DID.
     */
    function getBlockNumberUpdated(bytes32 _did)
    public
    view
    returns (uint256 blockNumberUpdated)
    {
        return didRegisterList.didRegisters[_did].blockNumberUpdated;
    }

    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return didOwner the address of the DID owner.
     */
    function getDIDOwner(bytes32 _did)
    public
    view
    returns (address didOwner)
    {
        return didRegisterList.didRegisters[_did].owner;
    }

    function getDIDRoyaltyRecipient(bytes32 _did)
    public
    view
    returns (address)
    {
        address res = didRegisterList.didRegisters[_did].royaltyRecipient;
        if (res == address(0)) {
            return didRegisterList.didRegisters[_did].creator;
        }
        return res;
    }

    function getDIDRoyaltyScheme(bytes32 _did)
    public
    view
    returns (address)
    {
        return address(didRegisterList.didRegisters[_did].royaltyScheme);
    }

    function getDIDCreator(bytes32 _did)
    public
    view
    returns (address)
    {
        return didRegisterList.didRegisters[_did].creator;
    }

    /**
     * @dev _grantPermission grants access permission to grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function _grantPermission(
        bytes32 _did,
        address _grantee
    )
    internal
    {
        require(
            _grantee != address(0),
            'Invalid grantee'
        );
        didPermissions[_did][_grantee] = true;
        emit DIDPermissionGranted(
            _did,
            msg.sender,
            _grantee
        );
    }

    /**
     * @dev _revokePermission revokes access permission from grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function _revokePermission(
        bytes32 _did,
        address _grantee
    )
    internal
    {
        require(
            didPermissions[_did][_grantee],
            'Grantee already revoked'
        );
        didPermissions[_did][_grantee] = false;
        emit DIDPermissionRevoked(
            _did,
            msg.sender,
            _grantee
        );
    }

    /**
     * @dev _getPermission gets access permission of a grantee
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     * @return true if grantee has access permission to a DID 
     */
    function _getPermission(
        bytes32 _did,
        address _grantee
    )
    internal
    view
    returns(bool)
    {
        return didPermissions[_did][_grantee];
    }


    //// PROVENANCE SUPPORT METHODS

    /**
     * Fetch the complete provenance entry attributes
     * @param _provId refers to the provenance identifier
     * @return did to what DID refers this entry
     * @return relatedDid DID related with the entry
     * @return agentId the agent identifier
     * @return activityId referring to the id of the activity
     * @return agentInvolvedId agent involved with the action
     * @return method the w3c provenance method
     * @return createdBy who is creating this entry
     * @return blockNumberUpdated in which block was updated
     * @return signature digital signature 
     * 
     */
    function getProvenanceEntry(
        bytes32 _provId
    )
    public
    view
    returns (     
        bytes32 did,
        bytes32 relatedDid,
        address agentId,
        bytes32 activityId,
        address agentInvolvedId,
        uint8   method,
        address createdBy,
        uint256 blockNumberUpdated,
        bytes memory signature
    )
    {
        did = provenanceRegistry.list[_provId].did;
        relatedDid = provenanceRegistry.list[_provId].relatedDid;
        agentId = provenanceRegistry.list[_provId].agentId;
        activityId = provenanceRegistry.list[_provId].activityId;
        agentInvolvedId = provenanceRegistry.list[_provId].agentInvolvedId;
        method = provenanceRegistry.list[_provId].method;
        createdBy = provenanceRegistry.list[_provId].createdBy;
        blockNumberUpdated = provenanceRegistry
            .list[_provId].blockNumberUpdated;
        signature = provenanceRegistry.list[_provId].signature;
    }

    /**
     * @notice isDIDOwner check whether a given address is owner for a DID
     * @param _address user address.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     */
    function isDIDOwner(
        address _address,
        bytes32 _did
    )
    public
    view
    returns (bool)
    {
        return _address == didRegisterList.didRegisters[_did].owner;
    }


    /**
     * @notice isOwnerProviderOrDelegate check whether msg.sender is owner, provider or
     * delegate for a DID given
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return boolean true if yes
     */
    function isOwnerProviderOrDelegate(
        bytes32 _did
    )
    public
    view
    returns (bool)
    {
        return (msg.sender == didRegisterList.didRegisters[_did].owner ||
                    isProvenanceDelegate(_did, msg.sender) ||
                    isDIDProvider(_did, msg.sender));
    }    
    
    /**
     * @notice isProvenanceDelegate check whether a given DID delegate exists
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegate's address.
     * @return boolean true if yes     
     */
    function isProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isDelegate(_did, _delegate);
    }

    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return provenanceOwner the address of the Provenance owner.
     */
    function getProvenanceOwner(bytes32 _did)
    public
    view
    returns (address provenanceOwner)
    {
        return provenanceRegistry.list[_did].createdBy;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '../NFTBase.sol';

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 */
contract NFTUpgradeable is ERC1155Upgradeable, NFTBase {
    
    /**
     * @dev See {_setURI}.
     */
    // solhint-disable-next-line
    function initialize(string memory uri_) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
        __Ownable_init_unchained();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(MINTER_ROLE, msg.sender);
        setContractMetadataUri(uri_);
    }
    
    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(account, operator) || _proxyApprovals[operator];
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter can mint');
        _mint(to, id, amount, data);
    }

    function burn(address to, uint256 id, uint256 amount) public {
        require(balanceOf(to, id) >= amount, 'ERC1155: burn amount exceeds balance');
        require(
            hasRole(MINTER_ROLE, _msgSender()) || // Or the DIDRegistry is burning the NFT 
            to == _msgSender() || // Or the NFT owner is msg.sender 
            isApprovedForAll(to, _msgSender()), // Or the msg.sender is approved
            'ERC1155: caller is not owner nor approved'
        );
        _burn(to, id, amount);
    }

    function addMinter(address account) public onlyOwner {
        AccessControlUpgradeable._setupRole(MINTER_ROLE, account);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _metadata[tokenId].nftURI;
    }

  
    
    /**
    * @dev Record some NFT Metadata
    * @param tokenId the id of the asset with the royalties associated
    * @param nftURI the URI (https, ipfs, etc) to the metadata describing the NFT
    */
    function setNFTMetadata(
        uint256 tokenId,
        string memory nftURI
    )
    public
    {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter');
        _setNFTMetadata(tokenId, nftURI);
    }    
    
    /**
    * @dev Record the asset royalties
    * @param tokenId the id of the asset with the royalties associated
    * @param receiver the receiver of the royalties (the original creator)
    * @param royaltyAmount percentage (no decimals, between 0 and 100)    
    */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    ) 
    public
    {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter');
        _setTokenRoyalty(tokenId, receiver, royaltyAmount);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) 
    public 
    view 
    virtual 
    override(ERC1155Upgradeable, IERC165Upgradeable) 
    returns (bool) 
    {
        return AccessControlUpgradeable.supportsInterface(interfaceId)
        || ERC1155Upgradeable.supportsInterface(interfaceId)
        || interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '../NFTBase.sol';

/**
 *
 * @dev Implementation of the basic standard multi-token.
 */
contract NFT721Upgradeable is ERC721Upgradeable, NFTBase {

    // solhint-disable-next-line
    function initializeWithName(
        string memory name, 
        string memory symbol,
        string memory uri
    ) 
    public 
    virtual 
    initializer 
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __Ownable_init_unchained();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(MINTER_ROLE, msg.sender);
        setContractMetadataUri(uri);
    }

    // solhint-disable-next-line
    function initialize()
    public
    virtual
    initializer
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained('', '');
        __Ownable_init_unchained();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(MINTER_ROLE, msg.sender);
    }    
    
    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account, 
        address operator
    ) 
    public 
    view 
    virtual 
    override 
    returns (bool) 
    {
        return super.isApprovedForAll(account, operator) || _proxyApprovals[operator];
    }
    
    function addMinter(
        address account
    ) 
    public 
    onlyOwner 
    {
        AccessControlUpgradeable._setupRole(MINTER_ROLE, account);
    }    
    
    function mint(
        address to, 
        uint256 id
    ) 
    public 
    virtual 
    {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter can mint');
        _mint(to, id);
    }

    function burn(
        uint256 id
    ) 
    public 
    {
        require(
            hasRole(MINTER_ROLE, msg.sender) || // Or the DIDRegistry is burning the NFT 
            balanceOf(msg.sender) > 0, // Or the msg.sender is owner and have balance
            'ERC721: caller is not owner or not have balance'
        );        
        _burn(id);
    }
    
    function tokenURI(
        uint256 tokenId
    ) 
    public 
    virtual 
    view 
    override 
    returns (string memory) 
    {
        return _metadata[tokenId].nftURI;
    }
    
    /**
    * @dev Record some NFT Metadata
    * @param tokenId the id of the asset with the royalties associated
    * @param nftURI the URI (https, ipfs, etc) to the metadata describing the NFT
    */
    function setNFTMetadata(
        uint256 tokenId,
        string memory nftURI
    )
    public
    {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter');
        _setNFTMetadata(tokenId, nftURI);
    }

    /**
    * @dev Record the asset royalties
    * @param tokenId the id of the asset with the royalties associated
    * @param receiver the receiver of the royalties (the original creator)
    * @param royaltyAmount percentage (no decimals, between 0 and 100)    
    */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    )
    public
    {
        require(hasRole(MINTER_ROLE, msg.sender), 'only minter');
        _setTokenRoyalty(tokenId, receiver, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) 
    public 
    view 
    virtual 
    override(ERC721Upgradeable, IERC165Upgradeable) 
    returns (bool) 
    {
        return AccessControlUpgradeable.supportsInterface(interfaceId)
        || ERC721Upgradeable.supportsInterface(interfaceId)
        || interfaceId == type(IERC2981Upgradeable).interfaceId;
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

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

/**
 * @title Interface for different royalty schemes.
 * @author Nevermined
 */
interface IRoyaltyScheme {
    /**
     * @notice check that royalties are correct
     * @param _did compute royalties for this DID
     * @param _amounts amounts in payment
     * @param _receivers receivers of payments
     * @param _tokenAddress payment token. zero address means native token (ether)
     */
    function check(bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress) external view returns (bool);
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

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../governance/INVMConfig.sol';

/**
 * @title Provenance Registry Library
 * @author Nevermined
 *
 * @dev All function calls are currently implemented without side effects
 */
/* solium-disable-next-line */
abstract contract ProvenanceRegistry is OwnableUpgradeable {

    // solhint-disable-next-line
    function __ProvenanceRegistry_init() internal initializer {
        __Context_init_unchained();
        __ProvenanceRegistry_init_unchained();
    }

    // solhint-disable-next-line
    function __ProvenanceRegistry_init_unchained() internal initializer {
    }
    
    // Provenance Entity
    struct Provenance {
        // DID associated to this provenance event
        bytes32 did;
        // DID created or associated to the original one triggered on this provenance event
        bytes32 relatedDid;
        // Agent associated to the provenance event
        address agentId;
        // Provenance activity
        bytes32 activityId;
        // Agent involved in the provenance event beyond the agent id
        address agentInvolvedId;
        // W3C PROV method
        uint8   method;
        // Who added this event to the registry
        address createdBy;
        // Block number of when it was added
        uint256 blockNumberUpdated;
        // Signature of the delegate
        bytes   signature;  
    }

    // List of Provenance entries registered in the system
    struct ProvenanceRegistryList {
        mapping(bytes32 => Provenance) list;
    }
    
    ProvenanceRegistryList internal provenanceRegistry;
    
    // W3C Provenance Methods
    enum ProvenanceMethod {
        ENTITY,
        ACTIVITY,
        WAS_GENERATED_BY,
        USED,
        WAS_INFORMED_BY,
        WAS_STARTED_BY,
        WAS_ENDED_BY,
        WAS_INVALIDATED_BY,
        WAS_DERIVED_FROM,
        AGENT,
        WAS_ATTRIBUTED_TO,
        WAS_ASSOCIATED_WITH,
        ACTED_ON_BEHALF
    }

    /**
    * Provenance Events
    */
    event ProvenanceAttributeRegistered(
        bytes32 indexed provId,
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 _activityId,
        bytes32 _relatedDid,
        address _agentInvolvedId,
        ProvenanceMethod _method,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    ///// EVENTS ///////
    
    event WasGeneratedBy(
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );


    event Used(
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event WasDerivedFrom(
        bytes32 indexed _newEntityDid,
        bytes32 indexed _usedEntityDid,
        address indexed _agentId,
        bytes32 _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event WasAssociatedWith(
        bytes32 indexed _entityDid,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event ActedOnBehalf(
        bytes32 indexed _entityDid,
        address indexed _delegateAgentId,
        address indexed _responsibleAgentId,
        bytes32 _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    function _provenanceStorage() virtual internal returns (bool);

    /**
     * @notice create an event in the Provenance store
     * @dev access modifiers and storage pointer should be implemented in ProvenanceRegistry
     * @param _provId refers to provenance event identifier
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _relatedDid refers to decentralized identifier (a byte32 length ID) of a related entity
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _agentInvolvedId refers to address of the agent involved with the provenance record     
     * @param _method refers to the W3C Provenance method
     * @param _createdBy refers to address of the agent triggering the activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate. 
    */
    function createProvenanceEntry(
        bytes32 _provId,
        bytes32 _did,
        bytes32 _relatedDid,
        address _agentId,
        bytes32 _activityId,
        address _agentInvolvedId,
        ProvenanceMethod   _method,
        address _createdBy,
        bytes  memory _signatureDelegate,
        string memory _attributes
    )
    internal
    {

        if (!_provenanceStorage()) {
            return;
        }

        require(
            provenanceRegistry.list[_provId].createdBy == address(0x0),
            'Already existing provId'
        );

        provenanceRegistry.list[_provId] = Provenance({
            did: _did,
            relatedDid: _relatedDid,
            agentId: _agentId,
            activityId: _activityId,
            agentInvolvedId: _agentInvolvedId,
            method: uint8(_method),
            createdBy: _createdBy,
            blockNumberUpdated: block.number,
            signature: _signatureDelegate
        });

        /* emitting _attributes here to avoid expensive storage */
        emit ProvenanceAttributeRegistered(
            _provId,
            _did, 
            _agentId,
            _activityId,
            _relatedDid,
            _agentInvolvedId,
            _method,
            _attributes,
            block.number
        );
        
    }


    /**
     * @notice Implements the W3C PROV Generation action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return the number of the new provenance size
     */
    function _wasGeneratedBy(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool)
    {
        
        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_GENERATED_BY,
            msg.sender,
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasGeneratedBy(
            _did,
           msg.sender,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Usage action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _signatureUsing refers to the digital signature provided by the agent using the _did     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
    */
    function _used(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        bytes memory _signatureUsing,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.USED,
            msg.sender,
            _signatureUsing,
            _attributes
        );
        
        emit Used(
            _did,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }


    /**
     * @notice Implements the W3C PROV Derivation action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _newEntityDid refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _usedEntityDid refers to decentralized identifier (a bytes32 length ID) of the entity used to derive the new did
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function _wasDerivedFrom(
        bytes32 _provId,
        bytes32 _newEntityDid,
        bytes32 _usedEntityDid,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _newEntityDid,
            _usedEntityDid,
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_DERIVED_FROM,
            msg.sender,
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasDerivedFrom(
            _newEntityDid,
            _usedEntityDid,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Association action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
    */
    function _wasAssociatedWith(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {
        
        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_ASSOCIATED_WITH,
            msg.sender,
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasAssociatedWith(
            _did,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Delegation action
     * Each party involved in this method (_delegateAgentId & _responsibleAgentId) must provide a valid signature.
     * The content to sign is a representation of the footprint of the event (_did + _delegateAgentId + _responsibleAgentId + _activityId) 
     *
     * @param _provId unique identifier referring to the provenance entry
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _delegateAgentId refers to address acting on behalf of the provenance record
     * @param _responsibleAgentId refers to address responsible of the provenance record
     * @param _activityId refers to activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate.     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function _actedOnBehalf(
        bytes32 _provId,
        bytes32 _did,
        address _delegateAgentId,
        address _responsibleAgentId,
        bytes32 _activityId,
        bytes memory _signatureDelegate,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _did,
            '',
            _delegateAgentId,
            _activityId,
            _responsibleAgentId,
            ProvenanceMethod.ACTED_ON_BEHALF,
            msg.sender,
            _signatureDelegate,
            _attributes
        );
        
        emit ActedOnBehalf(
            _did,
            _delegateAgentId,
            _responsibleAgentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '../interfaces/IRoyaltyScheme.sol';

/**
 * @title DID Registry Library
 * @author Nevermined
 *
 * @dev All function calls are currently implemented without side effects
 */
library DIDRegistryLibrary {

    using SafeMathUpgradeable for uint256;

    // DIDRegistry Entity
    struct DIDRegister {
        // DIDRegistry entry owner
        address owner;
        // The percent of the sale that is going back to the original `creator` in the secondary market  
        uint8 royalties;
        // Flag to control if NFTs config was already initialized
        bool nftInitialized;
        // Flag to control if NFTs config was already initialized (erc 721)
        bool nft721Initialized;
        // DIDRegistry original creator, this can't be modified after the asset is registered 
        address creator;
        // Checksum associated to the DID
        bytes32 lastChecksum;
        // URL to the metadata associated to the DID
        string  url;
        // Who was the last one updated the entry
        address lastUpdatedBy;
        // When was the last time was updated
        uint256 blockNumberUpdated;
        // Providers able to manage this entry
        address[] providers;
        // Delegates able to register provenance events on behalf of the owner or providers
        address[] delegates;
        // The NFTs supply associated to the DID 
        uint256 nftSupply;
        // The max number of NFTs associated to the DID that can be minted 
        uint256 mintCap;
        address royaltyRecipient;
        IRoyaltyScheme royaltyScheme;
    }

    // List of DID's registered in the system
    struct DIDRegisterList {
        mapping(bytes32 => DIDRegister) didRegisters;
        bytes32[] didRegisterIds; // UNUSED
    }

    /**
     * @notice update the DID store
     * @dev access modifiers and storage pointer should be implemented in DIDRegistry
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _checksum includes a one-way HASH calculated using the DDO content
     * @param _url includes the url resolving to the DID Document (DDO)
     */
    function update(
        DIDRegisterList storage _self,
        bytes32 _did,
        bytes32 _checksum,
        string calldata _url
    )
    external
    {
        address didOwner = _self.didRegisters[_did].owner;
        address creator = _self.didRegisters[_did].creator;
        
        if (didOwner == address(0)) {
            didOwner = msg.sender;
            creator = didOwner;
        }

        _self.didRegisters[_did].owner = didOwner;
        _self.didRegisters[_did].creator = creator;
        _self.didRegisters[_did].lastChecksum = _checksum;
        _self.didRegisters[_did].url = _url;
        _self.didRegisters[_did].lastUpdatedBy = msg.sender;
        _self.didRegisters[_did].owner = didOwner;
        _self.didRegisters[_did].blockNumberUpdated = block.number;
    }

    /**
     * @notice initializeNftConfig creates the initial setup of NFTs minting and royalties distribution.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created. 
     * @dev update the DID registry providers list by adding the mintCap and royalties configuration
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _cap refers to the mint cap
     * @param _royaltyHandler contract for handling royalties
     */
    function initializeNftConfig(
        DIDRegisterList storage _self,
        bytes32 _did,
        uint256 _cap,
        IRoyaltyScheme _royaltyHandler
    )
    internal
    {
        require(_self.didRegisters[_did].owner != address(0), 'DID not stored');
        
        require(!_self.didRegisters[_did].nftInitialized, 'NFT already initialized');
        
        _self.didRegisters[_did].mintCap = _cap;
        _self.didRegisters[_did].royaltyScheme = _royaltyHandler;
        _self.didRegisters[_did].nftInitialized = true;
    }

    function initializeNft721Config(
        DIDRegisterList storage _self,
        bytes32 _did,
        IRoyaltyScheme _royaltyHandler
    )
    internal
    {
        require(_self.didRegisters[_did].owner != address(0), 'DID not stored');
        
        require(!_self.didRegisters[_did].nft721Initialized, 'NFT already initialized');
        
        _self.didRegisters[_did].royaltyScheme = _royaltyHandler;
        _self.didRegisters[_did].nft721Initialized = true;
    }


    /**
     * @notice areRoyaltiesValid checks if for a given DID and rewards distribution, this allocate the  
     * original creator royalties properly
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _amounts refers to the amounts to reward
     * @param _receivers refers to the receivers of rewards
     * @return true if the rewards distribution respect the original creator royalties
     */
    function areRoyaltiesValid(
        DIDRegisterList storage _self,
        bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress
    )
    internal
    view
    returns (bool)
    {
        if (address(_self.didRegisters[_did].royaltyScheme) != address(0)) {
            return _self.didRegisters[_did].royaltyScheme.check(_did, _amounts, _receivers, _tokenAddress);
        }
        // If there are no royalties everything is good
        if (_self.didRegisters[_did].royalties == 0) {
            return true;
        }

        // If (sum(_amounts) == 0) - It means there is no payment so everything is valid
        // returns true;
        uint256 _totalAmount = 0;
        for(uint i = 0; i < _amounts.length; i++)
            _totalAmount = _totalAmount.add(_amounts[i]);
        if (_totalAmount == 0)
            return true;
        
        // If (_did.creator is not in _receivers) - It means the original creator is not included as part of the payment
        // return false;
        address recipient = _self.didRegisters[_did].creator;
        if (_self.didRegisters[_did].royaltyRecipient != address(0)) {
            recipient = _self.didRegisters[_did].royaltyRecipient;
        }
        bool found = false;
        uint256 index;
        for (index = 0; index < _receivers.length; index++) {
            if (recipient == _receivers[index])  {
                found = true;
                break;
            }
        }

        // The creator royalties are not part of the rewards
        if (!found) {
            return false;
        }

        // If the amount to receive by the creator is lower than royalties the calculation is not valid
        // return false;
        uint256 _requiredRoyalties = ((_totalAmount.mul(_self.didRegisters[_did].royalties)) / 100);

        // Check if royalties are enough
        // Are we paying enough royalties in the secondary market to the original creator?
        return (_amounts[index] >= _requiredRoyalties);
    }


    /**
     * @notice addProvider add provider to DID registry
     * @dev update the DID registry providers list by adding a new provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param provider the provider's address 
     */
    function addProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address provider
    )
    internal
    {
        require(
            provider != address(0) && provider != address(this),
            'Invalid provider'
        );
        
        if (!isProvider(_self, _did, provider)) {
            _self.didRegisters[_did].providers.push(provider);
        }

    }

    /**
     * @notice removeProvider remove provider from DID registry
     * @dev update the DID registry providers list by removing an existing provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _provider the provider's address 
     */
    function removeProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _provider
    )
    internal
    returns(bool)
    {
        require(
            _provider != address(0),
            'Invalid provider'
        );

        int256 i = getProviderIndex(_self, _did, _provider);

        if (i == -1) {
            return false;
        }

        delete _self.didRegisters[_did].providers[uint256(i)];

        return true;
    }

    /**
     * @notice updateDIDOwner transfer DID ownership to a new owner
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _newOwner the new DID owner address
     */
    function updateDIDOwner(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _newOwner
    )
    internal
    {
        require(_newOwner != address(0));
        _self.didRegisters[_did].owner = _newOwner;
    }

    /**
     * @notice isProvider check whether DID provider exists
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _provider the provider's address 
     * @return true if the provider already exists
     */
    function isProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _provider
    )
    public
    view
    returns(bool)
    {
        if (getProviderIndex(_self, _did, _provider) == -1)
            return false;
        return true;
    }


    
    /**
     * @notice getProviderIndex get the index of a provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param provider the provider's address 
     * @return the index if the provider exists otherwise return -1
     */
    function getProviderIndex(
        DIDRegisterList storage _self,
        bytes32 _did,
        address provider
    )
    private
    view
    returns(int256 )
    {
        for (uint256 i = 0;
            i < _self.didRegisters[_did].providers.length; i++) {
            if (provider == _self.didRegisters[_did].providers[i]) {
                return int(i);
            }
        }

        return - 1;
    }

    //////////// DELEGATE METHODS

    /**
     * @notice addDelegate add delegate to DID registry
     * @dev update the DID registry delegates list by adding a new delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param delegate the delegate's address 
     */
    function addDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address delegate
    )
    internal
    {
        require(delegate != address(0) && delegate != address(this));

        if (!isDelegate(_self, _did, delegate)) {
            _self.didRegisters[_did].delegates.push(delegate);
        }

    }

    /**
     * @notice removeDelegate remove delegate from DID registry
     * @dev update the DID registry delegates list by removing an existing delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _delegate the delegate's address 
     */
    function removeDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _delegate
    )
    internal
    returns(bool)
    {
        require(_delegate != address(0));

        int256 i = getDelegateIndex(_self, _did, _delegate);

        if (i == -1) {
            return false;
        }

        delete _self.didRegisters[_did].delegates[uint256(i)];

        return true;
    }

    /**
     * @notice isDelegate check whether DID delegate exists
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _delegate the delegate's address 
     * @return true if the delegate already exists
     */
    function isDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _delegate
    )
    public
    view
    returns(bool)
    {
        if (getDelegateIndex(_self, _did, _delegate) == -1)
            return false;
        return true;
    }

    /**
     * @notice getDelegateIndex get the index of a delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param delegate the delegate's address 
     * @return the index if the delegate exists otherwise return -1
     */
    function getDelegateIndex(
        DIDRegisterList storage _self,
        bytes32 _did,
        address delegate
    )
    private
    view
    returns(int256)
    {
        for (uint256 i = 0;
            i < _self.didRegisters[_did].delegates.length; i++) {
            if (delegate == _self.didRegisters[_did].delegates[i]) {
                return int(i);
            }
        }

        return - 1;
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

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';

/**
 *
 * @dev Implementation of the Royalties EIP-2981 base contract
 * See https://eips.ethereum.org/EIPS/eip-2981
 */
abstract contract NFTBase is IERC2981Upgradeable, OwnableUpgradeable, AccessControlUpgradeable {

    // Mapping from account to proxy approvals
    mapping (address => bool) internal _proxyApprovals;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');    
    
    struct RoyaltyInfo {
        address receiver;
        uint256 royaltyAmount;
    }
    
    struct NFTMetadata {
        string nftURI;
    }
    
    // Mapping of Royalties per tokenId (DID)
    mapping(uint256 => RoyaltyInfo) internal _royalties;
    // Mapping of NFT Metadata object per tokenId (DID)
    mapping(uint256 => NFTMetadata) internal _metadata;
    // Mapping of expiration block number per user (subscription NFT holder)
    mapping(address => uint256) internal _expiration;

    // Used as a URL where is stored the Metadata describing the NFT contract
    string private _contractMetadataUri;
    
    /** 
     * Event for recording proxy approvals.
     */
    event ProxyApproval(address sender, address operator, bool approved);
    
    function setProxyApproval(
        address operator, 
        bool approved
    ) 
    public 
    onlyOwner 
    virtual 
    {
        _proxyApprovals[operator] = approved;
        emit ProxyApproval(_msgSender(), operator, approved);
    }

    function _setNFTMetadata(
        uint256 tokenId,
        string memory tokenURI
    )
    internal
    {
        _metadata[tokenId] = NFTMetadata(tokenURI);
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    )
    internal
    {
        require(royaltyAmount <= 1000000, 'ERC2981Royalties: Too high');
        _royalties[tokenId] = RoyaltyInfo(receiver, royaltyAmount);
    }    
    
    /**
     * @inheritdoc	IERC2981Upgradeable
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    )
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.receiver;
        royaltyAmount = (value * royalties.royaltyAmount) / 100;
    }

    /**
    * @dev Record the URI storing the Metadata describing the NFT Contract
    *      More information about the file format here: 
    *      https://docs.opensea.io/docs/contract-level-metadata
    * @param _uri the URI (https, ipfs, etc) to the metadata describing the NFT Contract    
    */    
    function setContractMetadataUri(
        string memory _uri
    )
    public
    onlyOwner
    virtual
    {
        _contractMetadataUri = _uri;
    }
    
    function contractURI()
    public
    view
    returns (string memory) {
        return _contractMetadataUri;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}