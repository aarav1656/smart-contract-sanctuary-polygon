/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT

/** 
 *  SourceUnit: [email protected]
*/


pragma solidity 0.8.13;

/** @dev Struct that stores the list of all products
    * @param buyer the buyer 
    * @param seller the seller 
    * @param token purchase token
    * @param amount amount of token purchase 
    * @param id id specified to the product 
    * @param startSales when sale start
    * @param endSales when sale end
    * @param isCompleted status of transaction
    */
struct AllProducts{
    address buyer;
    address seller;
    uint96 id; 
    address token;
    bool    isCompleted;
    bool 	isOnDispute;
    uint256 amount;
    uint128 startSales;
    uint128 endSales;
}

/** @dev Struct For Dispute Ranks Requirements
    * @param NFTaddresses Addresses of the NFT token contract 
    * @param mustHaveNFTID IDs of the NFTs token 
    * @param pairTokenID pid on masterChef Contract that disputer must staked must have
    * @param pairTokenAmountToStake The Minimum amount of s `pair` to stake
    * @param merchantFeeToRaiseDispute The fee for a merchant to raise a dispute
    * @param buyerFeeToRaiseDisputeNoDecimal The fee for a buyer to raise a dispute without decimal
    */	
struct DisputeRaised {
    address who;
    address against;
    address token;
    bool 	isResolved;
    uint256 amount;
    uint256 payment;
    uint256 time;
    uint128 votesCommence;
    uint128 votesEnded;
}

/** @dev Struct For Counsil Members
    * @param forBuyer How many Tips the buyer has accumulated 
    * @param forSeller How many Tips the seller has accumulated 
    * @param tippers arrays of tippers
    * @param whoITip arrays of whom Tippers tips
    */	
struct MembersTips {
    uint256 forBuyer;
    uint256 forSeller;
    address qualified;
    address[] joinedCouncilMembers;
    address[] tippers;
    address[] whoITip;
}

struct Store {
    bool    isResolving;
    bool isLocked;
    uint256 joined;
    uint256 totalVotes;
    uint256 wrongVote;
    uint256 tFee4WrongVotes;
}

struct TokenDetails {
    uint256 tradeAmount;
    bytes   rank;
    address token;
    uint256 sellerFee;
    uint256 buyerFee;
}


// "Rigel's Protocol: Balance of 'from' is less than amount to sell"
error Insufficient_Balalnce();
// "Rigel's Protocol: Unable to withdraw from 'from' address"
error Withdrawal_denied();
// "Rigel's Protocol: Token Specify is not valid with ID"
error Invalid_Token();
// "Rigel's Protocol: Transaction has been completed "
error Transaction_completed();
// "Rigel's Protocol: This Product is on dispute"
error Product_On_Dispute();
// "Rigel's Protocol: Amount Secify for gas is less than min fee"
error Low_Gas();
// "Rigel's Protocol: A party to a dispute cant join Voting session"
error not_Permitted();
// "Rigel's Protocol: Patience is a Virtue"
error Be_Patient();
// "Rigel's Protocol: Permission Denied, address not qualified for this `rank`"
error Permission_Denied();
// "Rigel's Protocol: Dispute already raised for this Product"
error Dispute_Raised();
// "Rigel's Protocol: You have No Right to vote "
error Voting_Denied();
// "Rigel's Protocol: Invalid Product ID"
error Invalid_ProductID();
// "Rigel's Protocol: You don't have permission to raise a dispute for `who` "
error cannot_Raise_Dispute();
// "Rigel's Protocol: msg.sender has already voted for this `product ID` "
error Already_voted();
// "Rigel's Protocol: `who` is not a participant"
error Not_a_Participant();
// "Rigel's Protocol: Dispute on this product doesn't Exist"
error No_Dispute();
// "Rigel's Protocol: Max amount of require Tip Met."
error Tip_Met_Max_Amt();
// "Rigel's Protocol: Minimum Council Members require for this vote not met"
error More_Members_Needed();
// "Rigel's Protocol: Unable to withdraw gasFee from 'from' address"
error Unable_To_Withdraw();
// "Balance of contract is less than inPut amount"
error Low_Contract_Balance();
// funds are currently locked
error currentlyLocked();
// "Rigel's Protocol: Permission Denied, address not qualified for this `rank`"
error Not_Qualify();
// "Rigel's Protocol: Votes already stated"
error VoteCommence();
// "Rigel's Protocol: Permission Denied, due to numbers completed numbers of council members require for the dispute"
error CompletedMember();
// "Rigel's Protocol: Length of arg invalid"
error invalidLength();
// "Rigel's Protocol: input amount can't be greater than amount of token to sell"
error invalidAmount();

error accountBlacklisted();


/**
 * @dev silently declare mapping for the products on Rigel's Protocol Decentralized P2P network
 */
interface events {
   /**
     * @dev Emitted when the Buyer makes a call to Lock Merchant Funds, is set by
     * a call to {makeBuyPurchase}. `value` is the new allowance.
     */
    event Buy(address indexed merchant, address indexed buyer, address token, uint256 amount, uint96 productID, uint256 time);

