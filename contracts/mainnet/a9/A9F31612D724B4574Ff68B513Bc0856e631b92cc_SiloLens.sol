// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./interfaces/IBaseSilo.sol";
import "./interfaces/ISilo.sol";
import "./lib/EasyMath.sol";
import "./lib/Ping.sol";
import "./lib/Solvency.sol";

/// @title SiloLens
/// @notice Utility contract that simplifies reading data from Silo protocol contracts
/// @custom:security-contact [email protected]
contract SiloLens {
    using EasyMath for uint256;

    ISiloRepository immutable public siloRepository;

    error InvalidRepository();

    constructor (ISiloRepository _siloRepo) {
        if (!Ping.pong(_siloRepo.siloRepositoryPing)) revert InvalidRepository();

        siloRepository = _siloRepo;
    }

    /// @dev Amount of token that is available for borrowing.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return Silo liquidity
    function liquidity(ISilo _silo, address _asset) external view returns (uint256) {
        return ERC20(_asset).balanceOf(address(_silo)) - _silo.assetStorage(_asset).collateralOnlyDeposits;
    }

    /// @notice Get amount of asset token that has been deposited to Silo
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of all deposits made for given asset
    function totalDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.utilizationData(_asset).totalDeposits;
    }

    /// @notice Get amount of asset token that has been deposited to Silo with option "collateralOnly"
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of all "collateralOnly" deposits made for given asset
    function collateralOnlyDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).collateralOnlyDeposits;
    }

    /// @notice Get amount of asset that has been borrowed
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of asset that has been borrowed
    function totalBorrowAmount(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).totalBorrowAmount;
    }

    /// @notice Get amount of fees earned by protocol to date
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of fees earned by protocol to date
    function protocolFees(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.interestData(_asset).protocolFees;
    }

    /// @notice Returns Loan-To-Value for an account
    /// @dev Each Silo has multiple asset markets (bridge assets + unique asset). This function calculates
    /// a sum of all deposits and all borrows denominated in quote token. Returns fraction between borrow value
    /// and deposit value with 18 decimals.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which LTV is calculated
    /// @return userLTV user current LTV with 18 decimals
    function getUserLTV(ISilo _silo, address _user) external view returns (uint256 userLTV) {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        (userLTV, ) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.MaximumLTV
        );
    }

    /// @notice Get totalSupply of debt token
    /// @dev Debt token represents a share in total debt of given asset
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return totalSupply of debt token
    function totalBorrowShare(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.totalSupply();
    }

    /// @notice Calculates current borrow amount for user with interest
    /// @dev Interest is calculated based on the provided timestamp with is expected to be current time.
    /// @param _silo Silo address from which to read data
    /// @param _asset token address for which calculation are done
    /// @param _user account for which calculation are done
    /// @param _timestamp timestamp used for interest calculations
    /// @return total amount of asset user needs to repay at provided timestamp
    function getBorrowAmount(ISilo _silo, address _asset, address _user, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return Solvency.getUserBorrowAmount(
            _silo.assetStorage(_asset),
            _user,
            Solvency.getRcomp(_silo, siloRepository, _asset, _timestamp)
        );
    }

    /// @notice Get debt token balance of a user
    /// @dev Debt token represents a share in total debt of given asset. This method calls balanceOf(_user)
    /// on that token.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of debt token of given user
    function borrowShare(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.balanceOf(_user);
    }

    /// @notice Get underlying balance of all deposits of given token of given user including "collateralOnly"
    /// deposits
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of underlying tokens for the given user
    function collateralBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        // Overflow shouldn't happen if the underlying token behaves correctly, as the total supply of underlying
        // tokens can't overflow by definition
        unchecked {
            return balanceOfUnderlying(_state.totalDeposits, _state.collateralToken, _user) +
                balanceOfUnderlying(_state.collateralOnlyDeposits, _state.collateralOnlyToken, _user);
        }
    }

    /// @notice Get amount of debt of underlying token for given user
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of underlying token owed
    function debtBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        return balanceOfUnderlying(_state.totalBorrowAmount, _state.debtToken, _user);
    }

    /// @notice Calculate value of collateral asset for user
    /// @dev It dynamically adds interest earned. Takes for account collateral only deposits as well.
    /// @param _silo Silo address from which to read data
    /// @param _user account for which calculation are done
    /// @param _asset token address for which calculation are done
    /// @return value of collateral denominated in quote token with 18 decimal
    function calculateCollateralValue(ISilo _silo, address _user, address _asset)
        external
        view
        returns (uint256)
    {
        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();
        ISilo.AssetStorage memory assetStorage = _silo.assetStorage(_asset);

        uint256 assetPrice = priceProviderRepo.getPrice(_asset);
        uint8 assetDecimals = ERC20(_asset).decimals();
        uint256 userCollateralTokenBalance = assetStorage.collateralToken.balanceOf(_user);
        uint256 userCollateralOnlyTokenBalance = assetStorage.collateralOnlyToken.balanceOf(_user);

        uint256 assetAmount = Solvency.getUserCollateralAmount(
            assetStorage,
            userCollateralTokenBalance,
            userCollateralOnlyTokenBalance,
            Solvency.getRcomp(_silo, siloRepository, _asset, block.timestamp),
            siloRepository
        );

        return assetAmount.toValue(assetPrice, assetDecimals);
    }

    /// @notice Calculate value of borrowed asset by user
    /// @dev It dynamically adds interest earned to borrowed amount
    /// @param _silo Silo address from which to read data
    /// @param _user account for which calculation are done
    /// @param _asset token address for which calculation are done
    /// @return value of debt denominated in quote token with 18 decimal
    function calculateBorrowValue(ISilo _silo, address _user, address _asset)
        external
        view
        returns (uint256)
    {
        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();
        uint256 assetPrice = priceProviderRepo.getPrice(_asset);
        uint256 assetDecimals = ERC20(_asset).decimals();

        uint256 rcomp = Solvency.getRcomp(_silo, siloRepository, _asset, block.timestamp);
        uint256 borrowAmount = Solvency.getUserBorrowAmount(_silo.assetStorage(_asset), _user, rcomp);

        return borrowAmount.toValue(assetPrice, assetDecimals);
    }

    /// @notice Get combined liquidation threshold for a user
    /// @dev Methodology for calculating liquidation threshold is as follows. Each Silo is combined form multiple
    /// assets (bridge assets + unique asset). Each of these assets may have different liquidation threshold.
    /// That means effective liquidation threshold must be calculated per asset based on current deposits and
    /// borrows of given account.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return liquidationThreshold liquidation threshold of given user
    function getUserLiquidationThreshold(ISilo _silo, address _user)
        external
        view
        returns (uint256 liquidationThreshold)
    {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        liquidationThreshold = Solvency.calculateLTVLimit(
            Solvency.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.LiquidationThreshold
        );
    }

    /// @notice Get combined maximum Loan-To-Value for a user
    /// @dev Methodology for calculating maximum LTV is as follows. Each Silo is combined form multiple assets
    /// (bridge assets + unique asset). Each of these assets may have different maximum Loan-To-Value for
    /// opening borrow position. That means effective maximum LTV must be calculated per asset based on
    /// current deposits and borrows of given account.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return maximumLTV Maximum Loan-To-Value of given user
    function getUserMaximumLTV(ISilo _silo, address _user) external view returns (uint256 maximumLTV) {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        maximumLTV = Solvency.calculateLTVLimit(
            Solvency.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.MaximumLTV
        );
    }

    /// @notice Check if user is in debt
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return TRUE if user borrowed any amount of any asset, otherwise FALSE
    function inDebt(ISilo _silo, address _user) external view returns (bool) {
        address[] memory allAssets = _silo.getAssets();

        for (uint256 i; i < allAssets.length;) {
            if (_silo.assetStorage(allAssets[i]).debtToken.balanceOf(_user) != 0) return true;

            unchecked {
                i++;
            }
        }

        return false;
    }

    /// @notice Check if user has position (debt or borrow) in any asset
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return TRUE if user has position (debt or borrow) in any asset
    function hasPosition(ISilo _silo, address _user) external view returns (bool) {
        (, ISilo.AssetStorage[] memory assetsStorage) = _silo.getAssetsWithState();

        for (uint256 i; i < assetsStorage.length; i++) {
            if (assetsStorage[i].debtToken.balanceOf(_user) != 0) return true;
            if (assetsStorage[i].collateralToken.balanceOf(_user) != 0) return true;
            if (assetsStorage[i].collateralOnlyToken.balanceOf(_user) != 0) return true;
        }

        return false;
    }

    /// @notice Calculates fraction between borrowed amount and the current liquidity of tokens for given asset
    /// denominated in percentage
    /// @dev Utilization is calculated current values in storage so it does not take for account earned
    /// interest and ever-increasing total borrow amount. It assumes `Model.DP()` = 100%.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return utilization value
    function getUtilization(ISilo _silo, address _asset) external view returns (uint256) {
        ISilo.UtilizationData memory data = ISilo(_silo).utilizationData(_asset);

        return EasyMath.calculateUtilization(
            getModel(_silo, _asset).DP(),
            data.totalDeposits,
            data.totalBorrowAmount
        );
    }

    /// @notice Yearly interest rate for depositing asset token, dynamically calculated for current block timestamp
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return APY with 18 decimals
    function depositAPY(ISilo _silo, address _asset) external view returns (uint256) {
        uint256 dp = getModel(_silo, _asset).DP();

        // amount of deposits in asset decimals
        uint256 totalDepositsAmount = totalDepositsWithInterest(_silo, _asset);

        if (totalDepositsAmount == 0) return 0;

        // amount of debt generated per year in asset decimals
        uint256 generatedDebtAmount = totalBorrowAmountWithInterest(_silo, _asset) * borrowAPY(_silo, _asset) / dp;

        return generatedDebtAmount * Solvency._PRECISION_DECIMALS / totalDepositsAmount;
    }

    /// @notice Calculate amount of entry fee for given amount
    /// @param _amount amount for which to calculate fee
    /// @return Amount of token fee to be paid
    function calcFee(uint256 _amount) external view returns (uint256) {
        uint256 entryFee = siloRepository.entryFee();
        if (entryFee == 0) return 0; // no fee

        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            return _amount * entryFee / Solvency._PRECISION_DECIMALS;
        }
    }

    /// @dev Method for sanity check
    /// @return always true
    function lensPing() external pure returns (bytes4) {
        return this.lensPing.selector;
    }

    /// @notice Yearly interest rate for borrowing asset token, dynamically calculated for current block timestamp
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return APY with 18 decimals
    function borrowAPY(ISilo _silo, address _asset) public view returns (uint256) {
        return getModel(_silo, _asset).getCurrentInterestRate(address(_silo), _asset, block.timestamp);
    }

    /// @notice returns total deposits with interest dynamically calculated at current block timestamp
    /// @param _asset asset address
    /// @return _totalDeposits total deposits amount with interest
    function totalDepositsWithInterest(ISilo _silo, address _asset) public view returns (uint256 _totalDeposits) {
        uint256 rcomp = getModel(_silo, _asset).getCompoundInterestRate(address(_silo), _asset, block.timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();
        ISilo.UtilizationData memory data = _silo.utilizationData(_asset);

        return Solvency.totalDepositsWithInterest(data.totalDeposits, protocolShareFee, rcomp);
    }

    /// @notice returns total borrow amount with interest dynamically calculated at current block timestamp
    /// @param _asset asset address
    /// @return _totalBorrowAmount total deposits amount with interest
    function totalBorrowAmountWithInterest(ISilo _silo, address _asset)
        public
        view
        returns (uint256 _totalBorrowAmount)
    {
        uint256 rcomp = Solvency.getRcomp(_silo, siloRepository, _asset, block.timestamp);
        ISilo.UtilizationData memory data = _silo.utilizationData(_asset);

        return Solvency.totalBorrowAmountWithInterest(data.totalBorrowAmount, rcomp);
    }

    /// @notice Get underlying balance of collateral or debt token
    /// @dev You can think about debt and collateral tokens as cToken in compound. They represent ownership of
    /// debt or collateral in given Silo. This method converts that ownership to exact amount of underlying token.
    /// @param _assetTotalDeposits Total amount of assets that has been deposited or borrowed. For collateral token,
    /// use `totalDeposits` to get this value. For debt token, use `totalBorrowAmount` to get this value.
    /// @param _shareToken share token address. It's the collateral and debt share token address. You can find
    /// these addresses in:
    /// - `ISilo.AssetStorage.collateralToken`
    /// - `ISilo.AssetStorage.collateralOnlyToken`
    /// - `ISilo.AssetStorage.debtToken`
    /// @param _user wallet address for which to read data
    /// @return balance of underlying token deposited or borrowed of given user
    function balanceOfUnderlying(uint256 _assetTotalDeposits, IShareToken _shareToken, address _user)
        public
        view
        returns (uint256)
    {
        uint256 share = _shareToken.balanceOf(_user);
        return share.toAmount(_assetTotalDeposits, _shareToken.totalSupply());
    }

    /// @dev gets interest rates model object
    /// @param _silo Silo address from which to read data
    /// @param _asset asset for which to calculate interest rate
    /// @return IInterestRateModel interest rates model object
    function getModel(ISilo _silo, address _asset) public view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(_silo), _asset));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IShareToken.sol";
