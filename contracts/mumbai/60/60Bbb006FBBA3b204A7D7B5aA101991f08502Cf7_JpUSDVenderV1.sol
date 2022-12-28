/* ---- Structure of the this contract ----
- interfaces
- JpUSDVenderV1 contract
    - events
    - basic variables and constructor
    - return/update min and max amount
    - price feed erc20 interface
    - PURCHASING AND REDEEMING
        - purchase with native token
        - purchase with native token - core functions
        - purchase with ERC20 token
        - purchase with ERC20 token - core functions
        - redeem JPYC token with jpUSD token
        - redeem JPYC token with jpUSD token - core functions
    - withdraw & ownership, pause
    - whitelist
    - native token on/off
*/
// 
// Memo: todos when change chain
// - change the price feed: 
//      - add new args in constructor, new priceFeedJpyUsd & new priceFeedNativeUsd addresses, 
//      - use `addPriceFeed(_jpyusdAddress)` to add new price feed
//      - change owner if necessary
// Pricefeed list: 
// JPY / USD (mainnet): 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3
// ETH / USD (mainnet): 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 -> Native token
// USDC / USD (mainnet): 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6
// DAI / USD (mainnet): 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
// JPY / USD (Matic): 0xd647a6fc9bc6402301583c91decc5989d8bc382d decimals:8
// Matic / USD (Matic): 0xab594600376ec9fd91f8e885dadf0ce036862de0 decimals:8 -> Native token
// USDC / USD (Matic): 0xfe4a8cc5b5b2366c1b58bea3858e81843581b2f7 decimals:8 
// ETH / USD (Matic): 0xf9680d99d6c9589e2a93a78a04a279e509205945 decimals:8
// JPY / USD (Matic): 0xd647a6fc9bc6402301583c91decc5989d8bc382d decimals:8
// ETH / USD (Goerli): 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e decimals:8
// JPY / USD (Goerli): 0x295b398c95cEB896aFA18F25d0c6431Fd17b1431 decimals:8
// MATIC / USD (Mumbai): 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada decimals: 8 -> Native token


// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";

// ---- interfaces ----
// ERC20 interface
interface IERC20 {
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


// Chainlink interface
interface AggregatorV3Interface {
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
    
