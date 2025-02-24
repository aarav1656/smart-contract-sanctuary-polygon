/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-29
*/

// SPDX-License-Identifier: MIT
/**  
* Blockfantasy Smart Contract
**/

pragma solidity ^0.8.4;
pragma abicoder v2;

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        // solhint-disable-next-line max-line-length
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
  }

/** @title fantasy Prize Contract.
 * @notice A contract for calculating blockfantasy fantasy 
 * player points and prize distribution using fabionacci
 */

 contract Fantazy is Ownable, ReentrancyGuard{
     using SafeMath for uint256;
     using SafeERC20 for IERC20;

     uint256 public currenteventid;
     uint256 public currentpoolId;
     uint256 public commission1;
     uint256 private eventuserscount;
     uint256 private totalteampoint; //make private later
     uint256 private teampoint; //make private later
     uint256 private vicemultiplier;
     uint256 private captainmultiplier;
     address public operatorAddress;
     address private we;
     address private treasury;
     uint256 private userresultcount;
     address[] private emptyaddress;
     address public honeypot;
     uint256[] private empty;
    //uint256[] public test100;
     string[] private emptystring;
     uint256 private bal;
     IERC20 public usdt;

     struct Event{
         uint256 eventid; //would be an increment for each new event
         string eventname;
         uint256[] eventspool;
         uint256[] playerslist;
         address[] users;
         uint256 closetime;
         uint256 matchtime;
         bool canceled;
     }

     struct Users{
         uint256 eventid;
         address user;
         uint256 userscore;
         uint256[] teamnames;
         uint256[] userpool;
     }

     struct Team{
         address user;
         uint256 teamid;
         string teamname;
         uint256 selectedcaptain;
         uint256 selectedvicecaptain;
         uint256[9] selectedplayers;
         uint256 teamscore;
     }

     struct Pool{
         uint256 poolid;
         uint256[] teamsarray;
         uint256 entryfee;
         uint256 pooluserlimt;
         address[] userarray; 
         bool canceled;
         address[] playersrank;
         uint256[] prizeDistribution;
         bool prizesPaid;
     }

     struct Players{
         uint256 eventid;
         uint256 player;
         uint256 playerscore; 
     }

     struct Teamresult{
         uint256 team;
         uint256 score;
     }
     
     struct Usercount{
        uint256[] teamcount;
     }

     //mapping
     mapping(uint256 => Event) private _events;
     mapping(uint256 => Users) private _user;
     mapping(uint256 => Players) private _player;
     mapping(uint256 => mapping(uint256 => Team)) private teams;
     mapping(uint256 => Pool) private pools;
     mapping(uint256 => Teamresult) private _teamresult;
     mapping(uint256 => address) private usertoteam;
     mapping(uint256 => uint256) private _lastindex;
     mapping(uint256 => bool) private comissionpaid;
     mapping(uint256 => bool) private comissionpaidusdt;
     mapping(uint256 => mapping(uint256 => bool)) private teaminpool;
     mapping(uint256 => mapping(address => bool)) private userteamusdt;
     mapping(uint256 => mapping(address => bool)) private eventpaidforuser;
     mapping(uint256 => mapping(uint256 => uint256)) public poolbalance;
     mapping(uint256 => mapping(uint256 => uint256)) public poollimit;
     mapping(uint256 => mapping(uint256 => uint256)) public poolbalanceusdt;
     mapping(uint256 => mapping(uint256 => bool)) private claimedcanceledpool;
     mapping(uint256 => uint256) private userinpoolcount; //this for our chainlink keeper
     mapping(uint256 => uint256) private paidcount;
     mapping(uint256 => uint256) private usdtcount;
     mapping(uint256 => uint256) private maticcount;
     mapping(uint256 => mapping(uint256 => uint256)) private playerpoints; //event to players to points
     mapping(address => mapping(uint256 => uint256[])) private selectedusers; //event to players to selected players array
     mapping(uint256 => mapping(uint256 => uint256)) private teampointforevent; //users point for a particular event     
     mapping(address => mapping(uint256 => Usercount)) private userteamcount; //used for team count required


     //events
     event NewEvent(uint256 indexed eventID, string name, uint256 starttime);
     event Newpool(uint256 indexed poolid, uint256 fee, uint256 userlimit);
     event Joinedevent(address indexed player, uint256 indexed eventID, uint256 indexed pool, uint256 teamid, string teamname);
     event Newteam(address indexed player, uint256 indexed eventID, uint256 indexed teamid, string teamname);
     event Editteam(address indexed player, uint256 indexed eventID, uint256 indexed teamid);
     event Editteamleaders(address indexed player, uint256 indexed eventID, uint256 indexed teamid, uint256 captain, uint256 vicecaptain);
     event Canceleventpool(uint256 indexed eventID);
     event Cancelonlyevent(uint256 indexed eventID);
     event poolcanceled(uint256 indexed poolid);
     event claimedfee(uint256 indexed poolid, uint256 indexed teamid, uint256 indexed eventID, address player);
     event updatedplayerscore(uint256 indexed eventID);
     event Poolclaimed(uint256 indexed eventID, uint256 indexed poolid);

     constructor(address _treasury, uint256 _commission, address _honeypot, uint256 _currenteventid, uint256 _currentpoolId){
         treasury = _treasury;
         commission1 = _commission;
         honeypot = _honeypot;
         currenteventid = _currenteventid;
         currentpoolId = _currentpoolId;
     }

     function CreateEvents(
         string memory name,
         uint256[] memory playerspid,
         uint256 starttime
         ) external onlyOwner{
             require(starttime > block.timestamp, "Start time needs to be higher than the current time");
             require(playerspid.length > 0, "Add a player");
             //add requirements statement
             currenteventid++;
             _events[currenteventid] = Event({
                 eventid : currenteventid,
                 eventname : name,
                 eventspool : empty, 
                 playerslist : playerspid,
                 users : emptyaddress,
                 closetime : starttime.sub(60),
                 matchtime : starttime,
                 canceled : false

             });
             for (uint256 i = 0; i < playerspid.length; i++){
                 uint256 but = playerspid[i];
                 playerpoints[currenteventid][but] = 0; 
                 _player[currenteventid] = Players ({
                     eventid : currenteventid,
                     player : but,
                     playerscore : 0
                 });
             }

            emit NewEvent(currenteventid, name, starttime);
    }

    function Createpool(
        uint256 fee,
        uint256 eventID,
        uint256 userlimit
        ) public onlyOwner {
            require(fee > 0, "Add a fee for pool");
            require(userlimit > 0, "pool must have a userlimit");
            currentpoolId++;
            pools[currentpoolId] = Pool({
                poolid : currentpoolId,
                teamsarray : empty,
                entryfee : fee,
                pooluserlimt : userlimit,
                userarray : emptyaddress,
                canceled : false,
                playersrank : emptyaddress,
                prizeDistribution: empty,
                prizesPaid : false
            });
            _events[eventID].eventspool.push(currentpoolId);
            poolbalance[eventID][currentpoolId] = 0;
            poollimit[eventID][currentpoolId] = userlimit;
            comissionpaid[currentpoolId] = false;
            paidcount[currentpoolId] = 0;
            usdtcount[currentpoolId] = 0;
            maticcount[currentpoolId] = 0;

            emit Newpool(currentpoolId, fee, userlimit);
        }

    function Joinevent(
        uint256 eventID,
        address user,
        string memory teamname,
        uint256 _captain,
        uint256 _vicecaptain,
        uint256[9] calldata _playersselected,
        uint256 pool,
        uint256 _teamid
    ) public payable nonReentrant{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");// check this
        require(!_events[eventID].canceled, "Event has been canceled");
        uint256[] memory fit = userteamcount[user][pool].teamcount;
        require(fit.length < 6, "User team count is more than 6");
        require(pools[pool].entryfee == msg.value, "Enter the exact entry fee");
        require(!pools[pool].canceled, "pool has been canceled");
        require(msg.sender == user, "enter your correct wallet address");
        uint256 limit = poollimit[eventID][pool];
        uint256[] memory pimp = pools[pool].teamsarray;
        require(pimp.length <= limit, "Pool count more than the limit");

        uint256 yummyindex = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex + msg.value;

        eventuserscount++;
        Createteam(user, eventID, _captain, teamname, _vicecaptain, _playersselected, _teamid, false);
        _user[eventID] = Users({
            eventid : eventID,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][pool].teamcount.push(_teamid);
        _user[eventID].teamnames.push(_teamid);
        _user[eventID].userpool.push(pool);
        _events[eventID].users.push(user);
        pools[pool].teamsarray.push(_teamid);
        pools[pool].userarray.push(user);
        claimedcanceledpool[pool][_teamid] = false;
        teaminpool[pool][_teamid] = true;
        uint currentcount = maticcount[pool];
        maticcount[pool] = currentcount + 1; 

        emit Joinedevent(msg.sender, eventID, pool, _teamid, teamname);
    }

    function AdminDelegateJoin(
        uint256 eventID,
        address user,
        string memory teamname,
        uint256 _captain,
        uint256 _vicecaptain,
        uint256[9] calldata _playersselected,
        uint256 pool,
        uint256 _teamid
    ) external payable nonReentrant onlyOwner{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");// check this
        require(!_events[eventID].canceled, "Event has been canceled");
        uint256[] memory fit = userteamcount[user][pool].teamcount;
        require(fit.length < 6, "User team count is more than 6");
        require(pools[pool].entryfee == msg.value, "Enter the exact entry fee");
        require(!pools[pool].canceled, "pool has been canceled");
        uint256 limit = poollimit[eventID][pool];
        uint256[] memory pimp = pools[pool].teamsarray;
        require(pimp.length <= limit, "Pool count more than the limit");

        uint256 yummyindex = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex + msg.value;

        eventuserscount++;
        Createteam(user, eventID, _captain, teamname, _vicecaptain, _playersselected, _teamid, false);
        _user[eventID] = Users({
            eventid : eventID,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][pool].teamcount.push(_teamid);
        _user[eventID].teamnames.push(_teamid);
        _user[eventID].userpool.push(pool);
        _events[eventID].users.push(user);
        pools[pool].teamsarray.push(_teamid);
        pools[pool].userarray.push(user);
        claimedcanceledpool[pool][_teamid] = false;
        teaminpool[pool][_teamid] = true;
        uint currentcount = maticcount[pool];
        maticcount[pool] = currentcount + 1; 

        emit Joinedevent(msg.sender, eventID, pool, _teamid, teamname);
    }

    /*function multiadminbatch(uint256 eventID, address[] memory users, string[] memory _teamnames, uint256[] memory _captains, uint256[] memory _vicecaptains, uint256[9] calldata selctedplayers, uint256 pool, uint256[] memory _teams) external onlyOwner{
        address[] memory play = users;
        for (uint256 i = 0; i < play.length; i++){
            AdminDelegateJoin{value: pools[pool].entryfee}(eventID, play[i], _teamnames[i], _captains[i], _vicecaptains[i], selctedplayers, pool, _teams[i]);
        }
    }*/

    function Createteam(
        address useraddress,
        uint256 eventID,
        uint256 captain,
        string memory _teamname,
        uint256 vicecaptain,
        uint256[9] calldata playersselected,
        uint256 _teamid,
        bool check
        ) internal {
             require(captain > 0, "You must have a captain");
             require(vicecaptain > 0, "You must have a vice-captain");
             require(playersselected.length == 9, "You must have 11 selected players");
            //_teamid++;
            teams[eventID][_teamid] = Team({
                user : useraddress,
                teamid : _teamid,
                teamname : _teamname,
                selectedcaptain : captain,
                selectedvicecaptain : vicecaptain,
                selectedplayers : playersselected,
                teamscore : 0
            });
            selectedusers[useraddress][eventID] = playersselected;
            usertoteam[_teamid] = useraddress;
            userteamusdt[_teamid][useraddress] = check;

            emit Newteam(msg.sender, eventID, _teamid, _teamname);
        } 
///////////////////
    function editSelectedPlayers(uint256 eventID, uint256 team, uint256[9] calldata playersselected, address useraddress) public onlyOwner{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(useraddress == teams[eventID][team].user, "Not team owner");
        delete teams[eventID][team].selectedplayers;
        teams[eventID][team].selectedplayers = playersselected;

        emit Editteam(useraddress, eventID, team);
    }

    function editCaptainandVice(uint256 eventID, uint256 team, uint256 captain, uint256 vicecaptain, address useraddress) public onlyOwner{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(useraddress == teams[eventID][team].user, "Not team owner");
        teams[eventID][team].selectedcaptain = captain;
        teams[eventID][team].selectedvicecaptain = vicecaptain;

        emit Editteamleaders(useraddress, eventID, team, captain, vicecaptain);
    }

    function batcheditCaptainandVice(uint256 eventID, uint256[] memory _teams, uint256[] memory captains, uint256[] memory vicecaptains, address[] memory _users) external onlyOwner{
        address[] memory play = _users;
        for (uint256 i = 0; i < play.length; i++){
            editCaptainandVice(eventID, _teams[i], captains[i], vicecaptains[i], _users[i]);
        }
    }

    function canceleventandpool(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;
        for(uint256 i=0; i < _events[eventID].eventspool.length; i++){
            cancelpool(_events[eventID].eventspool[i]);
        }

        emit Canceleventpool(eventID);
    }

    function canceleventthenpoolmanually(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;

        emit Cancelonlyevent(eventID);
    }

    function cancelpool(uint256 poolid) public onlyOwner{
        require(!pools[poolid].canceled, "Pool has already been canceled");
        pools[poolid].canceled = true;

        emit poolcanceled(poolid);
    }

    function returnentryfee(uint256 poolid, uint256 team, uint256 eventID) internal nonReentrant{
        require(pools[poolid].canceled = true, "Pool has not been canceled");
        require(claimedcanceledpool[poolid][team] == false, "You have claimed pool"); 
        require(teaminpool[poolid][team] = true, "Team is not part of pool");
        address user = teams[eventID][team].user;
        uint256 fee = pools[poolid].entryfee;
        payable(user).transfer(fee);
        claimedcanceledpool[poolid][team] = true;

        emit claimedfee(poolid, team, eventID, msg.sender);
    }

    function returnentryfeeall(uint256 pool, uint256 eventID) external onlyOwner{
        require(pools[pool].teamsarray.length < 13, "Pool must have less than 13 players");
        uint256[] memory play = pools[pool].teamsarray;
        for (uint256 i = 0; i < play.length; i++){
            returnentryfee(pool, play[i], eventID);
        }
    }

    function returnentrynocondition(uint256[] memory _teamss, uint256 pool, uint256 eventID) external onlyOwner{
        uint256[] memory play = _teamss;
        for (uint256 i = 0; i < play.length; i++){
            returnentryfee(pool, play[i], eventID);
        }
    }

    function changecommision(uint256 rate) public onlyOwner{
        require(rate < 300, "Commission must have a value Or cannot be greater than 300");
        commission1 = rate;
    }

    function changecaptainmultiplier(uint256 _multiplier) public onlyOwner{
        captainmultiplier = _multiplier;
    }

    function changevicemultiplier(uint256 _multiplier) public onlyOwner{
        vicemultiplier = _multiplier;
    }

    function changeHoneypot(address _honeypot1) public onlyOwner{
        honeypot = _honeypot1;
    }

    function changeTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;
    }

    function updateplayerscore(uint256[] calldata scores, uint256 eventID) public onlyOwner{
        require(scores.length > 0, "Score array must have a value");
        uint256[] memory playerspid = _events[eventID].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[eventID][but] = scores[i];
        }

        emit updatedplayerscore(eventID);
    }

    function getCommission() public view returns (uint256) {
        return commission1;
    }

    function getEvent(uint256 eventID) public view returns (string memory, uint256[] memory, uint[] memory, uint256, uint256, bool) {
        return ( _events[eventID].eventname,
        _events[eventID].eventspool,
        _events[eventID].playerslist,
        _events[eventID].closetime,
        _events[eventID].matchtime,
        _events[eventID].canceled);
    }

    function getTeamdetails(uint256 team, uint256 eventID) public view returns (address, string memory, uint256, uint256, uint256[9] memory, uint256) {
        return (teams[eventID][team].user,
        teams[eventID][team].teamname,
        teams[eventID][team].selectedcaptain,
        teams[eventID][team].selectedvicecaptain,
        teams[eventID][team].selectedplayers,
        teams[eventID][team].teamscore);
    }

    function getpooldetails(uint256 pool) public view returns (uint256[] memory, uint256, uint256, address[] memory, bool, uint256[] memory, bool) {
        return (pools[pool].teamsarray,
        pools[pool].entryfee,
        pools[pool].pooluserlimt,
        pools[pool].userarray,
        pools[pool].canceled,
        pools[pool].prizeDistribution,
        pools[pool].prizesPaid);
    }

    function getallpoolsresult(uint256 eventID) public onlyOwner{
        uint256[] memory allpool = _events[eventID].eventspool;
        for (uint256 i = 0; i < allpool.length; i++){
            getallteampoint(eventID, allpool[i]);
        }
    }

    function getallteampoint(uint256 eventID, uint256 poolid) public onlyOwner {//should this be called by admin
        uint256[] memory boy = pools[poolid].teamsarray;
        for (uint256 i = 0; i < boy.length; i++){
            boy[i];
            uint256[9] memory tip=teams[eventID][boy[i]].selectedplayers;
            geteachteampoint(tip, eventID, boy[i], poolid,teams[eventID][boy[i]].selectedcaptain, teams[eventID][boy[i]].selectedvicecaptain);
        }
    }

    function geteachteampoint(uint256[9] memory userarray, uint256 eventID, uint256 team, uint256 pool, uint256 cpid, uint256 vpid) internal returns (uint256) {
        for (uint256 i = 0; i < userarray.length; i++){
            uint256 me = userarray[i];
            totalteampoint += playerpoints[eventID][me];
            uint256 vp = playerpoints[eventID][vpid];
            uint256 cp = playerpoints[eventID][cpid];
            uint256 vicecaptainpoint = vp.mul(vicemultiplier);
            uint256 captainpoint = cp.mul(captainmultiplier);
            uint256 Totalpoint = vicecaptainpoint.add(captainpoint).add(totalteampoint);
            teampoint = Totalpoint;
            teams[eventID][team].teamscore = teampoint;
            _teamresult[pool] = Teamresult({
                team : team,
                score : teampoint
            });
        }
        return teampoint;
    }

    function getalluserresult(uint256 pool) public view returns (Teamresult[] memory){
        uint256 count = pools[pool].teamsarray.length;
        Teamresult[] memory results = new Teamresult[](count);
        for (uint i = 0; i < count; i++) {
            Teamresult storage result = _teamresult[i];
            results[i] = result; 
        }
        return results;
    }

    function buildDistribution(uint256 _playerCount, uint256 _stakeToPrizeRatio, uint256 poolid, uint256 _skew) internal  view returns (uint256[] memory){
         //uint256 stakeToPrizeRatio = (_stakeToPrizeRatio.mul(10)).div(10);
         uint256 stakeToPrizeRatio = _stakeToPrizeRatio; 
         uint256[] memory prizeModel = YummyFibPrizeModel(_playerCount, _skew);
         uint256[] memory distributions = new uint[](_playerCount);
         uint256 prizePool = getPrizePoolLessCommission(poolid);
         //uint256 prizePool = 88;
          for (uint256 i=0; i<prizeModel.length; i++){
              uint256 constantPool = prizePool.mul(stakeToPrizeRatio).div(100);
              //uint256 constantPool = prizePool.mul(stakeToPrizeRatio);
              uint256 variablePool = prizePool.sub(constantPool);
              uint256 constantPart = pools[poolid].entryfee;
              //uint256 constantPart = 10;
              uint256 variablePart = variablePool.mul(prizeModel[i]).div(100);
              uint256 prize = constantPart.add(variablePart);
              distributions[i] = prize;
          }
          return distributions;
     }

    function YummyFibPrizeModel (uint256 _playerCount, uint256 _skew) internal pure returns (uint256[] memory){
        uint256[] memory fib = new uint[](_playerCount);
        uint256 skew = _skew;
        for (uint256 i=0; i<_playerCount; i++) {
             if (i <= 1) {
                 fib[i] = 1;
                } else {
                     // as skew increases, more winnings go towards the top quartile
                     fib[i] = (fib[i.sub(1)]).add(fib[i.sub(2)]);
                }
        }
        uint256[] memory fib2 = new uint[](fib.length);
        for (uint256 i=0; i<fib.length; i++) {
            //fib2[i] = fib[i].mul(skew).div(_playerCount).add(fib[i]);
            fib2[i] = fib[i].mul(1 + ((skew).div(_playerCount)));
        }
        uint256 fibSum = getArraySum(fib2);
        uint256[] memory bib = new uint[](fib.length);
        for (uint256 i=0; i<fib.length; i++) {
            bib[i] = (fib2[i].mul(100)).div(fibSum);
        }
        return bib;
    }
    function getCommission(uint256 poolid) public view returns(uint256){
        //address[] memory me = pools[poolid].userarray;
        uint me = maticcount[poolid];
        return me.mul(pools[poolid].entryfee)
                        .mul(commission1)
                        .div(1000);
    }

    function getPrizePoolLessCommission(uint256 poolid) public view returns(uint256){
        address[] memory me = pools[poolid].userarray;
        uint256 totalPrizePool = (me.length
                                    .mul(pools[poolid].entryfee))
                                    .sub(getCommission(poolid));
        return totalPrizePool;
    }

    function submitPlayersByRank(address[] memory users, uint256 poolid, uint256 stakeToPrizeRatio, uint256 _skew) public onlyOwner{
        require(pools[poolid].playersrank.length <= 0);
        pools[poolid].playersrank = users;
        uint256[] memory me = pools[poolid].teamsarray;
        pools[poolid].prizeDistribution = buildDistribution(me.length, stakeToPrizeRatio, poolid, _skew);
    }

    function getArraySum(uint256[] memory _array) internal pure returns (uint256){
        uint256 sum = 0;
        for (uint256 i=0; i<_array.length; i++){
            sum = sum.add(_array[i]);
        }
        return sum;
    }

    function getPrizeDistribution(uint256 pool) public view returns(uint256[] memory){
        return pools[pool].prizeDistribution;
    }

    function withdrawPrizes(uint256 eventID, uint256 poolid, uint256 index, uint256 param) public onlyOwner{
        require(!pools[poolid].prizesPaid, "The prizes have already been paid.");
        require(pools[poolid].playersrank.length > 0);
        uint256[] memory me = pools[poolid].teamsarray;
        uint256 lastindex = me.length.sub(index);
        //uint256 exempt = pools[poolid].entryfee / 100;
        uint256 totalexempt = pools[poolid].entryfee /*+ exempt*/;
        uint256 endindex;
        uint256 null1 = 0;
        if(lastindex <= 10){
        endindex = me.length;
        } else{
            endindex = index.add(10);
        }
        for(uint256 i= null1.add(index); i < endindex; i++ ){
            if(i >= param){
            uint256 balance = poolbalance[eventID][poolid];
            if(balance > pools[poolid].entryfee && pools[poolid].prizeDistribution[i] >= pools[poolid].entryfee/*totalexempt*/ ){
            payable(address(uint160(pools[poolid].playersrank[i])))
            .transfer(pools[poolid].prizeDistribution[i]);
            uint256 balance2 = poolbalance[eventID][poolid];
            uint256 taken = pools[poolid].prizeDistribution[i];
            poolbalance[eventID][poolid] = balance2 - taken;
            }
            eventpaidforuser[eventID][pools[poolid].playersrank[i]] = true;
           }
        }
        uint256 balance1 = poolbalance[eventID][poolid];
        if(balance1 < totalexempt){
            pools[poolid].prizesPaid = true;
        }
        emit Poolclaimed(eventID, poolid);
     }

    function withdrawPrizes2(address[] calldata users, uint256[] calldata amounts, uint256 eventID, uint256 poolid) external onlyOwner{
        require(!pools[poolid].prizesPaid, "The prizes have already been paid.");
        require(users.length == amounts.length,"Must be equal");
        //require(users.length <= 10,"");
        uint256[] memory me = pools[poolid].teamsarray;
        uint256 us = paidcount[poolid];
        require(us < me.length,"Must be less than");

        for(uint256 i = 0; i < users.length; i++){
            uint256 balance = poolbalance[eventID][poolid];
            if(balance > pools[poolid].entryfee){
            payable(address(uint160(users[i]))).transfer(amounts[i]);

            uint256 balance2 = poolbalance[eventID][poolid];
            uint256 taken = amounts[i];
            poolbalance[eventID][poolid] = balance2 - taken;
            }
            eventpaidforuser[eventID][users[i]] = true;
        }

        uint256 balance1 = poolbalance[eventID][poolid];

        if(balance1 < pools[poolid].entryfee){
            pools[poolid].prizesPaid = true;
        }

        paidcount[poolid] += users.length;

        emit Poolclaimed(eventID, poolid);
     }

    function withdrawunknown(IERC20 token) public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function checklastindex(uint256 poolid) public view returns(uint256){
        uint256 index = _lastindex[poolid];
        return index;
    }

    function withdrawCommission(uint256 poolid, uint256 eventID) public onlyOwner{
        require(comissionpaid[poolid] == false, "Commission has been paid");
        uint mul = getCommission(poolid) * 4;
            uint get = poolbalance[eventID][poolid];
            if(get <= mul){
                payable(treasury).transfer(get);
                comissionpaid[poolid] = true;
            }
    }

     receive() external payable {}
 }

 contract Multibatcher is Ownable{

    function multiadminbatcher(address _fantazy, uint256 eventID, address[] memory users, string[] memory _teamnames, uint256[] memory _captains, uint256[] memory _vicecaptains, uint256[9] calldata selctedplayers, uint256 pool, uint256[] memory _teams, uint256 _enteryfee) external payable onlyOwner{
        Fantazy _callee = Fantazy(payable(_fantazy));
        address[] memory play = users;
        for (uint256 i = 0; i < play.length; i++){
            _callee.AdminDelegateJoin{value: _enteryfee}(eventID, play[i], _teamnames[i], _captains[i], _vicecaptains[i], selctedplayers, pool, _teams[i]);
        }
    }

    receive() external payable {}
}