import "./IFlashLiquidationReceiver.sol";
import "./ISiloRepository.sol";

interface IBaseSilo {
    enum AssetStatus { Undefined, Active, Removed }

    /// @dev Storage struct that holds all required data for a single token market
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        IShareToken collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        IShareToken collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        IShareToken debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    /// @dev Storage struct that holds data related to fees and interest
    struct AssetInterestData {
        /// @dev Total amount of already harvested protocol fees
        uint256 harvestedProtocolFees;
        /// @dev Total amount (ever growing) of asset token that has been earned by the protocol from
        /// generated interest.
        uint256 protocolFees;
        /// @dev Timestamp of the last time `interestRate` has been updated in storage.
        uint64 interestRateTimestamp;
        /// @dev True if asset was removed from the protocol. If so, deposit and borrow functions are disabled
        /// for that asset
        AssetStatus status;
    }

    /// @notice data that InterestModel needs for calculations
    struct UtilizationData {
        uint256 totalDeposits;
        uint256 totalBorrowAmount;
        /// @dev timestamp of last interest accrual
        uint64 interestRateTimestamp;
    }

    /// @dev Shares names and symbols that are generated while asset initialization
    struct AssetSharesMetadata {
        /// @dev Name for the collateral shares token
        string collateralName;
        /// @dev Symbol for the collateral shares token
        string collateralSymbol;
        /// @dev Name for the collateral only (protected collateral) shares token
        string protectedName;
        /// @dev Symbol for the collateral only (protected collateral) shares token
        string protectedSymbol;
        /// @dev Name for the debt shares token
        string debtName;
        /// @dev Symbol for the debt shares token
        string debtSymbol;
    }

    /// @notice Emitted when deposit is made
    /// @param asset asset address that was deposited
    /// @param depositor wallet address that deposited asset
    /// @param amount amount of asset that was deposited
    /// @param collateralOnly type of deposit, true if collateralOnly deposit was used
    event Deposit(address indexed asset, address indexed depositor, uint256 amount, bool collateralOnly);

    /// @notice Emitted when withdraw is made
    /// @param asset asset address that was withdrawn
    /// @param depositor wallet address that deposited asset
    /// @param receiver wallet address that received asset
    /// @param amount amount of asset that was withdrew
    /// @param collateralOnly type of withdraw, true if collateralOnly deposit was used
    event Withdraw(
        address indexed asset,
        address indexed depositor,
        address indexed receiver,
        uint256 amount,
        bool collateralOnly
    );

