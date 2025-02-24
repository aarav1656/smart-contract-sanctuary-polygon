// SPDX-License-Identifier: none

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/addressChecker.sol";

pragma solidity ^0.8.0;

contract ZenithVote is Ownable, ReentrancyGuard{
    using Address for address;
    using addressChecker for address;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    uint256 private feeCreateVote;
    uint256 private voteAmount;
    uint256 private voteHold;
    uint256 private createHold;
    Counters.Counter private totalVote;
    feeClaim private claimFee;

    address immutable public ztv;

    struct vote{
        bool executed;
        address owner;
        uint256 start;
        uint256 end;
        string title;
        string question;
        string[] choice;
    }

    struct voteData {
        bool voted;
        uint256 choosed;
        uint256 deposited;
    }

    struct feeClaim{
        uint256 feeArg1;
        uint256 feeArg2;
    }

    struct logVote{
        address voter;
        uint256 deposited;
    }

    mapping (address => bool) private manager;
    mapping (uint256 => vote) private userVote;
    mapping (address => uint256[]) private userProposals;
    mapping (uint256 => mapping (uint256 => uint256)) private totalUserVote;
    mapping (uint256 => mapping (uint256 => logVote[])) private voteLog;
    mapping (address => mapping (uint256 => voteData)) private usersChoosed;

    event managerStatus(
        address indexed user,
        bool indexed isManagerNow
    );
    event changedFeeClaim(
        uint256 indexed newArg1,
        uint256 indexed newArg2
    );
    event changedVoteAmount(
        uint256 indexed newAmount
    );
    event changedFeeCreate(
        uint256 indexed newAmount
    );
    event changedMinHoldVote(
        uint256 indexed newAmount
    );
    event changedMinHoldCreate(
        uint256 indexed newAmount
    );
    event createdVote(
        address indexed owner,
        uint256 indexed voteId,
        uint256 start,
        uint256 end,
        string title,
        string question,
        string[] choice
    );
    event executedVote(
        uint256 indexed voteId,
        uint256 indexed voteWin
    );
    event userVoted(
        address indexed voter,
        uint256 indexed voteId,
        uint256 indexed choice
    );
    event userClaimed(
        address indexed voter,
        uint256 indexed voteId,
        uint256 indexed deposited
    );

    constructor(
        uint256 createFee,
        uint256 amountVote,
        uint256 amountCreateHold,
        uint256 amountVoteHold,
        uint256 claimArg1,
        uint256 claimArg2,
        address voteToken
    ){
        require(
            voteToken.isERC20(),
            "ZenithVote : voteToken address is not ERC20!"
        );

        feeCreateVote = createFee;
        voteAmount = amountVote;
        voteHold = amountCreateHold;
        createHold = amountVoteHold;
        claimFee = feeClaim(
            claimArg1,
            claimArg2
        );
        ztv = voteToken;
    }

    modifier onlyManager() {
        require(
            isManager(_msgSender()) == true,
            "ZenithVote : only vote manager allowed!"
        );
        _;
    }

    function setManager(
        address target,
        bool status
    ) external virtual nonReentrant onlyOwner {
        manager[target] = status;

        emit managerStatus(target, status);
    }

    function changeFeeClaim(
        uint256 claimArg1,
        uint256 claimArg2
    ) external virtual nonReentrant onlyManager {
        claimFee = feeClaim(
            claimArg1,
            claimArg2
        );

        emit changedFeeClaim(
            claimArg1,
            claimArg2
        );
    }

    function changeFeeCreate(
        uint256 createFee
    ) external virtual nonReentrant onlyManager {
        feeCreateVote = createFee;

        emit changedFeeCreate(createFee);
    }

    function changeVoteAmount(
        uint256 amountVote
    ) external virtual nonReentrant onlyManager {
        voteAmount = amountVote;

        emit changedVoteAmount(amountVote);
    }

    function changeVoteMinHold(
        uint256 amountHold
    ) external virtual nonReentrant onlyManager {
        voteHold = amountHold;

        emit changedMinHoldVote(amountHold);
    }

    function changeCreateMinHold(
        uint256 amountHold
    ) external virtual nonReentrant onlyManager {
        createHold = amountHold;

        emit changedMinHoldCreate(amountHold);
    }

    function createVote(
        uint256 start,
        uint256 end,
        string memory title,
        string memory question,
        string[] memory choice
    ) external virtual nonReentrant {
        require(
            choice.length >= 2 && choice.length <= 4,
            "ZenithVote : choice min 2 max 4"
        );

        if(getCreateHold() > 0){
            require(
                IERC20(ztv).balanceOf(_msgSender()) >= getCreateHold(),
                "ZenithVote : Minimum holding is required!"
            );
        }

        if(getCreateFee() > 0){
            IERC20(ztv).safeTransferFrom(
                _msgSender(),
                owner(),
                getCreateFee()
            );
        }

        uint256 currentId = totalVote.current();
        userVote[currentId] = vote(
            false,
            _msgSender(),
            start,
            end,
            title,
            question,
            choice
        );

        totalVote.increment();
        userProposals[_msgSender()].push(currentId);

        emit createdVote(
            _msgSender(),
            currentId,
            start,
            end,
            title,
            question,
            choice
        );
    }

    function claimVote(
        uint256 voteId
    ) external virtual nonReentrant {
        require(
            getVoteData(voteId, voteId)[0].end < block.timestamp,
            "ZenithVote : Please wait vote until ended!"
        );
        require(
            getUserChoosed(_msgSender(), voteId).deposited > 0,
            "ZenithVote : You already claim!"
        );

        unchecked{
            uint256 deposited = getUserChoosed(_msgSender(), voteId).deposited;
            uint256 feeOfClaim = ((deposited * getClaimFee().feeArg1) / getClaimFee().feeArg2) / 100;
            uint256 finalClaim = deposited - feeOfClaim;
            usersChoosed[_msgSender()][voteId].deposited = 0;

            IERC20(ztv).safeTransfer(
                owner(),
                feeOfClaim
            );
            IERC20(ztv).safeTransfer(
                _msgSender(),
                finalClaim
            );

            emit userClaimed(
                _msgSender(),
                voteId,
                deposited
            );
        }
    }

    function executeVote(
        uint256 voteId
    ) external virtual nonReentrant {
        require(
            voteId < getTotalVote(),
            "ZenithVote : This vote id is never proposed!"
        );
        require(
            getVoteData(voteId, voteId)[0].end < block.timestamp,
            "ZenithVote : Please wait until vote period ended!"
        );
        require(
            getVoteData(voteId, voteId)[0].owner == _msgSender(),
            "ZenithVote : Only vote owner allowed!"
        );
        require(
            getVoteData(voteId, voteId)[0].executed == false,
            "ZenithVote : Vote already executed!"
        );

        uint256[] memory votedData = getTotalUserVote(voteId);
        uint256 biggest;

        for(uint256 x; x < votedData.length; x++){
            if(votedData[x] > votedData[x+1]){
                biggest = x;
            }else{
                biggest = x + 1;
            }
        }

        userVote[voteId].executed = true;

        emit executedVote(
            voteId,
            biggest
        );
    }

    function userWantVote(
        uint256 voteId,
        uint256 userChoose,
        uint256 votePower
    ) external virtual nonReentrant {
        require(
            getVoteData(voteId, voteId)[0].executed == false,
            "ZenithVote : This vote already executed!"
        );
        require(
            getVoteData(voteId, voteId)[0].end >= block.timestamp,
            "ZenithVote : Vote already ended!"
        );

        if(getUserChoosed(_msgSender(), voteId).voted == true){
            require(
                userChoose == getUserChoosed(_msgSender(), voteId).choosed,
                "ZenithVote : You already vote other option, please check your choice"
            );
        }

        if(getVoteHold() > 0){
            require(
                IERC20(ztv).balanceOf(_msgSender()) >= getVoteHold(),
                "ZenithVote : Minimum holding is required!"
            );
        }

        uint256 amountVote = getVoteAmount();

        if(amountVote > 0){
            require(
                votePower >= 1,
                "ZenithVote : Minimum vote power is 1!"
            );

            IERC20(ztv).safeTransferFrom(
                _msgSender(),
                address(this),
                amountVote * votePower
            );
        }else{
            require(
                getUserChoosed(_msgSender(), voteId).voted == false,
                "ZenithVote : You already vote!"
            );

            require(
                votePower == 1,
                "ZenithVote : Power only 1 for zero amount vote!"
            );
        }

        usersChoosed[_msgSender()][voteId] = voteData(
            true,
            userChoose,
            amountVote * votePower
        );
        totalUserVote[voteId][userChoose] += votePower;
        voteLog[voteId][userChoose].push(logVote(
            _msgSender(),
            amountVote * votePower
        ));

        emit userVoted(
            _msgSender(),
            voteId,
            userChoose
        );
    }

    function getCreateFee() public view returns(uint256){
        return feeCreateVote;
    }
    
    function getCreateHold() public view returns(uint256){
        return createHold;
    }

    function getVoteAmount() public view returns(uint256){
        return voteAmount;
    }

    function getVoteHold() public view returns(uint256){
        return voteHold;
    }

    function getTotalVote() public view returns(uint256){
        return totalVote.current();
    }

    function getClaimFee() public view returns(feeClaim memory){
        return claimFee;
    }

    function isManager(
        address user
    ) public view returns(bool){
        return user == owner() || manager[user] == true;
    }

    function getUserProposals(
        address user
    ) public view returns(uint256[] memory){
        return userProposals[user];
    }

    function getLogVoteData(
        uint256 voteId,
        uint256 choiceId,
        uint256 maxSize
    ) public view returns(logVote[] memory log){
        uint256 latestId = voteLog[voteId][choiceId].length;
        log = new logVote[](maxSize);

        if (maxSize == 1) {
            log[0] = voteLog[voteId][choiceId][latestId - 1];
        } else {
            if(maxSize <= latestId){
                for (uint256 i = 0; i < maxSize; i++) {
                    log[i] = voteLog[voteId][choiceId][latestId - (i + 1)];
                }
            }else{
                revert("ZenithVote : Overflow");
            }
        }
    }

    function getVoteData(
        uint256 voteFromId,
        uint256 voteToId
    ) public view returns(vote[] memory proposals){
        require(
            voteFromId <= voteToId,
            "ZenithVote : FromId must be less than ToId!"
        );
        require(
            voteToId <= getTotalVote(),
            "ZenithVote : Overflow!"
        );
        proposals = new vote[](voteToId - voteFromId + 1);
        if (voteFromId == voteToId) {
            // proposals = new vote[](1);
            proposals[0] = userVote[voteFromId];
        } else {
            // proposals = new vote[](voteToId - voteFromId);
            for (uint256 i = voteFromId; i <= voteToId; i++) {
                proposals[i] = userVote[i];
            }
        }
    }

    function getTotalUserVote(
        uint256 voteId
    ) public view returns(uint256[] memory){
        require(
            voteId < getTotalVote(),
            "ZenithVote : This vote id is never opened!"
        );
        
        uint256 getLength = getVoteData(voteId, voteId)[0].choice.length;
        uint256[] memory data = new uint256[](getLength);

        for(uint256 a; a < getLength; a++){
            data[a] = totalUserVote[voteId][a];
        }

        return data;
    }

    function getUserChoosed(
        address user,
        uint256 voteId
    ) public view returns(voteData memory){
        require(
            voteId < getTotalVote(),
            "ZenithVote : This vote id is never opened!"
        );
        return usersChoosed[user][voteId];
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library addressChecker{
    function isERC20(
        address target
    ) internal view returns(bool) {
        return _tryIsERC20(target);
    }

    function _tryIsERC20(
        address target
    ) private view returns(bool) {
        try IERC20Metadata(target).decimals() returns(uint8 decimals) {
            return decimals > 0;
        }catch{
            return false;
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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