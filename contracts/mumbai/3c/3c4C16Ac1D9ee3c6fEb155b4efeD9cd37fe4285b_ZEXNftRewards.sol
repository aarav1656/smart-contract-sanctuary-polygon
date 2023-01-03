/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

// File: contracts\interfaces\UniswapRouterInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface UniswapRouterInterface{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// File: contracts\interfaces\TokenInterface.sol

pragma solidity 0.8.11;

interface TokenInterface{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\interfaces\NftInterface.sol

pragma solidity 0.8.11;

interface NftInterface{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterface.sol

pragma solidity 0.8.11;

interface VaultInterface{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
}

// File: contracts\interfaces\PairsStorageInterface.sol

pragma solidity 0.8.11;

interface PairsStorageInterface{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosDai(uint) external view returns(uint);
}

// File: contracts\interfaces\StorageInterface.sol






pragma solidity 0.8.11;

interface StorageInterface{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterface);
    function token() external view returns(TokenInterface);
    function linkErc677() external view returns(TokenInterface);
    function tokenDaiRouter() external view returns(UniswapRouterInterface);
    function priceAggregator() external view returns(AggregatorInterface);
    function vault() external view returns(VaultInterface);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterface);
}

interface AggregatorInterface{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterface);
    function nftRewards() external view returns(NftRewardsInterface);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