    /**
     * @dev Emitted when the Merchant Comfirmed that they have recieved their Funds, is set by
     * a call to {makeSellPurchase}. `value` is the new allowance.
     */
    event Sell(address indexed buyer, address indexed merchant, address token, uint256 amount, uint96 productID, uint256 time);

    /**
     * @dev Emitted when Dispute is raise.
     */
    event dispute(address indexed who, address indexed against, address token, uint256 amount, uint256 ID, uint256 time);

    /**
     * @dev Emitted when a vote has been raise.
     */
    event councilVote(address indexed councilMember, address indexed who, uint96 productID, uint256 indexedOfID, uint256 time);

    event SetStakeAddr(address indexed rgpStake);

    event SetWhiteList(address[] indexed accounts, bool status);

    event ResolveVotes( uint96 productID, uint256 indexedOf, address indexed who);

    event JoinDispute( address indexed account, uint96 productID, uint256 indexedOf);

    event CancelDebt(uint256 amount, address indexed account);

    event CastVote(uint96 productID, uint256 indexedOf, address who);

    event rewards(address token, address[] indexed memmber, uint256 amount, uint256 withdrawTime);

    event MultipleAdmin(address[] indexed _adminAddress, bool status);

    event EmmergencyWithdrawalOfETH(uint256 amount);

    event WithdrawTokenFromContract(address indexed tokenAddress, uint256 _amount, address indexed _receiver);
    
    event newAssetAdded(address indexed newAsset, uint256 seller, uint256 buyer);
    event delist(address indexed removed);
}

interface IStakeRIgel {

    function getMyRank(address account) external view returns(uint256);

    function getLockPeriodData() external view returns(uint256, uint256);

