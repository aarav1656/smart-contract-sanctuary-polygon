// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UVReserve.sol";
import "./UVTakeProfit.sol";
import "./interfaces/IUVReserveFactory.sol";

contract UVReserveFactory is Ownable, AccessControl, IUVReserveFactory {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint8 => address) public managers;
    mapping(uint8 => address) public fundWallets;

    mapping(uint8 => address) public getPoolReserve;
    address[] public allPoolsReserve;
    mapping(uint8 => address) public getPoolTP;
    address[] public allPoolsTP;
    uint8 orderNumber = 0;

    event PoolCreated(address indexed reserveAddress, address indexed stakeAddress, uint8 orderNumber);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Create a new Reserve
    function createReserve(
        address _fundWallet,
        address _pool,
        address _manager
    ) public onlyRole(ADMIN_ROLE) {
        orderNumber += 1;
        address poolTP = address(new UVTakeProfit());
        address poolReserve = address(new UVReserve());
        IUVTakeProfit(poolTP).initialize(orderNumber, _pool, _fundWallet);
        IUVReserve(poolReserve).initialize(orderNumber, poolTP);

        getPoolReserve[orderNumber] = poolReserve;
        allPoolsReserve.push(poolReserve);
        getPoolTP[orderNumber] = poolTP;
        allPoolsTP.push(poolTP);
        managers[orderNumber] = _manager;
        fundWallets[orderNumber] = _fundWallet;

        emit PoolCreated(poolReserve, poolTP, orderNumber);
    }

    // Add Role to the pool
    function addPoolRole(uint8 _orderNumber, address _manager)
        public
        onlyOwner
    {
        IUVReserve(getPoolReserve[_orderNumber]).addManager(_manager);
        IUVTakeProfit(getPoolTP[_orderNumber]).addManager(_manager);
        managers[_orderNumber] = _manager;
    }

    // Remove Role from the pool
    function removePoolRole(uint8 _orderNumber, address _manager)
        public
        onlyOwner
    {
        IUVReserve(getPoolReserve[_orderNumber]).removeManager(_manager);
        IUVTakeProfit(getPoolTP[_orderNumber]).removeManager(_manager);

        managers[_orderNumber] = address(0);
    }

    // Add Role to the factory
    function addRole(address _addr) public onlyOwner {
        _setupRole(ADMIN_ROLE, _addr);
    }

    // Remove Role from the factory
    function removeRole(address _addr) public onlyOwner {
        _revokeRole(ADMIN_ROLE, _addr);
    }

    // Get length of all pools
    function getPoolsLength() public view returns (uint256) {
        return allPoolsReserve.length;
    }

    // Get info of a pool
    function getPoolInfo(uint8 _orderNumber)
        public
        view
        returns (
            address _poolReserve,
            address _poolTP,
            address _manager,
            address _fundWallet
        )
    {
        return (
            getPoolReserve[_orderNumber],
            getPoolTP[_orderNumber],
            managers[_orderNumber],
            fundWallets[_orderNumber]
        );
    }

    // Set fund wallet address for the pool
    function setFundWallet(uint8 _orderNumber, address _fundWallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        IUVReserve(getPoolReserve[_orderNumber]).setFundWallet(_fundWallet);
        IUVTakeProfit(getPoolTP[_orderNumber]).setFundWallet(_fundWallet);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./interfaces/IUVReserve.sol";

contract UVReserve is Ownable, AccessControl, IUVReserve {
    using SafeMath for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public constant SWAP_ROUTER_ADDRESS =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant stableCoin =
        0xAd7B2E9307d7ceBf18471358ffA7e0d34d87c130;
    uint24 public constant poolFee = 3000;

    ISwapRouter public swapRouter;
    address public factoryReserve;
    address public fundWallet;

    uint8 public orderNumber;
    address public tpPool;

    event SellToken(address indexed tokenInAddress, uint256 amountIn);

    constructor() {
        factoryReserve = msg.sender;
    }

    function initialize(uint8 _orderNumber, address _tpPool) external {
        require(msg.sender == factoryReserve, "FORBIDDEN");
        orderNumber = _orderNumber;
        tpPool = _tpPool;
        factoryReserve = msg.sender;
        swapRouter = ISwapRouter(SWAP_ROUTER_ADDRESS);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    // important to receive BNB
    receive() external payable {}

    fallback() external payable {}

    // Sell token on pancake router
    function sellToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        bytes calldata _path,
        uint256 _deadline
    ) public onlyRole(MANAGER_ROLE) {
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: _deadline,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin
            });

        // Executes the swap.
        uint256 realAmount = swapRouter.exactInput(params);

        emit SellToken(_tokenIn, realAmount);
    }

    // Transfer token from reserve to pool tp
    function transferTokenToTPPool(address token, uint256 amount)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(token != address(0));
        require(amount > 0);
        IERC20 tokenInstance = IERC20(token);
        tokenInstance.transfer(tpPool, amount);
    }

    // get pool reserve address
    function getPoolReserve() public view returns (address) {
        return address(this);
    }

    // Add wallet to manager role
    function addManager(address _manager) public onlyOwner {
        _setupRole(MANAGER_ROLE, _manager);
    }

    // Remove wallet from manager role
    function removeManager(address _manager) public onlyOwner {
        revokeRole(MANAGER_ROLE, _manager);
    }

    // Set the fund wallet
    function setFundWallet(address _fundWallet) public onlyOwner {
        fundWallet = _fundWallet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUVTakeProfit.sol";
import "./interfaces/IUVReserveFactory.sol";

contract UVTakeProfit is Ownable, AccessControl, IUVTakeProfit {
    using SafeMath for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct StakeInfo {
        uint8 Id;
        uint256 totalToken;
        uint8 decimals;
        uint256 remainingToken;
        address tokenAddress;
        uint64 closeTimestamp;
        uint64 openTimestamp;
        uint8 feePercent;
    }

    struct UserInfo {
        uint256 amount;
        uint256 stakeTime;
    }

    mapping(uint8 => mapping(address => UserInfo)) public users; // Key string Key is address
    mapping(uint8 => StakeInfo) public stakeInfos; // Key is address of token

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    address public factoryReserve;
    address public fundWallet;
    uint8 public orderNumber;
    address public poolToken;

    event WithdrawToken(
        address indexed user,
        address indexed tokenAddress,
        uint256 _amount
    );
    event FinishStake(address indexed user, uint256 _amount);

    constructor() {
        factoryReserve = msg.sender;
    }

    function initialize(
        uint8 _orderNumber,
        address _poolToken,
        address _fundWallet
    ) external {
        require(msg.sender == factoryReserve, "Only factory can initialize");
        orderNumber = _orderNumber;
        poolToken = _poolToken;
        fundWallet = _fundWallet;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}

    // Distribute tokens to users
    function distributeTokens(
        address[] memory _users,
        uint256 _amountDistribute,
        address _tokenAddress,
        uint8 _feePercent,
        uint8 _decimals
    ) public onlyRole(MANAGER_ROLE) {
        IERC20 instance = IERC20(_tokenAddress);
        IERC20 instancePoolToken = IERC20(poolToken);
        uint256 _totalSupply = instancePoolToken.totalSupply();
        uint256 totalFee = 0;
        uint256 amountDistribute = _amountDistribute;
        uint8 feePercent = _feePercent;
        uint256 dec = 10**(18 - _decimals);

        for (uint256 index = 0; index < _users.length; index++) {
            address user = _users[index];
            uint256 amount = instancePoolToken.balanceOf(user);

            uint256 multiples = 10**18;
            uint256 tokenPerPoolToken = amountDistribute.div(
                _totalSupply.div(multiples)
            );
            uint256 amountToUser = amount.mul(tokenPerPoolToken).div(multiples);
            uint256 fee = 0;
            if (feePercent > 0) {
                fee = (amountToUser.mul(feePercent)).div(1000);
                totalFee += fee;
            }
            instance.transfer(user, amountToUser.sub(fee).div(dec));
        }
        if (totalFee > 0) instance.transfer(fundWallet, totalFee.div(dec));
    }

    // Create stakeinfos token for user
    function createStakeInfo(
        uint8 _id,
        address _tokenAddress,
        uint256 _amount,
        uint64 _openTime,
        uint64 _closeTime,
        uint8 _feePercent,
        uint8 _decimals
    ) public onlyRole(MANAGER_ROLE) {
        require(_tokenAddress != address(0));
        require(stakeInfos[_id].openTimestamp == 0, "Stake is already created");
        require(_closeTime > block.timestamp);

        stakeInfos[_id].tokenAddress = _tokenAddress;
        stakeInfos[_id].totalToken = _amount;
        stakeInfos[_id].decimals = _decimals;
        stakeInfos[_id].remainingToken = _amount;
        stakeInfos[_id].closeTimestamp = _closeTime;
        stakeInfos[_id].openTimestamp = _openTime;
        stakeInfos[_id].feePercent = _feePercent;
    }

    // Withdraw Token
    function withdrawToken(uint8 _stakeId) external {
        uint256 _amountStake = IERC20(poolToken).balanceOf(msg.sender);
        require(_amountStake > 0, "You have no tokens to stake");

        IERC20(poolToken).transferFrom(msg.sender, address(this), _amountStake);
        users[_stakeId][msg.sender].amount = _amountStake;
        users[_stakeId][msg.sender].stakeTime = block.timestamp;

        require(
            users[_stakeId][msg.sender].amount > 0,
            "You have no tokens to withdraw"
        );
        uint256 _totalSupply = IERC20(poolToken).totalSupply();
        uint256 multiples = 10**18;
        uint256 tokenPerPoolToken = stakeInfos[_stakeId].totalToken.div(
            _totalSupply.div(multiples)
        );
        uint256 amountWithdraw = users[_stakeId][msg.sender]
            .amount
            .mul(tokenPerPoolToken)
            .div(multiples);

        uint256 totalToken = amountWithdraw;
        uint256 dec = 10**(18 - stakeInfos[_stakeId].decimals);
        uint256 fee = 0;
        if (stakeInfos[_stakeId].feePercent > 0) {
            fee = (totalToken.mul(stakeInfos[_stakeId].feePercent)).div(1000);
            IERC20(stakeInfos[_stakeId].tokenAddress).transfer(fundWallet, fee.div(dec));
        }

        IERC20(stakeInfos[_stakeId].tokenAddress).transfer(
            msg.sender,
            totalToken.sub(fee).div(dec)
        );

        stakeInfos[_stakeId].remainingToken -= totalToken;
        emit WithdrawToken(
            msg.sender,
            stakeInfos[_stakeId].tokenAddress,
            totalToken
        );
    }

    // Get pool reserved
    function getReserve() public view returns (address) {
        (address _poolReserved, , , ) = IUVReserveFactory(factoryReserve)
            .getPoolInfo(orderNumber);
        return _poolReserved;
    }

    // Finish Stake
    function finishStake() external onlyRole(MANAGER_ROLE) {
        IERC20 instance = IERC20(poolToken);

        instance.transfer(BURN_ADDRESS, instance.balanceOf(address(this)));
    }

    // Add wallet to manager role
    function addManager(address _manager) public onlyOwner {
        _setupRole(MANAGER_ROLE, _manager);
    }

    // Remove wallet from manager role
    function removeManager(address _manager) public onlyOwner {
        revokeRole(MANAGER_ROLE, _manager);
    }

    // Set the fund wallet
    function setFundWallet(address _fundWallet) public onlyOwner {
        fundWallet = _fundWallet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUVReserveFactory {
    function createReserve(
        address _fundWallet,
        address _pool,
        address _manager
    ) external;

    function addPoolRole(uint8 _orderNumber, address _manager) external;

    function removePoolRole(uint8 _orderNumber, address _manager) external;

    function addRole(address _addr) external;

    function removeRole(address _addr) external;

    function getPoolsLength() external view returns (uint256);

    function getPoolInfo(uint8 _orderNumber)
        external
        view
        returns (
            address _poolReserve,
            address _poolTP,
            address _manager,
            address _fundWallet
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
pragma solidity ^0.8.12;

interface IUVReserve {
    function initialize(uint8 _orderNumber, address _tpPool) external;

    function sellToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        bytes calldata _path,
        uint256 _deadline
    ) external;

    function setFundWallet(address _fundWallet) external;

    function transferTokenToTPPool(address token, uint256 amount) external;

    function getPoolReserve() external view returns (address);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUVTakeProfit {
    function initialize(
        uint8 _orderNumber,
        address _poolToken,
        address _fundWallet
    ) external;

    function createStakeInfo(
        uint8 _id,
        address _tokenAddress,
        uint256 _amount,
        uint64 _openTime,
        uint64 _closeTime,
        uint8 _feePercent,
        uint8 _decimals
    ) external;

    function setFundWallet(address _fundWallet) external;

    function withdrawToken(uint8 _stakeId) external;

    function finishStake() external;

    function addManager(address _manager) external;

    function removeManager(address _manager) external;
}