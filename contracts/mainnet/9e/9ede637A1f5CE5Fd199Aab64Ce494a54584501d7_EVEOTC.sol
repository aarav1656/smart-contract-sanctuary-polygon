/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);

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

/**
 * 
 * Stakes is an interest gain contract for ERC-20 tokens
 * 
 * assets is the ERC20 token
 * interest_rate: percentage rate
 * maturity is the time in seconds after which is safe to end the stake
 * penalization for ending a stake before maturity time
 * lower_amount is the minimum amount for creating a stake
 * 
 */
contract EVEOTCStakes is Owner, ReentrancyGuard {

    // token    
    IERC20 public asset;

    // stakes history
    struct Record {
        uint256 from;
        uint256 amount;
        bool active;
    }

    // contract parameters
    uint16 public interest_rate;    // Interest rate for users who lock funds

    // Users locked funds
    mapping(address => Record) public ledger;

    event StakeStart(address indexed user, uint256 value);
    event StakeEnd(address indexed user, uint256 value, uint256 interest);

    constructor(IERC20 _erc20, address _owner, uint16 _rate) Owner(_owner) {
        asset = _erc20;
        interest_rate = _rate;
    }
    
    function startLock(uint256 _value) external nonReentrant {
        require(!ledger[msg.sender].active, "The user already has locked funds");
        require(asset.transferFrom(msg.sender, address(this), _value));
        ledger[msg.sender] = Record(block.timestamp, _value, true);
        emit StakeStart(msg.sender, _value);
    }

    function endLock() external nonReentrant {

        require(ledger[msg.sender].active, "No locked funds found");
        
        uint256 _interest = get_gains(msg.sender);

        // check that the owner can pay interest before trying to pay
        if (asset.allowance(getOwner(), address(this)) >= _interest && asset.balanceOf(getOwner()) >= _interest) {
            require(asset.transferFrom(getOwner(), msg.sender, _interest));
        } else {
            _interest = 0;
        }

        require(asset.transfer(msg.sender, ledger[msg.sender].amount));
        ledger[msg.sender].amount = 0;
        ledger[msg.sender].active = false;
        emit StakeEnd(msg.sender, ledger[msg.sender].amount, _interest);

    }

    function stakingSet(IERC20 _asset, uint16 _rate) external isOwner {
        interest_rate = _rate;
        asset = _asset;
    }
    
    // calculate interest to the current date time
    function get_gains(address _address) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address].from;
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds * ledger[_address].amount * interest_rate / 100 / _year_seconds;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}

