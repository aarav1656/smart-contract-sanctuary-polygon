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
pragma solidity 0.8.12;

import "./interfaces/IManagers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** TEST INFO
 * BotPrevention ve Main Vault contractı deploy edilmiştir.
 * Main Vault contract adresi, Souls Token adresi ve BotPrevention contract adresi  managers contractına güvenilir adres olarak kaydedildikten sonra managers contractın sahipliği Main Vault contracta aktarılmıştır.
 * Cüzdanda bulunan Stable tokenlar Main Vault contractına approve edilmiştir.
 * BotPrevention contractında token adresi olarak souls token adresi set edilmiştir.
 * botPrevention contractında Managers contractının adresi set edilmiştir.
 * Liquidity Vault contractı deploy edilmiş ve Main Vault contract üstünden init işlemi yapılmıştır.
 * Likidite eklenmesi sonucu oluşan pair adresi botPrevention contractına set edilmiştir.
 */
contract BotPrevention is Ownable {
    //Structs
    struct BotProtectionParams {
        uint256 activateIfBalanceExeeds;
        uint256 maxSellAmount;
        uint256 durationBetweenSells;
    }

    //Storage Variables
    IManagers private managers;
    BotProtectionParams public botPreventionParams;

    address public tokenAddress;
    address public dexPairAddress;

    uint256 public tradingStartTimeOnDEX; 
    uint256 public botPreventionDuration = 15 minutes;
    uint256 public currentSession;

    bool public tradingEnabled = true; 

    mapping(address => uint256) public walletCanSellAfter;
    mapping(uint256 => mapping(address => uint256)) private boughtAmountDuringBotProtection;

    //Custom Errors
    error BotPreventionAmountLock();
    error BotPreventionTimeLock();
    error SetTokenAddressFirst();
    error MustBeInTheFuture();
    error TradingIsDisabled();
    error TradingNotStarted();
    error AlreadyDisabled();
    error IncorrectToken();
    error AlreadyEnabled();
    error NotAuthorized();
    error ZeroAddress();
    error AlreadySet();

    //Events
    event ResetBotPreventionData(uint256 currentSession);
    event EnableTrading(address manager, bool isApproved);
    event DisableTrading(address manager, bool isApproved);

    constructor(uint256 _tradingStartTime) {
        //TODO: Decide the parameter values for bot protection
        botPreventionParams = BotProtectionParams({
            activateIfBalanceExeeds: 10000 ether,
            maxSellAmount: 1000 ether,
            durationBetweenSells: 10 minutes
        });
        tradingStartTimeOnDEX = _tradingStartTime;
    }

    //Modifiers
    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyTokenContract() {
        if (tokenAddress != msg.sender) {
            revert IncorrectToken();
        }
        _;
    }

    //Write Functions

    function setBotPreventionParams(
        uint256 _activationLimit,
        uint256 _maxSellAmount,
        uint256 _durationBetweenSellsInMinutes
    ) external onlyOwner {
        botPreventionParams = BotProtectionParams({
            activateIfBalanceExeeds: _activationLimit,
            maxSellAmount: _maxSellAmount,
            durationBetweenSells: _durationBetweenSellsInMinutes
        });
    }

    //Managers function
    /** TEST INFO
     * disableTrading ile birlikte test edilmiştir.
     */
    function enableTrading(uint256 _tradingStartTime, uint256 _botPreventionDurationInMinutes) external onlyManager {
        if (tokenAddress == address(0)) {
            revert SetTokenAddressFirst();
        }
        if (tradingEnabled) {
            revert AlreadyEnabled();
        }
        if (_tradingStartTime < block.timestamp) {
            revert MustBeInTheFuture();
        }

        string memory _title = "Enable/Disable Trading";
        bytes memory _encodedValues = abi.encode(true, _tradingStartTime, _botPreventionDurationInMinutes);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            tradingEnabled = true;
            tradingStartTimeOnDEX = _tradingStartTime;
            botPreventionDuration = _botPreventionDurationInMinutes * 1 minutes;
            managers.deleteTopic(_title);
        }
        emit EnableTrading(msg.sender, _isApproved);
    }

    //Managers function
    /** TEST INFO
     **** Managers can disable trading by voting
     * 3 manager tarafından contract üstünde trading işlemi disable edilmiştir.
     * Daha sonra trade yapılması denediğinde 'TransferHelper: TRANSFER_FROM_FAILED' hatası döndüğü gözlemlenmiştir.
     * 3 manager tarafından trading tekrar enable edilmiştir.
     * Blok zamanı yeni trading başlangıç zamanına simüle edilmiştir.
     * Trade yapılması denendiğinde 'TransferHelper: TRANSFER_FROM_FAILED' hatası döndüğü gözlemlenmiştir.
     * Blok zamanı bir sonraki trade işleminin yapılabileceği zamana simüle edilmiş ve trade işleminin başarılı bir şekilde yapılabildiği gözlemlenmiştir.
     * */
    function disableTrading() external onlyManager {
        if (!tradingEnabled) {
            revert AlreadyDisabled();
        }
        string memory _title = "Enable/Disable Trading";
        bytes memory _encodedValues = abi.encode(false, 0, 0);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            tradingEnabled = false;
            managers.deleteTopic(_title);
        }
        emit DisableTrading(msg.sender, _isApproved);
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function resetBotPreventionData() external onlyTokenContract {
        tradingStartTimeOnDEX = block.timestamp;
        currentSession++;

        emit ResetBotPreventionData(currentSession);
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            revert ZeroAddress();
        }
        if (tokenAddress != address(0)) {
            revert AlreadySet();
        }
        tokenAddress = _tokenAddress;
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function setManagersAddress(address _address) external onlyOwner {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        managers = IManagers(_address);
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function setDexPairAddress(address _pairAddress) external onlyOwner {
        if (dexPairAddress != address(0)) {
            revert AlreadySet();
        }
        if (_pairAddress == address(0)) {
            revert ZeroAddress();
        }
        dexPairAddress = _pairAddress;
        // tradingEnabled = false;
    }

    /** TEST INFO
	 
	 **** Swapping tokens is not available when trading is disabled
	 * Trading enable edilmeden swap yapılması denendiğinde 'Pancake: TRANSFER_FAILED' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Managers can enable trading by voting
	 * 3 Manager hesap tarafından trading işleminin aktifleştirilebildiği gözlemlenmiştir.
	 * Aktifleştirme sırasında gönderilen trading start time ve bot prevention duration parametrelerinin ilgili değişkenlere aktarıldığı gözlemlenmiştir.
	 
	 **** Swapping tokens is not available when trading is enabled but before trading start time
	 * Trading enable edilmiş durumdayken 10 Stable token SOULS tokena swap edilmek istenmiş ve 'Pancake: TRANSFER_FAILED' hatası döndüğü gözlemlenmiştir.
	 
	 ****  Swapping tokens is available when trading is enabled and reach trading start time
	 * Trading start time bloğuna ulaşacak şekilde zaman simüle edilmiştir.
	 * Müteakibinde cüzdanda bulunan 10 Stable token'dan SOULS token'a swap yapılmıştır. Oluşan loglar aşağıdaki şekildedir.
	 Stable balance before trade:  999973000.0
			- SOULS balance before trade:  0.0
			- Swapping 10 Stable to SOULS tokens
			- Stable balance after trade:  999972990.0
			- SOULS balance after trade:  1108.479162146732430012
	
	**** Can sell back token before reacing balance limit of bot protection
	* Satın alınan tüm tokenlar tekrar Stable tokena transfer edilmiştir. Oluşan loglar aşağıdaki şekildedir.
			- Stable balance before trade:  999972990.0
			- SOULS balance before trade:  1108.479162146732430012
			- Swapping 1108.479162146732430012 SOULS tokens to Stable
			- SOULS balance after trade:  0.0

	**** Activates bot protection for wallet when balance exeeds the limit
	* 10000 SOULS token satın alınmış ve unun 5000 tanesi başka bir adrese transfer edilmiştir.
	* Henüz adresin bot protection kapsamına girmediği gözlemlenmiştir.
	* Extra 20000 SOULS token satın alınmış ve adresin bot protection kapsamına girdiği gözlemlenmiştir. Oluşan loglar aşağıdaki şekildedir.
			- Balance limit for activationg bot protection:  10000.0
			- Buying 10000.0 SOULS
			- SOULS balance before transfer:  10000.0
			- SOULS balance before trade:  5000.0
			- Bot protection is still passive for wallet
			- Buying extra 10000.0 SOULS tokens to activate bot protection
			- Bot protection is activated for wallet
	**** Cannot sell more than allowed amount when bot protection is activated
	* Bot protection kontratında satışlar için geçmesi gereken süreye gidecek şekilde zaman simüle edilmiştir.
	* Bir defada satılabilecek miktardan (1000 token) bir fazlasının satılması denenmiş ve 'TransferHelper: TRANSFER_FROM_FAILED' hatası döndüğü gözlemlenmiştir.
	 
	**** Must wait until unlock time after every sell
	* Tek defada satılabilecek miktarda token satılmıştır.
	* İkinci defa aynı miktarda token satılması denendiğinde 'TransferHelper: TRANSFER_FROM_FAILED' hatası döndüğü gözlemlenmiştir.
	* Bir sonraki trade işlemi için gerekli zamanın geçmesi simüle edilmiştir.
	* Tekrar satış denendiğinde satışın başarılı olduğu gözlemlenmiştir.
	* Önceki iki madde tekrar test edilmiş ve her trade arasında gerekli zamanın geçmesi gerektiği gözlemlenmiştir.
	 */
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external view onlyTokenContract returns (bool) {
        // console.log("bot prevention before transfer", dexPairAddress, from, to);
        if (((dexPairAddress != address(0) && (from == dexPairAddress)) || to == dexPairAddress)) {
            // console.log("Trade transaction");
            //Trade transaction
            if (!tradingEnabled) {
                // console.log("TradingIsDisabled");
                revert TradingIsDisabled();
            }
            if (block.timestamp < tradingStartTimeOnDEX) {
                // console.log("TradingNotStarted");
                revert TradingNotStarted();
            }
            if (block.timestamp < tradingStartTimeOnDEX + botPreventionDuration) {
                //While bot protection is active
                if (to == dexPairAddress) {
                    //Selling Souls
                    if (block.timestamp < walletCanSellAfter[from]) {
                        // console.log("BotPreventionTimeLock");
                        revert BotPreventionTimeLock();
                    }
                    if (walletCanSellAfter[from] > 0) {
                        if (amount > botPreventionParams.maxSellAmount) {
                            // console.log("BotPreventionAmountLock");
                            revert BotPreventionAmountLock();
                        }
                    }
                }
            }
        }
        // console.log("before transfer ok");
        return true;
    }

    function afterTokenTransfer(address from, address to, uint256 amount) external onlyTokenContract returns (bool) {
        if (dexPairAddress != address(0) && block.timestamp < tradingStartTimeOnDEX + botPreventionDuration) {
            if (from == dexPairAddress) {
                //Buying Tokens
                if (
                    block.timestamp > tradingStartTimeOnDEX &&
                    block.timestamp < tradingStartTimeOnDEX + botPreventionDuration
                ) {
                    boughtAmountDuringBotProtection[currentSession][to] += amount;
                }
                if (boughtAmountDuringBotProtection[currentSession][to] > botPreventionParams.activateIfBalanceExeeds) {
                    walletCanSellAfter[to] = block.timestamp + botPreventionParams.durationBetweenSells;
                }
            } else if (to == dexPairAddress) {
                //Selling Tokens
                if (
                    block.timestamp > tradingStartTimeOnDEX &&
                    block.timestamp < tradingStartTimeOnDEX + botPreventionDuration
                ) {
                    if (boughtAmountDuringBotProtection[currentSession][from] >= amount) {
                        boughtAmountDuringBotProtection[currentSession][from] -= amount;
                    }
                }
                if (walletCanSellAfter[from] > 0) {
                    walletCanSellAfter[from] = block.timestamp + botPreventionParams.durationBetweenSells;
                }
            } else {
                //Standard transfer
                if (IERC20(tokenAddress).balanceOf(to) > botPreventionParams.activateIfBalanceExeeds) {
                    walletCanSellAfter[to] = block.timestamp + botPreventionParams.durationBetweenSells;
                }
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function addAddressToTrustedSources(address _address, string memory _name) external;
}