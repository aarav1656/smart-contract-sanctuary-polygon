pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import './common/IERC20.sol';
import './common/EnumerableSet.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PrizePoolManager is OwnableUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping (address => bool) public isAuthorized;
    IERC20 public USDC;
    mapping (uint256 => EnumerableSet.UintSet) private users;
    EnumerableSet.UintSet private activePrizePools;
    EnumerableSet.UintSet private closedPrizePools;
    mapping (uint256 => uint256) public amountWonByUserId;
    mapping (uint256 => PrizePool) private prizePools;
    address public platformReceiver;
    address public dividendReceiver;
    address public custodialAddress;
    uint256 public feeLimit;

    uint256 public totalDividendsPaid;
    uint256 public totalPlatformPaid;
    uint256 public totalPayoutsPaid;

    struct User {
        uint256 userId;
        address walletAddress;
    }

    struct PrizePool {
        string description;
        uint256 numberOfUsers;
        bool onlyPayFees;
        mapping (uint256 => User) users;
        uint256 usersRegistered;
        uint256 entryFee;
        uint256 fixedPrizePool;
        uint256 totalEntryFee;
        uint256 totalPayout;
        uint256 dividendsPaid;
        uint256 platformPaid;
        bool active;
    }

    event PrizePoolInitialized(uint256 indexed entityId, string description, uint256 numberOfUsers, uint256 entryFee);
    event UserRegistered(uint256 indexed entityId, uint256 indexed userId, address indexed walletAddress, uint256 amount);
    event UserUnregistered(uint256 indexed entityId, uint256 indexed userId, bool refunded, uint256 amountRefunded);
    event PaidOut(uint256 indexed entityId, uint256 indexed userId, uint256 indexed amount);
    event PrizePoolClosed(uint256 indexed entityId);
    event PrizePoolReopened(uint256 indexed entityId);
    event SentToDividends(address indexed divReceiver, uint256 amount);
    event SentToPlatform(address indexed platformReceiver, uint256 amount);

    function initialize(address _USDC, address _custodialAddress, address _dividendReceiver, address _platformReceiver) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        USDC = IERC20(_USDC);
        custodialAddress = _custodialAddress;
        isAuthorized[msg.sender] = true;
        platformReceiver = _platformReceiver;
        dividendReceiver = _dividendReceiver;
        feeLimit = 500; // 5%
        isAuthorized[_custodialAddress] = true;
    }

    modifier onlyAuthorized {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    function setCustodialAddress(address _custodialAddress) external onlyOwner {
        custodialAddress = _custodialAddress;
    }   

    function setAuthorization(address account, bool authorized) external onlyOwner {
        isAuthorized[account] = authorized;
    }

    function setReceivers(address _dividendReceiver, address _platformReceiver) external onlyOwner {
        platformReceiver = _platformReceiver;
        dividendReceiver = _dividendReceiver;
    }

    function initializeNewPrizePool(
        uint256 entityId, // tournamentId or matchId
        string calldata desc, 
        uint256 _numberOfUsers, 
        uint256 entryFee,
        uint256[] memory userIds, 
        address[] memory walletAddresses,
        uint256 _fixedPrizePool
    ) external onlyAuthorized {
        require(!activePrizePools.contains(entityId), "Prize pool already created");
        require(userIds.length == walletAddresses.length, "Array length mismatch");
        activePrizePools.add(entityId);
        PrizePool storage prizePool = prizePools[entityId];
        prizePool.description = desc;
        prizePool.numberOfUsers = _numberOfUsers;
        prizePool.entryFee = entryFee;
        prizePool.fixedPrizePool = _fixedPrizePool;
        prizePool.active = true;
        prizePool.onlyPayFees = false;
        if(walletAddresses.length > 0 && walletAddresses[0] == address(0)){
            prizePool.onlyPayFees = true;
        }
        for(uint256 i = 0; i < userIds.length; i++){ 
            _registerUser( 
                entityId,
                walletAddresses[i], 
                userIds[i], 
                entryFee 
            ); 
        } 
        emit PrizePoolInitialized(entityId, desc, _numberOfUsers, entryFee);
    }

    function registerUsers(
        uint256 entityId,
        address[] memory walletAddresses,
        uint256[] memory userIds,
        uint256[] memory amounts
    ) external onlyAuthorized {
        require(prizePools[entityId].active, 'Game is not active');
        for(uint256 i = 0; i < userIds.length; i++){ 
            _registerUser( 
                entityId,
                walletAddresses[i], 
                userIds[i], 
                amounts[i] 
            ); 
        } 
    }

    // register each player individually using this function
    function registerUser(
        uint256 entityId,
        address walletAddress, 
        uint256 userId, 
        uint256 amount
    ) external onlyAuthorized {
        require(prizePools[entityId].active, 'Prize pool is not active');
        _registerUser(entityId, walletAddress, userId, amount);
    }

    // register each player individually using this function
    function _registerUser(
        uint256 entityId,
        address walletAddress, 
        uint256 userId, 
        uint256 amount
    ) internal {
        PrizePool storage prizePool = prizePools[entityId];
        require(users[entityId].length() < prizePool.numberOfUsers, "Prize pool full");
        require(amount <= prizePool.entryFee, "Amount too high");

        if(!users[entityId].contains(userId)){
            users[entityId].add(userId);
            prizePool.usersRegistered += 1;
            prizePool.users[userId].walletAddress = walletAddress;
            prizePool.users[userId].userId = userId;
        } else {
            revert("User already added to prize pool");
        }

        if(!prizePool.onlyPayFees){
            require(getWalletUsdcBalance(walletAddress) >= amount, "Not enough tokens");
            if(amount > 0){
                USDC.transferFrom(walletAddress, address(this), amount);
            }
        }
        
        prizePool.totalEntryFee += amount;
        
        emit UserRegistered(entityId, userId, walletAddress, amount);
    }

    function unregisterUsers(
        uint256 entityId,
        uint256[] memory userIds
    ) external onlyAuthorized {
        for(uint256 i = 0; i < userIds.length; i++){
            _unregisterUser(entityId, userIds[i]);
        }
    }

    function _unregisterUser(
        uint256 entityId,
        uint256 userId
    ) internal {
        PrizePool storage prizePool = prizePools[entityId];
        require(users[entityId].contains(userId), "User not registered");
        users[entityId].remove(userId);
        prizePool.usersRegistered -= 1;
        if(!prizePool.onlyPayFees){
            require(getContractUsdcBalance() >= prizePool.entryFee, "Not enough tokens to refund");
            USDC.transfer(prizePool.users[userId].walletAddress, prizePool.entryFee);
        }
        
        prizePool.totalEntryFee -= prizePool.entryFee;
        
        emit UserUnregistered(entityId, userId, !prizePool.onlyPayFees, prizePool.entryFee);
    }

    //  payout each game
    function payOutWinners(
        uint256 entityId, 
        uint256[] memory userIds, 
        uint256[] memory amounts, 
        uint256[] memory platformFees, 
        uint256[] memory dividendFees, 
        bool closeGame
    ) external onlyAuthorized {
        PrizePool storage prizePool = prizePools[entityId];
        require(activePrizePools.contains(entityId), "Game Not Active");
        require(userIds.length == amounts.length && amounts.length == platformFees.length && platformFees.length == dividendFees.length, "Array length mismatch");
        
        uint256 userId;
        uint256 amount;
        uint256 totalDividendPayout;
        uint256 totalPlatformPayout;
        uint256 totalPayoutAmount;

        for(uint256 i = 0; i < userIds.length; i++){
            userId = userIds[i];
            amount = amounts[i];
            require(getContractUsdcBalance() >= amount, "Not enough USDC to payout");
            require(prizePool.users[userId].userId == userId, "User not registered");
            if(!prizePool.onlyPayFees){
                USDC.transfer(prizePool.users[userId].walletAddress, amount);
            }
            totalDividendPayout += dividendFees[i];
            totalPlatformPayout += platformFees[i];
            totalPayoutAmount += amounts[i];
            amountWonByUserId[userId] += amount;
            emit PaidOut(entityId, userId, amount);
        }
        if(prizePool.totalEntryFee > 0){
            uint256 compareTo = prizePool.fixedPrizePool != 0 ? prizePool.fixedPrizePool : prizePool.totalEntryFee;
            require(totalDividendPayout + totalPlatformPayout + totalPayoutAmount + prizePool.totalPayout + prizePool.dividendsPaid + prizePool.platformPaid <= compareTo, "Payout too high");
        }

        prizePool.totalPayout += totalPayoutAmount;
        totalPayoutsPaid += totalPayoutAmount;

        if(prizePool.onlyPayFees){
            USDC.transferFrom(custodialAddress, address(this), totalDividendPayout + totalPlatformPayout);
        }

        if(totalDividendPayout > 0){
            require(getContractUsdcBalance() >= totalDividendPayout, "Not enough USDC to payout dividend");
            USDC.transfer(dividendReceiver, totalDividendPayout);
            prizePool.dividendsPaid += totalDividendPayout;
            totalDividendsPaid += totalDividendPayout;
            emit SentToDividends(dividendReceiver, totalDividendPayout);
        }

        if(totalPlatformPayout > 0){
            require(getContractUsdcBalance() >= totalPlatformPayout, "Not enough USDC to payout platform");
            USDC.transfer(platformReceiver, totalPlatformPayout);
            prizePool.platformPaid += totalPlatformPayout;
            totalPlatformPaid += totalPlatformPayout;
            emit SentToPlatform(platformReceiver, totalPlatformPayout);
        }

        if(closeGame){
            activePrizePools.remove(entityId);
            closedPrizePools.add(entityId);
            prizePool.active = false;
            emit PrizePoolClosed(entityId);
        }
    }

    //for emergency reopening a game to finish payouts
    function reopenPrizePool(uint256 entityId) external onlyOwner {
        PrizePool storage prizePool = prizePools[entityId];
        require(closedPrizePools.contains(entityId), "Prize pool is not closed");
        
        activePrizePools.add(entityId);
        closedPrizePools.remove(entityId);
        prizePool.active = true;
        emit PrizePoolReopened(entityId);
    }

    function getPrizePool(uint256 entityId) external view returns (
            uint256 numberOfUsers,
            uint256 usersRegistered,
            uint256 entryFee,
            uint256 totalEntryFee,
            uint256 fixedPrizePool,
            uint256 totalPayout,
            uint256 dividendsPaid,
            uint256 platformPaid,
            bool onlyPayFees,
            bool active
        )
    {
        PrizePool storage prizePool = prizePools[entityId];
        numberOfUsers = prizePool.numberOfUsers;
        usersRegistered = prizePool.usersRegistered;
        entryFee = prizePool.entryFee;
        totalEntryFee = prizePool.totalEntryFee;
        fixedPrizePool = prizePool.fixedPrizePool;
        totalPayout = prizePool.totalPayout;
        dividendsPaid = prizePool.dividendsPaid;
        platformPaid = prizePool.platformPaid;
        onlyPayFees = prizePool.onlyPayFees;
        active = prizePool.active;        
    }

    function getPrizePoolUsers(uint256 entityId) public view returns (uint256[] memory userIds, 
        bool[] memory isWallet, 
        address[] memory walletAddress)
    {
        PrizePool storage prizePool = prizePools[entityId];
        uint256 usersLength = users[entityId].length();
        userIds = new uint256[](usersLength);
        isWallet = new bool[](usersLength);
        walletAddress = new address[](usersLength);
        uint256 player;
        for(uint256 i = 0; i < usersLength; i++){
            player = users[entityId].at(i);
            userIds[i] = prizePool.users[player].userId;
            walletAddress[i] = prizePool.users[player].walletAddress;
        }
        return (userIds, isWallet, walletAddress);
    }

    function getContractUsdcBalance() public view returns (uint256){
        return USDC.balanceOf(address(this));
    }

    function getWalletUsdcBalance(address holder) public view returns (uint256){
        return USDC.balanceOf(holder);
    }

    function getActiveGames() external view returns (uint256[] memory){
        return activePrizePools.values();
    }
    
    function getInactivePrizePools() external view returns (uint256[] memory){
        return closedPrizePools.values();
    }
}

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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