contract EVEOTCTokens is EVEOTCStakes {

    // Token Object for coins available in the system
    // This tokens are added by admins
    struct Token {
        address token;                  // the token address
        uint256 cmc_index;              // coinmarketcap api index
        address chanlink_aggregator;    // chainlink oracle
        uint256 manual_entry_price;     // price if set manually, minimum price has to be > 0
        uint256 last_update;            // last update
        uint256 last_price;             // last price
    }

    // Total set of tokens
    Token[] public tokens;
    uint256 public tokens_length;

    // the index of the token in the tokens array
    // the if the value is 0 means it does not exists, if the value is > 0 then the index is tokens_indexes[address] - 1
    mapping (address => uint256) public tokens_indexes;

    // system tokens list if they are enabled or not
    mapping (address => bool) public tokens_enabled;

    // Token Object for coins available in the system
    // This tokens are added by regular users
    struct UserToken {
        address token;              // the token address
        address owner;              // the first user that added this token
        uint256 manual_entry_price; // price if set manually
        uint256 last_update;        // last update
    }

    // Total set of user tokens
    UserToken[] public user_tokens;
    uint256 public user_tokens_length;

    // the index of the token in the tokens array
    // the if the value is 0 means it does not exists, if the value is > 0 then the index is tokens_indexes[address] - 1
    mapping (address => uint256) public user_tokens_indexes;

    // user tokens list if they are enabled or not
    mapping (address => bool) public user_tokens_enabled;

    address public oracle_api;

    event USDPriceCustomAPI(address token, uint256 price);
    event USDPriceAggregator(address token, uint256 price);
    event USDPriceManualEntry(address token, uint256 price);

    constructor(IERC20 _erc20, address _owner, uint16 _rate, address _oracle_api) 
        EVEOTCStakes(_erc20, _owner, _rate) {
        oracle_api = _oracle_api;
    }

    // set admin parameters
    function rootSet(address _oracle_api) external isOwner {
        oracle_api = _oracle_api;
    }

    /**
     *
     * Add or replace system tokens
     * 
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     *
     * Polygon aggregagtors
     * https://docs.chain.link/docs/matic-addresses/
     *   BNB Price: 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e
     *
     */
    function addToken(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) external isOwner {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        // find the position of the token in the tokens array
        uint256 _the_index = tokens_indexes[_token];

        // at this point _the_index is 0 (non existing token) or token existing in the tokens array in the position _the_index + 1

        // add the token if it doesn't exists, update if it does exists
        Token memory _the_token = Token(
            _token,
            _cmc_index,
            _aggregator,
            _price,
            block.timestamp,
            _price
        );

        if (_the_index == 0) {
            tokens.push(_the_token);
            _the_index = tokens.length - 1;

            // we keep track of the token index to avoid loops in arrays
            tokens_indexes[_token] = tokens.length; // we need to add 1 to index, because 0 means not existing token

            tokens_length = tokens.length;
        } else {
            _the_index--; // we reduce 1 to the index because we added 1 to the token index in the lines before
            tokens[_the_index] = _the_token;
        }

        // at this point _the_index is the real position in the tokens array 

        // enable token either way, found or not
        tokens_enabled[tokens[_the_index].token] = true;

        if (_price>0) {
            emit USDPriceManualEntry(_token, _price);
        }

    }

    // enable / disable tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeTokenStatus(uint256 _i, bool _enabled) external isOwner {
        tokens_enabled[tokens[_i].token] = _enabled;
    }

    // add user tokens
    // this tokens are added as not enabled, they need to be approved by an admin
    function addUserToken(address _token, uint256 _price) external {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        // find the position of the token in the tokens array
        uint256 _the_index = user_tokens_indexes[_token];

        // find if the token exists
        if (_the_index > 0) return;

        // add token if not exists
        UserToken memory _the_token = UserToken(_token, msg.sender, _price, block.timestamp);

        user_tokens.push(_the_token);
        user_tokens_length = user_tokens.length;

        // we keep track of the token index to avoid loops in arrays
        user_tokens_indexes[_token] = user_tokens.length; // we need to add 1 to index, because 0 means not existing token

    }

    function setUserTokenPrice(
        uint256 _i, 
        uint256 _manual_entry_price
    ) external {
        require(user_tokens[_i].owner == msg.sender, "OTC: caller is not the owner of the token");
        user_tokens[_i].manual_entry_price = _manual_entry_price;
        if (_manual_entry_price>0) {
            user_tokens[_i].last_update = block.timestamp;
            emit USDPriceManualEntry(user_tokens[_i].token, _manual_entry_price);
        }
    }

    // enable / disable user tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeUserTokenStatus(uint256 _i, bool _enabled) external isOwner {
        user_tokens_enabled[user_tokens[_i].token] = _enabled;
    }

    // change user owner of the user token
    // _i: tokens array position
    // _owner: new owner
    function changeUserTokenOwner(uint256 _i, address _owner) external isOwner {
        user_tokens[_i].owner = _owner;
    }

    // get usd price of any token and if it is a custom oracle price get update the price from oracle (spending LINK)
    // TODO: this should be internal or restricted
    function getUSDPrice(address _token) public returns (uint256 price) {

        // Get the index of the token in the system tokens array, if exists

        // Is a system token?
        if (tokens_enabled[_token]) {

            // find the index
            uint256 _token_index = tokens_indexes[_token];
            
            if (_token_index == 0) return 0; // 0 in tokens_indexes means not existing token

            // if _token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _token_index--;

            // the price reference is CMC? if so return the custom api oracle price
            if (tokens[_token_index].cmc_index > 0) {
                tokens[_token_index].last_price = getAPIUSDPrice(tokens[_token_index].cmc_index);
                tokens[_token_index].last_update = block.timestamp;
                emit USDPriceCustomAPI(_token, tokens[_token_index].last_price);
                return tokens[_token_index].last_price;
            // there is a chainlink oracle for this token? if so return the oracle price
            } else if (tokens[_token_index].chanlink_aggregator != address(0)) {
                tokens[_token_index].last_price = getAggregatorUSDPrice(tokens[_token_index].chanlink_aggregator);
                tokens[_token_index].last_update = block.timestamp;
                emit USDPriceAggregator(_token, tokens[_token_index].last_price);
                return tokens[_token_index].last_price;
            // default to manual entry price
            } else {
                return tokens[_token_index].manual_entry_price;
            }

        // is a user token?
        } else if (user_tokens_enabled[_token]) {

            // find the index
            uint256 _user_token_index = user_tokens_indexes[_token];

            if (_user_token_index == 0) return 0; // 0 in tokens_indexes means not existing token

            // if _user_token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _user_token_index--;

            return user_tokens[_user_token_index].manual_entry_price;

        // panic!
        } else {
            require(false, "OTC: Token is not enabled");
        }
    }

    // get usd price of a chainlink default oracle
    function getAggregatorUSDPrice(address _aggregator) internal view returns (uint256) {
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(_aggregator);
        (, int price,,,) = priceFeed.latestRoundData();
        // transform the price to the decimals based on the aggregator decimals function
        return uint(price) * 10 ** 8 / 10 ** IERC20(_aggregator).decimals();
    }

    // get usd price of a token using a custom api call
    function getAPIUSDPrice(uint256 _cmc_index) internal returns (uint256 price) {
        OTCChainLinkOracle oracleAPIContract = OTCChainLinkOracle(oracle_api);
        oracleAPIContract.refreshAPIUSDPrice(_cmc_index);
        return (oracleAPIContract.usd_prices(_cmc_index));
    }

}