    function decimals() external view returns (uint8);
}


// ---- CORE CONTRACT ----
/// @title Contract for selling and buying jpUSD
/// @notice This contract is not supposed to hold or mint any tokens. It is just a contract in the middle. 
contract JpUSDVenderV1 is Pausable {

    // ---- events ----
    event BoughtWithNative(uint256 jpusdAmount, uint256 nativeAmount, address indexed buyer, uint256 fee);
    event BoughtWithERC20(uint256 jpusdAmount, uint256 ERC20, address indexed buyer, address indexed tokenAddress, uint256 fee); // with ERC20 token address
    event RedeemJpyc(uint256 jpycAmount, uint256 jpusdAmount, address indexed redeemer, uint256 fee);
    event AddPriceFeed(address indexed tokenAddress, address chainlinkPriceFeed);
    event TurnOffPriceFeed(address indexed tokenAddress); 
    event AddToWhitelist(address indexed whitelistedAddress); 
    event RemoveFromWhitelist(address indexed unwhiteliestedAddress); 
    event ChangeJpycOwner(address owner);
    event ChangeSupplier(address newSupplier);
    event ChangeReceiver(address newReceiver);

    // supplier changes fees
    event ChangeBuyingFee(uint256 buyingBasisPointsRate);
    event ChangeRedeemingFee(uint256 redeemingBasisPointsRate);

    // native token on/off
    event ToggleNativeTokenOn(bool nativeTokenOn);


    // ---- basic variables and constructor ----
    // chainlink decimals' constant variable
    uint256 constant CHAINLINK_DECIMALS = 1e8;

    // supplier, receiver & owner
    address payable supplier;
    address payable receiver;
    address owner;

    // fee(basis point rate) 
    // if fee is necessary
    uint256 public buyingBasisPointsRate; // feeRate (in percentage) = basisPointsRate / 10000
    uint256 public redeemingBasisPointsRate; // feeRate (in percentage) = basisPointsRate / 10000
    
    // jpyc
    address public immutable jpyc_address;
    uint256 internal immutable jpyc_decimals; 
    
    // jpusd
    address public immutable jpusd_address; 
    uint256 internal immutable jpusd_decimals;  
    
    // max and min amount for jpyc
    uint256 internal minimumPurchaseAmount;
    uint256 internal maximumPurchaseAmount;
    
    // chainlink interfaces: native & JPYUSD
    AggregatorV3Interface internal priceFeedNativeUsd;
    AggregatorV3Interface internal priceFeedJpyUsd;

    // jpyc&jpusd interface
    IERC20 internal jpycInterface;
    IERC20 internal jpusdInterface;

    // chainlink interface for an arbitrary ERC20 tokens
    // only when a token is registered using addPriceFeed function, then it can be used to purchase jpUSD
    mapping(address => AggregatorV3Interface) internal priceFeedERC20Usd;
    mapping(address => bool) internal priceFeedRegistered;
    
    // whitelist related
    mapping(address => bool) internal whitelistedAdresses;
    bool internal whitelistOn;

    // value shows native token purchase is on/off
    bool internal nativeTokenOn;

    // @dev Initialize the contract with parameters and predetermined values
    // @notice Owner(_contractOwner) is the most import role in this contract. Make sure to set it right
    // @param _jpyc_address and jpusd_address The token addresses
    // @param _tokenSupplier and _tokenReceiver supplier and receiver of jpUSD vender v1
    // @param _contractOwner The owner of the contract who manages the onlyOwner functions
    constructor(address _jpyc_address, address _jpusd_address, address payable _tokenSupplier, address payable _tokenReceiver, address _contractOwner) {
        supplier = _tokenSupplier;
        receiver = _tokenReceiver;
        owner = _contractOwner;
        jpyc_address = _jpyc_address;
        jpusd_address = _jpusd_address;
        jpycInterface = IERC20(_jpyc_address);
        jpyc_decimals = IERC20(_jpyc_address).decimals();
        jpusdInterface = IERC20(_jpusd_address);
        jpusd_decimals = IERC20(_jpusd_address).decimals();
        minimumPurchaseAmount = 1000e18; // min jpyc amount as 1000 jpyc
        maximumPurchaseAmount = 200000e18; // max jpyc amount as 200000 jpyc

        priceFeedJpyUsd = AggregatorV3Interface(
            // TODO: CHANGE this according to the situation
            // 0x766cdDC69f7Da70dE18e45c7009EDa00E2F68b9f // mumbai jpyusd mock
            0x295b398c95cEB896aFA18F25d0c6431Fd17b1431 // Georli
            // 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3 // mainnet (change to this if you want to run the test on mainnet fork)
            // 0xD647a6fC9BC6402301583C91decC5989d8Bc382D // polygon mainnet
        );
        
        priceFeedNativeUsd = AggregatorV3Interface(
            // TODO: CHANGE this according to the situation
            // 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada // mumbai matic
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e // Georli
            // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // mainnet (change to this if you want to run the test on mainnet fork)
            // 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0 // polygon mainnet
        );

        // emits events for the constructor
        emit ChangeBuyingFee(0);
        emit ChangeRedeemingFee(0);
        emit ToggleNativeTokenOn(false); // used `false` instead of nativeTokenOn
        emit ChangeSupplier(_tokenSupplier);
        emit ChangeReceiver(_tokenReceiver);
        emit ChangeJpycOwner(_contractOwner);
    }

    // change buying basis fee rate
    function setBuyingFeeRate(uint256 _newBasisPoints) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(_newBasisPoints <= 300, "exceed maximum amount"); // maximun is 3% (300 / 10000)
        buyingBasisPointsRate = _newBasisPoints; // basisPointsRate / 10,000  e.g. 30 -> 0.3%
        emit ChangeBuyingFee(_newBasisPoints);
    }

