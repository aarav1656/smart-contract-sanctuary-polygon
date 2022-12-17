//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./BaseJarvixTokenDirectSale.sol";

/**
 * @title This is the Jarvix implementation for ERC20 token direct sale
 * @dev It will be based on a price handler to determine ERC20 token price in several currencies which can be the "COIN"
 * default chain coin or any other ERC20 tokens. In case of ERC20 tokens, their contract reference should also be defined
 * in the direct sale contract in order to be able to interact with them
 * @author tazous
 */
contract JarvixTokenDirectSale is BaseJarvixTokenDirectSale {

    /**
     * @dev Contract constructor
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param priceHandlerAddress_ Address of the price handler contract in use for TOKEN price calculation
     * @param tokenAddress_ Address of the TOKEN contract in sale by this contract
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param creatorFeesRate_ Fees rate applicable for contract creator to be paid for its work
     * @param creatorFeesRateDecimals_ Fees rate applicable decimals
     */
    constructor(address proxyHubAddress_, address priceHandlerAddress_, address tokenAddress_,
                bytes32 TOKEN_, uint32 creatorFeesRate_, uint8 creatorFeesRateDecimals_)
    BaseJarvixTokenDirectSale(proxyHubAddress_, priceHandlerAddress_, tokenAddress_,
                              TOKEN_, creatorFeesRate_, creatorFeesRateDecimals_)
    SecuredProcessProxy(address(0), true, true, true) {
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "jarvix-solidity-utils/contracts/CurrencyUtils.sol";
import "jarvix-solidity-utils/contracts/SecuredProcess.sol";
import "./JarvixPriceHandler.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** Cannot set price handler contract address to null */
error PriceHandler_ContractIsInconsistent(bytes32 TOKEN, bytes32 expected);
/** Cannot use provided address */
error DirectSale_InvalidAddress(address invalidAddress);
/** Cannot find reference to a specific Currency */
error DirectSale_NonexistentCurrency(bytes32 currency);
/** Cannot change token address with remaining funds on it */
error DirectSale_RemainingFunds(bytes32 currency, uint256 remainingAmount);
/** Cannot use a specific Currency */
error DirectSale_WrongCurrency(bytes32 currency);
error DirectSale_TransferredAmountTooLow(bytes32 currency, uint256 transferredAmount, uint256 expected);
error DirectSale_RequestedAmountTooHigh(uint256 requestedAmount, uint256 available);
error DirectSale_ReimbursementFailed(bytes32 currency, uint256 reimbursedAmount);

error DirectSale_ERC777_WrongFrom(address from, address expected);
error DirectSale_ERC777_WrongTo(address to, address expected);
error DirectSale_ERC777_WrongMsgSender(address msgSender, address expected, bytes32 currency);
error DirectSale_ERC777_WrongData(bytes data);
error DirectSale_ERC777_WrongMethod(string method);
/** TOKEN buyer could not be message sender in ERC777 case */
error DirectSale_ERC777_WrongBuyer(address buyer);
/** No amount could have already been transferred in pure ERC20 case */
error DirectSale_ERC20_TransferredAmountNotNull(bytes32 currency, uint256 transferredAmount);

/**
 * @title This is the Base Jarvix implementation for TOKENs direct sale. This basis implementation will treat
 * TOKEN as an ERC20 token and has to be extended if other type of token shall be handled
 * @dev It will be based on a price handler to determine token price in several currencies which can be the "COIN"
 * default chain coin or any other ERC20 tokens. In case of ERC20 tokens, their contract reference should also be defined
 * in the direct sale contract in order to be able to interact with them
 * Owner from [Ownable] should be understood here as smart contract creator
 * @author tazous
 */
abstract contract BaseJarvixTokenDirectSale is CurrencyHandler, PriceHandlerProxy, SecuredProcessProxy,
                                               PausableImpl, Ownable, IERC777Recipient {
    /** Role definition necessary to be able to manage contract funds */
    bytes32 public constant FUNDS_ADMIN_ROLE = keccak256("FUNDS_ADMIN_ROLE");

    /** @dev Definition of the buyWithTokens(...) method name */
    bytes32 private constant buyWithTokens_methodName = keccak256(abi.encodePacked("buyWithTokens"));
    /** @dev Definition of the buyAmountWithTokens(...) method name */
    bytes32 private constant buyAmountWithTokens_methodName = keccak256(abi.encodePacked("buyAmountWithTokens"));

    /** @dev Fees rate applicable for contract creator to be paid for its work */
    Decimals.Number_uint32 public creatorFeesRate;
    /** @dev Modification proposal to fees rate applicable for contract creator to be paid for its work */
    Decimals.Number_uint32 public creatorFeesRateProposal;

    /**
     * @dev Event to be sent when TOKENs are purchased
     * @param beneficiary Address of the beneficiary of the purchased TOKENs
     * @param amount Amount of TOKENs purchased
     * @param currency Currency in which the TOKENs where purchased
     * @param price Full price of the purchased TOKENs in chosen currency
     * @param discount True if discount may apply, false if it is bonus
     * @param discountOrBonusRate Discount/Bonus rate applied during the purchase (with applicable decimals)
     * @param pivotPriceUSD Full price of the currency amount involved in the transaction in Pivot USD currency (with
     * applicable decimals)
     */
    event TokensPurchased(address indexed beneficiary, uint256 amount, bytes32 indexed currency, uint256 price,
                          bool indexed discount, Decimals.Number_uint256 discountOrBonusRate, Decimals.Number_uint256 pivotPriceUSD);
    /**
     * @dev Event to be sent when funds are withdrawn
     * @param beneficiary Address of the beneficiary of the withdrawn funds
     * @param amount Amount of funds withdrawn
     * @param currency Currency of funds withdrawn
     */
    event FundsWithdrawn(address indexed beneficiary, uint256 amount, bytes32 indexed currency);
    /**
     * @dev Event to be sent when creator fees rate are changed
     * @param admin Address of the contract's funds administrator that validated the change
     * @param creatorFeesRate New fees rate applicable for contract creator to be paid for its work
     */
    event CreatorFeesRateChanged(address indexed admin, Decimals.Number_uint32 creatorFeesRate);

    /**
     * @dev Contract constructor
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param priceHandlerAddress_ Address of the price handler contract in use for TOKEN price calculation
     * @param tokenAddress_ Address of the TOKEN contract in sale by this contract
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param creatorFeesRate_ Fees rate applicable for contract creator to be paid for its work
     * @param creatorFeesRateDecimals_ Fees rate applicable decimals
     */
    constructor(address proxyHubAddress_, address priceHandlerAddress_, address tokenAddress_,
                bytes32 TOKEN_, uint32 creatorFeesRate_, uint8 creatorFeesRateDecimals_)
    CurrencyHandler(TOKEN_) ProxyDiamond(proxyHubAddress_) PriceHandlerProxy(priceHandlerAddress_) {
        // Set address of the TOKEN contract in sale by this contract
        setTokenAddress(TOKEN_, tokenAddress_);
        // Set fees rate applicable for contract creator to be paid for its work
        _setCreatorFeesRate(creatorFeesRate_, creatorFeesRateDecimals_);

        // ERC1820 Registry for ERC777 token recipient Registration
        IERC1820Registry erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        bytes32 TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
        erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     * @dev Getter of the price handler contract
     */
    function getPriceHandler() internal view override returns(JarvixPriceHandler) {
        JarvixPriceHandler priceHandler = super.getPriceHandler();
        if(priceHandler.getTOKEN() != getTOKEN()) revert PriceHandler_ContractIsInconsistent(priceHandler.getTOKEN(), getTOKEN());
        return priceHandler;
    }

    /**
     * @dev Pulic getter of the address of the TOKEN contract if currency code is "TOKEN" or ERC20 token contract
     * corresponding to given currency code (could be any other of the handled tokens such as "USDC"...). Will return
     * address(0) if token contract address is not defined
     */
    function getTokenAddress(bytes32 currency) public view returns (address) {
        return ProxyHub(proxyHubAddress).findProxyAddress(currency);
    }
    /**
     * @dev Internal getter of the address of the TOKEN contract if currency code is "TOKEN" or ERC20 token contract
     * corresponding to given currency code (could be any other of the handled tokens such as "USDC"...). Will revert
     * if token contract address is not defined
     */
    function _getTokenAddress(bytes32 currency) internal view returns (address) {
        address tokenAddress = getTokenAddress(currency);
        if(tokenAddress == address(0)) revert DirectSale_NonexistentCurrency(currency);
        return tokenAddress;
    }
    /**
     * @dev Setter of the address of the TOKEN contract if currency code is "TOKEN" or of the ERC20 token contract
     * corresponding to given currency code, only accessible by admins. If direct sale contract still have funds for
     * ERC20 token contract about to be changed, update will revert
     */
    function setTokenAddress(bytes32 currency, address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address _tokenAddress = getTokenAddress(currency);
        // No address change
        if(_tokenAddress == tokenAddress) {
            return;
        }
        // Cannot change token contract address with remaining funds
        if(_tokenAddress != address(0) && getBalance(currency) != 0) {
            revert DirectSale_RemainingFunds(currency, getBalance(currency));
        }
        // References the currency
        if(tokenAddress == address(0)) {
            _removeToken(currency);
        }
        else if(_tokenAddress == address(0)){
            _addToken(currency);
        }
        // Store the token address
        _setProxy(currency, tokenAddress, getTokenInterfaceId(currency), true, true, false);
    }
    function getTokenInterfaceId(bytes32 currency) internal virtual view returns (bytes4) {
        // Cannot define a token address for blockchain coin
        if(currency == COIN) revert DirectSale_WrongCurrency(COIN);
        if(currency == getTOKEN()) return type(IERC20).interfaceId;
        // External contract does not seem to implement IERC165
        return 0x00;
    }
    /**
     * @dev Getter of the contract handling TOKENs in sale treated as an ERC20 token
     */
    function getERC20() private view returns (ERC20) {
        return getERC20(getTOKEN());
    }
    /**
     * @dev Getter of the contract handling requested ERC20 token currency
     */
    function getERC20(bytes32 currency) private view returns (ERC20) {
        return ERC20(_getTokenAddress(currency));
    }

    /**
     * @dev Fallback function when directly sending coins to a contract
     * see https://ethereum.stackexchange.com/questions/20874/payable-function-in-solidity
     */
    fallback() external payable {
        buyWithCoins();
    }
    /**
     * @dev Fallback function when directly sending coins to a contract
     * see https://ethereum.stackexchange.com/questions/20874/payable-function-in-solidity
     */
    receive() external payable {
        buyWithCoins();
    }
    /**
     * @dev This is the method to call to directly buy TOKENs with COINs. Amount of purchased TOKENs will directly be
     * calculated from amount of COINs sent in the message value at the time the transaction in being processed by the contract
     * @return The amount of purchased TOKENs
     */
    function buyWithCoins() public payable returns (uint256) {
        // Calculate the amount of TOKENs corresponding to sent amount of coins
        (uint256 tokenAmount, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD) =
            transform(COIN, msg.value);
        // Perform the final buy
        _buy(msg.sender, tokenAmount, COIN, msg.value, false, bonusRate, pivotPriceUSD);
        return tokenAmount;
    }
    /**
     * @dev This is the method to call to directly buy TOKENs with COINs. Amount of COINs needed to buy desired amount of
     * TOKENs will be calculated at the time the transaction in being processed by the contract. Transaction will revert
     * if not enough COINs were sent, otherwise, exceeding amount of COINs will be reimbursed
     * @param tokenAmountRequested Requested amount of TOKENs to be purchased
     * @return The amount of purchased TOKENs
     */
    function buyAmountWithCoins(uint256 tokenAmountRequested) public payable returns (uint256) {
        // Calculate the amount of coins corresponding to requested amount of TOKENs
        (uint256 coinAmount, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD) =
            transformBack(COIN, tokenAmountRequested);
        // Check that enough coins where sent
        if(coinAmount > msg.value) revert DirectSale_TransferredAmountTooLow(COIN, msg.value, coinAmount);
        // Perform the final buy
        _buy(msg.sender, tokenAmountRequested, COIN, coinAmount, true, discountRate, pivotPriceUSD);
        // Reimburse leftover coins amount
        uint256 leftover = msg.value - coinAmount;
        if(leftover > 0) {
            (bool sent, ) = msg.sender.call{value: leftover}("Sent to much coins, reimburse leftover");
            if(!sent) revert DirectSale_ReimbursementFailed(COIN, leftover);
        }
        return tokenAmountRequested;
    }
    /**
     * @dev Fallback function when directly sending ERC777 tokens to a contract
     * @param operator Operator of the transfer
     * @param from Origin of the funds (should be the same a operator expect for a plain old ERC20 transfer)
     * @param to Destination of the funds (should be this contract address)
     * @param amount The amount of tokens received
     * @param userData Payload of the user/caller
     * @param operatorData Payload of the operator (should be empty)
     */
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) public override {
        if(operatorData.length != 0) revert DirectSale_ERC777_WrongData(operatorData);
        // Plain old ERC20 transfer method
        if(userData.length == 0) {
            return;
        }
        if(operator != from) revert DirectSale_ERC777_WrongFrom(from, operator);
        if(to != address(this)) revert DirectSale_ERC777_WrongTo(to, address(this));
        // Decode the method name and its parameters to call the appropriate method
        (string memory methodName, bytes32 currency, uint256 tokenAmountSentOrRequested) = abi.decode(userData, (string, bytes32, uint256));
        // Inconsistent currency token address
        if(msg.sender != _getTokenAddress(currency)) revert DirectSale_ERC777_WrongMsgSender(msg.sender, _getTokenAddress(currency), currency);
        // Call requested method
        if(keccak256(abi.encodePacked(methodName)) == buyWithTokens_methodName) {
            _buyWithTokens(currency, tokenAmountSentOrRequested, amount, from);
        }
        else if(keccak256(abi.encodePacked(methodName)) == buyAmountWithTokens_methodName) {
            _buyAmountWithTokens(currency, tokenAmountSentOrRequested, amount, from);
        }
        // Revert if method name is unknown
        else {
            revert DirectSale_ERC777_WrongMethod(methodName);
        }
    }
    /**
     * @dev This is the method to call to directly buy TOKENs with other ERC20 tokens. Amount of purchased TOKENs will
     * directly be deduced from amount of tokens to be transferred from ERC20 contract at the time the transaction in being
     * processed by the contract
     * @param currency Currency code of the ERC20 token contract to be used to buy TOKENs
     * @param erc20TokenAmountRequired Amount of ERC20 tokens to be used to buy TOKENs
     * @return The amount of purchased TOKENs
     */
    function buyWithTokens(bytes32 currency, uint256 erc20TokenAmountRequired) public returns (uint256) {
        return _buyWithTokens(currency, erc20TokenAmountRequired, 0, address(0));
    }
    /**
     * @dev This is the internal method that will directly buy TOKENs with other ERC20 tokens. Amount of purchased TOKENs
     * will directly be deduced from amount of tokens to be transferred from ERC20 contract at the time the transaction in
     * being processed by the contract. If more tokens than needed are transferred, they will be reimbursed to the sender
     * @param currency Currency code of the ERC20 token contract to be used to buy TOKENs
     * @param erc20TokenAmountRequired Amount of ERC20 tokens to be used to buy TOKENs
     * @param erc20TokenAmountTransferred Amount of ERC20 tokens already sent the current contract
     * @param buyer Address of the buyer to which reimburse potentially oversent tokens (ERC777 case only)
     * @return The amount of purchased TOKENs
     */
    function _buyWithTokens(bytes32 currency, uint256 erc20TokenAmountRequired, uint256 erc20TokenAmountTransferred, address buyer) internal returns (uint256) {
        // Calculate the amount of TOKENs corresponding to sent amount of ERC20 tokens
        (uint256 tokenAmountRequested, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD) =
            transform(currency, erc20TokenAmountRequired);
        _buyFromTokens(currency, tokenAmountRequested, erc20TokenAmountRequired, erc20TokenAmountTransferred,
                       buyer, false, bonusRate, pivotPriceUSD);
        return tokenAmountRequested;
    }
    /**
     * @dev This is the method to call to directly buy TOKENs with other ERC20 tokens. Amount of tokens needed to buy desired
     * amount of TOKENs will be calculated at the time the transaction in being processed by the contract and ERC20 transfer
     * to this contract will be initiated with it
     * @param currency Currency code of the ERC20 token contract to be used to buy TOKENs
     * @param tokenAmountRequested Desired amount of TOKENs to buy
     * @return The amount of ERC20 tokens used to purchase TOKENs
     */
    function buyAmountWithTokens(bytes32 currency, uint256 tokenAmountRequested) public returns (uint256) {
        return _buyAmountWithTokens(currency, tokenAmountRequested, 0, address(0));
    }
    /**
     * @dev This is the internal method that will directly buy TOKENs with other ERC20 tokens. Amount of tokens needed to
     * buy desired amount of TOKENs will be calculated at the time the transaction in being processed by the contract and
     * ERC20 transfer to this contract will be initiated with it minus already transferred tokens amount. If more tokens
     * than needed are transferred, they will be reimbursed to the sender
     * @param currency Currency code of the ERC20 token contract to be used to buy TOKENs
     * @param tokenAmountRequested Desired amount of TOKENs to buy
     * @param erc20TokenAmountTransferred Amount of ERC20 tokens already sent the current contract
     * @param buyer Address of the buyer to which reimburse potentially oversent tokens (ERC777 case only)
     * @return The amount of ERC20 tokens used to purchase TOKENs
     */
    function _buyAmountWithTokens(bytes32 currency, uint256 tokenAmountRequested, uint256 erc20TokenAmountTransferred, address buyer) internal returns (uint256) {
        // Calculate the amount of coins corresponding to requested amount of TOKENs
        (uint256 erc20TokenAmountRequired, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD) =
            transformBack(currency, tokenAmountRequested);
        _buyFromTokens(currency, tokenAmountRequested, erc20TokenAmountRequired, erc20TokenAmountTransferred,
                       buyer, true, discountRate, pivotPriceUSD);
        return erc20TokenAmountRequired;
    }
    /**
     * @dev This is the internal method that will directly buy TOKENs with other ERC20 tokens. All amounts should be calculated
     * by calling methods. Required missing ERC20 tokens will be requested (transferred to) by this contract or if more ERC20
     * tokens than needed are transferred, they will be reimbursed to the sender
     * @param currency Currency code of the ERC20 token contract to be used to buy TOKENs
     * @param tokenAmountRequested Desired amount of TOKENs to buy
     * @param erc20TokenAmountRequired Amount of ERC20 tokens to be used to buy TOKENs
     * @param erc20TokenAmountTransferred Amount of ERC20 tokens already sent the current contract
     * @param buyer Address of the buyer to which reimburse potentially oversent tokens (ERC777 case only)
     * @param discount True if discount may apply, false if it is bonus
     * @param discountOrBonusRate Discount/Bonus rate applied during the purchase (with applicable decimals)
     * @param pivotPriceUSD Full price of the currency amount involved in the transaction in Pivot USD currency (with applicable
     * decimals)
     */
    function _buyFromTokens(bytes32 currency, uint256 tokenAmountRequested, uint256 erc20TokenAmountRequired, uint256 erc20TokenAmountTransferred,
                            address buyer, bool discount, Decimals.Number_uint256 memory discountOrBonusRate, Decimals.Number_uint256 memory pivotPriceUSD) internal {
        // We are in the pure ERC20 "transfer" case
        if(buyer == address(0)) {
            // No amount could have already been transferred in pure ERC20 case
            if(erc20TokenAmountTransferred != 0) revert DirectSale_ERC20_TransferredAmountNotNull(currency, erc20TokenAmountTransferred);
            buyer = msg.sender;
        }
        // We are in the ERC777 "send" case
        else {
            // TOKEN buyer could not be message sender in ERC777 case
            if(buyer == msg.sender) revert DirectSale_ERC777_WrongBuyer(buyer);
        }
        if(getBalance(getTOKEN()) < tokenAmountRequested) revert DirectSale_RequestedAmountTooHigh(tokenAmountRequested, getBalance(getTOKEN()));
        // Retrieve the amount of ERC20 tokens from its contract in order to buy TOKENs with if not already done or some are missing
        if(erc20TokenAmountTransferred < erc20TokenAmountRequired) {
            SafeERC20.safeTransferFrom(getERC20(currency), buyer, address(this), erc20TokenAmountRequired - erc20TokenAmountTransferred);
        }
        // Reimburse oversent ERC20 tokens amount if applicable (
        else if(erc20TokenAmountTransferred > erc20TokenAmountRequired) {
            SafeERC20.safeTransfer(getERC20(currency), buyer, erc20TokenAmountTransferred - erc20TokenAmountRequired);
        }
        _buy(buyer, tokenAmountRequested, currency, erc20TokenAmountRequired, discount, discountOrBonusRate, pivotPriceUSD);
    }
    /**
     * @dev Internal purchase method that will perform the TOKENs transfer to the buyer's address only if contract is not
     * paused and emit corresponding TokensPurchased event
     */
    function _buy(address buyer, uint256 amount, bytes32 currency, uint256 price, bool discount,
                  Decimals.Number_uint256 memory discountOrBonusRate, Decimals.Number_uint256 memory pivotPriceUSD) private whenNotPaused() {
        if(buyer == address(0)) revert DirectSale_InvalidAddress(buyer);
        _doProcess(getSecuredProcessName(), buyer, amount);
        _transfer(buyer, amount);
        emit TokensPurchased(buyer, amount, currency, price, discount, discountOrBonusRate, pivotPriceUSD);
    }
    function transform(bytes32 fromCurrency, uint256 amount) public virtual view
    returns (uint256 result, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        return getPriceHandler().transform(fromCurrency, getTOKEN(), amount);
    }
    function transformBack(bytes32 fromCurrency, uint256 amount) public virtual view
    returns (uint256 result, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        return getPriceHandler().transformBack(fromCurrency, getTOKEN(), amount);
    }
    /**
     * @dev Internal purchase method that will perform the TOKENs transfer to the buyer's address
     */
    function _transfer(address buyer, uint256 amount) internal virtual {
        SafeERC20.safeTransfer(getERC20(), buyer, amount);
    }

    /**
     * @dev Method used to get the secured process name to use (if any is defined)
     */
    function getSecuredProcessName() public virtual view returns (bytes32) {
        return getTOKEN();
    }

    /**
     * @dev Define new smart contract's creator fees rate
     * @param creatorFeesRate_ New fees rate applicable for contract creator to be paid for its work
     * @param decimals_ New fees rate applicable decimals
     */
    function _setCreatorFeesRate(uint32 creatorFeesRate_, uint8 decimals_) private {
        (creatorFeesRate_, decimals_) = Decimals.cleanFromTrailingZeros_uint32(creatorFeesRate_, decimals_);
        // Do nothing if no change
        if(creatorFeesRate.value == creatorFeesRate_ && creatorFeesRate.decimals == decimals_) {
            return;
        }
        // Apply new creator fees rate
        creatorFeesRate.value = creatorFeesRate_;
        creatorFeesRate.decimals = decimals_;
        // Align creator fees rate proposal with new creator fees rate
        creatorFeesRateProposal.value = creatorFeesRate_;
        creatorFeesRateProposal.decimals = decimals_;
        emit CreatorFeesRateChanged(msg.sender, creatorFeesRate);
    }
    /**
     * @dev This is the method to be called by designed smart contract's creator to propose a new fees rate
     * @param creatorFeesRate_ Modification proposal to fees rate applicable for contract creator to be paid for its work
     * @param decimals_ Fees rate proposal applicable decimals
     */
    function proposeNewCreatorFeesRate(uint32 creatorFeesRate_, uint8 decimals_) external onlyOwner {
        creatorFeesRateProposal = Decimals.Number_uint32(creatorFeesRate_, decimals_);
    }
    /**
     * @dev This is the method to be called by a contract's funds administrator to approve creator fees rate modification
     * proposal
     */
    function acceptNewCreatorFeesRate() external onlyRole(FUNDS_ADMIN_ROLE) {
        // Apply current creator fees rate modification proposal
        _setCreatorFeesRate(creatorFeesRateProposal.value, creatorFeesRateProposal.decimals);
    }

    /**
     * @dev This method will withdraw desired amount of given currency to the call address (could be default chain coin
     * "COIN" or any other of the handled tokens as "USDC"... even "TOKEN" could be withdrawn back from this Direct Sale
     * contract) only if message sender has FUNDS_ADMIN_ROLE role
     * @param currency Currency code for which to withdraw funds to caller address
     * @param amount Amount of funds to withdraw to caller address
     */
    function withdraw(bytes32 currency, uint256 amount) public virtual onlyRole(FUNDS_ADMIN_ROLE) {
        if(msg.sender == address(0)) revert DirectSale_InvalidAddress(msg.sender);
        uint256 creatorFeesAmount = 0;
        // Calculate potential smart contract creator's fees amount and deduce it from caller withdrawn amount
        if(creatorFeesRate.value != 0 && owner() != address(0)) {
            creatorFeesAmount = amount * creatorFeesRate.value / 10**(2+creatorFeesRate.decimals);
            amount -= creatorFeesAmount;
        }
        if(currency == COIN) {
            // Transfer caller withdrawn amount
            payable(msg.sender).transfer(amount);
            // Transfer potential smart contract creator's fees amount
            if(creatorFeesAmount != 0) {
                payable(owner()).transfer(creatorFeesAmount);
            }
        }
        else {
            // Transfer caller withdrawn amount
            SafeERC20.safeTransfer(getERC20(currency), msg.sender, amount);
            // Transfer potential smart contract creator's fees amount
            if(creatorFeesAmount != 0) {
                SafeERC20.safeTransfer(getERC20(currency), owner(), creatorFeesAmount);
            }
        }
        emit FundsWithdrawn(msg.sender, amount, currency);
        // If creator's fees amount where sent, emit an event about it
        if(creatorFeesAmount != 0) {
            emit FundsWithdrawn(owner(), creatorFeesAmount, currency);
        }
    }
    /**
     * @dev This method will return this Direct Sale contract's balance for given currency
     */
    function getBalance(bytes32 currency) public virtual view returns (uint256) {
        if(currency == COIN) {
            return address(this).balance;
        }
        else {
            return getERC20(currency).balanceOf(address(this));
        }
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** Cannot find reference to a specific Token */
error CurrencyHandler_NonexistentToken(bytes32 currency);
/** Can find reference to a specific Token */
error CurrencyHandler_ExistentToken(bytes32 currency);

/**
 * @title This is the base implementation for Currency Handling contracts.
 * @dev Defines basis implementation needed when handling currencies
 * @author tazous
 */
contract CurrencyHandler {
    /** Definition of the generical TOKEN */
    bytes32 public constant TOKEN = keccak256("TOKEN");
    /** Definition of the default chain coin (such as ETHER on ethereum, MATIC on polygon...) */
    bytes32 public constant COIN = keccak256("COIN");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant WETH = keccak256("WETH");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant USDC = keccak256("USDC");
    /** Definition of the USDT ERC20 token */
    bytes32 public constant USDT = keccak256("USDT");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant DAI = keccak256("DAI");

    /** @dev Enumerable set used to reference every ERC20 tokens defined in this contract (expect for generical TOKEN value) */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _tokens;

    /** @dev Code defined as the generical TOKEN value. Cannot be set to immutable as it is used under the wood during
     * contract construction which is not allowed. There is therefore no way to update it programmatically in this contract */
    bytes32 private _TOKEN;

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     */
    constructor(bytes32 TOKEN_) {
        _TOKEN = TOKEN_;
    }

    /**
     * @dev Getter of the code defined as the generical TOKEN value
     */
    function getTOKEN() public view returns (bytes32) {
        return _TOKEN;
    }

    /**
     * @dev This method returns the number of ERC20 tokens defined in this contract (expect for generical TOKEN value).
     * Can be used together with {getToken} to enumerate all tokens defined in this contract.
     */
    function getTokenCount() public view returns (uint256) {
        return _tokens.length();
    }
    /**
     * @dev This method returns one of the ERC20 tokens defined in this contract (expect for generical TOKEN value).
     * `index` must be a value between 0 and {getTokenCount}, non-inclusive.
     * Tokens are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getToken} and {getTokenCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getToken(uint256 index) public view returns (bytes32) {
        return _tokens.at(index);
    }
    /**
     * @dev This method checks if given currency code is one of ERC20 tokens defined in this contract (expect for generical
     * TOKEN value)
     * @param currency Currency code which existance among ERC20 tokens defined in this contract should be checked
     * @return True if given currency code is one of ERC20 tokens defined in this contract, false otherwise
     */
    function hasToken(bytes32 currency) public view returns (bool) {
        return _tokens.contains(currency);
    }
    function checkTokenExists(bytes32 currency) public view {
        if(!hasToken(currency)) revert CurrencyHandler_NonexistentToken(currency);
    }
    function checkTokenIsFree(bytes32 currency) public view {
        if(hasToken(currency)) revert CurrencyHandler_ExistentToken(currency);
    }
    /**
     * @dev This method adds given currency code has one of ERC20 tokens defined in this contract (TOKEN & COIN values are
     * not accepted)
     * @param currency Currency code to be added among ERC20 tokens defined in this contract
     */
    function _addToken(bytes32 currency) internal {
        if(currency != COIN && currency != getTOKEN()) {
            checkTokenIsFree(currency);
            _tokens.add(currency);
        }
    }
    /**
     * @dev This method removes given currency code from one of ERC20 tokens defined in this contract (TOKEN & COIN values
     * are not accepted)
     * @param currency Currency code to be removed from ERC20 tokens defined in this contract
     */
    function _removeToken(bytes32 currency) internal {
        if(currency != COIN && currency != getTOKEN()) {
            checkTokenExists(currency);
            _tokens.remove(currency);
        }
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ProxyUtils.sol";

interface ISecuredProcess {
    function checkProcess(bytes32 processName, address address2Process, uint256 amount2Process) external view;
    function doProcess(bytes32 processName, address address2Process,uint256 amount2Process) external;
}

abstract contract SecuredProcessProxy is ProxyDiamond {
    /** @dev Key used to reference the proxied SecuredProcess contract */
    bytes32 public constant PROXY_SecuredProcess = keccak256("SecuredProcessProxy");
    /** ISecuredProcess interface ID definition */
    bytes4 public constant ISecuredProcessInterfaceId = type(ISecuredProcess).interfaceId;

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param securedProcessAddress_ Address of the contract handling secured process
     */
    constructor(address securedProcessAddress_, bool nullable, bool updatable, bool adminable/*, bytes32 defaultProcessName_*/) {
        //_defaultProcessName = defaultProcessName_ == 0x00 ? bytes32(uint256(uint160(address(this))) << 96) : defaultProcessName_;//abi.encodePacked(address(this));
        _setSecuredProcessProxy(PROXY_SecuredProcess, securedProcessAddress_, nullable, updatable, adminable);
    }

    function checkProcess(bytes32 processName, address address2Process, uint256 amount2Process) public view virtual {
        address securedProcessAddress = getProxy(PROXY_SecuredProcess);
        if(securedProcessAddress != address(0)) {
            ISecuredProcess(securedProcessAddress).checkProcess(processName, address2Process, amount2Process);
        }
    }
    function _doProcess(bytes32 processName, address address2Process, uint256 amount2Process) internal virtual {
        address securedProcessAddress = getProxy(PROXY_SecuredProcess);
        if(securedProcessAddress != address(0)) {
            ISecuredProcess(securedProcessAddress).doProcess(processName, address2Process, amount2Process);
        }
    }

    function _setSecuredProcessProxy(bytes32 key, address securedProcessAddress_,
                                     bool nullable, bool updatable, bool adminable) internal {
        _setProxy(key, securedProcessAddress_, ISecuredProcessInterfaceId, nullable, updatable, adminable);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "jarvix-solidity-utils/contracts/CurrencyUtils.sol";
import "jarvix-solidity-utils/contracts/NumberUtils.sol";
import "jarvix-solidity-utils/contracts/ProxyUtils.sol";
import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/** Cannot transform back from TOKEN to currency as bonus mode is activated */
error PriceHandler_BonusMode();
/** Cannot transform from currency to TOKEN as discount mode is activated */
error PriceHandler_DiscountMode();
/** Cannot calculate a price, requested quantity too low */
error PriceHandler_QuantityToLow(bytes32 currency, uint256 amount);
/** Cannot find reference to a specific Currency */
error PriceHandler_NonexistentCurrency(bytes32 currency);
/** Cannot use a specific Currency */
error PriceHandler_WrongCurrency(bytes32 currency);

interface IJarvixPrice{
    function transform(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) external view
    returns (uint256 result, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD);
    function transformBack(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) external view
    returns (uint256 result, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD);
}

/**
 * @title This is the Jarvix base implementation for Price Handling used by tokens Direct Sale contract.
 * @dev Defines the applicable methods needed for price handing using USD as pivot currency by default
 * @author tazous
 */
abstract contract JarvixPriceHandler is IJarvixPrice, CurrencyHandler, AccessControlImpl {
    /** Role definition necessary to be able to manage prices */
    bytes32 public constant PRICES_ADMIN_ROLE = keccak256("PRICES_ADMIN_ROLE");
    /** IJarvixPrice interface ID definition */
    bytes4 public constant IJarvixPriceInterfaceId = type(IJarvixPrice).interfaceId;

    /**
     * @dev Currency price data structure
     * 'decimals' is the number of decimals for which the price data is defined (for instance, if decimals equals
     * to 5, the price data is defined for 10000 or 1e5 units of currencies)
     * 'priceUSD' is USD price defined in this price data with its applicable decimals
     */
    struct CurrencyPriceData {
        uint8 decimals;
        Decimals.Number_uint256 priceUSD;
    }
    /**
     * @dev TOKEN price discount structure (linear increasing rate discount)
     * 'endingAmountUSD' is at what level of USD amount (not taking any decimals into account) will the rate discount stop
     * increasing
     * 'maxDiscountRate' is the max discount rate that will be applyed when endingAmountUSD is reached with its applicable decimals
     * 'isBonus' indicates if discount should be treated as a bonus instead of discount or not
     */
    struct TokenPriceDiscount {
        uint256 endingAmountUSD;
        Decimals.Number_uint32 maxDiscountRate;
        bool isBonus;
    }
    /** @dev Defined TOKEN applicable price discount policy */
    TokenPriceDiscount private _tokenPriceDiscount;

    /**
     * @dev Event emitted whenever TOKEN price discount is changed
     * 'admin' Address of the administrator that changed TOKEN price discount
     * 'endingAmountUSD' Level of USD amount (not taking any decimals into account) when the rate discount stops increasing
     * 'maxDiscountRate' Max discount rate that will be applyed when endingAmountUSD is reached
     * 'isBonus' Should discount be treated as a bonus instead of discount or not
     */
    event TokenPriceDiscountChanged(address indexed admin, uint256 endingAmountUSD, Decimals.Number_uint32 maxDiscountRate, bool isBonus);

    /**
     * @dev Default constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     */
    constructor(bytes32 TOKEN_) CurrencyHandler(TOKEN_) {}

    /**
     * @dev Transform given amount of 'fromCurrency' into 'toCurrency'. Amounts are understood regardless of any decimals
     * concern and are calculated using USD as pivot currency
     * Will return the result amount of 'toCurrency' corresponding to given amount of 'fromCurrency' associated with applyed
     * bonus rate and pivot currency amount (and their applicable decimals)
     * @param fromCurrency Currency from which amount should be transformed into 'toCurrency'
     * @param toCurrency Currency into which amount should be transformed from 'toCurrency'
     * @param amount Amount of fromCurrency to be transformed into toCurrency
     */
    function transform(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) public view
    returns (uint256 result, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        Decimals.Number_uint256 memory bonusRate_ = Decimals.Number_uint256(0, 0);
        // No calculation needed
        if(amount == 0 || fromCurrency == toCurrency) {
            return (amount, bonusRate_, bonusRate_);
        }
        // Get the USD price for given amount of 'fromCurrency'
        Decimals.Number_uint256 memory fromPriceUSD_ = getPriceUSD(fromCurrency, amount);
        // Keep it as pivot USD amount
        Decimals.Number_uint256 memory pivotPriceUSD_ = Decimals.Number_uint256(fromPriceUSD_.value, fromPriceUSD_.decimals);
        // Get the USD price for 1 'toCurrency'
        Decimals.Number_uint256 memory toRateUSD_ = getPriceUSD(toCurrency, 1);
        // When converting to TOKEN, a bonus may apply
        if(toCurrency == getTOKEN() && _tokenPriceDiscount.maxDiscountRate.value != 0) {
            if(!_tokenPriceDiscount.isBonus) revert PriceHandler_DiscountMode();
            // Get the applicable discount
            bonusRate_ = calculateTokenPriceDiscountRate(fromPriceUSD_.value, fromPriceUSD_.decimals);
            // Apply the potential bonus, ie increase usable amount of USD
            fromPriceUSD_.value = fromPriceUSD_.value * (10**bonusRate_.decimals + bonusRate_.value);
            fromPriceUSD_.decimals += bonusRate_.decimals;
        }
        return (doTransform(fromPriceUSD_, toRateUSD_, fromCurrency, amount), bonusRate_, pivotPriceUSD_);
    }
    /**
     * @dev Transform back given expected amount of 'toCurrency' into 'fromCurrency'. Amounts are understood regardless of any
     * decimals concern and are calculated using USD as pivot currency
     * Will return the result amount of 'fromCurrency' corresponding to given amount of 'toCurrency' associated with applyed
     * discount rate and pivot currency amount (and their applicable decimals)
     * @param fromCurrency Currency into which amount of 'toCurrency' should be transformed back
     * @param toCurrency Currency from which amount should be transformed back into 'fromCurrency'
     * @param amount Amount of toCurrency to be transformed back into fromCurrency
     */
    function transformBack(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) public view
    returns (uint256 result, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        Decimals.Number_uint256 memory discountRate_ = Decimals.Number_uint256(0, 0);
        // No calculation needed
        if(amount == 0 || fromCurrency == toCurrency) {
            return (amount, discountRate_, discountRate_);
        }
        // Get the USD price for 1 'fromCurrency'
        Decimals.Number_uint256 memory fromRateUSD_ = getPriceUSD(fromCurrency, 1);
        // Get the USD price for given amount of 'toCurrency'
        Decimals.Number_uint256 memory toPriceUSD_ = getPriceUSD(toCurrency, amount);
        // Keep it as pivot USD amount
        Decimals.Number_uint256 memory pivotPriceUSD_ = Decimals.Number_uint256(toPriceUSD_.value, toPriceUSD_.decimals);
        // When converting back from TOKEN, a discount may apply
        if(toCurrency == getTOKEN() && _tokenPriceDiscount.maxDiscountRate.value != 0) {
            if(_tokenPriceDiscount.isBonus) revert PriceHandler_BonusMode();
            // Get the applicable discount
            discountRate_ = calculateTokenPriceDiscountRate(toPriceUSD_.value, toPriceUSD_.decimals);
            // Apply the potential discount, ie decrease needed amount of USD
            toPriceUSD_.value = toPriceUSD_.value * (10**discountRate_.decimals - discountRate_.value);
            toPriceUSD_.decimals += discountRate_.decimals;
            // TODO SEE IF IT WAS RELEVANT
            pivotPriceUSD_.value = toPriceUSD_.value;
            pivotPriceUSD_.decimals = toPriceUSD_.decimals;
        }
        return (doTransform(toPriceUSD_, fromRateUSD_, toCurrency, amount), discountRate_, pivotPriceUSD_);
    }
    function doTransform(Decimals.Number_uint256 memory price, Decimals.Number_uint256 memory rate, bytes32 currency, uint256 amount)
    private pure returns (uint256) {
        // Align decimals if needed
        (price, rate) = Decimals.align_Number(price, rate);
        // Perform price calculation
        uint256 result = price.value / rate.value;
        if(result == 0) revert PriceHandler_QuantityToLow(currency, amount);
        return result;
    }
    /**
     * @dev Getter of the USD price for given currency amount (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * Will return the result price in USD for given currency associated with applicable decimals
     * @param currency Currency for which to get the USD price
     * @param amount Amount of currency for which to get the USD price
     */
    function getPriceUSD(bytes32 currency, uint256 amount) public view returns (Decimals.Number_uint256 memory) {
        CurrencyPriceData memory data = getPriceData(currency);
        return Decimals.cleanFromTrailingZeros_Number(Decimals.Number_uint256(amount * data.priceUSD.value,
                                                                              data.decimals + data.priceUSD.decimals));
    }
    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * 'currency' Code of the currency for which to get the price data
     * Returns the price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view virtual returns (CurrencyPriceData memory);

    /**
     * @dev Getter of the TOKEN applicable price discount policy (linear increasing rate discount)
     */
    function getTokenPriceDiscount() external view returns(TokenPriceDiscount memory) {
        return _tokenPriceDiscount;
    }
    /**
     * @dev Setter of the TOKEN applicable price discount policy (linear increasing rate discount)
     * @param endingAmountUSD Level of USD amount (not taking any decimals into account) when the rate discount stops increasing
     * @param maxDiscountRate Max discount rate that will be applyed when endingAmountUSD is reached
     * @param decimals maxDiscountRate applicable decimals
     * @param isBonus Should discount be treated as a bonus instead of discount or not
     */
    function setTokenPriceDiscount(uint256 endingAmountUSD, uint32 maxDiscountRate, uint8 decimals, bool isBonus) external onlyRole(PRICES_ADMIN_ROLE) {
        if(endingAmountUSD == 0 || maxDiscountRate == 0) {
            endingAmountUSD = 0;
            maxDiscountRate = 0;
            decimals = 0;
            isBonus = false;
        }
        else {
            (maxDiscountRate, decimals) = Decimals.cleanFromTrailingZeros_uint32(maxDiscountRate, decimals);
        }
        _tokenPriceDiscount = TokenPriceDiscount(endingAmountUSD, Decimals.Number_uint32(maxDiscountRate, decimals), isBonus);
        emit TokenPriceDiscountChanged(msg.sender, endingAmountUSD, _tokenPriceDiscount.maxDiscountRate, isBonus);
    }
    /**
     * @dev Calculate the applicable TOKEN price discount rate using a linear increasing rate discount policy
     * @param amountUSD Amount of USD for which to calculate the applicable TOKEN price discount rate
     * @param decimalsUSD Decimals of given amount of USD
     * Returns the applicable TOKEN price discount rate for given amount of USD associated with applicable decimals
     */
    function calculateTokenPriceDiscountRate(uint256 amountUSD, uint8 decimalsUSD) public view returns(Decimals.Number_uint256 memory) {
        if(_tokenPriceDiscount.maxDiscountRate.value == 0) {
            return Decimals.Number_uint256(0, 0);
        }
        amountUSD = amountUSD / (10**decimalsUSD);
        if(_tokenPriceDiscount.endingAmountUSD <= amountUSD) {
            return Decimals.Number_uint256(_tokenPriceDiscount.maxDiscountRate.value, _tokenPriceDiscount.maxDiscountRate.decimals);
        }
        Decimals.Number_uint256 memory discountRate_ = Decimals.Number_uint256(
            amountUSD * _tokenPriceDiscount.maxDiscountRate.value*100000 / _tokenPriceDiscount.endingAmountUSD,
            _tokenPriceDiscount.maxDiscountRate.decimals + 5);
        return Decimals.cleanFromTrailingZeros_Number(discountRate_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IJarvixPriceInterfaceId;
    }
}

abstract contract PriceHandlerProxy is ProxyDiamond {
    /** @dev Key used to reference the proxied JarvixPriceHandler contract */
    bytes32 public constant PROXY_PriceHandler = keccak256("PriceHandlerProxy");

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param priceHandlerAddress_ Address of the contract handling prices
     */
    constructor(address priceHandlerAddress_) {
        _setPriceHandlerProxy(priceHandlerAddress_);
    }

    /**
     * Getter of the contract handling prices
     */
    function getPriceHandler() internal view virtual returns(JarvixPriceHandler) {
        return JarvixPriceHandler(getProxy(PROXY_PriceHandler));
    }
    function _setPriceHandlerProxy(address priceHandlerAddress_) internal virtual {
        // Cannot define a IJarvixPrice interface ID constant as in mixed handler, it would be inherited twice, leading
        // to compilation failure
        _setProxy(PROXY_PriceHandler, priceHandlerAddress_, type(IJarvixPrice).interfaceId, false, true, true);
    }
}

/**
 * @title This is the Jarvix implementation for Manual Price Handling used by tokens Direct Sale contract.
 * @dev Manual price calculation is based on statically defined Currency->USD Prices
 * @author tazous
 */
contract JarvixPriceHandlerManual is JarvixPriceHandler {

    /** @dev Defined Currencies pricing data */
    mapping(bytes32 => CurrencyPriceData) private _pricesData;

    /**
     * @dev Event emitted whenever pricing data is changed
     * 'admin' Address of the administrator that changed pricing data
     * 'currency' Code of the currency for which pricing data is changed
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * 'priceUSD' Currency USD price with it applicable decimals
     */
    event PriceDataChanged(address indexed admin, bytes32 indexed currency, uint8 decimals, Decimals.Number_uint256 priceUSD);

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param coinDecimals Number of decimals for which the COIN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of COINs)
     * @param coinPriceUSD COIN USD price
     * @param coinDecimalsUSD Number of decimals of the COIN USD price
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                uint8 coinDecimals, uint256 coinPriceUSD, uint8 coinDecimalsUSD)
    JarvixPriceHandler(TOKEN_) {
        _setPriceData(TOKEN_, tokenDecimals, tokenPriceUSD, tokenDecimalsUSD);
        _setPriceData(COIN, coinDecimals, coinPriceUSD, coinDecimalsUSD);
    }

    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to get the price data
     * @return The price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view virtual override returns (CurrencyPriceData memory) {
        CurrencyPriceData memory result = _pricesData[currency];
        if(result.priceUSD.value == 0) revert PriceHandler_NonexistentCurrency(currency);
        return result;
    }
    /**
     * @dev External setter of the price data for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...) only accessible to prices administrators
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param priceUSD Currency USD price
     * @param decimalsUSD Number of decimals of the currency USD price
     */
    function setPriceData(bytes32 currency, uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) external onlyRole(PRICES_ADMIN_ROLE) {
        _setPriceData(currency, decimals, priceUSD, decimalsUSD);
    }
    /**
     * @dev Internal setter of the price data for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param priceUSD Currency USD price
     * @param decimalsUSD Number of decimals of the currency USD price
     */
    function _setPriceData(bytes32 currency, uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) internal {
        CurrencyPriceData storage priceData = _pricesData[currency];
        (priceUSD, decimalsUSD) = Decimals.cleanFromTrailingZeros(priceUSD, decimalsUSD);
        if(priceData.priceUSD.value == priceUSD) {
            if(priceUSD == 0 || (priceData.decimals == decimals && priceData.priceUSD.decimals == decimalsUSD)) {
                return;
            }
            priceData.decimals = decimals;
            priceData.priceUSD.decimals = decimalsUSD;
            emit PriceDataChanged(msg.sender, currency, priceData.decimals, priceData.priceUSD);
            return;
        }
        if(priceData.priceUSD.value == 0) {
            _pricesData[currency] = CurrencyPriceData(decimals, Decimals.Number_uint256(priceUSD, decimalsUSD));
            _addToken(currency);
        }
        else if(priceUSD == 0) {
            priceData.decimals = 0;
            priceData.priceUSD.value = 0;
            priceData.priceUSD.decimals = 0;
            _removeToken(currency);
        }
        else {
            priceData.decimals = decimals;
            priceData.priceUSD.value = priceUSD;
            priceData.priceUSD.decimals = decimalsUSD;
        }
        emit PriceDataChanged(msg.sender, currency, priceData.decimals, priceData.priceUSD);
    }
}
/**
 * @title This is the Jarvix implementation for Automatic Price Handling used by tokens Direct Sale contract.
 * @dev Automatic price calculation is based on Chainlink Currency->USD Price Feed contract, except for TOKEN, which price
 * is defined statically
 * @author tazous
 */
contract JarvixPriceHandlerAuto is JarvixPriceHandler {

    /**
     * @dev Currency data used for automatic price calculation
     * 'decimals' is the number of decimals for which the price data is defined (for instance, if decimals equals
     * to 5, the price data is defined for 10000 or 1e5 units of currencies)
     * 'usdAggregatorV3Address' Chainlink Currency->USD Price Feed contract address
     */
    struct CurrencyData {
        uint8 decimals;
        address usdAggregatorV3Address;
    }

    /** @dev Defined currencies data used for automatic price calculation */
    mapping(bytes32 => CurrencyData) private _currenciesData;
    /** @dev Defined TOKEN pricing data */
    CurrencyPriceData private _priceData;

    /**
     * @dev Event emitted whenever currency data is changed
     * 'admin' Address of the administrator that changed currency data
     * 'currency' Code of the currency for which price data is changed
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * 'usdAggregatorV3Address' Chainlink Currency->USD Price Feed contract address
     */
    event CurrencyDataChanged(address indexed admin, bytes32 indexed currency, uint8 decimals, address usdAggregatorV3Address);
    /**
     * @dev Event emitted whenever TOKEN price data is changed
     * 'admin' Address of the administrator that changed TOKEN price data
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the price
     * data is defined for 10000 or 1e5 units of TOKENs)
     * 'priceUSD' TOKEN USD price with it applicable decimals
     */
    event TokenPriceDataChanged(address indexed admin, uint8 decimals, Decimals.Number_uint256 priceUSD);

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param coinDecimals Number of decimals for which the COIN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of COINs)
     * @param coin2usdAggregatorV3Address Chainlink COIN->USD Price Feed contract address
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                uint8 coinDecimals, address coin2usdAggregatorV3Address)
    JarvixPriceHandler(TOKEN_) {
        _setTokenPriceData(tokenDecimals, tokenPriceUSD, tokenDecimalsUSD);
        _setCurrencyData(COIN, coinDecimals, coin2usdAggregatorV3Address);
    }

    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to get the price data
     * @return The price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view override returns (CurrencyPriceData memory) {
        // TOKEN pricing data is defined "statically'
        if(currency == getTOKEN()) {
            return _priceData;
        }
        // Get the currency data
        CurrencyData storage currencyData = _getCurrencyData(currency);
        // Build corresponding USD price aggregator
        AggregatorV3Interface usdPriceFeed = AggregatorV3Interface(currencyData.usdAggregatorV3Address);
        // Get last USD price
        (, int256 priceUSD_, , ,) = usdPriceFeed.latestRoundData();
        Decimals.Number_uint256 memory priceUSD = Decimals.Number_uint256(uint256(priceUSD_), usdPriceFeed.decimals());
        priceUSD = Decimals.cleanFromTrailingZeros_Number(priceUSD);
        // Build & return the result
        return CurrencyPriceData(currencyData.decimals, priceUSD);
    }

    /**
     * @dev Getter of the data used for given currency automatic price calculation (TOKEN is not part of it)
     */
    function getCurrencyData(bytes32 currency) external view returns (CurrencyData memory) {
        return _currenciesData[currency];
    }
    /**
     * @dev Getter of the data used for given currency automatic price calculation (TOKEN is not part of it). Will revert
     * if given currency is unknown
     */
    function _getCurrencyData(bytes32 currency) internal view returns (CurrencyData storage) {
        CurrencyData storage currencyData = _currenciesData[currency];
        if(currencyData.usdAggregatorV3Address == address(0)) revert PriceHandler_NonexistentCurrency(currency);
        return currencyData;
    }
    /**
     * @dev External setter of the price data for given currency automatic price calculation (could be default chain coin
     * "COIN" or any other of the handled tokens as "USDC"... except TOKEN which can be defined by its own setter) only
     * accessible to contract administrators
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param usdAggregatorV3Address Chainlink Currency->USD Price Feed contract address
     */
    function setCurrencyData(bytes32 currency, uint8 decimals, address usdAggregatorV3Address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setCurrencyData(currency, decimals, usdAggregatorV3Address);
    }
    /**
     * @dev Internal setter of the price data for given currency automatic price calculation (could be default chain coin
     * "COIN" or any other of the handled tokens as "USDC"... except TOKEN which can be defined by its own setter)
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param usdAggregatorV3Address Chainlink Currency->USD Price Feed contract address
     */
    function _setCurrencyData(bytes32 currency, uint8 decimals, address usdAggregatorV3Address) internal {
        if(currency == getTOKEN()) revert PriceHandler_WrongCurrency(currency);
        CurrencyData storage currencyData = _currenciesData[currency];
        if(currencyData.usdAggregatorV3Address == usdAggregatorV3Address) {
            if(usdAggregatorV3Address == address(0) || currencyData.decimals == decimals) {
                return;
            }
            currencyData.decimals = decimals;
            emit CurrencyDataChanged(msg.sender, currency, currencyData.decimals, currencyData.usdAggregatorV3Address);
            return;
        }
        if(currencyData.usdAggregatorV3Address == address(0)) {
            _currenciesData[currency] = CurrencyData(decimals, usdAggregatorV3Address);
            _addToken(currency);
        }
        else if(usdAggregatorV3Address == address(0)) {
            currencyData.decimals = 0;
            currencyData.usdAggregatorV3Address = usdAggregatorV3Address;
            _removeToken(currency);
        }
        else {
            // Check that given address can be treated as a chainlink aggregator smart contract
            AggregatorV3Interface(usdAggregatorV3Address).latestRoundData();
            currencyData.decimals = decimals;
            currencyData.usdAggregatorV3Address = usdAggregatorV3Address;
        }
        emit CurrencyDataChanged(msg.sender, currency, currencyData.decimals, currencyData.usdAggregatorV3Address);
    }

    /**
     * @dev External setter of the TOKEN price data only accessible to prices administrators
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of TOKENs)
     * @param priceUSD TOKEN USD price
     * @param decimalsUSD Number of decimals of the TOKEN USD price
     */
    function setTokenPriceData(uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) external onlyRole(PRICES_ADMIN_ROLE) {
        _setTokenPriceData(decimals, priceUSD, decimalsUSD);
    }
    /**
     * @dev Internal setter of the TOKEN price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of TOKENs)
     * @param priceUSD TOKEN USD price
     * @param decimalsUSD Number of decimals of the TOKEN USD price
     */
    function _setTokenPriceData(uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) internal {
        _priceData.decimals = decimals;
        _priceData.priceUSD = Decimals.cleanFromTrailingZeros_Number(Decimals.Number_uint256(priceUSD, decimalsUSD));
        emit TokenPriceDataChanged(msg.sender, _priceData.decimals, _priceData.priceUSD);
    }
}
/**
 * @title This is the Jarvix implementation for Mixed Price Handling used by tokens Direct Sale contract. Mixed
 * means it is based on a fully Manual Price Handler implementation that delegates to another linked deployed Price Handler
 * contract on unknown currencies or COIN
 * @dev Mixed price calculation is based on statically defined Currency->USD Prices and default to Proxied Price Handler
 * calculation if not explicitly defined or if currency is COIN
 * @author tazous
 */
contract JarvixPriceHandlerMixed is JarvixPriceHandlerManual, PriceHandlerProxy {

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param priceHandlerAddress_ Address of the Proxied Price Handler contract to default to on unknown currencies or COIN
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                address proxyHubAddress_, address priceHandlerAddress_)
    JarvixPriceHandlerManual(TOKEN_, tokenDecimals, tokenPriceUSD, tokenDecimalsUSD, 0, 0, 0)
    ProxyDiamond(proxyHubAddress_) PriceHandlerProxy(priceHandlerAddress_) {}

    /**
     * @dev Manual Price Handler contract implementation is overridden in order to default to Proxied Price Handler contract
     * on unknown currencies or COIN
     */
    function getPriceData(bytes32 currency) public view override returns (CurrencyPriceData memory) {
        if(currency == getTOKEN() || hasToken(currency)) {
            return super.getPriceData(currency);
        }
        return getPriceHandler().getPriceData(currency);
    }

    /**
     * @dev This method returns the number of ERC20 tokens FULLY defined in this contract (expect for generical TOKEN value).
     * Can be used together with {getTokenFully} to enumerate all tokens FULLY defined in this contract. Fully means directly
     * defined by the contract or defined by linked price handler contract
     */
    function getTokenCountFully() public view returns (uint256) {
        // Get count of tokens defined directly on current price handler
        uint256 count = getTokenCount();
        // Parse linked price handler defined tokens
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        uint256 countProxy = priceHandlerProxy.getTokenCount();
        for(uint256 i = 0 ; i < countProxy ; i++) {
            bytes32 tokenProxy = priceHandlerProxy.getToken(i);
            // Token is neither the generic one defined by this contracts nor already defined
            if(tokenProxy != getTOKEN() && !hasToken(tokenProxy)) {
                count++;
            }
        }
        // Check if generical TOKEN defined by linked price handler should be counted as well
        bytes32 TOKENProxy = priceHandlerProxy.getTOKEN();
        if(TOKENProxy != getTOKEN() && !hasToken(TOKENProxy)) {
            count++;
        }
        return count;
    }
    /**
     * @dev This method returns one of the ERC20 tokens FULLY defined in this contract (expect for generical TOKEN value).
     * `index` must be a value between 0 and {getTokenCountFully}, non-inclusive. Fully means directly defined by the contract
     * or defined by linked price handler contract
     * Tokens are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getTokenFully} and {getTokenCountFully}, make sure you perform all queries on the same block.
     * See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getTokenFully(uint256 index) public view returns (bytes32) {
        // Index is in the range of directly defined token
        if(index < getTokenCount()) {
            return getToken(index);
        }
        // Shift index to be used on linked price handler
        index -= getTokenCount();
        uint256 currentIndex = 0;
        // Parse linked price handler defined tokens
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        uint256 countProxy = priceHandlerProxy.getTokenCount();
        for(uint256 i = 0 ; i < countProxy ; i++) {
            bytes32 tokenProxy = priceHandlerProxy.getToken(i);
            // Token is generic one defined by this contracts or already defined
            if(tokenProxy == getTOKEN() || hasToken(tokenProxy)) {
               continue;
            }
            // Requested index reached
            if(currentIndex == index) {
                return tokenProxy;
            }
            // Continue to next index
            currentIndex++;
        }
        if(currentIndex == index) {
            // Check if generical TOKEN defined by linked price handler should be part of result
            bytes32 TOKENProxy = priceHandlerProxy.getTOKEN();
            if(TOKENProxy != getTOKEN() && !hasToken(TOKENProxy)) {
                return TOKENProxy;
            }
        }
        // Should fail as it is out of range
        return priceHandlerProxy.getToken(countProxy);
    }
    /**
     * @dev This method checks if given currency code is one of ERC20 tokens FULLY defined in this contract (expect for
     * generical TOKEN value). Fully means directly defined by the contract or defined by linked price handler contract
     * @param currency Currency code which existance among ERC20 tokens FULLY defined in this contract should be checked
     * @return True if given currency code is one of ERC20 tokens FULLY defined in this contract, false otherwise
     */
    function hasTokenFully(bytes32 currency) public view returns (bool) {
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        return hasToken(currency) || (currency != getTOKEN() && (priceHandlerProxy.getTOKEN() == currency ||
                                                                 priceHandlerProxy.hasToken(currency)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "../ERC20/IERC20.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/IERC1820Registry.sol";

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777 is Context, IERC777, IERC20 {
    using Address for address;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev `defaultOperators` may be an empty array.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(_msgSender(), recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(holder, spender, amount);
        _send(holder, recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: transfer from the zero address");
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
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
            require(currentAllowance >= amount, "ERC777: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable {

    /**
     * @dev Default constructor
     */
    constructor() {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role` instead of a string generated message
     */
    function _checkRole(bytes32 role, address account) internal view virtual override {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        address sender = _msgSender();
        if(!hasRole(getRoleAdmin(role), sender) && !hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            revert AccessControl_MissingRole(sender, getRoleAdmin(role));
        }
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev Sets `role` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminItself(bytes32 role) public {
        setRoleAdmin(role, role);
    }
    /**
     * @dev Sets DEFAULT_ADMIN_ROLE as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender
     * is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminDefault(bytes32 role) public {
        setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to grant access to pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable {
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
library EnumerableSet {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SecurityUtils.sol";

error ProxyHub_ContractIsNull();
error ProxyHub_ContractIsInvalid(bytes4 interfaceId);
error ProxyHub_KeyNotDefined(address user, bytes32 key);
error ProxyHub_NotUpdatable();
error ProxyHub_NotAdminable();
error ProxyHub_CanOnlyBeRestricted();
error ProxyHub_CanOnlyBeAdminableIfUpdatable();

/**
 * @dev As solidity contracts are size limited, and to ease modularity and potential upgrades, contracts should be divided
 * into smaller contracts in charge of specific functional processes. Links between those contracts and their users can be
 * seen as 'proxies', a way to call and delegate part of a treatment. Instead of having every user contract referencing and
 * managing links to those proxies, this part as been delegated to following ProxyHub. User contract might then declare
 * themself as ProxyDiamond to easily store and access their own proxies
 */
contract ProxyHub is PausableImpl {

    /**
     * @dev Proxy definition data structure
     * 'proxyAddress' Address of the proxied contract
     * 'interfaceId' ID of the interface the proxied contract should comply to (ERC165)
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    struct Proxy {
        address proxyAddress;
        bytes4 interfaceId;
        bool nullable;
        bool updatable;
        bool adminable;
        bytes32 adminRole;
    }
    /** @dev Proxies defined for users on keys */
    mapping(address => mapping(bytes32 => Proxy)) private _proxies;
    /** @dev Enumerable set used to reference every defined users */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _users;
    /** @dev Enumerable sets used to reference every defined keys by users */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(address => EnumerableSet.Bytes32Set) private _keys;

    /**
     * @dev Event emitted whenever a proxy is defined
     * 'admin' Address of the administrator that defined the proxied contract (will be the user if directly managed)
     * 'user' Address of the of the user for which a proxy was defined
     * 'key' Key by which the proxy was defined and referenced
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    event ProxyDefined(address indexed admin, address indexed user, bytes32 indexed key, address proxyAddress,
                       bytes4 interfaceId, bool nullable, bool updatable, bool adminable, bytes32 adminRole);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Search for the existing proxy defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function findProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        return _proxies[user][key];
    }
    /**
     * @dev Search for the existing proxy defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function findProxy(bytes32 key) public view returns (Proxy memory) {
        return findProxyFor(msg.sender, key);
    }
    /**
     * @dev Search for the existing proxy address defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function findProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return findProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Search for the existing proxy address defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function findProxyAddress(bytes32 key) external view returns (address) {
        return findProxy(key).proxyAddress;
    }
    /**
     * @dev Search if proxy has been defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return True if proxy has been defined by given user on provided key, false otherwise
     */
    function isKeyDefinedFor(address user, bytes32 key) public view returns (bool) {
        // A proxy can have only been initialized whether with a null address AND nullablevalue set to true OR a not null
        // address (When a structure has not yet been initialized, all boolean value are false)
        return _proxies[user][key].proxyAddress != address(0) || _proxies[user][key].nullable;
    }
    /**
     * @dev Check if proxy has been defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     */
    function checkKeyIsDefinedFor(address user, bytes32 key) internal view {
        if(!isKeyDefinedFor(user, key)) revert ProxyHub_KeyNotDefined(user, key);
    }
    /**
     * @dev Get the existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function getProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        checkKeyIsDefinedFor(user, key);
        return _proxies[user][key];
    }
    /**
     * @dev Get the existing proxy defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function getProxy(bytes32 key) public view returns (Proxy memory) {
        return getProxyFor(msg.sender, key);
    }
    /**
     * @dev Get the existing proxy address defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function getProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return getProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Get the existing proxy address defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function getProxyAddress(bytes32 key) external view returns (address) {
        return getProxy(key).proxyAddress;
    }

    /**
     * @dev Set already existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found, with ProxyHub_NotAdminable if not allowed to be modified by administrator, with ProxyHub_CanOnlyBeRestricted
     * if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull when given address is null
     * and null not allowed
     * @param user User that should have defined the proxy being modified
     * @param key Key by which the proxy being modified should have been defined
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function setProxyFor(address user, bytes32 key, address proxyAddress, bytes4 interfaceId,
                         bool nullable, bool updatable, bool adminable) external {
        _setProxy(msg.sender, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, DEFAULT_ADMIN_ROLE);
    }
    /**
     * @dev Define proxy for caller on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                      bool nullable, bool updatable, bool adminable, bytes32 adminRole) external {
        _setProxy(msg.sender, msg.sender, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    function _setProxy(address admin, address user, bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) private whenNotPaused() {
        if(!updatable && adminable) revert ProxyHub_CanOnlyBeAdminableIfUpdatable();
        // Check if we are in update mode and perform updatability validation
        if(isKeyDefinedFor(user, key)) {
            Proxy memory proxy = _proxies[user][key];
            // Proxy is being updated directly by its user
            if(admin == user) {
                if(!proxy.updatable) revert ProxyHub_NotUpdatable();
            }
            // Proxy is being updated "externally" by an administrator
            else {
                if(!proxy.adminable && admin != user) revert ProxyHub_NotAdminable();
                _checkRole(proxy.adminRole, admin);
                // Admin role is never given in that case, should then be retrieved
                adminRole = _proxies[user][key].adminRole;
            }
            if(proxy.interfaceId != interfaceId || proxy.adminRole != adminRole) revert ProxyHub_CanOnlyBeRestricted();
            // No update to be performed
            if(proxy.proxyAddress == proxyAddress && proxy.nullable == nullable &&
               proxy.updatable == updatable && proxy.adminable == adminable) {
                return;
            }
            if((!_proxies[user][key].nullable && nullable) ||
               (!_proxies[user][key].updatable && updatable) ||
               (!_proxies[user][key].adminable && adminable)) {
                revert ProxyHub_CanOnlyBeRestricted();
            }
        }
        // Proxy cannot be initiated by administration
        else if(admin != user) revert ProxyHub_KeyNotDefined(user, key);
        // Proxy reference is being created
        else {
            _users.add(user);
            _keys[user].add(key);
        }
        // Check Proxy depending on its address
        if(proxyAddress == address(0)) {
            // Proxy address cannot be set to null
            if(!nullable) revert ProxyHub_ContractIsNull();
        }
        // Interface ID is defined
        else if(interfaceId != 0x00) {
            // Proxy should support requested interface
            if(!ERC165(proxyAddress).supportsInterface(interfaceId)) revert ProxyHub_ContractIsInvalid(interfaceId);
        }

        _proxies[user][key] = Proxy(proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
        emit ProxyDefined(admin, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    /**
     * @dev This method returns the number of users defined in this contract.
     * Can be used together with {getUserAt} to enumerate all users defined in this contract.
     */
    function getUserCount() public view returns (uint256) {
        return _users.length();
    }
    /**
     * @dev This method returns one of the users defined in this contract.
     * `index` must be a value between 0 and {getUserCount}, non-inclusive.
     * Users are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getUserAt} and {getUserCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param index Index at which to search for the user
     */
    function getUserAt(uint256 index) public view returns (address) {
        return _users.at(index);
    }
    /**
     * @dev This method returns the number of keys defined in this contract for a user.
     * Can be used together with {getKeyAt} to enumerate all keys defined in this contract for a user.
     * @param user User for which to get defined number of keys
     */
    function getKeyCount(address user) public view returns (uint256) {
        return _keys[user].length();
    }
    /**
     * @dev This method returns one of the keys defined in this contract for a user.
     * `index` must be a value between 0 and {getKeyCount}, non-inclusive.
     * Keys are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getKeyAt} and {getKeyCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param user User for which to get key at defined index
     * @param index Index at which to search for the key of defined user
     */
    function getKeyAt(address user, uint256 index) public view returns (bytes32) {
        return _keys[user].at(index);
    }
}

error ProxyDiamond_ContractIsInvalid();

/**
 * @dev This is the contract to extend in order to easily store and access a proxy
 */
contract ProxyDiamond {
    /** @dev Address of the Hub where proxies are stored */
    address public immutable proxyHubAddress;

    /**
     * @dev Default constructor
     * @param proxyHubAddress_ Address of the Hub where proxies are stored
     */
    constructor(address proxyHubAddress_) {
        proxyHubAddress = proxyHubAddress_;
    }

    /**
     * @dev Returns the address of the proxy defined by current proxy diamond on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxy(bytes32 key) public virtual view returns (address) {
        return ProxyHub(proxyHubAddress).getProxyAddress(key);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function _setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual {
        ProxyHub(proxyHubAddress).setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed. Adminnistrator role will be the default one returned by getProxyAdminRole()
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function _setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable) internal virtual {
        _setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, getProxyAdminRole());
    }
    /**
     * @dev Default proxy hub administrator role
     */
    function getProxyAdminRole() public virtual returns (bytes32) {
        return 0x00;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Decimals {

    /**
     * @dev Decimal number structure, base on a uint256 value and its applicable decimals number
     */
    struct Number_uint256 {
        uint256 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint32 value and its applicable decimals number
     */
    struct Number_uint32 {
        uint32 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint8 value and its applicable decimals number
     */
    struct Number_uint8 {
        uint8 value;
        uint8 decimals;
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(uint256 value_, uint8 decimals_) internal pure returns(uint256 value, uint8 decimals) {
        if(value_ == 0) {
            return (0, 0);
        }
        while(decimals_ > 0 && value_ % 10 == 0) {
            decimals_--;
            value_ = value_/10;
        }
        return (value_, decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint32(uint32 value_, uint8 decimals_) internal pure returns(uint32 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint32(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint8(uint8 value_, uint8 decimals_) internal pure returns(uint8 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint8(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number(Number_uint256 memory number) internal pure returns(Number_uint256 memory) {
        (uint256 value, uint8 decimals) = cleanFromTrailingZeros(number.value, number.decimals);
        return Number_uint256(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint32(Number_uint32 memory number) internal pure returns(Number_uint32 memory) {
        (uint32 value, uint8 decimals) = cleanFromTrailingZeros_uint32(number.value, number.decimals);
        return Number_uint32(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint8(Number_uint8 memory number) internal pure returns(Number_uint8 memory) {
        (uint8 value, uint8 decimals) = cleanFromTrailingZeros_uint8(number.value, number.decimals);
        return Number_uint8(value, decimals);
    }

    function align_Number(Decimals.Number_uint256 memory number1_, Decimals.Number_uint256 memory number2_) internal pure
    returns (Decimals.Number_uint256 memory number1, Decimals.Number_uint256 memory number2) {
        if(number1_.decimals < number2_.decimals) {
            number1_.value = number1_.value * 10**(number2_.decimals - number1_.decimals);
            number1_.decimals = number2_.decimals;
        }
        else if(number2_.decimals < number1_.decimals) {
            number2_.value = number2_.value * 10**(number1_.decimals - number2_.decimals);
            number2_.decimals = number1_.decimals;
        }
        return (number1_, number2_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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