interface NftRewardsInterface{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterface.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// File: contracts\ZEXNftRewards.sol


pragma solidity 0.8.11;

contract ZEXNftRewards {

    // Contracts (constant)
    StorageInterface constant storageT = StorageInterface(0xaee4d11a16B2bc65EDD6416Fb626EB404a6D65BD);

    // Params (constant)
    uint constant ROUND_LENGTH = 50;

    // Params (adjustable)
    uint public triggerTimeout = 5;     // blocks
    uint public sameBlockLimit = 10;    // bots

    uint public firstP = 40;            // %
    uint public sameBlockP = 20;        // %
    uint public poolP = 40;             // %

    // Custom data types
    struct TriggeredLimit{ address first; address[] sameBlock; uint block; }
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterface.LimitOrder order; }
    
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }

    // State
    uint public currentOrder = 1;                                           // current order in round
    uint public currentRound;                                               // current round (1 round = 50 orders)

    mapping(uint => uint) public roundTokens;                               // total token rewards for a round
    mapping(address => mapping(uint => uint)) public roundOrdersToClaim;    // orders to claim from a round (out of 50)

    mapping(address => uint) public tokensToClaim;                          // rewards other than pool (first & same block)
    
    mapping(
        address => mapping(
            uint => mapping(
                uint => mapping(
                    StorageInterface.LimitOrder => TriggeredLimit
                )
            )
        )
    ) public triggeredLimits;   // limits being triggered

    mapping(address => mapping(uint => mapping(uint => OpenLimitOrderType))) public openLimitOrderTypes;

    // Statistics
    mapping(address => uint) public tokensClaimed; // 1e18
    uint public tokensClaimedTotal; // 1e18

    // Events
    event NumberUpdated(string name, uint value);
    event PercentagesUpdated(uint firstP, uint sameBlockP, uint poolP);

    event TriggeredFirst(TriggeredLimitId id, address bot);
    event TriggeredSameBlock(TriggeredLimitId id, address bot);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(TriggeredLimitId id, address first, uint sameBlockCount, uint reward);
    
    event PoolTokensClaimed(address bot, uint fromRound, uint toRound, uint tokens);
    event TokensClaimed(address bot, uint tokens);

    constructor() { }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier onlyTrading(){ require(msg.sender == storageT.trading(), "TRADING_ONLY"); _; }
    modifier onlyCallbacks(){ require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY"); _; }

    // Manage params
    function updateTriggerTimeout(uint _triggerTimeout) external onlyGov{
        require(_triggerTimeout >= 5, "LESS_THAN_5");
        triggerTimeout = _triggerTimeout;
        emit NumberUpdated("triggerTimeout", _triggerTimeout);
    }
    function updateSameBlockLimit(uint _sameBlockLimit) external onlyGov{
        require(_sameBlockLimit >= 5, "LESS_THAN_5");
        sameBlockLimit = _sameBlockLimit;
        emit NumberUpdated("sameBlockLimit", _sameBlockLimit);
    }
    function updatePercentages(uint _firstP, uint _sameBlockP, uint _poolP) external onlyGov{
        require(_firstP + _sameBlockP + _poolP == 100, "SUM_NOT_100");

        firstP = _firstP;
        sameBlockP = _sameBlockP;
        poolP = _poolP;

        emit PercentagesUpdated(_firstP, _sameBlockP, _poolP);
    }

    // Triggers
    function storeFirstToTrigger(TriggeredLimitId calldata _id, address _bot) external onlyTrading{
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        t.first = _bot;
        delete t.sameBlock;
        t.block = block.number;

        emit TriggeredFirst(_id, _bot);
    }
    function storeTriggerSameBlock(TriggeredLimitId calldata _id, address _bot) external onlyTrading{
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        
        require(t.block == block.number, "TOO_LATE");
        require(t.sameBlock.length < sameBlockLimit, "SAME_BLOCK_LIMIT");
        
        t.sameBlock.push(_bot);
        
        emit TriggeredSameBlock(_id, _bot);
    }
    function unregisterTrigger(TriggeredLimitId calldata _id) external onlyCallbacks{
        delete triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        emit TriggerUnregistered(_id);
    }

    // Distribute rewards
    function distributeNftReward(TriggeredLimitId calldata _id, uint _reward) external onlyCallbacks{
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        require(t.block > 0, "NOT_TRIGGERED");

        tokensToClaim[t.first] += _reward * firstP / 100;

        if(t.sameBlock.length > 0){
            uint sameBlockReward = _reward * sameBlockP / t.sameBlock.length / 100;
            for(uint i = 0; i < t.sameBlock.length; i++){
                tokensToClaim[t.sameBlock[i]] += sameBlockReward;
            }
        }

        roundTokens[currentRound] += _reward * poolP / 100;
        roundOrdersToClaim[t.first][currentRound] ++;

        if(currentOrder == ROUND_LENGTH){
            currentOrder = 1;
            currentRound ++;
        }else{
            currentOrder ++;
        }

        emit TriggerRewarded(_id, t.first, t.sameBlock.length, _reward);
    }

    // Claim rewards
    function claimPoolTokens(uint _fromRound, uint _toRound) external{
        require(_toRound >= _fromRound, "TO_BEFORE_FROM");
        require(_toRound < currentRound, "TOO_EARLY");

        uint tokens;

        for(uint i = _fromRound; i <= _toRound; i++){
            tokens += roundOrdersToClaim[msg.sender][i]*roundTokens[i]/ROUND_LENGTH;
            roundOrdersToClaim[msg.sender][i] = 0;
        }

        require(tokens > 0, "NOTHING_TO_CLAIM");
        storageT.handleTokens(msg.sender, tokens, true);

        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;
        
        emit PoolTokensClaimed(msg.sender, _fromRound, _toRound, tokens);
    }
    function claimTokens() external{
        uint tokens = tokensToClaim[msg.sender];
        require(tokens > 0, "NOTHING_TO_CLAIM");

        tokensToClaim[msg.sender] = 0;
        storageT.handleTokens(msg.sender, tokens, true);

        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;

        emit TokensClaimed(msg.sender, tokens);
    }

    // Manage open limit order types
    function setOpenLimitOrderType(address _trader, uint _pairIndex, uint _index, OpenLimitOrderType _type) external onlyTrading{
        openLimitOrderTypes[_trader][_pairIndex][_index] = _type;
    }

    // Getters
    function triggered(TriggeredLimitId calldata _id) external view returns(bool){
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        return t.block > 0;
    }
    function timedOut(TriggeredLimitId calldata _id) external view returns(bool){
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        return t.block > 0 && block.number - t.block >= triggerTimeout;
    }
    function sameBlockTriggers(TriggeredLimitId calldata _id) external view returns(address[] memory){
        return triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order].sameBlock;
    }
}