// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./interfaces/INomoRouter.sol";
import "./interfaces/INomoNFT.sol";
import "./interfaces/INomoCalculator.sol";

contract NomoLeagueClosed is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;

    /// @notice Nomo Router contract
    INomoRouter public router;

    /// @notice Nomo NFT contract
    INomoNFT public nft;

    /// @notice Token in form of which rewards are payed, v1 version, don't use now
    IERC20Upgradeable internal rewardToken;

    /// @notice Name of the league
    string public name;

    /// @notice Total number of games in the league
    uint256 public totalGames;

    /// @notice Maximal number of tokens one player can stake
    uint256 public tokenLimitPerPlayer;

    /// @notice Duration of one game
    uint256 public constant GAME_DURATION = 6 days;

    /// @notice Duration of staking period in one game
    uint256 public constant STAKING_DURATION = 0;

    /// @notice Last game ID (index)
    uint256 public lastGameId;

    /// @notice Timestamp when last game has started
    uint256 public lastGameStart;

    /// @notice Displays if all games in league have finished
    bool public finished;

    /// @notice Structure to store one player's info
    /// @dev Active points is total number of NFT points, active in this game (staked in time)
    /// @dev Pending points is total number of NFT points, that were staked too late to participate in current game
    /// @dev Current game is ID of the game when player has interacted with contract for the last time (used for calculations)
    struct Player {
        uint256 activePoints;
        uint256 pendingPoints;
        uint256 currentGame;
        uint256 tokensStaked;
    }

    /// @notice Mapping of addresses to their player info
    mapping(address => Player) public players;

    /// @notice Total number of active (participating in current game) points of staked NFTs
    uint256 public totalActivePoints;

    /// @notice Total number of pending (not participating in current game) points of staked NFTs
    uint256 public totalPendingPoints;

    /// @notice Mapping of tokenIds to number of points with which they are staked
    mapping(uint256 => uint256) public tokenPoints;

    /// @notice Internal mapping of token IDs to the game IDs when they were pending (used for calculations)
    mapping(uint256 => uint256) public _tokenPendingAtGame;

    /// @notice Reward per one active point, magnified by 2**128 for precision
    /// @notice v1 version, don't use for new contract
    uint256 private _magnifiedRewardPerPoint;

    /// @notice Mapping of game IDs to values of magnifiedRewardPerPoint at their end (used for calculations)
    /// @notice v1 version, don't use for new contract
    mapping(uint256 => uint256) private _rewardPerPointAfterGame;

    /// @notice Mapping of addresses to their corrections of the rewards (used to maintain rewards unchanged when number of player's points change)
    /// @notice v1 version, don't use for new contract
    mapping(address => int256) private _magnifiedRewardCorrections;

    //// @notice Mapping of addresses to their withdrawn reward amounts
    /// @notice v1 version, don't use for new contract
    mapping(address => uint256) private _rewardWithdrawals;

    /// @notice Magnitude by which rewards are multiplied during calculations for precision
    uint256 public constant _magnitude = 2**128;

    /// @notice Tokens in form of which rewards are payed
    address[] public rewardTokens;

    /// @notice Reward per one active point, magnified by 2**128 for precision
    mapping(uint256 => uint256) internal _v2_magnifiedRewardPerPoint;

    /// @notice Reward token position => game IDs => values of magnifiedRewardPerPoint at their end (used for calculations)
    mapping(uint256 => mapping(uint256 => uint256)) internal _v2_rewardPerPointAfterGame;

    /// @notice Reward token position => user address => corrections of the rewards (used to maintain rewards unchanged when number of player's points change)
    mapping(uint256 => mapping(address => int256)) internal _v2_magnifiedRewardCorrections;

    //// @notice Reward token position => user address => withdrawn reward amounts
    mapping(uint256 => mapping(address => uint256)) internal _v2_rewardWithdrawals;

    //// @notice Helpful flag for provide update to new version
    uint256 internal _version;

    // EVENTS

    /// @notice Event emitted when user withdraws his reward
    event RewardsWithdrawn(address indexed account, uint256[] amounts);

    /// @notice Event emitted when new game starts
    event NewGameStarted(uint256 indexed index);

    /// @notice Event emitted when token is staked to the league
    event TokenStaked(address indexed account, uint256 indexed tokenId);

    /// @notice Event emitted when token is unstaked from league
    event TokenUnstaked(address indexed account, uint256 indexed tokenId);

    /// @notice Event emitted when user's active points change
    event ActivePointsChanged(uint256 newPoints);

    /// @notice Event emitted when token points update
    event UpdatePoints(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed lastGameId,
        uint256 tokenPendingAtGame,
        uint256 newPoints
    );

    // CONSTRUCTOR

    function initialize(
        INomoRouter router_,
        string memory name_,
        uint256 totalGames_,
        uint256 tokenLimitPerPlayer_
    ) external initializer {
        __Ownable_init();

        router = router_;
        nft = INomoNFT(router.nft());
        uint256 rewardTokensLength = router.rewardTokensLength();
        rewardTokens = new address[](rewardTokensLength);
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            rewardTokens[i] = router.rewardTokens(i);
        }

        name = name_;
        totalGames = totalGames_;
        tokenLimitPerPlayer = tokenLimitPerPlayer_;

        _version = 2;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Function to sync reward tokens list with router
     */
    function updateRewardTokensList() external onlyOwner {
        uint256 rewardTokensLength = router.rewardTokensLength();
        require(rewardTokensLength > rewardTokens.length, "already updated");
        for (uint256 i = rewardTokens.length; i < rewardTokensLength; i++) {
            rewardTokens.push(router.rewardTokens(i));
        }
    }

    /**
     * @notice Function to withdraw accumulated rewards
     */
    function withdrawReward() external {
        revert("not supported");
        _movePendingPoints(msg.sender);

        uint256[] memory rewards = totalRewardsOf(msg.sender);
        _moveRewardWithdrawals(msg.sender);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _v2_rewardWithdrawals[i][msg.sender] += rewards[i];
            IERC20Upgradeable(rewardTokens[i]).safeTransfer(msg.sender, rewards[i]);
        }

        emit RewardsWithdrawn(msg.sender, rewards);
    }

    /**
     * @notice Function to withdraw accumulated rewards via router, not supported
     */
    function withdrawRewardForUser(address _user) external onlyRouter {
        // revert("not supported");
    }

    /**
     * @notice Auxilary function to update player's pending and active point
     */
    function updatePlayer(address account) external {
        _movePendingPoints(account);
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function to get total rewards of one account in the league
     * @param account Address to get rewards for
     * @return Total rewards, in order corresponded rewardTokens
     */
    function totalRewardsOf(address account) public view returns (uint256[] memory) {
        uint256 currentActivePoints = players[account].activePoints + players[account].pendingPoints;
        uint256 rewardTokensLength = router.rewardTokensLength();

        uint256[] memory pendingRewards = new uint256[](rewardTokensLength);
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            int256 currentCorrections = getMagnifiedRewardCorrections(i, account) -
                SafeCastUpgradeable.toInt256(
                    getRewardPerPointAfterGame(i, players[account].currentGame) * players[account].pendingPoints
                );

            uint256 accumulatedReward = SafeCastUpgradeable.toUint256(
                SafeCastUpgradeable.toInt256(currentActivePoints * getMagnifiedRewardPerPoint(i)) + currentCorrections
            ) / _magnitude;

            pendingRewards[i] = accumulatedReward - getRewardWithdrawals(i, account);
        }
        return pendingRewards;
    }

    /**
     * @notice Function to get total accumulated rewards of one account in the league
     * @param account Address to get rewards for
     * @return Total accumulated rewards, in order corresponded rewardTokens
     */
    function getAccumulatedReward(address account) external view returns (uint256[] memory) {
        uint256 currentActivePoints = players[account].activePoints + players[account].pendingPoints;
        uint256 rewardTokensLength = router.rewardTokensLength();

        uint256[] memory accumulatedReward = new uint256[](rewardTokensLength);
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            int256 currentCorrections = getMagnifiedRewardCorrections(i, account) -
                SafeCastUpgradeable.toInt256(
                    getRewardPerPointAfterGame(i, players[account].currentGame) * players[account].pendingPoints
                );

            accumulatedReward[i] =
                SafeCastUpgradeable.toUint256(
                    SafeCastUpgradeable.toInt256(currentActivePoints * getMagnifiedRewardPerPoint(i)) +
                        currentCorrections
                ) /
                _magnitude;
        }
        return accumulatedReward;
    }

    /**
     * @notice Getter for magnifiedRewardPerPoint
     */
    function getMagnifiedRewardPerPoint(uint256 rewardIndex) public view returns (uint256) {
        if (rewardIndex == 0 && _version < 2 && _magnifiedRewardPerPoint != type(uint256).max) {
            return _magnifiedRewardPerPoint;
        }
        return _v2_magnifiedRewardPerPoint[rewardIndex];
    }

    /**
     * @notice Getter for rewardPerPointAfterGame
     */
    function getRewardPerPointAfterGame(uint256 rewardIndex, uint256 gameId) public view returns (uint256) {
        if (rewardIndex == 0 && _version < 2 && _rewardPerPointAfterGame[gameId] != type(uint256).max) {
            return _rewardPerPointAfterGame[gameId];
        }
        return _v2_rewardPerPointAfterGame[rewardIndex][gameId];
    }

    /**
     * @notice Getter for magnifiedRewardCorrections
     */
    function getMagnifiedRewardCorrections(uint256 rewardIndex, address account) public view returns (int256) {
        if (rewardIndex == 0 && _version < 2 && _magnifiedRewardCorrections[account] != type(int256).max) {
            return _magnifiedRewardCorrections[account];
        }
        return _v2_magnifiedRewardCorrections[rewardIndex][account];
    }

    /**
     * @notice Getter for rewardWithdrawals
     */
    function getRewardWithdrawals(uint256 rewardIndex, address account) public view returns (uint256) {
        if (rewardIndex == 0 && _version < 2 && _rewardWithdrawals[account] != type(uint256).max) {
            return _rewardWithdrawals[account];
        }
        return _v2_rewardWithdrawals[rewardIndex][account];
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function to finish current game (distributing reward) and start a new one, can only be called by owner
     * @param totalRewards Rewards to distribute for current game
     */
    function nextGame(uint256[] calldata totalRewards) external onlyOwner {
        revert("not supported");
        require(!finished, "NomoLeague::nextGame: league is finished");
        if (lastGameId != 0) {
            _finishGame(totalRewards);
        }
        if (lastGameId < totalGames) {
            lastGameStart = block.timestamp;
            lastGameId += 1;

            emit NewGameStarted(lastGameId);
        } else {
            finished = true;
        }
    }

    /**
     * @notice Function to stake token, can't be called directly, staking should go through router
     */
    function stakeToken(address account, uint256 tokenId) external onlyRouter {
        revert("not supported");
        _movePendingPoints(account);

        require(
            players[account].tokensStaked + 1 <= tokenLimitPerPlayer,
            "NomoLeague::stakeToken: stake exceeds limit per player"
        );
        players[account].tokensStaked++;

        uint256 points = _getPoints(tokenId);
        tokenPoints[tokenId] = points;
        if (block.timestamp > lastGameStart + STAKING_DURATION || lastGameStart == 0) {
            _tokenPendingAtGame[tokenId] = lastGameId;
            totalPendingPoints += points;
            players[account].pendingPoints += points;
        } else {
            totalActivePoints += points;
            emit ActivePointsChanged(totalActivePoints);
            players[account].activePoints += points;
            _moveMagnifiedRewardPerPoint();
            _moveMagnifiedRewardCorrections(account);
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                _v2_magnifiedRewardCorrections[i][account] -= SafeCastUpgradeable.toInt256(
                    _v2_magnifiedRewardPerPoint[i] * points
                );
            }
        }

        emit TokenStaked(account, tokenId);
    }

    /**
     * @notice Function to update tokens limit per player
     */
    function setTokenLimitPerPlayer(uint256 _newLimit) external onlyOwner {
        tokenLimitPerPlayer = _newLimit;
    }

    /**
     * @notice Function to update league's name
     */
    function setName(string memory _newName) external onlyOwner {
        name = _newName;
    }

    /**
     * @notice Function to unstake token, can't be called directly, unstaking should go through router
     */
    function unstakeToken(address account, uint256 tokenId) external onlyRouter {
        _movePendingPoints(account);

        players[account].tokensStaked--;

        if (_tokenPendingAtGame[tokenId] == lastGameId) {
            totalPendingPoints -= tokenPoints[tokenId];
            players[account].pendingPoints -= tokenPoints[tokenId];
        } else {
            totalActivePoints -= tokenPoints[tokenId];
            emit ActivePointsChanged(totalActivePoints);
            players[account].activePoints -= tokenPoints[tokenId];
            _moveMagnifiedRewardPerPoint();
            _moveMagnifiedRewardCorrections(account);
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                _v2_magnifiedRewardCorrections[i][account] += SafeCastUpgradeable.toInt256(
                    _v2_magnifiedRewardPerPoint[i] * tokenPoints[tokenId]
                );
            }
        }
        _tokenPendingAtGame[tokenId] = 0;
        tokenPoints[tokenId] = 0;

        emit TokenUnstaked(account, tokenId);
    }

    /**
     * @notice Function to update token points, can't be called directly, updating should go through router
     */
    function updatePoints(address account, uint256 tokenId) external onlyRouter {
        _movePendingPoints(account);
        uint256 oldPoints = tokenPoints[tokenId];
        uint256 newPoints = _getPoints(tokenId);
        if (_tokenPendingAtGame[tokenId] == lastGameId) {
            players[account].pendingPoints -= oldPoints;
            players[account].pendingPoints += newPoints;
            totalPendingPoints -= oldPoints;
            totalPendingPoints += newPoints;
        } else {
            players[account].activePoints -= oldPoints;
            players[account].activePoints += newPoints;
            _moveMagnifiedRewardPerPoint();
            _moveMagnifiedRewardCorrections(account);
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                _v2_magnifiedRewardCorrections[i][account] += (SafeCastUpgradeable.toInt256(
                    _v2_magnifiedRewardPerPoint[i] * oldPoints
                ) - SafeCastUpgradeable.toInt256(_v2_magnifiedRewardPerPoint[i] * newPoints));
            }
            totalActivePoints -= oldPoints;
            totalActivePoints += newPoints;
        }
        tokenPoints[tokenId] = newPoints;
        emit UpdatePoints(account, tokenId, lastGameId, _tokenPendingAtGame[tokenId], newPoints);
    }

    // PRIVATE FUNCTION

    /// @dev This function updates reward per point, distributing reward
    /// @dev and then converts pending points from current game to active for next game
    function _finishGame(uint256[] calldata totalRewards) private {
        require(
            block.timestamp >= lastGameStart + GAME_DURATION,
            "NomoLeague::startNewGame: previous game isn't finished yet"
        );
        require(totalRewards.length == rewardTokens.length, "wrong totalRewards length");
        _moveMagnifiedRewardPerPoint();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (totalRewards[i] > 0) {
                require(
                    totalActivePoints > 0,
                    "NomoLeague::startNewGame: can't distribute non-zero reward with zero players"
                );
                _v2_magnifiedRewardPerPoint[i] += (_magnitude * totalRewards[i]) / totalActivePoints;
            }
        }

        _moveRewardPerPointAfterGame(lastGameId);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _v2_rewardPerPointAfterGame[i][lastGameId] = _v2_magnifiedRewardPerPoint[i];
        }
        totalActivePoints += totalPendingPoints;
        emit ActivePointsChanged(totalActivePoints);
        totalPendingPoints = 0;
    }

    function _getPoints(uint256 tokenId) private view returns (uint256) {
        (, , , , , uint256 setId, , , ) = nft.getCardImageDataByTokenId(tokenId);
        return INomoCalculator(router.calculator(setId)).calculatePoints(tokenId, lastGameStart);
    }

    /// @dev This function converts player's pending points from previous games to active
    /// @dev It is called before each player's interaction with league for correct lazy reward calculations
    function _movePendingPoints(address account) private {
        if (players[account].currentGame != lastGameId) {
            players[account].activePoints += players[account].pendingPoints;
            _moveRewardPerPointAfterGame(players[account].currentGame);
            _moveMagnifiedRewardCorrections(account);
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                _v2_magnifiedRewardCorrections[i][account] -= SafeCastUpgradeable.toInt256(
                    _v2_rewardPerPointAfterGame[i][players[account].currentGame] * players[account].pendingPoints
                );
            }
            players[account].pendingPoints = 0;
            players[account].currentGame = lastGameId;
        }
    }

    /**
     * @notice Helper for update magnifiedRewardPerPoint for work with many tokens
     */
    function _moveMagnifiedRewardPerPoint() internal {
        if (_version < 2 && _magnifiedRewardPerPoint != type(uint256).max) {
            _v2_magnifiedRewardPerPoint[0] = _magnifiedRewardPerPoint;
            _magnifiedRewardPerPoint = type(uint256).max;
        }
    }

    /**
     * @notice Helper for update rewardPerPointAfterGame for work with many tokens
     */
    function _moveRewardPerPointAfterGame(uint256 gameId) internal {
        if (_version < 2 && _rewardPerPointAfterGame[gameId] != type(uint256).max) {
            _v2_rewardPerPointAfterGame[0][gameId] = _rewardPerPointAfterGame[gameId];
            _rewardPerPointAfterGame[gameId] = type(uint256).max;
        }
    }

    /**
     * @notice Helper for update magnifiedRewardCorrections for work with many tokens
     */
    function _moveMagnifiedRewardCorrections(address account) internal {
        if (_version < 2 && _magnifiedRewardCorrections[account] != type(int256).max) {
            _v2_magnifiedRewardCorrections[0][account] = _magnifiedRewardCorrections[account];
            _magnifiedRewardCorrections[account] = type(int256).max;
        }
    }

    /**
     * @notice Helper for update rewardWithdrawals for work with many tokens
     */
    function _moveRewardWithdrawals(address account) internal {
        if (_version < 2 && _rewardWithdrawals[account] != type(uint256).max) {
            _v2_rewardWithdrawals[0][account] = _rewardWithdrawals[account];
            _rewardWithdrawals[account] = type(uint256).max;
        }
    }

    // MODIFIERS

    modifier onlyRouter() {
        require(msg.sender == address(router), "NomoLeague: sender isn't NomoRouter");
        _;
    }

    /**
     * @notice Function can be used by owner to withdraw any stuck token from the league
     * @param token address of the token to rescue.
     */
    function withdrawAnyToken(address token) external onlyOwner {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoRouter {
    event TokenStaked(address indexed account, uint256 indexed tokenId, uint256 leagueId);

    event TokenUnstaked(address indexed account, uint256 indexed tokenId, uint256 leagueId);

    event LeagueAdded(address indexed league, uint256 indexed leagueId);

    event LeagueRemoved(address indexed league, uint256 indexed leagueId);

    function stakeTokens(uint256[] calldata tokenIds) external;

    function unstakeTokens(uint256[] calldata tokenIds) external;

    function totalRewardOf(address account) external view returns (uint256);

    function nft() external view returns (address);

    function rewardTokens(uint256 index) external view returns (address);

    function rewardTokensLength() external view returns (uint256);

    function calculator(uint256 setId) external view returns (address);

    function leagues(uint256 id) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INomoNFT is IERC721 {
    function getCardImageDataByTokenId(uint256 _tokenId)
        external
        view
        returns (
            string memory name,
            string memory imageURL,
            uint256 league,
            uint256 gen,
            uint256 playerPosition,
            uint256 parametersSetId,
            string[] memory parametersNames,
            uint256[] memory parametersValues,
            uint256 parametersUpdateTime
        );

    function getCardImage(uint256 _cardImageId)
        external
        view
        returns (
            string memory name,
            string memory imageURL,
            uint256 league,
            uint256 gen,
            uint256 playerPosition,
            uint256 parametersSetId,
            string[] memory parametersNames,
            uint256[] memory parametersValues,
            uint256 parametersUpdateTime
        );

    function PARAMETERS_DECIMALS() external view returns (uint256);

    function cardImageToExistence(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoCalculator {
    function calculatePoints(uint256 _tokenId, uint256 _gameStartTime) external view returns (uint256 points);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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