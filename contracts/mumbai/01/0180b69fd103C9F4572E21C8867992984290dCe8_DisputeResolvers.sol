/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: MIT
// File: contracts/Interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

// File: contracts/Interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.12;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/Interfaces/IBetFoundationFactory.sol


pragma solidity >=0.6.12;

interface IBetFoundationFactory {
    function provideBetData(address betAddress_) external view returns(address,address,uint,bool,bool);
    function raiseDispute(address betAddress_) external returns(bool);
    function postDisputeProcess(address betAddress_) external returns(bool);
        function createBet(
        address parentBet_,
        address betId_,
        uint betTakerRequiredLiquidity_,
        uint betEndingTime_,
        uint tokenId_,
        uint totalBetOptions_,
        uint selectedOptionByUser_,
        uint tokenLiqidity_,
        uint lossSimulationPercentage_
    ) external payable returns (bool _status,address _betTrendSetter);
    function joinBet(
        address betAddress_,
        uint tokenLiqidity_,
        uint selectedOptionByUser_,
        uint tokenId_
    )
        external
        payable
        returns (bool);
    function withdrawLiquidity(address betAddress_) external payable returns (bool);
    function resolveBet(address betAddress_,uint finalOption_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,bool isCustomized_,bool lossSimulationFlag_) external returns(bool);
    function banBet(address betAddress_,bool lossSimulationFlag_) external returns(bool);
}
// File: contracts/Interfaces/IDisputeResolution.sol


pragma solidity >=0.6.12;

