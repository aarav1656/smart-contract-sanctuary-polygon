/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "State.sol";
import "LoanOpeningsEvents.sol";
import "VaultController.sol";
import "InterestHandler.sol";
import "SwapsUser.sol";
import "PausableGuardian.sol";


contract LoanOpenings is State, LoanOpeningsEvents, VaultController, InterestHandler, SwapsUser, PausableGuardian {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.borrowOrTradeFromPool.selector, target);
        _setTarget(this.setDelegatedManager.selector, target);
        _setTarget(this.getRequiredCollateral.selector, target);
        _setTarget(this.getRequiredCollateralByParams.selector, target);
        _setTarget(this.getBorrowAmount.selector, target);
        _setTarget(this.getBorrowAmountByParams.selector, target);

        // TODO remove next deploy
        _setTarget(bytes4(keccak256("getEstimatedMarginExposure(address,address,uint256,uint256,uint256,uint256,bytes")), address(0));
    }

    // Note: Only callable by loan pools (iTokens)
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] calldata sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
            // collateralTokenReceived: total collateralToken deposit
        bytes calldata loanDataBytes)
        external
        payable
        nonReentrant
        pausable
        returns (LoanOpenData memory)
    {
        require(msg.value == 0 || loanDataBytes.length != 0, "loanDataBytes required with ether");

        // only callable by loan pools
        require(loanPoolToUnderlying[msg.sender] != address(0), "not authorized");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");

        if (initialMargin == 0) {
            require(isTorqueLoan, "initialMargin == 0");
            initialMargin = loanParamsLocal.minInitialMargin;
        }

        // get required collateral
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentValues[1],
            initialMargin,
            isTorqueLoan
        );
        require(collateralAmountRequired != 0, "collateral is 0");

        return _borrowOrTrade(
            loanParamsLocal,
            loanId,
            isTorqueLoan,
            collateralAmountRequired,
            initialMargin,
            sentAddresses,
            sentValues,
            loanDataBytes
        );
    }

    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external
        pausable
    {
        require(loans[loanId].borrower == msg.sender, "unauthorized");

        _setDelegatedManager(
            loanId,
            msg.sender,
            delegated,
            toggle
        );
    }

    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        public
        view
        returns (uint256 collateralAmountRequired)
    {
        if (marginAmount != 0) {
            collateralAmountRequired = _getRequiredCollateral(
                loanToken,
                collateralToken,
                newPrincipal,
                marginAmount,
                isTorqueLoan
            );

            uint256 feePercent = isTorqueLoan ?
                borrowingFeePercent :
                tradingFeePercent;
            if (collateralAmountRequired != 0 && feePercent != 0) {
                collateralAmountRequired = collateralAmountRequired
                    .mul(WEI_PERCENT_PRECISION)
                    .divCeil(
                        WEI_PERCENT_PRECISION - feePercent // never will overflow
                    );
            }
        }
    }

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal)
        public
        view
        returns (uint256 collateralAmountRequired)
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        return getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            newPrincipal,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
    }

    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan)
        public
        view
        returns (uint256 borrowAmount)
    {
        if (marginAmount != 0) {
            if (isTorqueLoan) {
                marginAmount = marginAmount
                    .add(WEI_PERCENT_PRECISION); // adjust for over-collateralized loan
            }

            if (loanToken == collateralToken) {
                borrowAmount = collateralTokenAmount
                    .mul(WEI_PERCENT_PRECISION)
                    .div(marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                    collateralToken,
                    loanToken
                );
                if (sourceToDestPrecision != 0) {
                    borrowAmount = collateralTokenAmount
                        .mul(WEI_PERCENT_PRECISION)
                        .mul(sourceToDestRate)
                        .div(marginAmount)
                        .div(sourceToDestPrecision);
                }
            }

            uint256 feePercent = isTorqueLoan ?
                borrowingFeePercent :
                tradingFeePercent;
            if (borrowAmount != 0 && feePercent != 0) {
                borrowAmount = borrowAmount
                    .mul(
                        WEI_PERCENT_PRECISION - feePercent // never will overflow
                    )
                    .div(WEI_PERCENT_PRECISION);
            }
        }
    }

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount)
        public
        view
        returns (uint256 borrowAmount)
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        return getBorrowAmount(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            collateralTokenAmount,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
    }

    function _borrowOrTrade(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
        bool isTorqueLoan,
        uint256 collateralAmountRequired,
        uint256 initialMargin,
        address[4] memory sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] memory sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenReceived: total loanToken deposit
            // collateralTokenReceived: total collateralToken deposit
        bytes memory loanDataBytes)
        internal
        returns (LoanOpenData memory)
    {
        require (loanParamsLocal.collateralToken != loanParamsLocal.loanToken, "collateral/loan match");
        require (initialMargin >= loanParamsLocal.minInitialMargin, "initialMargin too low");

        // maxLoanTerm == 0 indicates a Torqueloan and requres that torqueInterest != 0
        /*require(loanParamsLocal.maxLoanTerm != 0 ||
            sentValues[2] != 0, // torqueInterest
            "invalid interest");*/

        require(loanId != 0, "invalid loanId");

        // initialize loan
        Loan storage loanLocal = _initializeLoan(
            loanParamsLocal,
            loanId,
            initialMargin,
            sentAddresses,
            sentValues
        );

        poolPrincipalTotal[sentAddresses[0]] = poolPrincipalTotal[sentAddresses[0]]
            .add(sentValues[1]); // newPrincipal

        uint256 amount;
        if (isTorqueLoan) {
            require(sentValues[3] == 0, "surplus loan token");

            amount = _getBorrowingFee(collateralAmountRequired);
            if (amount != 0) {
                _payBorrowingFee(
                    sentAddresses[1], // borrower
                    loanId,
                    loanParamsLocal.collateralToken,
                    amount
                );
            }

        } else {
            amount = 0; // repurposed

            // update collateral after trade
            // sentValues[3] is repurposed to hold loanToCollateralSwapRate to avoid stack too deep error
            uint256 receivedAmount;
            (receivedAmount,,sentValues[3]) = _loanSwap(
                loanId,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                sentAddresses[1], // borrower
                sentValues[3], // loanTokenUsable (minSourceTokenAmount)
                0, // maxSourceTokenAmount (0 means minSourceTokenAmount)
                0, // requiredDestTokenAmount (enforces that all of loanTokenUsable is swapped)
                false, // bypassFee
                loanDataBytes
            );
            sentValues[4] = sentValues[4] // collateralTokenReceived
                .add(receivedAmount);
        }

        // settle collateral
        require(
            _isCollateralSatisfied(
                loanParamsLocal,
                loanLocal,
                initialMargin,
                sentValues[4],
                collateralAmountRequired,
                amount // borrowingFee
            ),
            "collateral insufficient"
        );

        loanLocal.collateral = loanLocal.collateral
            .add(sentValues[4])
            .sub(amount); // borrowingFee

        if (!isTorqueLoan) {
            // reclaiming varaible -> entryLeverage = 100 / initialMargin
            sentValues[2] = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, initialMargin);
        }

        _finalizeOpen(
            loanParamsLocal,
            loanLocal,
            sentAddresses,
            sentValues,
            isTorqueLoan
        );
        if(loanDataBytes.length != 0){
            if(abi.decode(loanDataBytes, (uint128)) & DELEGATE_FLAG != 0) {
                (, bytes[] memory payloads) = abi.decode(loanDataBytes, (uint128, bytes[]));
                _setDelegatedManager(loanId, sentAddresses[1], abi.decode(payloads[1], (address)), true);
            }
        }
        return LoanOpenData({
            loanId: loanId,
            principal: sentValues[1],
            collateral: sentValues[4]
        });
    }

    function _finalizeOpen(
        LoanParams memory loanParamsLocal,
        Loan storage loanLocal,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues,
        bool isTorqueLoan)
        internal
    {
        (uint256 initialMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            initialMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        if (loanLocal.startTimestamp == block.timestamp) {
            if (isTorqueLoan) {
                loanLocal.startRate = collateralToLoanRate;
            } else {
                loanLocal.startRate = sentValues[3]; // loanToCollateralSwapRate
            }
        }

        _emitOpeningEvents(
            loanParamsLocal,
            loanLocal,
            sentAddresses,
            sentValues,
            collateralToLoanRate,
            initialMargin,
            isTorqueLoan
        );
    }

    function _emitOpeningEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues,
        uint256 collateralToLoanRate,
        uint256 margin,
        bool isTorqueLoan)
        internal
    {
        if (isTorqueLoan) {
            emit Borrow(
                sentAddresses[1],                               // user (borrower)
                sentAddresses[0],                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                sentValues[1],                                  // newPrincipal
                sentValues[4],                                  // newCollateral
                0,                                              // interestRate (old value: sentValues[0])
                0,                                              // interestDuration (old value: sentValues[2])
                collateralToLoanRate,                           // collateralToLoanRate,
                margin                                          // currentMargin
            );
        } else {
            // currentLeverage = 100 / currentMargin
            margin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, margin);

            emit Trade(
                sentAddresses[1],                               // user (trader)
                sentAddresses[0],                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.collateralToken,                // collateralToken
                loanParamsLocal.loanToken,                      // loanToken
                sentValues[4],                                  // positionSize
                sentValues[1],                                  // borrowedAmount
                0,                                              // interestRate (old value: sentValues[0])
                0,                                              // settlementDate (old value: loanLocal.endTimestamp)
                sentValues[3],                                  // entryPrice (loanToCollateralSwapRate)
                sentValues[2],                                  // entryLeverage
                margin                                          // currentLeverage
            );
        }
    }

    function _setDelegatedManager(
        bytes32 loanId,
        address delegator,
        address delegated,
        bool toggle)
        internal
    {
        delegatedManagers[loanId][delegated] = toggle;

        emit DelegatedManagerSet(
            loanId,
            delegator,
            delegated,
            toggle
        );
    }

    function _isCollateralSatisfied(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 initialMargin,
        uint256 newCollateral,
        uint256 collateralAmountRequired,
        uint256 borrowingFee)
        internal
        view
        returns (bool)
    {
        // allow at most 2% under-collateralized
        collateralAmountRequired = collateralAmountRequired
            .mul(98 ether)
            .div(100 ether)
            .add(borrowingFee);

        if (newCollateral < collateralAmountRequired) {
            // check that existing collateral is sufficient coverage
            if (loanLocal.collateral != 0) {
                uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
                    loanParamsLocal.loanToken,
                    loanParamsLocal.collateralToken,
                    loanLocal.principal,
                    loanLocal.collateral,
                    initialMargin
                );
                return newCollateral
                    .add(maxDrawdown) >= collateralAmountRequired;
            } else {
                return false;
            }
        }
        return true;
    }

    function _initializeLoan(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
        uint256 initialMargin,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues)
        internal
        returns (Loan storage sloanLocal)
    {
        require(loanParamsLocal.active, "loanParams disabled");

        address lender = sentAddresses[0];
        address borrower = sentAddresses[1];
        address manager = sentAddresses[3];
        uint256 newPrincipal = sentValues[1];

        sloanLocal = loans[loanId];

        if (sloanLocal.id == 0) {
            // new loan
            sloanLocal.id = loanId;
            sloanLocal.loanParamsId = loanParamsLocal.id;
            sloanLocal.principal = newPrincipal;
            sloanLocal.startTimestamp = block.timestamp;
            sloanLocal.startMargin = initialMargin;
            sloanLocal.borrower = borrower;
            sloanLocal.lender = lender;
            sloanLocal.active = true;
            //sloanLocal.pendingTradesId = 0;
            //sloanLocal.collateral = 0; // calculated later
            //sloanLocal.endTimestamp = 0; // calculated later
            //sloanLocal.startRate = 0; // queried later

            activeLoansSet.addBytes32(loanId);
            lenderLoanSets[lender].addBytes32(loanId);
            borrowerLoanSets[borrower].addBytes32(loanId);

            // interest settlement for new loan
            loanRatePerTokenPaid[loanId] = poolRatePerTokenStored[lender];
        } else {
            // existing loan
            sloanLocal = loans[loanId];
            //require(sloanLocal.active && block.timestamp < sloanLocal.endTimestamp, "loan has ended");
            require(sloanLocal.active, "loan has ended");
            require(sloanLocal.borrower == borrower, "borrower mismatch");
            require(sloanLocal.lender == lender, "lender mismatch");
            require(sloanLocal.loanParamsId == loanParamsLocal.id, "loanParams mismatch");

            sloanLocal.principal = sloanLocal.principal
                .add(newPrincipal);
        }

        if (manager != address(0)) {
            _setDelegatedManager(
                loanId,
                borrower,
                manager,
                true
            );
        }
    }

    function _getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        internal
        view
        returns (uint256 collateralTokenAmount)
    {
        if (loanToken == collateralToken) {
            collateralTokenAmount = newPrincipal
                .mul(marginAmount)
                .divCeil(WEI_PERCENT_PRECISION);
        } else {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                collateralToken,
                loanToken
            );
            if (sourceToDestRate != 0) {
                collateralTokenAmount = newPrincipal
                    .mul(sourceToDestPrecision)
                    .mul(marginAmount)
                    .divCeil(sourceToDestRate * WEI_PERCENT_PRECISION);
            }
        }

        if (isTorqueLoan && collateralTokenAmount != 0) {
            collateralTokenAmount = collateralTokenAmount
                .mul(WEI_PERCENT_PRECISION)
                .divCeil(marginAmount)
                .add(collateralTokenAmount);
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "Constants.sol";
import "Objects.sol";
import "EnumerableBytes32Set.sol";
import "ReentrancyGuard.sol";
import "InterestOracle.sol";
import "Ownable.sol";
import "SafeMath.sol";


contract State is Constants, Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;
    address public priceFeeds;                                                              // handles asset reference price lookups
    address public swapsImpl;                                                               // handles asset swaps using dex liquidity

    mapping (bytes4 => address) public logicTargets;                                        // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                                 // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                                      // loanParamsId => LoanParams

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;                    // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;                  // borrower => orderParamsId => Order

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;                // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest;         // lender => loanToken => LenderInterest object (depreciated)
    mapping (bytes32 => LoanInterest) public loanInterest;                                  // loanId => LoanInterest object (depreciated)

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                               // implementations set
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                                // active loans set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;           // lender loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;         // borrow loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;        // user loan params set

    address public feesController;                                                          // address controlling fee withdrawals

    uint256 public lendingFeePercent = 10 ether; // 10% fee                                 // fee taken from lender interest payments
    mapping (address => uint256) public lendingFeeTokensHeld;                               // total interest fees received and not withdrawn per asset
    mapping (address => uint256) public lendingFeeTokensPaid;                               // total interest fees withdraw per asset (lifetime fees = lendingFeeTokensHeld + lendingFeeTokensPaid)

    uint256 public tradingFeePercent = 0.15 ether; // 0.15% fee                             // fee paid for each trade
    mapping (address => uint256) public tradingFeeTokensHeld;                               // total trading fees received and not withdrawn per asset
    mapping (address => uint256) public tradingFeeTokensPaid;                               // total trading fees withdraw per asset (lifetime fees = tradingFeeTokensHeld + tradingFeeTokensPaid)

    uint256 public borrowingFeePercent = 0.09 ether; // 0.09% fee                           // origination fee paid for each loan
    mapping (address => uint256) public borrowingFeeTokensHeld;                             // total borrowing fees received and not withdrawn per asset
    mapping (address => uint256) public borrowingFeeTokensPaid;                             // total borrowing fees withdraw per asset (lifetime fees = borrowingFeeTokensHeld + borrowingFeeTokensPaid)

    uint256 public protocolTokenHeld;                                                       // current protocol token deposit balance
    uint256 public protocolTokenPaid;                                                       // lifetime total payout of protocol token

    uint256 public affiliateFeePercent = 30 ether; // 30% fee share                         // fee share for affiliate program

    mapping (address => mapping (address => uint256)) public liquidationIncentivePercent;   // percent discount on collateral for liquidators per loanToken and collateralToken

    mapping (address => address) public loanPoolToUnderlying;                               // loanPool => underlying
    mapping (address => address) public underlyingToLoanPool;                               // underlying => loanPool
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                                  // loan pools set

    mapping (address => bool) public supportedTokens;                                       // supported tokens for swaps

    uint256 public maxDisagreement = 5 ether;                                               // % disagreement between swap rate and reference rate

    uint256 public sourceBufferPercent = 5 ether;                                           // used to estimate kyber swap source amount

    uint256 public maxSwapSize = 1500 ether;                                                // maximum supported swap size in ETH


    /**** new interest model start */
    mapping(address => uint256) public poolLastUpdateTime; // per itoken
    mapping(address => uint256) public poolPrincipalTotal; // per itoken
    mapping(address => uint256) public poolInterestTotal; // per itoken
    mapping(address => uint256) public poolRatePerTokenStored; // per itoken

    mapping(bytes32 => uint256) public loanInterestTotal; // per loan
    mapping(bytes32 => uint256) public loanRatePerTokenPaid; // per loan

    mapping(address => uint256) internal poolLastInterestRate; // per itoken
    mapping(address => InterestOracle.Observation[256]) internal poolInterestRateObservations; // per itoken
    mapping(address => uint8) internal poolLastIdx; // per itoken
    uint32 public timeDelta;
    uint32 public twaiLength;
    /**** new interest model end */


    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "IWethERC20.sol";


contract Constants {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    uint256 internal constant DAYS_IN_A_YEAR = 365;
    uint256 internal constant ONE_MONTH = 2628000; // approx. seconds in a month

    // string internal constant UserRewardsID = "UserRewards"; // decommissioned
    string internal constant LoanDepositValueID = "LoanDepositValue";

    //IWethERC20 public constant wethToken = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // mainnet
    //address public constant bzrxTokenAddress = 0x56d811088235F11C8920698a204A5010a788f4b3; // mainnet
    //address public constant vbzrxTokenAddress = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F; // mainnet
    //address public constant OOKI = address(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B); // mainnet

    //IWethERC20 public constant wethToken = IWethERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C); // kovan
    //address public constant bzrxTokenAddress = 0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2; // kovan
    //address public constant vbzrxTokenAddress = 0x6F8304039f34fd6A6acDd511988DCf5f62128a32; // kovan
    
    //IWethERC20 public constant wethToken = IWethERC20(0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6); // local testnet only
    //address public constant bzrxTokenAddress = 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87; // local testnet only
    //address public constant vbzrxTokenAddress = 0xa3B53dDCd2E3fC28e8E130288F2aBD8d5EE37472; // local testnet only

    //IWethERC20 public constant wethToken = IWethERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // bsc (Wrapped BNB)
    //address public constant bzrxTokenAddress = address(0); // bsc
    //address public constant vbzrxTokenAddress = address(0); // bsc
    //address public constant OOKI = address(0); // bsc

    IWethERC20 public constant wethToken = IWethERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // polygon (Wrapped MATIC)
    address public constant bzrxTokenAddress = address(0); // polygon
    address public constant vbzrxTokenAddress = address(0); // polygon
    address public constant OOKI = 0xCd150B1F528F326f5194c012f32Eb30135C7C2c9; // polygon

    //IWethERC20 public constant wethToken = IWethERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); // avax (Wrapped AVAX)
    //address public constant bzrxTokenAddress = address(0); // avax
    //address public constant vbzrxTokenAddress = address(0); // avax

    // IWethERC20 public constant wethToken = IWethERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); // arbitrum
    // address public constant bzrxTokenAddress = address(0); // arbitrum
    // address public constant vbzrxTokenAddress = address(0); // arbitrum
    // address public constant OOKI = address(0x400F3ff129Bc9C9d239a567EaF5158f1850c65a4); // arbitrum
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "IWeth.sol";
import "IERC20.sol";


contract IWethERC20 is IWeth, IERC20 {}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "LoanStruct.sol";
import "LoanParamsStruct.sol";
import "OrderStruct.sol";
import "LenderInterestStruct.sol";
import "LoanInterestStruct.sol";


contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanStruct {
    struct Loan {
        bytes32 id;                 // id of the loan
        bytes32 loanParamsId;       // the linked loan params id
        bytes32 pendingTradesId;    // the linked pending trades id
        uint256 principal;          // total borrowed amount outstanding
        uint256 collateral;         // total collateral escrowed for the loan
        uint256 startTimestamp;     // loan start time
        uint256 endTimestamp;       // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin;        // initial margin when the loan opened
        uint256 startRate;          // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower;           // borrower of this loan
        address lender;             // lender of this loan
        bool active;                // if false, the loan has been fully closed
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanParamsStruct {
    struct LoanParams {
        bytes32 id;                 // id of loan params object
        bool active;                // if false, this object has been disabled by the owner and can't be used for future loans
        address owner;              // owner of this object
        address loanToken;          // the token being loaned
        address collateralToken;    // the required collateral token
        uint256 minInitialMargin;   // the minimum allowed initial margin
        uint256 maintenanceMargin;  // an unhealthy loan when current margin is at or below this value
        uint256 maxLoanTerm;        // the maximum term for new loans (0 means there's no max term)
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract OrderStruct {
    struct Order {
        uint256 lockedAmount;           // escrowed amount waiting for a counterparty
        uint256 interestRate;           // interest rate defined by the creator of this order
        uint256 minLoanTerm;            // minimum loan term allowed
        uint256 maxLoanTerm;            // maximum loan term allowed
        uint256 createdTimestamp;       // timestamp when this order was created
        uint256 expirationTimestamp;    // timestamp when this order expires
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding of asset (DEPRECIATED)
        uint256 owedPerDay;         // interest owed per day for all loans of asset (DEPRECIATED)
        uint256 owedTotal;          // total interest owed for all loans of asset (DEPRECIATED)
        uint256 paidTotal;          // total interest paid so far for asset (DEPRECIATED)
        uint256 updatedTimestamp;   // last update (DEPRECIATED)
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interest owed per day for loan (DEPRECIATED)
        uint256 depositTotal;       // total escrowed interest for loan (DEPRECIATED)
        uint256 updatedTimestamp;   // last update (DEPRECIATED)
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes32Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            output[i-start] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function getAddress(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (address)
    {
        bytes32 value = set.values[index];
        address addrvalue;
        assembly {
            addrvalue := value
        }
        return addrvalue;
    }
}

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]Ï€.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

pragma solidity ^0.5.0;

library InterestOracle {
    struct Observation {
        uint32 blockTimestamp;
        int56 irCumulative;
        int24 tick;
    }

    /// @param last The specified observation
    /// @param blockTimestamp The new timestamp
    /// @param tick The active tick
    /// @return Observation The newly populated observation
    function convert(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick
    ) private pure returns (Observation memory) {
        return
            Observation({
                blockTimestamp: blockTimestamp,
                irCumulative: last.irCumulative + int56(tick) * (blockTimestamp - last.blockTimestamp),
                tick: tick
            });
    }

    /// @param self oracle array
    /// @param index most recent observation index
    /// @param blockTimestamp timestamp of observation
    /// @param tick active tick
    /// @param cardinality populated elements
    /// @param minDelta minimum time delta between observations
    /// @return indexUpdated The new index
    function write(
        Observation[256] storage self,
        uint8 index,
        uint32 blockTimestamp,
        int24 tick,
        uint8 cardinality,
        uint32 minDelta
    ) internal returns (uint8 indexUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation in last minDelta seconds
        if (last.blockTimestamp + minDelta >= blockTimestamp) return index;

        indexUpdated = (index + 1) % cardinality;
        self[indexUpdated] = convert(last, blockTimestamp, tick);
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param index latest index
    /// @param cardinality populated elements
    function binarySearch(
        Observation[256] storage self,
        uint32 target,
        uint8 index,
        uint8 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            if (beforeOrAt.blockTimestamp == 0) {
                l = 0;
                r = index;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;
            bool targetBeforeOrAt = atOrAfter.blockTimestamp >= target;
            if (!targetAtOrAfter) {
                r = i - 1;
                continue;
            } else if (!targetBeforeOrAt) {
                l = i + 1;
                continue;
            }
            break;
        }
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param tick current tick
    /// @param index latest index
    /// @param cardinality populated elements
    function getSurroundingObservations(
        Observation[256] storage self,
        uint32 target,
        int24 tick,
        uint8 index,
        uint8 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {

        beforeOrAt = self[index];

        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                return (beforeOrAt, atOrAfter);
            } else {
                return (beforeOrAt, convert(beforeOrAt, target, tick));
            }
        }

        beforeOrAt = self[(index + 1) % cardinality];
        if (beforeOrAt.blockTimestamp == 0) beforeOrAt = self[0];
        require(beforeOrAt.blockTimestamp <= target && beforeOrAt.blockTimestamp != 0, "OLD");
        return binarySearch(self, target, index, cardinality);
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgo lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return irCumulative cumulative interest rate, calculated with rate * time
    function observeSingle(
        Observation[256] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint8 index,
        uint8 cardinality
    ) internal view returns (int56 irCumulative) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) {
                last = convert(last, time, tick);
            }
            return last.irCumulative;
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, target, tick, index, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // left boundary
            return beforeOrAt.irCumulative;
        } else if (target == atOrAfter.blockTimestamp) {
            // right boundary
            return atOrAfter.irCumulative;
        } else {
            // middle
            return
                beforeOrAt.irCumulative +
                    ((atOrAfter.irCumulative - beforeOrAt.irCumulative) / (atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp)) *
                    (target - beforeOrAt.blockTimestamp);
        }
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgos lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return irCumulative cumulative interest rate, calculated with rate * time
    function arithmeticMean(
        Observation[256] storage self,
        uint32 time,
        uint32[2] memory secondsAgos,
        int24 tick,
        uint8 index,
        uint8 cardinality
    ) internal view returns (int24) {
        int56 firstPoint = observeSingle(self, time, secondsAgos[1], tick, index, cardinality);
        int56 secondPoint = observeSingle(self, time, secondsAgos[0], tick, index, cardinality);
        return int24((firstPoint-secondPoint) / (secondsAgos[0]-secondsAgos[1]));
    }
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanOpeningsEvents {

    event Borrow(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 interestDuration,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event Trade(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address collateralToken,
        address loanToken,
        uint256 positionSize,
        uint256 borrowedAmount,
        uint256 interestRate,
        uint256 settlementDate,
        uint256 entryPrice, // one unit of collateralToken, denominated in loanToken
        uint256 entryLeverage,
        uint256 currentLeverage
    );

    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );

    struct LoanOpenData {
        bytes32 loanId;
        uint256 principal;
        uint256 collateral;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "Constants.sol";
import "SafeERC20.sol";


contract VaultController is Constants {
    using SafeERC20 for IERC20;

    event VaultDeposit(
        address indexed asset,
        address indexed from,
        uint256 amount
    );
    event VaultWithdraw(
        address indexed asset,
        address indexed to,
        uint256 amount
    );

    function vaultEtherDeposit(
        address from,
        uint256 value)
        internal
    {
        IWethERC20 _wethToken = wethToken;
        _wethToken.deposit.value(value)();

        emit VaultDeposit(
            address(_wethToken),
            from,
            value
        );
    }

    function vaultEtherWithdraw(
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IWethERC20 _wethToken = wethToken;
            uint256 balance = address(this).balance;
            if (value > balance) {
                _wethToken.withdraw(value - balance);
            }
            Address.sendValue(address(uint160(to)), value);

            emit VaultWithdraw(
                address(_wethToken),
                to,
                value
            );
        }
    }

    function vaultDeposit(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransferFrom(
                from,
                address(this),
                value
            );

            emit VaultDeposit(
                token,
                from,
                value
            );
        }
    }

    function vaultWithdraw(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransfer(
                to,
                value
            );

            emit VaultWithdraw(
                token,
                to,
                value
            );
        }
    }

    function vaultTransfer(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            if (from == address(this)) {
                IERC20(token).safeTransfer(
                    to,
                    value
                );
            } else {
                IERC20(token).safeTransferFrom(
                    from,
                    to,
                    value
                );
            }
        }
    }

    function vaultApprove(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
            IERC20(token).safeApprove(to, 0);
        }
        IERC20(token).safeApprove(to, value);
    }
}

pragma solidity ^0.5.0;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "State.sol";
import "ILoanPool.sol";
import "MathUtil.sol";
import "InterestRateEvents.sol";
import "InterestOracle.sol";
import "TickMathV1.sol";

contract InterestHandler is State, InterestRateEvents {
    using MathUtil for uint256;
    using InterestOracle for InterestOracle.Observation[256];
    // returns up to date loan interest or 0 if not applicable
    function _settleInterest(
        address pool,
        bytes32 loanId)
        internal
        returns (uint256 _loanInterestTotal)
    {
        poolLastIdx[pool] = poolInterestRateObservations[pool].write(
            poolLastIdx[pool],
            uint32(block.timestamp),
            TickMathV1.getTickAtSqrtRatio(uint160(poolLastInterestRate[pool])),
            uint8(-1),
            timeDelta
        );
        uint256[7] memory interestVals = _settleInterest2(
            pool,
            loanId,
            false
        );
        poolInterestTotal[pool] = interestVals[1];
        poolRatePerTokenStored[pool] = interestVals[2];

        if (interestVals[3] != 0) {
            poolLastInterestRate[pool] = interestVals[3];
            emit PoolInterestRateVals(
                pool,
                interestVals[0],
                interestVals[1],
                interestVals[2],
                interestVals[3]
            );
        }

        if (loanId != 0) {
            _loanInterestTotal = interestVals[5];
            loanInterestTotal[loanId] = _loanInterestTotal;
            loanRatePerTokenPaid[loanId] = interestVals[6];
            emit LoanInterestRateVals(
                loanId,
                interestVals[4],
                interestVals[5],
                interestVals[6]
            );
        }

        poolLastUpdateTime[pool] = block.timestamp;
    }

    function _getPoolPrincipal(
        address pool)
        internal
        view
        returns (uint256)
    {
        uint256[7] memory interestVals = _settleInterest2(
            pool,
            0,
            true
        );

        return interestVals[0]      // _poolPrincipalTotal
            .add(interestVals[1]);  // _poolInterestTotal
    }

    function _getLoanPrincipal(
        address pool,
        bytes32 loanId)
        internal
        view
        returns (uint256)
    {
        uint256[7] memory interestVals = _settleInterest2(
            pool,
            loanId,
            false
        );

        return interestVals[4]      // _loanPrincipalTotal
            .add(interestVals[5]);  // _loanInterestTotal
    }

    function _settleInterest2(
        address pool,
        bytes32 loanId,
        bool includeLendingFee)
        internal
        view
        returns (uint256[7] memory interestVals)
    {
        /*
            uint256[7] ->
            0: _poolPrincipalTotal,
            1: _poolInterestTotal,
            2: _poolRatePerTokenStored,
            3: _poolNextInterestRate,
            4: _loanPrincipalTotal,
            5: _loanInterestTotal,
            6: _loanRatePerTokenPaid
        */

        interestVals[0] = poolPrincipalTotal[pool]
            .add(lenderInterest[pool][loanPoolToUnderlying[pool]].principalTotal); // backwards compatibility
        interestVals[1] = poolInterestTotal[pool];

        uint256 lendingFee = interestVals[1]
            .mul(lendingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);

        uint256 _poolVariableRatePerTokenNewAmount;
        (_poolVariableRatePerTokenNewAmount, interestVals[3]) = _getRatePerTokenNewAmount(pool, interestVals[0].add(interestVals[1] - lendingFee));

        interestVals[1] = interestVals[0]
            .mul(_poolVariableRatePerTokenNewAmount)
            .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION)
            .add(interestVals[1]);

        if (includeLendingFee) {
            interestVals[1] -= lendingFee;
        }

        interestVals[2] = poolRatePerTokenStored[pool]
            .add(_poolVariableRatePerTokenNewAmount);

         if (loanId != 0 && (interestVals[4] = loans[loanId].principal) != 0) {
            interestVals[5] = interestVals[4]
                .mul(interestVals[2].sub(loanRatePerTokenPaid[loanId])) // _loanRatePerTokenUnpaid
                .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION)
                .add(loanInterestTotal[loanId]);

            interestVals[6] = interestVals[2];
        }
    }

    function _getRatePerTokenNewAmount(
        address pool,
        uint256 poolTotal)
        internal
        view
        returns (uint256 ratePerTokenNewAmount, uint256 nextInterestRate)
    {
        uint256 timeSinceUpdate = block.timestamp.sub(poolLastUpdateTime[pool]);
        uint256 benchmarkRate = TickMathV1.getSqrtRatioAtTick(poolInterestRateObservations[pool].arithmeticMean(
            uint32(block.timestamp),
            [uint32(timeSinceUpdate+twaiLength), uint32(timeSinceUpdate)],
            poolInterestRateObservations[pool][poolLastIdx[pool]].tick,
            poolLastIdx[pool],
            uint8(-1)
        ));
        if (timeSinceUpdate != 0 &&
            (nextInterestRate = ILoanPool(pool)._nextBorrowInterestRate(poolTotal, 0, benchmarkRate)) != 0) {
            ratePerTokenNewAmount = timeSinceUpdate
                .mul(nextInterestRate) // rate per year
                .mul(WEI_PERCENT_PRECISION)
                .div(31536000); // seconds in a year
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface ILoanPool {
    function tokenPrice()
        external
        view
        returns (uint256 price);

    function borrowInterestRate()
        external
        view
        returns (uint256);

    function _nextBorrowInterestRate(
        uint256 totalBorrow,
        uint256 newBorrow,
        uint256 lastInterestRate)
        external
        view
        returns (uint256 nextRate);

    function totalAssetSupply()
        external
        view
        returns (uint256);

    function assetBalanceOf(
        address _owner)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.8.0;

library MathUtil {

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

        return c;
    }

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract InterestRateEvents {

    event PoolInterestRateVals(
        address indexed pool,
        uint256 poolPrincipalTotal,
        uint256 poolInterestTotal,
        uint256 poolRatePerTokenStored,
        uint256 poolNextInterestRate
    );

    event LoanInterestRateVals(
        bytes32 indexed loanId,
        uint256 loanPrincipalTotal,
        uint256 loanInterestTotal,
        uint256 loanRatePerTokenPaid
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMathV1 {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = uint256(-1) / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) public pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "State.sol";
import "IPriceFeeds.sol";
import "SwapsEvents.sol";
import "FeesHelper.sol";
import "ISwapsImpl.sol";
import "IDexRecords.sol";
import "Flags.sol";

contract SwapsUser is State, SwapsEvents, FeesHelper, Flags {
    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes
    )
        internal
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed,
            uint256 sourceToDestSwapRate
        )
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this), // receiver
                address(this), // returnToSender
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );

        // will revert if swap size too large
        _checkSwapSize(sourceToken, sourceTokenAmountUsed);

        // will revert if disagreement found
        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool, // bypassFee
        bytes memory loanDataBytes
    ) internal returns (uint256, uint256) {
        //addrs[0]: sourceToken
        //addrs[1]: destToken
        //addrs[2]: receiver
        //addrs[3]: returnToSender
        //addrs[4]: user
        //vals[0]:  minSourceTokenAmount
        //vals[1]:  maxSourceTokenAmount
        //vals[2]:  requiredDestTokenAmount

        require(vals[0] != 0, "sourceAmount == 0");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) {
            // bypassFee
            if (vals[2] == 0) {
                // condition: vals[0] will always be used as sourceAmount
                if (loanDataBytes.length != 0 && abi.decode(loanDataBytes, (uint128)) & PAY_WITH_OOKI_FLAG != 0) {
                    tradingFee = _getTradingFeeWithOOKI(addrs[0], vals[0]);
                    if(tradingFee != 0){
                        if(abi.decode(loanDataBytes, (uint128)) & HOLD_OOKI_FLAG != 0){
                            tradingFee = _adjustForHeldBalance(tradingFee, addrs[4]);
                        }
                        IERC20(OOKI).safeTransferFrom(addrs[4], address(this), tradingFee);
                        _payTradingFee(
                            addrs[4], // user
                            loanId,
                            OOKI, // sourceToken
                            tradingFee
                        );
                    }
                    tradingFee = 0;
                } else {
                    tradingFee = _getTradingFee(vals[0]);
                    if (tradingFee != 0) {
                        if(loanDataBytes.length != 0 && abi.decode(loanDataBytes, (uint128)) & HOLD_OOKI_FLAG != 0){
                            tradingFee = _adjustForHeldBalance(tradingFee, addrs[4]);
                        }
                        _payTradingFee(
                            addrs[4], // user
                            loanId,
                            addrs[0], // sourceToken
                            tradingFee
                        );

                        vals[0] = vals[0].sub(tradingFee);
                    }
                }
            } else {
                // condition: unknown sourceAmount will be used

                if (loanDataBytes.length != 0 && abi.decode(loanDataBytes, (uint128)) & PAY_WITH_OOKI_FLAG != 0) {
                    tradingFee = _getTradingFeeWithOOKI(addrs[1], vals[2]);
                    if(tradingFee != 0){
                        if(abi.decode(loanDataBytes, (uint128)) & HOLD_OOKI_FLAG != 0){
                            tradingFee = _adjustForHeldBalance(tradingFee, addrs[4]);
                        }
                        IERC20(OOKI).safeTransferFrom(addrs[4], address(this), tradingFee);
                        _payTradingFee(
                            addrs[4], // user
                            loanId,
                            OOKI, // sourceToken
                            tradingFee
                        );
                    }
                    tradingFee = 0;
                } else {
                    tradingFee = _getTradingFee(vals[2]);

                    if (tradingFee != 0) {
                        if(loanDataBytes.length != 0 && abi.decode(loanDataBytes, (uint128)) & HOLD_OOKI_FLAG != 0){
                            tradingFee = _adjustForHeldBalance(tradingFee, addrs[4]);
                        }
                        vals[2] = vals[2].add(tradingFee);
                    }
                }


            }
        }

        if (vals[1] == 0) {
            vals[1] = vals[0];
        } else {
            require(vals[0] <= vals[1], "min greater than max");
        }
        if (loanDataBytes.length != 0 && abi.decode(loanDataBytes, (uint128)) & DEX_SELECTOR_FLAG != 0) {
            (, bytes[] memory payload) = abi.decode(
                loanDataBytes,
                (uint128, bytes[])
            );
            loanDataBytes = payload[0];
        }
        (
            destTokenAmountReceived,
            sourceTokenAmountUsed
        ) = _swapsCall_internal(addrs, vals, loanDataBytes);

        if (vals[2] == 0) {
            // there's no minimum destTokenAmount, but all of vals[0] (minSourceTokenAmount) must be spent, and amount spent can't exceed vals[0]
            require(
                sourceTokenAmountUsed == vals[0],
                "swap too large to fill"
            );

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed + tradingFee; // will never overflow
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than vals[1] (maxSourceTokenAmount)
            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(
                destTokenAmountReceived >= vals[2],
                "insufficient swap liquidity"
            );

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4], // user
                    loanId, // loanId,
                    addrs[1], // destToken
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived - tradingFee; // will never overflow
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes memory loanDataBytes
    )
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data;
        address swapImplAddress;
        bytes memory swapData;
        uint256 dexNumber = 1;
        if (loanDataBytes.length != 0) {
            (dexNumber, swapData) = abi.decode(
                loanDataBytes,
                (uint256, bytes)
            );
        }

        swapImplAddress = IDexRecords(swapsImpl).retrieveDexAddress(
            dexNumber
        );
        
        data = abi.encodeWithSelector(
            ISwapsImpl(swapImplAddress).dexSwap.selector,
            addrs[0], // sourceToken
            addrs[1], // destToken
            addrs[2], // receiverAddress
            addrs[3], // returnToSenderAddress
            vals[0], // minSourceTokenAmount
            vals[1], // maxSourceTokenAmount
            vals[2], // requiredDestTokenAmount
            swapData
        );

        bool success;
        (success, data) = swapImplAddress.delegatecall(data);

        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
        (destTokenAmountReceived, sourceTokenAmountUsed) = abi.decode(
            data,
            (uint256, uint256)
        );
    }

    function _swapsExpectedReturn(
        address trader,
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        bytes memory payload
    ) internal returns (uint256 expectedReturn) {
        
        uint256 tradingFee = _getTradingFee(sourceTokenAmount);

        address swapImplAddress;
        bytes memory dataToSend;
        uint256 dexNumber = 1;
        if (payload.length == 0) {
            dataToSend = abi.encode(sourceToken, destToken);
        } else {
            (uint128 flag, bytes[] memory payloads) = abi.decode(
                payload,
                (uint128, bytes[])
            );
            if (flag & HOLD_OOKI_FLAG != 0) {
                tradingFee = _adjustForHeldBalance(tradingFee, trader);
            }
            if (flag & PAY_WITH_OOKI_FLAG != 0) {
                tradingFee = 0;
            }
            if(flag & DEX_SELECTOR_FLAG != 0){
                (dexNumber, dataToSend) = abi.decode(payloads[0], (uint256, bytes));
            } else {
                dataToSend = abi.encode(sourceToken, destToken);
            }
        }
        if (tradingFee != 0) {
            sourceTokenAmount = sourceTokenAmount.sub(tradingFee);
        }
        
        swapImplAddress = IDexRecords(swapsImpl).retrieveDexAddress(
            dexNumber
        );

        (expectedReturn, ) = ISwapsImpl(swapImplAddress).dexAmountOutFormatted(
            dataToSend,
            sourceTokenAmount
        );
    }

    function _checkSwapSize(address tokenAddress, uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wethToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(
                    tokenAddress,
                    amount
                );
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;


interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract SwapsEvents {

    event LoanSwap(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event ExternalSwap(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "State.sol";
import "SafeERC20.sol";
import "ERC20Detailed.sol";
import "IPriceFeeds.sol";
import "VaultController.sol";
import "FeesEvents.sol";
import "MathUtil.sol";

contract FeesHelper is State, VaultController, FeesEvents {
    using SafeERC20 for IERC20;
    using MathUtil for uint256;

    function _adjustForHeldBalance(
        uint256 feeAmount,
        address user)
        internal view
        returns (uint256)
    {
        uint256 balance = ERC20Detailed(OOKI).balanceOf(user);
        if (balance > 1e25) {
            return feeAmount.mul(4).divCeil(5);
        } else if (balance > 1e24) {
            return feeAmount.mul(85).divCeil(100);
        } else if (balance > 1e23) {
            return feeAmount.mul(9).divCeil(10);
        } else {
            return feeAmount;
        }
    }

    // calculate trading fee
    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // calculate trading fee
    function _getTradingFeeWithOOKI(
        address sourceToken,
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return IPriceFeeds(priceFeeds)
            .queryReturn(
                sourceToken,
                OOKI,
                feeTokenAmount
                    .mul(tradingFeePercent)
                    .divCeil(WEI_PERCENT_PRECISION)
            );
    }

    // calculate loan origination fee
    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // calculate loan origination fee
    function _getBorrowingFeeWithOOKI(
        address sourceToken,
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return IPriceFeeds(priceFeeds)
            .queryReturn(
                sourceToken,
                OOKI,
                feeTokenAmount
                    .mul(borrowingFeePercent)
                    .divCeil(WEI_PERCENT_PRECISION)
            );
    }

    // calculate lender (interest) fee
    function _getLendingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(lendingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // settle trading fee
    function _payTradingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (tradingFee != 0) {
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .add(tradingFee);

            emit PayTradingFee(
                user,
                feeToken,
                loanId,
                tradingFee
            );
        }
    }

    // settle loan origination fee
    function _payBorrowingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (borrowingFee != 0) {
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .add(borrowingFee);

            emit PayBorrowingFee(
                user,
                feeToken,
                loanId,
                borrowingFee
            );
        }
    }

    // settle lender (interest) fee
    function _payLendingFee(
        address lender,
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (lendingFee != 0) {
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .add(lendingFee);

            vaultTransfer(
                feeToken,
                lender,
                address(this),
                lendingFee
            );

            emit PayLendingFee(
                lender,
                feeToken,
                lendingFee
            );
        }
    }
}

pragma solidity ^0.5.0;

import "IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract FeesEvents {

    enum FeeType {
        Lending,
        Trading,
        Borrowing,
        SettleInterest
    }

    event PayLendingFee(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    event SettleFeeRewardForInterestExpense(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PayTradingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PayBorrowingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    // DEPRECATED
    event EarnReward(
        address indexed receiver,
        bytes32 indexed loanId,
        FeeType indexed feeType,
        address token,
        uint256 amount
    );
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.17;

interface ISwapsImpl {
    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata payload
    )
        external
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount
    ) external view returns (uint256);

    function dexAmountOut(bytes calldata route, uint256 amountIn)
        external
        returns (uint256 amountOut, address midToken);

    function dexAmountOutFormatted(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function dexAmountIn(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function dexAmountInFormatted(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function setSwapApprovals(address[] calldata tokens) external;
	
    function revokeApprovals(address[] calldata tokens) external;
}

pragma solidity >=0.5.17;

interface IDexRecords {
    function retrieveDexAddress(uint256 dexNumber)
        external
        view
        returns (address);

    function setDexID(address dexAddress) external;
	
    function setDexID(uint256 dexID, address dexAddress) external;
	
    function getDexCount() external view returns(uint256);
}

pragma solidity >=0.5.17 <0.9.0;

contract Flags {
    uint128 public constant DEX_SELECTOR_FLAG = 2; // base-2: 10
    uint128 public constant DELEGATE_FLAG = 4;
    uint128 public constant PAY_WITH_OOKI_FLAG = 8;
    uint128 public constant HOLD_OOKI_FLAG = 1;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "Ownable.sol";


contract PausableGuardian is Ownable {

    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable {
        require(!_isPaused(msg.sig), "paused");
        _;
    }

    modifier onlyGuardian {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        _;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public onlyGuardian {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 1)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public onlyGuardian {
        // only DAO can unpause, and adding guardian temporarily
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 0)
        }
    }

    function changeGuardian(address newGuardian) public onlyGuardian {
        assembly {
            sstore(Pausable_GuardianAddress, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        assembly {
            guardian := sload(Pausable_GuardianAddress)
        }
    }

    function pause(bytes4 [] calldata sig)
        external
        onlyGuardian
    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionPause(sig[i]);
        }
    }

    function unpause(bytes4 [] calldata sig)
        external
        onlyGuardian
    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionUnPause(sig[i]);
        }
    }
}