/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

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

pragma solidity ^0.8.2;

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.9;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.9;

interface IRandomNumberGenerator {
    function requestRandomNumber(uint256 id) external;
}

pragma solidity ^0.8.9;

interface IStrategy {
    function calculateCount(uint256 price, uint256 countIn) external pure returns (uint256 value,uint256 countOut);
}

pragma solidity ^0.8.9;

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
pragma solidity ^0.8.9;

contract LuckyBoxRepeat is ReentrancyGuard, Initializable, OwnableUpgradeable{
    // 状态
    enum Status {
        NotOpened,
        Openable,
        Opening,
        Claimable,
        End
    }
    // 奖品
    struct lotteryAward {
        Status status; // 状态
        string tokenType; // 奖品类型 
        string tokenChain; // 奖品所在链 
        address tokenAddress; // 奖品合约地址
        uint256 tokenId; // 奖品是 nft 时对应的 token id
        address tokenOwner; // 奖品所在地址
        uint256 tokenAmount; // 奖品数量
        address ticketStrategy; // 策略地址
        // 其他
        uint64 startTime;  // 开始时间
        uint64 endTime; // 结束时间
        uint256 soldCount; // 已买数量
        uint256 luckyTicket; // 中奖号码
    }

    // 奖票
    struct lotteryTicket {
        string buyType; // 支付类型 
        address buyToken; // 支付类型是 erc20 时对应的合约地址
        uint256 ticketPrice; // 单价
        uint256 ticketUserAmount; // 单个钱包购买上限
        uint256 ticketAllAmount; // 奖品总量
    }
    mapping(uint256 => lotteryAward) public idToLotteryAward; // 奖品
    mapping(uint256 => lotteryTicket) public idToLotteryTicket; // 奖票
    mapping(uint256 => address[]) public idToUsers; // 用户总量
    mapping(uint256 => bool) public idToWinnerClaimed;
    mapping(uint256 => bool) public idToOwnerClaimed;
    mapping(uint256 => uint256) public idToRandomNumber;
    mapping(uint256 => bool) idToSupportOpen;
    mapping(uint256 => mapping(address => bool)) public idToIsWhitelist;
    mapping(uint256 => mapping(address => uint256)) idToOwnerBalance;
    mapping(uint256 => mapping(address => uint256[][])) public idToUserTicketIdxs; // [ [ticketStartIdx, ticketEndIdx], ... ]
    mapping(uint256 => mapping(address => uint256)) public idToUserTicketAmount; // 用户对应购买数量
    IRandomNumberGenerator public rng; 


    event lotteryStatusChanged(Status newStatus);
    event BuyTickets(address buyer,uint256 ticketStartIdx,uint256 tickectEndIdx);
    event NftClaimed(address winner);
    event PaymentClaimed(address creator);

    modifier onlyWhitelist(uint256 id) {
        require(
            idToIsWhitelist[id][msg.sender] || msg.sender == owner(),
            "Only whitelist"
        );
        _;
    }

    function initialize(
        address _randomGenerator
    ) external initializer {
        __Ownable_init();
        rng = IRandomNumberGenerator(_randomGenerator);
    }

    // 可接受本币
    receive() external payable {}

    // 创建
    function createBox(uint256 id, lotteryAward memory award,lotteryTicket memory ticket) external onlyOwner{
        require(idToLotteryAward[id].tokenAmount == 0,"exist");
        // 奖品公共部分
        require(award.tokenOwner != address(0),"award token owner is address(0)");
        require(award.tokenAmount != 0,"award token amount is 0");
        require(award.ticketStrategy != address(0),"award strategy is address(0)");
        require(award.endTime > award.startTime  && award.startTime > block.timestamp,"award time invalidate");
        require(award.soldCount == 0,"award sold count not is 0");
        require(award.luckyTicket == 0,"award lucky ticket not is 0");
        // 奖品单独部分
        if (keccak256(abi.encodePacked(award.tokenType)) == keccak256("20")) { // erc20
            require(award.tokenAddress != address(0),"award token address is address(0)");
            require(award.tokenId == 0,"award token id not is 0");
        } else if (keccak256(abi.encodePacked(award.tokenType)) == keccak256("bnb")) { // bnb
            require(award.tokenAddress != address(0),"award token address is address(0)");
            require(award.tokenId != 0,"award token id is 0");
        } else if (keccak256(abi.encodePacked(award.tokenType)) == keccak256("721")) { // erc721
            require(award.tokenAddress == address(0),"award token address is not address(0)");
        } else {
            revert("award token type not support");
        }

        // 奖票公共部分
        require(ticket.ticketPrice != 0,"ticket price is 0");
        require(ticket.ticketUserAmount != 0,"ticket user amount is 0");
        require(ticket.ticketAllAmount != 0,"ticket all amount is 0");
        // 奖票单独部分
        if (keccak256(abi.encodePacked(ticket.buyType)) == keccak256("20")) { // erc20
            require(ticket.buyToken != address(0),"ticket buy token address is address(0)");
        } else if (keccak256(abi.encodePacked(ticket.buyType)) == keccak256("bnb")) { // bnb
            require(ticket.buyToken == address(0),"ticket buy token address is not address(0)");
        } else {
            revert("ticket buy type not support");
        }

        idToLotteryAward[id] = award;
        idToLotteryTicket[id] = ticket;
    }

    // 购买
    function buyTicket(uint256 id, address tokenAddress, address owner, uint256 countIn) external payable{
        // 判断状态
        require(idToLotteryAward[id].status == Status.NotOpened,"not opened");
        // 判断时间
        require(block.timestamp > idToLotteryAward[id].startTime,"not start");
        require(block.timestamp < idToLotteryAward[id].endTime,"had ended");
        // 判断购买数量
        require(countIn != 0,"countIn is 0");
        // 判断个人购买上限
        require(idToUserTicketAmount[id][owner] <= idToLotteryTicket[id].ticketUserAmount,"over buy amount");
        // 判断总量
        require(idToLotteryAward[id].soldCount + countIn <= idToLotteryTicket[id].ticketAllAmount,"over all amount");

        (uint256 value,uint256 countOut) = IStrategy(idToLotteryAward[id].ticketStrategy).calculateCount(idToLotteryTicket[id].ticketPrice,countIn);


        // 判断 
        if (keccak256(abi.encodePacked(idToLotteryTicket[id].buyType)) == keccak256("20")) {
            // erc20 支付
            IERC20(tokenAddress).transferFrom(owner, address(this), value);
        }else {
            // 本币支付
            require(msg.value >= value, "not enough value");
            if (msg.value > value) {
                // 多出的退回去
                payable(owner).transfer(msg.value - value);
            }
        }
        idToOwnerBalance[id][owner] += value;

        uint256 ticketStartIdx = idToLotteryAward[id].soldCount;
        uint256 ticketEndIdx = ticketStartIdx + countOut - 1;
        if (idToUserTicketIdxs[id][owner].length == 0) {
            idToUsers[id].push(owner);
        }
        idToUserTicketIdxs[id][owner].push([ticketStartIdx, ticketEndIdx]);
        emit BuyTickets(msg.sender, ticketStartIdx, ticketEndIdx);

        idToUserTicketAmount[id][owner] += countOut;

        idToLotteryAward[id].soldCount += countOut;

        if (idToLotteryAward[id].soldCount == idToLotteryTicket[id].ticketAllAmount) {
            setlotteryStatus(id, Status.Openable);
        }
    }

    // 开奖
    function openLucky(uint256 id) external nonReentrant {
        require(idToLotteryAward[id].status == Status.Openable,"not openable");
        require((idToLotteryAward[id].soldCount == idToLotteryTicket[id].ticketAllAmount) || (block.timestamp >= idToLotteryAward[id].endTime && idToSupportOpen[id]),"can not open lucky");
        rng.requestRandomNumber(id);
        setlotteryStatus(id, Status.Opening);
    }

    // 领奖
    function claim(uint256 id, address owner, uint256 idx) external {
        require(idToLotteryAward[id].status == Status.Claimable && !idToWinnerClaimed[id],"not claimable");
        require(block.timestamp >= idToLotteryAward[id].endTime,"not end");

        require(idToUserTicketIdxs[id][owner].length > idx, "only valid idx");

        uint256[][] memory ticketIdxs = idToUserTicketIdxs[id][owner];
        uint256 ticketStartIdx = ticketIdxs[idx][0];
        uint256 ticketEndIdx = ticketIdxs[idx][1];
        require(idToLotteryAward[id].luckyTicket >= ticketStartIdx && idToLotteryAward[id].luckyTicket <= ticketEndIdx,"not the winner");

        idToWinnerClaimed[id] = true;

        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("20")) { // erc20
            IERC20(idToLotteryAward[id].tokenAddress).transferFrom(address(this),owner,idToLotteryAward[id].tokenAmount);
        } 
        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("bnb")) { // bnb
            payable(owner).transfer(idToLotteryAward[id].tokenAmount);
        }
        emit NftClaimed(owner);
        if (idToWinnerClaimed[id] && idToOwnerClaimed[id]) {
            setlotteryStatus(id, Status.End);
        }
    }

    // 合约款项
    function claimPayment(uint256 id, address owner) external onlyWhitelist(id){
        require(idToLotteryAward[id].status == Status.Claimable && !idToOwnerClaimed[id],"not claimable");

        idToOwnerClaimed[id] = true;
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit PaymentClaimed(owner);
        if (idToWinnerClaimed[id] && idToOwnerClaimed[id]) {
            setlotteryStatus(id, Status.End);
        }
    }

    // 留局
    function refundUser(uint256 id, uint256 start, uint256 end) external {
        require((block.timestamp >= idToLotteryAward[id].endTime) && !idToSupportOpen[id],"not end");
        // 判断 
        if (keccak256(abi.encodePacked(idToLotteryTicket[id].buyType)) == keccak256("20")) {
            for (uint256 i = start; i <= end; i++) {
                // erc20 退还
                address user = idToUsers[id][i];
                uint256 balance = idToOwnerBalance[id][user];
                delete idToOwnerBalance[id][user];
                IERC20(idToLotteryTicket[id].buyToken).transfer(user,balance);
            }
        }else {
            for (uint256 i = start; i <= end; i++) {
                // bnb 退还
                address user = idToUsers[id][i];
                uint256 balance = idToOwnerBalance[id][user];
                delete idToOwnerBalance[id][user];
                payable(user).transfer(balance);
            }
        }
    }

    function refundOwner(uint256 id) external {
        require((block.timestamp >= idToLotteryAward[id].endTime) && !idToSupportOpen[id],"not end");
        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("20")) { // erc20
            IERC20(idToLotteryAward[id].tokenAddress).transfer(owner(), idToLotteryAward[id].tokenAmount);
        } 
        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("bnb")) { // bnb
            payable(owner()).transfer(idToLotteryAward[id].tokenAmount);
        } 
    }

    // 撤销
    function revoke(uint256 id) external onlyWhitelist(id){
        require((block.timestamp < idToLotteryAward[id].startTime),"had start");
        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("20")) { // erc20
            IERC20(idToLotteryAward[id].tokenAddress).transfer(msg.sender, idToLotteryAward[id].tokenAmount);
        } 
        if (keccak256(abi.encodePacked(idToLotteryAward[id].tokenType)) == keccak256("bnb")) { // bnb
            payable(msg.sender).transfer(idToLotteryAward[id].tokenAmount);
        } 
    }

    // chainlink 回调
    function receiveRandomNumber(uint256 id, uint256 _randomNumber) external {
        require(idToLotteryAward[id].status == Status.Opening, "not opening");
        idToRandomNumber[id] = _randomNumber;
        idToLotteryAward[id].luckyTicket = idToRandomNumber[id] % idToLotteryAward[id].soldCount;
        setlotteryStatus(id, Status.Claimable);
    }

    function getUsers(uint256 id) external view returns (address[] memory) {
        return idToUsers[id];
    }

    // 状态设置
    function setlotteryStatus(uint256 id, Status newStatus) private {
        idToLotteryAward[id].status = newStatus;
        emit lotteryStatusChanged(newStatus);
    }

    function addWhitelists(uint256 id, address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            idToIsWhitelist[id][addrs[i]] = true;
        }
    }

    function removeWhitelists(uint256 id, address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            delete idToIsWhitelist[id][addrs[i]];
        }
    }

    function addSupportOpen(uint256 id) external onlyOwner {
        idToSupportOpen[id] = true;
    }

    function removeSupportOpen(uint256 id) external onlyOwner {
        delete idToSupportOpen[id];
    }
}