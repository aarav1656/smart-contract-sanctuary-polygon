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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IArenaOwner {

    function arenaOwner(uint256 tokenId) external view returns(address);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IPlatformAndArenaFee {
    
    function platformAndArenaFee(uint256 arenaId) external view returns(uint256);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IPlatformAndArenaFeeCurrency {
    
    function platformAndArenaFeeCurrency(uint256 arenaId) external view returns(address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;

        address platformAndArenaFeeCurrency;
        uint256 platformAndArenaFee;
        uint256 arenaMap;
        
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Hound.sol';


interface IHound {

    function hound(uint256 houndId) external view returns(Hound.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IHoundOwner {

    function houndOwner(uint256 tokenId) external view returns(address);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IRefreshStamina {

    function refreshStamina(uint256 houndId) external;

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IUpdateHoundRunning {

    function updateHoundRunning(uint256 houndId, uint256 runningOn) external returns(uint256 ranOn);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Hound {

    struct ConstructorBreeding {
        address externalBreedingFeeCurrency;
        address breedingCooldownCurrency;
        uint256 breedingCooldown;
        uint256 breedingCooldownTimeUnit;
        uint256 refillBreedingCooldownCost;
    }

    struct ConstructorStamina {
        address staminaRefillCurrency;
        uint256 staminaRefill1x;
        uint32 staminaPerTimeUnit;
        uint32 staminaCap;
    }

    struct Profile {
        string name;
        string token_uri;
        uint256 runningOn;
        bool custom;
    }

    struct Breeding {
        uint256 lastBreed;
        uint256 externalBreedingFee;
        bool availableToBreed;
    }

    struct Stamina {
        uint256 staminaLastUpdate;
        uint32 staminaValue;
    }

    struct Identity {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint256 specie;
        uint32[72] geneticSequence;
        string extensionTraits;
    }

    struct Struct {
        Stamina stamina;
        Breeding breeding;
        Identity identity;
        Profile profile;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Payment.sol';

interface IPay {

	function pay(
		address from,
        address to,
        address currency,
        uint256[] memory ids, // for batch transfers
        uint256[] memory amounts, // for batch transfers
        Payment.PaymentTypes paymentType
	) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library MicroPayment {
    
    struct Struct {
        address currency;
        uint256 amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Payment {

    enum PaymentTypes {
        ERC721,
        ERC1155,
        ERC20,
        DEFAULT
    }
    
    struct Struct {
        address[] from;
        address[] to;
        address[] currency;
        uint256[][] ids;
        uint256[][] amounts;
        PaymentTypes[] paymentType;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/MicroPayment.sol';

interface IGetEnqueueCost {

    function getEnqueueCost(uint256 queueId) external view returns(
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library QueuesConstructor {
    struct Struct {
        address[] operators;

        // Contract modules
        address methods;
        address restricted;
        address queues;
        address zerocost;

        // External dependencies
        address arenas;
        address hounds;
        address payments;
        address races;

        address raceUploader;
        bytes4[][] targets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';

library Core {
    
    struct Struct {

        string name;

        address feeCurrency;

        address raceEntryTicketCurrency;

        uint256[] participants;

        uint256[] enqueueDates;

        uint256 arena;

        uint256 raceEntryTicket;

        uint256 fee;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Queue.sol';
import './Constructor.sol';
import '../../arenas/params/Arena.sol';
import '../../arenas/interfaces/IArenaOwner.sol';
import '../../arenas/interfaces/IPlatformAndArenaFee.sol';
import '../../arenas/interfaces/IPlatformAndArenaFeeCurrency.sol';
import '../../payments/interfaces/IPay.sol';
import '../../payments/params/MicroPayment.sol';
import '../../hounds/interfaces/IUpdateHoundRunning.sol';
import '../../hounds/interfaces/IHoundOwner.sol';
import '../../hounds/interfaces/IHound.sol';
import '../../hounds/interfaces/IRefreshStamina.sol';
import '../../races/interfaces/IRaceStart.sol';
import '../../whitelist/Index.sol';
import '../../hounds/params/Hound.sol';
import '../interfaces/IGetEnqueueCost.sol';


contract Params is ReentrancyGuard, Whitelist {
    
    event QueuesCreation(uint256 indexed idStart, uint256 indexed idStop, Queue.Struct[] newQueues);
    event DeleteQueue(uint256 indexed id);
    event PlayerEnqueue(uint256 indexed id, uint256 indexed hound, address indexed player);
    event EditQueue(uint256 indexed id, Queue.Struct queue);
    event QueueClosed(uint256 indexed id);
    event Unenqueue(uint256 indexed id, uint256 indexed hound);

    uint256 public id = 1;
    QueuesConstructor.Struct public control;
    mapping(uint256 => Queue.Struct) public queues;

    constructor(QueuesConstructor.Struct memory input) Whitelist(input.operators, input.targets) {
        control = input;
    }

    function setGlobalParameters(QueuesConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
        updateWhitelist(globalParameters.operators, globalParameters.targets);
    }
    
    function queue(uint256 queueId) external view returns(Queue.Struct memory) {
        return queues[queueId];
    }

    function staminaCostOf(uint256 queueId) external view returns(uint32) {
        return queues[queueId].staminaCost;
    }

    function participantsOf(uint256 queueId) external view returns(uint256[] memory) {
        return queues[queueId].core.participants;
    }

    function enqueueDatesOf(uint256 queueId) external view returns(uint256[] memory) {
        return queues[queueId].core.enqueueDates;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import './Core.sol';


library Queue {
    
    struct Struct {

        Core.Struct core;

        uint256[] speciesAllowed;

        uint256 startDate;

        uint256 endDate;

        uint256 lastCompletion;

        uint32 totalParticipants;

        uint32 cooldown;

        uint32 staminaCost;

        bool closed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract QueuesRestricted is Params {

    constructor(QueuesConstructor.Struct memory input) Params(input) {}

    function createQueues(
        Queue.Struct[] memory createdQueues
    ) 
        external 
        whitelisted 
    {
        uint256 platformAndArenaFee;
        for ( uint256 i = 0 ; i < createdQueues.length ; ++i ) {
            platformAndArenaFee = IPlatformAndArenaFee(control.arenas).platformAndArenaFee(createdQueues[i].core.arena);
            require(platformAndArenaFee < createdQueues[i].core.raceEntryTicket / createdQueues[i].totalParticipants);
            queues[id] = createdQueues[i];
            ++id;
        }

        emit QueuesCreation(id-createdQueues.length,id-1,createdQueues);
    }

    function editQueue(
        uint256 queueId, 
        Queue.Struct memory queue
    ) 
        external 
        whitelisted 
    {
        uint256 platformAndArenaFee = IPlatformAndArenaFee(control.arenas).platformAndArenaFee(queue.core.arena);
        require(platformAndArenaFee < queue.core.raceEntryTicket / queue.totalParticipants);
        queues[queueId] = queue;
        emit EditQueue(queueId,queues[queueId]);
    }

    function closeQueue(
        uint256 queueId
    ) 
        external 
        whitelisted 
    {
        queues[queueId].closed = true;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = queues[queueId].core.raceEntryTicket;

        address arenaCurrency = IPlatformAndArenaFeeCurrency(control.arenas).platformAndArenaFeeCurrency(queues[queueId].core.arena);

        for ( uint256 i = 0; i < queues[queueId].core.participants.length; ++i ) {
            if ( queues[queueId].core.participants[i] > 0 ) {
                require(IUpdateHoundRunning(control.hounds).updateHoundRunning(queues[queueId].core.participants[i], queueId) != 0);
                address houndOwner = IHoundOwner(control.hounds).houndOwner(queues[queueId].core.participants[i]);

                IPay(control.payments).pay{
                    value: arenaCurrency == address(0) ? queues[queueId].core.raceEntryTicket : 0
                }(
                    address(this),
                    houndOwner,
                    arenaCurrency,
                    new uint256[](0),
                    amounts,
                    arenaCurrency == address(0) ? Payment.PaymentTypes.DEFAULT : Payment.PaymentTypes.ERC20
                );
            }
        }

        emit QueueClosed(queueId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../queues/params/Queue.sol';


interface IRaceStart {

    function raceStart(
        uint256 queueId,
        Queue.Struct memory queue
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';


contract Whitelist is Ownable {

    mapping(address => bytes4[]) public whitelists;

    constructor(address[] memory operators, bytes4[][] memory targets) {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                whitelists[operators[i]].push(targets[i][j]);
            }
        }
    }

    function updateWhitelist(address[] memory operators, bytes4[][] memory targets) internal {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                if ( j >= whitelists[operators[i]].length ) {
                    whitelists[operators[i]].push(targets[i][j]);
                } else {
                    whitelists[operators[i]][j] = targets[i][j];
                }
            }
        }
    }

    modifier whitelisted() {
        bool found = false;
        for (uint256 i = 0; i < whitelists[msg.sender].length; ++i) {
            if ( whitelists[msg.sender][i] == msg.sig ) {
                found = true;
            }
        }
        require(found);
        _;
    }

}