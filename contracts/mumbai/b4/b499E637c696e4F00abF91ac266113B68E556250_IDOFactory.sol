// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Code by 9571  2023-02-26

import "./idopool.sol";
import "./erc20/IERC20.sol";
import "./erc20/SafeERC20.sol";
import "./access/Ownable.sol";

contract IDOFactory is Ownable {
    using SafeERC20 for IERC20;

    address public adminAddr;
    uint256 public adminPoint0;
    uint256 public adminPoint1;

    mapping(address => uint256) userTime;

    event debug(
        string name,
        address msg,
        address owner,
        address admin,
        string text, 
        string group, 
        uint256 mode 
    );

    constructor(address admin) {
        adminAddr = admin;
        adminPoint0 = 50;
        adminPoint1 = 50;
        transferOwnership(admin);
    }

    function setFee0(uint256 fee) public onlyOwner {
        adminPoint0 = fee;
    }

    function setFee1(uint256 fee) public onlyOwner {
        adminPoint1 = fee;
    }

    function setUserTime(address addr) public onlyOwner {
        userTime[addr] = block.timestamp;
    }

    function createIDO(idopool.projectInfo memory data) external {

        require(data.startTime > block.timestamp, "The start time must be greater than the current time");

        require(data.lockNum < 36, "Max lockNum");
        require(data.startTime < data.endTime, "time range error");
        require(data.timeList.length >= 1, "unlock time not set");

        require(data.timeList[0] > data.endTime, "first unlock time  error");

        require(
            block.timestamp > userTime[msg.sender],
            "Not completed last time"
        );

        IERC20 token;
        token = IERC20(data.tokenB);

        if (data.projectType == 1) {
            uint256 amountIn = token.balanceOf(msg.sender);
            require(amountIn >= data.inTokenCapacity, "Insufficient balance");
        }

        idopool contractAddr;

        if (data.projectType == 0) {
            contractAddr = new idopool(
                data,
                msg.sender,
                adminAddr,
                adminPoint0
            );
        }

        if (data.projectType == 1) {
            contractAddr = new idopool(
                data,
                msg.sender,
                adminAddr,
                adminPoint1
            );
        }

        userTime[msg.sender] = data.endTime;

        if (data.projectType == 1) {
            SafeERC20.safeTransferFrom(
                token,
                address(msg.sender),
                address(contractAddr),
                data.inTokenCapacity
            );
        }

        emit debug(
            "create",
            address(contractAddr),
            msg.sender,
            adminAddr,
            data.projectText,
            data.groupID,
            data.projectType
        );
    }

    function IDOVerify() external {
        idopool.projectInfo memory data;
        data.inTokenCapacity = 0;
        //data.projectType = 0;
        //data.projectText = "0";
         data.groupID = "test";
        //data.tokenA=0x636e7652db6a961e47459586Ecf256358a6f15f9;
        //data.tokenB=0x1D3a434EeaC22d9935C14557d04B6b2D466696F7;

        idopool contractAddr = new idopool(
            data,
            msg.sender,
            adminAddr,
            adminPoint0
        );
       
        /*
        emit debug(
            "createIDOTest",
            address(contractAddr),
            msg.sender,
            adminAddr,
            data.projectText,
            data.groupID,
            data.projectType
        );
        */
        emit debug(
            "createIDOTest",
            address(contractAddr),
            msg.sender,
            adminAddr,
            data.projectText,
            data.groupID,
            data.projectType
        );

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Code by 9571  2023-02-26

import "./erc20/IERC20.sol";
import "./erc20/SafeERC20.sol";
import "./access/Ownable.sol";

contract idopool is Ownable {
    using SafeERC20 for IERC20;

    uint256 public adminPoint;
    //uint256 public num;
    uint256 public withdraw;
    uint256 public remainingAmount;
    mapping(address => uint256) userRecharge;

    struct projectInfo {
        address tokenA;
        address tokenB;
        string projectText;
        uint256 projectType;
        string groupID;
        uint256 startTime;
        uint256 endTime;
        uint256 inTokenCapacity;
        uint256 inTokenAmount;
        uint256 outTokenCapacity;
        uint256 maxExchange;
        uint256 exchange;
        uint256 decimalA;
        uint256 decimalB;
        uint256 lockNum;
        uint256[] timeList;
    }

    projectInfo Info;

    struct lockUser {
        uint256 startTime;
        uint256 amountB;
    }

    struct lockAmount {
        mapping(address => uint256) userAmountB;
    }

    mapping(uint256 => lockAmount) private itemMapping;

    address public sendAddrA;
    address public sendAddrB;

    IERC20 public tokenA;
    IERC20 public tokenB;

    address public adminAddr;

    modifier onlyAdminSender() {
        require(tx.origin == adminAddr);
        _;
    }

    event debug(
        string name,
        address msg,
        address addr,
        uint256 exec,
        uint256 number,
        uint256 time
    );

    constructor(
        projectInfo memory data,
        address owner,
        address admin,
        uint256 _adminPoint
    ) {
        tokenA = IERC20(data.tokenA);
        tokenB = IERC20(data.tokenB);
        sendAddrA = data.tokenA;
        sendAddrB = data.tokenB;

        data.outTokenCapacity = data.inTokenCapacity;
        remainingAmount = data.inTokenCapacity;

        Info = data;

        transferOwnership(owner);

        adminAddr = admin;
        adminPoint = _adminPoint;
    }

    function queryProjectInfo() public view returns (projectInfo memory) {
        return Info;
    }

    /*
    function queryNum() public view returns (uint256) {
        return num;
    }
    */

    function advanceRelease() public onlyOwner {
        Info.endTime = block.timestamp;
        emit debug(
            "endTime",
            address(msg.sender),
            address(this),
            0,
            Info.endTime,
            0
        );
    }

    function setFee(uint256 fee) public onlyAdminSender {
        adminPoint = fee;
    }

    function swap(uint256 _amountIn) public {
        uint256 amountIn = (_amountIn * Info.exchange) * Info.decimalB;
        require(amountIn <= Info.maxExchange, "amount exceed max");

        require(block.timestamp <= Info.endTime, "raise already end!");
        require(Info.startTime <= block.timestamp, "Not started!");
        require(_amountIn >= 100, "amount exceed min");

        require(
            Info.outTokenCapacity - amountIn >= 0,
            "surplus amount insufficient"
        );

        uint256 balance = tokenA.balanceOf(msg.sender);
        uint256 transferAmount = _amountIn * Info.decimalA;

        require(balance >= transferAmount, "erc20 amount exceeds balance");

        tokenA.safeTransferFrom(msg.sender, address(this), transferAmount);

        /*
        if (userRecharge[msg.sender] == 0) {
            num = num + 1;
        }
        */

        Info.outTokenCapacity = Info.outTokenCapacity - amountIn;

        userRecharge[msg.sender] += transferAmount;

        Info.inTokenAmount += transferAmount;

        uint256 amountOutB = amountIn / Info.lockNum;

        for (uint256 i = 0; i < Info.timeList.length; i++) {
            lockAmount storage handle = itemMapping[Info.timeList[i]];

            handle.userAmountB[msg.sender] += amountOutB;
        }

        emit debug(
            "swap",
            address(msg.sender),
            address(this),
            transferAmount,
            amountIn,
            block.timestamp
        );
    }

    function receiveUser() public {
        require(
            block.timestamp >= Info.timeList[0],
            "The unlocking time is not up"
        );

        uint256 amount = 0;

        for (uint256 i = 0; i < Info.timeList.length; i++) {
            lockAmount storage handle = itemMapping[Info.timeList[i]];

            if (block.timestamp > Info.timeList[i]) {
                if (handle.userAmountB[msg.sender] > 0) {
                    amount += handle.userAmountB[msg.sender];

                    handle.userAmountB[msg.sender] = 0;
                }
            }
        }
        require(amount > 0, "There is no amount to claim");
        tokenB.transfer(msg.sender, amount);
        remainingAmount = remainingAmount - amount;
        emit debug(
            "receiveUser",
            address(msg.sender),
            address(this),
            0,
            amount,
            block.timestamp
        );
    }

    function queryUser() public view returns (lockUser[] memory) {
        //check user
        //require(userRecharge[msg.sender] > 0, "you are Not involved");

        lockUser[] memory items = new lockUser[](Info.timeList.length);

        for (uint256 i = 0; i < Info.timeList.length; i++) {
            lockAmount storage handle = itemMapping[Info.timeList[i]];
            items[i].startTime = Info.timeList[i];
            items[i].amountB = handle.userAmountB[msg.sender];
        }
        return items;
    }

    function receiveOwner() public onlyOwner {
        uint256 amountIn = tokenA.balanceOf(address(this));

        require(block.timestamp >= Info.endTime, "project unfinished");
        require(withdraw == 0, "project already withdraw");

        /*
        require(
            userRecharge[msg.sender] > 0,
            "All amounts have been collected"
        )*/

        if (amountIn > 0) {
            uint256 amountOut = (amountIn / 1000) * adminPoint;

            tokenA.transfer(adminAddr, amountOut);

            amountIn = tokenA.balanceOf(address(this));

            tokenA.transfer(owner(), amountIn);
        }

        if (Info.outTokenCapacity > 0) {
            tokenB.transfer(owner(), Info.outTokenCapacity);
            //Info.outTokenCapacity = 0;
        }
        remainingAmount = remainingAmount - Info.outTokenCapacity;
        emit debug(
            "receiveOwner",
            address(msg.sender),
            address(this),
            amountIn,
            Info.outTokenCapacity,
            block.timestamp
        );

        withdraw = 1;

        //userRecharge[msg.sender] = 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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