    /// @notice Emitted on asset borrow
    /// @param asset asset address that was borrowed
    /// @param user wallet address that borrowed asset
    /// @param amount amount of asset that was borrowed
    event Borrow(address indexed asset, address indexed user, uint256 amount);

    /// @notice Emitted on asset repay
    /// @param asset asset address that was repaid
    /// @param user wallet address that repaid asset
    /// @param amount amount of asset that was repaid
    event Repay(address indexed asset, address indexed user, uint256 amount);

    /// @notice Emitted on user liquidation
    /// @param asset asset address that was liquidated
    /// @param user wallet address that was liquidated
    /// @param shareAmountRepaid amount of collateral-share token that was repaid. This is collateral token representing
    /// ownership of underlying deposit.
    /// @param seizedCollateral amount of underlying token that was seized by liquidator
    event Liquidate(address indexed asset, address indexed user, uint256 shareAmountRepaid, uint256 seizedCollateral);

    /// @notice Emitted when the status for an asset is updated
    /// @param asset asset address that was updated
    /// @param status new asset status
    event AssetStatusUpdate(address indexed asset, AssetStatus indexed status);

    /// @return version of the silo contract
    function VERSION() external returns (uint128); // solhint-disable-line func-name-mixedcase

    /// @notice Synchronize current bridge assets with Silo
    /// @dev This function needs to be called on Silo deployment to setup all assets for Silo. It needs to be
    /// called every time a bridged asset is added or removed. When bridge asset is removed, depositing and borrowing
    /// should be disabled during asset sync.
    function syncBridgeAssets() external;

    /// @notice Get Silo Repository contract address
    /// @return Silo Repository contract address
    function siloRepository() external view returns (ISiloRepository);

    /// @notice Get asset storage data
    /// @param _asset asset address
    /// @return AssetStorage struct
    function assetStorage(address _asset) external view returns (AssetStorage memory);

    /// @notice Get asset interest data
    /// @param _asset asset address
    /// @return AssetInterestData struct
    function interestData(address _asset) external view returns (AssetInterestData memory);

    /// @dev helper method for InterestRateModel calculations
    function utilizationData(address _asset) external view returns (UtilizationData memory data);

    /// @notice Calculates solvency of an account
    /// @param _user wallet address for which solvency is calculated
    /// @return true if solvent, false otherwise
    function isSolvent(address _user) external view returns (bool);

    /// @notice Returns all initialized (synced) assets of Silo including current and removed bridge assets
    /// @return assets array of initialized assets of Silo
    function getAssets() external view returns (address[] memory assets);

    /// @notice Returns all initialized (synced) assets of Silo including current and removed bridge assets
    /// with corresponding state
    /// @return assets array of initialized assets of Silo
    /// @return assetsStorage array of assets state corresponding to `assets` array
    function getAssetsWithState() external view returns (address[] memory assets, AssetStorage[] memory assetsStorage);

    /// @notice Check if depositing an asset for given account is possible
    /// @dev Depositing an asset that has been already borrowed (and vice versa) is disallowed
    /// @param _asset asset we want to deposit
    /// @param _depositor depositor address
    /// @return true if asset can be deposited by depositor
    function depositPossible(address _asset, address _depositor) external view returns (bool);

    /// @notice Check if borrowing an asset for given account is possible
    /// @dev Borrowing an asset that has been already deposited (and vice versa) is disallowed
    /// @param _asset asset we want to deposit
    /// @param _borrower borrower address
    /// @return true if asset can be borrowed by borrower
    function borrowPossible(address _asset, address _borrower) external view returns (bool);