interface IDisputeResolution {
    function stake() external returns(bool);
    function withdraw() external returns(bool);
    function createDisputeRoom(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external returns (bool);
    function createDispute(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external returns(bool);
    function processVerdict(bytes32 hash_,bytes memory signature_,uint selectedVerdict_,address betAddress_) external returns(bool);   
    function brodcastFinalVerdict(address betAddress_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function adminResolution(address betAddress_,uint finalVerdictByAdmin_,address[] memory users_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function getUserStrike(address user_) external view returns(uint);
    function getJuryStrike(address user_) external view returns(uint);
    function getBetStatus(address betAddress_) external view returns(bool,bool);
    function forwardVerdict(address betAddress_) external view returns(uint);
    function adminResolutionForUnavailableEvidance(address betAddress_,uint finalVerdictByAdmin_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function getUserVoteStatus(address user_,address betAddress) external view returns (bool);
    function getJuryStatistics(address user_) external view returns (uint,uint,uint,bool);
    function getJuryVersion(address user_) external view returns (uint);
}
// File: contracts/Interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.6.12;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: contracts/Libraries/ProcessData.sol


pragma solidity >=0.6.12;




library ProcessData {
    
    function rsvExtracotr(bytes32 hash_,bytes memory sig_) public pure returns (address) {
        require(sig_.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");
        return recoverSigner(hash_, v, r, s);
    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns(address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }    

    function getProofStatus(bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,address betInitiator_,address betTaker_) public pure returns(bool _makerProof,bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = rsvExtracotr(hash_[0],maker_);
        a[1] = rsvExtracotr(hash_[1],taker_);
        for(uint i=0;i<a.length;i++) {
            if(a[i] == betInitiator_) {
                _makerProof = true;
            }
        }
        for(uint i=0;i<a.length;i++) {
            if(a[i] == betTaker_) {
                _takerProof = true;
            }
        }
    }

    function resolutionClearance(bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,address betInitiator,address betTaker) public pure returns(bool status_) {
        bool _makerProof;bool _takerProof;
        (_makerProof,_takerProof) =  getProofStatus(hash_,maker_,taker_,betInitiator,betTaker);
        if(_makerProof || _takerProof) status_ = true;
    }

    function swapping(address uniswapV2Router_,address tokenA_,address tokenB_) public view returns(uint) {
        //IERC20(tokenB_).approve(uniswapV2Router_,address(this).balance);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint[] memory amount = new uint[](2);
        amount = tokenA_ == 0x5B67676a984807a212b1c59eBFc9B3568a474F0a ? IUniswapV2Router02(uniswapV2Router_).getAmountsOut(address(this).balance,t) : IUniswapV2Router02(uniswapV2Router_).getAmountsOut(IERC20(tokenA_).balanceOf(address(this)),t);
        return amount[1];
    }

}
// File: contracts/Interfaces/IConfig.sol


pragma solidity >=0.6.12;

interface IConfig {

    function getAdmin() external view returns(address);
    function getAaveTimeThresold() external view returns(uint);
    function getBlacklistedAsset(address asset_) external view returns(bool);

    function setDisputeConfig(uint escrowAmount_,uint requirePaymentForJury_) external returns(bool);
    function getDisputeConfig() external view returns(uint,uint);

    function setWalletAddress(address developer_,address escrow_) external returns(bool);
    function getWalletAddress() external view returns(address,address);

    function getTokensPerStrike(uint strike_) external view returns(uint);
    function getJuryTokensShare(uint strike_,uint version_) external view returns(uint);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_,
        uint256 pool_distribution_amount_without_trendsetter_,
        uint256 burn_amount_without_trendsetter
    ) external returns(bool);

    function setAaveFeeConfig(
        uint aave_apy_bet_winner_distrubution_,
        uint aave_apy_bet_looser_distrubution_
    ) external returns(bool);

    function getFeeDeductionConfig() external view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,uint);

    function getAaveConfig() external view returns(uint,uint);
    
    function setAddresses(
        address lendingPoolAddressProvider_,
        address wethGateway_,
        address aWMATIC_,
        address aDAI_,
        address uniswapV2Factory,
        address uniswapV2Router
    )
        external
        returns (
            address,
            address,
            address,
            address
        );

    function getAddresses() external view returns(address,address,address,address,address,address);

    function setPairAddresses(address tokenA_,address tokenB_) external returns(bool);

    function getPairAddress(address tokenA_) external view returns(address,address);

    function getUniswapRouterAddress() external view returns(address);

    function getAaveRecovery() external view returns(address,address,address);


}
// File: contracts/Utils/Structs.sol


pragma solidity >=0.6.12;

contract Structs {

    struct BetDetail {
        address parentBet;
        address betInitiator;
        address betTaker;
        address winner;
        uint betTakerRequiredLiquidity;
        uint betStartingTime;
        uint betEndingTime;
        uint tokenId;
        uint winnerOption;
        bool isTaken;
        bool isWithdrawed;
        uint totalBetOptions;
        bool isDisputed;
        bool isDrawed;
        mapping(address => bool) userWithdrawalStatus;
        mapping(uint => address) selectedOptionByUser;
        mapping(address => uint) userLiquidity;
    }

    struct ReplicatedBet {
        address betTrendSetter;
        uint underlyingBetCounter;
        mapping(uint => address) underlyingBets;
    }

    struct DisputeRoom {
        address betCreator;
        address betTaker;
        uint totalOptions;
        uint finalOption;
        uint userStakeAmount;
        mapping (uint => address[]) selectedOptionByJury;
        mapping (uint => uint) optionWeight;
        mapping (address => bool) isVerdictProvided;
        bool isResolvedByAdmin;
        uint disputeCreatedAt;
        bool isResolved;
        uint jurySize;
        uint disputedOption;
        bool isCustomized;
        address disputeCreator;
    }

}

// File: contracts/Utils/Mappings.sol


pragma solidity >=0.6.12;


contract Mappings is Structs {
    mapping(uint => address) public bets;
    mapping(address => BetDetail) public betDetails;
    mapping(address => ReplicatedBet) public replicatedBets;
    mapping(address => bool) public betStatus;
    mapping(address => bool) public isTokenValid;
    mapping(address => DisputeRoom) public disputeRooms;
    mapping(address => uint) public userStrikes;
    mapping(address => uint) public juryStrike;
    mapping(address => uint) public lastWithdrawal;
    mapping(address => uint) public usersStake;
    mapping(address => uint) public userInitialStake;
    mapping(address => bool) public isActiveStaker;
    mapping(address => uint) public juryVersion; 
}

// File: contracts/MainContractBucket/DisputeResolver.sol


pragma solidity >=0.6.12;








contract DisputeResolvers is Mappings,IDisputeResolution {
    
    address internal admin;
    address internal config;
    address internal aggregator;
    address internal Factory;
    address internal dbethAddress;

    uint internal jurySize;

    constructor(address admin_,address config_,address aggregator_,address dbethAddress_) public {
        admin = admin_;
        config = config_;
        aggregator = aggregator_;
        jurySize = 3;
        dbethAddress = dbethAddress_;
    }

    function setFactory(address factory_) external returns(bool) {
        Factory = factory_;

        return true;
    }

    function getJuryVersion(address user_) external view override returns (uint) {
        return juryVersion[user_];
    }

    event DisputeRoomCreation(address indexed betAddress_);

    function stake() external override returns(bool) {
        require(juryStrike[tx.origin] < 4, "Strike Level Exceeds");
        if(juryVersion[tx.origin] == 0) juryVersion[tx.origin] += 1;
        uint amount;
        if(juryStrike[tx.origin] == 0) {
            (,amount) = IConfig(config).getDisputeConfig();
            // require(amount ==  lastWithdrawal[tx.origin],"Not Provided Enough Liquidity");
            usersStake[tx.origin] += amount;
            lastWithdrawal[tx.origin] = 0;   
            userInitialStake[tx.origin] = amount;
            IERC20(dbethAddress).transferFrom(tx.origin,address(this),amount); 
        } else {
            amount = lastWithdrawal[tx.origin];
            usersStake[tx.origin] += amount;
            lastWithdrawal[tx.origin] = 0;   
            IERC20(dbethAddress).transferFrom(tx.origin,address(this),amount); 
        }
        isActiveStaker[tx.origin] = true;

        return true;
    }

    function withdraw() external override returns(bool) {
        uint amount_ =  calculateStrikeAmount(tx.origin);
        lastWithdrawal[tx.origin] = userInitialStake[tx.origin] - amount_;

        IERC20(dbethAddress).transfer(tx.origin,lastWithdrawal[tx.origin]);  
        usersStake[tx.origin] = 0;
        isActiveStaker[tx.origin] = false;
        // IERC20(dbethAddress).transfer(admin,amount_); 

        return true;
    }

    function createDisputeRoom(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external override returns (bool) {
        require(disputeRooms[betAddress_].betCreator == address(0),"Already Raised Dispute");
        address betInitiator;address betTaker;uint totalBetOptions;
        (betInitiator,betTaker,totalBetOptions,,) = IBetFoundationFactory(Factory).provideBetData(betAddress_);
        require(userStrikes[tx.origin] < 5, "Strike Level Exceed");
        require(hash_.length >0 && signature_.length >0,"Not Provided Evidance");
        disputeRooms[betAddress_].betCreator = betInitiator; 
        disputeRooms[betAddress_].betTaker = betTaker;
        disputeRooms[betAddress_].totalOptions = totalBetOptions + 1;
        disputeRooms[betAddress_].disputeCreatedAt = block.timestamp;
        disputeRooms[betAddress_].disputedOption = disputedOption_;
        IBetFoundationFactory(Factory).raiseDispute(betAddress_);
        disputeRooms[betAddress_].isCustomized = true;
        disputeRooms[betAddress_].disputeCreator = tx.origin;

        emit DisputeRoomCreation(betAddress_);    

        return true;
    }


    function createDispute(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external override returns(bool) {
        require(disputeRooms[betAddress_].betCreator == address(0),"Already Raised Dispute");
        address betInitiator;address betTaker;uint totalBetOptions;
        (betInitiator,betTaker,totalBetOptions,,) = IBetFoundationFactory(Factory).provideBetData(betAddress_);
        // require(betTaker ==  tx.origin,"Only Bet Taker Can Raise Dispute");
        require(userStrikes[tx.origin] < 5, "Strike Level Exceed");
        require(hash_.length >0 && signature_.length >0,"Not Provided Evidance");
        disputeRooms[betAddress_].betCreator = betInitiator; 
        disputeRooms[betAddress_].betTaker = betTaker;
        disputeRooms[betAddress_].totalOptions = totalBetOptions + 1;
        //(uint escrowAmount,uint requirePaymentForRaiseDispute,uint requirePaymentForJury) = IConfig(config).getDisputeConfig();
        disputeRooms[betAddress_].userStakeAmount = IConfig(config).getTokensPerStrike(userStrikes[tx.origin]);
        disputeRooms[betAddress_].disputeCreatedAt = block.timestamp;
        disputeRooms[betAddress_].disputedOption = disputedOption_;
        IBetFoundationFactory(Factory).raiseDispute(betAddress_);
        disputeRooms[betAddress_].isCustomized = true;
        disputeRooms[betAddress_].disputeCreator = tx.origin;
        IERC20(dbethAddress).transferFrom(tx.origin,address(this),IConfig(config).getTokensPerStrike(userStrikes[tx.origin]));   

        emit DisputeRoomCreation(betAddress_);    

        return true;
    }

    function processVerdict(bytes32 hash_,bytes memory signature_,uint selectedVerdict_,address betAddress_) external override returns(bool) {
        require(juryStrike[tx.origin] < 4,"Strike Level Exceed");
        require(usersStake[tx.origin] > 0,"User Does Not Have Balance");
        require(!disputeRooms[betAddress_].isVerdictProvided[tx.origin],"Already Provided Verdict");
        require(ProcessData.rsvExtracotr(hash_,signature_) == tx.origin,"Signature Not Verified");
        disputeRooms[betAddress_].jurySize += 1;
        require(disputeRooms[betAddress_].jurySize <= jurySize,"Room Is Full");
        disputeRooms[betAddress_].selectedOptionByJury[selectedVerdict_].push(tx.origin);
        disputeRooms[betAddress_].optionWeight[selectedVerdict_] += 1;
        disputeRooms[betAddress_].isVerdictProvided[tx.origin] = true;
        
        return true;
    }

    function userStrikeManager(address betAddress_,bool _makerProof,bool _takerProof,uint _highestSelected) internal {
        if(disputeRooms[betAddress_].betCreator == disputeRooms[betAddress_].disputeCreator || !_makerProof) {
            if(disputeRooms[betAddress_].disputedOption != _highestSelected || !_makerProof) {
                userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            }
        } else if(disputeRooms[betAddress_].betTaker == disputeRooms[betAddress_].disputeCreator || !_takerProof) {
            bool maker_one;
            bool taker_one;
            bool taker_two;
            if(disputeRooms[betAddress_].disputedOption != _highestSelected) taker_one = true;
            if(disputeRooms[betAddress_].disputedOption == _highestSelected) maker_one = true;
            if(!_takerProof) taker_two = true;
            if(!_makerProof) maker_one = false;
            if(maker_one) userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            if(taker_one || taker_two) userStrikes[disputeRooms[betAddress_].betTaker] += 1;
        }
    }

    function brodcastFinalVerdict(address betAddress_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external override returns(bool) {
        require(jurySize == disputeRooms[betAddress_].jurySize,"Not Received Enough Votes");
        require(!disputeRooms[betAddress_].isResolved || !disputeRooms[betAddress_].isResolvedByAdmin,"This Bet Is Already Resolved");
        require(hash_.length >0,"Not Enough Evidance Provided");
        (uint _highestSelected,bool _isForAdmin) = calculateFinalVerdict(betAddress_);
        (bool _makerProof,bool _takerProof) = getProofStatus(hash_,maker_,taker_,betAddress_);
        if(!_makerProof && !_takerProof) _isForAdmin = true;
        require(!_isForAdmin,"Only Admin Can Resolve This Bet");
            disputeRooms[betAddress_].isResolved = true;
            disputeRooms[betAddress_].finalOption = _highestSelected;
            userStrikeManager(betAddress_,_makerProof,_takerProof,_highestSelected);
            if(_highestSelected == disputeRooms[betAddress_].disputedOption) {
                    if(disputeRooms[betAddress_].userStakeAmount > 0) IERC20(dbethAddress).transfer(disputeRooms[betAddress_].betTaker,disputeRooms[betAddress_].userStakeAmount);
                    // if(userStrikes[disputeRooms[betAddress_].betTaker] != 0) {
                    //     userStrikes[disputeRooms[betAddress_].betTaker] -= 1;
                    // }
                    //if(_makerProof) userStrikes[disputeRooms[betAddress_].betCreator] += 1;
                    IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
            } else {
                // if(userStrikes[disputeRooms[betAddress_].betCreator] != 0) {
                //     userStrikes[disputeRooms[betAddress_].betCreator] -= 1;
                // }
                //if(_takerProof) userStrikes[disputeRooms[betAddress_].betTaker] += 1;
                IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
            }
            uint escrowAmount;
            (escrowAmount,) = IConfig(config).getDisputeConfig();
            for(uint i=0;i<disputeRooms[betAddress_].selectedOptionByJury[_highestSelected].length;i++) {
                if(_highestSelected == disputeRooms[betAddress_].disputedOption) {
                    // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] != 0) {
                    //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] -= 1;
                    // }
                    address to = disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i];
                    uint value = escrowAmount/disputeRooms[betAddress_].selectedOptionByJury[_highestSelected].length;
                    IERC20(dbethAddress).transferFrom(admin,to,value);
                } else {
                    // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] != 0) {
                    //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] -= 1;
                    // }
                    if(disputeRooms[betAddress_].userStakeAmount > 0) {
                        address to = disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i];
                        uint value = disputeRooms[betAddress_].userStakeAmount/disputeRooms[betAddress_].selectedOptionByJury[_highestSelected].length;
                        IERC20(dbethAddress).transfer(to,value);
                    } else {
                        address to = disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i];
                        uint value = escrowAmount/disputeRooms[betAddress_].selectedOptionByJury[_highestSelected].length;
                        IERC20(dbethAddress).transferFrom(admin,to,value);
                    }
                }
            }
            for(uint i=0;i<disputeRooms[betAddress_].totalOptions;i++) {
                if(i != _highestSelected) {
                    for(uint j=0;j<disputeRooms[betAddress_].selectedOptionByJury[i].length;j++) {
                        //IERC20(dbethAddress).transfer(admin,calculateStrikeAmount(disputeRooms[betAddress_].selectedOptionByJury[i][j]));
                        address _temp = disputeRooms[betAddress_].selectedOptionByJury[i][j];
                        juryStrike[_temp] += 1;
                    }
                }
            }
        
        return true;
    }

    function getProofStatus(bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,address betAddress_) internal view returns(bool _makerProof,bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = ProcessData.rsvExtracotr(hash_[0],maker_);
        a[1] = ProcessData.rsvExtracotr(hash_[1],taker_);
        for(uint i=0;i<a.length;i++) {
            if(a[i] == disputeRooms[betAddress_].betCreator) {
                if(!_makerProof) _makerProof = true;
            }
        }
        for(uint i=0;i<a.length;i++) {
            if(a[i] == disputeRooms[betAddress_].betTaker) {
                if(!_takerProof) _takerProof = true;
            }
        }
    }

    function calculateStrikeAmount(address user_) internal view returns(uint) {
        uint amount;
        for(uint i=1;i<=juryStrike[user_];i++) {
            amount += (IConfig(config).getJuryTokensShare(i,juryVersion[tx.origin]) * userInitialStake[tx.origin]) / 1e2;
        }
        return (amount);
    }

    function calculateFinalVerdict(address betAddress_) internal view returns(uint _highestSelected,bool _isForAdmin) {
        uint _options = disputeRooms[betAddress_].totalOptions;
        uint256[] memory a = new uint[](_options);

        for(uint i=0;i<_options;i++) {
            a[i] = disputeRooms[betAddress_].optionWeight[i];
        }
        uint _temp;
        for(uint i=0;i<a.length;i++) {
            if(a[i] == 1) _temp +=1;
        }
        if(_temp == 3) {
            _isForAdmin = true;
        }  else {
            uint256 _highest;
            for(uint256 i=0;i<a.length;i++) {
                if(a[i] > _highest) {
                    _highest = a[i];
                }
            }
            for(uint i=0;i<a.length;i++) {
                if(a[i] == _highest) {
                    _highestSelected = i;
                }
            }
            if(_highestSelected == 3  || _highest == 1) {
                _isForAdmin = true;
            }
        }
    }

    function updateAdmin(address admin_) external returns(bool) {
        admin = admin_;

        return true;
    }

    function adminResolutionForUnavailableEvidance(address betAddress_,uint finalVerdictByAdmin_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external override returns(bool) {
        require(tx.origin == admin,"Caller Is Not Owner");
        disputeRooms[betAddress_].finalOption = finalVerdictByAdmin_;
        disputeRooms[betAddress_].isResolvedByAdmin = true;
        (bool _makerProof,bool _takerProof) = getProofStatus(hash_,maker_,taker_,betAddress_);
        if(!_makerProof) {
            userStrikes[disputeRooms[betAddress_].betCreator] += 1;
        } else if (! _takerProof) {
            userStrikes[disputeRooms[betAddress_].betTaker] += 1;
        }
        IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);

        return true;
    }

    function adminResolution(address betAddress_,uint finalVerdictByAdmin_,address[] memory users_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external override returns(bool) {
        require(tx.origin == admin,"Caller Is Not Owner");
        require(!disputeRooms[betAddress_].isResolved,"Already Resolved"); 
        disputeRooms[betAddress_].finalOption = finalVerdictByAdmin_;
        disputeRooms[betAddress_].isResolvedByAdmin = true;
        (bool _makerProof,bool _takerProof) = getProofStatus(hash_,maker_,taker_,betAddress_);
        userStrikeManager(betAddress_,_makerProof,_takerProof,finalVerdictByAdmin_);
        if(disputeRooms[betAddress_].disputedOption == finalVerdictByAdmin_) {
            // if(userStrikes[disputeRooms[betAddress_].betTaker] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betTaker] -= 1;
            // }
            //if(_makerProof) userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            if(disputeRooms[betAddress_].userStakeAmount > 0) IERC20(dbethAddress).transfer(disputeRooms[betAddress_].betTaker,disputeRooms[betAddress_].userStakeAmount);
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        } else {
            // if(userStrikes[disputeRooms[betAddress_].betCreator] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betCreator] -= 1;
            // }
            //if(_takerProof) userStrikes[disputeRooms[betAddress_].betTaker] += 1;
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        }
        uint escrowAmount;
        (escrowAmount,) = IConfig(config).getDisputeConfig();
        for(uint i=0;i<disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_].length;i++) {
            if(disputeRooms[betAddress_].disputedOption == finalVerdictByAdmin_) {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] != 0) {
                //         juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] -= 1;
                // }
                address to = disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i];
                uint value = escrowAmount/disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_].length;
                IERC20(dbethAddress).transferFrom(admin,to,value);
                // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
            } else {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] != 0) {
                //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] -= 1;
                // }
                if(disputeRooms[betAddress_].userStakeAmount > 0) {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i];
                    uint value = disputeRooms[betAddress_].userStakeAmount/disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_].length;
                    IERC20(dbethAddress).transfer(to,value);   
                    // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
                } else {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i];
                    uint value = escrowAmount/disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_].length;
                    IERC20(dbethAddress).transferFrom(admin,to,value);
                    // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
                }
            }
        }
        for(uint i=0;i<disputeRooms[betAddress_].totalOptions;i++) {
            if(i != finalVerdictByAdmin_) {
                for(uint j=0;j<disputeRooms[betAddress_].selectedOptionByJury[i].length;j++) {
                    //IERC20(dbethAddress).transfer(admin,calculateStrikeAmount(disputeRooms[betAddress_].selectedOptionByJury[i][j]));
                    address _temp = disputeRooms[betAddress_].selectedOptionByJury[i][j];
                    juryStrike[_temp] += 1;
                }
            }
        }
        for(uint i=0;i<users_.length;i++) {
            juryStrike[users_[i]] += 1;
        }

        return true;
    }

    function getUserStrike(address user_) external view override returns(uint) {
        return userStrikes[user_];
    }

    function getJuryStrike(address user_) external view override returns(uint) {
        return juryStrike[user_];
    }

    function getBetStatus(address betAddress_) external view override returns(bool,bool) {
        return (disputeRooms[betAddress_].isResolved,disputeRooms[betAddress_].isResolvedByAdmin);
    }

    function forwardVerdict(address betAddress_) external view override returns(uint) {
        return disputeRooms[betAddress_].finalOption;
    }

    function getUserVoteStatus(address user_,address betAddress) external view override returns (bool _status) {
        return disputeRooms[betAddress].isVerdictProvided[user_];
    }

    function getJuryStatistics(address user_) external view override returns (uint usersStake_,uint lastWithdrawal_,uint userInitialStake_,bool isActiveStaker_) {
        usersStake_ = usersStake[user_];
        lastWithdrawal_ = lastWithdrawal[user_];
        userInitialStake_ = userInitialStake[user_];
        isActiveStaker_ = isActiveStaker[user_];
    }

}