// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Web3liminator_V1 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for string;
    using SafeERC20Upgradeable for IERC20Upgradeable; // new in V1

    enum NFLTeam {
        NONE,
        ARIZONA,
        ATLANTA,
        BALTIMORE,
        BUFFALO,
        CAROLINA,
        CHICAGO,
        CINCINNATI,
        CLEVELAND,
        DALLAS,
        DENVER,
        DETROIT,
        GREENBAY,
        HOUSTON,
        INDIANAPOLIS,
        JACKSONVILLE,
        KANSASCITY,
        LASVEGAS,
        LACHARGERS,
        LARAMS,
        MIAMI,
        MINNESOTA,
        NEWENGLAND,
        NEWORLEANS,
        NYGIANTS,
        NYJETS,
        PHILADELPHIA,
        PITTSBURGH,
        SANFRANCISCO,
        SEATTLE,
        TAMPABAY,
        TENNESSEE,
        WASHINGTON
    }

    // @dev NORESULT means either a bye or no final result yet
    enum WeeklyResult {
        INCOMPLETE,
        LOSS,
        WIN,
        TIE,
        BYE
    }

    /// @notice
    struct NFLGame {
        NFLTeam homeTeam;
        NFLTeam awayTeam;
        NFLTeam winner;
        uint256 kickoffTime;
        uint8 week;
        bool resultHasBeenSet;
    }

    address public eligibilityCheckAddress;
    uint8 public numberOfLeagueWeeks;
    uint8 public startingWeek;
    mapping(uint8 => NFLGame[]) public weeksToGamesMapping; // possibly not needed as opposed to iterating.
    mapping(NFLTeam => WeeklyResult[]) public teamResultsByWeek;
    address[] public addressesRegisteredList;
    bool[] public cachedEliminationList;
    mapping(address => bool) public addressesRegisteredMapping;
    mapping(address => string) public usernamesMapping;
    mapping(address => NFLTeam[]) public contestantWinnersPicked;
    mapping(address => uint8) public contestantWinsPickedScore;

    mapping(address => uint8) public addressesToChallengesBoughtMapping; // new in V1
    bool public challengeFlagBuyingEnabled; // new in V1
    uint8 public activeWeekIndex; //new in V1
    /// @notice erc20 payment token
    IERC20Upgradeable public paymentToken; // new in V1

    function initialize(
        address eligibilityAddress,
        uint8 leagueWeeks,
        uint8 startingWeekOfSeason,
        address paymentTokenAddress
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        paymentToken = IERC20Upgradeable(paymentTokenAddress);
        eligibilityCheckAddress = eligibilityAddress;
        numberOfLeagueWeeks = leagueWeeks;
        startingWeek = startingWeekOfSeason;
        for (uint256 j = 0; j < 33; j++) {
            for (uint8 i = 0; i < numberOfLeagueWeeks; i++) {
                teamResultsByWeek[NFLTeam(j)].push(WeeklyResult.INCOMPLETE);
            }
        }
    }

    function isEliminated(address addressToCheck) public view returns (bool) {
        bool eliminated = false;
        uint8 numChallenges = addressesToChallengesBoughtMapping[
            addressToCheck
        ];
        for (uint8 i = 0; i < numberOfLeagueWeeks; i++) {
            NFLTeam team_picked = contestantWinnersPicked[addressToCheck][i];
            WeeklyResult team_result = teamResultsByWeek[team_picked][i];
            if (team_result == WeeklyResult.LOSS) {
                // if week 9 or earlier your challenge flag can save you.
                if (i < (11 - startingWeek)) {
                    if (numChallenges == 0) {
                        // no challenges left, so call them eliminated.
                        eliminated = true;
                        break;
                    } else {
                        // decrement number of challenges remaining.
                        numChallenges--;
                    }
                } else {
                    eliminated = true;
                    break;
                }
            }
        }
        return eliminated;
    }

    function setEligibilityTokenAddress(address eligibilityAddress)
        external
        onlyOwner
    {
        eligibilityCheckAddress = eligibilityAddress;
    }

    function getContestantList() public view returns (address[] memory) {
        return addressesRegisteredList;
    }

    function getPicksByAddress(address addressToCheck)
        public
        view
        returns (NFLTeam[] memory)
    {
        return contestantWinnersPicked[addressToCheck];
    }

    function getAllPicksByWeek(uint8 week_of_season)
        public
        view
        returns (NFLTeam[] memory)
    {
        NFLTeam[] memory picks_list = new NFLTeam[](
            addressesRegisteredList.length
        );
        for (uint256 i; i < addressesRegisteredList.length; i++) {
            picks_list[i] = contestantWinnersPicked[addressesRegisteredList[i]][
                week_of_season
            ];
        }
        return picks_list;
    }

    function getAllEliminatedStatus() public view returns (bool[] memory) {
        bool[] memory eliminated_list = new bool[](
            addressesRegisteredList.length
        );
        for (uint256 i; i < addressesRegisteredList.length; i++) {
            eliminated_list[i] = isEliminated(addressesRegisteredList[i]);
        }
        // cachedEliminationList = eliminated_list;
        return eliminated_list;
    }

    function getTeamResultsByWeek(uint8 week_of_season)
        public
        view
        returns (WeeklyResult[] memory)
    {
        WeeklyResult[] memory team_results_list = new WeeklyResult[](33);
        for (uint256 i = 0; i < 33; i++) {
            team_results_list[i] = teamResultsByWeek[NFLTeam(i)][
                week_of_season
            ];
        }
        // cachedEliminationList = eliminated_list;
        return team_results_list;
    }

    function getNumberOfGamesInWeek(uint8 week_of_season)
        public
        view
        returns (uint256 numberOfGames)
    {
        return weeksToGamesMapping[week_of_season].length;
    }

    function isRegistered(address addressToCheck) public view returns (bool) {
        return addressesRegisteredMapping[addressToCheck];
    }

    function register(string calldata username) external {
        checkEligibility(msg.sender);
        require(
            addressesRegisteredMapping[msg.sender] == false,
            "Address already registered"
        );
        addressesRegisteredList.push(msg.sender);
        usernamesMapping[msg.sender] = username;
        addressesRegisteredMapping[msg.sender] = true;
        for (uint8 i = 0; i < numberOfLeagueWeeks; i++) {
            contestantWinnersPicked[msg.sender].push(NFLTeam.NONE);
        }
    }

    function pickWeeklyWinner(uint8 week_of_season, NFLTeam team_to_win)
        external
    {
        checkEligibility(msg.sender);
        bool game_found = false;
        for (uint8 i = 0; i < weeksToGamesMapping[week_of_season].length; i++) {
            //LOGIC CHECK - CANNOT CHANGE FROM GAME IF ALREADY STARTED
            if (
                weeksToGamesMapping[week_of_season][i].homeTeam ==
                contestantWinnersPicked[msg.sender][week_of_season] ||
                weeksToGamesMapping[week_of_season][i].awayTeam ==
                contestantWinnersPicked[msg.sender][week_of_season]
            ) {
                require(
                    block.timestamp <
                        weeksToGamesMapping[week_of_season][i].kickoffTime,
                    "Game already locked, cannot change current choice"
                );
            }

            //LOGIC CHECK - CANNOT CHANGE TO A GAME ALREADY STARTED
            if (
                weeksToGamesMapping[week_of_season][i].homeTeam ==
                team_to_win ||
                weeksToGamesMapping[week_of_season][i].awayTeam == team_to_win
            ) {
                game_found = true;
                require(
                    block.timestamp <
                        weeksToGamesMapping[week_of_season][i].kickoffTime,
                    "Game already locked, cannot change to a locked choice"
                );
            }
        }

        // they have to pick a team that is actually listed as a home or away team on the given week.
        require(
            game_found == true || team_to_win == NFLTeam.NONE,
            "Did not find the team you selected on this given week"
        );

        // LOGIC CHECK - CANNOT CHANGE TO A TEAM ALREADY PICKED UNLESS YOU ARE CHANGING THAT TEAM TO NONE
        if (team_to_win != NFLTeam.NONE) {
            for (uint8 i = 0; i < numberOfLeagueWeeks; i++) {
                require(
                    contestantWinnersPicked[msg.sender][i] != team_to_win,
                    "The team you picked is already being used on another week. Cannot use a team twice"
                );
            }
        }

        // IF TEAM IS ON A BYE DON'T ALLOW THEM TO CHOOSE EITHER
        require(
            teamResultsByWeek[team_to_win][week_of_season] != WeeklyResult.BYE,
            "Cannot choose a team on their bye week"
        );

        // finally let them set it if it passes all checks
        contestantWinnersPicked[msg.sender][week_of_season] = team_to_win;
    }

    function bulkAddGames(
        uint8[] calldata game_weeks,
        NFLTeam[] calldata home_teams,
        NFLTeam[] calldata away_teams,
        uint256[] calldata kickoff_times
    ) external onlyOwner {
        require(
            (game_weeks.length == home_teams.length &&
                game_weeks.length == away_teams.length &&
                game_weeks.length == kickoff_times.length),
            "All datasets must be of the same length"
        );
        for (uint256 i; i < game_weeks.length; i++) {
            // add an NFLGame to the
            NFLGame memory newGame = NFLGame({
                week: game_weeks[i],
                homeTeam: home_teams[i],
                awayTeam: away_teams[i],
                kickoffTime: kickoff_times[i],
                winner: NFLTeam.NONE,
                resultHasBeenSet: false
            });
            weeksToGamesMapping[game_weeks[i]].push(newGame);
        }
    }

    function bulkChangeGameDetail(
        uint8[] calldata game_weeks,
        uint256[] calldata game_indexes,
        NFLTeam[] calldata home_teams,
        NFLTeam[] calldata away_teams,
        uint256[] calldata kickoff_times
    ) external onlyOwner {
        require(
            (game_weeks.length == home_teams.length &&
                game_weeks.length == away_teams.length &&
                game_weeks.length == game_indexes.length &&
                game_weeks.length == kickoff_times.length),
            "All datasets must be of the same length"
        );
        for (uint256 i; i < 1; i++) {
            weeksToGamesMapping[game_weeks[i]][game_indexes[i]]
                .homeTeam = home_teams[i];
            weeksToGamesMapping[game_weeks[i]][game_indexes[i]]
                .awayTeam = away_teams[i];
            weeksToGamesMapping[game_weeks[i]][game_indexes[i]]
                .kickoffTime = kickoff_times[i];
        }
    }

    function bulkUpdateGameResults(
        uint8[] calldata game_weeks,
        uint256[] calldata game_ids,
        NFLTeam[] calldata winning_teams
    ) external onlyOwner {
        require(
            (game_weeks.length == game_ids.length &&
                game_weeks.length == winning_teams.length),
            "All datasets must be of the same length"
        );
        for (uint256 i; i < game_weeks.length; i++) {
            // the result has to be a tie or at least has to include one of the two teams playing that week
            require(
                winning_teams[i] == NFLTeam.NONE ||
                    weeksToGamesMapping[game_weeks[i]][game_ids[i]].homeTeam ==
                    winning_teams[i] ||
                    weeksToGamesMapping[game_weeks[i]][game_ids[i]].awayTeam ==
                    winning_teams[i],
                "Must choose one. ofthe two teams to win or must choose none"
            );
            weeksToGamesMapping[game_weeks[i]][game_ids[i]]
                .winner = winning_teams[i];
            weeksToGamesMapping[game_weeks[i]][game_ids[i]]
                .resultHasBeenSet = true;
            if (winning_teams[i] != NFLTeam.NONE) {
                teamResultsByWeek[winning_teams[i]][
                    game_weeks[i]
                ] = WeeklyResult.WIN;
                if (
                    weeksToGamesMapping[game_weeks[i]][game_ids[i]].homeTeam ==
                    winning_teams[i]
                ) {
                    teamResultsByWeek[
                        weeksToGamesMapping[game_weeks[i]][game_ids[i]].homeTeam
                    ][game_weeks[i]] = WeeklyResult.WIN;
                    teamResultsByWeek[
                        weeksToGamesMapping[game_weeks[i]][game_ids[i]].awayTeam
                    ][game_weeks[i]] = WeeklyResult.LOSS;
                } else {
                    teamResultsByWeek[
                        weeksToGamesMapping[game_weeks[i]][game_ids[i]].homeTeam
                    ][game_weeks[i]] = WeeklyResult.LOSS;
                    teamResultsByWeek[
                        weeksToGamesMapping[game_weeks[i]][game_ids[i]].awayTeam
                    ][game_weeks[i]] = WeeklyResult.WIN;
                }
            } else {
                teamResultsByWeek[
                    weeksToGamesMapping[game_weeks[i]][game_ids[i]].homeTeam
                ][game_weeks[i]] = WeeklyResult.TIE;
                teamResultsByWeek[
                    weeksToGamesMapping[game_weeks[i]][game_ids[i]].awayTeam
                ][game_weeks[i]] = WeeklyResult.TIE;
            }
        }
    }

    function updateTeamWeeklyResults(
        uint8[] calldata game_weeks,
        NFLTeam[] calldata teams,
        WeeklyResult[] calldata results
    ) external onlyOwner {
        require(
            (game_weeks.length == teams.length &&
                game_weeks.length == results.length),
            "All datasets must be of the same length"
        );
        for (uint256 i; i < game_weeks.length; i++) {
            teamResultsByWeek[teams[i]][game_weeks[i]] = results[i];
        }
    }

    function buyAChallengeFlag() external nonReentrant {
        checkEligibility(msg.sender);
        // maximum of 1 challenge flags
        uint8 previously_bought = addressesToChallengesBoughtMapping[
            msg.sender
        ];
        require(
            previously_bought < 1,
            "Maximum challenges allowed per person is 1"
        );
        require(
            activeWeekIndex < 11 - startingWeek,
            "Challenge flags cannot be bought or used after week 9"
        );

        // hecka hardcoded. Need to think of a better function for this
        uint256 payment_amount = 100 * 1000000000000000000;
        // convert the amount paid using 18 decimal places. without a decimals variable this only works with standard 18 decimals currencies.
        _proceedPayment(msg.sender, address(this), payment_amount);
        addressesToChallengesBoughtMapping[msg.sender]++;
    }

    // intended to be used as a promo mechanic.
    function giveChallengeFlags(uint8 numberToGive, address recipient)
        external
        onlyOwner
    {
        addressesToChallengesBoughtMapping[recipient] += numberToGive;
    }

    function checkEligibility(address addressToCheck)
        internal
        view
        returns (bool)
    {
        bool eligible = false;
        if (eligibilityCheckAddress == address(0) || _msgSender() == owner()) {
            eligible = true;
        } else {
            require(
                IERC721Upgradeable(eligibilityCheckAddress).balanceOf(
                    addressToCheck
                ) > 0,
                "No eligibility tokens detected, cannot perform requested action"
            );
            eligible = true;
        }
        return eligible;
    }

    function getAllGamesForWeek(uint8 week_of_season)
        external
        view
        returns (NFLGame[] memory)
    {
        return weeksToGamesMapping[week_of_season];
    }

    function setPaymentToken(address paymentTokenAddress) external onlyOwner {
        paymentToken = IERC20Upgradeable(paymentTokenAddress);
    }

    function setActiveWeekIndex(uint8 week_of_season) external onlyOwner {
        activeWeekIndex = week_of_season;
    }

    function advanceActiveWeekIndex() external onlyOwner {
        activeWeekIndex++;
    }

    function setChallengeFlagBuying(bool enabled) external onlyOwner {
        challengeFlagBuyingEnabled = enabled;
    }

    /**
     * @notice to proceed payment from buyer to seller
     * @dev only internal usage
     * @param seller token payee
     * @param buyer token payer
     * @param price amount of paymentToken to purchase nft
     */
    function _proceedPayment(
        address buyer,
        address seller,
        uint256 price
    ) private {
        paymentToken.safeTransferFrom(buyer, seller, price);
    }

    /**
    @notice Withdraws any rake collected from games that were completed
     */
    function withdrawAll() external onlyOwner {
        paymentToken.safeTransfer(
            msg.sender,
            paymentToken.balanceOf(address(this))
        );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}