/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract Statistics is Initializable {
    address public ethernaut;
    address[] public players;
    address[] public levels;
    uint256 private globalNoOfInstancesCreated;
    uint256 private globalNoOfInstancesCompleted;
    uint256 private globalNoOfFailedSubmissions;
    struct LevelInstance {
        address instance;
        bool isCompleted;
        uint256 timeCreated;
        uint256 timeCompleted;
        uint256[] timeSubmitted;
    }
    struct Level {
        uint256 noOfInstancesCreated;
        uint256 noOfInstancesSubmitted_Success;
        uint256 noOfSubmissions_Failed;
    }
    mapping(address => uint256) private globalNoOfLevelsCompletedByPlayer;
    mapping(address => uint256) private globalNoOfInstancesCreatedByPlayer;
    mapping(address => uint256) private globalNoOfInstancesCompletedByPlayer;
    mapping(address => uint256) private globalNoOfFailedSubmissionsByPlayer;
    mapping(address => Level) private levelStats;
    mapping(address => mapping(address => uint256)) private levelFirstInstanceCreationTime;
    mapping(address => mapping(address => uint256)) private levelFirstCompletionTime;
    mapping(address => mapping(address => LevelInstance)) private playerStats;
    mapping(address => bool) private playerExists;
    mapping(address => bool) private levelExists;
    mapping(address => uint256) private averageTimeTakenToCompleteLevels;
    event playerScoreProfile(address indexed player, uint256 indexed averageCompletionTime, uint256 indexed globalLevelsCompleted);
    modifier levelExistsCheck(address level) {
        require(doesLevelExist(level), "Level doesn't exist");
        _;
    }
    modifier levelDoesntExistCheck(address level) {
        require(!doesLevelExist(level), "Level already exists");
        _;
    }
    modifier playerExistsCheck(address player) {
        require(doesPlayerExist(player), "Player doesn't exist");
        _;
    }
    modifier onlyEthernaut() {
        require(
            msg.sender == ethernaut,
            "Only Ethernaut can call this function"
        );
        _;
    }
    function initialize(address _ethernautAddress) public initializer {
        ethernaut = _ethernautAddress;
    }
    // Protected functions
    function createNewInstance(
        address instance,
        address level,
        address player
    ) external onlyEthernaut levelExistsCheck(level) {
        if (!doesPlayerExist(player)) {
            players.push(player);
            playerExists[player] = true;
        }
        // If it is the first instance of the level
        if(playerStats[player][level].instance == address(0)) {
            levelFirstInstanceCreationTime[player][level] = block.timestamp;
        }
        playerStats[player][level] = LevelInstance(
            instance,
            false,
            block.timestamp,
            0,
            playerStats[player][level].timeSubmitted.length != 0
                ? playerStats[player][level].timeSubmitted
                : new uint256[](0)
        );
        levelStats[level].noOfInstancesCreated++;
        globalNoOfInstancesCreated++;
        globalNoOfInstancesCreatedByPlayer[player]++;
    }
    function submitSuccess(
        address instance,
        address level,
        address player
    ) external onlyEthernaut levelExistsCheck(level) playerExistsCheck(player) {
        require(
            playerStats[player][level].instance != address(0),
            "Instance for the level is not created"
        );
        require(
            playerStats[player][level].instance == instance,
            "Submitted instance is not the created one"
        );
        require(
            playerStats[player][level].isCompleted == false,
            "Level already completed"
        );
        // If it is the first submission in the level
        if(levelFirstCompletionTime[player][level] == 0) {
            globalNoOfLevelsCompletedByPlayer[player]++;
            levelFirstCompletionTime[player][level] = block.timestamp;
        }
        playerStats[player][level].timeSubmitted.push(block.timestamp);
        playerStats[player][level].timeCompleted = block.timestamp;
        playerStats[player][level].isCompleted = true;
        levelStats[level].noOfInstancesSubmitted_Success++;
        globalNoOfInstancesCompleted++;
        globalNoOfInstancesCompletedByPlayer[player]++;
        uint256 totalNoOfLevelsCompletedByPlayer = getTotalNoOfLevelsCompletedByPlayer(player);
        uint256 newAverageTimeTakenToCompleteLevels = updateAverageTimeTakenToCompleteLevelsByPlayer(player, level, totalNoOfLevelsCompletedByPlayer);
        emit playerScoreProfile(
            player, 
            newAverageTimeTakenToCompleteLevels, 
            totalNoOfLevelsCompletedByPlayer
        );
    }
    function submitFailure(
        address instance,
        address level,
        address player
    ) external onlyEthernaut levelExistsCheck(level) playerExistsCheck(player) {
        require(
            playerStats[player][level].instance != address(0),
            "Instance for the level is not created"
        );
        require(
            playerStats[player][level].instance == instance,
            "Submitted instance is not the created one"
        );
        require(
            playerStats[player][level].isCompleted == false,
            "Level already completed"
        );
        playerStats[player][level].timeSubmitted.push(block.timestamp);
        levelStats[level].noOfSubmissions_Failed++;
        globalNoOfFailedSubmissions++;
        globalNoOfFailedSubmissionsByPlayer[player]++;
    }
    function saveNewLevel(address level)
        external
        levelDoesntExistCheck(level)
        onlyEthernaut
    {
        levelExists[level] = true;
        levels.push(level);
    }
    // Player specific metrics
    // number of levels created by player
    function getTotalNoOfLevelInstancesCreatedByPlayer(address player)
        public
        view
        playerExistsCheck(player)
        returns (uint256)
    {
        return globalNoOfInstancesCreatedByPlayer[player];
    }
    // number of levels completed by player
    function getTotalNoOfLevelInstancesCompletedByPlayer(address player)
        public
        view
        playerExistsCheck(player)
        returns (uint256)
    {
        return globalNoOfInstancesCompletedByPlayer[player];
    }
    // number of levels failed by player
    function getTotalNoOfFailedSubmissionsByPlayer(address player)
        public
        view
        playerExistsCheck(player)
        returns (uint256)
    {
        return globalNoOfFailedSubmissionsByPlayer[player];
    }
    function getTotalNoOfLevelsCompletedByPlayer(address player)
        public
        view
        playerExistsCheck(player)
        returns (uint256)
    {
        return globalNoOfLevelsCompletedByPlayer[player];
    }
    // number of failed submissions of a specific level by player (0 if player didn't play the level)
    function getTotalNoOfFailuresForLevelAndPlayer(
        address level,
        address player
    )
        public
        view
        playerExistsCheck(player)
        levelExistsCheck(level)
        returns (uint256)
    {
        return
            playerStats[player][level].instance != address(0)
                ? playerStats[player][level].timeSubmitted.length
                : 0;
    }
    // Is a specific level completed by a specific player ?
    function isLevelCompleted(address player, address level)
        public
        view
        playerExistsCheck(player)
        levelExistsCheck(level)
        returns (bool)
    {
        return playerStats[player][level].isCompleted;
    }
    // How much time a player took to complete a level (in seconds)
    function getTimeElapsedForCompletionOfLevel(address player, address level)
        public
        view
        playerExistsCheck(player)
        levelExistsCheck(level)
        returns (uint256)
    {
        require(levelFirstCompletionTime[player][level] != 0, "Level not completed");
        return
            levelFirstCompletionTime[player][level] - levelFirstInstanceCreationTime[player][level];
    }
    // Get a specific submission time per level and player
    // Useful to measure differences between submissions time
    function getSubmissionsForLevelByPlayer(
        address player,
        address level,
        uint256 index
    )
        public
        view
        playerExistsCheck(player)
        levelExistsCheck(level)
        returns (uint256)
    {
        require(
            playerStats[player][level].timeSubmitted.length >= index,
            "Index outbounded"
        );
        return playerStats[player][level].timeSubmitted[index];
    }
    // Percentage of total levels completed by player (1e18 = 100%)
    function getPercentageOfLevelsCompleted(address player)
        public
        view
        playerExistsCheck(player)
        returns (uint256)
    {
        // Changed from 100 to 1e18 otherwise when levels.length > 100 this will round to 0 always
        return
            (getTotalNoOfLevelsCompletedByPlayer(player) * 1e18) /
            levels.length;
    }
    // Function to update the average time elapsed for all player's completed levels on first successful submission
    function updateAverageTimeTakenToCompleteLevelsByPlayer(address player, address level, uint256 totalNoOfLevelsCompletedByPlayer) private returns(uint256) {
        uint256 lastAverageTime = averageTimeTakenToCompleteLevels[player];
        uint256 newAverageTimeTakenToCompleteLevels;
        uint256 timeTakenForThisSuccessfulSubmission;
        timeTakenForThisSuccessfulSubmission = levelFirstCompletionTime[player][level] - levelFirstInstanceCreationTime[player][level];
        //now, set the average time value in the mapping via evaluating its current value;
        if (averageTimeTakenToCompleteLevels[player] == 0) {
            averageTimeTakenToCompleteLevels[player] = timeTakenForThisSuccessfulSubmission;
        } else {
            newAverageTimeTakenToCompleteLevels = ((lastAverageTime * (totalNoOfLevelsCompletedByPlayer-1)) + timeTakenForThisSuccessfulSubmission)/totalNoOfLevelsCompletedByPlayer;
            averageTimeTakenToCompleteLevels[player] = newAverageTimeTakenToCompleteLevels;
        }
        return newAverageTimeTakenToCompleteLevels;
    }
    // Game specific metrics
    function getTotalNoOfLevelInstancesCreated() public view returns (uint256) {
        return globalNoOfInstancesCreated;
    }
    function getTotalNoOfLevelInstancesCompleted() public view returns (uint256) {
        return globalNoOfInstancesCompleted;
    }
    function getTotalNoOfFailedSubmissions() public view returns (uint256) {
        return globalNoOfFailedSubmissions;
    }
    function getTotalNoOfPlayers() public view returns (uint256) {
        return players.length;
    }
    function getNoOfFailedSubmissionsForLevel(address level)
        public
        view
        levelExistsCheck(level)
        returns (uint256)
    {
        return levelStats[level].noOfSubmissions_Failed;
    }
    function getNoOfInstancesForLevel(address level)
        public
        view
        levelExistsCheck(level)
        returns (uint256)
    {
        return levelStats[level].noOfInstancesCreated;
    }
    function getNoOfCompletedSubmissionsForLevel(address level)
        public
        view
        levelExistsCheck(level)
        returns (uint256)
    {
        return levelStats[level].noOfInstancesSubmitted_Success;
    }
    // Internal functions
    function doesLevelExist(address level) public view returns (bool) {
        return levelExists[level];
    }
    function doesPlayerExist(address player) public view returns (bool) {
        return playerExists[player];
    }
    function getTotalNoOfEthernautLevels() public view returns(uint256) {
        return levels.length;
    }
    function getAverageTimeTakenToCompleteLevels(address player) public view returns(uint256) {
        return averageTimeTakenToCompleteLevels[player];
    }
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}