    function getSetsBadgeForMerchant(bytes memory _badge) external view returns(
        bytes  memory   Rank,
        bytes  memory   otherRank,
        address[] memory tokenAddresses,
        uint256[] memory requireURI,
        uint256 maxRequireJoin,
        uint256 wrongVotesFees
    );
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract Storage is events {
    mapping(uint96 => AllProducts) private allProducts;
    mapping(uint256 => MembersTips) private  tips;
    mapping(uint256 => DisputeRaised[]) private  raisedDispute;
    mapping(address => mapping(address => uint256)) private balance;
    mapping(address => Store) private store;
    mapping(address => bool)  private refWhitelist;
    mapping(address => bool) private isAdded;
    mapping(address => uint256) private buyer;
    mapping(address => uint256) private allTrade;
    mapping(address => uint256) private totalAmountTraded;
    mapping(address => uint256) private refSpecialWhitelist;
    mapping(address => bool) private hasBeenReferred;
    mapping(address => bool) private hasReferral;
    mapping(address => address) private whoIreferred;
    mapping(address => bool) private isBlacklisted;
    TokenDetails[] private tokenDetails;
    address[] private member;
    address private immutable RGP;
    address private immutable devAddress;
    address private RGPStake;
    uint256 private refWithoutWhitelistPercent;
    uint256 private beforeVotesStart;
    uint256 private votingEllapseTime;
    uint256 private maxNumbersofCouncils;
    uint256 private unlistedTokenFees;
    uint256 private sellerFee;
    uint96 private transactionID; // if 79228162514264337593543950335 require upgrade

    constructor(address _dev, address _rgp) {
        RGP = _rgp;
        devAddress = _dev;
    }

    modifier completed(uint96 productID) {
        if (allProducts[productID].isCompleted) revert Transaction_completed();
        _;
    }

    modifier invalid(uint96 productID) {
        if (productID > transactionID)  revert Invalid_ProductID(); 
        if (allProducts[productID].isOnDispute)  revert Dispute_Raised(); 
        _;
    }

    modifier checkAmount(uint96 productID, uint256 _howMuch) {
        if (_howMuch > allProducts[productID].amount) revert invalidAmount();
        _;
    }

    modifier noPermit(uint96 productID) {
        if (msg.sender == raisedDispute[productID][0].who)  revert not_Permitted();
        if (msg.sender == raisedDispute[productID][0].against)  revert not_Permitted();
        if(store[msg.sender].isLocked) revert currentlyLocked();
        _;
    }

    modifier checkBlacklist(address account) {
        if(isBlacklisted[account]) revert accountBlacklisted();
        _;
    }

    function _blacklisted(address account, bool status) internal {
        isBlacklisted[account] = status;
    }

    
    function _storeProducts(address purchaseToken, address from, uint256 amountInDecimals) internal returns(uint96) {
        uint96 id = transactionID++;
        allTrade[purchaseToken] += amountInDecimals;
        totalAmountTraded[purchaseToken] += amountInDecimals;
        allProducts[id] =  AllProducts(address(this), from, id, purchaseToken, false, false, amountInDecimals, uint128(block.timestamp), 0);
        return id;
    }

    /** @notice getPercentageForPointZeroes give access to be able to get the percentage of an `amount`
     * for values and supports decimal numbers too.
     * @dev Returns the `percentage` of the input `amount`.
     * @param amount The `amount` you want to get the percent from.
     * @param percentage The `percentage` you want to derive from the `amount` inputed
     * 1% = 10 why 100% = 1000
     */ 
    function getPercentageForPointZeroes(uint256 amount, uint256 percentage) internal pure returns(uint256) {
        return (amount * percentage) / 1000;
    }

    function _setDeployment(uint256 sellersFeeInRGP, uint256 unWhitelistedAddressReferralFeeInPercent, uint256 unListedTokenRewardPercent) internal {
        sellerFee = sellersFeeInRGP;
        refWithoutWhitelistPercent = unWhitelistedAddressReferralFeeInPercent;
        unlistedTokenFees = unListedTokenRewardPercent;
    }

    function _specialAddresses(address account, uint256 percentageValue, bool status) internal {
        refWhitelist[account] = status;
        refSpecialWhitelist[account] = percentageValue;
    }

    function _setBuyersFeeForAToken(address token, uint256 fee) internal {
        buyer[token] = fee;
    }

    function _getTokenFeeForBuyer(address _asset) internal view returns(uint256) {
        return buyer[_asset];
    }

    function _isAssestAdded(address _asset) internal view returns(bool _isAdded)  {
        _isAdded = isAdded[_asset];
    }

    function _getAssetPriceOnDispute(uint256 assetID) internal view returns(TokenDetails memory tD) {
        tD = tokenDetails[assetID];
    }

    function _sellerFeeDebit(address from) internal {
        _merchantChargesDibited(from, sellerFee);
    }

    function _merchantChargesDibited(address from, uint256 amount) internal {
        IERC20(RGP).transferFrom(from, address(this), amount); 
    }

    function _contractTransfer(address token, address user, uint256 amount) internal {
        IERC20(token).transfer(user, amount); 
    }


    function _setTokenPrice(uint256 _trade, bytes memory _ranks, address _asset, uint256 _sellerFee, uint256 buyesFee) internal {
        TokenDetails memory tD = TokenDetails(_trade, _ranks, _asset, _sellerFee, buyesFee);
        tokenDetails.push(tD);
        isAdded[_asset] = true;
    }

    function _delistAsset(uint256 assetID) internal returns(address) {
        isAdded[tokenDetails[assetID].token] = false;
        return tokenDetails[assetID].token;
    }

    function _getGas(IERC20 purchaseToken, uint256 _howMuch) internal view returns(uint256 _gas, uint256 rem) {
        // AllProducts memory all = allProducts[productID];
        uint256 subGas;
        // uint256 amount = (all.amount);
        uint256 gas = buyer[address(purchaseToken)];
        uint256 remnant;
        if (gas == 0) {
            subGas = getPercentageForPointZeroes(_howMuch,unlistedTokenFees);
            remnant = _howMuch - subGas;
        } else {
            remnant =  _howMuch - gas;
            subGas = gas; //_howMuch - remnant;
        }
        return(subGas, remnant);
    }

    function _isForBuyerOrSeller(uint96 productID, address who) internal  returns(bool forBuyer){
        if (allProducts[productID].seller == who) {
            forBuyer = false;
        } else  {        
            allProducts[productID].buyer = who;        
            forBuyer = true;
        }
        allProducts[productID].isOnDispute = true;
    }

    function _getDisputeFees(uint256 _amountBeenTraded, address token) internal view returns(
        bytes memory rank, 
        uint256 buyersDisputeFee, 
        uint256 sellerDisputeFee, 
        uint256 wrongVote) {
        uint256 lent = tokenDetails.length;
        for (uint256 i; i < lent;) {
            TokenDetails memory tD = tokenDetails[i];
            (
                ,,, ,, uint256 wVote
            ) = IStakeRIgel(RGPStake).getSetsBadgeForMerchant(tD.rank);
            if (_amountBeenTraded <= tD.tradeAmount && tD.token == token) {
                buyersDisputeFee = tD.buyerFee;
                sellerDisputeFee = tD.sellerFee;
                rank = tD.rank;
                wrongVote = wVote;   
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function _sortRewards(address from, address referral) internal {
        address getWhoReferredSeller = whoIreferred[from];
        uint256 _s_seller = sellerFee;
        uint256 refShare = getPercentageForPointZeroes(_s_seller, refWithoutWhitelistPercent);
        _settleBuyReferralRewards(_s_seller, refShare, from, referral, getWhoReferredSeller);
        
        if (getWhoReferredSeller != address(0)) {            
            _contractTransfer(RGP, getWhoReferredSeller, refShare);
        }
    }


    function _settleBuyReferralRewards(uint256 s_seller, uint256 isRefRew, address from,  address referral, address getWhoReferredReferral) internal {
        uint256 refShare;  
        if (referral != address(0)) {
            hasBeenReferred[referral] = true;
            whoIreferred[referral] = from;
            if(!refWhitelist[referral]) {
                refShare = getPercentageForPointZeroes(s_seller, refWithoutWhitelistPercent);
                _contractTransfer(RGP, referral, refShare);  
            } else {
                uint256 specialReferral = refSpecialWhitelist[referral];
                refShare = getPercentageForPointZeroes(s_seller, specialReferral);
                _contractTransfer(RGP, referral, refShare); 
                
            }
        }
        if (getWhoReferredReferral != address(0)) {
            devReward(RGP, (s_seller - (refShare + isRefRew)));
            _contractTransfer(RGP, devAddress, (s_seller - (refShare + isRefRew))); 
        } else {_contractTransfer(RGP, devAddress, (s_seller - (refShare)));  }
        
    }

    function _transferAndEmit(uint96 productID, address to, uint256 remnant,uint256 subGas) internal {
        address s_token = allProducts[productID].token;
        _contractTransfer(s_token, to, remnant);
        emit Buy(to, allProducts[productID].seller, s_token, subGas, productID, block.timestamp);
    }


    function _check(uint96 productID, address purchaseToken) internal view {
        if (purchaseToken != allProducts[productID].token)  revert Invalid_Token();
        if (allProducts[productID].isOnDispute)  revert Product_On_Dispute(); 
    }

    function devReward(address token, uint256 amount) internal {
        _contractTransfer(token, devAddress, amount); 
    }

    function _updateBuy(uint96 productID, uint256 _howMuch, address to) internal {
        uint256 tradingAmount = allProducts[productID].amount;
        tradingAmount -= _howMuch;
        tradingAmount == 0 ? allProducts[productID].isCompleted = true : allProducts[productID].isCompleted = false ;
        tradingAmount == 0 ? allProducts[productID].endSales = uint128(block.timestamp) : 0;

        allProducts[productID].amount = tradingAmount;
        allProducts[productID].buyer = to;
    }

    function _settleSellReferralRewards(IERC20 purchaseToken, uint256 subGas, address to,  address referral) internal {
        uint256 refShare; 
        address getWhoReferredBuyer = whoIreferred[to];

        uint256 isRefRew = getPercentageForPointZeroes(subGas, refWithoutWhitelistPercent);
        if (referral != address(0)) {
            hasBeenReferred[referral] = true;
            whoIreferred[referral] = to;
            if(!refWhitelist[referral]) {
                refShare = isRefRew;
                _contractTransfer(address(purchaseToken), referral, refShare);  
            } else {
                uint256 specialReferral = refSpecialWhitelist[referral];
                refShare = getPercentageForPointZeroes(subGas, specialReferral);
                _contractTransfer(address(purchaseToken), referral, refShare);                 
            }
        }
        if (getWhoReferredBuyer != address(0)) {
            _contractTransfer(address(purchaseToken), getWhoReferredBuyer, isRefRew);
            devReward(address(purchaseToken), (subGas - (refShare + isRefRew)));
        } else {
            devReward(address(purchaseToken), (subGas - refShare));
        }        
    }

    function _returnAllProducts(uint96 productID) internal view returns(AllProducts memory all) {
        all = allProducts[productID];
    }

    // Dispute section

    function _whenBuyersIsOnDispute(uint96 productID) internal {
        address s_token = allProducts[productID].token;
        address who = allProducts[productID].buyer;
        address _seller = allProducts[productID].seller;
        uint256 s_amount = allProducts[productID].amount;
        (,uint256 buyersDisputeFee, ,)= _getDisputeFees( s_amount, s_token); 

        allProducts[productID].amount = (s_amount - buyersDisputeFee);
        _isOnDispute(
            who, 
            _seller, 
            s_token, 
            productID, 
            allProducts[productID].amount, 
            buyersDisputeFee, 
            beforeVotesStart
        );
        emit dispute(who, _seller, s_token, s_amount, productID, block.timestamp);
    }

    function _sellerIsOnDispute(uint96 productID) internal {
        address s_token = allProducts[productID].token;
        address who = allProducts[productID].seller;
        address _buyer = allProducts[productID].buyer;
        uint256 s_amount = allProducts[productID].amount;
        (,, uint256 sellerDisputeFee,)= _getDisputeFees( s_amount, s_token); 

        _merchantChargesDibited(who, sellerDisputeFee); 
        _isOnDispute(
            who, 
            _buyer, 
            s_token, 
            productID, 
            s_amount, 
            sellerDisputeFee, 
            beforeVotesStart
        );
        emit dispute(who, _buyer, s_token, s_amount, productID, block.timestamp);
    }

    function _checkIfAccountHasJoined(uint96 productID) internal view {
        bool hasJoined;
        uint256 lent = tips[productID].joinedCouncilMembers.length;
        for(uint256 i; i < lent; ) {
            address joined = tips[productID].joinedCouncilMembers[i];
            if (msg.sender == joined) {
                hasJoined = true;
                break;
            }
            unchecked {
                i++;
            }
        }
        if(hasJoined) revert not_Permitted();
    }

    function _userRankQualification(uint96 productID) internal view {
        (
            uint256 _max
        ) = IStakeRIgel(RGPStake).getMyRank(msg.sender);

        if(_max < allProducts[productID].amount) revert Not_Qualify();    
    }

    
    function _updateAndEmit(uint96 productID) internal {
        uint256 lent =  tips[productID].joinedCouncilMembers.length;
        if (lent == maxNumbersofCouncils) {
            uint128 commence = raisedDispute[productID][0].votesCommence;
            if (block.timestamp < uint256(commence))  revert CompletedMember();
            if (block.timestamp > uint256(commence))  revert VoteCommence();
        }

        store[msg.sender].isResolving = true;
        store[msg.sender].joined ++;
        tips[productID].joinedCouncilMembers.push(msg.sender);

        if (lent== maxNumbersofCouncils) { 
            raisedDispute[productID][0].votesEnded = uint128(block.timestamp + votingEllapseTime);
        }
        emit JoinDispute(msg.sender, productID, 0);
    }

    function _rightToVot(uint96 productID) internal view {
        bool haveRight;
        uint256 len = tips[productID].joinedCouncilMembers.length;
        for (uint256 i; i < len;) {
            address voters = tips[productID].joinedCouncilMembers[i];
            if (voters == msg.sender) {
                haveRight = true;
                break;                
            } else {haveRight = false;}
            unchecked {
                i++;
            }
        }         
        if (!haveRight)  revert Voting_Denied();
    }

    function _checkIfAccountHasVote(uint96 productID, address account) internal view returns(bool isTrue) {
        uint256 lent = tips[productID].tippers.length;
        for (uint256 i; i < lent; ) {
            address chk = tips[productID].tippers[i];
            if (account == chk) {
                isTrue = true;
                break;
            } else {
                isTrue = false;
            }
            unchecked {
                i++;
            }
        }
    }


    function _update(address user) internal {
        store[user].joined --;
        store[user].totalVotes ++;
        if (store[user].joined == 0) {
            store[user].isResolving = false;
        }
    }

    function _tip(uint96 productID, address who) internal {

        address s_token = allProducts[productID].token;       
        uint256 s_amount = allProducts[productID].amount;
        (, , , uint256 wrongVotesFees)= _getDisputeFees(s_amount, s_token);  

        require(who == raisedDispute[productID][0].who || who == raisedDispute[productID][0].against, "Rigel's Protocol: `who` is not a participant");

        address s_qualified = tips[productID].qualified;
        if (!allProducts[productID].isOnDispute)  revert No_Dispute(); 
        if (s_qualified != address(0))  revert Tip_Met_Max_Amt(); 
        if (raisedDispute[productID][0].votesEnded == 0)  revert Be_Patient();

        if (block.timestamp > uint256(raisedDispute[productID][0].votesCommence)) {
            if (tips[productID].joinedCouncilMembers.length < maxNumbersofCouncils)  revert More_Members_Needed();              
        }
        _updateTipForBuyerAndSeller(productID, who);

        _chkLockStatus();
        uint256 _payment = raisedDispute[productID][0].payment;

        if(s_qualified != address(0)) {  
            _contractTransfer(s_token, s_qualified, s_amount);  
            uint256 _devReward = (_payment* 20) / 100;
            uint256 sharableRewards = (_payment * 80) / 100;

            devReward(s_token, _devReward);

            _l(productID, sharableRewards, wrongVotesFees, s_token, s_qualified);
        }
        emit councilVote(msg.sender, who, productID, 0, block.timestamp);
    }


    function _chkLockStatus() internal {
        (uint256 tLockCheck, uint256 pLockCheck) = _lockPeriod();
        if (store[msg.sender].totalVotes >= tLockCheck) {
            if (store[msg.sender].wrongVote >= pLockCheck) {
                store[msg.sender].isLocked = true;
                store[msg.sender].totalVotes = 0;
                store[msg.sender].wrongVote = 0;
            }else {
                store[msg.sender].totalVotes = 0;
                store[msg.sender].wrongVote = 0;
            }
        }
    }


    function _lockPeriod() internal view returns(uint256 tLockCheck, uint256 pLockCheck) {
        (tLockCheck, pLockCheck) = IStakeRIgel(RGPStake).getLockPeriodData();
    }

    function _l(uint96 productID, uint256 amountShared, uint256 fee,address token, address who) internal {       
        (address[] memory qua, address[] memory lst) = _cShare(productID, who);
        uint256 lent = qua.length;
        for (uint256 i; i < lent; ) {
            address cons = qua[i];
            if (cons != address(0)) {       
                member.push(cons); 
            }
            unchecked {
                i++;
            }
        }
        uint256 mem = member.length;
        for (uint256 j; j < mem; ) {
            uint256 forEach = amountShared / mem;
            address consM = member[j];
            _contractTransfer(token, consM, forEach); 
            emit rewards(token,member , amountShared, block.timestamp);
            unchecked {
                j++;
            }                
        }
        delete member;
        uint256 lstLength = lst.length;
        for (uint256 x; x < lstLength;) {
            address ls = lst[x];
            if (ls != address(0)) {
                store[ls].tFee4WrongVotes += fee;
                store[ls].wrongVote ++;
            }
            unchecked {
                x++;
            } 
        }
        allProducts[productID].isCompleted = true;
        allProducts[productID].isOnDispute = false;
        allProducts[productID].endSales = uint128(block.timestamp);

    }

    function _cShare(uint256 productID, address who) internal view returns(address[] memory, address[] memory) {
        uint256 lenWho = tips[productID].whoITip.length;      
        address[] memory won = new address[](lenWho);
        address[] memory lost = new address[](lenWho);
        if (who != address(0)) {
            for (uint256 i; i < lenWho; ) {
                address l = tips[productID].whoITip[i];
                address c = tips[productID].tippers[i];
                if (l == who) {
                    won[i] = c;
                }
                 else if(l != who) {
                    lost[i] = c;
                }
                unchecked {
                    i++;
                }
            }
        }
        return (won, lost);        
    }

    function _updateTipForBuyerAndSeller(uint96 productID, address who) private {
        tips[productID].tippers.push(msg.sender);
        tips[productID].whoITip.push(who);
        if (who == allProducts[productID].buyer) {
            tips[productID].forBuyer++;
        }
        if (who == allProducts[productID].seller) {
            tips[productID].forSeller++;
        }
        uint256 div2 = tips[productID].joinedCouncilMembers.length / 2;
        if (tips[productID].forBuyer >= (div2 + 1)) {
            tips[productID].qualified = who;
        } 
        if(tips[productID].forSeller >= (div2 + 1)) {
            tips[productID].qualified = who;
        }
    }

    function _cancelDebt(uint256 amount) internal {        
        
        store[msg.sender].tFee4WrongVotes -= amount;
        if (store[msg.sender].tFee4WrongVotes == 0) {
            store[msg.sender].isLocked = false;
        }
        emit CancelDebt(amount, msg.sender);
    }

    function _buyerAndSellerConsensus(uint96 productID,address who) internal {
        bool _who = _isForBuyerOrSeller(productID, who);
        allProducts[productID].isCompleted = true;
        allProducts[productID].endSales = uint128(block.timestamp);
        
        uint256 len = tips[productID].joinedCouncilMembers.length;
        uint256 s_amount = allProducts[productID].amount;
        address s_token = allProducts[productID].token;

        (, uint256 buyersDisputeFee, uint256 sellerDisputeFee, ) = _getDisputeFees(s_amount, s_token);
        if (_who) {
            allProducts[productID].amount = (s_amount - buyersDisputeFee);
            uint256 forEach = buyersDisputeFee / len;
            if (len > 0) {
                for (uint256 i; i < len; ){
                    address voters = tips[productID].joinedCouncilMembers[i];
                    _update(voters);
                    _contractTransfer(s_token, voters, forEach);
                    unchecked {
                        i++;
                    }
                }
            }   
            _contractTransfer(s_token, who, allProducts[productID].amount);  
            emit rewards(s_token, tips[productID].joinedCouncilMembers , buyersDisputeFee, block.timestamp);         
        } else {
            _merchantChargesDibited(who, sellerDisputeFee);  
            uint256 forEach = sellerDisputeFee / len;           
            if (len > 0) {
                for (uint256 i; i < len; ) {
                    address voters = tips[productID].joinedCouncilMembers[i];  
                    _update(voters);
                    _contractTransfer(RGP, voters, forEach);   
                    unchecked {
                        i++;
                    }     
                } 
            } 
            _contractTransfer(s_token, who, allProducts[productID].amount);  
            emit rewards(RGP, tips[productID].joinedCouncilMembers , sellerDisputeFee, block.timestamp);
        }
        allProducts[productID].isCompleted = true;
        allProducts[productID].isOnDispute = false;
        allProducts[productID].endSales = uint128(block.timestamp);
        raisedDispute[productID][0].isResolved = true;

        emit ResolveVotes(productID, 0, who);
    }

    function _setStake(address rgpStake) internal {
        RGPStake = rgpStake;
    }
    
    function _stakeManagement(uint256 beforeVoteCommence, uint256 voteEllapseTime, uint256 numOfCouncils) internal {
        beforeVotesStart = beforeVoteCommence;
        votingEllapseTime = voteEllapseTime;
        maxNumbersofCouncils = numOfCouncils;
    }
    

    function _isOnDispute(
        address who, 
        address against, 
        address token, 
        uint256 productID,  
        uint256 amount, 
        uint256 fee,
        uint256 _join
    ) internal {
        DisputeRaised memory rDispute = DisputeRaised(
            who, against, token, false, amount, fee , block.timestamp, uint128(block.timestamp + _join), 0
        );
        raisedDispute[productID].push(rDispute);
    }

    function viewStateManagement() external view returns(uint256 , uint256 , uint256 ) {
        return (
            beforeVotesStart,
            votingEllapseTime,
            maxNumbersofCouncils
        );
    }

    function disputesPersonnel(address account ) external view returns(Store memory userInfo) {
        userInfo = store[account];
    }

    function getTotalUserLock(address account ) external view returns(bool, bool) {
        return(store[account].isResolving, store[account].isLocked);
    }

    function productDetails(uint96 productID) external view returns (AllProducts memory all) {
        all = allProducts[productID];
    }

    function getDisputeRaised(uint256 productID) external view returns(DisputeRaised memory disputeRaise) {
        disputeRaise = raisedDispute[productID][0];
    }

    function getWhoIsleading(uint256 productID) external view returns(MembersTips memory tip) {
        tip = tips[productID];
    }

    function rigelToken() external view returns(address) {        
        return RGP;
    }

    function dev() external view returns(address) {
        return devAddress;
    }

    function stakesContractAddress() external view returns(address) {
        return RGPStake;
    }

    function getSetRefPercent(address account) external view returns(uint256) {
        return refSpecialWhitelist[account];
    }

    function getAmountTradedOn(address _asset) external view returns(uint256) {
        return allTrade[_asset];
    }


    function getUnlistedTokenChargePercent() external view returns(uint256) {
        return unlistedTokenFees;
    }

    /**
     * @dev Returns `uint256` the amount of RGP Merchant will pay through {makeBuyPurchase}.
     */
    function getFees() external view returns (uint256 _sellerFee, uint256 unwhitelistRef) {
        _sellerFee = sellerFee;
        unwhitelistRef = refWithoutWhitelistPercent;
    }

    function lengthOfListedAsset() external view returns(uint256) {
        return tokenDetails.length;
    }

    function getTransactionID() external view returns (uint96) {
        return transactionID;
    }

    function blacklistStatus(address account) external view returns(bool) {
        return isBlacklisted[account];
    }
}


abstract contract Ownable {

    mapping(address => bool) private isAdminAddress;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {        
        isAdminAddress[_msgSender()] = true;
        _owner = _msgSender();
    }

    function _adminSet(address _admin, bool status) internal {
        isAdminAddress[_admin] = status;
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

    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()], "Access Denied: Need Admin Accessibility");
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


abstract contract Rigelp2pPriceSet is Ownable, Storage {

    constructor (address _dev, address rgpToken) Storage(_dev, rgpToken) {}


    function setAssetPriceForDisputes(
        address _asset, 
        uint256[] calldata _tadeAmount, 
        bytes[] calldata _ranks, 
        uint256[] calldata sellerFee, 
        uint256[] calldata buyerFee
    ) external onlyOwner {
        uint256 lent = _tadeAmount.length;
        if (
            lent != _ranks.length &&
            sellerFee.length != buyerFee.length
        ) revert invalidLength();
        for (uint256 i; i < lent; ) {
            _setTokenPrice(_tadeAmount[i], _ranks[i], _asset, sellerFee[i], buyerFee[i]);
            emit newAssetAdded(_asset, sellerFee[i], buyerFee[i]);
            unchecked {
                i++;
            }
        }
    }

    function setFeeForBuyers(address[] memory asset, uint256[] memory fee) external onlyOwner {
        uint256 lent = asset.length;
        if (lent != fee.length) revert invalidLength();
        for (uint256 i; i < lent; ) {
            _setBuyersFeeForAToken(asset[i], fee[i]);
            unchecked {
                i++;    
            }
        }
    }

    //
    function setDeploy(
        uint256 sellersFeeInRGP, 
        uint256 unWhitelistedAddressReferralFeeInPercent, 
        uint256 unListedTokenRewardPercent) 
        external onlyOwner {        
        _setDeployment(sellersFeeInRGP,unWhitelistedAddressReferralFeeInPercent,unListedTokenRewardPercent);
    }

    /** @notice setWhiteList. Enabling the owner to be able to set and reset whitelisting accounts status.
	 * @param accounts arrays of `accounts` to update their whitelisting `status`
	 * @param status the status could be true or false.
     * Function signature e43f696e  =>  setWhiteList(address[],bool)   
     */
    function setSpecialWhiteList(address[] memory accounts, uint256[] memory percent, bool status) external onlyOwner {
        uint256 len = accounts.length;
        if (len != percent.length) revert invalidLength();
        for(uint256 i = 0; i < len; ) {
            _specialAddresses(accounts[i], percent[i], status);
            emit SetWhiteList(accounts, status);
            unchecked {
                i++;
            }
        } 
    }



    function delistAsset(uint256[] memory _assets) external onlyOwner {
        uint256 lent = _assets.length;
        for (uint256 i; i < lent; ) {
            address asset = _delistAsset(_assets[i]);
            emit delist(asset);
            unchecked {
                i++;
            }
        }
    }

    function getBatchTokenFeeForBuyer(address[] memory _asset) external view returns(uint256[] memory _fee) {
        _fee = new uint256[](_asset.length);
        for ( uint256 i; i < _asset.length; ) {
            _fee[i] = _getTokenFeeForBuyer(_asset[i]);
            unchecked {
                i++;
            }
        }
        return _fee;
    }

    function getAssetPriceOnDispute(uint256[] memory assetID) external view returns(TokenDetails[] memory tD, bool[] memory) {
        uint256 _assetLength = assetID.length;
        tD = new TokenDetails[](_assetLength);
        bool[] memory _added = new bool[](_assetLength);
        for (uint256 i; i < _assetLength;) {
            tD[i] = _getAssetPriceOnDispute(assetID[i]);
            _added[i] = _isAssestAdded(tD[i].token);
            unchecked {
                i++;
            }
        }
        return (tD, _added);
    }

}

contract RigelDecentralizedP2PSystem is Rigelp2pPriceSet {
    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //
    
    /** @notice Constructor. Links with RigelDecentralizedP2PSystem contract
     * @param _dev dev address;
     * @param rgpToken address of RGP token Contract;
    */
    constructor (address _dev, address rgpToken) Rigelp2pPriceSet(_dev, rgpToken) {}

    // ********************************* //
    // *** EXTERNAL WRITE FUNCTIONS *** //
    // ******************************* //
    
    /** @notice makeBuyPurchase access to a user
     * @param purchaseToken address of token contract address to check for approval
     * @param amount amount of the token to purchase by 'to' from 'from' not in decimal
     * @param from address of the seller
     * @param referral referral address
     */ 
    function makeSellOrder(IERC20 purchaseToken, uint256 amount, address from, address referral) external checkBlacklist(from) returns(uint256){   
        uint256 tokenBalance = purchaseToken.balanceOf(from);
        uint256 amountInDecimals = getAmountInTokenDecimal(purchaseToken, amount);
        if (tokenBalance < amountInDecimals)  revert Insufficient_Balalnce();
        _sellerFeeDebit(from);
        purchaseToken.transferFrom(from, address(this), amountInDecimals);
        _sortRewards(from, referral);
        uint96 id = _storeProducts(address(purchaseToken), from, amountInDecimals);
        emit Buy(from, address(this), address(purchaseToken), amountInDecimals, id, block.timestamp);
        return id;

    }

    // /** @dev grant access to a user for the sell of token specified.
    //  * @param purchaseToken address of token contract address to check for approval
    //  * @param from address of the seller
    //  * @param productID the product id
    //  */ 
    function completeBuyOrder(
        IERC20 purchaseToken,  
        uint96 productID, 
        address to, 
        uint256 _howMuch, 
        address referral
    ) 
        external 
        onlyAdmin
        completed(productID)
        checkAmount(productID,_howMuch)
        checkBlacklist(to)
    {
        _check(productID, address(purchaseToken));
        uint256 amountInDecimals = getAmountInTokenDecimal(purchaseToken, _howMuch);
        (uint256 subGas,uint256 remnant) = _getGas(purchaseToken, amountInDecimals);
        _updateBuy(productID, amountInDecimals, to);
        _settleSellReferralRewards(purchaseToken, subGas, to, referral);
        _transferAndEmit(productID, to, remnant, subGas);
    }

    function raiseDispute(uint96 productID, address who) external onlyAdmin completed(productID) invalid(productID) {        
        bool _who = _isForBuyerOrSeller(productID, who);
        if (_who) {
            _whenBuyersIsOnDispute(productID);
        } else {
            _sellerIsOnDispute(productID);
        }
    }

    function resolveVotes(uint96 productID, address who) external onlyAdmin {
        _buyerAndSellerConsensus(productID, who);
    }

    function joinDispute(uint96 productID) external completed(productID) noPermit(productID){

        _checkIfAccountHasJoined(productID);
           
        _userRankQualification(productID);
        
        _updateAndEmit(productID);
    }

    function cancelDebt(uint256 amount) external {       
        
        _merchantChargesDibited(_msgSender(), amount);

        _cancelDebt(amount);

    }

    function castVote(uint96 productID, address who) external {   
        _rightToVot(productID);

        if ((_checkIfAccountHasVote(productID, _msgSender()))) revert Already_voted(); 

        _update(_msgSender());       
        _tip(productID, who);
        emit CastVote(productID, 0, who);
    }

    function blackList(address account, bool status) external onlyOwner {
        _blacklisted(account, status);
    }

    // *************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************* //

    // ****************************** //
    // *** PUBLIC VIEW FUNCTIONS *** //
    // **************************** //
    function getDisputeFees(uint256 _amountBeenTraded, address token) public view returns(
        bytes memory rank, 
        uint256 buyersDisputeFee, 
        uint256 sellerDisputeFee, 
        uint256 wrongVote) {

        (rank, buyersDisputeFee, sellerDisputeFee, wrongVote) = _getDisputeFees(_amountBeenTraded, token);
    }

    function getAmountInTokenDecimal(IERC20 purchaseToken, uint256 amount) public view returns (uint256 tDecimals) {
        tDecimals = amount * 10**purchaseToken.decimals();
    }

    // ******************************** //
    // *** EXTERNAL VIEW FUNCTIONS *** //
    // ****************************** //

    function iVoted(uint96 productID, address account) external view returns(bool isTrue) {
        isTrue = _checkIfAccountHasVote(productID, account);
    }

    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        uint256 lent = _adminAddress.length;
        if (status == true) {
           for(uint256 i; i < lent; ) {
                _adminSet(_adminAddress[i], status);
                unchecked {
                    i++;
                }
            } 
            emit MultipleAdmin(_adminAddress, status);
        } else{
            for(uint256 i; i < lent; ) {
                _adminSet(_adminAddress[i], false);
                unchecked {
                    i++;
                }
            }
        }
        emit MultipleAdmin(_adminAddress, status);
    }

    /** @notice setStakeAddr. Enabling the owner to be able to reset sets fees for buyes and sellers
	 * @param rgpStake Updating the staking contract address by the owner.
     * Function signature a9e51d32  =>  setStakeAddr(address)  
     */
    function setStakeAddr(address rgpStake) external onlyOwner {
        _setStake(rgpStake);
        emit SetStakeAddr(rgpStake);
    }
    
    function stakeManagement(uint256 beforeVoteCommence, uint256 voteEllapseTime, uint256 numOfCouncils) external onlyOwner {
        _stakeManagement(beforeVoteCommence, voteEllapseTime,numOfCouncils);
    }

    receive() external payable{}

    function emmergencyWithdrawalOfETH(uint256 amount) external onlyOwner{
        payable(owner()).transfer(amount);
        emit EmmergencyWithdrawalOfETH(amount);
    }
}