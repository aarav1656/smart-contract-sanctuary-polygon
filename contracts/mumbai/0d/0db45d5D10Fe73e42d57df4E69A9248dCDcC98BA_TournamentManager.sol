// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TournamentManager
 * @notice This Contract allows an EVO from the Equals9 platform to create a
 * tournament and receive tickets from subscription in the form of the ONE token, or other native currency token.
 * The sum of all tickets is the total prize. The prize will be distributed later with a PaymentSplitter.
 * There is also a native token fee that if present can be used to stake and generate energy that can be
 * distributed among subscription for free transactions.
 */

contract TournamentManager is Ownable, ReentrancyGuard, Pausable {
    string public name;

    struct Sponsor {
        address walletAddress;
        uint256 amount;
    }

    struct Player {
        address walletAddress;
    }

    struct Tournament {
        address admin;
        IERC20 token;
        uint256 totalShares;
        uint256 totalAccTokenReward;
        uint256 sponsorTotalAcc;
        uint256 tokenFee;
        TournamentState state;
    }

    /**
     * @dev for simplicity some variables will be storaged outside the tournament struct
     */

    mapping(uint256 => mapping(address => uint256)) public subscription;

    mapping(uint256 => Sponsor[]) public sponsors;

    mapping(uint256 => Player[]) public players;

    mapping(uint256 => Tournament) public tournaments;

    // to make it easier to redeem, shares will be not related to specific tournaments instatiated
    mapping(address => uint256) public shares;

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private id;

    /**
     * @notice will be used to represent the current state
     * of the tournament. Players can only unsbubscribe
     * if tournament is in Waiting state. Not any other.
     */
    enum TournamentState {
        Waiting,
        Started,
        Ended
    }

    event TournamentCreated(uint256 indexed id);
    event SubscriptionCancelled(
        uint256 indexed id,
        address player,
        uint256 subscription,
        address token
    );
    event TournamentCanceled(uint256 indexed id);
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event prizeIncreased(
        uint256 indexed id,
        address sender,
        uint256 prize,
        address tokenAddress
    );
    event PlayerJoined(
        uint256 indexed id,
        address player,
        uint256 subscription,
        address token
    );
    event PlayerExited(uint256 indexed id, address player);

    /**
     * @dev Creates an instance of the TournamentManager
     */

    constructor() {
        name = "Tournament Manager Contract";
    }

    /**
     * @dev creates a tournament and associates it to an id. The sender is the administrator of this
     * tournament id. Allows the creator to associate a diferent token from the network token, it
     * requires to be rc20.
     * @param _fee the subscription price for this tournamentInstance.
     * @param _token the address of the given token contract.
     */

    function createTournament(uint256 _fee, address _token)
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        uint256 currentId = id.current();
        Tournament storage newTournament = tournaments[currentId];
        newTournament.admin = msg.sender;
        newTournament.state = TournamentState.Waiting;
        newTournament.tokenFee = _fee;
        newTournament.token = _token == address(0)
            ? IERC20(address(0))
            : IERC20(_token);
        tournaments[currentId] = newTournament;
        id.increment();
        emit TournamentCreated(currentId);
        return currentId;
    }

    /**
     * @notice the tournamentAdmin is capable of cancelling a tournament.
     * @dev it sends back every subscription value to all players that joined this tournament.
     * @param _id the id of the tournament to cancel.
     */

    function cancelTournament(uint256 _id) public payable onlyAdmin(_id) {
        Tournament storage tournament = tournaments[_id];
        require(tournament.totalAccTokenReward > 0, "Tournament has already distributed all tokens");
        tournament.state = TournamentState.Ended;
        for (uint256 i = 0; i < players[_id].length; i++) {
            if (subscription[_id][players[_id][i].walletAddress] == 0) continue;
            _cancelSubscription(_id, payable(players[_id][i].walletAddress));
        }
        for (uint256 i = 0; i < sponsors[_id].length; i++) {
            _returnSponsorsTokens(
                _id,
                payable(sponsors[_id][i].walletAddress),
                sponsors[_id][i].amount
            );
        }
        emit TournamentCanceled(_id);
    }

    /**
     * @dev this funciton increases readability. It's only used in the cancelTournament() method,
     * and it sends back the refund for the player that joined a cancelled tournament
     * @param _id the id of the tournament to cancel.
     * @param _subscriber the player that subscribe and will receive back it's funds
     */

    function _cancelSubscription(uint256 _id, address payable _subscriber)
        private
        nonReentrant
    {
        Tournament storage tournament = tournaments[_id];
        uint256 refund = subscription[_id][_subscriber];
        subscription[_id][_subscriber] = 0;
        tournament.totalAccTokenReward -= refund;

        if (tournament.token == IERC20(address(0))) {
            Address.sendValue(_subscriber, refund);
            emit SubscriptionCancelled(_id, _subscriber, refund, address(0));
        } else {
            tournament.token.safeTransfer(_subscriber, refund);
            emit SubscriptionCancelled(
                _id,
                _subscriber,
                refund,
                address(tournament.token)
            );
        }
    }

    /**
     * @dev this funciton increases readability. It's only used in the cancelTournament() method,
     * and it sends back the refund for the player that joined a cancelled tournament
     * @param _id the id of the tournament to cancel.
     * @param _sponsor the sponsor that will receive back it's funds
     * @param _amount the amount of tokens used to sponsor the tournament
     */
    function _returnSponsorsTokens(
        uint256 _id,
        address payable _sponsor,
        uint256 _amount
    ) private nonReentrant {
        Tournament storage tournament = tournaments[_id];
        if (tournament.token == IERC20(address(0))) {
            Address.sendValue(_sponsor, _amount);
            tournament.totalAccTokenReward -= _amount;
            emit SubscriptionCancelled(_id, _sponsor, _amount, address(0));
        } else {
            tournament.token.safeTransfer(_sponsor, _amount);
            tournament.totalAccTokenReward -= _amount;
            tournament.sponsorTotalAcc -= _amount;
            emit SubscriptionCancelled(
                _id,
                _sponsor,
                _amount,
                address(tournament.token)
            );
        }
    }

    /**
     * @dev this modifier is used to check if the creator of the tournament is the one calling the method.
     * only the creator is allowed to associate shares and change the tournament state.
     * @param _id the id of the tournament to join
     */
    modifier onlyAdmin(uint256 _id) {
        require(
            tournaments[_id].admin == msg.sender,
            "only the admin of this tournament can handle this function"
        );
        _;
    }

    modifier onlyTokenERC20(uint256 _id) {
        require(
            tournaments[_id].token != IERC20(address(0)),
            "only avaible if theres a token ERC20 specified for this tournament"
        );
        _;
    }

    modifier onlyNetworkToken(uint256 _id) {
        require(
            tournaments[_id].token == IERC20(address(0)),
            "only avaible if theres no token ERC20 specified for this tournament"
        );
        _;
    }

    /**
     * @notice use this function to join the tournment.
     * It is necessary to pay the native token fee otherwise the player won't be
     * registered as participant of the tournament.
     * @param _id the id of the tournament to join
     */
    function join(uint256 _id)
        public
        payable
        nonReentrant
        onlyNetworkToken(_id)
    {
        Tournament storage tournament = tournaments[_id];
        require(
            tournament.state == TournamentState.Waiting,
            "tournament already started or ended"
        );
        require(
            msg.value == tournament.tokenFee,
            "amount inserted is not the required ticket price"
        );
        require(
            subscription[_id][msg.sender] == 0,
            "player has already joined"
        );

        subscription[_id][msg.sender] = msg.value;
        tournament.totalAccTokenReward += msg.value;
        players[_id].push(Player(msg.sender));
        emit PlayerJoined(_id, msg.sender, msg.value, address(0));
    }

    /**
     * @notice use this function to join the tournment.
     * It is necessary to pay the native token fee otherwise the player won't be
     * registered as participant of the tournament.
     * @param _id the id of the tournament to join
     */

    function joinERC20(uint256 _id) public nonReentrant onlyTokenERC20(_id) {
        Tournament storage tournament = tournaments[_id];
        require(
            tournament.state == TournamentState.Waiting,
            "tournament not waiting"
        );
        require(
            subscription[_id][msg.sender] == 0,
            "player has already joined"
        );

        uint256 _amount = tournament.tokenFee;
        subscription[_id][msg.sender] = _amount;
        tournament.totalAccTokenReward += _amount;
        tournament.token.safeTransferFrom(msg.sender, address(this), _amount);
        players[_id].push(Player(msg.sender));
        emit PlayerJoined(_id, msg.sender, _amount, address(tournament.token));
    }

    /**
     * @notice use this function to pay for the subscription of someone else
     * It is necessary to pay the native token fee otherwise the player won't be
     * registered as participant of the tournament.
     * @param _id the id of the tournament to join
     */
    function joinSomeoneElse(uint256 _id, address _player)
        public
        payable
        nonReentrant
        onlyNetworkToken(_id)
    {
        Tournament storage tournament = tournaments[_id];
        require(
            tournament.state == TournamentState.Waiting,
            "tournament already started or ended"
        );
        require(
            msg.value == tournament.tokenFee,
            "amount inserted is not the required ticket price"
        );
        require(subscription[_id][_player] == 0, "player has already joined");
        subscription[_id][_player] = msg.value;
        tournament.totalAccTokenReward += msg.value;
        players[_id].push(Player(_player));
        emit PlayerJoined(_id, _player, msg.value, address(0));
    }

    /**
     * @notice use this function to pay for the subscription of someone else
     * It is necessary to pay using the proper token fee otherwise the player won't be
     * registered as participant of the tournament.
     * @param _id the id of the tournament to join
     */
    function joinSomeoneElseERC20(
        uint256 _id,
        address _player
    ) public payable nonReentrant onlyTokenERC20(_id) {
        Tournament storage tournament = tournaments[_id];
        require(
            tournament.state == TournamentState.Waiting,
            "tournament already started or ended"
        );
        uint256 amount = tournament.tokenFee;
        require(subscription[_id][_player] == 0, "player has already joined");
        subscription[_id][_player] = amount;
        tournament.totalAccTokenReward += amount;
        players[_id].push(Player(_player));
        tournament.token.safeTransferFrom(msg.sender, address(this), amount);
        emit PlayerJoined(_id, _player, amount, address(0));
    }

    /**
     * @notice use this function to add up the prize of the tournament using,
     * the network token
     * @param _id the id of the tournament to join
     */
    function addPrize(uint256 _id)
        public
        payable
        nonReentrant
        onlyNetworkToken(_id)
    {
        Tournament storage tournament = tournaments[_id];
        require(msg.value > 0, "prize increase must be greater than 0");
        require(
            tournament.state == TournamentState.Waiting,
            "tournament already started or ended"
        );

        tournament.totalAccTokenReward += msg.value;
        tournament.sponsorTotalAcc += msg.value;
        sponsors[_id].push(
            Sponsor({walletAddress: msg.sender, amount: msg.value})
        );
        emit prizeIncreased(_id, msg.sender, msg.value, address(0));
    }

    /**
     * @notice use this function to add up the prize of the tournament using,
     * a ERC20 token
     * @param _id the id of the tournament to join
     * @param _amount the ERC20 token amount used to transfer to the contract
     */
    function addPrizeERC20(uint256 _id, uint256 _amount)
        public
        payable
        nonReentrant
        onlyTokenERC20(_id)
    {
        Tournament storage tournament = tournaments[_id];
        require(_amount > 0, "prize increase must be greater than 0");
        require(
            tournament.state == TournamentState.Waiting,
            "tournament already started or ended"
        );

        tournament.token.safeTransferFrom(msg.sender, address(this), _amount);
        tournament.totalAccTokenReward += _amount;
        tournament.sponsorTotalAcc += _amount;
        sponsors[_id].push(
            Sponsor({walletAddress: msg.sender, amount: _amount})
        );
        emit prizeIncreased(
            _id,
            msg.sender,
            _amount,
            address(tournament.token)
        );
    }

    /**
     * @notice only the creator of this tournament is allowed to set the state
     * @param _id the id of the tournament to check state
     * @param _state the state to be specified
     */
    function setState(uint256 _id, TournamentState _state)
        public
        onlyAdmin(_id)
    {
        tournaments[_id].state = _state;
    }

    /**
     * @notice Auxuliary function to avoid misusage of setState function
     * @param _id the id of the tournament
     */
    function setWaitingState(uint256 _id) public onlyAdmin(_id) {
        tournaments[_id].state = TournamentState.Waiting;
    }

    /**
     * @notice Auxuliary function to avoid misusage of setState function
     * @param _id the id of the tournament
     */
    function setEndedState(uint256 _id) public onlyAdmin(_id) {
        tournaments[_id].state = TournamentState.Ended;
    }

    /**
     * @notice Auxuliary function to avoid misusage of setState function
     * @param _id the id of the tournament
     */
    function setStartedState(uint256 _id) public onlyAdmin(_id) {
        tournaments[_id].state = TournamentState.Started;
    }

    /**
     * @notice a player can exit a tournament and receive it's payment back
     * if the tournament has not started yet
     * @param _id the id of the tournament to exit
     */
    function exit(uint256 _id) public {
        Tournament storage tournament = tournaments[_id];
        require(
            subscription[_id][msg.sender] == tournament.tokenFee,
            "player must have paid the entire fee"
        );
        require(
            tournament.state == TournamentState.Waiting,
            "cannot exit if state is not waiting"
        );
        _cancelSubscription(_id, payable(msg.sender));
        emit PlayerExited(_id, msg.sender);
    }

    /**
     * @dev axuilirary function to check if player has paid the ticket, hence
     * joined the tournament
     * @param _id the id of the tournament to check payment
     * @param _player address to be checked
     */
    function checkPayment(uint256 _id, address _player)
        public
        view
        returns (bool)
    {
        if (subscription[_id][_player] == 0) {
            return false;
        } else return true;
    }

    /**
     * @dev Sets the Payment Splitter variables` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param _id the id of the tournament this splitting is coming from
     * @param  _payees the receivers
     * @param _shares the amount of shares each payee receive. The indexes of these arrays MUST match
     * in order to guarantee they are receiving the adequate value
     */
    function splitPayment(
        uint256 _id,
        address[] memory _payees,
        uint256[] memory _shares
    ) public onlyAdmin(_id) {
        Tournament storage tournament = tournaments[_id];
        require(
            _payees.length == _shares.length,
            "payees and shares length mismatch"
        );
        require(_payees.length > 0, "no payees");

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_id, _payees[i], _shares[i]);
        }

        tournament.totalShares = 0;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param _id The _id of the
     * @param _account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(
        uint256 _id,
        address _account,
        uint256 _shares
    ) private {
        Tournament storage tournament = tournaments[_id];
        require(
            _account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(_shares > 0, "PaymentSplitter: shares are 0");
        require(players[_id].length > 0, "No players joined the tournament");
        require(tournament.totalAccTokenReward >= _shares, "Shares greater than accumulated token reward");
        
        shares[_account] += _shares;
        tournament.totalShares += _shares;
        tournament.totalAccTokenReward -= _shares;
        emit PayeeAdded(_account, _shares);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their
     * balance of shares
     * @param _account the receiver address of the shares
     * @param _amount the amount to be received
     */
    function release(
        uint256 _id,
        address payable _account,
        uint256 _amount
    ) public payable nonReentrant {
        require(shares[_account] > 0, "account has no shares");
        require(_amount <= shares[_account], "amount exceeds shares");
        Tournament storage tournament = tournaments[_id];

        shares[_account] -= _amount;

        if (tournament.token == IERC20(address(0))) {
            Address.sendValue(_account, _amount);
        } else {
            tournament.token.safeTransfer(_account, _amount);
        }

        emit PaymentReleased(_account, _amount);
    }

    /**
     * @dev helper function to return the array length of players of a particular tournament
     */
    function getPlayersLength(uint256 _id) external view returns (uint256) {
        return players[_id].length;
    }

    /**
     * @dev retunrs the current version of this contract

     */
    function version() public pure returns (string memory) {
        return "1.5.0";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
interface IERC20Permit {
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