    /// @dev Amount of token that is available for borrowing
    /// @param _asset asset to get liquidity for
    /// @return Silo liquidity
    function liquidity(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IBaseSilo.sol";

interface ISilo is IBaseSilo {
    /// @notice Deposit `_amount` of `_asset` tokens from `msg.sender` to the Silo
    /// @param _asset The address of the token to deposit
    /// @param _amount The amount of the token to deposit
    /// @param _collateralOnly True if depositing collateral only
    /// @return collateralAmount deposited amount
    /// @return collateralShare user collateral shares based on deposited amount
    function deposit(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 collateralAmount, uint256 collateralShare);

    /// @notice Router function to deposit `_amount` of `_asset` tokens to the Silo for the `_depositor`
    /// @param _asset The address of the token to deposit
    /// @param _depositor The address of the recipient of collateral tokens
    /// @param _amount The amount of the token to deposit
    /// @param _collateralOnly True if depositing collateral only
    /// @return collateralAmount deposited amount
    /// @return collateralShare `_depositor` collateral shares based on deposited amount
    function depositFor(address _asset, address _depositor, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 collateralAmount, uint256 collateralShare);

    /// @notice Withdraw `_amount` of `_asset` tokens from the Silo to `msg.sender`
    /// @param _asset The address of the token to withdraw
    /// @param _amount The amount of the token to withdraw
    /// @param _collateralOnly True if withdrawing collateral only deposit
    /// @return withdrawnAmount withdrawn amount that was transferred to user
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function withdraw(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    /// @notice Router function to withdraw `_amount` of `_asset` tokens from the Silo for the `_depositor`
    /// @param _asset The address of the token to withdraw
    /// @param _depositor The address that originally deposited the collateral tokens being withdrawn,
    /// it should be the one initiating the withdrawal through the router
    /// @param _receiver The address that will receive the withdrawn tokens
    /// @param _amount The amount of the token to withdraw
    /// @param _collateralOnly True if withdrawing collateral only deposit
    /// @return withdrawnAmount withdrawn amount that was transferred to `_receiver`
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function withdrawFor(
        address _asset,
        address _depositor,
        address _receiver,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    /// @notice Borrow `_amount` of `_asset` tokens from the Silo to `msg.sender`
    /// @param _asset The address of the token to borrow
    /// @param _amount The amount of the token to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare user debt share based on borrowed amount
    function borrow(address _asset, uint256 _amount) external returns (uint256 debtAmount, uint256 debtShare);

    /// @notice Router function to borrow `_amount` of `_asset` tokens from the Silo for the `_receiver`
    /// @param _asset The address of the token to borrow
    /// @param _borrower The address that will take the loan,
    /// it should be the one initiating the borrowing through the router
    /// @param _receiver The address of the asset receiver
    /// @param _amount The amount of the token to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare `_receiver` debt share based on borrowed amount
    function borrowFor(address _asset, address _borrower, address _receiver, uint256 _amount)
        external
        returns (uint256 debtAmount, uint256 debtShare);

    /// @notice Repay `_amount` of `_asset` tokens from `msg.sender` to the Silo
    /// @param _asset The address of the token to repay
    /// @param _amount amount of asset to repay, includes interests
    /// @return repaidAmount amount repaid
    /// @return burnedShare burned debt share
    function repay(address _asset, uint256 _amount) external returns (uint256 repaidAmount, uint256 burnedShare);

    /// @notice Allows to repay in behalf of borrower to execute liquidation
    /// @param _asset The address of the token to repay
    /// @param _borrower The address of the user to have debt tokens burned
    /// @param _amount amount of asset to repay, includes interests
    /// @return repaidAmount amount repaid
    /// @return burnedShare burned debt share
    function repayFor(address _asset, address _borrower, uint256 _amount)
        external
        returns (uint256 repaidAmount, uint256 burnedShare);

    /// @dev harvest protocol fees from an array of assets
    /// @return harvestedAmounts amount harvested during tx execution for each of silo asset
    function harvestProtocolFees() external returns (uint256[] memory harvestedAmounts);

    /// @notice Function to update interests for `_asset` token since the last saved state
    /// @param _asset The address of the token to be updated
    /// @return interest accrued interest
    function accrueInterest(address _asset) external returns (uint256 interest);

    /// @notice this methods does not requires to have tokens in order to liquidate user
    /// @dev during liquidation process, msg.sender will be notified once all collateral will be send to him
    /// msg.sender needs to be `IFlashLiquidationReceiver`
    /// @param _users array of users to liquidate
    /// @param _flashReceiverData this data will be forward to msg.sender on notification
    /// @return assets array of all processed assets (collateral + debt, including removed)
    /// @return receivedCollaterals receivedCollaterals[userId][assetId] => amount
    /// amounts of collaterals send to `_flashReceiver`
    /// @return shareAmountsToRepaid shareAmountsToRepaid[userId][assetId] => amount
    /// required amounts of debt to be repaid
    function flashLiquidate(address[] memory _users, bytes memory _flashReceiverData)
        external
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepaid
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

library EasyMath {
    error ZeroAssets();
    error ZeroShares();

    function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        uint256 result = amount * totalShares / totalAmount;

        // Prevent rounding error
        if (result == 0 && amount != 0) {
            revert ZeroShares();
        }

        return result;
    }

    function toShareRoundUp(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        uint256 numerator = amount * totalShares;
        uint256 result = numerator / totalAmount;
        
        // Round up
        if (numerator % totalAmount != 0) {
            result += 1;
        }

        return result;
    }

    function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 result = share * totalAmount / totalShares;

        // Prevent rounding error
        if (result == 0 && share != 0) {
            revert ZeroAssets();
        }

        return result;
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        uint256 result = numerator / totalShares;
        
        // Round up
        if (numerator % totalShares != 0) {
            result += 1;
        }

        return result;
    }

    function toValue(uint256 _assetAmount, uint256 _assetPrice, uint256 _assetDecimals)
        internal
        pure
        returns (uint256)
    {
        return _assetAmount * _assetPrice / 10 ** _assetDecimals;
    }

    function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {
        for(uint256 i; i < _numbers.length; i++) {
            s += _numbers[i];
        }
    }

    /// @notice Calculates fraction between borrowed and deposited amount of tokens denominated in percentage
    /// @dev It assumes `_dp` = 100%.
    /// @param _dp decimal points used by model
    /// @param _totalDeposits current total deposits for assets
    /// @param _totalBorrowAmount current total borrows for assets
    /// @return utilization value
    function calculateUtilization(uint256 _dp, uint256 _totalDeposits, uint256 _totalBorrowAmount)
        internal
        pure
        returns (uint256)
    {
        if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

        return _totalBorrowAmount * _dp / _totalDeposits;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/ISilo.sol";
import "../interfaces/IInterestRateModel.sol";
import "../interfaces/ISiloRepository.sol";
import "./EasyMath.sol";

library Solvency {
    using EasyMath for uint256;

    /// @notice
    /// MaximumLTV - Maximum Loan-to-Value ratio represents the maximum borrowing power of all user's collateral
    /// positions in a Silo
    /// LiquidationThreshold - Liquidation Threshold represents the threshold at which all user's borrow positions
    /// in a Silo will be considered under collateralized and subject to liquidation
    enum TypeofLTV { MaximumLTV, LiquidationThreshold }

    error DifferentArrayLength();
    error UnsupportedLTVType();

    struct SolvencyParams {
        /// @param siloRepository SiloRepository address
        ISiloRepository siloRepository;
        /// @param silo Silo address
        ISilo silo;
        /// @param assets array with assets
        address[] assets;
        /// @param assetStates array of states for each asset, where index match the `assets` index
        ISilo.AssetStorage[] assetStates;
        /// @param user wallet address for which to read debt
        address user;
    }

    /// @dev is value that used for integer calculations and decimal points for utilization ratios, LTV, protocol fees
    uint256 internal constant _PRECISION_DECIMALS = 1e18;
    uint256 internal constant _INFINITY = type(uint256).max;

    /// @notice Returns current user LTV and second LTV chosen in params
    /// @dev This function is optimized for protocol use. In some cases there is no need to keep the calculation
    /// going and predefined results can be returned.
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @param _secondLtvType type of LTV to be returned as second value
    /// @return currentUserLTV Loan-to-Value ratio represents current user's proportion of debt to collateral
    /// @return secondLTV second type of LTV which depends on _secondLtvType, zero is returned if the value of the loan
    /// or the collateral are zero
    function calculateLTVs(SolvencyParams memory _params, TypeofLTV _secondLtvType)
        internal
        view
        returns (uint256 currentUserLTV, uint256 secondLTV)
    {
        uint256[] memory totalBorrowAmounts = getBorrowAmounts(_params);

        // this return avoids eg. additional checks on withdraw, when user did not borrow any asset
        if (EasyMath.sum(totalBorrowAmounts) == 0) return (0, 0);

        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory borrowValues = convertAmountsToValues(
            priceProvidersRepository,
            _params.assets,
            totalBorrowAmounts
        );

        // value of user's total debt
        uint256 borrowTotalValue = EasyMath.sum(borrowValues);

        if (borrowTotalValue == 0) return (0, 0);

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMath.sum(collateralValues);

        if (collateralTotalValue == 0) return (_INFINITY, 0);

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _secondLtvType,
            collateralValues
        );

        currentUserLTV = borrowTotalValue * _PRECISION_DECIMALS / collateralTotalValue;

        // one of Solvency.TypeofLTV
        secondLTV = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Calculates chosen LTV limit
    /// @dev This function should be used by external actors like SiloLens and UI/subgraph. `calculateLTVs` is
    /// optimized for protocol use and may not return second LVT calculation when they are not needed.
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @param _ltvType acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @return limit theoretical LTV limit of `_ltvType`
    function calculateLTVLimit(SolvencyParams memory _params, TypeofLTV _ltvType)
        internal
        view
        returns (uint256 limit)
    {
        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMath.sum(collateralValues);

        if (collateralTotalValue == 0) return 0;

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _ltvType,
            collateralValues
        );

        limit = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Returns worth (in quote token) of each collateral deposit of a user
    /// @param _priceProvidersRepository address of IPriceProvidersRepository where prices are read
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return collateralValues worth of each collateral deposit of a user as an array
    function getUserCollateralValues(IPriceProvidersRepository _priceProvidersRepository, SolvencyParams memory _params)
        internal
        view
        returns(uint256[] memory collateralValues)
    {
        uint256[] memory collateralAmounts = getCollateralAmounts(_params);
        collateralValues = convertAmountsToValues(_priceProvidersRepository, _params.assets, collateralAmounts);
    }

    /// @notice Convert assets amounts to values in quote token (amount * price)
    /// @param _priceProviderRepo address of IPriceProvidersRepository where prices are read
    /// @param _assets array with assets for which prices are read
    /// @param _amounts array of amounts
    /// @return values array of values for corresponding assets
    function convertAmountsToValues(
        IPriceProvidersRepository _priceProviderRepo,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal view returns (uint256[] memory values) {
        if (_assets.length != _amounts.length) revert DifferentArrayLength();

        values = new uint256[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] == 0) continue;

            uint256 assetPrice = _priceProviderRepo.getPrice(_assets[i]);
            uint8 assetDecimals = ERC20(_assets[i]).decimals();

            values[i] = _amounts[i].toValue(assetPrice, assetDecimals);
        }
    }

    /// @notice Get amount of collateral for each asset
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return collateralAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not deposit given collateral token.
    function getCollateralAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory collateralAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        collateralAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 userCollateralTokenBalance = _params.assetStates[i].collateralToken.balanceOf(_params.user);
            uint256 userCollateralOnlyTokenBalance = _params.assetStates[i].collateralOnlyToken.balanceOf(_params.user);

            if (userCollateralTokenBalance + userCollateralOnlyTokenBalance == 0) continue;

            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);

            collateralAmounts[i] = getUserCollateralAmount(
                _params.assetStates[i],
                userCollateralTokenBalance,
                userCollateralOnlyTokenBalance,
                rcomp,
                _params.siloRepository
            );
        }
    }

    /// @notice Get amount of debt for each asset
    /// @param _params `Solvency.SolvencyParams` struct with needed params for calculation
    /// @return totalBorrowAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not borrow given token.
    function getBorrowAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory totalBorrowAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        totalBorrowAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);
            totalBorrowAmounts[i] = getUserBorrowAmount(_params.assetStates[i], _params.user, rcomp);
        }
    }

    /// @notice Get amount of deposited token, including collateralOnly deposits
    /// @param _assetStates state of deposited asset in Silo
    /// @param _userCollateralTokenBalance balance of user's share collateral token
    /// @param _userCollateralOnlyTokenBalance balance of user's share collateralOnly token
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @param _siloRepository SiloRepository address
    /// @return amount of underlying token deposited, including collateralOnly deposit
    function getUserCollateralAmount(
        ISilo.AssetStorage memory _assetStates,
        uint256 _userCollateralTokenBalance,
        uint256 _userCollateralOnlyTokenBalance,
        uint256 _rcomp,
        ISiloRepository _siloRepository
    ) internal view returns (uint256) {
        uint256 assetAmount = _userCollateralTokenBalance == 0 ? 0 : _userCollateralTokenBalance.toAmount(
            totalDepositsWithInterest(_assetStates.totalDeposits, _siloRepository.protocolShareFee(), _rcomp),
            _assetStates.collateralToken.totalSupply()
        );

        uint256 assetCollateralOnlyAmount = _userCollateralOnlyTokenBalance == 0
            ? 0
            : _userCollateralOnlyTokenBalance.toAmount(
                _assetStates.collateralOnlyDeposits,
                _assetStates.collateralOnlyToken.totalSupply()
            );

        return assetAmount + assetCollateralOnlyAmount;
    }

    /// @notice Get amount of borrowed token
    /// @param _assetStates state of borrowed asset in Silo
    /// @param _user user wallet address for which to read debt
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @return amount of borrowed token
    function getUserBorrowAmount(ISilo.AssetStorage memory _assetStates, address _user, uint256 _rcomp)
        internal
        view
        returns (uint256)
    {
        uint256 balance = _assetStates.debtToken.balanceOf(_user);
        if (balance == 0) return 0;

        uint256 totalBorrowAmountCached = totalBorrowAmountWithInterest(_assetStates.totalBorrowAmount, _rcomp);
        return balance.toAmountRoundUp(totalBorrowAmountCached, _assetStates.debtToken.totalSupply());
    }

    /// @notice Get compounded interest rate from the model
    /// @param _silo Silo address
    /// @param _siloRepository SiloRepository address
    /// @param _asset address of asset for which to read interest rate
    /// @param _timestamp used to determine amount of time from last rate update
    /// @return rcomp compounded interest rate for an asset
    function getRcomp(ISilo _silo, ISiloRepository _siloRepository, address _asset, uint256 _timestamp)
        internal
        view
        returns (uint256 rcomp)
    {
        IInterestRateModel model = _siloRepository.getInterestRateModel(address(_silo), _asset);
        rcomp = model.getCompoundInterestRate(address(_silo), _asset, _timestamp);
    }

    /// @notice Returns total deposits with interest dynamically calculated with the provided rComp
    /// @param _assetTotalDeposits total deposits for asset
    /// @param _protocolShareFee `siloRepository.protocolShareFee()`
    /// @param _rcomp compounded interest rate
    /// @return _totalDepositsWithInterests total deposits amount with interest
    function totalDepositsWithInterest(uint256 _assetTotalDeposits, uint256 _protocolShareFee, uint256 _rcomp)
        internal
        pure
        returns (uint256 _totalDepositsWithInterests)
    {
        uint256 depositorsShare = _PRECISION_DECIMALS - _protocolShareFee;

        return _assetTotalDeposits + _assetTotalDeposits * _rcomp / _PRECISION_DECIMALS * depositorsShare /
            _PRECISION_DECIMALS;
    }

    /// @notice Returns total borrow amount with interest dynamically calculated with the provided rComp
    /// @param _totalBorrowAmount total borrow amount
    /// @param _rcomp compounded interest rate
    /// @return totalBorrowAmountWithInterests total borrow amount with interest
    function totalBorrowAmountWithInterest(uint256 _totalBorrowAmount, uint256 _rcomp)
        internal
        pure
        returns (uint256 totalBorrowAmountWithInterests)
    {
        totalBorrowAmountWithInterests = _totalBorrowAmount + _totalBorrowAmount * _rcomp / _PRECISION_DECIMALS;
    }

    /// @notice Calculates protocol liquidation fee and new protocol total fees collected
    /// @param _protocolEarnedFees amount of total collected fees so far
    /// @param _amount amount on which we will apply fee
    /// @param _liquidationFee liquidation fee in Solvency._PRECISION_DECIMALS
    /// @return liquidationFeeAmount calculated interest
    /// @return newProtocolEarnedFees the new total amount of protocol fees
    function calculateLiquidationFee(uint256 _protocolEarnedFees, uint256 _amount, uint256 _liquidationFee)
        internal
        pure
        returns (uint256 liquidationFeeAmount, uint256 newProtocolEarnedFees)
    {
        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            liquidationFeeAmount = _amount * _liquidationFee / Solvency._PRECISION_DECIMALS;

            if (_protocolEarnedFees > type(uint256).max - liquidationFeeAmount) {
                newProtocolEarnedFees = type(uint256).max;
                liquidationFeeAmount = type(uint256).max - _protocolEarnedFees;
            } else {
                newProtocolEarnedFees = _protocolEarnedFees + liquidationFeeAmount;
            }
        }
    }

    /// @notice Calculates theoretical value (in quote token) that user could borrow based given collateral value
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _asset address of collateral token
    /// @param _type type of LTV limit to use for calculations
    /// @param _collateralValue value of collateral deposit (in quote token)
    /// @return availableToBorrow value (in quote token) that user can borrow against collateral value
    function _getAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address _asset,
        TypeofLTV _type,
        uint256 _collateralValue
    ) private view returns (uint256 availableToBorrow) {
        uint256 assetLTV;

        if (_type == TypeofLTV.MaximumLTV) {
            assetLTV = _siloRepository.getMaximumLTV(_silo, _asset);
        } else if (_type == TypeofLTV.LiquidationThreshold) {
            assetLTV = _siloRepository.getLiquidationThreshold(_silo, _asset);
        } else {
            revert UnsupportedLTVType();
        }

        // value that can be borrowed against the deposit
        // ie. for assetLTV = 50%, 1 ETH * 50% = 0.5 ETH of available to borrow
        availableToBorrow = _collateralValue * assetLTV / _PRECISION_DECIMALS;
    }

    /// @notice Calculates theoretical value (in quote token) that user can borrow based on deposited collateral
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _assets array with assets
    /// @param _ltvType type of LTV limit to use for calculations
    /// acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @param _collateralValues value (worth in quote token) of each deposit made by user
    /// @return totalAvailableToBorrowValue value (in quote token) that user can borrow against collaterals
    function _getTotalAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address[] memory _assets,
        TypeofLTV _ltvType,
        uint256[] memory _collateralValues
    ) private view returns (uint256 totalAvailableToBorrowValue) {
        if (_assets.length != _collateralValues.length) revert DifferentArrayLength();

        for (uint256 i = 0; i < _assets.length; i++) {
            totalAvailableToBorrowValue += _getAvailableToBorrowValue(
                _siloRepository,
                _silo,
                _assets[i],
                _ltvType,
                _collateralValues[i]
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./INotificationReceiver.sol";

interface IShareToken is IERC20Metadata {
    /// @notice Emitted every time receiver is notified about token transfer
    /// @param notificationReceiver receiver address
    /// @param success false if TX reverted on `notificationReceiver` side, otherwise true
    event NotificationSent(
        INotificationReceiver indexed notificationReceiver,
        bool success
    );

    /// @notice Mint method for Silo to create debt position
    /// @param _account wallet for which to mint token
    /// @param _amount amount of token to be minted
    function mint(address _account, uint256 _amount) external;

    /// @notice Burn method for Silo to close debt position
    /// @param _account wallet for which to burn token
    /// @param _amount amount of token to be burned
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev when performing Silo flash liquidation, FlashReceiver contract will receive all collaterals
interface IFlashLiquidationReceiver {
    /// @dev this method is called when doing Silo flash liquidation
    ///         one can NOT assume, that if _seizedCollateral[i] != 0, then _shareAmountsToRepaid[i] must be 0
    ///         one should assume, that any combination of amounts is possible
    ///         on callback, one must call `Silo.repayFor` because at the end of transaction,
    ///         Silo will check if borrower is solvent.
    /// @param _user user address, that is liquidated
    /// @param _assets array of collateral assets received during user liquidation
    ///         this array contains all assets (collateral borrowed) without any order
    /// @param _receivedCollaterals array of collateral amounts received during user liquidation
    ///         indexes of amounts are related to `_assets`,
    /// @param _shareAmountsToRepaid array of amounts to repay for each asset
    ///         indexes of amounts are related to `_assets`,
    /// @param _flashReceiverData data that are passed from sender that executes liquidation
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes memory _flashReceiverData
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ISiloFactory.sol";
import "./ITokensFactory.sol";
import "./IPriceProvidersRepository.sol";
import "./INotificationReceiver.sol";
import "./IInterestRateModel.sol";

interface ISiloRepository {
    /// @dev protocol fees in precision points (Solvency._PRECISION_DECIMALS), we do allow for fee == 0
    struct Fees {
        /// @dev One time protocol fee for opening a borrow position in precision points (Solvency._PRECISION_DECIMALS)
        uint64 entryFee;
        /// @dev Protocol revenue share in interest paid in precision points (Solvency._PRECISION_DECIMALS)
        uint64 protocolShareFee;
        /// @dev Protocol share in liquidation profit in precision points (Solvency._PRECISION_DECIMALS).
        /// It's calculated from total collateral amount to be transferred to liquidator.
        uint64 protocolLiquidationFee;
    }

    struct SiloVersion {
        /// @dev Default version of Silo. If set to 0, it means it is not set. By default it is set to 1
        uint128 byDefault;

        /// @dev Latest added version of Silo. If set to 0, it means it is not set. By default it is set to 1
        uint128 latest;
    }

    /// @dev AssetConfig struct represents configurable parameters for each Silo
    struct AssetConfig {
        /// @dev Loan-to-Value ratio represents the maximum borrowing power of a specific collateral.
        ///      For example, if the collateral asset has an LTV of 75%, the user can borrow up to 0.75 worth
        ///      of quote token in the principal currency for every quote token worth of collateral.
        ///      value uses 18 decimals eg. 100% == 1e18
        ///      max valid value is 1e18 so it needs storage of 60 bits
        uint64 maxLoanToValue;

        /// @dev Liquidation Threshold represents the threshold at which a borrow position will be considered
        ///      undercollateralized and subject to liquidation for each collateral. For example,
        ///      if a collateral has a liquidation threshold of 80%, it means that the loan will be
        ///      liquidated when the borrowAmount value is worth 80% of the collateral value.
        ///      value uses 18 decimals eg. 100% == 1e18
        uint64 liquidationThreshold;

        /// @dev interest rate model address
        IInterestRateModel interestRateModel;
    }

    event NewDefaultMaximumLTV(uint64 defaultMaximumLTV);

    event NewDefaultLiquidationThreshold(uint64 defaultLiquidationThreshold);

    /// @notice Emitted on new Silo creation
    /// @param silo deployed Silo address
    /// @param asset unique asset for deployed Silo
    /// @param siloVersion version of deployed Silo
    event NewSilo(address indexed silo, address indexed asset, uint128 siloVersion);

    /// @notice Emitted when new Silo (or existing one) becomes a bridge pool (pool with only bridge tokens).
    /// @param pool address of the bridge pool, It can be zero address when bridge asset is removed and pool no longer
    /// is treated as bridge pool
    event BridgePool(address indexed pool);

    /// @notice Emitted on new bridge asset
    /// @param newBridgeAsset address of added bridge asset
    event BridgeAssetAdded(address indexed newBridgeAsset);

    /// @notice Emitted on removed bridge asset
    /// @param bridgeAssetRemoved address of removed bridge asset
    event BridgeAssetRemoved(address indexed bridgeAssetRemoved);

    /// @notice Emitted when default interest rate model is changed
    /// @param newModel address of new interest rate model
    event InterestRateModel(IInterestRateModel indexed newModel);

    /// @notice Emitted on price provider repository address update
    /// @param newProvider address of new oracle repository
    event PriceProvidersRepositoryUpdate(
        IPriceProvidersRepository indexed newProvider
    );

    /// @notice Emitted on token factory address update
    /// @param newTokensFactory address of new token factory
    event TokensFactoryUpdate(address indexed newTokensFactory);

    /// @notice Emitted on router address update
    /// @param newRouter address of new router
    event RouterUpdate(address indexed newRouter);

    /// @notice Emitted on INotificationReceiver address update
    /// @param newIncentiveContract address of new INotificationReceiver
    event NotificationReceiverUpdate(INotificationReceiver indexed newIncentiveContract);

    /// @notice Emitted when new Silo version is registered
    /// @param factory factory address that deploys registered Silo version
    /// @param siloLatestVersion Silo version of registered Silo
    /// @param siloDefaultVersion current default Silo version
    event RegisterSiloVersion(address indexed factory, uint128 siloLatestVersion, uint128 siloDefaultVersion);

    /// @notice Emitted when Silo version is unregistered
    /// @param factory factory address that deploys unregistered Silo version
    /// @param siloVersion version that was unregistered
    event UnregisterSiloVersion(address indexed factory, uint128 siloVersion);

    /// @notice Emitted when default Silo version is updated
    /// @param newDefaultVersion new default version
    event SiloDefaultVersion(uint128 newDefaultVersion);

    /// @notice Emitted when default fee is updated
    /// @param newEntryFee new entry fee
    /// @param newProtocolShareFee new protocol share fee
    /// @param newProtocolLiquidationFee new protocol liquidation fee
    event FeeUpdate(
        uint64 newEntryFee,
        uint64 newProtocolShareFee,
        uint64 newProtocolLiquidationFee
    );

    /// @notice Emitted when asset config is updated for a silo
    /// @param silo silo for which asset config is being set
    /// @param asset asset for which asset config is being set
    /// @param assetConfig new asset config
    event AssetConfigUpdate(address indexed silo, address indexed asset, AssetConfig assetConfig);

    /// @notice Emitted when silo (silo factory) version is set for asset
    /// @param asset asset for which asset config is being set
    /// @param version Silo version
    event VersionForAsset(address indexed asset, uint128 version);

    /// @param _siloAsset silo asset
    /// @return version of Silo that is assigned for provided asset, if not assigned it returns zero (default)
    function getVersionForAsset(address _siloAsset) external returns (uint128);

    /// @notice setter for `getVersionForAsset` mapping
    /// @param _siloAsset silo asset
    /// @param _version version of Silo that will be assigned for `_siloAsset`, zero (default) is acceptable
    function setVersionForAsset(address _siloAsset, uint128 _version) external;

    /// @notice use this method only when off-chain verification is OFF
    /// @dev Silo does NOT support rebase and deflationary tokens
    /// @param _siloAsset silo asset
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @return createdSilo address of created silo
    function newSilo(address _siloAsset, bytes memory _siloData) external returns (address createdSilo);

    /// @notice use this method to deploy new version of Silo for an asset that already has Silo deployed.
    /// Only owner (DAO) can replace.
    /// @dev Silo does NOT support rebase and deflationary tokens
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation. Use 0 for default version which is fine
    /// for 99% of cases.
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @return createdSilo address of created silo
    function replaceSilo(
        address _siloAsset,
        uint128 _siloVersion,
        bytes memory _siloData
    ) external returns (address createdSilo);

    /// @notice Set factory contract for debt and collateral tokens for each Silo asset
    /// @dev Callable only by owner
    /// @param _tokensFactory address of TokensFactory contract that deploys debt and collateral tokens
    function setTokensFactory(address _tokensFactory) external;

    /// @notice Set default fees
    /// @dev Callable only by owner
    /// @param _fees:
    /// - _entryFee one time protocol fee for opening a borrow position in precision points
    /// (Solvency._PRECISION_DECIMALS)
    /// - _protocolShareFee protocol revenue share in interest paid in precision points
    /// (Solvency._PRECISION_DECIMALS)
    /// - _protocolLiquidationFee protocol share in liquidation profit in precision points
    /// (Solvency._PRECISION_DECIMALS). It's calculated from total collateral amount to be transferred
    /// to liquidator.
    function setFees(Fees calldata _fees) external;

    /// @notice Set configuration for given asset in given Silo
    /// @dev Callable only by owner
    /// @param _silo Silo address for which config applies
    /// @param _asset asset address for which config applies
    /// @param _assetConfig:
    ///    - _maxLoanToValue maximum Loan-to-Value, for details see `Repository.AssetConfig.maxLoanToValue`
    ///    - _liquidationThreshold liquidation threshold, for details see `Repository.AssetConfig.maxLoanToValue`
    ///    - _interestRateModel interest rate model address, for details see `Repository.AssetConfig.interestRateModel`
    function setAssetConfig(
        address _silo,
        address _asset,
        AssetConfig calldata _assetConfig
    ) external;

    /// @notice Set default interest rate model
    /// @dev Callable only by owner
    /// @param _defaultInterestRateModel default interest rate model
    function setDefaultInterestRateModel(IInterestRateModel _defaultInterestRateModel) external;

    /// @notice Set default maximum LTV
    /// @dev Callable only by owner
    /// @param _defaultMaxLTV default maximum LTV in precision points (Solvency._PRECISION_DECIMALS)
    function setDefaultMaximumLTV(uint64 _defaultMaxLTV) external;

    /// @notice Set default liquidation threshold
    /// @dev Callable only by owner
    /// @param _defaultLiquidationThreshold default liquidation threshold in precision points
    /// (Solvency._PRECISION_DECIMALS)
    function setDefaultLiquidationThreshold(uint64 _defaultLiquidationThreshold) external;

    /// @notice Set price provider repository
    /// @dev Callable only by owner
    /// @param _repository price provider repository address
    function setPriceProvidersRepository(IPriceProvidersRepository _repository) external;

    /// @notice Set router contract
    /// @dev Callable only by owner
    /// @param _router router address
    function setRouter(address _router) external;

    /// @notice Set NotificationReceiver contract
    /// @dev Callable only by owner
    /// @param _silo silo address for which to set `_notificationReceiver`
    /// @param _notificationReceiver NotificationReceiver address
    function setNotificationReceiver(address _silo, INotificationReceiver _notificationReceiver) external;

    /// @notice Adds new bridge asset
    /// @dev New bridge asset must be unique. Duplicates in bridge assets are not allowed. It's possible to add
    /// bridge asset that has been removed in the past. Note that all Silos must be synced manually. Callable
    /// only by owner.
    /// @param _newBridgeAsset bridge asset address
    function addBridgeAsset(address _newBridgeAsset) external;

    /// @notice Removes bridge asset
    /// @dev Note that all Silos must be synced manually. Callable only by owner.
    /// @param _bridgeAssetToRemove bridge asset address to be removed
    function removeBridgeAsset(address _bridgeAssetToRemove) external;

    /// @notice Registers new Silo version
    /// @dev User can choose which Silo version he wants to deploy. It's possible to have multiple versions of Silo.
    /// Callable only by owner.
    /// @param _factory factory contract that deploys new version of Silo
    /// @param _isDefault true if this version should be used as default
    function registerSiloVersion(ISiloFactory _factory, bool _isDefault) external;

    /// @notice Unregisters Silo version
    /// @dev Callable only by owner.
    /// @param _siloVersion Silo version to be unregistered
    function unregisterSiloVersion(uint128 _siloVersion) external;

    /// @notice Sets default Silo version
    /// @dev Callable only by owner.
    /// @param _defaultVersion Silo version to be set as default
    function setDefaultSiloVersion(uint128 _defaultVersion) external;

    /// @notice Check if contract address is a Silo deployment
    /// @param _silo address of expected Silo
    /// @return true if address is Silo deployment, otherwise false
    function isSilo(address _silo) external view returns (bool);

    /// @notice Get Silo address of asset
    /// @param _asset address of asset
    /// @return address of corresponding Silo deployment
    function getSilo(address _asset) external view returns (address);

    /// @notice Get Silo Factory for given version
    /// @param _siloVersion version of Silo implementation
    /// @return ISiloFactory contract that deploys Silos of given version
    function siloFactory(uint256 _siloVersion) external view returns (ISiloFactory);

    /// @notice Get debt and collateral Token Factory
    /// @return ITokensFactory contract that deploys debt and collateral tokens
    function tokensFactory() external view returns (ITokensFactory);

    /// @notice Get Router contract
    /// @return address of router contract
    function router() external view returns (address);

    /// @notice Get current bridge assets
    /// @dev Keep in mind that not all Silos may be synced with current bridge assets so it's possible that some
    /// assets in that list are not part of given Silo.
    /// @return address array of bridge assets
    function getBridgeAssets() external view returns (address[] memory);

    /// @notice Get removed bridge assets
    /// @dev Keep in mind that not all Silos may be synced with bridge assets so it's possible that some
    /// assets in that list are still part of given Silo.
    /// @return address array of bridge assets
    function getRemovedBridgeAssets() external view returns (address[] memory);

    /// @notice Get maximum LTV for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return maximum LTV in precision points (Solvency._PRECISION_DECIMALS)
    function getMaximumLTV(address _silo, address _asset) external view returns (uint256);

    /// @notice Get Interest Rate Model address for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return address of interest rate model
    function getInterestRateModel(address _silo, address _asset) external view returns (IInterestRateModel);

    /// @notice Get liquidation threshold for asset in given Silo
    /// @dev If dedicated config is not set, method returns default config
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return liquidation threshold in precision points (Solvency._PRECISION_DECIMALS)
    function getLiquidationThreshold(address _silo, address _asset) external view returns (uint256);

    /// @notice Get incentive contract address. Incentive contracts are responsible for distributing rewards
    /// to debt and/or collateral token holders of given Silo
    /// @param _silo address of Silo
    /// @return incentive contract address
    function getNotificationReceiver(address _silo) external view returns (INotificationReceiver);

    /// @notice Get owner role address of Repository
    /// @return owner role address
    function owner() external view returns (address);

    /// @notice get PriceProvidersRepository contract that manages price providers implementations
    /// @return IPriceProvidersRepository address
    function priceProvidersRepository() external view returns (IPriceProvidersRepository);

    /// @dev Get protocol fee for opening a borrow position
    /// @return fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function entryFee() external view returns (uint256);

    /// @dev Get protocol share fee
    /// @return protocol share fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function protocolShareFee() external view returns (uint256);

    /// @dev Get protocol liquidation fee
    /// @return protocol liquidation fee in precision points (Solvency._PRECISION_DECIMALS == 100%)
    function protocolLiquidationFee() external view returns (uint256);

    /// @dev Checks all conditions for new silo creation and throws when not possible to create
    /// @param _asset address of asset for which you want to create silo
    /// @param _assetIsABridge bool TRUE when `_asset` is bridge asset, FALSE when it is not
    function ensureCanCreateSiloFor(address _asset, bool _assetIsABridge) external view;

    function siloRepositoryPing() external pure returns (bytes4);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Common interface for Silo Incentive Contract
interface INotificationReceiver {
    /// @dev Informs the contract about token transfer
    /// @param _token address of the token that was transferred
    /// @param _from sender
    /// @param _to receiver
    /// @param _amount amount that was transferred
    function onAfterTransfer(address _token, address _from, address _to, uint256 _amount) external;

    /// @dev Sanity check function
    /// @return always true
    function notificationReceiverPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface ISiloFactory {
    /// @notice Emitted when Silo is deployed
    /// @param silo address of deployed Silo
    /// @param asset address of asset for which Silo was deployed
    /// @param version version of silo implementation
    event NewSiloCreated(address indexed silo, address indexed asset, uint128 version);

    /// @notice Must be called by repository on constructor
    /// @param _siloRepository the SiloRepository to set
    function initRepository(address _siloRepository) external;

    /// @notice Deploys Silo
    /// @param _siloAsset unique asset for which Silo is deployed
    /// @param _version version of silo implementation
    /// @param _data (optional) data that may be needed during silo creation
    /// @return silo deployed Silo address
    function createSilo(address _siloAsset, uint128 _version, bytes memory _data) external returns (address silo);

    /// @dev just a helper method to see if address is a factory
    function siloFactoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IShareToken.sol";

interface ITokensFactory {
    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed collateral token
    event NewShareCollateralTokenCreated(address indexed token);

    /// @notice Emitted when collateral token is deployed
    /// @param token address of deployed debt token
    event NewShareDebtTokenCreated(address indexed token);

    ///@notice Must be called by repository on constructor
    /// @param _siloRepository the SiloRepository to set
    function initRepository(address _siloRepository) external;

    /// @notice Deploys collateral token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed collateral share token
    function createShareCollateralToken(
        string memory _name,
        string memory _symbol,
        address _asset
    ) external returns (IShareToken);

    /// @notice Deploys debt token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _asset underlying asset for which token is deployed
    /// @return address of deployed debt share token
    function createShareDebtToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        returns (IShareToken);

    /// @dev just a helper method to see if address is a factory
    /// @return always true
    function tokensFactoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

interface IPriceProvidersRepository {
    /// @notice Emitted when price provider is added
    /// @param newPriceProvider new price provider address
    event NewPriceProvider(IPriceProvider indexed newPriceProvider);

    /// @notice Emitted when price provider is removed
    /// @param priceProvider removed price provider address
    event PriceProviderRemoved(IPriceProvider indexed priceProvider);

    /// @notice Emitted when asset is assigned to price provider
    /// @param asset assigned asset   address
    /// @param priceProvider price provider address
    event PriceProviderForAsset(address indexed asset, IPriceProvider indexed priceProvider);

    /// @notice Register new price provider
    /// @param _priceProvider address of price provider
    function addPriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Unregister price provider
    /// @param _priceProvider address of price provider to be removed
    function removePriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Sets price provider for asset
    /// @dev Request for asset price is forwarded to the price provider assigned to that asset
    /// @param _asset address of an asset for which price provider will be used
    /// @param _priceProvider address of price provider
    function setPriceProviderForAsset(address _asset, IPriceProvider _priceProvider) external;

    /// @notice Returns "Time-Weighted Average Price" for an asset
    /// @param _asset address of an asset for which to read price
    /// @return price TWAP price of a token with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Gets price provider assigned to an asset
    /// @param _asset address of an asset for which to get price provider
    /// @return priceProvider address of price provider
    function priceProviders(address _asset) external view returns (IPriceProvider priceProvider);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Gets manager role address
    /// @return manager role address
    function manager() external view returns (address);

    /// @notice Checks if providers are available for an asset
    /// @param _asset asset address to check
    /// @return returns TRUE if price feed is ready, otherwise false
    function providersReadyForAsset(address _asset) external view returns (bool);

    /// @notice Returns true if address is a registered price provider
    /// @param _provider address of price provider to be removed
    /// @return true if address is a registered price provider, otherwise false
    function isPriceProvider(IPriceProvider _provider) external view returns (bool);

    /// @notice Gets number of price providers registered
    /// @return number of price providers registered
    function providersCount() external view returns (uint256);

    /// @notice Gets an array of price providers
    /// @return array of price providers
    function providerList() external view returns (address[] memory);

    /// @notice Sanity check function
    /// @return returns always TRUE
    function priceProvidersRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IInterestRateModel {
    /* solhint-disable */
    struct Config {
        // uopt ∈ (0, 1) – optimal utilization;
        int256 uopt;
        // ucrit ∈ (uopt, 1) – threshold of large utilization;
        int256 ucrit;
        // ulow ∈ (0, uopt) – threshold of low utilization
        int256 ulow;
        // ki > 0 – integrator gain
        int256 ki;
        // kcrit > 0 – proportional gain for large utilization
        int256 kcrit;
        // klow ≥ 0 – proportional gain for low utilization
        int256 klow;
        // klin ≥ 0 – coefficient of the lower linear bound
        int256 klin;
        // beta ≥ 0 - a scaling factor
        int256 beta;
        // ri ≥ 0 – initial value of the integrator
        int256 ri;
        // Tcrit ≥ 0 - the time during which the utilization exceeds the critical value
        int256 Tcrit;
    }
    /* solhint-enable */

    /// @dev Set dedicated config for given asset in a Silo. Config is per asset per Silo so different assets
    /// in different Silo can have different configs.
    /// It will try to call `_silo.accrueInterest(_asset)` before updating config, but it is not guaranteed,
    /// that this call will be successful, if it fail config will be set anyway.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    function setConfig(address _silo, address _asset, Config calldata _config) external;

    /// @dev get compound interest rate and update model storage
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRateAndUpdate(
        address _asset,
        uint256 _blockTimestamp
    ) external returns (uint256 rcomp);

    /// @dev Get config for given asset in a Silo. If dedicated config is not set, default one will be returned.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    /// @return Config struct for asset in Silo
    function getConfig(address _silo, address _asset) external view returns (Config memory);

    /// @dev get compound interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcomp);

    /// @dev get current annual interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function getCurrentInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcur);

    /// @notice get the flag to detect rcomp restriction (zero current interest) due to overflow
    /// overflow boolean flag to detect rcomp restriction
    function overflowDetected(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (bool overflow);

    /// @dev pure function that calculates current annual interest rate
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function calculateCurrentInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (uint256 rcur);

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    /// @return overflow boolean flag to detect rcomp restriction
    function calculateCompoundInterestRateWithOverflowDetection(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit, // solhint-disable-line var-name-mixedcase
        bool overflow
    );

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    function calculateCompoundInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit // solhint-disable-line var-name-mixedcase
    );

    /// @dev returns decimal points used by model
    function DP() external pure returns (uint256); // solhint-disable-line func-name-mixedcase

    /// @dev just a helper method to see if address is a InterestRateModel
    /// @return always true
    function interestRateModelPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title Common interface for Silo Price Providers
interface IPriceProvider {
    /// @notice Returns "Time-Weighted Average Price" for an asset. Calculates TWAP price for quote/asset.
    /// It unifies all tokens decimal to 18, examples:
    /// - if asses == quote it returns 1e18
    /// - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18 WETH per 1 USDC
    /// @param _asset address of an asset for which to read price
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    function getPrice(address _asset) external view returns (uint256 price);

    /// @dev Informs if PriceProvider is setup for asset. It does not means PriceProvider can provide price right away.
    /// Some providers implementations need time to "build" buffer for TWAP price,
    /// so price may not be available yet but this method will return true.
    /// @param _asset asset in question
    /// @return TRUE if asset has been setup, otherwise false
    function assetSupported(address _asset) external view returns (bool);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is PriceProvider
    /// @dev this can save us from simple human errors, in case we use invalid address
    /// but this should NOT be treated as security check
    /// @return always true
    function priceProviderPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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