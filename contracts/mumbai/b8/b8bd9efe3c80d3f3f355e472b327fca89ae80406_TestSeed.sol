/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

//SPDX-License-Identifier: MIT
// File: TestSeed_flat.sol


// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


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
// File: contracts/Auth.sol


pragma solidity ^0.8.0;

// OpenZeppelin implementations


abstract contract Auth is Initializable {
    address internal owner;

    mapping(address => bool) internal authorizations;

    event OwnershipTransferred(address owner);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Auth: Caller is not the owner");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "Auth: Caller is not authorized");
        _;
    }

    function __Auth_init(address _owner) internal onlyInitializing {
        owner = _owner;
        authorizations[_owner] = true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function authorize(address _account) public onlyOwner {
        authorizations[_account] = true;
    }

    function unauthorize(address _account) public onlyOwner {
        authorizations[_account] = false;
    }

    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }

    function isAuthorized(address _account) public view returns (bool) {
        return authorizations[_account];
    }

    function transferOwnership(address payable _account) public onlyOwner {
        owner = _account;
        authorizations[_account] = true;
        emit OwnershipTransferred(_account);
    }
}
// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/TestSeed.sol


pragma solidity ^0.8.0;

// OpenZeppelin implementations



// Auth contract


contract TestSeed is Auth {
    IERC20Upgradeable public sleepToken;

    bool public isClaimable;

    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;

    uint256 public softCapEthAmount;
    uint256 public hardCapEthAmount;

    uint256 public totalDepositedEthBalance;

    uint256 public minimumDepositEthAmount;
    uint256 public maximumDepositEthAmount;

    uint256 public tokenPrice;
    uint256 public tokenDecimal;

    uint256 public vestingPeriods;
    uint256 public vestingPeriodDenomination;

    bool public onlyWhitelist;
    mapping(address => bool) public whitelist;

    mapping(address => uint256) public deposits;

    struct ClaimableTokens {
        uint256 tokenAmount;
        uint256 dateDeposited;
        uint256 lastClaimedDate;
    }
    mapping(address => ClaimableTokens[]) claimableTokens;

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event Claimed(address addr, uint256 amount);

    function initialize(address _owner, IERC20Upgradeable _sleepToken)
        public
        initializer
    {
        __Auth_init(msg.sender);

        sleepToken = _sleepToken;

        isClaimable = false;

        softCapEthAmount = 1 ether;
        hardCapEthAmount = 2 ether;

        minimumDepositEthAmount = 0.001 ether;
        maximumDepositEthAmount = 0.5 ether;

        tokenPrice = 0.4 ether;
        tokenDecimal = 1e18;

        vestingPeriods = 30;
        vestingPeriodDenomination = 1 days;

        onlyWhitelist = true;
        whitelist[_owner] = true;

        presaleStartTimestamp = block.timestamp;
        presaleEndTimestamp = block.timestamp + 10 days + 1 hours + 30 minutes;
    }

    function setPresaleTime(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end, "start must be less than end");
        presaleStartTimestamp = _start;
        presaleEndTimestamp = _end;
    }

    function setMinMaxDepositAmounts(uint256 _min, uint256 _max)
        external
        onlyOwner
    {
        minimumDepositEthAmount = _min;
        maximumDepositEthAmount = _max;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setSoftCap(uint256 _softCap) external onlyOwner {
        softCapEthAmount = _softCap;
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCapEthAmount = _hardCap;
    }

    function setTokenDecimal(uint256 _tokenDecimal) external onlyOwner {
        tokenDecimal = _tokenDecimal;
    }

    function setVestingSettings(
        uint256 _vestingPeriods,
        uint256 _vestingPeriodDenomination
    ) external onlyOwner {
        vestingPeriods = _vestingPeriods;
        vestingPeriodDenomination = _vestingPeriodDenomination;
    }

    function setWhitelistStatus(bool _status) external onlyOwner {
        onlyWhitelist = _status;
    }

    function manageWhitelist(address[] calldata _addresses, bool _status)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function setToken(address _address) external onlyOwner {
        require(
            _address != address(0),
            "token address cannot be the zero address"
        );
        sleepToken = IERC20Upgradeable(_address);
    }

    function setClaimable(bool _isClaimable) external onlyOwner {
        isClaimable = _isClaimable;
    }

    receive() external payable {
        // React to receiving bnb
        deposit();
    }

    function deposit() public payable {
        require(
            block.timestamp >= presaleStartTimestamp &&
                block.timestamp <= presaleEndTimestamp,
            "presale is not active"
        );
        require(
            totalDepositedEthBalance + msg.value <= hardCapEthAmount,
            "deposit limits reached"
        );
        require(
            deposits[msg.sender] + msg.value >= minimumDepositEthAmount &&
                deposits[msg.sender] + msg.value <= maximumDepositEthAmount,
            "amount deposited does not satisfy min and max requirements"
        );

        if (!whitelist[msg.sender]) {
            require(
                !onlyWhitelist,
                "Only whitelisted wallets can purchase tokens at this time"
            );
        }

        uint256 newBalance = deposits[msg.sender] + msg.value;

        uint256 tokenAmount = (msg.value * tokenDecimal) / tokenPrice;
        claimableTokens[msg.sender].push(
            ClaimableTokens(tokenAmount, block.timestamp, 0)
        );

        deposits[msg.sender] = newBalance;
        totalDepositedEthBalance += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function getUserClaimableTokens(address _address)
        external
        view
        returns (uint256)
    {
        uint256 tokenAmount = 0;
        uint256 totalVestingPeriod = vestingPeriods * vestingPeriodDenomination;

        ClaimableTokens[] memory userClaimableTokens = claimableTokens[
            _address
        ];
        for (uint256 i = 0; i < userClaimableTokens.length; i++) {
            if (userClaimableTokens[i].lastClaimedDate == 0) {
                tokenAmount += (userClaimableTokens[i].tokenAmount * 25) / 100;
                userClaimableTokens[i].lastClaimedDate = userClaimableTokens[i]
                    .dateDeposited;
            }

            uint256 lastPossibleClaimDate = userClaimableTokens[i]
                .dateDeposited + totalVestingPeriod;
            if (
                userClaimableTokens[i].lastClaimedDate <= lastPossibleClaimDate
            ) {
                uint256 claimDate = block.timestamp > lastPossibleClaimDate
                    ? lastPossibleClaimDate
                    : block.timestamp;
                uint256 numDurationsPassed = (claimDate -
                    userClaimableTokens[i].lastClaimedDate) /
                    vestingPeriodDenomination;
                tokenAmount +=
                    numDurationsPassed *
                    (((userClaimableTokens[i].tokenAmount * 75) / 100) /
                        vestingPeriods);
                userClaimableTokens[i].lastClaimedDate = claimDate;
            }
        }

        return tokenAmount;
    }

    function claim() external {
        require(isClaimable, "Tokens not yet claimable");

        uint256 tokenAmount = 0;
        uint256 totalVestingPeriod = vestingPeriods * vestingPeriodDenomination;

        ClaimableTokens[] storage userClaimableTokens = claimableTokens[
            msg.sender
        ];
        for (uint256 i = 0; i < userClaimableTokens.length; i++) {
            if (userClaimableTokens[i].lastClaimedDate == 0) {
                tokenAmount += (userClaimableTokens[i].tokenAmount * 25) / 100;
                userClaimableTokens[i].lastClaimedDate = userClaimableTokens[i]
                    .dateDeposited;
            }

            uint256 lastPossibleClaimDate = userClaimableTokens[i]
                .dateDeposited + totalVestingPeriod;
            if (
                userClaimableTokens[i].lastClaimedDate <= lastPossibleClaimDate
            ) {
                uint256 claimDate = block.timestamp > lastPossibleClaimDate
                    ? lastPossibleClaimDate
                    : block.timestamp;
                uint256 numDurationsPassed = (claimDate -
                    userClaimableTokens[i].lastClaimedDate) /
                    vestingPeriodDenomination;
                tokenAmount +=
                    numDurationsPassed *
                    (((userClaimableTokens[i].tokenAmount * 75) / 100) /
                        vestingPeriods);
                userClaimableTokens[i].lastClaimedDate = claimDate;
            }
        }

        sleepToken.transfer(msg.sender, tokenAmount);

        emit Claimed(msg.sender, deposits[msg.sender]);
    }

    function releaseFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function releaseTokens() external onlyOwner {
        sleepToken.transfer(msg.sender, sleepToken.balanceOf(address(this)));
    }

    function recoverBEP20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(getOwner(), _tokenAmount);

        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverBEP20Upgradeable(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        IERC20Upgradeable(_tokenAddress).transfer(getOwner(), _tokenAmount);

        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if (block.timestamp > presaleEndTimestamp) {
            return 0;
        } else {
            return (presaleEndTimestamp - block.timestamp);
        }
    }

    /* Airdrop */
    function seedSaleMultisender(
        address[] calldata _addresses,
        uint256[] calldata _tokens
    ) external onlyOwner {
        require(
            _addresses.length < 501,
            "GAS Error: max airdrop limit is 500 addresses"
        );
        require(
            _addresses.length == _tokens.length,
            "Mismatch between address and token count"
        );

        uint256 SCCC = 0;

        for (uint256 i = 0; i < _addresses.length; i++) {
            SCCC = SCCC + _tokens[i];
        }

        require(
            sleepToken.balanceOf(address(this)) >= SCCC,
            "Not enough tokens in wallet"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            sleepToken.transfer(_addresses[i], _tokens[i]);
        }
    }

    function seedSaleMultisender_fixed(
        address[] calldata _addresses,
        uint256 _tokens
    ) external onlyOwner {
        require(
            _addresses.length < 801,
            "GAS Error: max airdrop limit is 800 addresses"
        );

        uint256 SCCC = _tokens * _addresses.length;

        require(
            sleepToken.balanceOf(address(this)) >= SCCC,
            "Not enough tokens in wallet"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            sleepToken.transfer(_addresses[i], _tokens);
        }
    }
}