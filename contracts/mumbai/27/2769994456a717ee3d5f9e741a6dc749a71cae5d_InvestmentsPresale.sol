// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./InvestmentsLiquidityLock.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
}

contract InvestmentsPresale {
    using SafeMath for uint256;

    IUniswapV2Router02 private constant QuickSwapRouter =
    IUniswapV2Router02(address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff));

    address payable internal FactoryAddress; // address that creates the presale contracts
    address payable public DevAddress; // address where dev fees will be transferred to
    address public LiqLockAddress; // address where LP tokens will be locked

    IERC20 public token; // token that will be sold
    address payable public presaleCreatorAddress; // address where percentage of invested wei will be transferred to

    mapping(address => uint256) public investments; // total wei invested per address
    //mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => bool) public claimed; // if true, it means investor already claimed the tokens or got a refund

    uint256 private DevFeePercentage; // dev fee to support the development of Investments
    uint256 private MinDevFeeInWei; // minimum fixed dev fee to support the development of Investments
    uint256 public Id; // used for fetching presale without referencing its address

    uint256 public totalInvestorsCount; // total investors count
    uint256 public presaleCreatorClaimWei; // wei to transfer to presale creator per investor claim
    uint256 public presaleCreatorClaimTime; // time when presale creator can collect funds raise
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public uniListingPriceInWei; // token price when listed in Uniswap
    uint256 public uniLiquidityAddingTime; // time when adding of liquidity in uniswap starts, investors can claim their tokens afterwards
    uint256 public uniLPTokensLockDurationInDays; // how many days after the liquity is added the presale creator can unlock the LP tokens
    uint256 public uniLiquidityPercentageAllocation; // how many percentage of the total invested wei that will be added as liquidity

    bool public uniLiquidityAdded = false; // if true, liquidity is added in Uniswap and lp tokens are locked
    //bool public onlyWhitelistedAddressesAllowed = true; // if true, only whitelisted addresses can invest
    bool public DevFeesExempted = false; // if true, presale will be exempted from dev fees
    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens

    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkDiscord;
    bytes32 public linkWebsite;

    event invested(string investStatus);
    event liquidityAdded(string liquidityStatus);
    event tokenClaim(string claimStatus);
    event refunded(string refundStatus);
    // event cancelAndTransferTokens(string cancelAndTransferStatus);
    event collectFunds(string status);

    constructor(address _FactoryAddress, address _DevAddress) public {
        require(_FactoryAddress != address(0));
        require(_DevAddress != address(0));

        FactoryAddress = payable(_FactoryAddress);
        DevAddress = payable(_DevAddress);
    }

    modifier onlyDev() {
        require(FactoryAddress == msg.sender || DevAddress == msg.sender);
        _;
    }

    modifier onlyFactory() {
        require(FactoryAddress == msg.sender);
        _;
    }

    modifier onlyPresaleCreatorOrFactory() {
        require(
            presaleCreatorAddress == msg.sender || FactoryAddress == msg.sender,
            "Not presale creator or factory"
        );
        _;
    }

    modifier onlyPresaleCreator() {
        require(presaleCreatorAddress == msg.sender, "Not presale creator");
        _;
    }