    // change redeeming basis fee rate 
    function setRedeemingFeeRate(uint256 _newBasisPoints) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(_newBasisPoints <= 300, "exceed maximum amount"); // maximun is 3%
        redeemingBasisPointsRate = _newBasisPoints; // basisPointsRate / 10,000  e.g. 30 -> 0.3%
        emit ChangeRedeemingFee(_newBasisPoints);
    }


    // ---- return/update min and max amount ----
    /*
     * @return The minimum purchasing amount per transaction.
     */
    function showMinimumPurchaseAmount()
        external
        view
        returns (uint256 _minimumPurchaseAmount)
    {
        return minimumPurchaseAmount;
    }

    /*
     * @return The maximum purchasing amount per transaction.
     */
    function showMaximumPurchaseAmount()
        external
        view
        returns (uint256 _maximumPurchaseAmount)
    {
        return maximumPurchaseAmount;
    }

    /*
     * @param _newMinimumPurchaseAmount The new min amount of JPYC
     * @dev Updates the minimum purchase amount per transaction
     * @notice Initial min purchasable amount is set as 1000e18
     */
    function updateMinimumPurchaseAmount(uint256 _newMinimumPurchaseAmount)
        external
        onlyOwner
    {
        minimumPurchaseAmount = _newMinimumPurchaseAmount;
    }

    /**
     * @param _newMaximumPurchaseAmount The new max amount of JPYC
     * @dev Updates the maximum purchase amount
     * @notice Initial max purchasable amount is set as 200000e18
     */
    function updateMaximumPurchaseAmount(uint256 _newMaximumPurchaseAmount)
        external
        onlyOwner
    {
        maximumPurchaseAmount = _newMaximumPurchaseAmount;
    }


    // ---- price feed erc20 interface ----
    /*
     * @param Token address
     * @return The price feed contract interface of `_tokenAddress` related to USD
     */
    function getPriceFeedContract(address _tokenAddress)
        external
        view
        returns (AggregatorV3Interface contractAddress)
    {
        return priceFeedERC20Usd[_tokenAddress];
    }

    /*
     * @dev Add the `_chainlinkPriceFeed` interface of a certain `_tokenAddress` with the token price of USD e.g. USDC / USD
     * @param _tokenAddress Token address
     * @param _chainlinkPriceFeed Chainlinnk price feed address
     */
    function addPriceFeed(address _tokenAddress, address _chainlinkPriceFeed) 
        external
        onlyOwner
    {
        priceFeedERC20Usd[_tokenAddress] = AggregatorV3Interface(_chainlinkPriceFeed);
        priceFeedRegistered[_tokenAddress] = true;
        emit AddPriceFeed(_tokenAddress, _chainlinkPriceFeed);
    }

    // turn off the price feed
    function turnOffPriceFeed(address _tokenAddress) external onlyOwner { 
        priceFeedRegistered[_tokenAddress] = false;
        emit TurnOffPriceFeed(_tokenAddress);
    }

    // show the state of token registration
    function tokenIsRegistered(address _tokenAddress) public view returns(bool){
        return priceFeedRegistered[_tokenAddress];
    }

    // ---- PURCHASING AND REDEEMING ----
    // get buying fee from total _amount
    function getBuyingFee(uint256 _amount) public view returns(uint256){
        return _amount * buyingBasisPointsRate / 10000;
    }

    // get redeeming fee from total _amount
    function getRedeemingFee(uint256 _amount) public view returns(uint256){
        return _amount * redeemingBasisPointsRate / 10000;
    }

    // get total amount(with fee) from _amount without fee
    function getAmountIncludingBuyingFee(uint256 _amount) public view returns(uint256) {
        return _amount * 10000 / (10000 - buyingBasisPointsRate);
    }

    // get total amount(with fee) from _amount without fee
    function getAmountIncludingRedeemingFee(uint256 _amount) public view returns(uint256) {
        return _amount * 10000 / (10000 - redeemingBasisPointsRate);
    }

    // check if the amount is in limited range
    function checkAmountRange(uint256 _jpycAmount) internal view {
        require(minimumPurchaseAmount <= _jpycAmount && _jpycAmount <= maximumPurchaseAmount, "amount must be within range"); 
    }

    // ---- purchase with native token ----
    /*
     * @return The current Native token price in USD.
     */
    function getLatestNativeUsdPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedNativeUsd.latestRoundData();
        return price;
    }

    /*
     * @param `_jpusdAmount` The jpUSD amount to be calculated
     * @return The required `nativeAmount` for the `_usdAmount` you input.
     * @notice native/usd price decimal is considered as 8 here. ETH/USD and MATIC/USD are both 8.
     */
    function getNativeAmountFromJpusd(uint256 _jpusdAmount)
        public
        view
        returns (uint256 nativeAmount)
    {
        return nativeAmount =(_jpusdAmount * CHAINLINK_DECIMALS) / uint256(getLatestNativeUsdPrice());
    }

    /*
     * @param  `_nativeAmount` The native amount to be calculated
     * @return The `jpUSDAmount` equals to `_nativeAmount` you input.
     */
    function getJpusdAmountFromNative(uint256 _nativeAmount)
        public
        view
        returns (uint256 usdAmount)
    {
        return usdAmount =(uint256(getLatestNativeUsdPrice()) * _nativeAmount) / CHAINLINK_DECIMALS;
    }


    // ---- purchase with native token - core functions ----
    /*
     * @param _jpusdAMount The amount of jpusd user wants to purchase.
     * @param _amountOutMax The largest amount of native token user wants to pay
     * @dev Receives exact amount of jpUSD (_jpusdAmount) for as less Native token as possible, using Chainlink pricefeed. 
     * @notice User can set parameter: _amountOutMax = nativeAmount * 10000 / (10000 - buyingBasisPointsRate) , if msg.value is more than this, the transaction will fail. 
     */
    function purchaseExactJpusdWithNative(
        uint256 _jpusdAmount,
        uint256 _amountOutMax
    ) external whenNotPaused isWhitelisted(msg.sender) payable {
        // check if native token purchase is on
        require(nativeTokenOn, "purchase by native token is off");
        uint256 jpycAmount = getJpycAmountFromJpusd(_jpusdAmount);
        // 1. checking purchasing limit by user's receiving jpyc value
        checkAmountRange(jpycAmount);
        // get native amount before fee calculation
        uint256 nativeAmount = getNativeAmountFromJpusd(_jpusdAmount);
        // make nativeAmount include fee if fee exists
        uint256 fee;
        if (buyingBasisPointsRate > 0) {
            nativeAmount = getAmountIncludingBuyingFee(nativeAmount);
            fee = nativeAmount - getNativeAmountFromJpusd(_jpusdAmount);
        }
        // 2. check slippage
        require(nativeAmount <= _amountOutMax, "excessive slippage amount");
        // 3. user sent enough native amount
        require(msg.value >= nativeAmount, "msg.value must be greater than calculated native token amount");
        // 4. enough approved amount from supplier
        require(_jpusdAmount <= jpusdInterface.allowance(supplier, address(this)), "insufficient allowance of jpUSD");
        // token transfering action. send token to receiver
        receiver.transfer(nativeAmount); 
        jpusdInterface.transferFrom(supplier, msg.sender, _jpusdAmount);

        // return native token to user if necessaary
        if (msg.value > nativeAmount)
            payable(msg.sender).transfer(msg.value - nativeAmount);
        // event
        emit BoughtWithNative(_jpusdAmount, nativeAmount, msg.sender, fee);
    }

    /*
     * @param _amountInMin The least amount of jpUSD token user wants to receive.
     * @dev Receives as many jpUSD as possible for exact msg.value, using Chinlink price feed.
     * @notice you can set parameter: calculate _amountInMin using jpusdAmountFromNative. If jpUSD is less than this,  the transaction will fail. The calculation should consider the fee if fee exists.
     */
    function purchaseJpusdWithExactNative(uint256 _amountInMin)
        external
        whenNotPaused
        isWhitelisted(msg.sender)
        payable
    {
        // check if native token purchase is on
        require(nativeTokenOn, "purchase by native token is off");
        // make nativeAmount exclude fee if fee exists
        uint256 fee;
        uint256 nativeAmount = msg.value;
        if (buyingBasisPointsRate > 0) {
            fee = getBuyingFee(msg.value);
            nativeAmount = nativeAmount - fee;
        }
        // calculate jpyc amount from: exact native token - fee
        uint256 jpusdAmountFromNative = getJpusdAmountFromNative(nativeAmount);
        uint256 jpycAmount = getJpycAmountFromJpusd(jpusdAmountFromNative);
        // 1.checking purchasing limit by user's receiving jpyc value
        checkAmountRange(jpycAmount);
        // 2. check slippage
        require(jpusdAmountFromNative >= _amountInMin, "excessive slippage amount");
        // 3. enough approved amount from supplier
        require(jpusdAmountFromNative <= jpusdInterface.allowance(supplier, address(this)), "insufficient allowance of jpUSD");
        // token transfering action
        receiver.transfer(msg.value);
        jpusdInterface.transferFrom(supplier, msg.sender, jpusdAmountFromNative);
        // event
        emit BoughtWithNative(jpusdAmountFromNative, msg.value, msg.sender, fee);
    }


    // ---- purchase with ERC20 token ----
    /*
     * @return The current price feed of the token of `_tokenAddress`
     */
    function getLatestERC20UsdPrice(address _tokenAddress)
        public
        view
        returns (int256)
    {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedERC20Usd[_tokenAddress].latestRoundData();
        return price;
    }

    /*
     * @return The current decimals of `_tokenAddress` price feed
     */
    function getERC20UsdPriceDecimals(address _tokenAddress)
        public
        view
        returns (uint8)
    {
        return priceFeedERC20Usd[_tokenAddress].decimals();
    }

    /*
     * @return The required `erc20Amount` for the `_jpusdAmount` you input.
     * @dev make sure that _jpusdAmount and jpusd has the same decimals 18
     */
    function getERC20AmountFromJpusd(
        uint256 _jpusdAmount,
        address _tokenAddress
    ) public view returns (uint256 erc20Amount) {
        return
            erc20Amount = ((_jpusdAmount / uint256(getLatestERC20UsdPrice(_tokenAddress))) *
                    (10 **(uint256(getERC20UsdPriceDecimals(_tokenAddress) + IERC20(_tokenAddress).decimals())))) / 1e18;
    }

    /*
     * @return The `jpusdAmount` calculated from `_erc20Amount` you input.
     */
    function getJpusdAmountFromERC20(uint256 _erc20Amount, address _tokenAddress)
        public
        view
        returns (uint256 jpusdAmount)
    {
        return
            jpusdAmount = ((_erc20Amount * uint256(getLatestERC20UsdPrice(_tokenAddress))) / 
                (10**uint256(getERC20UsdPriceDecimals(_tokenAddress)))) * 10**(18 - IERC20(_tokenAddress).decimals());
    }

    // ---- purchase with ERC20 token - core functions ----
    /*
     * @param _jpusdAmount The amount of jpUSD user wants to buy
     * @param _amountOutMax The slippage
     * @param _tokenAddress The erc20 token address
     * @dev Receives exact amount of jpUSD (_jpusdAmount) for ERC20 within the slippage(_amountOutMax erc20), using the chainlink pricefeed.
     * @notice User can set _amountOutMax: erc20Amount * 10000 / (10000 - buyingBasisPointsRate). When it is more than this value, it will fail.
     */
    function purchaseExactJpusdWithERC20(
        uint256 _jpusdAmount,
        uint256 _amountOutMax,
        address _tokenAddress
    ) external whenNotPaused isWhitelisted(msg.sender) {
        // 1. check price feed
        require(priceFeedRegistered[_tokenAddress], "token pricefeed is not registered or turned off"); 
        // calculate JPYC amount from jpUSD
        uint256 jpycAmount = getJpycAmountFromJpusd(_jpusdAmount); 
        // 2.checking purchasing limit by user's receiving jpyc value
        checkAmountRange(jpycAmount);
        // calculate erc20 amount by exact jpUSD
        uint256 erc20Amount = getERC20AmountFromJpusd(_jpusdAmount, _tokenAddress);
        // fee
        uint256 fee;
        if (buyingBasisPointsRate > 0) {
            // make erc20Amount include fee if it exists
            erc20Amount = getAmountIncludingBuyingFee(erc20Amount);
            fee = erc20Amount - getERC20AmountFromJpusd(_jpusdAmount, _tokenAddress);
        }
        // 3. check slippage 
        require(erc20Amount <= _amountOutMax, "excessive slippage amount");
        // 4. check if user's erc20 balance is enough
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= erc20Amount, "insufficient balance of ERC20 token");
        // 5. check if supplier's approved jpUSD token is enough
        require(_jpusdAmount <= jpusdInterface.allowance(supplier, address(this)), "insufficient allowance of jpUSD");
        // transfer tokens
        IERC20(_tokenAddress).transferFrom(msg.sender, receiver, erc20Amount);
        jpusdInterface.transferFrom(supplier, msg.sender, _jpusdAmount);
        // event
        emit BoughtWithERC20(_jpusdAmount, erc20Amount, msg.sender, _tokenAddress, fee);
    }

    /*
     * @param _erc20Amount The erc20 amount user want to pay
     * @param _amountInMin The jpUSD slippage
     * @param _tokenAddress The erc20 token address
     * @dev Receives jpUSD for an exact _erc20Amount within the slippage(_amountInMin jpUSD), using the chinlink price feed.
     * @notice To get jpUSD token as much as possible by paying an exact amount of erc20 token
     * You can set the _amountInMin = _erc20Amount - fee as slipapge. If the amount is less than this, it will fail.
     */
    function purchaseJpusdWithExactERC20(
        uint256 _erc20Amount,
        uint256 _amountInMin,
        address _tokenAddress
    ) external whenNotPaused isWhitelisted(msg.sender) {
        // 1. check price feed
        require(priceFeedRegistered[_tokenAddress], "token pricefeed is not registered or turned off");
        // fee
        uint256 fee;
        uint256 erc20Amount = _erc20Amount;
        if (buyingBasisPointsRate > 0) {
            fee = getBuyingFee(_erc20Amount);
            // make erc20Amount exclude fee if it exists
            erc20Amount = _erc20Amount - fee;
        }
        // 2.check purchasing limit by user's receiving jpyc value
        uint256 jpusdAmountFromERC20 = getJpusdAmountFromERC20(erc20Amount, _tokenAddress);
        uint256 jpycAmount = getJpycAmountFromJpusd(jpusdAmountFromERC20); 
        checkAmountRange(jpycAmount);
        // 3. check slippage
        require(jpusdAmountFromERC20 >= _amountInMin, "excessive slippage amount");
        // 4. check if user has enough erc20 token
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _erc20Amount, "insufficient balance of ERC20 token");
        // 5. check if supplier has approved enough jpUSD token
        require(jpusdAmountFromERC20 <= jpusdInterface.allowance(supplier, address(this)), "insufficient allowance of jpUSD");
        // transfer token
        IERC20(_tokenAddress).transferFrom(msg.sender, receiver, _erc20Amount);
        jpusdInterface.transferFrom(supplier, msg.sender, jpusdAmountFromERC20);
        // event
        emit BoughtWithERC20(jpusdAmountFromERC20, _erc20Amount, msg.sender, _tokenAddress, fee);
    }


    // ---- redeem JPYC token with jpUSD token ----
    /*
     *@return The current price of JPY in USD.
     */
    function getLatestJpyusdPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedJpyUsd.latestRoundData();
        return price;
    }

    /*
     *@return The amount of redeemable JPYC from a certain amount of USD
     *@notice Regards jpUSD as USD and JPYC as JPY
     */
    function getJpycAmountFromJpusd(uint256 _jpusdAmount)
        public
        view
        returns (uint256 jpycAmount)
    {
        return jpycAmount = (_jpusdAmount / uint256(getLatestJpyusdPrice())) * CHAINLINK_DECIMALS;
    }

    /*
     *@return The amount of redeemable JPYC from a certain amount of USD
     *@notice Regards jpUSD as USD and JPYC as JPY
     */
    function getJpusdAmountFromJpyc(uint256 _jpycAmount)
        public
        view
        returns (uint256 jpusdAmount)
    {
        return jpusdAmount = (_jpycAmount * uint256(getLatestJpyusdPrice())) / CHAINLINK_DECIMALS;
    }


    // ---- redeem JPYC token with jpUSD token - core functions ----
    /*
     * @dev User redeems an exact amount of JPYC(_jpycAmount) from jpUSD and pays less than the slippage(_amountOutMin jpUSD), using the Chainlink pricefeed.
     * @notice With fee being charged, the amount limit check is before the fee calculation. Slippagge should consider this in order to make the transaction go through. 
     * User can set parameter: _amountOutMax >=  getJpusdAmountFromJpyc(_jpycAmount * 10000 / (10000 - redeemingBasisPointsRate)). If user pays more than _amountOutMax jpUSD then transaction will fail.
     */
    function redeemExactJpycWithJpusd(uint256 _jpycAmount, uint256 _amountOutMax) external whenNotPaused isWhitelisted(msg.sender) {
        // 1. checking redeeming limit based how much user will receive
        checkAmountRange(_jpycAmount);
        // calculate jpusdAmount without fee
        uint256 jpusdAmount = getJpusdAmountFromJpyc(_jpycAmount);
        // get fee if it exists
        uint256 fee;
        if (redeemingBasisPointsRate > 0) {
            // calculate jpusdAmount including fee
            jpusdAmount = getAmountIncludingRedeemingFee(jpusdAmount);
            fee = jpusdAmount - getJpusdAmountFromJpyc(_jpycAmount);
        }
        // 2. checking slippage
        require(jpusdAmount <= _amountOutMax, "excessive slippage amount");
        // 3. check if user's jpUSD amount is enough
        require(jpusdInterface.balanceOf(msg.sender) >= jpusdAmount, "insufficient balance of jpUSD token");
        // 4. check if the supplier's approved jpUSD amount is enough
        require(_jpycAmount <= jpycInterface.allowance(supplier, address(this)), "insufficient allowance of JPYC");
        // transfer token to receiver
        jpusdInterface.transferFrom(msg.sender, receiver, jpusdAmount);
        jpycInterface.transferFrom(supplier, msg.sender, _jpycAmount);
        // events
        emit RedeemJpyc(_jpycAmount, jpusdAmount, msg.sender, fee);
    }

    /*
     * @dev User redeem JPYC from an exact amount of jpUSD (_jpusdAmount) get more than the slippage(_amountInMax JPYC), using the Chainlink pricefeed.
     * @notice With fee being charged, the amount limit check is before the fee calculation. Slippagge should consider this in order to calculate a proper amount. 
     * User can set parameter: _amountInMin <= (getJpycAmountFromJpusd(_jpusdAmount) - fee). If user gets more than _amountInMin the trasaction will fail.
     */
    function redeemJpycWithExactJpusd(uint256 _jpusdAmount, uint256 _amountInMin) external whenNotPaused isWhitelisted(msg.sender) {
        uint256 jpycAmountFromJpusd = getJpycAmountFromJpusd(_jpusdAmount);
        // get fee if it exists
        uint256 fee;
        if (redeemingBasisPointsRate > 0) {
            fee = getRedeemingFee(jpycAmountFromJpusd);
            // exclude fee from the jpycAmountFromJpusd
            jpycAmountFromJpusd = jpycAmountFromJpusd - fee;
        }
        // 1. check redeeming limit by user's receiving jpyc value
        checkAmountRange(jpycAmountFromJpusd);
        // 2. check slippage
        require(jpycAmountFromJpusd >= _amountInMin, "excessive slippage amount");
        // 3. check if user's jpUSD balance is enough
        require(jpusdInterface.balanceOf(msg.sender) >= _jpusdAmount, "insufficient balance of jpUSD token");
        // 4. check supplier's approved jpyc balance
        require(jpycAmountFromJpusd <= jpycInterface.allowance(supplier, address(this)), "insufficient allowance of JPYC");
        // transfer token to receiver
        jpusdInterface.transferFrom(msg.sender, receiver, _jpusdAmount);
        jpycInterface.transferFrom(supplier, msg.sender, jpycAmountFromJpusd);
        // event
        emit RedeemJpyc(jpycAmountFromJpusd, _jpusdAmount, msg.sender, fee);
    }


    // ---- withdraw & ownership, pause ----
    /// @dev To withdraw ERC20 tokens
    function withdrawERC20(address _tokenAddress) external onlyOwner {
        IERC20(_tokenAddress).transfer(
            msg.sender,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    // owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender must be jpyc owner");
        _;
    }

    /*
     * @dev Pause 
     */
    function pause() public onlyOwner {
        _pause();
    }

    /*
     * @dev Unpause 
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /// transfer ownership
    /*
     * @dev Change supplier to a new address.
     */
    function changeJpycOwner(address _newOwner)
        public
        payable
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "_owner is not allowed to be zero address"
        );
        owner = _newOwner;
        emit ChangeJpycOwner(_newOwner);
    }

    /// change supplier
    /*
     * @dev Change supplier to a new address.
     */
    function changeSupplier(address payable _newSupplier)
        public
        payable
        onlyOwner
    {
        require(
            _newSupplier != address(0),
            "_newSupplier is not allowed to be zero address"
        );
        supplier = _newSupplier;
        emit ChangeSupplier(_newSupplier);
    }

    /// change receiver
    /*
     * @dev Change receiver to a new address.
     */
    function changeReceiver(address payable _newReceiver)
        public
        payable
        onlyOwner
    {
        require(
            _newReceiver != address(0),
            "_newReceiver is not allowed to be zero address"
        );
        receiver = _newReceiver;
        emit ChangeReceiver(_newReceiver);
    }

    /// ---- whitelist ----
    /*
     * @dev Add the _address to whitelist and set the value to true
     */
    function addToWhitelist(address _address) external onlyOwner {
        whitelistedAdresses[_address] = true;
        emit AddToWhitelist(_address);
    }

    /*
     * @dev remove the _address from whitelist and set the value to false
     */
     function removeFromWhitelist(address _address) external onlyOwner {
        whitelistedAdresses[_address] = false;
        emit RemoveFromWhitelist(_address);
     }

     function turnOffWhitelist() external onlyOwner { 
        whitelistOn = false;
     }


     function turnOnWhitelist() external onlyOwner { 
        whitelistOn = true;
     }

     function showWhitelistOn() external view returns(bool){ 
        return whitelistOn;
     }

    /*
     * @dev check if a address is whitelisted or not
     */
     function whitelisted(address _address) public view returns(bool) {
        return whitelistedAdresses[_address];
     }

    // modifier for checking if the address is in the whitelist
     modifier isWhitelisted(address _address) { 
        if(whitelistOn) {
            require(whitelisted(_address), "the address is not whitelisted");
        }
        _;
     }

    // ---- native token on/off ----
    // show nativeToken purchase is on or off
    function showNativeTokenOn() public view returns(bool){ 
        return nativeTokenOn;
     }
    
    // turn on native token purchase
    function toggleNativeTokenOn() external onlyOwner {
        nativeTokenOn = !nativeTokenOn;
        emit ToggleNativeTokenOn(nativeTokenOn);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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