contract EVEOTC is EVEOTCTokens {
    
    uint8 public commission;       // commission to pay by liquidity providers in the provided token

    /**
     * An offer can be a Smart Trade Offer or an Option Trade
     */
    struct Offer {
        bool smart_trade; // smart_trade = true its a Smart Trade Offer
                          // smart_trade = false its an Option Trade Offer
        address owner;  // the liquidity provider
        address from;   // token on sale
        address[] to;   // tokens receiveed
        uint256 available;  // original amount
        uint256 filled;     // amount sold
        uint256 surplus;    // excess paid by the seller to cover commission expenses
        uint256 filled_surplus;  // amount of the surplus paid in commissions
        uint256 price;      // Custom Price or Strike price
                            // If smart_trade is true, then, if > 0 is a custom price in USD, if 0 means a market price
                            // If smart_trade is false, then this is the strike price
        uint256 discount_or_premium;   // discount percentage or premium price
                                       // If smart_trade is true, then this is the discount percentage
                                       // If smart_trade is false, this is the premium price
        uint256 time; // vesting duration in days or expiration day if it is 
                      // If smart_trade is true, then this is the vesting duration in days
                      // If smart_trade is false, then this is an expiration date / time
        uint8 commission;   // commission at the moment of Offer creation
                            // commission settings in the smart contract may change over time, we make commission decisions based on the settings at the time of trade creation
        bool active;  // active or not
    }

    // all system offers, historical and active
    Offer[] public smart_trades;
    Offer[] public option_trades;

    // Owners
    mapping (address => uint256[]) public smart_trades_owners;
    mapping (address => uint256[]) public option_trades_owners;
    
    // Tokens on sale, address: token for sale
    mapping (address => uint256[]) public smart_trades_from;
    mapping (address => uint256[]) public option_trades_from;
    
    // Tokens for payment, address: token received
    mapping (address => uint256[]) public smart_trades_to;
    mapping (address => uint256[]) public option_trades_to;

    event NewOffer(
        bool smart_trade,
        address owner,
        address from,
        address[] to,
        uint256 available,
        uint256 surplus,
        uint256 price,
        uint8   discount_or_premium,
        uint256 time
    );

    // Offer buyer
    struct Purchase {
        uint256 offer_index;  // reference to Offer
        address from;       // token bought
        address to;         // token used for payment
        uint256 amount;     // amount bought
        uint256 withdrawn;  // amount withdrawn by buyer
        uint256 timestamp;
        address buyer;
    }

    // all purchases
    Purchase[] public smart_trades_purchases;
    Purchase[] public option_trades_purchases;

    // all buyers mapping to purchases index
    mapping (address => uint256[]) smart_trades_buyers;
    mapping (address => uint256[]) option_trades_buyers;

    // given an offer index returns all purchases indexes
    mapping (uint256 => uint256[]) smart_trades_offer_purchases;
    mapping (uint256 => uint256[]) option_trades_offer_purchases;
    //       ^ offer    ^ purchases
    
    event NewPurchase (
        uint256 purchase_index,
        uint256 offer_index,
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        address buyer
    );

    event PurchaseWithdraw (
        uint256 purchase_index,
        uint256 offer_index,
        uint256 withdrawn,
        address buyer
    );

    constructor(IERC20 _erc20, address _owner, uint16 _rate, uint8 _commission, address _oracle_api) 
        EVEOTCTokens(_erc20, _owner, _rate, _oracle_api) {
        commission = _commission;
    }

    function commissionSet(uint8 _commission) external isOwner {
        commission = _commission;
    }

    /**
     * Create a token sale offer for both Smart and Option trades
     * The seller needs to approve the amount "available" plus the commission
     * The record of the contracts will record only the available amount
     * the surplus will be stored for commission payment purposes
     */

    function addOffer(bool _smart_trade, address _from, address[] memory _to, uint256 _available, uint256 _price, uint8 _discount_or_premium, uint256 _time) external {

        require(_available > 0, "OTC: Offer has to be greater than 0");
        if (_smart_trade) {
            require(_discount_or_premium < 100, "OTC: discount has to be lower than 100");
        }

        // validate all tokens
        if (!tokens_enabled[address(_from)] || !user_tokens_enabled[address(_from)]) {
            require(false, "OTC: Token on sale is not enabled");
        }
        for (uint256 i; i < _to.length; i++) {
            if (!tokens_enabled[address(_to[i])] || !user_tokens_enabled[address(_to[i])]) {
                require(false, "OTC: Payment token is not enabled");
            }
        }

        // calculate the surplus from the seller to pay commissions
        uint256 _surplus = 0; // initialize surplus with 0
        uint8 _commission = 0; // initialize commission with 0
        // if the seller doesn't have a staking active then he must pay commissions
        if (!ledger[msg.sender].active) { 
            _surplus = _available * commission / 100;
            _commission = commission;
        }

        // lock the funds of the offer plus the surplus to pay commissions to admin
        require(IERC20(_from).transferFrom(msg.sender, address(this), _available + _surplus), "OTC: error transfering token funds");

        // process smart trades
        if (_smart_trade) {

            // add the offer to the record list
            smart_trades.push(Offer(_smart_trade, msg.sender, _from, _to, _available, 0, _surplus, 0, _price, _discount_or_premium, _time, _commission, true));

            // add the offer index to all mappings
            uint256 index = smart_trades.length - 1;
            smart_trades_from[_from].push(index);
            for (uint256 i; i < _to.length; i++) {
                smart_trades_to[_to[i]].push(index);
            }
            smart_trades_owners[msg.sender].push(index);

        // process option trades
        } else {

            // add the offer to the record list
            option_trades.push(Offer(_smart_trade, msg.sender, _from, _to, _available, 0, _surplus, 0, _price, _discount_or_premium, _time, _commission, true));

            // add the offer index to all mappings
            uint256 index = option_trades.length - 1;
            option_trades_from[_from].push(index);
            for (uint256 i; i < _to.length; i++) {
                option_trades_to[_to[i]].push(index);
            }
            option_trades_owners[msg.sender].push(index);

        }

        emit NewOffer( _smart_trade, msg.sender, _from, _to, _available, _surplus, _price, _discount_or_premium, _time);

    }

    /**
     * A customer can buy a smart trade
     *     index: index in the smart_trades array
     *     to: address of the token used for payment
     *     amount: to buy, must be previously approved
     */
    function buySmartTrade(uint256 _index, address _to, uint256 _amount) external nonReentrant {

        // validate that this is an active smart trade
        require(smart_trades[_index].active, "OTC: Smart Trade is not active");
        
        // validate that this token is valid
        bool token_found = false;
        for (uint256 i; i < smart_trades[_index].to.length; i++) {
            if (smart_trades[_index].to[i] == _to) {
                token_found = true;
                break;
            }
        }
        require(token_found, "OTC: token not found in the selected offer");

        // validate that this amount is under the limits available of the offer
        require(smart_trades[_index].available - smart_trades[_index].filled <= _amount, "OTC: not enough amount in the offer");

        // get the price of the offer and calculate the payment amount in the payment token

        // it is a custom price in USD?
        uint256 sell_token_price = 0;
        if (smart_trades[_index].price > 0) {
            // take this as a reference price of the selling token
            sell_token_price = smart_trades[_index].price;
        // it is not a custom price?
        } else {
            // get the price in USD of the selling soken
            sell_token_price = getUSDPrice(smart_trades[_index].from);
        }

        // get the payment token price
        uint256 pay_token_price = getUSDPrice(_to);

        /**
         * calculate the payment amount
         * 
         * ETH price: 1500$ => 150000000000
         * - 10%:     1350$ => 135000000000
         * Price of ETH in $ with 8 decimals divided by price of BTC in $ with 8 decimals:
         *      135000000000 / 2000000000000 = 0,0675 BTC
         * BTC with 6 decimals:
         *  0,0675 * 10 ** 6 = 6750000 BTC
         */ 

        // uint256 sell_token_discount_price = sell_token_price * (1 - (smart_trades[_index].discount_or_premium / 100));

        uint256 sell_token_discount_price = sell_token_price - ((sell_token_price * smart_trades[_index].discount_or_premium) / 100);
        //                                  1500             - ((1500             * 10                                       / 100)) 
        //                                  1500             - ((15000                                                       / 100)) 
        //                                  1500             - 150
        //                                  1350
        //                                  ==> 135000000000

        uint256 total_payment = (sell_token_discount_price * 10 ** IERC20(_to).decimals()) / pay_token_price;
        //                      (135000000000              * 10 ** 6                    ) / 2000000000000;
        //                      (135000000000              * 1000000                    ) / 2000000000000;
        //                      135000000000000000                                        / 2000000000000;
        //                      67500
        //                      ==> 0,0675

        // The buyer pays 100% of the price in the selected token to the offer owner
        require(IERC20(_to).transferFrom(msg.sender, smart_trades[_index].owner, total_payment), "OTC: error doing the payment");

        // If the seller has to pay commissions, pay in the token being sold
        // the seller pays the commission based on the commission set at the moment of transaction
        // this is to avoid liquidity errors in case the admin changes the commission in the middle
        uint256 _surplus = _amount * smart_trades[_index].commission / 100;
        if (_surplus > 0) {
            require(IERC20(smart_trades[_index].from).transferFrom(address(this), getOwner(), _surplus), "OTC: error paying commissions to owner");
        }

        // The buyer got assigned the amount bought
        smart_trades_purchases.push(Purchase(_index, smart_trades[_index].from, _to, _amount, 0, block.timestamp, msg.sender));

        // the smart trade filled amount is updated, the funds are reserved        
        smart_trades[_index].filled += _amount;

        uint256 smart_trades_purchases_index = smart_trades_purchases.length - 1;

        // update contract indexes:
        smart_trades_buyers[msg.sender].push(smart_trades_purchases_index);
        smart_trades_offer_purchases[_index].push(smart_trades_purchases_index);

        emit NewPurchase (
            smart_trades_purchases_index,
            _index,
            smart_trades[_index].from, 
            _to, 
            _amount, 
            block.timestamp, 
            msg.sender
        );

    }

    /**
     * return the maximum amount of tokens a buyer can withdraw at the moment from a smart trade
     */
    function getPurchasedWithdrawableTokens(uint256 _purchased_index) public view returns(uint256 _amount) {

        // elapsed: get the number of seconds elapsed since the purchase
        uint256 elapsed = block.timestamp - smart_trades_purchases[_purchased_index].timestamp;

        // time: get the number of seconds of the vesting
        // smart_trades[smart_trades_purchases[_purchased_index].offer_index].time;

        // if elapsed time is greater than the time of vesting, get the maximum time of vesting as the elapsed time
        if (elapsed > smart_trades[smart_trades_purchases[_purchased_index].offer_index].time) {
            elapsed = smart_trades[smart_trades_purchases[_purchased_index].offer_index].time;
        }

        // amount available: elapsed * amount bought / time 
        uint256 available = elapsed * smart_trades_purchases[_purchased_index].amount / smart_trades[smart_trades_purchases[_purchased_index].offer_index].time;

        // minus already withdrawn
        return available - smart_trades_purchases[_purchased_index].withdrawn;

    }

    /**
     * withdraw tokens bought in smart trades (by buyer), it withdraw the available vesting amount
     */
    function getPurchasedTokens(uint256 _purchased_index) external nonReentrant {
        
        // validate that the purchase belongs to sender
        require(smart_trades_purchases[_purchased_index].buyer == msg.sender, "OTC: caller is not the buyer");

        // validate that the amount to withdraw is greater than 0
        uint256 available_to_withdraw = getPurchasedWithdrawableTokens(_purchased_index);
        require(available_to_withdraw > 0, "OTC: there are no more funds to withdraw");

        // withdraw tokens
        require(IERC20(smart_trades_purchases[_purchased_index].from).transferFrom(address(this), msg.sender, available_to_withdraw), "OTC: error doing the withdraw");

        // update amount withdrawn
        smart_trades_purchases[_purchased_index].withdrawn += available_to_withdraw;

    }

    // TODO: remove smart trade offer, an owner can deactivate the offer and withdraw remaining funds?
    // really ^ ?

    // TODO: what happen with smart trades not withdrawn after vesting time?

    // TODO: buyOptionTrade: a buyer buys with option trade

    // TODO: completeOptionTrade: a buyer finish the payment and receive the tokens

    // TODO: remove option trade offer, an owner can deactivate the offer and withdraw remaining funds

    // TODO: what happen with unfinished trade offers after expiring time?

}

abstract contract OTCChainLinkOracle {
    mapping(uint256 => uint256) public usd_prices;
    mapping(uint256 => uint256) public usd_prices_last;
    function refreshAPIUSDPrice(uint256 _cmc_index) public {}
}