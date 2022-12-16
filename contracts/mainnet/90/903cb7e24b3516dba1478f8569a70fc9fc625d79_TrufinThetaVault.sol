// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {GnosisAuction} from "../../../libraries/GnosisAuction.sol";
import {TrufinThetaVaultStorage} from "../../../storage/TrufinThetaVaultStorage.sol";
import {Vault} from "../../../libraries/Vault.sol";
import {VaultLifecycle} from "../../../libraries/VaultLifecycle.sol";
import {ShareMath} from "../../../libraries/ShareMath.sol";
import {TrufinVault} from "./base/TrufinVault.sol";
import {IMasterWhitelist} from "../../../interfaces/IMasterWhitelist.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * TrufinThetaVault should not inherit from any other contract aside from TrufinVault, TrufinThetaVaultStorage
 */
contract TrufinThetaVault is TrufinVault, TrufinThetaVaultStorage {
    using SafeERC20 for IERC20;

    /************************************************
     *  NON UPGRADEABLE STORAGE (only adding of variables allowed)
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public OTOKEN_FACTORY;

    /************************************************
     *  CONSTANTS
     ***********************************************/

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event PremiumDiscountSet(
        uint256 premiumDiscount,
        uint256 newPremiumDiscount
    );

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct per week (1_000_000 = 1%)
     * @param _performanceFee is the perfomance fee pct per week (1_000_000 = 1%)
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     * @param _auctionDuration is the duration of the gnosis auction
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
        uint32 _premiumDiscount;
        uint256 _auctionDuration;
    }

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    //this contract is inherited, so:
    uint256[50] private __gap;

    /************************************************
     *  INITIALIZATION
     ***********************************************/
    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param _wmatic is the Wrapped Matic contract
     * (!!!IMPORTANT: always _wmatic=WMATIC despite of using asset in Vault params!!!)
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     * @param _whitelist is the contract address for the whitelist
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        address _wmatic,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction,
        uint256 _period,
        address _whitelist,
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        require(
            _oTokenFactory != address(0),
            "t01"
            //"oTokenFactory should not be a zero address"
        );
        OTOKEN_FACTORY = _oTokenFactory;
        baseInitialize(
            _wmatic,
            _usdc,
            _gammaController,
            _marginPool,
            _gnosisEasyAuction,
            _whitelist,
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams
        );
        require(
            _initParams._optionsPremiumPricer != address(0),
            "t02"
            //"_optionsPremiumPricer should not be a zero address"
        );
        require(
            _initParams._strikeSelection != address(0),
            "t03"
            //"_strikeSelection should not be a zero address"
        );
        require(
            _initParams._premiumDiscount > 0 &&
                _initParams._premiumDiscount <
                100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "t04"
            //"_premiumDiscount should be more than zero and less than 100%"
        );
        require(
            _initParams._auctionDuration >= MIN_AUCTION_DURATION,
            "t05"
            //"_auctionDuration more than MIN_AUCTION_DURATION"
        );
        require(
            _period % 7 == 0,
            "t06"
            //"invalid period"
        );

        PERIOD = _period;
        optionsPremiumPricer = _initParams._optionsPremiumPricer;
        strikeSelection = _initParams._strikeSelection;
        premiumDiscount = _initParams._premiumDiscount;
        auctionDuration = _initParams._auctionDuration;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new discount on premiums for options we are selling
     * @param newPremiumDiscount is the premium discount
     */
    function setPremiumDiscount(uint256 newPremiumDiscount)
        external
        onlyKeeper
    {
        require(
            newPremiumDiscount > 0 &&
                newPremiumDiscount <= 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "t07"
            //"Invalid discount"
        );

        emit PremiumDiscountSet(premiumDiscount, newPremiumDiscount);

        premiumDiscount = newPremiumDiscount;
    }

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        require(
            newAuctionDuration >= MIN_AUCTION_DURATION,
            "t08"
            //"Invalid auction duration"
        );

        emit AuctionDurationSet(auctionDuration, newAuctionDuration);

        auctionDuration = newAuctionDuration;
    }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external onlyOwner {
        require(
            newStrikeSelection != address(0),
            "t09"
            //"newStrikeSelection should not be a zero address"
        );
        strikeSelection = newStrikeSelection;
    }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer)
        external
        onlyOwner
    {
        require(
            newOptionsPremiumPricer != address(0),
            "t10"
            //"newOptionsPremiumPricer should not be a zero address"
        );
        optionsPremiumPricer = newOptionsPremiumPricer;
    }

    /**
     * @notice Optionality to set strike price manually
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(
            strikePrice > 0,
            "t11" /*"strikePrice should be greater than zero"*/
        );
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new whitelist contract
     * @param _newWhiteList is the address of the new whitelist
     */
    function setWhiteList(address _newWhiteList) external onlyOwner {
        require(
            _newWhiteList != address(0),
            "t12" /*"Whitelist can't be zero address"*/
        );
        WHITELIST = IMasterWhitelist(_newWhiteList);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt = depositReceipts[
            msg.sender
        ];

        uint256 currentRound = vaultState.round;
        require(
            amount > 0,
            "t13" /*"amount should be greater than zero"*/
        );
        require(
            depositReceipt.round == currentRound,
            "t14" /*"Invalid round"*/
        );
        require(
            !IMasterWhitelist(WHITELIST).isUserBlacklisted(msg.sender),
            "t15"
            //"User blacklisted"
        );

        uint256 receiptAmount = depositReceipt.amount;
        require(
            receiptAmount >= amount,
            "t16" /*"Exceed amount"*/
        );

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount - amount);

        vaultState.totalPending = uint128(
                uint256(vaultState.totalPending) - amount
            );
        
        emit InstantWithdraw(msg.sender, amount, currentRound);

        transferAsset(msg.sender, amount);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw()
        external
        nonReentrant
        returns (uint256 withdrawAmount)
    {
        require(
            IMasterWhitelist(WHITELIST).isUserWhitelisted(msg.sender) ||
                IMasterWhitelist(WHITELIST).isVaultWhitelisted(msg.sender),
            "t17"
            //"User is not whitelisted"
        );

        //slither-disable-next-line reentrancy-benign
        withdrawAmount = _completeWithdraw();
        // decrease lastQueuedWithdrawAmount only if completeWithdraw is called after rollToNextOption
        // Before rollToNextOption, we only have withdrawalShares which are updated inside _completeWithdraw
        if (optionState.currentOption != address(0)) 
            lastQueuedWithdrawAmount = uint128(
                uint256(lastQueuedWithdrawAmount) - withdrawAmount
            );
            //
        return withdrawAmount;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and closes the existing short.
     *         This allows all the users to withdraw if the next option is malicious.
     */
    function commitAndClose() external nonReentrant {
        require(optionState.currentOption != address(0) || (vaultState.round == 1), "t20");
        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign        
        _closeShort();
        uint256 currentBalance = IERC20(vaultParams.asset).balanceOf(
            address(this)
        );
        
        uint256 pendingAmount = vaultState.totalPending;
        uint256 queuedWithdrawShares = vaultState.queuedWithdrawShares;
        uint256 currentShareSupply = totalSupply();

        uint256 pricePerShareBeforeFee = ShareMath.pricePerShare(
            currentShareSupply,
            currentBalance,
            pendingAmount,
            vaultParams.decimals
        );

        uint256 queuedWithdrawBeforeFee = currentShareSupply > 0
            ? ShareMath.sharesToAsset(
                queuedWithdrawShares,
                pricePerShareBeforeFee,
                vaultParams.decimals
            )
            : 0;

        // Deduct the difference between the newly scheduled withdrawals
        // and the older withdrawals
        // so we can charge them fees before they leave
        uint256 withdrawAmountDiff = queuedWithdrawBeforeFee >
            lastQueuedWithdrawAmount
            ? queuedWithdrawBeforeFee - lastQueuedWithdrawAmount
            : 0;
        
        uint256 balanceForVaultFees = currentBalance + withdrawAmountDiff - queuedWithdrawBeforeFee;
        
        (
            uint256 performanceFeeInAsset,
            ,
            uint256 totalVaultFee
        ) = VaultLifecycle.getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                performanceFee,
                managementFee
            );

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance -= totalVaultFee;
        ShareMath.assertUint104(currentBalance);
        
        uint256 newPricePerShare = ShareMath.pricePerShare(
            currentShareSupply,
            currentBalance,
            pendingAmount,
            vaultParams.decimals
        );
        uint256 currentRound = vaultState.round;
        roundPricePerShare[currentRound] = newPricePerShare;
        uint256 feesNotSentToRecipient = calcFeesNotSentToRecipient(
            totalVaultFee
        );
        if (totalVaultFee > 0) {
            transferAsset(
                payable(feeRecipient),
                totalVaultFee - feesNotSentToRecipient
            );
        }
        emit CollectVaultFees(
            performanceFeeInAsset,
            totalVaultFee,
            currentRound,
            feeRecipient
        );
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort() private {
        uint256 lockedAmount = vaultState.lockedAmount;
        address oldOption = optionState.currentOption;
        vaultState.lockedAmount = 0;
        optionState.currentOption = address(0);
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);

            uint256 withdrawAmount = VaultLifecycle.settleShort(
                GAMMA_CONTROLLER
            );
            //slither-disable-next-line reentrancy-events
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        require(optionState.currentOption == address(0), "t19");
        (
            address otokenAddress,
            uint256 premium,
            uint256 strikePrice,
            uint256 delta,
            uint256 currentOptionExpirationAt
        ) = VaultLifecycle.commitAndClose(
                strikeSelection,
                optionsPremiumPricer,
                premiumDiscount,
                VaultLifecycle.CloseParams({
                    OTOKEN_FACTORY: OTOKEN_FACTORY,
                    USDC: USDC,
                    currentOption: address(0),
                    lastStrikeOverrideRound: lastStrikeOverrideRound,
                    overriddenStrikePrice: overriddenStrikePrice,
                    period: PERIOD
                }),
                vaultParams,
                vaultState
            );
        optionState.currentOptionExpirationAt = currentOptionExpirationAt;
        emit NewOptionStrikeSelected(strikePrice, delta);

        ShareMath.assertUint104(premium);
        currentOtokenPremium = uint104(premium);
    
        //slither-disable-next-line reentrancy-benign
        uint256 queuedWithdrawAmount = _rollToNextOption(otokenAddress);

        lastQueuedWithdrawAmount = queuedWithdrawAmount;
        uint256 lockedBalance = IERC20(vaultParams.asset).balanceOf(address(this)) - queuedWithdrawAmount;
        require(lockedBalance > 0, "t53");
        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);
        emit OpenShort(otokenAddress, lockedBalance, msg.sender);
        //slither-disable-next-line reentrancy-benign
        VaultLifecycle.createShort(
            GAMMA_CONTROLLER,
            MARGIN_POOL,
            otokenAddress,
            lockedBalance
        );
        //slither-disable-next-line reentrancy-benign
        _startAuction();
    }

    /**
     * @notice Initiate the gnosis auction.
     */
    function startAuction() external onlyKeeper nonReentrant {
        _startAuction();
    }

    function _startAuction() private {
        //slither-disable-next-line uninitialized-local
        GnosisAuction.AuctionDetails memory auctionDetails;

        uint256 currOtokenPremium = currentOtokenPremium;

        require(
            currOtokenPremium > 0,
            "t18"
            //"currentOtokenPremium should be greater than zero"
        );

        auctionDetails.oTokenAddress = optionState.currentOption;
        auctionDetails.gnosisEasyAuction = GNOSIS_EASY_AUCTION;
        auctionDetails.asset = vaultParams.asset;
        auctionDetails.whitelist = address(WHITELIST);
        auctionDetails.assetDecimals = vaultParams.decimals;
        auctionDetails.oTokenPremium = currOtokenPremium;
        auctionDetails.duration = auctionDuration;

        optionAuctionID = VaultLifecycle.startAuction(auctionDetails);
    }

    /**
     * @notice Burn the remaining oTokens left over from gnosis auction.
     */
    function burnRemainingOTokens() external onlyKeeper nonReentrant {
        //slither-disable-next-line reentrancy-benign
        uint256 unlockedAssetAmount = VaultLifecycle.burnOtokens(
            GAMMA_CONTROLLER,
            optionState.currentOption
        );

        vaultState.lockedAmount = uint104(
            uint256(vaultState.lockedAmount) - unlockedAssetAmount
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
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DSMath} from "../vendor/DSMath.sol";
import {IGnosisAuction} from "../interfaces/IGnosisAuction.sol";
import {IOtoken} from "../interfaces/GammaInterface.sol";
import {IOptionsPremiumPricer} from "../interfaces/ITrufin.sol";
import {Vault} from "./Vault.sol";
import {ITrufinThetaVault} from "../interfaces/ITrufinThetaVault.sol";

library GnosisAuction {
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when gnosis auction is initiated
     * @param auctioningToken the address of the auctioning token
     * @param biddingToken the address of the bidding token
     * @param auctionCounter is the indentifier of the auction
     * @param manager the address of the auction starter
     */
    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    /**
     * @dev Emitted when new bid is placed
     * @param auctionId the auction identifier
     * @param auctioningToken the address of the auctioning token
     * @param sellAmount the sell amount
     * @param buyAmount the buy amount
     * @param bidder the address of the bidder
     */
    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    /// @dev struct describing auction details
    struct AuctionDetails {
        /// @dev address of oToken we minted and are selling
        address oTokenAddress;
        /// @dev address of the Gnosis auction
        address gnosisEasyAuction;
        /// @dev address of asset we want in exchange for oTokens. Should match vault `asset`
        address asset;
        /// @dev address of the contract that manages the whitelist
        address whitelist;
        /// @dev the number of decimals used to get asset user representation
        uint256 assetDecimals;
        /// @dev the premium for the options
        uint256 oTokenPremium;
        /// @dev the duration of the auction
        uint256 duration;
    }

    /// @dev struct describing a bid
    struct BidDetails {
        /// @dev the address of the auctioning token
        address oTokenAddress;
        /// @dev the address of the Gnosis auction
        address gnosisEasyAuction;
        /// @dev the amount of asset that was bidded
        address asset;
        /// @dev the number of decimals used to get asset user representation
        uint256 assetDecimals;
        /// @dev the auction identifier
        uint256 auctionId;
        /// @dev total locked asset balance
        uint256 lockedBalance;
        /// @dev the percent of funds used for weekly option purchace
        uint256 optionAllocation;
        /// @dev the premium paid for single option
        uint256 optionPremium;
        /// @dev the address making the bid
        address bidder;
    }

    /**
     * @dev function to intiate a new auction
     * Emits InitiateGnosisAuction
     * @param auctionDetails the auction details
     * @return auctionID the auction identifier
     */
    function startAuction(AuctionDetails calldata auctionDetails)
        internal
        returns (uint256 auctionID)
    {
        uint256 oTokenSellAmount = getOTokenSellAmount(
            auctionDetails.oTokenAddress
        );

        IERC20(auctionDetails.oTokenAddress).safeApprove(
            auctionDetails.gnosisEasyAuction,
            oTokenSellAmount
        );

        // minBidAmount is total oTokens to sell * premium per oToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount = DSMath.wmul(
            oTokenSellAmount * (10**10),
            auctionDetails.oTokenPremium
        );

        minBidAmount = auctionDetails.assetDecimals == 18
            ? minBidAmount
            : (
                auctionDetails.assetDecimals > 18
                    ? minBidAmount * (10**(auctionDetails.assetDecimals - 18))
                    : minBidAmount /
                        (10**(uint256(18) - auctionDetails.assetDecimals))
            );

        require(
            minBidAmount <= type(uint96).max,
            "optionPremium * oTokenSellAmount > type(uint96) max value!"
        );

        uint256 auctionEnd = block.timestamp + auctionDetails.duration;

        auctionID = IGnosisAuction(auctionDetails.gnosisEasyAuction)
            .initiateAuction(
                // address of oToken we minted and are selling
                auctionDetails.oTokenAddress,
                // address of asset we want in exchange for oTokens. Should match vault `asset`
                auctionDetails.asset,
                // orders can be cancelled at any time during the auction
                auctionEnd,
                // order will last for `duration`
                auctionEnd,
                // we are selling all of the otokens minus a fee taken by gnosis
                uint96(oTokenSellAmount),
                // the minimum we are willing to sell all the oTokens for. A discount is applied on black-scholes price
                uint96(minBidAmount),
                // the minimum bidding amount must be 1 * 10 ** -assetDecimals
                1,
                // the min funding threshold
                0,
                // no atomic closure
                false,
                // access manager contract
                auctionDetails.whitelist,
                // bytes for storing info like a whitelist for who can bid
                bytes("")
            );

        emit InitiateGnosisAuction(
            auctionDetails.oTokenAddress,
            auctionDetails.asset,
            auctionID,
            msg.sender
        );
    }

    /**
     * @dev function to place a bid
     * Emits PlaceAuctionBid
     * @param bidDetails the bid details
     * @return sellAmount the options to be allocated
     * @return buyAmount the amount of options to buy
     * @return userId the user identifier
     */
    function placeBid(BidDetails calldata bidDetails)
        internal
        returns (
            uint256 sellAmount,
            uint256 buyAmount,
            uint64 userId
        )
    {
        // calculate how much to allocate
        //slither-disable-next-line divide-before-multiply
        sellAmount =
            (bidDetails.lockedBalance * (bidDetails.optionAllocation)) /
            (100 * Vault.OPTION_ALLOCATION_MULTIPLIER);

        // divide the `asset` sellAmount by the target premium per oToken to
        // get the number of oTokens to buy (8 decimals)
        buyAmount =
            (sellAmount *
                (10**(bidDetails.assetDecimals + Vault.OTOKEN_DECIMALS))) /
            (bidDetails.optionPremium) /
            (10**bidDetails.assetDecimals);

        require(
            sellAmount <= type(uint96).max,
            "sellAmount > type(uint96) max value!"
        );
        require(
            buyAmount <= type(uint96).max,
            "buyAmount > type(uint96) max value!"
        );

        // approve that amount
        IERC20(bidDetails.asset).safeApprove(
            bidDetails.gnosisEasyAuction,
            sellAmount
        );

        uint96[] memory _minBuyAmounts = new uint96[](1);
        uint96[] memory _sellAmounts = new uint96[](1);
        bytes32[] memory _prevSellOrders = new bytes32[](1);
        _minBuyAmounts[0] = uint96(buyAmount);
        _sellAmounts[0] = uint96(sellAmount);
        _prevSellOrders[
            0
        ] = 0x0000000000000000000000000000000000000000000000000000000000000001;

        // place sell order with that amount
        userId = IGnosisAuction(bidDetails.gnosisEasyAuction).placeSellOrders(
            bidDetails.auctionId,
            _minBuyAmounts,
            _sellAmounts,
            _prevSellOrders,
            "0x"
        );

        emit PlaceAuctionBid(
            bidDetails.auctionId,
            bidDetails.oTokenAddress,
            sellAmount,
            buyAmount,
            bidDetails.bidder
        );

        return (sellAmount, buyAmount, userId);
    }

    /**
     * @dev function to claim options
     * @param auctionSellOrder auction sell order
     * @param gnosisEasyAuction easy auction address
     * @param counterpartyThetaVault theta vault address
     */
    function claimAuctionOtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) internal {
        bytes32 order = encodeOrder(
            auctionSellOrder.userId,
            auctionSellOrder.buyAmount,
            auctionSellOrder.sellAmount
        );
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        //slither-disable-next-line unused-return
        IGnosisAuction(gnosisEasyAuction).claimFromParticipantOrder(
            ITrufinThetaVault(counterpartyThetaVault).optionAuctionID(),
            orders
        );
    }

    /**
     * @dev get contract oToken balance
     * @param oTokenAddress the address of the otoken
     * @return the amount of oTokens
     */
    function getOTokenSellAmount(address oTokenAddress)
        internal
        view
        returns (uint256)
    {
        // We take our current oToken balance. That will be our sell amount
        // but otokens will be transferred to gnosis.
        uint256 oTokenSellAmount = IERC20(oTokenAddress).balanceOf(
            address(this)
        );

        require(
            oTokenSellAmount <= type(uint96).max,
            "oTokenSellAmount > type(uint96) max value!"
        );

        return oTokenSellAmount;
    }

    /**
     * @dev function to calculate oToken premium
     * @param oTokenAddress the address of the oToken
     * @param optionsPremiumPricer OptionPremiumPricer address
     * @param premiumDiscount the vault discount applied to the premium
     * @return the premium paid for single option
     */
    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer = IOptionsPremiumPricer(
            optionsPremiumPricer
        );

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium = premiumPricer.getPremium(
            newOToken.strikePrice(),
            newOToken.expiryTimestamp(),
            newOToken.isPut()
        );
        // Apply a discount to incentivize arbitraguers
        optionPremium =
            (optionPremium * (premiumDiscount)) /
            (100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER);
        require(
            optionPremium <= type(uint96).max,
            "optionPremium > type(uint96) max value!"
        );

        return optionPremium;
    }

    /**
     * @dev function to encode order into bytes32
     * @param userId order userid
     * @param buyAmount order buy amount
     * @param sellAmount order sell amount
     * @return the bytes32 that encode the order
     */
    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(userId) << 192) +
                    (uint256(buyAmount) << 96) +
                    uint256(sellAmount)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

