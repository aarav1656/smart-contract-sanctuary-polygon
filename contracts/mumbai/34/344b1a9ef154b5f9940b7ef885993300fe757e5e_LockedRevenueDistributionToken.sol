// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import "revenue-distribution-token/RevenueDistributionToken.sol";
import "./interfaces/ILockedRevenueDistributionToken.sol";

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██╗░░░░░██████╗░██████╗░████████╗░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██████╔╝██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░███████╗██║░░██║██████╔╝░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░                                                                       ░░░░
░░░░                  Locked Revenue Distribution Token                    ░░░░
░░░░                                                                       ░░░░
░░░░  Extending Maple's RevenueDistributionToken with time-based locking,  ░░░░
░░░░  fee-based instant withdrawals and public vesting schedule updating.  ░░░░
░░░░                                                                       ░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

/**
 * @title ERC-4626 revenue distribution vault with locking.
 * @notice Tokens are locked and must be subject to time-based or fee-based withdrawal conditions.
 * @author GET Protocol
 * @author Uses Maple's RevenueDistributionToken under the AGPL-3.0 (https://github.com/maple-labs/revenue-distribution-token)
 */
contract LockedRevenueDistributionToken is
    ILockedRevenueDistributionToken,
    RevenueDistributionToken
{
    uint256 public constant lockTime = 52 weeks;
    uint256 public earlyWithdrawalFee;

    mapping(address => WithdrawalRequest) public withdrawalRequests;
    mapping(address => bool) public withdrawalFeeExemptions;

    constructor(
        string memory name,
        string memory symbol,
        address owner,
        address asset,
        uint256 precision,
        uint256 _earlyWithdrawalFee
    )
        RevenueDistributionToken(name, symbol, owner, asset, precision)
    {
        earlyWithdrawalFee = _earlyWithdrawalFee;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                     Administrative Functions                      ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /// @notice Sets the early withdrawal fee, applied when making instant withdrawals or redemptions.
    /// @notice Can only be set by owner.
    /// @param percentage_ Fee percentage. Must be an integer between 0 and 100 inclusive.
    function setEarlyWithdrawalFee(uint256 percentage_) external override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(percentage_ >= 0 && percentage_ <= 100, "LRDT:INVALID_FEE");
        earlyWithdrawalFee = percentage_;

        emit EarlyWithdrawalFeeChanged(earlyWithdrawalFee);
    }

    /// @notice Sets or unsets a contract address to be exempt from the withdrawal fee.
    /// @notice Useful in case of future migrations where an approved contract may be given permission to migrate balances to a new token.
    /// @notice Can only be set by owner.
    /// @param addr_ Address to exempt from early withdrawal fees.
    /// @param status_ true to add exemption, false to remove exemption.
    function setWithdrawalFeeExemption(address addr_, bool status_)
        external
        override
    {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        if (status_) {
            withdrawalFeeExemptions[addr_] = true;
        } else {
            delete withdrawalFeeExemptions[addr_];
        }

        emit WithdrawalFeeExemptionStatusChanged(addr_, status_);
    }

    /// @notice Performs a redemption without applying the early withdrawal fee.
    /// @notice Caller must be exempt.
    /// @param shares_ Number of shares to redeem.
    /// @param receiver_ Address to receive underlying assets to. Typically the owner.
    /// @param owner_ Onwer account of the underlying assets.
    /// @return assets_ The assets redeemed and transferred to the receiver.
    function redeemFeeExempt(uint256 shares_, address receiver_, address owner_)
        external
        virtual
        override
        nonReentrant
        returns (uint256 assets_)
    {
        require(withdrawalFeeExemptions[msg.sender], "LRDT:CALLER_NOT_EXEMPT");
        _burn(
            shares_,
            assets_ = super.previewRedeem(shares_),
            receiver_,
            owner_,
            msg.sender
        );
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Staker Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /// @notice Creates a new withdrawal request for future execution using the shares conversion at the point of request. May only be executed after the unlock date.
    /// @notice Users with an active withdrawal request will not be able to transfer the share token.
    /// @dev This only creates a 'right of future redemption' but does not change any underlying balances of shares or assets.
    /// @param shares_ Number of shares to redeem upon unlock.
    function createWithdrawalRequest(uint256 shares_) external override {
        require(
            shares_ <= balanceOf[msg.sender], "LRDT:USER_SHARE_INSUFFICIENT"
        );
        WithdrawalRequest memory _request = WithdrawalRequest(
            block.timestamp + lockTime, shares_, convertToAssets(shares_)
        );
        withdrawalRequests[msg.sender] = _request;

        emit WithdrawalRequestCreated(_request);
    }

    /// @notice Removes any open withdrawal request for the sender.
    function removeWithdrawalRequest() external override {
        delete withdrawalRequests[msg.sender];
        emit WithdrawalRequestRemoved();
    }

    /// @notice Executes an existing withdrawal request that has passed its unlock date.
    function executeWithdrawalRequest() external override nonReentrant {
        WithdrawalRequest memory request = withdrawalRequests[msg.sender];
        require(
            block.timestamp >= request.unlockTime, "LRDT:WITHDRAWAL_NOT_UNLOCKED"
        );

        delete withdrawalRequests[msg.sender];

        _burn(
            request.shares, request.assets, msg.sender, msg.sender, msg.sender
        );
        emit WithdrawalRequestExcercised(request);
    }

    /// @notice Transfers vault share token to another recipient. Overrides ERC20 transfer function.
    /// @notice Transfers will fail when the sender has an active withdrawal request.
    /// @param recipient_ Address to receive tokens.
    /// @param amount_ Amount of tokens to transfer.
    /// @return success_ Returns true on successful transfer.
    function transfer(address recipient_, uint256 amount_)
        external
        override
        returns (bool success_)
    {
        require(
            withdrawalRequests[msg.sender].shares == 0,
            "LRDT:T:EXISTING_WITHDRAWAL_REQUEST"
        );
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @notice Transfers vault share token to another recipient. Overrides ERC20 transferFrom function.
    /// @notice Transfers will fail when the owner has an active withdrawal request.
    /// @param owner_ Address to send tokens from.
    /// @param recipient_ Address to receive tokens.
    /// @param amount_ Amount of tokens to transfer.
    /// @return success_ Returns true on successful transfer.
    function transferFrom(address owner_, address recipient_, uint256 amount_)
        external
        override
        returns (bool success_)
    {
        require(
            withdrawalRequests[owner_].shares == 0,
            "LRDT:T:EXISTING_WITHDRAWAL_REQUEST"
        );
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /// @notice Executes an existing withdrawal request that has passed its unlock date.
    /// @return issuanceRate_ Slope of release of newly added assets.
    /// @return freeAssets_ Amount of assets currently released to stakers.
    function updateVestingSchedule()
        external
        virtual
        returns (uint256 issuanceRate_, uint256 freeAssets_)
    {
        uint256 vestingPeriod_ = 2 weeks;
        // This require is here to prevent public function calls extending the
        // vesting period infinitely. By allowing this to be called again on
        // the last day of the vesting period, we can maintain a regular
        // schedule of reward distribution on the same day of the week.
        //
        // Aside from the following line, and a fixed vesting period, this
        // function is unchanged from the Maple implementation.
        require(
            vestingPeriodFinish <= block.timestamp + 24 hours,
            "LRDT:UVS:STILL_VESTING"
        );
        require(totalSupply != 0, "LRDT:UVS:ZERO_SUPPLY");

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = freeAssets = totalAssets();

        // Calculate slope.
        issuanceRate_ = issuanceRate = (
            (ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision
        ) / vestingPeriod_;

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingPeriod_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         View Functions                            ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /// @dev Rounds down the amount of assets returned to the staker on fee calculation after conversion.
    /// @param shares_  Number of shares to redeem.
    /// @return assets_ Amount of assets that would be withdrawn.
    function previewRedeem(uint256 shares_)
        public
        view
        override
        returns (uint256 assets_)
    {
        assets_ = super.previewRedeem(shares_);
        assets_ = (assets_ * (100 - earlyWithdrawalFee)) / 100;
    }

    /// @dev Rounds down the amount of assets to withdrawn to the staker prior to conversion.
    /// @param assets_ Amount of assets to withdraw.
    /// @param shares_ Number of shares that would be redeemed.
    function previewWithdraw(uint256 assets_)
        public
        view
        override
        returns (uint256 shares_)
    {
        assets_ = (assets_ * 100) / (100 - earlyWithdrawalFee);
        shares_ = super.previewWithdraw(assets_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20 }       from "../modules/erc20/contracts/ERC20.sol";
import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { IRevenueDistributionToken } from "./interfaces/IRevenueDistributionToken.sol";

/*
    ██████╗ ██████╗ ████████╗
    ██╔══██╗██╔══██╗╚══██╔══╝
    ██████╔╝██║  ██║   ██║
    ██╔══██╗██║  ██║   ██║
    ██║  ██║██████╔╝   ██║
    ╚═╝  ╚═╝╚═════╝    ╚═╝
*/

contract RevenueDistributionToken is IRevenueDistributionToken, ERC20 {

    uint256 public immutable override precision;  // Precision of rates, equals max deposit amounts before rounding errors occur

    address public override asset;  // Underlying ERC-20 asset used by ERC-4626 functionality.

    address public override owner;         // Current owner of the contract, able to update the vesting schedule.
    address public override pendingOwner;  // Pending owner of the contract, able to accept ownership.

    uint256 public override freeAssets;           // Amount of assets unlocked regardless of time passed.
    uint256 public override issuanceRate;         // asset/second rate dependent on aggregate vesting schedule.
    uint256 public override lastUpdated;          // Timestamp of when issuance equation was last updated.
    uint256 public override vestingPeriodFinish;  // Timestamp when current vesting schedule ends.

    uint256 private locked = 1;  // Used in reentrancy check.

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier nonReentrant() {
        require(locked == 1, "RDT:LOCKED");

        locked = 2;

        _;

        locked = 1;
    }

    constructor(string memory name_, string memory symbol_, address owner_, address asset_, uint256 precision_)
        ERC20(name_, symbol_, ERC20(asset_).decimals())
    {
        require((owner = owner_) != address(0), "RDT:C:OWNER_ZERO_ADDRESS");

        asset     = asset_;  // Don't need to check zero address as ERC20(asset_).decimals() will fail in ERC20 constructor.
        precision = precision_;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function acceptOwnership() external virtual override {
        require(msg.sender == pendingOwner, "RDT:AO:NOT_PO");

        emit OwnershipAccepted(owner, msg.sender);

        owner        = msg.sender;
        pendingOwner = address(0);
    }

    function setPendingOwner(address pendingOwner_) external virtual override {
        require(msg.sender == owner, "RDT:SPO:NOT_OWNER");

        pendingOwner = pendingOwner_;

        emit PendingOwnerSet(msg.sender, pendingOwner_);
    }

    function updateVestingSchedule(uint256 vestingPeriod_) external virtual override returns (uint256 issuanceRate_, uint256 freeAssets_) {
        require(msg.sender == owner, "RDT:UVS:NOT_OWNER");
        require(totalSupply != 0,    "RDT:UVS:ZERO_SUPPLY");

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = freeAssets = totalAssets();

        // Calculate slope.
        issuanceRate_ = issuanceRate = ((ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision) / vestingPeriod_;

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingPeriod_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    /************************/
    /*** Staker Functions ***/
    /************************/

    function deposit(uint256 assets_, address receiver_) external virtual override nonReentrant returns (uint256 shares_) {
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function depositWithPermit(
        uint256 assets_,
        address receiver_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external virtual override nonReentrant returns (uint256 shares_)
    {
        ERC20(asset).permit(msg.sender, address(this), assets_, deadline_, v_, r_, s_);
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function mint(uint256 shares_, address receiver_) external virtual override nonReentrant returns (uint256 assets_) {
        _mint(shares_, assets_ = previewMint(shares_), receiver_, msg.sender);
    }

    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external virtual override nonReentrant returns (uint256 assets_)
    {
        require((assets_ = previewMint(shares_)) <= maxAssets_, "RDT:MWP:INSUFFICIENT_PERMIT");

        ERC20(asset).permit(msg.sender, address(this), maxAssets_, deadline_, v_, r_, s_);
        _mint(shares_, assets_, receiver_, msg.sender);
    }

    function redeem(uint256 shares_, address receiver_, address owner_) external virtual override nonReentrant returns (uint256 assets_) {
        _burn(shares_, assets_ = previewRedeem(shares_), receiver_, owner_, msg.sender);
    }

    function withdraw(uint256 assets_, address receiver_, address owner_) external virtual override nonReentrant returns (uint256 shares_) {
        _burn(shares_ = previewWithdraw(assets_), assets_, receiver_, owner_, msg.sender);
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal {
        require(receiver_ != address(0), "RDT:M:ZERO_RECEIVER");
        require(shares_   != uint256(0), "RDT:M:ZERO_SHARES");
        require(assets_   != uint256(0), "RDT:M:ZERO_ASSETS");

        _mint(receiver_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() + assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Deposit(caller_, receiver_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        require(ERC20Helper.transferFrom(asset, caller_, address(this), assets_), "RDT:M:TRANSFER_FROM");
    }

    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_) internal {
        require(receiver_ != address(0), "RDT:B:ZERO_RECEIVER");
        require(shares_   != uint256(0), "RDT:B:ZERO_SHARES");
        require(assets_   != uint256(0), "RDT:B:ZERO_ASSETS");

        if (caller_ != owner_) {
            _decreaseAllowance(owner_, caller_, shares_);
        }

        _burn(owner_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() - assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        require(ERC20Helper.transfer(asset, receiver_, assets_), "RDT:B:TRANSFER");
    }

    function _updateIssuanceParams() internal returns (uint256 issuanceRate_) {
        return issuanceRate = (lastUpdated = block.timestamp) > vestingPeriodFinish ? 0 : issuanceRate;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function balanceOfAssets(address account_) public view virtual override returns (uint256 balanceOfAssets_) {
        return convertToAssets(balanceOf[account_]);
    }

    function convertToAssets(uint256 shares_) public view virtual override returns (uint256 assets_) {
        uint256 supply = totalSupply;  // Cache to stack.

        assets_ = supply == 0 ? shares_ : (shares_ * totalAssets()) / supply;
    }

    function convertToShares(uint256 assets_) public view virtual override returns (uint256 shares_) {
        uint256 supply = totalSupply;  // Cache to stack.

        shares_ = supply == 0 ? assets_ : (assets_ * supply) / totalAssets();
    }

    function maxDeposit(address receiver_) external pure virtual override returns (uint256 maxAssets_) {
        receiver_;  // Silence warning
        maxAssets_ = type(uint256).max;
    }

    function maxMint(address receiver_) external pure virtual override returns (uint256 maxShares_) {
        receiver_;  // Silence warning
        maxShares_ = type(uint256).max;
    }

    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        maxShares_ = balanceOf[owner_];
    }

    function maxWithdraw(address owner_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = balanceOfAssets(owner_);
    }

    function previewDeposit(uint256 assets_) public view virtual override returns (uint256 shares_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of shares to issue to a user, given an amount of assets provided.
        shares_ = convertToShares(assets_);
    }

    function previewMint(uint256 shares_) public view virtual override returns (uint256 assets_) {
        uint256 supply = totalSupply;  // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of assets a user must provide, to be issued a given amount of shares.
        assets_ = supply == 0 ? shares_ : _divRoundUp(shares_ * totalAssets(), supply);
    }

    function previewRedeem(uint256 shares_) public view virtual override returns (uint256 assets_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of assets to send to a user, given amount of shares returned.
        assets_ = convertToAssets(shares_);
    }

    function previewWithdraw(uint256 assets_) public view virtual override returns (uint256 shares_) {
        uint256 supply = totalSupply;  // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of shares a user must return, to be sent a given amount of assets.
        shares_ = supply == 0 ? assets_ : _divRoundUp(assets_ * supply, totalAssets());
    }

    function totalAssets() public view virtual override returns (uint256 totalManagedAssets_) {
        uint256 issuanceRate_ = issuanceRate;

        if (issuanceRate_ == 0) return freeAssets;

        uint256 vestingPeriodFinish_ = vestingPeriodFinish;
        uint256 lastUpdated_         = lastUpdated;

        uint256 vestingTimePassed =
            block.timestamp > vestingPeriodFinish_ ?
                vestingPeriodFinish_ - lastUpdated_ :
                block.timestamp - lastUpdated_;

        return ((issuanceRate_ * vestingTimePassed) / precision) + freeAssets;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _divRoundUp(uint256 numerator_, uint256 divisor_) internal pure returns (uint256 result_) {
       return (numerator_ / divisor_) + (numerator_ % divisor_ > 0 ? 1 : 0);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface ILockedRevenueDistributionToken {
    struct WithdrawalRequest {
        uint256 unlockTime;
        uint256 shares;
        uint256 assets;
    }

    event WithdrawalRequestCreated(WithdrawalRequest request);

    event WithdrawalRequestRemoved();

    event WithdrawalRequestExcercised(WithdrawalRequest request);

    event EarlyWithdrawalFeeChanged(uint256 percentage);

    event WithdrawalFeeExemptionStatusChanged(address addr, bool status);

    function createWithdrawalRequest(uint256 shares_) external;

    function removeWithdrawalRequest() external;

    function executeWithdrawalRequest() external;

    function redeemFeeExempt(uint256 shares_, address receiver_, address owner_)
        external
        returns (uint256 assets_);

    function setEarlyWithdrawalFee(uint256 percentage_) external;

    function setWithdrawalFeeExemption(address addr_, bool status_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/*
    ███████╗██████╗  ██████╗    ██████╗  ██████╗
    ██╔════╝██╔══██╗██╔════╝    ╚════██╗██╔═████╗
    █████╗  ██████╔╝██║          █████╔╝██║██╔██║
    ██╔══╝  ██╔══██╗██║         ██╔═══╝ ████╔╝██║
    ███████╗██║  ██║╚██████╗    ███████╗╚██████╔╝
    ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚══════╝ ╚═════╝
*/

/**
 *  @title Modern ERC-20 implementation.
 *  @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {

    /**************/
    /*** ERC-20 ***/
    /**************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /****************/
    /*** ERC-2612 ***/
    /****************/

    // PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public override nonces;

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external override returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function permit(address owner_, address spender_, uint256 amount_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        require(deadline_ >= block.timestamp, "ERC20:P:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) &&
            (v_ == 27 || v_ == 28),
            "ERC20:P:MALLEABLE"
        );

        // Nonce realistically cannot overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                )
            );

            address recoveredAddress = ecrecover(digest, v_, r_, s_);

            require(recoveredAddress == owner_ && owner_ != address(0), "ERC20:P:INVALID_SIGNATURE");
        }

        _approve(owner_, spender_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) external override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) external override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function DOMAIN_SEPARATOR() public view override returns (bytes32 domainSeparator_) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked { totalSupply -= amount_; }

        emit Transfer(owner_, address(0), amount_);
    }

    function _decreaseAllowance(address owner_, address spender_, uint256 subtractedAmount_) internal {
        uint256 spenderAllowance = allowance[owner_][spender_];  // Cache to memory.

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply += amount_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply, and sum of user balances == totalSupply.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(owner_, recipient_, amount_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import {IERC20Like} from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {
    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(
        address token_,
        address to_,
        uint256 amount_
    ) internal returns (bool success_) {
        return
            _call(
                token_,
                abi.encodeWithSelector(
                    IERC20Like.transfer.selector,
                    to_,
                    amount_
                )
            );
    }

    function transferFrom(
        address token_,
        address from_,
        address to_,
        uint256 amount_
    ) internal returns (bool success_) {
        return
            _call(
                token_,
                abi.encodeWithSelector(
                    IERC20Like.transferFrom.selector,
                    from_,
                    to_,
                    amount_
                )
            );
    }

    function approve(
        address token_,
        address spender_,
        uint256 amount_
    ) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (
            !_call(
                token_,
                abi.encodeWithSelector(
                    IERC20Like.approve.selector,
                    spender_,
                    uint256(0)
                )
            )
        ) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return
            _call(
                token_,
                abi.encodeWithSelector(
                    IERC20Like.approve.selector,
                    spender_,
                    amount_
                )
            );
    }

    function _call(address token_, bytes memory data_)
        private
        returns (bool success_)
    {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        (success_, returnData) = token_.call(data_);

        return
            success_ &&
            (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "../../modules/erc20/contracts/interfaces/IERC20.sol";

import { IERC4626 } from "./IERC4626.sol";

/// @title A token that represents ownership of future revenues distributed linearly over time.
interface IRevenueDistributionToken is IERC20, IERC4626 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Issuance parameters have been updated after a `_mint` or `_burn`.
     *  @param freeAssets_   Resulting `freeAssets` (y-intercept) value after accounting update.
     *  @param issuanceRate_ The new issuance rate of `asset` until `vestingPeriodFinish_`.
     */
    event IssuanceParamsUpdated(uint256 freeAssets_, uint256 issuanceRate_);

    /**
     *  @dev   `newOwner_` has accepted the transferral of RDT ownership from `previousOwner_`.
     *  @param previousOwner_ The previous RDT owner.
     *  @param newOwner_      The new RDT owner.
     */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);

    /**
     *  @dev   `owner_` has set the new pending owner of RDT to `pendingOwner_`.
     *  @param owner_        The current RDT owner.
     *  @param pendingOwner_ The new pending RDT owner.
     */
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);

    /**
     *  @dev   `owner_` has updated the RDT vesting schedule to end at `vestingPeriodFinish_`.
     *  @param owner_               The current RDT owner.
     *  @param vestingPeriodFinish_ When the unvested balance will finish vesting.
     */
    event VestingScheduleUpdated(address indexed owner_, uint256 vestingPeriodFinish_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev The total amount of the underlying asset that is currently unlocked and is not time-dependent.
     *       Analogous to the y-intercept in a linear function.
     */
    function freeAssets() external view returns (uint256 freeAssets_);

    /**
     *  @dev The rate of issuance of the vesting schedule that is currently active.
     *       Denominated as the amount of underlying assets vesting per second.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev The timestamp of when the linear function was last recalculated.
     *       Analogous to t0 in a linear function.
     */
    function lastUpdated() external view returns (uint256 lastUpdated_);

    /**
     *  @dev The address of the account that is allowed to update the vesting schedule.
     */
    function owner() external view returns (address owner_);

    /**
     *  @dev The next owner, nominated by the current owner.
     */
    function pendingOwner() external view returns (address pendingOwner_);

    /**
     *  @dev The precision at which the issuance rate is measured.
     */
    function precision() external view returns (uint256 precision_);

    /**
     *  @dev The end of the current vesting schedule.
     */
    function vestingPeriodFinish() external view returns (uint256 vestingPeriodFinish_);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
     *  @dev Sets the pending owner as the new owner.
     *       Can be called only by the pending owner, and only after their nomination by the current owner.
     */
    function acceptOwnership() external;

    /**
     *  @dev   Sets a new address as the pending owner.
     *  @param pendingOwner_ The address of the next potential owner.
     */
    function setPendingOwner(address pendingOwner_) external;

    /**
     *  @dev    Updates the current vesting formula based on the amount of total unvested funds in the contract and the new `vestingPeriod_`.
     *  @param  vestingPeriod_ The amount of time over which all currently unaccounted underlying assets will be vested over.
     *  @return issuanceRate_  The new issuance rate.
     *  @return freeAssets_    The new amount of underlying assets that are unlocked.
     */
    function updateVestingSchedule(uint256 vestingPeriod_) external returns (uint256 issuanceRate_, uint256 freeAssets_);

    /************************/
    /*** Staker Functions ***/
    /************************/

    /**
     *  @dev    Does a ERC4626 `deposit` with a ERC-2612 `permit`.
     *  @param  assets_   The amount of `asset` to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @param  deadline_ The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_        ECDSA signature v component.
     *  @param  r_        ECDSA signature r component.
     *  @param  s_        ECDSA signature s component.
     *  @return shares_   The amount of shares minted.
     */
    function depositWithPermit(uint256 assets_, address receiver_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 shares_);

    /**
     *  @dev    Does a ERC4626 `mint` with a ERC-2612 `permit`.
     *  @param  shares_    The amount of `shares` to mint.
     *  @param  receiver_  The receiver of the shares.
     *  @param  maxAssets_ The maximum amount of assets that can be taken, as per the permit.
     *  @param  deadline_  The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_         ECDSA signature v component.
     *  @param  r_         ECDSA signature r component.
     *  @param  s_         ECDSA signature s component.
     *  @return assets_    The amount of shares deposited.
     */
    function mintWithPermit(uint256 shares_, address receiver_, uint256 maxAssets_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 assets_);


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP, including EIP-2612 permit functionality.
interface IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner_   Account that tokens are approved from.
     *  @param spender_ Account that tokens are approved for.
     *  @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner_     Account that tokens have moved from.
     *  @param recipient_ Account that tokens have moved to.
     *  @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_ Account that tokens are approved for.
     *  @param  amount_  Amount of tokens that have been approved.
     *  @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_          Account that tokens are approved for.
     *  @param  subtractedAmount_ Amount to decrease approval by.
     *  @return success_          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to increase the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_     Account that tokens are approved for.
     *  @param  addedAmount_ Amount to increase approval by.
     *  @return success_     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner_     Account that tokens are moving from.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner_     Account that tokens are approved from.
     *  @param  spender_   Account that tokens are approved for.
     *  @return allowance_ Allowance that one account has given another over their tokens.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account_ Account that owns the tokens.
     *  @return balance_ Amount of tokens owned by a given account.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals_ The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator_ The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /**
     *  @dev    Returns the name of the token.
     *  @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner_  The address of the owner account.
      *  @return nonce_ The nonce for the given owner.
     */
    function nonces(address owner_) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the permit type hash.
     *  @return permitTypehash_ The permit type hash.
     */
    function PERMIT_TYPEHASH() external view returns (bytes32 permitTypehash_);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply_ The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {
    function approve(address spender_, uint256 amount_)
        external
        returns (bool success_);

    function transfer(address recipient_, uint256 amount_)
        external
        returns (bool success_);

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    ) external returns (bool success_);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "../../modules/erc20/contracts/interfaces/IERC20.sol";

/// @title A standard for tokenized Vaults with a single underlying ERC-20 token.
interface IERC4626 is IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   `caller_` has exchanged `assets_` for `shares_` and transferred them to `owner_`.
     *         MUST be emitted when assets are deposited via the `deposit` or `mint` methods.
     *  @param caller_ The caller of the function that emitted the `Deposit` event.
     *  @param owner_  The owner of the shares.
     *  @param assets_ The amount of assets deposited.
     *  @param shares_ The amount of shares minted.
     */
    event Deposit(address indexed caller_, address indexed owner_, uint256 assets_, uint256 shares_);

    /**
     *  @dev   `caller_` has exchanged `shares_`, owned by `owner_`, for `assets_`, and transferred them to `receiver_`.
     *         MUST be emitted when assets are withdrawn via the `withdraw` or `redeem` methods.
     *  @param caller_   The caller of the function that emitted the `Withdraw` event.
     *  @param receiver_ The receiver of the assets.
     *  @param owner_    The owner of the shares.
     *  @param assets_   The amount of assets withdrawn.
     *  @param shares_   The amount of shares burned.
     */
    event Withdraw(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 assets_, uint256 shares_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     *  @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /********************************/
    /*** State Changing Functions ***/
    /********************************/

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of the assets cannot be deposited (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  assets_   The amount of assets to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The amount of shares minted.
     */
    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of shares cannot be minted (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  shares_   The amount of shares to mint.
     *  @param  receiver_ The receiver of the shares.
     *  @return assets_   The amount of assets deposited.
     */
    function mint(uint256 shares_, address receiver_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the shares cannot be redeemed (due to insufficient shares, withdrawal limits, slippage, etc).
     *  @param  shares_   The amount of shares to redeem.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the shares.
     *  @return assets_   The amount of assets sent to the receiver.
     */
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the assets cannot be withdrawn (due to insufficient assets, withdrawal limits, slippage, etc).
     *  @param  assets_   The amount of assets to withdraw.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the assets.
     *  @return shares_   The amount of shares burned from the owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    The amount of `assets_` the `shares_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to convert.
     *  @return assets_ The amount of equivalent assets.
     */
    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    The amount of `shares_` the `assets_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to convert.
     *  @return shares_ The amount of equivalent shares.
     */
    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be deposited on behalf of the `receiver_` through a `deposit` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the assets.
     *  @return assets_   The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver_) external view returns (uint256 assets_);

    /**
     *  @dev    Maximum amount of `shares_` that can be minted on behalf of the `receiver_` through a `mint` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The maximum amount of shares that can be minted.
     */
    function maxMint(address receiver_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `shares_` that can be redeemed from the `owner_` through a `redeem` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned shares otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the shares.
     *  @return shares_ The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be withdrawn from the `owner_` through a `withdraw` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned assets otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the assets.
     *  @return assets_ The maximum amount of assets that can be withdrawn.
     */
    function maxWithdraw(address owner_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of shares that would be minted in a `deposit` call in the same transaction.
     *          MUST NOT account for deposit limits like those returned from `maxDeposit` and should always act as though the deposit would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to withdraw.
     *  @return shares_ The amount of shares that would be redeemed.
     */
    function previewWithdraw(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Total amount of the underlying asset that is managed by the Vault.
     *          SHOULD include compounding that occurs from any yields.
     *          MUST NOT revert.
     *  @return totalAssets_ The total amount of assets the Vault manages.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

}