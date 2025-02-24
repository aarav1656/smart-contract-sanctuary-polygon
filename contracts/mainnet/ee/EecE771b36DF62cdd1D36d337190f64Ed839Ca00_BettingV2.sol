// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev Use to conduct tournament betting.
 * Has functions to create betting tournament and batch create betting tournament.
 * Has a function for adding more team to tournament after created.
 * Has a function to place bet on tournament.
 * Has a function to close tournament betting period and deduct fees.
 * Has a function to set tournament winner.
 * Has functions for retriving user reward, claim user reward and batch claim user reward.
 * Has functions for withdraw tournamnet fees, batch withdraw tournament fees and withdraw service fees.
 * Has a function to set contract fees percentage.
 * @notice Is pausable to prevent malicious behavior.
 */
contract BettingV2 is Ownable, AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant WORKER = keccak256("WORKER");
    uint256 public REWARDPRECISION = 10000000000;
    IERC20 public token;
    uint256 public serviceFeesPercentage;
    uint256 public tournamentFeesPercentage;
    uint256 public serviceFees;
    mapping(string => Tournament) public tournamentByTournamentId;

    struct Entry {
        string teamId;
        uint256 entryBetAmount;
        mapping(address => uint256) userBetAmount;
    }
    struct Tournament {
        string tournamentId;
        address tournamentOwner;
        uint256 tournamentFees;
        string winner;
        bool isClose;
        uint256 rewardPerBet;
        uint256 tournamentBetAmount;
        uint256 tournamentClaimAmount;
        mapping(address => uint256) userClaimAmount;
        uint256 entryCount;
        mapping(string => uint256) entryIdByTeamId;
        mapping(uint256 => Entry) entryByEntryId;
    }
    struct TournamentArgs {
        string tournamentId;
        string[] teamIds;
        address tournamentOwner;
    }
    struct UserEntryBetInfo {
        string teamId;
        uint256 userEntryBetAmount;
    }

    event TournamentCreated(string indexed tournamentId, string[] teamIds);
    event TournamentEntryAdded(string indexed tournamentId, string[] teamIds);
    event TournamentBetPlaced(string indexed tournamentId, string indexed teamId, address indexed userAddress, uint256 betAmount);
    event TournamentOwnerUpdated(string indexed tournamentId, address userAddress);
    event TournamentClosed(string indexed tournamentId);
    event TournamentFeesWithdrawed(string indexed tournamentId, address userAddress, uint256 withdrawAmount);
    event TournamentWinnerUpdated(string indexed tournamentId, string teamId, uint256 tournamentFees, uint256 serviceFees);
    event TournamentRewardClaimed(string indexed tournamentId, address indexed userAddress, uint256 claimAmount);
    event TournamentAdminRewardWithdrawed(string indexed tournamentId, address userAddress, uint256 withdrawAmount);
    event AdminServiceFeesWithdrawed(address userAddress, uint256 fees);
    event TournamentFeesPercentageUpdated(uint256 tournamentFeesPercentage);
    event ServiceFeesPercentageUpdated(uint256 serviceFeesPercentage);

    error InvalidTournamentArr(uint256 index, string reason);

    /**
     * @dev Set the address of token interface.
     * Setup role for deployer.
     * @param _tokenAddress - token address.
     * @param _serviceFeesPercentage - service fees percentage.
     */
    constructor(address _tokenAddress, uint256 _tournamentFeesPercentage, uint256 _serviceFeesPercentage) {
        token = IERC20(_tokenAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        setTournamentFeesPercentage(_tournamentFeesPercentage);
        setServiceFeesPercentage(_serviceFeesPercentage);
    }

    modifier tournamentCreated(string memory _tournamentId) {
        require(
            bytes(tournamentByTournamentId[_tournamentId].tournamentId).length >
                0,
            "[BettingV2.tournamentCreated] Tournament not created yet"
        );
        _;
    }
    modifier tournamentEntryExist(string memory _tournamentId, string memory _teamId) {
        require(
            tournamentByTournamentId[_tournamentId].entryIdByTeamId[_teamId] != 0,
            "[BettingV2.tournamentEntryExist] Tournament entry not exist"
        );
        _;
    }
    modifier beforeTournamentBettingClosed(string memory _tournamentId) {
        require(
            !tournamentByTournamentId[_tournamentId].isClose,
            "[BettingV2.beforeTournamentBettingClosed] Tournament betting period closed"
        );
        _;
    }
    modifier afterTournamentWinnerUpdated(string memory _tournamentId) {
        require(
            bytes(tournamentByTournamentId[_tournamentId].winner).length > 0,
            "[BettingV2.afterTournamentWinnerUpdated] Tournament winner not been updated yet"
        );
        _;
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[BettingV2] Revert receive function.");
    }

    fallback() external payable {
        revert("[BettingV2] Revert fallback function.");
    }

    /**
     * @dev Create betting tournament.
     * @param _tournamentId - tournament id generated from backend.
     * @param _teamIds - list of team id generated from backend.
     * @param _tournamentOwner - tournament owner address
     */
    function createBettingTournament(
        string memory _tournamentId,
        string[] memory _teamIds,
        address _tournamentOwner
    ) public whenNotPaused onlyRole(WORKER) {
        require(
            bytes(tournamentByTournamentId[_tournamentId].tournamentId)
                .length == 0,
            "[BettingV2.createBettingTournament] Tournament already created"
        );
        require(
            _teamIds.length > 1,
            "[BettingV2.createBettingTournament] Invalid teamIds length"
        );

        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        tournament.tournamentId = _tournamentId;
        tournament.tournamentOwner = _tournamentOwner;

        for (uint256 i = 0; i < _teamIds.length; i++) {
            string memory teamId = _teamIds[i];
            tournament.entryCount++;
            tournament.entryIdByTeamId[teamId] = tournament.entryCount;
            tournament.entryByEntryId[tournament.entryCount].teamId = teamId;
        }

        emit TournamentCreated(_tournamentId, _teamIds);
    }

    /**
     * @dev Create multiple betting tournament.
     * @param _tournamentArgsArr - array of tournament args.
     */
    function batchCreateBettingTournament(TournamentArgs[] memory _tournamentArgsArr)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        require(
            _tournamentArgsArr.length > 0,
            "[BettingV2.batchCreateBettingTournament] Invalid tournamentArgs array"
        );
        for (uint256 i = 0; i < _tournamentArgsArr.length; i++) {
            TournamentArgs memory tournamentArgs = _tournamentArgsArr[i];
            if(bytes(tournamentByTournamentId[tournamentArgs.tournamentId].tournamentId).length != 0)
                revert InvalidTournamentArr(i, "Tournament already created");
            if(tournamentArgs.teamIds.length <= 1)
                revert InvalidTournamentArr(i, "Invalid teamIds length");

            createBettingTournament(tournamentArgs.tournamentId, tournamentArgs.teamIds, tournamentArgs.tournamentOwner);
        }
    }

    /**
     * @dev Add betting tournament entries.
     * @param _tournamentId - tournament id generated from backend.
     * @param _teamIds - list of team id generated from backend.
     */
    function addBettingTournamentEntries(
        string memory _tournamentId,
        string[] memory _teamIds
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        tournamentCreated(_tournamentId)
        beforeTournamentBettingClosed(_tournamentId)
    {
        require(
            _teamIds.length > 0,
            "[BettingV2.addBettingTournamentEntries] Invalid entiryIds length"
        );

        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        for (uint256 i = 0; i < _teamIds.length; i++) {
            string memory teamId = _teamIds[i];
            require(
                tournament.entryIdByTeamId[teamId] == 0,
                "[BettingV2.addBettingTournamentEntry] Some team already exist in entry list"
            );

            tournament.entryCount++;
            tournament.entryIdByTeamId[teamId] = tournament.entryCount;
            tournament.entryByEntryId[tournament.entryCount].teamId = teamId;
        }

        emit TournamentEntryAdded(_tournamentId, _teamIds);
    }

    /**
     * @dev Place tournament bet on team.
     * @param _tournamentId - tournament id generated from backend.
     * @param _teamId - team id generated from backend.
     * @param _betAmount - bet amount.
     */
    function placeTournamentBet(
        string memory _tournamentId,
        string memory _teamId,
        uint256 _betAmount
    )
        external
        whenNotPaused
        tournamentCreated(_tournamentId)
        tournamentEntryExist(_tournamentId, _teamId)
        beforeTournamentBettingClosed(_tournamentId)
    {
        require(
            _betAmount > 0,
            "[BettingV2.placeTournamentBet] Invalid bet amount"
        );
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        Entry storage entry = tournament.entryByEntryId[
            tournament.entryIdByTeamId[_teamId]
        ];

        tournament.tournamentBetAmount += _betAmount;
        entry.entryBetAmount += _betAmount;
        entry.userBetAmount[msg.sender] += _betAmount;
        token.safeTransferFrom(msg.sender, address(this), _betAmount);

        emit TournamentBetPlaced(
            _tournamentId,
            _teamId,
            msg.sender,
            _betAmount
        );
    }

    /**
     * @dev Close tournament betting period.
     * @param _tournamentId - tournament id generated from backend.
     */
    function closeBettingTournament(string memory _tournamentId)
        public
        whenNotPaused
        onlyRole(WORKER)
        tournamentCreated(_tournamentId)
        beforeTournamentBettingClosed(_tournamentId)
    {
        tournamentByTournamentId[_tournamentId].isClose = true;

        emit TournamentClosed(_tournamentId);
    }

    /**
     * @dev Transfer tournament reward.
     * @param _tournament - tournament to transfer.
     * @param _reward - reward amount to transfer.
     * @notice seperate function to avoid reentrant call of batch claim tournament reward
     */
    function transferTournamentReward(Tournament storage _tournament, uint256 _reward) internal {
        _tournament.tournamentClaimAmount += _reward;
        _tournament.userClaimAmount[msg.sender] += _reward;
        safeUpoTransfer(msg.sender, _reward);

        emit TournamentRewardClaimed(_tournament.tournamentId, msg.sender, _reward);
    }

    /**
     * @dev Claim tournament reward.
     * @param _tournamentId - tournament id generated from backend.
     */
    function claimTournamentReward(string memory _tournamentId)
        external
        nonReentrant
        tournamentCreated(_tournamentId)
        afterTournamentWinnerUpdated(_tournamentId)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        uint256 reward = getUserTournamentClaimableReward(_tournamentId, msg.sender);
        require(
            reward > 0,
            "[BettingV2.claimTournamentReward] User not have claimable reward for this tournament"
        );
        transferTournamentReward(tournament, reward);
    }

    /**
     * @dev Claim multiple tournament reward.
     * @param _tournamentIds - array of tournament id generated from backend.
     *
     */
    function batchClaimTournamentReward(string[] memory _tournamentIds)
        external
        nonReentrant
    {   
        require(
            _tournamentIds.length > 0,
            "[BettingV2.batchClaimTournamentReward] Invalid tournamentId array"
        );
        for (uint256 i = 0; i < _tournamentIds.length; i++) {
            Tournament storage tournament = tournamentByTournamentId[_tournamentIds[i]];

            if(bytes(tournament.tournamentId).length == 0)
                revert InvalidTournamentArr(i, "Tournament not created yet");
            if(bytes(tournament.winner).length == 0)
                revert InvalidTournamentArr(i, "Tournament winner not been updated yet");

            uint256 reward = getUserTournamentClaimableReward(tournament.tournamentId, msg.sender);
            if(reward == 0) {
                revert InvalidTournamentArr(i, "User not have claimable reward for this tournament");
            } else {
                transferTournamentReward(tournament, reward);
            }
        }
    }

    /**
     * @dev Transfer tournament fee.
     * @param _tournament - tournament to transfer.
     * @param _tournamentFees - fee amount to transfer.
     * @notice seperate function to avoid reentrant call of batch tournament fees withdraw
     */
    function transferTournamentFees(Tournament storage _tournament, uint256 _tournamentFees) internal {
        safeUpoTransfer(msg.sender, _tournamentFees);
        emit TournamentFeesWithdrawed(_tournament.tournamentId, msg.sender, _tournamentFees);

        delete tournamentByTournamentId[_tournament.tournamentId].tournamentFees;
    }

    /**
     * @dev Allow tournament owner to withdraw tournament fees.
     * @param _tournamentId - tournament id generated from backend.
     */
    function tournamentFeesWithdraw(string memory _tournamentId)
        external
        nonReentrant
        tournamentCreated(_tournamentId)
        afterTournamentWinnerUpdated(_tournamentId)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        require(
            msg.sender == tournament.tournamentOwner,
            "[BettingV2.tournamentFeesWithdraw] Only tournament owner can withdraw fees"
        );
        uint256 tournamentFees = tournament.tournamentFees;
        require(
            tournamentFees > 0,
            "[BettingV2.tournamentFeesWithdraw] Tournament owner not have withdrawable fees for this tournament"
        );
        transferTournamentFees(tournament, tournamentFees);
    }

    /**
     * @dev Allow tournament owner to withdraw multiple tournament fees.
     * @param _tournamentIds - array of tournament id generated from backend.
     */
    function batchTournamentFeesWithdraw(string[] memory _tournamentIds)
        external
        nonReentrant
    {   
        require(
            _tournamentIds.length > 0,
            "[BettingV2.batchTournamentFeesWithdraw] Invalid tournamentId array"
        );
        for (uint256 i = 0; i < _tournamentIds.length; i++) {
            Tournament storage tournament = tournamentByTournamentId[_tournamentIds[i]];

            if(bytes(tournament.tournamentId).length == 0)
                revert InvalidTournamentArr(i, "Tournament not created yet");
            if(bytes(tournament.winner).length == 0)
                revert InvalidTournamentArr(i, "Tournament winner not been updated yet");
            if(msg.sender != tournament.tournamentOwner)
                revert InvalidTournamentArr(i, "Only tournament owner can withdraw fees");

            uint256 tournamentFees = tournament.tournamentFees;
            if(tournamentFees == 0) {
                revert InvalidTournamentArr(i, "Tournament owner not have withdrawable fees for this tournament");
            } else {
                transferTournamentFees(tournament, tournamentFees);
            }
        }
    }

    /**
     * @dev Allow admin to withdraw when no one bet on winner.
     * @param _tournamentId - tournament id generated from backend.
     */
    function adminRewardWithdraw(string memory _tournamentId)
        external
        nonReentrant
        onlyRole(WORKER)
        tournamentCreated(_tournamentId)
        afterTournamentWinnerUpdated(_tournamentId)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        Entry storage entry = tournament.entryByEntryId[tournament.entryIdByTeamId[tournament.winner]];
        require(
            entry.entryBetAmount == 0,
            "[BettingV2.adminRewardWithdraw] Admin cannot withdraw when there is bet on winner"
        );
        require(
            tournament.tournamentClaimAmount == 0,
            "[BettingV2.adminRewardWithdraw] Admin cannot withdraw more than once"
        );

        uint256 reward = tournament.tournamentBetAmount;
        require(
            reward > 0,
            "[BettingV2.adminRewardWithdraw] Tournament have no reward to be withdrawed"
        );
        tournament.tournamentClaimAmount += reward;
        safeUpoTransfer(msg.sender, reward);

        emit TournamentAdminRewardWithdrawed(_tournamentId, msg.sender, reward);
    }

    /**
     * @dev Allow admin to withdraw service fees.
     */
    function adminServiceFeesWithdraw() external nonReentrant onlyRole(WORKER) {
        require(
            serviceFees > 0,
            "[BettingV2.adminServiceFeeWithdraw] Contract have no service fees to be withdrawed"
        );
        safeUpoTransfer(msg.sender, serviceFees);
        emit AdminServiceFeesWithdrawed(msg.sender, serviceFees);

        delete serviceFees;
    }

    /**
     * @dev Calculate reward per bet on winner team.
     * @param _tournamentId - tournament id generated from backend.
     */
    function calculateTournamentReward(string memory _tournamentId) internal {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        Entry storage entry = tournament.entryByEntryId[
            tournament.entryIdByTeamId[tournament.winner]
        ];

        tournament.rewardPerBet = entry.entryBetAmount != 0 ?
            (tournament.tournamentBetAmount * REWARDPRECISION) / entry.entryBetAmount
            : 0;
    }

    /**
     * @dev Safty transfer Upo.
     * @param _userAddress - user address to be transfered to.
     * @param _upoAmount - upo amount to be transfered.
     */
    function safeUpoTransfer(address _userAddress, uint256 _upoAmount)
        internal
    {
        uint256 upoBalance = token.balanceOf(address(this));
        if (_upoAmount >= upoBalance) {
            token.safeTransfer(_userAddress, upoBalance);
        } else {
            token.safeTransfer(_userAddress, _upoAmount);
        }
    }

    /**
     * @dev Retrieve user betting tournament reward amount.
     * @param _tournamentId - tournament id generated from backend.
     * @param _userAddress - user address.
     */
    function getUserTournamentClaimableReward(
        string memory _tournamentId,
        address _userAddress
    ) public view returns (uint256 claimableReward) {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        Entry storage entry = tournament.entryByEntryId[
            tournament.entryIdByTeamId[tournament.winner]
        ];

        claimableReward = tournament.userClaimAmount[_userAddress] == 0
            ? (tournament.rewardPerBet * entry.userBetAmount[_userAddress]) /
                REWARDPRECISION
            : 0;
    }

    /**
     * @dev Retrieve tournament info.
     * @param _tournamentId - tournament id generated from backend.
     */
    function getTournamentInfo(string memory _tournamentId)
        external
        view
        returns (
            string memory tournamentId,
            address tournamentOwner,
            uint256 tournamentFees,
            string memory winner,
            bool isClose,
            uint256 rewardPerBet,
            uint256 tournamentBetAmount,
            uint256 tournamentClaimAmount,
            string[] memory tournamentEntries
        )
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];

        tournamentId = tournament.tournamentId;
        tournamentOwner = tournament.tournamentOwner;
        tournamentFees = tournament.tournamentFees;
        winner = tournament.winner;
        isClose = tournament.isClose;
        rewardPerBet = tournament.rewardPerBet;
        tournamentBetAmount = tournament.tournamentBetAmount;
        tournamentClaimAmount = tournament.tournamentClaimAmount;

        uint256 entryCount = tournament.entryCount;
        string[] memory list = new string[](entryCount);
        for (uint256 i = 0; i < entryCount; i++) {
            uint256 entryId = i + 1;
            list[i] = tournament.entryByEntryId[entryId].teamId;
        }
        tournamentEntries = list;
    }

    /**
     * @dev Retrieve tournament entry info.
     * @param _tournamentId - tournament id generated from backend.
     * @param _teamId - team id generated from backend.
     */
    function getEntryInfo(string memory _tournamentId, string memory _teamId)
        external
        view
        returns (string memory teamId, uint256 entryBetAmount)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        Entry storage entry = tournament.entryByEntryId[
            tournament.entryIdByTeamId[_teamId]
        ];

        teamId = entry.teamId;
        entryBetAmount = entry.entryBetAmount;
    }

    /**
     * @dev Retrieve tournament user info.
     * @param _tournamentId - tournament id generated from backend.
     * @param _userAddress - user address.
     */
    function getUserBetInfo(string memory _tournamentId, address _userAddress)
        external
        view
        returns (
            uint256 userTournamentBetAmount,
            uint256 userTournamentClaimAmount,
            UserEntryBetInfo[] memory userEntryBetInfo
        )
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        UserEntryBetInfo[] memory list = new UserEntryBetInfo[](
            tournament.entryCount
        );
        userTournamentBetAmount = 0;
        for (uint256 i = 0; i < tournament.entryCount; i++) {
            Entry storage entry = tournament.entryByEntryId[i + 1];
            list[i] = UserEntryBetInfo(
                entry.teamId,
                entry.userBetAmount[_userAddress]
            );
            userTournamentBetAmount += entry.userBetAmount[_userAddress];
        }
        userTournamentClaimAmount = tournament.userClaimAmount[_userAddress];
        userEntryBetInfo = list;
    }

    /**
     * @dev Set tournament winner, force close tournament, deduct service fees and calculate reward per bet.
     * @param _tournamentId - tournament id generated from backend.
     * @param _teamId - winner team id generated from backend.
     */
    function setTournamentWinner(
        string memory _tournamentId,
        string memory _teamId
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        tournamentCreated(_tournamentId)
        tournamentEntryExist(_tournamentId, _teamId)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        if(!tournament.isClose)
            closeBettingTournament(_tournamentId);
        require(
            bytes(tournament.winner).length == 0,
            "[BettingV2.setTournamentWinner] Tournament already have winner"
        );

        Entry storage winner = tournament.entryByEntryId[tournament.entryIdByTeamId[_teamId]];
        tournament.winner = _teamId;

        // Deduct fees
        uint256 tournamentFees;
        uint256 _serviceFees;
        if(winner.entryBetAmount != tournament.tournamentBetAmount) {
            tournamentFees = (tournament.tournamentBetAmount * tournamentFeesPercentage) / 100;
            _serviceFees = (tournament.tournamentBetAmount * serviceFeesPercentage) / 100;
            tournament.tournamentBetAmount -= (_serviceFees + tournamentFees);
            tournament.tournamentFees += tournamentFees;
            serviceFees += _serviceFees;
        }

        // Calculate reward
        tournament.rewardPerBet = winner.entryBetAmount != 0 ?
            (tournament.tournamentBetAmount * REWARDPRECISION) / winner.entryBetAmount
            : 0;

        emit TournamentWinnerUpdated(_tournamentId, _teamId, tournamentFees, _serviceFees);
    }

    /**
     * @dev Set tournament winner and calculate reward per bet.
     * @param _tournamentId - tournament id generated from backend.
     * @param _tournamentOwner - tournament owner address
     */
    function setTournamentOwner(
        string memory _tournamentId,
        address _tournamentOwner
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        tournamentCreated(_tournamentId)
        beforeTournamentBettingClosed(_tournamentId)
    {
        Tournament storage tournament = tournamentByTournamentId[_tournamentId];
        tournament.tournamentOwner = _tournamentOwner;

        emit TournamentOwnerUpdated(_tournamentId, _tournamentOwner);
    }

    /**
     * @dev Set contract tournament fees percentage.
     * @param _tournamentFeesPercentage - tournament fees percentage.
     */
    function setTournamentFeesPercentage(uint256 _tournamentFeesPercentage)
        public
        whenNotPaused
        onlyRole(WORKER)
    {
        require(
            _tournamentFeesPercentage >= 0 && _tournamentFeesPercentage <= 100,
            "[BettingV2.setTournamentFeesPercentage] Invalid tournament fees percentage"
        );
        tournamentFeesPercentage = _tournamentFeesPercentage;

        emit TournamentFeesPercentageUpdated(_tournamentFeesPercentage);
    }

    /**
     * @dev Set contract service fees percentage.
     * @param _serviceFeesPercentage - service fees percentage.
     */
    function setServiceFeesPercentage(uint256 _serviceFeesPercentage)
        public
        whenNotPaused
        onlyRole(WORKER)
    {
        require(
            _serviceFeesPercentage >= 0 && _serviceFeesPercentage <= 100,
            "[BettingV2.setServiceFeesPercentage] Invalid service fees percentage"
        );
        serviceFeesPercentage = _serviceFeesPercentage;

        emit ServiceFeesPercentageUpdated(_serviceFeesPercentage);
    }

    /**
     * @dev Set betting v2 in to pause state (only claim reward function and getter is allowed).
     */
    function pauseBettingV2() external onlyOwner {
        _pause();
    }

    /**
     * @dev Set betting v2 in to normal state.
     */
    function unpauseBettingV2() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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