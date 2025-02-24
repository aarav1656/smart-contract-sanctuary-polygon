// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ItemPool.sol";

interface INFTConfig {
    function blindBoxMint(address toAddress) external returns (uint256);
}

contract BlindBox is OwnableUpgradeable, ItemPool, ReentrancyGuardUpgradeable {
    IERC20Upgradeable public token_n;
    IERC20Upgradeable public token_s;
    INFTConfig public nft;

    uint256 constant public max_count_user = 5;
    uint256 constant public all_count_n = 500;
    uint256 constant public all_count_s = 500;

    uint256 public valid_count_n;
    uint256 public valid_count_s;
    uint256 public max_count_user_n;
    uint256 public max_count_user_s;
    mapping(address => uint) public user_buy_count_n;
    mapping(address => uint) public user_buy_count_s;

    uint256 public start_time;
    uint256 public end_time;
    uint256 public white_time;

    uint256 constant public price_n = 2 ether;
    uint256 constant public price_w_n = 1 ether;
    uint256 constant public price_s = 100 ether;
    uint256 constant public price_w_s = 50 ether;

    mapping(address => bool) public white_list;

    event eventBlindBoxMint(address indexed toAddress, uint256 indexed tokenId, uint256 indexed tokenType);
    event eventOpenResult(uint256 indexed itemType, uint256 indexed itemAmount);

    modifier checkWhiteList()
    {
        require(white_list[_msgSender()], 'not white list');

        _;
    }

    function initialize(IERC20Upgradeable _n, IERC20Upgradeable _s, INFTConfig _nft) public initializer
    {
        __Ownable_init();

        __ReentrancyGuard_init();

        updateNToken(_n);
        updateSToken(_s);
        updateNFT(_nft);

        _initItemPoolN();
        _initItemPoolS();

        valid_count_n = all_count_n;
        valid_count_s = all_count_s;
        max_count_user_n = max_count_user;
        max_count_user_s = max_count_user;
    }

    function updateNToken(IERC20Upgradeable _n) public onlyOwner
    {
        require(_n != IERC20Upgradeable(address(0)), "_n error");
        token_n = _n;
    }

    function updateSToken(IERC20Upgradeable _s) public onlyOwner
    {
        require(_s != IERC20Upgradeable(address(0)), "_s error");
        token_s = _s;
    }

    function updateNFT(INFTConfig _nft) public onlyOwner
    {
        require(_nft != INFTConfig(address(0)), "_nft error");
        nft = _nft;
    }

    function updateItemPoolN(ITEM_POOL[] memory _itemPool) external onlyOwner
    {
        _updateItemPoolN(_itemPool);
    }

    function updateItemPoolS(ITEM_POOL[] memory _itemPool) external onlyOwner
    {
        _updateItemPoolS(_itemPool);
    }

    function updateMaxCountUserN(uint256 _maxCount) external onlyOwner
    {
        max_count_user_n = _maxCount;
    }

    function updateMaxCountUserS(uint256 _maxCount) external onlyOwner
    {
        max_count_user_s = _maxCount;
    }

    function updateStartEndWhiteTime(uint256 _startTime, uint256 _endTime, uint256 _whiteTime) external onlyOwner
    {
        start_time = _startTime;
        end_time = _endTime;
        white_time = _whiteTime;
    }

    function updateWhiteList(address[] memory _sender, bool _flag) public onlyOwner
    {
        for(uint256 i = 0; i < _sender.length; i++){
            white_list[_sender[i]] = _flag;
        }
    }

    function random(uint256 _boxType, uint256 _index) public view returns (uint256)
    {
        uint256 init_total_weight = 0;

        if (_boxType == ITEM_TYPE_1)
        {
            init_total_weight = total_weight_n;
        }
        else
        {
            init_total_weight = total_weight_s;
        }

        uint256 randomNum = uint256(
            keccak256(abi.encode(tx.gasprice,
            tx.origin,
            block.number,
            block.timestamp,
            block.difficulty,
            init_total_weight,
            _index))
        );
        return randomNum % init_total_weight;
    }

    function buyBox(uint256 _amount, uint256 _boxType) external payable nonReentrant
    {
        require(_msgSender() == tx.origin, "sender error");
        require(block.timestamp >= start_time && block.timestamp < end_time, "time limit");
        if (_boxType == ITEM_TYPE_1)
        {
            require(msg.value >= price_n * _amount, "value error");
            require(valid_count_n >= _amount, "amount error");
            require(user_buy_count_n[_msgSender()] + _amount <= max_count_user_n, "amount limit");
        }
        else
        {
            require(msg.value >= price_s * _amount, "value error");
            require(valid_count_s >= _amount, "amount error");
            require(user_buy_count_s[_msgSender()] + _amount <= max_count_user_s, "amount limit");
        }

        openBox(_msgSender(), _amount, _boxType);
    }

    function whiteBuyBox(uint256 _amount, uint256 _boxType) external payable nonReentrant checkWhiteList
    {
        require(_msgSender() == tx.origin, "sender error");
        require(block.timestamp >= white_time && block.timestamp < start_time, "time limit");

        if (_boxType == ITEM_TYPE_1)
        {
            require(msg.value >= price_w_n * _amount, "value error");
            require(valid_count_n >= _amount, "amount error");
            require(user_buy_count_n[_msgSender()] + _amount <= max_count_user_n, "amount limit");
        }
        else
        {
            require(msg.value >= price_w_s * _amount, "value error");
            require(valid_count_s >= _amount, "amount error");
            require(user_buy_count_s[_msgSender()] + _amount <= max_count_user_s, "amount limit");
        }

        openBox(_msgSender(), _amount, _boxType);
    }

    function openBox(address _beneficiary, uint256 _amount, uint256 _boxType) internal
    {
        ITEM_POOL[] storage init_item_pool;
        uint256 init_total_weight = 0;

        if (_boxType == ITEM_TYPE_1)
        {
            init_item_pool = item_pool_n;
            init_total_weight = total_weight_n;
        }
        else
        {
            init_item_pool = item_pool_s;
            init_total_weight = total_weight_s;
        }
        
        for (uint256 i = 0; i < _amount; i++)
        {
            uint256 random_val = random(_boxType, i);
            uint256 tmp_sum = 0;
            for (uint256 j = 0; j < init_item_pool.length; j++)
            {

                if (init_item_pool[j].total_times == 0)
                    continue;

                tmp_sum += init_item_pool[j].item_weight;
                if (random_val >= tmp_sum)
                    continue;

                sendReward(_beneficiary, init_item_pool[j]);

                init_item_pool[j].total_times -= 1;
                if (init_item_pool[j].total_times == 0)
                    init_total_weight -= init_item_pool[j].item_weight;

                break;
            }
        }

        if (_boxType == ITEM_TYPE_1)
        {
            total_weight_n = init_total_weight;
            valid_count_n -= _amount;
            user_buy_count_n[_beneficiary] += _amount;
        }
        else
        {
            total_weight_s = init_total_weight;
            valid_count_s -= _amount;
            user_buy_count_s[_beneficiary] += _amount;
        }
    }

    function sendReward(address _beneficiary, ITEM_POOL memory _reward_item) internal
    {
        if (_reward_item.item_type == ITEM_TYPE_1)
        {
            //ERC20 N
            token_n.transfer(_beneficiary, _reward_item.item_amount * (10 ** 18));
        }
        else if (_reward_item.item_type == ITEM_TYPE_2)
        {
            //ERC20 S
            token_s.transfer(_beneficiary, _reward_item.item_amount * (10 ** 18));
        }
        else
        {
            //ERC721
            uint256 tokenId = nft.blindBoxMint(_beneficiary);
            emit eventBlindBoxMint(_beneficiary, tokenId, _reward_item.item_type);
        }

        emit eventOpenResult(_reward_item.item_type, _reward_item.item_amount);
    }
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
pragma solidity ^0.8.0;

abstract contract ItemPool {

    // n-token
    uint constant internal ITEM_TYPE_1 = 1;
    // s-token
    uint constant internal ITEM_TYPE_2 = 2;

    struct ITEM_POOL
    {
        uint item_type;
        uint total_times;
        uint item_amount;
        uint item_weight;
    }

    ITEM_POOL[] public item_pool_n;
    ITEM_POOL[] public item_pool_s;
    uint public total_weight_n;
    uint public total_weight_s;

    function _initItemPoolN() internal
    {
        delete item_pool_n;

        item_pool_n.push(ITEM_POOL(1, 25, 2000, 1000));
        item_pool_n.push(ITEM_POOL(1, 138, 10000, 5500));
        item_pool_n.push(ITEM_POOL(1, 75, 35000, 3000));
        item_pool_n.push(ITEM_POOL(10, 25, 1, 1000));
        item_pool_n.push(ITEM_POOL(11, 137, 1, 5500));
        item_pool_n.push(ITEM_POOL(12, 75, 1, 3000));
        item_pool_n.push(ITEM_POOL(13, 25, 1, 500));

        uint total = 0;

        for (uint i = 0; i != item_pool_n.length; i++)
        {
            total += item_pool_n[i].item_weight;
        }

        total_weight_n = total;
    }

    function _initItemPoolS() internal
    {
        delete item_pool_s;

        item_pool_s.push(ITEM_POOL(2, 25, 2000, 1000));
        item_pool_s.push(ITEM_POOL(2, 138, 10000, 5500));
        item_pool_s.push(ITEM_POOL(2, 75, 35000, 3000));
        item_pool_s.push(ITEM_POOL(20, 25, 1, 1000));
        item_pool_s.push(ITEM_POOL(21, 137, 1, 5500));
        item_pool_s.push(ITEM_POOL(22, 75, 1, 3000));
        item_pool_s.push(ITEM_POOL(23, 25, 1, 500));

        uint total = 0;

        for (uint i = 0; i != item_pool_s.length; i++)
        {
            total += item_pool_s[i].item_weight;
        }

        total_weight_s = total;
    }

    function _updateItemPoolN(ITEM_POOL[] memory _itemPool) internal
    {

        delete item_pool_n;
        uint tmp_weight = 0;

        for (uint i=0; i!= _itemPool.length; i++)
        {
             item_pool_n.push(_itemPool[i]);

             tmp_weight += _itemPool[i].item_weight;
        }
        total_weight_s = tmp_weight;
    }

    function _updateItemPoolS(ITEM_POOL[] memory _itemPool) internal
    {

        delete item_pool_s;
        uint tmp_weight = 0;

        for (uint i=0; i!= _itemPool.length; i++)
        {
             item_pool_s.push(_itemPool[i]);

             tmp_weight += _itemPool[i].item_weight;
        }
        total_weight_s = tmp_weight;
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