abstract contract TrufinThetaVaultStorage {
    /**
     * @dev Logic contract used to price options
     */
    address public optionsPremiumPricer;

    /**
     * @dev Logic contract used to select strike prices
     */
    address public strikeSelection;

    /**
     * @dev Premium discount on options we are selling (thousandths place: 000 - 999)
     */
    uint256 public premiumDiscount;

    /**
     * @dev Current oToken premium
     */
    uint256 public currentOtokenPremium;

    /**
     * @dev Last round id at which the strike was manually overridden
     */
    uint16 public lastStrikeOverrideRound;

    /**
     * @dev Price last overridden strike set to
     */
    uint256 public overriddenStrikePrice;

    /**
     * @dev Auction duration
     */
    uint256 public auctionDuration;

    /**
     * @dev Auction id of current option
     */
    uint256 public optionAuctionID;

    /**
     * @dev Amount locked for scheduled withdrawals last week;
     */
    uint256 public lastQueuedWithdrawAmount;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    //this contract is inherited, so:
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @dev Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    /// @dev Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    /// @dev Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    /// @dev Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    /// @dev Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /// @dev struct for vault general data
    struct VaultParams {
        /// @dev Option type the vault is selling
        bool isPut;
        /// @dev Token decimals for vault shares
        uint8 decimals;
        /// @dev Asset used in Theta Vault
        address asset;
        /// @dev deprecated: Underlying asset of the options sold by vault
        address underlying;
        /// @dev Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        /// @dev Vault cap
        uint104 cap;
    }

    /// @dev struct for vault state of the options sold and the timelocked option
    struct OptionState {
        /// @dev deprecated: Option that the vault is shorting / longing in the next cycle
        // todo: remove before a new deployment
        address unused;
        /// @dev Option that the vault is currently shorting / longing
        address currentOption;
        /// @dev deprecated: The timestamp when the `nextOption` can be used by the vault
        // todo: remove before a new deployment
        uint32 unused2;
        /// @dev The timestamp when the `nextOption` will expire
        uint256 currentOptionExpirationAt;
    }

    /// @dev struct for vault accounting state
    struct VaultState {
        /**
         * @dev 32 byte slot 1
         * Current round number. `round` represents the number of `period`s elapsed.
         */
        uint16 round;
        /// @dev Amount that is currently locked for selling options
        uint104 lockedAmount;
        /**
         * @dev Amount that was locked for selling options in the previous round
         * used for calculating performance fee deduction
         */
        uint104 lastLockedAmount;
        /**
         * @dev 32 byte slot 2
         * Stores the total tally of how much of `asset` there is
         * to be used to mint rTHETA tokens
         */
        uint128 totalPending;
        /// @dev Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
    }

    //todo: make it without mapping and use mapping in code
    /// @dev struct for fee rebate for whitelisted vaults depositings
    struct VaultFee {
        /// @dev Amount for whitelisted vaults
        mapping(uint16 => uint256) whitelistedVaultAmount;
        /// @dev Fees not to recipient fee recipient: Will be sent to the vault at complete
        mapping(uint16 => uint256) feesNotSentToRecipient;
    }

    /// @dev struct for pending deposit for the round
    struct DepositReceipt {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        /// @dev Unredeemed shares balance
        uint128 unredeemedShares;
    }

    /// @dev struct for pending withdrawals
    struct Withdrawal {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Number of shares withdrawn
        uint128 shares;
    }

    /// @dev struct for auction sell order
    struct AuctionSellOrder {
        /// @dev Amount of `asset` token offered in auction
        uint96 sellAmount;
        /// @dev Amount of oToken requested in auction
        uint96 buyAmount;
        /// @dev User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IStrikeSelection} from "../interfaces/ITrufin.sol";
import {GnosisAuction} from "./GnosisAuction.sol";
import {IOtokenFactory, IOtoken, IController, GammaTypes} from "../interfaces/GammaInterface.sol";
import {IGnosisAuction} from "../interfaces/IGnosisAuction.sol";

library VaultLifecycle {
    /// @dev struct with option details
    struct CloseParams {
        /// @dev the factory contract used to spawn otokens. Used to lookup otokens.
        address OTOKEN_FACTORY;
        /// @dev the address of usdc
        address USDC;
        /// @dev oToken address
        address currentOption;
        /// @dev last round the strike price was overriden
        uint16 lastStrikeOverrideRound;
        /// @dev overridden strike price
        uint256 overriddenStrikePrice;
        uint256 period;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param strikeSelection is the address of the contract with strike selection logic
     * @param optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param premiumDiscount is the vault's discount applied to the premium
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return otokenAddress is the address of the new option
     * @return premium is the premium of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */

    /// stack too deep - some reasonable local vars were removed
    function commitAndClose(
        address strikeSelection,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        CloseParams calldata closeParams,
        Vault.VaultParams calldata vaultParams,
        Vault.VaultState storage vaultState
    )
        external
        returns (
            address otokenAddress,
            uint256 premium,
            uint256 strikePrice,
            uint256 delta,
            uint256 expiry
        )
    {
        expiry = getNextExpiry(closeParams.currentOption, closeParams.period);

        IStrikeSelection selection = IStrikeSelection(strikeSelection);

        //slither-disable-next-line reentrancy-benign
        (strikePrice, delta) = closeParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (closeParams.overriddenStrikePrice, selection.delta()) //slither-disable-next-line reentrancy-benign
            : selection.getStrikePrice(expiry, vaultParams.isPut);
        //slither-disable-next-line timestamp
        require(strikePrice != 0, "strikePrice should not be zero");

        // retrieve address if option already exists, or deploy it
        //slither-disable-next-line reentrancy-benign
        otokenAddress = getOrDeployOtoken(
            closeParams,
            vaultParams,
            strikePrice,
            expiry
        );
        // get the black scholes premium of the option
        premium = GnosisAuction.getOTokenPremium(
            otokenAddress,
            optionsPremiumPricer,
            premiumDiscount
        );

        require(premium > 0, "premium should be greater than 0");

        return (otokenAddress, premium, strikePrice, delta, expiry);
    }

    /**
     * @notice Verify the otoken has the correct parameters to prevent vulnerability to opyn contract changes
     * @param otokenAddress is the address of the otoken
     * @param vaultParams is the struct with vault general data
     * @param USDC is the address of usdc
     */
    function verifyOtoken(
        address otokenAddress,
        Vault.VaultParams calldata vaultParams,
        address USDC
    ) private view {
        //slither-disable-next-line timestamp
        require(
            otokenAddress != address(0),
            "otokenAddress should not be a zero address"
        );

        IOtoken otoken = IOtoken(otokenAddress);
        //slither-disable-next-line incorrect-equality
        require(otoken.isPut() == vaultParams.isPut, "Type mismatch");
        //slither-disable-next-line incorrect-equality
        require(
            otoken.underlyingAsset() == vaultParams.underlying,
            "Wrong underlyingAsset"
        );
        //slither-disable-next-line incorrect-equality
        require(
            otoken.collateralAsset() == vaultParams.asset,
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        //slither-disable-next-line incorrect-equality
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC");
    }

    /**
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param asset is the address of the vault's asset
     * @param decimals is the decimals of the asset
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from last round
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 newPricePerShare;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from TrufinVault
     * @param params is the rollover parameters passed to compute the next state
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return mintShares is the amount of shares to mint from deposits
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams calldata params
    )
        external
        view
        returns (
            //   uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 mintShares
        )
    {
        // After closing the short, if the options expire in-the-money
        // vault pricePerShare would go down because vault's asset balance decreased.
        // This ensures that the newly-minted shares do not take on the loss.
        mintShares = ShareMath.assetToShares(
            vaultState.totalPending,
            params.newPricePerShare,
            params.decimals
        );

        queuedWithdrawAmount = params.currentShareSupply + mintShares > 0
            ? ShareMath.sharesToAsset(
                vaultState.queuedWithdrawShares,
                params.newPricePerShare,
                params.decimals
            )
            : 0;

        return (
            //          params.totalBalance - queuedWithdrawAmount, // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            mintShares
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external {
        IController controller = IController(gammaController);
        uint256 newVaultID = (
            controller.getAccountVaultCounter(address(this))
        ) + 1;

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals = uint256(
            IERC20Metadata(collateralAsset).decimals()
        );
        uint256 mintAmount;
        if (oToken.isPut()) {
            // For minting puts, there will be instances where the full depositAmount will not be used for minting.
            // This is because of an issue with precision.
            //
            // For ETH put options, we are calculating the mintAmount (10**8 decimals) using
            // the depositAmount (10**18 decimals), which will result in truncation of decimals when scaling down.
            // As a result, there will be tiny amounts of dust left behind in the Opyn vault when minting put otokens.
            //
            // For simplicity's sake, we do not refund the dust back to the address(this) on minting otokens.
            // We retain the dust in the vault so the calling contract can withdraw the
            // actual locked amount + dust at settlement.
            //
            // To test this behavior, we can console.log
            // MarginCalculatorInterface(0x7A48d10f372b3D7c60f6c9770B91398e4ccfd3C7).getExcessCollateral(vault)
            // to see how much dust (or excess collateral) is left behind.
            mintAmount =
                (depositAmount * (10**Vault.OTOKEN_DECIMALS) * (10**18)) /
                (oToken.strikePrice() * (10**(10 + collateralDecimals))); // we use 10**18 to give extra precision
        } else {
            mintAmount = depositAmount;

            if (collateralDecimals > 8) {
                uint256 scaleBy = 10**(collateralDecimals - 8); // oTokens have 8 decimals
                if (mintAmount > scaleBy) {
                    mintAmount = depositAmount / scaleBy; // scale down from 10**18 to 10**8
                }
            }
        }

        // double approve to fix non-compliant ERC20s
        IERC20Metadata collateralToken = IERC20Metadata(collateralAsset);
        require(
            collateralToken.approve(marginPool, depositAmount),
            "Can't approve tokens to marginPool"
        );

        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            3
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the opyn controller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(address gammaController) external returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault = controller.getVault(
            address(this),
            vaultID
        );

        require(vault.shortOtokens.length > 0, "shortOtokens does not exist");

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IERC20Metadata collateralToken = IERC20Metadata(
            vault.collateralAssets[0]
        );

        // The short position has been previously closed, or all the otokens have been burned.
        // So we return early.
        if (address(collateralToken) == address(0)) {
            return 0;
        }

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256 startCollateralBalance = collateralToken.balanceOf(
            address(this)
        );

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultID, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance - startCollateralBalance;
    }

    /**
     * @notice Exercises the ITM option using existing long otoken position. Currently this implementation is simple.
     * It calls the `Redeem` action to claim the payout.
     * @param gammaController is the address of the opyn controller contract
     * @param oldOption is the address of the old option
     * @param asset is the address of the vault's asset
     * @return amount of asset received by exercising the option
     */
    function settleLong(
        address gammaController,
        address oldOption,
        address asset
    ) external returns (uint256) {
        IController controller = IController(gammaController);

        uint256 oldOptionBalance = IERC20Metadata(oldOption).balanceOf(
            address(this)
        );
        //slither-disable-next-line incorrect-equality
        if (controller.getPayout(oldOption, oldOptionBalance) == 0) {
            return 0;
        }

        uint256 startAssetBalance = IERC20Metadata(asset).balanceOf(
            address(this)
        );

        // If it is after expiry, we need to redeem the profits
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oldOption, // address of otoken
            0, // not used
            oldOptionBalance, // otoken balance
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endAssetBalance = IERC20Metadata(asset).balanceOf(
            address(this)
        );

        return endAssetBalance - startAssetBalance;
    }

    /**
     * @notice Burn the remaining oTokens left over from auction. Currently this implementation is simple.
     * It burns oTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the opyn controller contract
     * @param currentOption is the address of the current option
     * @return amount of collateral redeemed by burning otokens
     */
    function burnOtokens(address gammaController, address currentOption)
        external
        returns (uint256)
    {
        uint256 numOTokensToBurn = IERC20Metadata(currentOption).balanceOf(
            address(this)
        );

        require(numOTokensToBurn > 0, "No oTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault = controller.getVault(
            address(this),
            vaultID
        );

        require(vault.shortOtokens.length > 0, "shortOtokens does not exist");

        IERC20Metadata collateralToken = IERC20Metadata(
            vault.collateralAssets[0]
        );

        uint256 startCollateralBalance = collateralToken.balanceOf(
            address(this)
        );

        // Burning `amount` of oTokens from the Trufin vault,
        // then withdrawing the corresponding collateral amount from the vault
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            2
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            address(vault.shortOtokens[0]), // otoken address
            vaultID, // vaultId
            numOTokensToBurn, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            address(collateralToken), // withdrawn asset
            vaultID, // vaultId
            (vault.collateralAmounts[0] * (numOTokensToBurn)) /
                (vault.shortAmounts[0]), // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance - startCollateralBalance;
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending = currentBalance > pendingAmount
            ? currentBalance - pendingAmount
            : 0;
        //slither-disable-next-line uninitialized-local
        uint256 _performanceFeeInAsset;
        //slither-disable-next-line uninitialized-local
        uint256 _managementFeeInAsset;
        //slither-disable-next-line uninitialized-local
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? ((lockedBalanceSansPending - lastLockedAmount) *
                    performanceFeePercent) / (100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? (lockedBalanceSansPending * managementFeePercent) /
                    (100 * Vault.FEE_MULTIPLIER)
                : 0;

            _vaultFee = _performanceFeeInAsset + _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @return the address of the option
     */
    function getOrDeployOtoken(
        CloseParams calldata closeParams,
        Vault.VaultParams calldata vaultParams,
        uint256 strikePrice,
        uint256 expiry)
         internal returns (address) {
        IOtokenFactory factory = IOtokenFactory(closeParams.OTOKEN_FACTORY);

        address otokenFromFactory = factory.getOtoken(
            vaultParams.underlying,
            closeParams.USDC,
            vaultParams.asset,
            strikePrice,
            expiry,
            vaultParams.isPut
        );
        //slither-disable-next-line timestamp
        if (otokenFromFactory != address(0)) {
            return otokenFromFactory;
        }
        //slither-disable-next-line reentrancy-benign
        address otoken = factory.createOtoken(
            vaultParams.underlying,
            closeParams.USDC,
            vaultParams.asset,
            strikePrice,
            expiry,
            vaultParams.isPut
        );

        verifyOtoken(otoken, vaultParams, closeParams.USDC);

        return otoken;
    }

    /**
     * @notice Starts the gnosis auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(GnosisAuction.AuctionDetails calldata auctionDetails)
        external
        returns (uint256)
    {
        return GnosisAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Places a bid in an auction
     * @param bidDetails is the struct with all the details of the
      bid including the auction's id and how much to bid
     */
    function placeBid(GnosisAuction.BidDetails calldata bidDetails)
        external
        returns (
            uint256 sellAmount,
            uint256 buyAmount,
            uint64 userId
        )
    {
        return GnosisAuction.placeBid(bidDetails);
    }

    /**
     * @notice Claims the oTokens belonging to the vault
     * @param auctionSellOrder is the sell order of the bid
     * @param gnosisEasyAuction is the address of the gnosis auction contract
     holding custody to the funds
     * @param counterpartyThetaVault is the address of the counterparty theta
     vault of this delta vault
     */
    function claimAuctionOtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) external {
        GnosisAuction.claimAuctionOtokens(
            auctionSellOrder,
            gnosisEasyAuction,
            counterpartyThetaVault
        );
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        address feeRecipient,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "Owner should not be a zero address");
        require(keeper != address(0), "Keeper should not be a zero address");
        require(
            feeRecipient != address(0),
            "feeRecipient should not be a zero address"
        );
        require(
            performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "performanceFee should not be greater than 100%"
        );
        require(
            managementFee < 100 * Vault.FEE_MULTIPLIER,
            "managementFee should not be greater than 100%"
        );
        require(bytes(tokenName).length > 0, "Token name cannot be empty");
        require(bytes(tokenSymbol).length > 0, "Token symbol cannot be empty");

        require(
            _vaultParams.asset != address(0),
            "Asset address cannot be a zero address"
        );
        require(
            _vaultParams.underlying != address(0),
            "underlying address cannot be a zero address"
        );
        require(
            _vaultParams.minimumSupply > 0,
            "minimumSupply should be greater than zero"
        );
        require(_vaultParams.cap > 0, "cap should be greater than zero");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the otoken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption, uint256 period)
        internal
        view
        returns (uint256)
    {
        // uninitialized state
        if (currentOption == address(0)) {
            return getAnyFriday(block.timestamp, period);
        }
        uint256 currentExpiry = IOtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        //slither-disable-next-line timestamp
        if (block.timestamp > currentExpiry + 7 days) {
            return getAnyFriday(block.timestamp, period);
        }
        return getAnyFriday(currentExpiry, period);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }

    function getAnyFriday(uint256 timestamp, uint256 expiryPeriod)
        internal
        pure
        returns (uint256)
    {
        //slither-disable-next-line weak-prng
        uint256 dayOfExpiryPeriod = ((timestamp / 1 days) + 4) % expiryPeriod;
        //slither-disable-next-line weak-prng
        uint256 nextExpiryDay = timestamp +
            ((expiryPeriod + (expiryPeriod - 2) - dayOfExpiryPeriod) %
                expiryPeriod) *
            1 days;
        //slither-disable-next-line weak-prng
        uint256 nextExpiry8am = nextExpiryDay -
            (nextExpiryDay % (24 hours)) +
            (8 hours);
        //slither-disable-next-line timestamp
        if (timestamp >= nextExpiry8am) {
            nextExpiry8am += expiryPeriod * 60 * 60 * 24; // expiry period which is in days should be converted to seconds
        }
        return nextExpiry8am;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {Vault} from "./Vault.sol";

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @dev return the amount of shares for given asset amount
     * @param assetAmount the asset amount
     * @param assetPerShare how much asset is need for share
     * @param decimals the asset decimals
     * @return the amount of shares for given asset amount
     */
    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * (10**decimals)) / (assetPerShare);
    }

    /**
     * @dev return the asset amount for given number of shares
     * @param shares the number of shares
     * @param assetPerShare how much asset is need for share
     * @param decimals the asset decimals
     * @return the asset amount for given shares
     */
    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * (assetPerShare)) / (10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = assetToShares(
                depositReceipt.amount,
                assetPerShare,
                decimals
            );

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    /**
     * @dev return the price of unit of share denominated in the asset
     * @param totalSupply total supply of shares
     * @param totalBalance the total amount of asset (including pending ammount)
     * @param pendingAmount the amount of asset that is pending until next round
     * (currently not actively managed by the vault)
     * @param decimals the shares decimals
     * @return the price for single share
     */
    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? (singleShare * (totalBalance - pendingAmount)) / totalSupply
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    /**
     * @dev require that the given number is within uint104 range
     */
    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    /**
     * @dev require that the given number is within the uint128 range
     */
    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Vault} from "../../../../libraries/Vault.sol";
import {VaultLifecycle} from "../../../../libraries/VaultLifecycle.sol";
import {ShareMath} from "../../../../libraries/ShareMath.sol";
import {IWMATIC} from "../../../../interfaces/IWMATIC.sol";
import {IMasterWhitelist} from "../../../../interfaces/IMasterWhitelist.sol";

contract TrufinVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE (only adding of variables is allowed)
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault whitelisted fee rebate
    Vault.VaultFee vaultFee;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice WMATIC 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    address public WMATIC;

    /// @notice USDC 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    address public USDC;

    // GAMMA_CONTROLLER is the top-level contract in Gamma protocol
    // which allows users to perform multiple actions on their vaults
    // and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/Controller.sol
    address public GAMMA_CONTROLLER;

    // MARGIN_POOL is Gamma protocol's collateral pool.
    // Needed to approve collateral.safeTransferFrom for minting otokens.
    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/MarginPool.sol
    address public MARGIN_POOL;

    // GNOSIS_EASY_AUCTION is Gnosis protocol's contract for initiating auctions and placing bids
    // https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
    address public GNOSIS_EASY_AUCTION;

    /// Period between each options sale.
    uint256 public PERIOD;

    // WHITELIST is the contract that manages the whitelist for lawyers, users, market makers, and gnosis auctions
    IMasterWhitelist public WHITELIST;

    /************************************************
     *  CONSTANTS
     ***********************************************/

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    event ChangeKeeper(address oldKeeper, address newKeeper);

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    //slither-disable-next-line shadowing-state
    uint256[50] private __gap;

    /************************************************
     * INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract
     * @param _wmatic is the Wrapped Matic contract
     * (!!!IMPORTANT: always _wmatic=WMATIC despite of using asset in Vault params!!!)
     * @param _usdc is the USDC contract
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     * @param _whitelist is the contract address for the whitelist
     */

    function baseInitialize(
        address _wmatic,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction,
        address _whitelist,
        address __owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams calldata _vaultParams /*initializer*/
    ) internal {
        //modifier /*initializer*/ shouldn't call twice, but this contract is
        //inherited with the same modifier
        require(_wmatic != address(0), "t21"); //WMATIC address is not set
        require(_usdc != address(0), "t22"); //USDC address is not set
        require(
            _gnosisEasyAuction != address(0),
            "t23" //gnosisEasyAuction address is not set
        );
        require(_whitelist != address(0), "t24"); //Whitelist address is not set
        require(
            _gammaController != address(0),
            "t25" //gammaController address is not set
        );
        require(_marginPool != address(0), "t26"); //marginPool address is not set

        VaultLifecycle.verifyInitializerParams(
            __owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        WMATIC = _wmatic;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        GNOSIS_EASY_AUCTION = _gnosisEasyAuction;
        WHITELIST = IMasterWhitelist(_whitelist);

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(__owner);

        keeper = _keeper;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee;
        vaultParams = _vaultParams;

        uint256 assetBalance = IERC20(vaultParams.asset).balanceOf(
            address(this)
        );
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "t27"); //Only keeper can call this function
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(
            newKeeper != address(0),
            "t28" //newKeeper should not be a zero address
        );
        emit ChangeKeeper(keeper, newKeeper);
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(
            newFeeRecipient != address(0),
            "t29" //newFeeRecipient should not be a zero address
        );
        require(newFeeRecipient != feeRecipient, "t30"); //Must be new feeRecipient
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(
            newManagementFee < 100 * Vault.FEE_MULTIPLIER,
            "t31" //Invalid management fee
        );

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = newManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(
            newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
            "t32" //Invalid performance fee
        );

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "t33"); //Cap should be greater than zero
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WMATIC
.
     */
    function depositMATIC() external payable nonReentrant {
        require(
            vaultParams.asset == WMATIC,
            "t34" //Only vault asset can be deposited
        );
        require(msg.value > 0, "t35"); //!value

        _depositFor(msg.value, msg.sender);

        IWMATIC(WMATIC).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "t36"); //Deposit amount must be positive

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "t37"); //Amount must be greater than zero.
        require(creditor != address(0), "t38"); //Creditor address must be set
        require(
            WHITELIST.isUserWhitelisted(msg.sender) ||
                WHITELIST.isVaultWhitelisted(msg.sender),
            "t40" //User is not whitelisted
        );

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    // User deposits -  There is a maximum cap
    // Vault Deposits - no cap

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        bool isVaultWhitelisted = WHITELIST.isVaultWhitelisted(creditor);
        require(
            isVaultWhitelisted || WHITELIST.isUserWhitelisted(creditor),
            "t40" //User is not whitelisted
        );

        uint256 currentRound = vaultState.round;
        // Keep track of the total deposited amount that comes from whitelisted vaults
        if (isVaultWhitelisted) {
            vaultFee.whitelistedVaultAmount[vaultState.round] += amount;
        } else {
            uint256 totalWithDepositedAmount = totalBalance() + amount;

            require(totalWithDepositedAmount <= vaultParams.cap, "t41"); //Exceed cap
            require(
                totalWithDepositedAmount >= vaultParams.minimumSupply,
                "t42" //Insufficient balance
            );
        }

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[depositReceipt.round],
            vaultParams.decimals
        );

        // If we have a pending deposit in the current round, we add on to the pending deposit
        //slither-disable-next-line incorrect-equality
        uint256 depositAmount = amount +
            (
                currentRound == depositReceipt.round
                    ? uint256(depositReceipt.amount)
                    : 0
            );

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    function initiateWithdrawInternal(uint256 numShares, address initiateFor)
        internal
    {
        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[initiateFor].amount > 0 ||
            depositReceipts[initiateFor].unredeemedShares > 0
        ) {
            _redeem(0, true, initiateFor);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[initiateFor];
        //slither-disable-next-line incorrect-equality
        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(initiateFor, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares + numShares;
        } else {
            require(existingShares == 0, "t43"); //Existing withdraw
            withdrawalShares = numShares;
            withdrawal.round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawal.shares = uint128(withdrawalShares);

        uint256 newQueuedWithdrawShares = uint256(
            vaultState.queuedWithdrawShares
        ) + numShares;
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        _transfer(initiateFor, address(this), numShares);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        require(numShares > 0, "t44"); //numShares should be greater than zero
        require(
            WHITELIST.isUserWhitelisted(msg.sender) ||
                WHITELIST.isVaultWhitelisted(msg.sender),
            "t40" //User is not whitelisted
        );
        initiateWithdrawInternal(numShares, msg.sender);
    }

    function initiateWithdrawLawyer(uint256 numShares, address initiateFor)
        external
        nonReentrant
    {
        require(numShares > 0, "t46"); //numShares should be greater than zero
        require(WHITELIST.isLawyer(msg.sender), "t47"); //Lawyer is not whitelisted
        initiateWithdrawInternal(numShares, initiateFor);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round or the current round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "t48"); //Not initiated

        uint16 round = vaultState.round;
        bool isAfterCommitAndClose = optionState.currentOption == address(0);
        require(
            isAfterCommitAndClose || withdrawalRound < round,
            "t49" //Round not closed
        );

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawal.shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares) - withdrawalShares
        );

        uint256 withdrawAmount = ShareMath.sharesToAsset(
            withdrawalShares,
            roundPricePerShare[withdrawalRound],
            vaultParams.decimals
        );
        uint256 vaultFeeToCredit;
        ///@dev whitelisted vaults must withdraw each round only after commitAndClose and before rollToNextOption in order to be able to claim the rebate
        ///if rollToNextOption is called, rebate goes to common pull and can't be claimed anymore
        if (
            isAfterCommitAndClose &&
            IMasterWhitelist(WHITELIST).isVaultWhitelisted(msg.sender)
        ) {
            //total rebate for whitelisted vault in the previous epoch
            //feesNotSentToRecipient was fixed in the current round
            uint256 totalFeeRebate = vaultFee.feesNotSentToRecipient[round];

            // Total deposit amount by whitelisted vaults in the current epoch
            //  deposit for current epoch was made in the "previous epoch"
            uint256 totalVaultDeposit = vaultFee.whitelistedVaultAmount[
                round - 1
            ];

            //total shares owned by whitelisted vaults
            uint256 totalWhitelistedVaultsShares = ShareMath.assetToShares(
                totalVaultDeposit,
                //and share price was fixed in the "previuos epoch" too
                roundPricePerShare[round - 1],
                vaultParams.decimals
            );

            //rebate amount to be added to the withdrawal amount
            if (totalWhitelistedVaultsShares > 0) {
                vaultFeeToCredit =
                    (totalFeeRebate * withdrawalShares) /
                    totalWhitelistedVaultsShares;
            }

            // New Withdraw Amount
            withdrawAmount += vaultFeeToCredit;
        }

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);
        _burn(address(this), withdrawalShares);
        require(
            withdrawAmount > 0,
            "t50" //withdrawAmount should be greater than zero
        );
        transferAsset(msg.sender, withdrawAmount);
        return (withdrawAmount);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(
        uint256 numShares,
        bool isMax,
        address redeemFor
    ) internal {
        Vault.DepositReceipt storage depositReceipt = depositReceipts[
            redeemFor
        ];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[depositReceipt.round],
            vaultParams.decimals
        );

        numShares = isMax ? unredeemedShares : numShares;
        //slither-disable-next-line incorrect-equality
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "t51"); //Exceeds available

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipt.amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipt.unredeemedShares = uint128(unredeemedShares - numShares);

        emit Redeem(redeemFor, numShares, depositReceipt.round);

        _transfer(address(this), redeemFor, numShares);
    }

    /// @notice emergency withdraw all funds of the Vault to the owner. Only the owner can call this function
    function emergencyWithdraw() external onlyOwner {
        uint256 assetAmount = IERC20(vaultParams.asset).balanceOf(
            address(this)
        );

        if (assetAmount > 0) {
            IERC20(vaultParams.asset).safeTransfer(msg.sender, assetAmount);
        }
        uint256 nativeCoinAmount = address(this).balance;
        if (nativeCoinAmount > 0) {
            bool sent = payable(msg.sender).send(nativeCoinAmount);
            require(sent, "t52"); //Failed to send native coin
        }
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    //calculate fees that should be returned to whitelisted vaults instead of being sent to the recepient
    function calcFeesNotSentToRecipient(uint256 totalVaultFee)
        internal
        returns (uint256)
    {
        uint16 round = vaultState.round;

        //base condition: round 0
        if ((totalVaultFee == 0) || (round == 1)) {
            return 0;
        }
        //Total amount of shares that exist
        uint256 totalSharesInContract = balanceOf(address(this)); //might be totalsupply or total balance

        // Total deposit amount by whitelisted vaults in the previous round

        uint256 totalVaultDeposit = vaultFee.whitelistedVaultAmount[round - 1];

        //total shares owned by whitelisted vaults
        uint256 totalWhitelistedVaultsShares = ShareMath.assetToShares(
            totalVaultDeposit,
            roundPricePerShare[round - 1], //first round i
            vaultParams.decimals
        );

        //Amount of funds that should be returned to vaults instead of being sent to the recepient
        uint256 totalFeeRebate = totalSharesInContract > 0
            ? (totalWhitelistedVaultsShares * totalVaultFee) /
                totalSharesInContract
            : 0;

        vaultFee.feesNotSentToRecipient[round] = totalFeeRebate;

        return totalFeeRebate;
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as setting next option, minting new shares, getting vault fees, etc.
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _rollToNextOption(address newOption)
        internal
        returns (uint256 queuedWithdrawAmount)
    {
        require(newOption != address(0), "t54"); //nextOption should exist

        uint256 mintShares;
        (
            //lockedBalance,
            queuedWithdrawAmount,
            mintShares
        ) = VaultLifecycle.rollover(
            vaultState,
            VaultLifecycle.RolloverParams(
                vaultParams.decimals,
                IERC20(vaultParams.asset).balanceOf(address(this)),
                totalSupply(),
                roundPricePerShare[vaultState.round]
            )
        );

        optionState.currentOption = newOption;

        // Finalize the pricePerShare at the end of the round
        uint16 currentRound = vaultState.round;

        _mint(address(this), mintShares);

        vaultState.totalPending = 0;
        vaultState.round = currentRound + 1;

        return (queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an MATIC transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WMATIC) {
            //slither-disable-next-line reentrancy-eth
            IWMATIC(WMATIC).withdraw(amount);
            //slither-disable-next-line arbitrary-send, low-level-calls, reentrancy-benign
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "t55"); //Transfer failed
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare = ShareMath.pricePerShare(
            totalSupply(),
            totalBalance(),
            vaultState.totalPending,
            _decimals
        );

        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount + heldByVault;
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
            vaultParams.decimals
        );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount) +
            IERC20(vaultParams.asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function currentOption() external view returns (address) {
        return optionState.currentOption;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }

    //todo: remove this when we make clear deployment
    // Gap is left to avoid storage collisions. Though TrufinVault is not upgradeable, we add this as a safety measure.
    uint256[50] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // (but can be inserted before ____gap with decreasing ___gap array size)
    // This is to prevent storage collisions. All storage variables should be appended to TrufinThetaVaultStorage
    // or TrufinDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
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

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.14;

/**
 * @title DSMath
 * @notice DS-Math provides arithmetic functions for the common numerical primitive types of Solidity
 */
library DSMath {
    /**
     * @notice Return x + y or an exception in case of uint overflow.
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    /**
     * @notice Return x * y or an exception in case of uint overflow.
     */
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    /**
     * @dev A Wad is a decimal number with 18 digits of precision that is being represented as an integer.
     */
    uint256 constant WAD = 10**18;
    /**
     * @dev rounds to zero if x*y < WAD / 2
     */
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AuctionType {
    struct AuctionData {
        IERC20 auctioningToken;
        IERC20 biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }
}

interface IGnosisAuction {
    // @dev: function to intiate a new auction
    // Warning: In case the auction is expected to raise more than
    // 2^96 units of the biddingToken, don't start the auction, as
    // it will not be settlable. This corresponds to about 79
    // billion DAI.
    //
    // Prices between biddingToken and auctioningToken are expressed by a
    // fraction whose components are stored as uint96.
    function initiateAuction(
        address _auctioningToken,
        address _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256);

    // Returns the number of auctions initiated
    function auctionCounter() external view returns (uint256);

    // Returns AuctionData struct corresponding to @param auctionId
    function auctionData(uint256 auctionId)
        external
        view
        returns (AuctionType.AuctionData memory);

    function auctionAccessManager(uint256 auctionId)
        external
        view
        returns (address);

    function auctionAccessData(uint256 auctionId)
        external
        view
        returns (bytes memory);

    // Getter function for constant FEE_DENOMINATOR
    // @returns 1000
    function FEE_DENOMINATOR() external view returns (uint256);

    // @returns the fraction of fees charged denominated by FEE_DENOMINATOR
    // @dev Value of 10 represents 1% fee (10 / FEE_DENOMINATOR)
    function feeNumerator() external view returns (uint256);

    // @dev function settling the auction and calculating the price
    function settleAuction(uint256 auctionId) external returns (bytes32);

    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external returns (uint64);

    function claimFromParticipantOrder(
        uint256 auctionId,
        bytes32[] memory orders
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral
        // in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(address owner)
        external
        view
        returns (uint256);

    function oracle() external view returns (address);

    function getVault(address _owner, uint256 _vaultId)
        external
        view
        returns (GammaTypes.Vault memory);

    function getProceed(address _owner, uint256 _vaultId)
        external
        view
        returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;
import {Vault} from "../libraries/Vault.sol";

interface IStrikeSelection {
    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256 newStrikePrice, uint256 newDelta);

    /**
     * @notice Getter function for delta
     * @dev delta for options strike price selection. 1 is 10000 (10**4)
     */
    function delta() external view returns (uint256);
}

interface IOptionsPremiumPricer {
    function getPremium(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getPremiumInStables(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getOptionDelta(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 volatility,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta);

    function getUnderlyingPrice() external view returns (uint256);

    function priceOracle() external view returns (address);

    function volatilityOracle() external view returns (address);

    function optionId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {Vault} from "../libraries/Vault.sol";

interface ITrufinThetaVault {
    // Getter function of Vault.OptionState.currentOption
    // Option that the vault is currently shorting / longing
    function currentOption() external view returns (address);

    // Getter function of Vault.OptionState.nextOption
    // Option that the vault is shorting / longing in the next cycle
    function nextOption() external view returns (address);

    // Getter function of struct Vault.VaultParams
    function vaultParams() external view returns (Vault.VaultParams memory);

    // Getter function of struct Vault.VaultState
    function vaultState() external view returns (Vault.VaultState memory);

    // Getter function of struct Vault.OptionParams
    function optionState() external view returns (Vault.OptionState memory);

    // Getter function which returs gammaController
    function GAMMA_CONTROLLER() external view returns (address);

    // Returns the Gnosis AuctionId of this vault option
    function optionAuctionID() external view returns (uint256);

    function withdrawInstantly(uint256 amount) external;

    function completeWithdraw() external returns (uint256 withdrawAmount);

    function initiateWithdraw(uint256 numShares) external;

    function shares(address account) external view returns (uint256);

    function deposit(uint256 amount) external;

    function accountVaultBalance(address account)
        external
        view
        returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IWMATIC {
    /**
     * @notice wrap deposited MATIC into WMATIC
     */
    function deposit() external payable;

    /**
     * @notice withdraw MATIC from contract
     * @dev Unwrap from WMATIC to MATIC
     * @param wad amount WMATIC to unwrap and withdraw
     */
    function withdraw(uint256 wad) external;

    /**
     * @notice Returns the WMATIC balance of @param account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice transfer WMATIC
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transfer(address dst, uint256 wad) external returns (bool);

    /**
     * @notice Returns amount spender is allowed to spend on behalf of the owner
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice approve transfer
     * @param guy address to approve
     * @param wad amount of WMATIC
     * @return True if tx succeeds, False if not
     */
    function approve(address guy, uint256 wad) external returns (bool);

    /**
     * @notice transfer from address
     * @param src source address
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function mint(address receiver_, uint256 amount_) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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