/*
    modifier whitelistedAddressOnly() {
        require(
            !onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }
*/
    modifier presaleIsNotCancelled() {
        require(!presaleCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier notYetClaimedOrRefunded() {
        require(!claimed[msg.sender], "Already claimed or refunded");
        _;
    }

    function setAddressInfo(
        address _presaleCreator,
        address _tokenAddress
    ) external onlyFactory {
        require(_presaleCreator != address(0));
        require(_tokenAddress != address(0));

        presaleCreatorAddress = payable(_presaleCreator);
        token = IERC20(_tokenAddress);
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _totalTokensinPool,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlyFactory {
        require(_totalTokens > 0);
        require(_tokenPriceInWei > 0);
        require(_openTime > 0);
        require(_closeTime > 0);
        require(_hardCapInWei > 0);

        // Hard cap > (token amount * token price)
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei));
        // Soft cap > to hard cap
        require(_softCapInWei <= _hardCapInWei);
        //  Min. wei investment > max. wei investment
        require(_minInvestInWei <= _maxInvestInWei);
        // Open time >= close time
        require(_openTime < _closeTime);

        totalTokens = _totalTokensinPool;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function setUniswapInfo(
        uint256 _uniListingPriceInWei,
        uint256 _uniLiquidityAddingTime,
        uint256 _uniLPTokensLockDurationInDays,
        uint256 _uniLiquidityPercentageAllocation
    ) external onlyFactory {
        require(_uniListingPriceInWei > 0);
        require(_uniLiquidityAddingTime > 0);
        require(_uniLPTokensLockDurationInDays > 0);
        require(_uniLiquidityPercentageAllocation > 0);

        require(closeTime > 0);
        // Listing time < close time
        require(_uniLiquidityAddingTime >= closeTime);

        uniListingPriceInWei = _uniListingPriceInWei;
        uniLiquidityAddingTime = _uniLiquidityAddingTime;
        uniLPTokensLockDurationInDays = _uniLPTokensLockDurationInDays;
        uniLiquidityPercentageAllocation = _uniLiquidityPercentageAllocation;
    }
/*
    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkDiscord,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite
    ) external onlyPresaleCreatorOrFactory {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkDiscord = _linkDiscord;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
    }
*/
    function setInfo(
        address _LiqLockAddress,
        //uint256 _DevFeePercentage,
        //uint256 _MinDevFeeInWei,
        uint256 _Id
    ) external onlyDev {
        LiqLockAddress = _LiqLockAddress;
        //DevFeePercentage = _DevFeePercentage;
        //MinDevFeeInWei = _MinDevFeeInWei;
        Id = _Id;
    }

    function editInfoPresaleDev(
        uint256 _openTime,
        uint256 _closeTime,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _uniLiquidityAddingTime,
        uint256 _uniLPTokensLockDurationInDays,
        uint256 _uniLiquidityPercentageAllocation
    ) external onlyPresaleCreator {
        require(block.timestamp < openTime, "Presale has already started");
        require(_closeTime > _openTime, "Close time cannot be less than open time");
        require(_uniLiquidityAddingTime >= _closeTime, "Liquidity adding time cannot be less than close time");
        require(_minInvestInWei <= _maxInvestInWei, "Max invest should be greater than min invest");
        require(_uniLPTokensLockDurationInDays > 0, "LP Tokens Lock Duration should be greater than 0");
        require(_uniLiquidityPercentageAllocation > 0, "Liquidity percentage allocation should be greater than 0");

        InvestmentsLiquidityLock liqlockaddy = InvestmentsLiquidityLock(address(LiqLockAddress));

        openTime = _openTime;
        closeTime = _closeTime;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        uniLiquidityAddingTime = _uniLiquidityAddingTime;
        uniLPTokensLockDurationInDays = _uniLPTokensLockDurationInDays;
        liqlockaddy.updateReleaseTimePresale(_uniLPTokensLockDurationInDays);
        uniLiquidityPercentageAllocation = _uniLiquidityPercentageAllocation;
    }

    /*function setDevFeesExempted(bool _DevFeesExempted)
    external
    onlyDev
    {
        DevFeesExempted = _DevFeesExempted;
    }*/
/*
    function setOnlyWhitelistedAddressesAllowed(bool _onlyWhitelistedAddressesAllowed)
    external
    onlyPresaleCreatorOrFactory
    {
        onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
    }

    function addwhitelistedAddresses(address[] calldata _whitelistedAddresses)
    external
    onlyPresaleCreatorOrFactory
    {
        onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }
*/
    function getTokenAmount(uint256 _weiAmount)
    internal
    view
    returns (uint256)
    {
        return _weiAmount.mul(1e18).div(tokenPriceInWei);
    }

    function invest()
    public
    payable
    //whitelistedAddressOnly
    presaleIsNotCancelled
    {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value <= tokensLeft.mul(tokenPriceInWei));
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(totalInvestmentInWei >= minInvestInWei, "Min investment not reached");
        require(totalInvestmentInWei <= maxInvestInWei, "Max investment reached");

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));

        emit invested("Invested Successfully");
    }

    receive() external payable {
        invest();
    }
    // add liquidity

    function addLiquidityAndLockLPTokens() external presaleIsNotCancelled {
        require(totalCollectedWei > 0);
        require(totalCollectedWei >= softCapInWei, "Project failed. Soft Cap not reached");
        require(!uniLiquidityAdded, "Liquidity already added");
        require(
            //!onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender] || 
            msg.sender == presaleCreatorAddress,
            "Not presale creator"
        );

        if (totalCollectedWei >= hardCapInWei && block.timestamp < uniLiquidityAddingTime) {
            require(msg.sender == presaleCreatorAddress, "Not presale creator");
        } else if (block.timestamp >= uniLiquidityAddingTime) {
            require(
                msg.sender == presaleCreatorAddress || investments[msg.sender] > 0,
                "Not presale creator or investor"
            );
            require(totalCollectedWei >= softCapInWei, "Soft cap not reached");
        } else {
            revert("Liquidity cannot be added yet");
        }

        uniLiquidityAdded = true;

        uint256 finalTotalCollectedWei = totalCollectedWei;
        // uint256 DevFeeInWei;
        /*if (!DevFeesExempted) {
            uint256 pctDevFee = finalTotalCollectedWei.mul(DevFeePercentage).div(100);
            DevFeeInWei = MinDevFeeInWei > pctDevFee ? pctDevFee : MinDevFeeInWei;
        }

        if (DevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(DevFeeInWei);
            DevAddress.transfer(DevFeeInWei);
        }*/

        uint256 liqPoolEthAmount = finalTotalCollectedWei.mul(uniLiquidityPercentageAllocation).div(100);
        uint256 liqPoolTokenAmount = liqPoolEthAmount.mul(1e18).div(uniListingPriceInWei);

        token.approve(address(QuickSwapRouter), liqPoolTokenAmount);

        QuickSwapRouter.addLiquidityETH{value : liqPoolEthAmount}(
            address(token),
            liqPoolTokenAmount,
            0,
            0,
            LiqLockAddress,
            block.timestamp.add(15 minutes)
        );

        uint256 unsoldTokensAmount = token.balanceOf(address(this)).sub(getTokenAmount(totalCollectedWei));
        if (unsoldTokensAmount > 0) {
            token.transfer(0x000000000000000000000000000000000000dEaD, unsoldTokensAmount);
        }

        presaleCreatorClaimWei = address(this).balance.mul(1e18).div(totalInvestorsCount.mul(1e18));
        presaleCreatorClaimTime = block.timestamp + 5 minutes;

        emit liquidityAdded("Liquidity added successfully");
    }

    function claimTokens()
    external
    //whitelistedAddressOnly
    presaleIsNotCancelled
    investorOnly
    notYetClaimedOrRefunded
    {
        require(uniLiquidityAdded, "Liquidity not yet added");

        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        token.transfer(msg.sender, getTokenAmount(investments[msg.sender]));

        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 funds = presaleCreatorClaimWei > balance ? balance : presaleCreatorClaimWei;
            presaleCreatorAddress.transfer(funds);
        }

        emit tokenClaim("Tokens claimed successfully");
    }

    function getRefund()
    external
    //whitelistedAddressOnly
    investorOnly
    notYetClaimedOrRefunded
    {
        if (!presaleCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
        }

        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance =  address(this).balance;
        require(presaleBalance > 0, "This contract does not have any balance");

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
        
        investments[msg.sender] = 0;

        totalCollectedWei = totalCollectedWei.sub(investment);
        totalInvestorsCount = totalInvestorsCount.sub(1);

        emit refunded("Refunded successfully");
    }

    /* function cancelAndTransferTokensToPresaleCreator() external {
        if (!uniLiquidityAdded && presaleCreatorAddress != msg.sender && DevAddress != msg.sender) {
            revert();
        }
        if (uniLiquidityAdded && DevAddress != msg.sender) {
            revert();
        }

        require(!presaleCancelled);
        presaleCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(presaleCreatorAddress, balance);
        }

        emit cancelAndTransferTokens("Presale cancelled and Tokens transferred successfully");
    } */

    function collectFundsRaised() onlyPresaleCreator external {
        require(uniLiquidityAdded);
        require(!presaleCancelled);
        require(block.timestamp >= presaleCreatorClaimTime, "Wait until presale creator claim time is reached");

        if (address(this).balance > 0) {
            presaleCreatorAddress.transfer(address(this).balance);
        }

        emit collectFunds("Funds collected successfully");
    }

    function checkStatus() external view returns (bool) {
        if(block.timestamp > closeTime || address(this).balance >= hardCapInWei) {
            return true;
        }
        else {
            return false;
        }
    }
}