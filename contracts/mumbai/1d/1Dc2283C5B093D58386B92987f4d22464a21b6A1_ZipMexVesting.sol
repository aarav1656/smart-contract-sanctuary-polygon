// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";


contract ZipMexVesting is Initializable, OwnableUpgradeable{
    using SafeMathUpgradeable for uint;

    IERC20 public token;

    uint private poolCount;

    event Claim(address indexed from, uint indexed poolIndex, uint tokenAmount);
    event VestingPoolAdded(uint indexed poolIndex, uint totalPoolTokenAmount);
    event BeneficiaryAdded(uint indexed poolIndex, address indexed beneficiary, uint addedTokenAmount);
    event BeneficiaryRemoved(uint indexed poolIndex, address indexed beneficiary, uint unlockedPoolAmount);

    struct Beneficiary {
        uint currentIndex;
        uint totalTokens;
        uint claimedTotalTokenAmount;
        bool beneficiaryStatus;
    }

    struct Pool {
        bool initialized;
        string name;

        uint[] releaseTimes;
        uint[] releaseAmountPercentage;

        mapping(address => Beneficiary) beneficiaries;

        uint totalPoolTokenAmount;
        uint lockedPoolTokens;
    }

    mapping(uint => Pool) private vestingPools;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(IERC20 _token) 
        public
        initializer

    {
        __Ownable_init();

        token = _token;
        poolCount = 0;

    }

    /**
    * @notice Checks whether the address is not zero.
    */
    modifier addressNotZero(address _address) {
        require(
            _address != address(0),
            "ZipMexVesting: Wallet address can not be zero."
        );
        _;
    }

    /**
    * @notice Checks whether the given pool index points to an existing pool.
    */
    modifier poolExists(uint _poolIndex) {
        require(
           vestingPools[_poolIndex].initialized == true,
            "ZipMexVesting: Pool does not exist."
        );
        _;
    }

    /**
    * @notice Checks whether the new pool's name already exist.
    */
    modifier nameDoesNotExist(string memory _name) {
        bool exists = false;
        for(uint i = 0; i < poolCount; i++){
            if(keccak256(abi.encodePacked(vestingPools[i].name)) == keccak256(abi.encodePacked(_name))){
                exists = true;
                break;
            }
        }
        require( 
            !exists, 
            "ZipMexVesting: Vesting pool with such name already exists.");
        _;
    }
    
    /**
    * @notice Checks whether token amount > 0.
    */
    modifier tokenAmountNotZero(uint _tokenAmount) {
        require(
            _tokenAmount > 0,
            "ZipMexVesting: Token amount can not be 0."
        );
        _;
    }

    /**
    * @notice Checks whether the address is beneficiary of the pool.
    */
    modifier onlyBeneficiary(uint _poolIndex) {
        require(
            vestingPools[_poolIndex].beneficiaries[msg.sender].beneficiaryStatus = true,
            "ZipMexVesting: Address is not in the beneficiary list."
        );
        _;
    }

    /**
    * @notice Checks whether the caller is admin or beneficiary of the pool.
    */
    modifier onlyAdminOrBeneficiary(uint _poolIndex) {
        address _owner = owner();
        bool isOwner;
        bool isBeneficiary;
        if(_owner == msg.sender){
            isOwner = true;
        }
        if(vestingPools[_poolIndex].beneficiaries[msg.sender].beneficiaryStatus == true){
            isBeneficiary = true;
        }
        require(
            isOwner || isBeneficiary,
            "ZipMexVesting: Only the Admin or a whitelisted beneficiary can update investment."
        );
        _;
    }

    /**
    * @notice Adds new vesting pool.
    * @param _name Vesting pool name, Project ID created in Launchpad.
    * @param _releaseTimes Array of timestamps corresponding to release.
    * @param _releaseAmountPercentage Array of release percentages.
    * @param _totalPoolTokenAmount Allocated tokens for a specific pool, Target fund for project.
    */
    function addVestingPool (
        string memory _name,
        uint[] memory _releaseTimes,
        uint[] memory _releaseAmountPercentage,
        uint _totalPoolTokenAmount)
        external
        onlyOwner
        nameDoesNotExist(_name)
        tokenAmountNotZero(_totalPoolTokenAmount)
    {
        uint totalPercent = 0;
        vestingPools[poolCount].initialized = true;
        vestingPools[poolCount].name = _name;

        for (uint i = 0; i < _releaseTimes.length; i++) {
            require(
                _releaseTimes[i] > block.timestamp,
                "ZipMexVesting: Release time should be in the future."
            );
        }    
        vestingPools[poolCount].releaseTimes = _releaseTimes;

        for (uint i = 0; i < _releaseAmountPercentage.length; i++) {
            totalPercent += _releaseAmountPercentage[i];
        }    
        require(
            totalPercent == 100,
            "ZipMexVesting: Release percentages should add upto 100%"
        );
        vestingPools[poolCount].releaseAmountPercentage = _releaseAmountPercentage;

        vestingPools[poolCount].totalPoolTokenAmount = _totalPoolTokenAmount;

        poolCount++;

        emit VestingPoolAdded(poolCount - 1, _totalPoolTokenAmount);
    }

    /**
    * @notice Adds address with invested token amount to vesting pool.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    * @param _tokenAmount Invested token amount (incl. decimals).
    */
    function addToBeneficiariesList(
        uint _poolIndex,
        address _address,
        uint _tokenAmount)
        public
        onlyAdminOrBeneficiary(_poolIndex)
        addressNotZero(_address)
        poolExists(_poolIndex)
        tokenAmountNotZero(_tokenAmount)
    {
        // Pool storage p = vestingPools[_poolIndex];
        uint totalPoolAmount = vestingPools[_poolIndex].totalPoolTokenAmount;
        require(
            totalPoolAmount >= (vestingPools[_poolIndex].lockedPoolTokens + _tokenAmount),
            "ZipMexVesting: Allocated token amount will exceed total pool amount."
        );

        vestingPools[_poolIndex].lockedPoolTokens += _tokenAmount;
        vestingPools[_poolIndex].beneficiaries[_address].totalTokens += _tokenAmount;

        emit BeneficiaryAdded(_poolIndex, _address, _tokenAmount);
    }

    /**
    * @notice Adds addresses with invested token amounts to the beneficiary list.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _addresses List of whitelisted addresses.
    * @param _tokenAmount Purchased token absolute amount (with included decimals).
    * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
    */
    function addToBeneficiariesListMultiple(
        uint _poolIndex,
        address[] calldata _addresses,
        uint[] calldata _tokenAmount)
        external
        onlyOwner
    {
        require(
            _addresses.length == _tokenAmount.length, 
            "ZipMexVesting: Addresses and token amount arrays must be the same size."
            );

        for (uint i = 0; i < _addresses.length; i++) {
           addToBeneficiariesList(_poolIndex, _addresses[i], _tokenAmount[i]);
        }
    }

    /**
    * @notice Gives an investor beneficiary status of a project after getting whitelisted.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _beneficiary Address of beneficiary.
    */
    function addToWhitelist(uint _poolIndex, address _beneficiary)
        public
        onlyOwner
        addressNotZero(_beneficiary)
    {
        vestingPools[_poolIndex].beneficiaries[_beneficiary].beneficiaryStatus = true;
    }

    /**
    * @notice Gives multiple addresses beneficiary status after getting whitelisted.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param whitelists Array of whitelisted investors' addresses.
    */
    function uploadWhitelist(uint _poolIndex, address[] memory whitelists) 
        external
        onlyOwner 
    {
        for(uint i=0; i<whitelists.length; i++ ){
            addToWhitelist( _poolIndex, whitelists[i]);
        }
    }

    /**
    * @notice Function lets caller claim unlocked tokens from specified vesting pool.
    * @param _poolIndex Index that refers to vesting pool object.
    */
    function claimTokens(uint _poolIndex)
        external
        poolExists(_poolIndex)
        addressNotZero(msg.sender)
        onlyBeneficiary(_poolIndex)
    {
        uint unlockedTokens = unlockedTokenAmount(_poolIndex, msg.sender);
        require(
            unlockedTokens > 0, 
            "ZipMexVesting: There are no claimable tokens yet."
        );
        require(
            unlockedTokens <= token.balanceOf(address(this)),
            "ZipMexVesting: There are not enough tokens in the contract."
        );
        vestingPools[_poolIndex].beneficiaries[msg.sender].claimedTotalTokenAmount += unlockedTokens;
        token.transfer(msg.sender, unlockedTokens);

        vestingPools[_poolIndex].beneficiaries[msg.sender].currentIndex += 1;
        emit Claim(msg.sender, _poolIndex, unlockedTokens);
    }

    /**
    * @notice Removes beneficiary from the structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    */
    function removeBeneficiary(uint _poolIndex, address _address)
        external
        onlyOwner
        poolExists(_poolIndex)
    {
        uint unlockedPoolAmount = vestingPools[_poolIndex].beneficiaries[_address].totalTokens - 
                                  vestingPools[_poolIndex].beneficiaries[_address].claimedTotalTokenAmount;
        vestingPools[_poolIndex].lockedPoolTokens -= unlockedPoolAmount;
        delete vestingPools[_poolIndex].beneficiaries[_address];
        emit BeneficiaryRemoved(_poolIndex, _address, unlockedPoolAmount);
    }

    /**
    * @notice Transfers tokens to the selected recipient.
    * @param _address Address of the recipient.
    * @param _tokenAmount Absolute token amount (with included decimals).
    */
    function withdrawContractTokens( 
        address _address, 
        uint256 _tokenAmount)
        external 
        onlyOwner 
        addressNotZero(_address) 
    {
        token.transfer(_address, _tokenAmount);
    }

    /**
    * @notice Calculates unlocked and unclaimed tokens based on upcoming release date.
    * @param _address Address of the beneficiary wallet.
    * @param _poolIndex Index that refers to vesting pool object.
    * @return uint total unlocked and unclaimed tokens.
    */
    function unlockedTokenAmount(uint _poolIndex, address _address)
        public
        view
        returns (uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint unlockedTokens = 0;
        uint currentVestingIndex = b.currentIndex;

        require(
            currentVestingIndex < p.releaseTimes.length,
            "ZipMexVesting: No more withdrawals scheduled for the current vesting schedule."
        );

        if (block.timestamp < p.releaseTimes[currentVestingIndex]) { 
            // Next release time not reached yet.
            return unlockedTokens;
        } 
        else
        { 
            require(
                b.claimedTotalTokenAmount < b.totalTokens,
                "ZipMexVesting: Cannot claim more than invested."
            );
            uint percentage = p.releaseAmountPercentage[currentVestingIndex];
            uint multiplier = percentage*100;

            unlockedTokens = b.totalTokens * multiplier /10000;

        }
        return unlockedTokens;
    }
    
    /**
    * @notice Checks how many tokens unlocked in a pool (not allocated to any user).
    * @param _poolIndex Index that refers to vesting pool object.
    */
    function totalUnlockedPoolTokens(uint _poolIndex) 
        external
        view
        returns (uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        return p.totalPoolTokenAmount - p.lockedPoolTokens;
    }

    /**
    * @notice View of the beneficiary structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    * @return Beneficiary structure information.
    */
    function beneficiaryInformation(uint _poolIndex, address _address)
        external
        view
        returns (
            uint,
            uint
        )
    {
        Beneficiary storage b = vestingPools[_poolIndex].beneficiaries[_address]; //memory keyword
        return (
            b.totalTokens,
            b.claimedTotalTokenAmount
        );
    }

    /**
    * @notice View of next release time and amount for a beneficiary in a given pool.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    * @return uint Next release time.
    * @return uint Next release amount.
    */
    function getNextReleaseTimeAndAmount(uint _poolIndex, address _address)
        external
        view
        returns (uint, uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint nextReleaseTime;
        uint nextReleaseAmount;
        uint currentVestingIndex = b.currentIndex;

        if(currentVestingIndex > p.releaseTimes.length){
            return(0,0);
        }
        else {
            
        uint percentage = p.releaseAmountPercentage[currentVestingIndex];
        uint multiplier = percentage * 100;

        nextReleaseTime = p.releaseTimes[currentVestingIndex];
        nextReleaseAmount = b.totalTokens*multiplier/10000;

        } 
        return (nextReleaseTime,nextReleaseAmount);
    }

    /**
    * @notice Return number of pools in contract.
    * @return uint pool count.
    */
    function getPoolCount() 
        external
        view
        returns (uint)
    {
        return poolCount;
    }

    /**
    * @notice Return claimable token address
    * @return IERC20 token.
    */
    function getToken() 
        external
        view
        returns (IERC20)
    {
        return token;
    }
    
    /**
    * @notice Returns pool index of a project.
    * @param _name Name of the project (ProjectID).
    * @return uint Vesting pool index.
    */
    function getPoolIndex(string memory _name)
        external
        view
        returns (uint)
    {
        uint poolIndex = 0;
        for(uint i = 0; i < poolCount; i++){
            if(keccak256(abi.encodePacked(vestingPools[i].name)) == keccak256(abi.encodePacked(_name))){
                poolIndex = i;
                break;
            }
        }
        return poolIndex;
    }

    /**
    * @notice View of the vesting pool structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @return Part of the vesting pool information.
    */
    function poolData(uint _poolIndex)
        external
        view
        returns (
            bool,
            string memory,
            uint
        )
    {
        Pool storage p = vestingPools[_poolIndex];
        return(
            p.initialized,
            p.name,
            p.totalPoolTokenAmount
        );        
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
library SafeMathUpgradeable {
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