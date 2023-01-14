// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IAssetTokenData.sol";
import "../interfaces/IAssetToken.sol";
import "../interfaces/IERC20Metadata.sol";

/// @title A contract built for instantly minting AssetTokens.
/// @author Yusuf Seyrek @ Swarm Markets GmbH
/// @notice Deposits the given asset in and issues the underlying AssetToken to the user.
/// @dev Normally, for minting AssetToken: minter should first call requestMint on the AssetToken
/// and then then wait for an approveMint event from the AssetToken issuer which is a role.
/// This contract sits in the AssetToken's issuer role. Because, when issuer role requests mint
/// it is automatically approved. Therefore, setting an AssetToken's issuer role as this contract's
/// address makes the minting instant for the users.
contract AssetTokenIssuer is AccessControlUpgradeable, ERC1155HolderUpgradeable {
    using SafeMath for uint256;

    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE_BPS = 1000;
    uint256 public constant DECIMALS = 10**27;

    uint256 public feeBPS;
    string public description;
    address public custodyAddress;
    address public assetTokenAddress;
    address public assetTokenPriceFeedAddress;
    bool public isMintPaused;

    mapping(address => address) public authorizedAssetsPriceFeedAddresses;

    modifier requireAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller should be Admin");
        _;
    }

    modifier requireNonEmptyAddress(address _address) {
        require(_address != address(0), "Address should be provided");
        _;
    }

    event AssetTokenMinted(
        address indexed to,
        uint256 amount,
        address indexed depositingAsset,
        uint256 depositingAssetAmount
    );
    event AssetAuthorized(address indexed asset, address priceFeed);
    event AssetUnauthorized(address indexed asset);
    event AssetTokenSet(address assetToken, address priceFeed);
    event CustodyAddressSet(address custody);
    event FeeBPSSet(uint256 feeBPS);
    event AssetTokenKyaSet(address assetToken, string kya);
    event DescriptionSet(string description);
    event AssetTokenMintApproved(address assetToken, uint256 mintRequestID, string referenceTo);
    event AssetTokenRedemptionApproved(address assetToken, uint256 redemptionRequestID, string approveTxID);
    event AssetTokenInterestRateSet(address assetToken, uint256 interestRate, bool isPositiveInterest);
    event AssetTokenIssuerTransferred(address assetToken, address newIssuer);
    event AssetTokenDataContractSet(address assetToken, address newAssetTokenData);
    event AssetTokenMinimumRedemptionAmountSet(address assetToken, uint256 minimumRedemptionAmount);
    event AssetTokenContractFreezed(address assetToken);
    event AssetTokenContractUnfreezed(address assetToken);
    event AssetTokenAgentAdded(address assetToken, address newAgent);
    event AssetTokenAgentRemoved(address assetToken, address agent);
    event AssetTokenMemberBlacklistExtended(address assetToken, address account);
    event AssetTokenMemberBlacklistReduced(address assetToken, address account);
    event AssetTokenTransferOnSafeguardAllowed(address assetToken, address account);
    event AssetTokenMintRequested(address assetToken, uint256 amount, address destination);
    event AssetTokenRedemptionRequested(address assetToken, uint256 assetTokenAmount, string destination);
    event AssetTokenRedemptionRequestCancelled(address assetToken, uint256 redemptionRequestID, string motive);
    event AssetTokenTransferOnSafeguardPrevented(address assetToken, address account);

    function initialize(
        string memory _description,
        uint256 _feeBPS,
        address _custodyAddress,
        address _assetTokenAddress,
        address _assetTokenPriceFeedAddress
    ) external initializer {
        require(_custodyAddress != address(0), "Custody should be provided");
        require(_feeBPS <= MAX_FEE_BPS, "Fee can not be greater than 1000 BPS (10%)");
        require(_assetTokenAddress != address(0), "Asset Token should be provided");
        require(_assetTokenPriceFeedAddress != address(0), "Asset Token Price Feed should be provided");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        description = _description;
        feeBPS = _feeBPS;
        custodyAddress = _custodyAddress;
        assetTokenAddress = _assetTokenAddress;
        assetTokenPriceFeedAddress = _assetTokenPriceFeedAddress;
        isMintPaused = false;
    }

    /// @notice Pauses mint functionality
    function pauseMint() external requireAdmin {
        isMintPaused = true;
    }

    /// @notice Unpauses mint functionality
    function unpauseMint() external requireAdmin {
        isMintPaused = false;
    }

    /// @notice Authorizes an asset with its USD price feed.
    /// @dev The authorized asset will be able to deposited in the mint function to get AssetToken in exchange.
    /// @param _assetAddress is the ERC-20 Token address that will be allowed to deposit in mint function.
    /// @param _usdPriceFeedAddress is the USD denominated price feed address of the given asset.
    function authorizeAsset(address _assetAddress, address _usdPriceFeedAddress)
        external
        requireAdmin
        requireNonEmptyAddress(_assetAddress)
        requireNonEmptyAddress(_usdPriceFeedAddress)
    {
        authorizedAssetsPriceFeedAddresses[_assetAddress] = _usdPriceFeedAddress;
        emit AssetAuthorized(_assetAddress, _usdPriceFeedAddress);
    }

    /// @notice Unauthorizes an asset.
    /// @dev Unauthorized assets can't be used in mint function anymore.
    /// @param _assetAddress is the ERC-20 Token address that will be excluded from allowed assets.
    function unauthorizeAsset(address _assetAddress) external requireAdmin requireNonEmptyAddress(_assetAddress) {
        require(authorizedAssetsPriceFeedAddresses[_assetAddress] != address(0), "Asset is already unauthorized");
        authorizedAssetsPriceFeedAddresses[_assetAddress] = address(0);
        emit AssetUnauthorized(_assetAddress);
    }

    /// @notice Sets the AssetToken address and its USD price feed.
    /// @dev The asset token will be the underlying asset for the issuer contract and it will be minted to the user.
    /// @param _assetTokenAddress is the underlying AssetToken address that will be minted within the issuer contract.
    /// @param _usdPriceFeedAddress is the USD denominated price feed address of the given AssetToken.
    function setAssetToken(address _assetTokenAddress, address _usdPriceFeedAddress)
        external
        requireAdmin
        requireNonEmptyAddress(_assetTokenAddress)
        requireNonEmptyAddress(_usdPriceFeedAddress)
    {
        assetTokenAddress = _assetTokenAddress;
        assetTokenPriceFeedAddress = _usdPriceFeedAddress;
        emit AssetTokenSet(_assetTokenAddress, _usdPriceFeedAddress);
    }

    /// @notice Sets the custody wallet address.
    /// @dev Custody wallet address is where issuer protocol keeps the depossitted funds.
    /// @param _custodyAddress is a wallet address that will be used as a vault for deposited assets.
    function setCustodyAddress(address _custodyAddress) external requireAdmin requireNonEmptyAddress(_custodyAddress) {
        custodyAddress = _custodyAddress;
        emit CustodyAddressSet(_custodyAddress);
    }

    /// @notice Sets the fee basis points.
    /// @dev A fee basis point is equal to 1/100th of 1 percent, which is 1 permyriad
    /// @param _feeBPS is a basis points which the issuer will use as fee. MAX VALUE is 1000 BPS = 10%
    function setFeeBPS(uint256 _feeBPS) external requireAdmin {
        require(_feeBPS <= MAX_FEE_BPS, "Fee can not be greater than 1000 BPS (10%)");
        feeBPS = _feeBPS;
        emit FeeBPSSet(_feeBPS);
    }

    /// @notice Sets the underlying AssetToken's kya string.
    /// @dev Only issuer is able to set kya url of the AssetToken.
    /// @param kya is an IPFS url for the metadata JSON.
    function setKya(string memory kya) external requireAdmin {
        _getAssetToken().setKya(kya);
        emit AssetTokenKyaSet(assetTokenAddress, kya);
    }

    /// @notice Sets the description property of this contract.
    /// @dev Description is used for describing the purpose of the deployed contract.
    /// @param _description is a string used for describing the purpose of the contract.
    function setDescription(string memory _description) external requireAdmin {
        description = _description;
        emit DescriptionSet(_description);
    }

    /// @notice Calls the approveMint method of the AssetToken.
    /// @dev Approves the mint request of the AssetToken.
    /// @param mintRequestID is the previously created mint request's ID.
    /// @param referenceTo is the string for specifying the reference for this mint request.
    function approveMint(uint256 mintRequestID, string memory referenceTo) external requireAdmin {
        _getAssetToken().approveMint(mintRequestID, referenceTo);
        emit AssetTokenMintApproved(assetTokenAddress, mintRequestID, referenceTo);
    }

    /// @notice Calls the approveRedemption method of the AssetToken.
    /// @dev Approves the redemption request of the AssetToken.
    /// @param redemptionRequestID is the previously created redemption request's ID.
    /// @param approveTxID is the transaction ID
    function approveRedemption(uint256 redemptionRequestID, string memory approveTxID) external requireAdmin {
        _getAssetToken().approveRedemption(redemptionRequestID, approveTxID);
        emit AssetTokenRedemptionApproved(assetTokenAddress, redemptionRequestID, approveTxID);
    }

    /// @notice Returns the AssetToken's getCurrentRate method's result.
    /// @dev Directly calls and returns the underlying AssetToken's current interest rate.
    function getCurrentRate() public view returns (uint256) {
        return _getAssetTokenData().getCurrentRate(assetTokenAddress);
    }

    /// @notice Sets the AssetToken's interest rate.
    /// @dev Directly calls the underlying AssetToken's set interest rate method.
    /// @param interestRate is the interest rate per-second value.
    /// @param positiveInterest is indicates that if interest rate is positive or negative.
    function setInterestRate(uint256 interestRate, bool positiveInterest) external requireAdmin {
        _getAssetTokenData().setInterestRate(assetTokenAddress, interestRate, positiveInterest);
        emit AssetTokenInterestRateSet(assetTokenAddress, interestRate, positiveInterest);
    }

    /// @notice Returns the AssetToken's getInterestRate method result.
    /// @dev Directly calls the underlying AssetToken's set interest rate method.
    /// @return interestRate interest rate per seconds
    /// @return positiveInterest indicates if interest is positive or negative
    function getInterestRate() external view returns (uint256, bool) {
        return _getAssetTokenData().getInterestRate(assetTokenAddress);
    }

    /// @notice Transfers the issuer role to a new account.
    /// @dev Directly calls the underlying AssetToken's transferIssuer method.
    /// @param newIssuer is the new issuer address.
    function transferIssuer(address newIssuer) external requireAdmin {
        _getAssetTokenData().transferIssuer(assetTokenAddress, newIssuer);
        emit AssetTokenIssuerTransferred(assetTokenAddress, newIssuer);
    }

    /// @notice Sets the AssetTokenData contract of the AssetToken.
    /// @dev Directly calls the underlying AssetToken's setAssetTokenData method.
    /// @param newAssetTokenData is the new asset token data contract address.
    function setAssetTokenData(address newAssetTokenData) external requireAdmin {
        _getAssetToken().setAssetTokenData(newAssetTokenData);
        emit AssetTokenDataContractSet(assetTokenAddress, newAssetTokenData);
    }

    /// @notice Sets the minimum redemption amount of the AssetToken.
    /// @dev Directly calls the underlying AssetToken's setMinimumRedemptionAmount method.
    /// @param _minimumRedemptionAmount is the AssetToken amount that will be allowed to redeem minimum.
    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external requireAdmin {
        _getAssetToken().setMinimumRedemptionAmount(_minimumRedemptionAmount);
        emit AssetTokenMinimumRedemptionAmountSet(assetTokenAddress, _minimumRedemptionAmount);
    }

    /// @notice Freezes the AssetToken contract.
    /// @dev Directly calls the underlying AssetToken's freezeContract method.
    function freezeAssetTokenContract() external requireAdmin {
        _getAssetToken().freezeContract();
        emit AssetTokenContractFreezed(assetTokenAddress);
    }

    /// @notice Unfreezes the AssetToken contract.
    /// @dev Directly calls the underlying AssetToken's unfreezeContract method.
    function unfreezeAssetTokenContract() external requireAdmin {
        _getAssetToken().unfreezeContract();
        emit AssetTokenContractUnfreezed(assetTokenAddress);
    }

    /// @notice Adds an agent to AssetTokenData contract for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's addAgent method.
    /// @param _newAgent is the new agent address
    function addAgent(address _newAgent) external requireAdmin {
        _getAssetTokenData().addAgent(assetTokenAddress, _newAgent);
        emit AssetTokenAgentAdded(assetTokenAddress, _newAgent);
    }

    /// @notice Removes an agent from AssetTokenData contract for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's removeAgent method.
    /// @param _agent is the agent address that will be removed.
    function removeAgent(address _agent) external requireAdmin {
        _getAssetTokenData().removeAgent(assetTokenAddress, _agent);
        emit AssetTokenAgentRemoved(assetTokenAddress, _agent);
    }

    /// @notice Blacklists an account for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's addMemberToBlacklist method.
    /// @param _account is the address that will be blacklisted.
    function addMemberToBlacklist(address _account) external requireAdmin {
        _getAssetTokenData().addMemberToBlacklist(assetTokenAddress, _account);
        emit AssetTokenMemberBlacklistExtended(assetTokenAddress, _account);
    }

    /// @notice Removes an account from the blacklist of the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's removeMemberFromBlacklist method.
    /// @param _account is the address that will be removed from the blacklist.
    function removeMemberFromBlacklist(address _account) external requireAdmin {
        _getAssetTokenData().removeMemberFromBlacklist(assetTokenAddress, _account);
        emit AssetTokenMemberBlacklistReduced(assetTokenAddress, _account);
    }

    /// @notice Allows the account to make transfers on the safeguard mode.
    /// @dev Directly calls the underlying AssetTokenData contract's allowTransferOnSafeguard method.
    /// @param _account is the address that will allowed for trading on the safeguard mode.
    function allowTransferOnSafeguard(address _account) external requireAdmin {
        _getAssetTokenData().allowTransferOnSafeguard(assetTokenAddress, _account);
        emit AssetTokenTransferOnSafeguardAllowed(assetTokenAddress, _account);
    }

    /// @notice Requests minting of the AssetToken.
    /// @dev Mints the requested amount and transfers it to the destination address.
    /// @param _amount is the AssetToken amount requested.
    /// @param _destination is the address that tokens will be minted to.
    function requestMint(uint256 _amount, address _destination) external requireAdmin returns (uint256) {
        uint256 mintRequestID = _getAssetToken().requestMint(_amount, _destination);
        emit AssetTokenMintRequested(assetTokenAddress, _amount, _destination);
        return mintRequestID;
    }

    /// @notice Requests the redemption of the AssetToken.
    /// @dev It will transfer the given asset token amount to the issuer contract and then will execute the
    /// requestRedemption method which redeems the previously deposited asset.
    /// @param _assetTokenAmount is the AssetToken amount wants to be redeemed.
    /// @param _destination is the address that deposited asset will be transferred to.
    /// @return redemptionRequestID is the created redemption request's ID.
    function requestRedemption(uint256 _assetTokenAmount, string memory _destination)
        external
        requireAdmin
        returns (uint256)
    {
        IERC20(assetTokenAddress).transferFrom(_msgSender(), address(this), _assetTokenAmount);
        uint256 redemptionRequestID = _getAssetToken().requestRedemption(_assetTokenAmount, _destination);

        emit AssetTokenRedemptionRequested(assetTokenAddress, _assetTokenAmount, _destination);
        return redemptionRequestID;
    }

    /// @notice Cancels a redemption request.
    /// @dev Calls the AssetToken's cancelRedemptionRequest method.
    /// @param _redemptionRequestID is the redemption request ID that will cancelled.
    /// @param _motive of the cancelation
    function cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) external {
        _getAssetToken().cancelRedemptionRequest(_redemptionRequestID, _motive);
        emit AssetTokenRedemptionRequestCancelled(assetTokenAddress, _redemptionRequestID, _motive);
    }

    /// @notice Prevents the AssetToken's transfers to a specific account on the safe guard mode.
    /// @dev Calls the AssetToken's preventTransferOnSafeguard method.
    /// @param _account is the address that will be prevented making transfers on the safe guard mode.
    function preventTransferOnSafeguard(address _account) external requireAdmin {
        _getAssetTokenData().preventTransferOnSafeguard(assetTokenAddress, _account);
        emit AssetTokenTransferOnSafeguardPrevented(assetTokenAddress, _account);
    }

    /// @notice Returns AssetTokenData contract of the AssetToken for internal usage.
    /// @dev Calls the internal utility method to easily access to the AssetTokenData contract.
    function _getAssetTokenData() private view returns (IAssetTokenData) {
        return IAssetTokenData(_getAssetToken().assetTokenDataAddress());
    }

    /// @notice Returns the AssetToken contract set in this issuer contract for internal usage.
    /// @dev Calls the internal utility method to easily access to the AssetToken contract.
    function _getAssetToken() private view returns (IAssetToken) {
        return IAssetToken(assetTokenAddress);
    }

    /// @notice Returns how much AssetToken will be minted with the given asset and amount.
    /// @dev External method to get how much AssetToken will minted with the given asset and amount-
    /// with the current interest rate included.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    /// @return amountToMint is the estimated amount of AssetToken.
    function getAmountToMint(address asset, uint256 amount) external view returns (uint256) {
        uint256 amountToRequest = calculateAmountToRequestMint(asset, amount);
        uint256 currentRate = getCurrentRate();

        return amountToRequest.mul(DECIMALS).div(currentRate);
    }

    /// @notice Returns how much AssetToken needs to be requested from the AssetToken contract.
    /// @dev Utility method to calculate the value that will be requested for the minting without the interest rate.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    /// @return amountToRequest is the calculated AssetToken amount.
    function calculateAmountToRequestMint(address asset, uint256 amount) public view returns (uint256) {
        uint256 fee = amount.mul(feeBPS).div(BPS);
        uint256 feeDeductedAmount = amount.sub(fee);

        (, int256 assetTokenPrice, , , ) = AggregatorV3Interface(assetTokenPriceFeedAddress).latestRoundData();
        (, int256 assetPrice, , , ) = AggregatorV3Interface(authorizedAssetsPriceFeedAddresses[asset])
            .latestRoundData();

        uint256 assetDecimals = IERC20Metadata(asset).decimals();
        uint256 assetValue = uint256(assetPrice).mul(feeDeductedAmount).div(10**assetDecimals);
        uint256 amountToRequest = assetValue.mul(DECIMALS).div(uint256(assetTokenPrice));

        return amountToRequest;
    }

    /// @notice Instantly mints AssetTokens for the account that calls this method.
    /// @dev This method will transfer the given asset in to the custody address.
    /// Then it calls the requestMint function of the AssetToken with the calculated amount to mint.
    /// Since, this contract is holding the issuer role of the AssetToken; it will instantly accept the request mint.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    function mint(
        address asset,
        uint256 amount,
        uint256 minExpectedAmount
    ) external requireNonEmptyAddress(asset) {
        require(isMintPaused == false, "Mint functionality has been paused");
        require(authorizedAssetsPriceFeedAddresses[asset] != address(0), "Asset is not authorized");
        require(amount > 0, "Amount should be greater than 0");
        require(minExpectedAmount > 0, "Min expected amount should be greater than 0");

        uint256 amountToRequest = calculateAmountToRequestMint(asset, amount);
        uint256 amountToMint = amountToRequest.mul(DECIMALS).div(getCurrentRate());

        require(amountToMint >= minExpectedAmount, "Min expected amount should be less or equal to amount to mint");

        IERC20(asset).transferFrom(_msgSender(), custodyAddress, amount);
        IAssetToken(assetTokenAddress).requestMint(amountToRequest, _msgSender());

        emit AssetTokenMinted(_msgSender(), amountToMint, asset, amount);
    }

    /// @notice Gets the name of the contract.
    /// @dev Contract name can be used to differentiate if issuer is an AssetTokenIssuer contract.
    /// @return name of the contract.
    function name() external pure returns (string memory) {
        return "AssetTokenIssuer";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @author Swarm Markets
/// @title
/// @notice
/// @notice

interface IAssetTokenData {
    function getIssuer(address _tokenAddress) external view returns (address);

    function getGuardian(address _tokenAddress) external view returns (address);

    function setContractToSafeguard(address _tokenAddress) external returns (bool);

    function freezeContract(address _tokenAddress) external returns (bool);

    function unfreezeContract(address _tokenAddress) external returns (bool);

    function isContractActive(address _tokenAddress) external view returns (bool);

    function isContractFreezed(address _tokenAddress) external view returns (bool);

    function beforeTokenTransfer(address, address) external;

    function onlyStoredToken(address _tokenAddress) external view;

    function onlyActiveContract(address _tokenAddress) external view;

    function onlyUnfreezedContract(address _tokenAddress) external view;

    function onlyIssuer(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrGuardian(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrAgent(address _tokenAddress, address _functionCaller) external view;

    function checkIfTransactionIsAllowed(
        address _caller,
        address _from,
        address _to,
        address _tokenAddress,
        bytes4 _operation,
        bytes calldata _data
    ) external view returns (bool);

    function mustBeAuthorizedHolders(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function update(address _tokenAddress) external;

    function getCurrentRate(address _tokenAddress) external view returns (uint256);

    function getInterestRate(address _tokenAddress) external view returns (uint256, bool);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function isAllowedTransferOnSafeguard(address _tokenAddress, address _account) external view returns (bool);

    function registerAssetToken(
        address _tokenAddress,
        address _issuer,
        address _guardian
    ) external returns (bool);

    function transferIssuer(address _tokenAddress, address _newIssuer) external;

    function setInterestRate(
        address _tokenAddress,
        uint256 _interestRate,
        bool _positiveInterest
    ) external;

    function addAgent(address _tokenAddress, address _newAgent) external;

    function removeAgent(address _tokenAddress, address _agent) external;

    function addMemberToBlacklist(address _tokenAddress, address _account) external;

    function removeMemberFromBlacklist(address _tokenAddress, address _account) external;

    function allowTransferOnSafeguard(address _tokenAddress, address _account) external;

    function preventTransferOnSafeguard(address _tokenAddress, address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IAssetToken {
    function assetTokenDataAddress() external view returns (address);

    function requestMint(uint256 _amount, address _destination) external returns (uint256);

    function approveMint(uint256 _mintRequestID, string memory _referenceTo) external;

    function approveRedemption(uint256 _redemptionRequestID, string memory _approveTxID) external;

    function setKya(string memory _kya) external;

    function setAssetTokenData(address _newAddress) external;

    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external;

    function freezeContract() external;

    function unfreezeContract() external;

    function requestRedemption(uint256 _assetTokenAmount, string memory _destination) external returns (uint256);

    function cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}