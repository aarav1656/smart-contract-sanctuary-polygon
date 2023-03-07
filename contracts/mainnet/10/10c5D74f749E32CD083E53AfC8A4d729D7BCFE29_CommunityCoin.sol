// SPDX-License-Identifier: UNLICENSED
/**
*****************
TEMPLATE CONTRACT
*****************
Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.
To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.
Copyright (c) Intercoin Inc. All rights reserved.
ALLOWED USAGE.
Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.
Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:
DISCLAIMERS AND DISCLOSURES.
Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.
Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.
Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.
INDEMNIFICATION.
Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.
NO WARRANTY.
THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 
LIMITATION OF LIABILITY. 
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.
TRADEMARKS.
This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.
LINK REQUIREMENTS.
Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:
"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."
STAKING OR SPENDING REQUIREMENTS.
In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.
CUSTOM ARRANGEMENTS.
Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.
ENTIRE AGREEMENT
This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.
SUCCESSORS AND ASSIGNS
This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.
ARBITRATION
All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
pragma solidity ^0.8.11;
//import "./interfaces/IHook.sol"; exists in PoolStakesLib
import "./interfaces/ITaxes.sol";
import "./interfaces/IDonationRewards.sol";

import "./interfaces/ICommunityCoin.sol";
import "./interfaces/ICommunityStakingPool.sol";

import "./interfaces/ICommunityStakingPoolFactory.sol";
//import "./interfaces/IStructs.sol"; exists in ICommunityCoin
import "./RolesManagement.sol";

//import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@artman325/community/contracts/interfaces/ICommunity.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

import "./libs/PoolStakesLib.sol";

//import "hardhat/console.sol";

contract CommunityCoin is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    CostManagerHelperERC2771Support,
    ICommunityCoin,
    RolesManagement,
    ERC777Upgradeable,
    IERC777RecipientUpgradeable
{
    //using MinimumsLib for MinimumsLib.UserStruct;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint64 internal constant LOCKUP_INTERVAL = 1 days;//24 * 60 * 60; // day in seconds
    uint64 internal constant LOCKUP_BONUS_INTERVAL = 52000 weeks;//1000 * 365 * 24 * 60 * 60; // 1000 years in seconds
    uint64 public constant FRACTION = 100000; // fractions are expressed as portions of this

    uint64 public constant MAX_REDEEM_TARIFF = 10000; //10%*FRACTION = 0.1 * 100000 = 10000
    uint64 public constant MAX_UNSTAKE_TARIFF = 10000; //10%*FRACTION = 0.1 * 100000 = 10000

    // max constants used in BeforeTransfer
    uint64 public constant MAX_TAX = 10000; //10%*FRACTION = 0.1 * 100000 = 10000
    uint64 public constant MAX_BOOST = 10000; //10%*FRACTION = 0.1 * 100000 = 10000

    address public taxHook;

    uint64 public redeemTariff;
    uint64 public unstakeTariff;

    address public hook; // hook used to bonus calculation
    address public donationRewardsHook; // donation hook rewards

    ICommunityStakingPoolFactory public instanceManagment; // ICommunityStakingPoolFactory

    uint256 internal discountSensitivity;

    // uint256 internal totalUnstakeable;
    // uint256 internal totalRedeemable;
    // // it's how tokens will store in pools. without bonuses.
    // // means totalReserves = SUM(pools.totalSupply)
    // uint256 internal totalReserves;
    IStructs.Total internal total;

    //      instance
    mapping(address => InstanceStruct) internal _instances;

    //bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // Constants for shifts
    uint8 internal constant OPERATION_SHIFT_BITS = 240; // 256 - 16

    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS = 0x1;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS_BONUS = 0x2;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS_BY_INVITE = 0x3;
    uint8 internal constant OPERATION_ADD_TO_CIRCULATION = 0x4;
    uint8 internal constant OPERATION_REMOVE_FROM_CIRCULATION = 0x5;
    uint8 internal constant OPERATION_PRODUCE = 0x6;
    uint8 internal constant OPERATION_PRODUCE_ERC20 = 0x7;
    uint8 internal constant OPERATION_UNSTAKE = 0x8;
    uint8 internal constant OPERATION_REDEEM = 0x9;
    uint8 internal constant OPERATION_GRANT_ROLE = 0xA;
    uint8 internal constant OPERATION_REVOKE_ROLE = 0xB;
    uint8 internal constant OPERATION_CLAIM = 0xC;
    uint8 internal constant OPERATION_SET_TRUSTEDFORWARDER = 0xD;
    uint8 internal constant OPERATION_SET_TRANSFER_OWNERSHIP = 0xE;
    uint8 internal constant OPERATION_TRANSFER_HOOK = 0xF;

    //      users
    mapping(address => UserData) internal users;

    bool flagHookTransferReentrant;
    bool flagBurnUnstakeRedeem;
    modifier proceedBurnUnstakeRedeem() {
        flagBurnUnstakeRedeem = true;
        _;
        flagBurnUnstakeRedeem = false;
    }
    event RewardGranted(address indexed token, address indexed account, uint256 amount);
    event Staked(address indexed account, uint256 amount, uint256 priceBeforeStake);

    event MaxTaxExceeded();
    event MaxBoostExceeded();

    /**
     * @notice initializing method. called by factory
     * @param tokenName internal token name 
     * @param tokenSymbol internal token symbol.
     * @param impl address of StakingPool implementation. usual it's `${tradedToken}c`
     * @param hook_ address of contract implemented IHook interface and used to calculation bonus tokens amount
     * @param stakingPoolFactory address of contract that managed and cloned pools
     * @param discountSensitivity_ discountSensitivity value that manage amount tokens in redeem process. multiplied by `FRACTION`(10**5 by default)
     * @param communitySettings tuple of IStructs.CommunitySettings. fractionBy, addressCommunity, roles, etc
     * @param costManager_ costManager address
     * @param producedBy_ address that produced instance by factory
     * @custom:calledby StakingFactory contract
     * @custom:shortd initializing contract. called by StakingFactory contract
     */
    function initialize(
        string calldata tokenName,
        string calldata tokenSymbol,
        address impl,
        address hook_,
        address stakingPoolFactory,
        uint256 discountSensitivity_,
        IStructs.CommunitySettings calldata communitySettings,
        address costManager_,
        address producedBy_
    ) external virtual override initializer {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);

        __Ownable_init();

        __ERC777_init(tokenName, tokenSymbol, (new address[](0)));

        __ReentrancyGuard_init();

        instanceManagment = ICommunityStakingPoolFactory(stakingPoolFactory); //new ICommunityStakingPoolFactory(impl);
        instanceManagment.initialize(impl);

        hook = hook_;
        if (hook_ != address(0)) {
            IHook(hook).setupCaller();
        }

        discountSensitivity = discountSensitivity_;

        __RolesManagement_init(communitySettings);

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        _accountForOperation(OPERATION_INITIALIZE << OPERATION_SHIFT_BITS, uint256(uint160(producedBy_)), 0);
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice method to distribute tokens after user stake. called externally only by pool contract
     * @param account address of user that tokens will mint for
     * @param amount token's amount
     * @param priceBeforeStake price that was before adding liquidity in pool
     * @custom:calledby staking-pool
     * @custom:shortd distribute wallet tokens
     */
    function issueWalletTokens(
        address account,
        uint256 amount,
        uint256 priceBeforeStake,
        uint256 donatedAmount
    ) external override {
        address instance = msg.sender; //here need a msg.sender as a real sender.

        // here need to know that is definetely StakingPool. because with EIP-2771 forwarder can call methods as StakingPool.
        ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo = instanceManagment.getInstanceInfoByPoolAddress(
            instance
        );

        require(instanceInfo.exists == true);

        // just call hook if setup before and that's all
        if (donatedAmount > 0 && donationRewardsHook != address(0)) {
            IDonationRewards(donationRewardsHook).onDonate(instanceInfo.tokenErc20, account, donatedAmount);
            return;
        }


        // calculate bonusAmount
        uint256 bonusAmount = (amount * instanceInfo.bonusTokenFraction) / FRACTION;

        // calculate invitedAmount
        address invitedBy = address(0);
        uint256 invitedAmount = 0;

        if (invitedByFraction != 0) {
            invitedBy = _invitedBy(account);

            if (invitedBy != address(0)) {
                //do invite comission calculation here
                invitedAmount = (amount * invitedByFraction) / FRACTION;
            }
        }

        //forward conversion( LP -> СС)
        amount = (amount * (instanceInfo.numerator)) / (instanceInfo.denominator);
        bonusAmount = (bonusAmount * (instanceInfo.numerator)) / (instanceInfo.denominator);
        invitedAmount = (invitedAmount * (instanceInfo.numerator)) / (instanceInfo.denominator);

        // means extra tokens should not to include into unstakeable and totalUnstakeable, but part of them will be increase totalRedeemable
        // also keep in mind that user can unstake only unstakeable[account].total which saved w/o bonusTokens, but minimums and mint with it.
        // it's provide to use such tokens like transfer but prevent unstake bonus in 1to1 after minimums expiring
        // amount += bonusAmount;

        _instances[instance]._instanceStaked += amount; // + bonusAmount + invitedAmount;

        _instances[instance].unstakeable[account] += amount;
        users[account].unstakeable += amount;

        // _instances[instance].unstakeableBonuses[account] += bonusAmount;
        // users[account].unstakeableBonuses += bonusAmount;
        _insertBonus(instance, account, bonusAmount);

        total.totalUnstakeable += amount;
        total.totalReserves += amount;

        if (invitedBy != address(0)) {
            // _instances[instance].unstakeableBonuses[invitedBy] += invitedAmount;
            // users[invitedBy].unstakeableBonuses += invitedAmount;
            _insertBonus(instance, invitedBy, invitedAmount);
        }

        // mint main part + bonus (@dev here bonus can be zero )
        _mint(account, (amount + bonusAmount), "", "");
        emit Staked(account, (amount + bonusAmount), priceBeforeStake);
        // locked main
        //users[account].tokensLocked._minimumsAdd(amount, instanceInfo.duration, LOCKUP_INTERVAL, false);
        MinimumsLib._minimumsAdd(users[account].tokensLocked, amount, instanceInfo.duration, LOCKUP_INTERVAL, false);

        _accountForOperation(
            OPERATION_ISSUE_WALLET_TOKENS << OPERATION_SHIFT_BITS,
            uint256(uint160(account)),
            amount + bonusAmount
        );

        // locked main
        if (bonusAmount > 0) {
            //users[account].tokensBonus._minimumsAdd(bonusAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            MinimumsLib._minimumsAdd(users[account].tokensBonus, bonusAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            _accountForOperation(
                OPERATION_ISSUE_WALLET_TOKENS_BONUS << OPERATION_SHIFT_BITS,
                uint256(uint160(account)),
                bonusAmount
            );
        }

        if (invitedBy != address(0)) {
            _mint(invitedBy, invitedAmount, "", "");
            //users[invitedBy].tokensBonus._minimumsAdd(invitedAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            MinimumsLib._minimumsAdd(users[invitedBy].tokensBonus, invitedAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            _accountForOperation(
                OPERATION_ISSUE_WALLET_TOKENS_BY_INVITE << OPERATION_SHIFT_BITS,
                uint256(uint160(invitedBy)),
                invitedAmount
            );
        }
    }

    /**
     * @notice method to adding tokens to circulation. called externally only by `CIRCULATION_ROLE`
     * @param account account that will obtain tokens
     * @param amount token's amount
     * @custom:calledby `CIRCULATION_ROLE`
     * @custom:shortd distribute tokens
     */
    function addToCirculation(address account, uint256 amount) external nonReentrant {

        _checkRole(circulationRoleId, _msgSender());

        _mint(account, amount, "", "");

        // dev note.
        // we shouldn't increase totalRedeemable. Circulations tokens raise inflations and calculated by (total-redeemable-unstakeable)
        //total.totalRedeemable += amount; 

        _accountForOperation(OPERATION_ADD_TO_CIRCULATION << OPERATION_SHIFT_BITS, uint256(uint160(account)), amount);

    }

    /**
     * @notice used to catch when used try to redeem by sending wallet tokens directly to contract
     * see more in {IERC777RecipientUpgradeable::tokensReceived}
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @custom:shortd part of {IERC777RecipientUpgradeable}
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (!(_msgSender() == address(this) && to == address(this))) {
            revert OwnTokensPermittedOnly();
        }
        _checkRole(redeemRoleId, from);
        __redeem(address(this), from, amount, new address[](0), Strategy.REDEEM);
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice function for creation erc20 instance pool.
     * @param tokenErc20 address of erc20 token.
     * @param duration duration represented in amount of `LOCKUP_INTERVAL`
     * @param bonusTokenFraction fraction of bonus tokens multiplied by {CommunityStakingPool::FRACTION} that additionally distributed when user stakes
     * @param donations array of tuples donations. address,uint256. if array empty when coins will obtain sender, overwise donation[i].account  will obtain proportionally by ration donation[i].amount
     * @return instance address of created instance pool `CommunityStakingPoolErc20`
     * @custom:shortd creation erc20 instance with simple options
     */
    function produce(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        IStructs.StructAddrUint256[] memory donations,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) public onlyOwner returns (address instance) {
        return
            _produce(
                tokenErc20,
                duration,
                bonusTokenFraction,
                popularToken,
                donations,
                rewardsRateFraction,
                numerator,
                denominator
            );
    }

    /**
     * @notice method to obtain tokens: lp or erc20, depends of pool that was staked before. like redeem but can applicable only for own staked tokens that haven't transfer yet. so no need to have redeem role for this
     * @param amount The number of ITRc tokens that will be unstaked.
     * @custom:shortd unstake own ITRc tokens
     */
    function unstake(uint256 amount) public nonReentrant {
        address account = _msgSender();
        _validateUnstake(account, amount);
        _unstake(account, amount, new address[](0), Strategy.UNSTAKE);
        _accountForOperation(OPERATION_UNSTAKE << OPERATION_SHIFT_BITS, uint256(uint160(account)), amount);
    }
    
    /**
     * @dev function has overloaded. wallet tokens will be redeemed from pools in order from deployed
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param amount The number of wallet tokens that will be redeemed.
     * @custom:shortd redeem tokens
     */
    function redeem(uint256 amount) public nonReentrant {
        _redeem(_msgSender(), amount, new address[](0), Strategy.REDEEM);

        _accountForOperation(OPERATION_REDEEM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), amount);
    }

    /**
     * @dev function has overloaded. wallet tokens will be redeemed from pools in order from `preferredInstances`. tx reverted if amoutn is unsufficient even if it is enough in other pools
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param amount The number of wallet tokens that will be redeemed.
     * @param preferredInstances preferred instances for redeem first
     * @custom:shortd redeem tokens with preferredInstances
     */
    function redeem(uint256 amount, address[] memory preferredInstances) public nonReentrant {
        _redeem(_msgSender(), amount, preferredInstances, Strategy.REDEEM);

        _accountForOperation(OPERATION_REDEEM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), amount);
    }

    /**
     * @notice way to view locked tokens that still can be unstakeable by user
     * @param account address
     * @custom:shortd view locked tokens
     */
    function viewLockedWalletTokens(address account) public view returns (uint256) {
        //return users[account].tokensLocked._getMinimum() + users[account].tokensBonus._getMinimum();
        return MinimumsLib._getMinimum(users[account].tokensLocked) + MinimumsLib._getMinimum(users[account].tokensBonus);
    }

    /**
     * @notice way to view locked tokens lists(main and bonuses) that still can be unstakeable by user
     * @param account address
     * @custom:shortd view locked tokens lists (main and bonuses)
     */
    function viewLockedWalletTokensList(address account) public view returns (uint256[][] memory, uint256[][] memory) {
        //return (users[account].tokensLocked._getMinimumList(), users[account].tokensBonus._getMinimumList());
        return (MinimumsLib._getMinimumList(users[account].tokensLocked), MinimumsLib._getMinimumList(users[account].tokensBonus));
    }

    // /**
    //  * @dev calculate how much token user will obtain if redeem and remove liquidity token.
    //  * There are steps:
    //  * 1. LP tokens swap to Reserved and Traded Tokens
    //  * 2. TradedToken swap to Reverved
    //  * 3. All Reserved tokens try to swap in order of swapPaths
    //  * @param account address which will be redeem funds from
    //  * @param amount liquidity tokens amount
    //  * @param preferredInstances array of preferred Stakingpool instances which will be redeem funds from
    //  * @param swapPaths array of arrays uniswap swapPath
    //  * @return address destination address
    //  * @return uint256 destination amount
    //  */
    // function simulateRedeemAndRemoveLiquidity(
    //     address account,
    //     uint256 amount, //amountLP,
    //     address[] memory preferredInstances,
    //     address[][] memory swapPaths
    // ) public view returns (address, uint256) {
    //     (
    //         address[] memory instancesToRedeem,
    //         uint256[] memory valuesToRedeem, 
    //         /*uint256[] memory amounts*/, 
    //         /* uint256 len*/ , 
    //         /*uint256 newAmount*/

    //     ) = _poolStakesAvailable(
    //             account,
    //             amount,
    //             preferredInstances,
    //             Strategy.REDEEM_AND_REMOVE_LIQUIDITY,
    //             totalSupply() //totalSupplyBefore
    //         );

    //     return instanceManagment.amountAfterSwapLP(instancesToRedeem, valuesToRedeem, swapPaths);
    // }

    /**
    * @notice calling claim method on Hook Contract. in general it's Rewards contract that can be able to accomulate bonuses. 
    * calling `claim` user can claim them
    */
    function claim() public {
        _accountForOperation(OPERATION_CLAIM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), 0);
        if (hook != address(0)) {
            IRewards(hook).onClaim(_msgSender());
        }
    }

    /**
     * @notice setup trusted forwarder address
     * @param forwarder trustedforwarder's address to set
     * @custom:shortd setup trusted forwarder
     * @custom:calledby owner
     */
    function setTrustedForwarder(address forwarder) public override onlyOwner {
        if (owner() == forwarder) {
            revert TrustedForwarderCanNotBeOwner(forwarder);
        }

        _setTrustedForwarder(forwarder);
        _accountForOperation(
            OPERATION_SET_TRUSTEDFORWARDER << OPERATION_SHIFT_BITS,
            uint256(uint160(_msgSender())),
            uint256(uint160(forwarder))
        );
    }
    /**
    * @notice ownable version transferOwnership with supports ERC2771 
    * @param newOwner new owner address
    * @custom:shortd transferOwnership
    * @custom:calledby owner
    */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (_isTrustedForwarder(msg.sender)) {
            revert DeniedForTrustedForwarder(msg.sender);
        }
        if (_isTrustedForwarder(newOwner)) {
            _setTrustedForwarder(address(0));
        }
        _accountForOperation(
            OPERATION_SET_TRANSFER_OWNERSHIP << OPERATION_SHIFT_BITS,
            uint256(uint160(_msgSender())),
            uint256(uint160(newOwner))
        );
        super.transferOwnership(newOwner);
    }

    /**
    * @notice additional tokens for the inviter
    * @param fraction fraction that will send to person which has invite person who staked
    * @custom:shortd set commission for addional tokens
    * @custom:calledby owner
    */
    function setCommission(uint256 fraction) public onlyOwner {
        invitedByFraction = fraction;
    }

    function setTariff(uint64 redeemTariff_, uint64 unstakeTariff_) public {
        _checkRole(tariffRoleId, _msgSender());
        if (redeemTariff_ > MAX_REDEEM_TARIFF || unstakeTariff_ > MAX_UNSTAKE_TARIFF) {
            revert AmountExceedsMaxTariff();
        }
        redeemTariff = redeemTariff_;
        unstakeTariff = unstakeTariff_;
    }

    /**
    * @notice set hook contract, tha implement Beforetransfer methodf and can be managed amount of transferred tokens.
    * @param taxAddress address of TaxHook
    * @custom:shortd set tax hook contract address
    * @custom:calledby owner
    */
    function setupTaxAddress(address taxAddress) public onlyOwner {
        require(taxHook == address(0));
        taxHook = taxAddress;
    }

    /**
    * @notice set donations contract, triggered when someone donate funds ina pool
    * @param addr address of donationRewardsHook
    * @custom:shortd set donations hook contract address
    * @custom:calledby owner
    */
    function setupDonationHookAddress(address addr) public onlyOwner {
        donationRewardsHook = addr;
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function _validateUnstake(address account, uint256 amount) internal view {
        uint256 balance = balanceOf(account);

        if (amount > balance) {
            revert InsufficientBalance(account, amount);
        }

        //uint256 locked = users[account].tokensLocked._getMinimum();
        uint256 locked = MinimumsLib._getMinimum(users[account].tokensLocked);

        uint256 remainingAmount = balance - amount;

        if (locked > remainingAmount) {
            revert StakeNotUnlockedYet(account, locked, remainingAmount);
        }
    }

    function _produce(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        IStructs.StructAddrUint256[] memory donations,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) internal returns (address instance) {
        instance = instanceManagment.produce(
            tokenErc20,
            duration,
            bonusTokenFraction,
            popularToken,
            donations,
            rewardsRateFraction,
            numerator,
            denominator
        );
        emit InstanceCreated(tokenErc20, instance);

        _accountForOperation(
            OPERATION_PRODUCE_ERC20 << OPERATION_SHIFT_BITS,
            (duration << (256 - 64)) + (bonusTokenFraction << (256 - 128)) + (numerator << (256 - 192)) + (denominator),
            0
        );
    }

    function _unstake(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal proceedBurnUnstakeRedeem {
        // console.log("_unstake#0");
        uint256 totalSupplyBefore = _burn(account, amount);

        (
            address[] memory instancesList,
            uint256[] memory values,
            uint256[] memory amounts,
            uint256 len,
            uint256 newAmount
        ) = _poolStakesAvailable(account, amount, preferredInstances, strategy, totalSupplyBefore);

        // not obviously but we burn all before. not need to burn this things separately
        // `newAmount` just confirm us how much amount using in calculation pools
            


        // console.log("_unstake#2");
        // console.log("len =",len);
        for (uint256 i = 0; i < len; i++) {
            // console.log("i =",i);
            // console.log("amounts[i] =",amounts[i]);
            // console.log("users[account].unstakeable =",users[account].unstakeable);
            // console.log("users[account].unstakeableBonuses =",users[account].unstakeableBonuses);
            //console.log(1);

            _instances[instancesList[i]]._instanceStaked -= amounts[i];

            // in stats we should minus without taxes as we did in burn
            _instances[instancesList[i]].unstakeable[account] -= amounts[i] * amount / newAmount;
            users[account].unstakeable -= amounts[i] * amount / newAmount;
            

            //console.log(4);

            //proceedPool(account, instancesList[i], values[i], strategy);
            PoolStakesLib.proceedPool(instanceManagment, hook, account, instancesList[i], values[i], strategy);
            //console.log(5);
        }
        //console.log(6);
    }

    // create map of instance->amount or LP tokens that need to redeem
    function _poolStakesAvailable(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy,
        uint256 totalSupplyBefore
    )
        internal
        view
        returns (
            address[] memory instancesAddress, // instance's addresses
            uint256[] memory values, // amounts to redeem in instance
            uint256[] memory amounts, // itrc amount equivalent(applied num/den)
            uint256 len,
            uint256 newAmount
        )
    {
        newAmount = PoolStakesLib.getAmountLeft(
            account,
            amount,
            totalSupplyBefore,
            strategy,
            total,
            discountSensitivity,
            users,
            unstakeTariff,
            redeemTariff,
            FRACTION
        );
        // console.log("_poolStakesAvailable::amountLeft=", amount);
        (instancesAddress, values, amounts, len) = PoolStakesLib.available(
            account,
            newAmount,
            preferredInstances,
            strategy,
            instanceManagment,
            _instances
        );
    }

    function _redeem(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal {
        _checkRole(redeemRoleId, account);

        __redeem(account, account, amount, preferredInstances, strategy);
    }

    function _burn(address account, uint256 amount)
        internal
        proceedBurnUnstakeRedeem
        returns (uint256 totalSupplyBefore)
    {
        totalSupplyBefore = totalSupply();
        if (account != address(this)) {
            //require(allowance(account, address(this))  >= amount, "Amount exceeds allowance");
            if (allowance(account, address(this)) < amount) {
                revert AmountExceedsAllowance(account, amount);
            }
        }

        _burn(account, amount, "", "");
    }

    function __redeem(
        address accountToBurn,
        address accountToRedeem,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal proceedBurnUnstakeRedeem {

        if (amount > total.totalRedeemable) {
            revert InsufficientBalance(accountToRedeem, amount);
        }

        uint256 totalSupplyBefore = _burn(accountToBurn, amount);

        (address[] memory instancesToRedeem, uint256[] memory valuesToRedeem, uint256[] memory amounts, uint256 len, /*uint256 newAmount*/) = _poolStakesAvailable(
            accountToRedeem,
            amount,
            preferredInstances,
            strategy, /*Strategy.REDEEM*/
            totalSupplyBefore
        );

        // not obviously but we burn all before. not need to burn this things separately
        // `newAmount` just confirm us how much amount using in calculation pools
        
        for (uint256 i = 0; i < len; i++) {
            if (_instances[instancesToRedeem[i]].redeemable > 0) {
                _instances[instancesToRedeem[i]].redeemable -= amounts[i];
                
                total.totalRedeemable -= amounts[i];
                total.totalReserves -= amounts[i];

                //proceedPool(accountToRedeem, instancesToRedeem[i], valuesToRedeem[i], strategy);
                PoolStakesLib.proceedPool(instanceManagment, hook, accountToRedeem, instancesToRedeem[i], valuesToRedeem[i], strategy);
            }
        }

    }

    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual override {
        
        if (
            from != address(0) && //otherwise minted
            !(from == address(this) && to == address(0)) && //burnt by contract itself
            address(taxHook) != address(0) && // tax hook setup
            !flagHookTransferReentrant // no reentrant here
        ) {
            // hook should return tuple: (success, amountAdjusted)
            //  can return true/false
            // true = revert ;  false -pass tx

            _accountForOperation(
                OPERATION_TRANSFER_HOOK << OPERATION_SHIFT_BITS,
                uint256(uint160(from)),
                uint256(uint160(to))
            );

            flagHookTransferReentrant = true;

            (bool success, uint256 amountAdjusted) = ITaxes(taxHook).beforeTransfer(_msgSender(), from, to, amount);
            if (success == false) {
                revert HookTransferPrevent(from, to, amount);
            }

            if (amount < amountAdjusted) {
                if (amount + amount * MAX_BOOST / FRACTION < amountAdjusted) {
                    amountAdjusted = amount + amount * MAX_BOOST / FRACTION;
                    emit MaxBoostExceeded();
                }
                _mint(to, amountAdjusted - amount, "", "");
            } else if (amount > amountAdjusted) {
                // if amountAdjusted less then amount with max tax
                if (amount - amount * MAX_TAX / FRACTION > amountAdjusted) {
                    amountAdjusted = amount - amount * MAX_TAX / FRACTION;
                    emit MaxTaxExceeded();
                }

                _burn(from, amount - amountAdjusted, "", "");

                amount = amountAdjusted;

            }

            // if amount == amountAdjusted do nothing

            flagHookTransferReentrant = false;
        }

        super._send(from, to, amount, userData, operatorData, requireReceptionAck);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
    
        super._beforeTokenTransfer(operator, from, to, amount);

        if (from != address(0)) {
            // otherwise minted
            if (from == address(this) && to == address(0)) {
                // burnt by contract itself
            } else {
                uint256 balance = balanceOf(from);

                if (balance >= amount) {
                    uint256 remainingAmount = balance - amount;

                    //-------------------
                    // locked sections
                    //-------------------
                    PoolStakesLib.lockedPart(users, from, remainingAmount);
                    //--------------------

                    if (
                        // not calculate if
                        flagBurnUnstakeRedeem || to == address(this) // - burn or unstake or redeem // - send directly to contract
                    ) {

                    } else {
                        //-------------------
                        // unstakeable sections
                        //-------------------
                        PoolStakesLib.unstakeablePart(users, _instances, from, to, total, amount);
                        //--------------------
                        
                    }
                } else {
                    // insufficient balance error would be in {ERC777::_move}
                }
            }
        }

    }

    /**
     * @dev implemented EIP-2771
     * @return signer return address of msg.sender. but consider EIP-2771 for trusted forwarder will return from msg.data payload
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, TrustedForwarder)
        returns (address signer)
    {
        return TrustedForwarder._msgSender();
    }

    function _insertBonus(
        address instance,
        address account,
        uint256 amount
    ) internal {
        if (!users[account].instancesList.contains(instance)) {
            users[account].instancesList.add(instance);
        }
        _instances[instance].unstakeableBonuses[account] += amount;
        users[account].unstakeableBonuses += amount;
    }

    

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./interfaces/IStructs.sol";
import "./maps/CommunityAccessMap.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@artman325/community/contracts/interfaces/ICommunity.sol";

/*ICommunityRolesManagement, */
abstract contract RolesManagement is Initializable {
    // itrc' fraction that will send to person who has invited "buy and stake" person
    uint256 public invitedByFraction;

    address internal communityAddress;
    uint8 internal redeemRoleId;
    uint8 internal circulationRoleId;
    uint8 internal tariffRoleId;

    error MissingRole(address account, uint8 roleId);

    function __RolesManagement_init(IStructs.CommunitySettings calldata communitySettings) internal onlyInitializing {
        require(communitySettings.addr != address(0));

        invitedByFraction = communitySettings.invitedByFraction;
        communityAddress = communitySettings.addr;
        redeemRoleId = communitySettings.redeemRoleId;
        circulationRoleId = communitySettings.circulationRoleId;
        tariffRoleId = communitySettings.tariffRoleId;
    }

    /**
     * @param fraction fraction that will send to person which has invite person who staked
     */
    function _setCommission(uint256 fraction) internal {
        invitedByFraction = fraction;
    }

    function _invitedBy(address account) internal view returns (address inviter) {
        return CommunityAccessMap(communityAddress).invitedBy(account);
    }

    function _checkRole(uint8 roleId, address account) internal view virtual {
        if (!hasRole(account, roleId)) {
            revert MissingRole(account, roleId);
            // revert(
            //     string(
            //         abi.encodePacked(
            //             "AccessControl: account ",
            //             StringsUpgradeable.toHexString(uint160(account), 20),
            //             " is missing role ",
            //             StringsUpgradeable.toHexString(uint256(role), 32)
            //         )
            //     )
            // );
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     *
     */
    function hasRole(address account, uint8 role) public view returns (bool) {

        // external call to community contract
        return ICommunity(communityAddress).hasRole(account, role);

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITaxes {
    function beforeTransfer(address operator, address from, address to, uint256 amount) external returns(bool success, uint256 amountAdjusted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";
import "../minimums/libs/MinimumsLib.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
interface ICommunityCoin {
    
    struct UserData {
        uint256 unstakeable; // total unstakeable across pools
        uint256 unstakeableBonuses;
        MinimumsLib.UserStruct tokensLocked;
        MinimumsLib.UserStruct tokensBonus;
        // lists where user staked or obtained bonuses
        EnumerableSetUpgradeable.AddressSet instancesList;
    }

    struct InstanceStruct {
        uint256 _instanceStaked;
        
        uint256 redeemable;
        // //      user
        // mapping(address => uint256) usersStaked;
        //      user
        mapping(address => uint256) unstakeable;
        //      user
        mapping(address => uint256) unstakeableBonuses;
        
    }

    function initialize(
        string calldata name,
        string calldata symbol,
        address poolImpl,
        address hook,
        address instancesImpl,
        uint256 discountSensitivity,
        IStructs.CommunitySettings calldata communitySettings,
        address costManager,
        address producedBy
    ) external;

    enum Strategy{ UNSTAKE, REDEEM} 

    event InstanceCreated(address indexed erc20token, address instance);
    
    error InsufficientBalance(address account, uint256 amount);
    error InsufficientAmount(address account, uint256 amount);
    error StakeNotUnlockedYet(address account, uint256 locked, uint256 remainingAmount);
    error TrustedForwarderCanNotBeOwner(address account);
    error DeniedForTrustedForwarder(address account);
    error OwnTokensPermittedOnly();
    error UNSTAKE_ERROR();
    error REDEEM_ERROR();
    error HookTransferPrevent(address from, address to, uint256 amount);
    error AmountExceedsAllowance(address account,uint256 amount);
    error AmountExceedsMaxTariff();
    
    function issueWalletTokens(address account, uint256 amount, uint256 priceBeforeStake, uint256 donatedAmount) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IHook.sol";
interface IDonationRewards is IHook {
    
    function bonus(address instance, address account, uint64 duration, uint256 amount) external;
    function transferHook(address operator, address from, address to, uint256 amount) external returns(bool);
    function claim() external;
    // methods above will be refactored 

    function onDonate(address token, address who, uint256 amount) external;
 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPool {
    
    function initialize(
        address stakingProducedBy_,
        address token_,
        address popularToken_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 rewardsRateFraction_
    ) external;

    function redeem(address account, uint256 amount) external returns(uint256 affectedAmount, uint64 rewardsRateFraction);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPoolFactory {
    
    
    struct InstanceInfo {
        address tokenErc20;
        uint64 duration;
        bool exists;
        uint64 bonusTokenFraction;
        address popularToken;
        uint64 rewardsRateFraction;
        uint64 numerator;
        uint64 denominator;
    }

    event InstanceCreated(address indexed erc20, address instance, uint instancesCount);

    function initialize(address impl) external;
    function getInstance(address tokenErc20, uint256 lockupIntervalCount) external view returns (address instance);
    function instancesByIndex(uint index) external view returns (address instance);
    function instances() external view returns (address[] memory instances);
    function instancesCount() external view returns (uint);
    function produce(address tokenErc20, uint64 duration, uint64 bonusTokenFraction, address popularToken, IStructs.StructAddrUint256[] memory donations, uint64 rewardsRateFraction, uint64 numerator, uint64 denominator) external returns (address instance);
    function getInstanceInfoByPoolAddress(address addr) external view returns(InstanceInfo memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ICommunityCoin.sol";
import "../interfaces/ICommunityStakingPoolFactory.sol";
import "../interfaces/ICommunityStakingPool.sol";
import "../interfaces/IRewards.sol";

//import "hardhat/console.sol";
library PoolStakesLib {
    using MinimumsLib for MinimumsLib.UserStruct;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function unstakeablePart(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address from, 
        address to, 
        IStructs.Total storage total, 
        uint256 amount
    ) external {
        // console.log("amount                         =",amount);
        // console.log("remainingAmount                =",remainingAmount);
        // console.log("users[from].unstakeable        =",users[from].unstakeable);
        // console.log("users[from].unstakeableBonuses =",users[from].unstakeableBonuses);
        // console.log("users[to].unstakeable          =",users[to].unstakeable);
        // console.log("users[to].unstakeableBonuses   =",users[to].unstakeableBonuses);
        // else it's just transfer

        // so while transfer user will user free tokens at first
        // then try to use locked. when using locked we should descrease

        //users[from].unstakeableBonuses;
        //try to get from bonuses
        //  here just increase redeemable
        //then try to get from main unstakeable
        //  here decrease any unstakeable vars
        //              increase redeemable
        uint256 r;
        uint256 left = amount;
        if (users[from].unstakeableBonuses > 0) {
            
            if (users[from].unstakeableBonuses >= left) {
                r = left;
            } else {
                r = users[from].unstakeableBonuses;
            }

            if (to == address(0)) {
                // it's simple burn and tokens can not be redeemable
            } else {
                total.totalRedeemable += r;
            }

            PoolStakesLib._removeBonusThroughInstances(users, _instances, from, r);
            users[from].unstakeableBonuses -= r;
            left -= r;
        }

        if ((left > 0) && (users[from].unstakeable >= left)) {
            // console.log("#2");
            if (users[from].unstakeable >= left) {
                r = left;
            } else {
                r = users[from].unstakeable;
            }

            //   r = users[from].unstakeable - left;
            // if (totalUnstakeable >= r) {
            users[from].unstakeable -= r;
            total.totalUnstakeable -= r;

            if (to == address(0)) {
                // it's simple burn and tokens can not be redeemable
            } else {
                total.totalRedeemable += r;
            }

            PoolStakesLib._removeMainThroughInstances(users, _instances, from, r);

            //left -= r;

            // }
        }

        // if (users[from].unstakeable >= remainingAmount) {
        //     uint256 r = users[from].unstakeable - remainingAmount;
        //     // if (totalUnstakeable >= r) {
        //     users[from].unstakeable -= r;
        //     totalUnstakeable -= r;
        //     if (to == address(0)) {
        //         // it's simple burn and tokens can not be redeemable
        //     } else {
        //         totalRedeemable += r;
        //     }
        //     // }
        // }
        // console.log("----------------------------");
        // console.log("users[from].unstakeable        =",users[from].unstakeable);
        // console.log("users[from].unstakeableBonuses =",users[from].unstakeableBonuses);
        // console.log("users[to].unstakeable          =",users[to].unstakeable);
        // console.log("users[to].unstakeableBonuses   =",users[to].unstakeableBonuses);
    }

    
    function _removeMainThroughInstances(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account, 
        uint256 amount
    ) internal {
        uint256 len = users[account].instancesList.length();
        address[] memory instances2Delete = new address[](len);
        uint256 j = 0;
        address instance;
        for (uint256 i = 0; i < len; i++) {
            instance = users[account].instancesList.at(i);
            if (_instances[instance].unstakeable[account] >= amount) {
                _instances[instance].unstakeable[account] -= amount;
                _instances[instance].redeemable += amount;
            } else if (_instances[instance].unstakeable[account] > 0) {
                _instances[instance].unstakeable[account] = 0;
                instances2Delete[j] = instance;
                j += 1;
                amount -= _instances[instance].unstakeable[account];
            }
        }

        // do deletion out of loop above. because catch out of array
        cleanInstancesList(users, _instances, account, instances2Delete, j);
    }

    function _removeBonusThroughInstances(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        // address account, 
        // // address to, 
        // // IStructs.Total storage total, 
        // uint256 amount
        address account, 
        uint256 amount
    ) internal {
        //console.log("START::_removeBonusThroughInstances");
        uint256 len = users[account].instancesList.length();
        address[] memory instances2Delete = new address[](len);
        uint256 j = 0;
        //console.log("_removeBonusThroughInstances::len", len);
        address instance;
        for (uint256 i = 0; i < len; i++) {
            instance = users[account].instancesList.at(i);
            if (_instances[instance].unstakeableBonuses[account] >= amount) {
                //console.log("_removeBonusThroughInstances::#1");
                _instances[instance].unstakeableBonuses[account] -= amount;
            } else if (_instances[instance].unstakeableBonuses[account] > 0) {
                //console.log("_removeBonusThroughInstances::#2");
                _instances[instance].unstakeableBonuses[account] = 0;
                instances2Delete[i] = instance;
                j += 1;
                amount -= _instances[instance].unstakeableBonuses[account];
            }
        }

        // do deletion out of loop above. because catch out of array
        PoolStakesLib.cleanInstancesList(users, _instances, account, instances2Delete, j);
        //console.log("END::_removeBonusThroughInstances");
    }

    /*
    function _removeBonus(
        address instance,
        address account,
        uint256 amount
    ) internal {
        // todo 0:
        //  check `instance` exists in list.
        //  check `amount` should be less or equal `_instances[instance].unstakeableBonuses[account]`

        _instances[instance].unstakeableBonuses[account] -= amount;
        users[account].unstakeableBonuses -= amount;

        if (_instances[instance].unstakeable[account] >= amount) {
            _instances[instance].unstakeable[account] -= amount;
        } else if (_instances[instance].unstakeable[account] > 0) {
            _instances[instance].unstakeable[account] = 0;
            //amount -= _instances[instance].unstakeable[account];
        }
        _cleanInstance(account, instance);
    }
    */

    function cleanInstancesList(
        
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account,
        address[] memory instances2Delete,
        uint256 indexUntil
    ) internal {
        // console.log("start::cleanInstancesList");
        // console.log("cleanInstancesList::indexUntil=",indexUntil);
        //uint256 len = instances2Delete.length;
        if (indexUntil > 0) {
            for (uint256 i = 0; i < indexUntil; i++) {
                PoolStakesLib._cleanInstance(users, _instances, account, instances2Delete[i]);
            }
        }
        // console.log("end::cleanInstancesList");
    }

     function _cleanInstance(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account, 
        address instance
    ) internal {
        //console.log("start::_cleanInstance");
        if (_instances[instance].unstakeableBonuses[account] == 0 && _instances[instance].unstakeable[account] == 0) {
            users[account].instancesList.remove(instance);
        }

        // console.log("end::_cleanInstance");
    }

    function lockedPart(
        mapping(address => ICommunityCoin.UserData) storage users,
        address from, 
        uint256 remainingAmount
    ) external {
        /*
        balance = 100
        amount = 40
        locked = 50
        minimumsTransfer - ? =  0
        */
        /*
        balance = 100
        amount = 60
        locked = 50
        minimumsTransfer - ? = [50 > (100-60)] locked-(balance-amount) = 50-(40)=10  
        */
        /*
        balance = 100
        amount = 100
        locked = 100
        minimumsTransfer - ? = [100 > (100-100)] 100-(100-100)=100  
        */

        uint256 locked = users[from].tokensLocked._getMinimum();
        uint256 lockedBonus = users[from].tokensBonus._getMinimum();
        //else drop locked minimum, but remove minimums even if remaining was enough
        //minimumsTransfer(account, ZERO_ADDRESS, (locked - remainingAmount))
        // console.log("locked---start");
        // console.log("balance        = ",balance);
        // console.log("amount         = ",amount);
        // console.log("remainingAmount= ",remainingAmount);
        // console.log("locked         = ",locked);
        // console.log("lockedBonus    = ",lockedBonus);
        if (locked + lockedBonus > 0 && locked + lockedBonus >= remainingAmount) {
            // console.log("#1");
            uint256 locked2Transfer = locked + lockedBonus - remainingAmount;
            if (lockedBonus >= locked2Transfer) {
                // console.log("#2.1");
                users[from].tokensBonus.minimumsTransfer(
                    users[address(0)].tokensBonus,
                    true,
                    (lockedBonus - locked2Transfer)
                );
            } else {
                // console.log("#2.2");

                // console.log("locked2Transfer = ", locked2Transfer);
                //uint256 left = (remainingAmount - lockedBonus);
                if (lockedBonus > 0) {
                    users[from].tokensBonus.minimumsTransfer(
                        users[address(0)].tokensBonus,
                        true,
                        lockedBonus
                    );
                    locked2Transfer -= lockedBonus;
                }
                users[from].tokensLocked.minimumsTransfer(
                    users[address(0)].tokensLocked,
                    true,
                    locked2Transfer
                );
            }
        }
        // console.log("locked         = ",locked);
        // console.log("lockedBonus    = ",lockedBonus);
        // console.log("locked---end");
        //-------------------
    }

    function proceedPool(
        ICommunityStakingPoolFactory instanceManagment,
        address hook,
        address account,
        address pool,
        uint256 amount,
        ICommunityCoin.Strategy strategy /*, string memory errmsg*/
    ) external {

        ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo = instanceManagment.getInstanceInfoByPoolAddress(pool);

        try ICommunityStakingPool(pool).redeem(account, amount) returns (
            uint256 affectedAmount,
            uint64 rewardsRateFraction
        ) {
// console.log("proceedPool");
// console.log(account, amount);
            if (
                (hook != address(0)) &&
                (strategy == ICommunityCoin.Strategy.UNSTAKE)
            ) {
                require(instanceInfo.exists == true);
                IRewards(hook).onUnstake(pool, account, instanceInfo.duration, affectedAmount, rewardsRateFraction);
            }
        } catch {
            if (strategy == ICommunityCoin.Strategy.UNSTAKE) {
                revert ICommunityCoin.UNSTAKE_ERROR();
            } else if (strategy == ICommunityCoin.Strategy.REDEEM) {
                revert ICommunityCoin.REDEEM_ERROR();
            }
            
        }
        
    }

    // adjusting amount and applying some discounts, fee, etc
    function getAmountLeft(
        address account,
        uint256 amount,
        uint256 totalSupplyBefore,
        ICommunityCoin.Strategy strategy,
        IStructs.Total storage total,
        // uint256 totalRedeemable,
        // uint256 totalUnstakeable,
        // uint256 totalReserves,
        uint256 discountSensitivity,
        mapping(address => ICommunityCoin.UserData) storage users,
        uint64 unstakeTariff, 
        uint64 redeemTariff,
        uint64 fraction

    ) external view returns(uint256) {
        
        if (strategy == ICommunityCoin.Strategy.REDEEM) {

            // LPTokens =  WalletTokens * ratio;
            // ratio = A / (A + B * discountSensitivity);
            // где 
            // discountSensitivity - constant set in constructor
            // A = totalRedeemable across all pools
            // B = totalSupply - A - totalUnstakeable
            uint256 A = total.totalRedeemable;
            uint256 B = totalSupplyBefore - A - total.totalUnstakeable;
            // uint256 ratio = A / (A + B * discountSensitivity);
            // amountLeft =  amount * ratio; // LPTokens =  WalletTokens * ratio;

            // --- proposal from audit to keep precision after division
            // amountLeft = amount * A / (A + B * discountSensitivity / 100000);
            amount = amount * A * fraction;
            amount = amount / (A + B * discountSensitivity / fraction);
            amount = amount / fraction;

            /////////////////////////////////////////////////////////////////////
            // Formula: #1
            // discount = mainTokens / (mainTokens + bonusTokens);
            // 
            // but what we have: 
            // - mainTokens     - tokens that user obtain after staked 
            // - bonusTokens    - any bonus tokens. 
            //   increase when:
            //   -- stakers was invited via community. so inviter will obtain amount * invitedByFraction
            //   -- calling addToCirculation
            //   decrease when:
            //   -- by applied tariff when redeem or unstake
            // so discount can be more then zero
            // We didn't create int256 bonusTokens variable. instead this we just use totalSupply() == (mainTokens + bonusTokens)
            // and provide uint256 totalReserves as tokens amount  without bonuses.
            // increasing than user stakes and decreasing when redeem
            // smth like this
            // discount = totalReserves / (totalSupply();
            // !!! keep in mind that we have burn tokens before it's operation and totalSupply() can be zero. use totalSupplyBefore instead 

            amount = amount * total.totalReserves / totalSupplyBefore;

            /////////////////////////////////////////////////////////////////////

            // apply redeem tariff                    
            amount -= amount * redeemTariff/fraction;
            
        }

        if (strategy == ICommunityCoin.Strategy.UNSTAKE) {

            if (
               (totalSupplyBefore - users[account].tokensBonus._getMinimum() < amount) || // insufficient amount
               (users[account].unstakeable < amount)  // check if user can unstake such amount across all instances
            ) {
                revert ICommunityCoin.InsufficientAmount(account, amount);
            }

            // apply unstake tariff
            amount -= amount * unstakeTariff/fraction;


        }

        return amount;
        
    }
    
    // create map of instance->amount or LP tokens that need to redeem
    function available(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        ICommunityCoin.Strategy strategy,
        ICommunityStakingPoolFactory instanceManagment,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances
    ) 
        external 
        view
        returns(
            address[] memory instancesAddress,  // instance's addresses
            uint256[] memory values,            // amounts to redeem in instance
            uint256[] memory amounts,           // itrc amount equivalent(applied num/den)
            uint256 len
        ) 
    {
    
        //  uint256 FRACTION = 100000;

        if (preferredInstances.length == 0) {
            preferredInstances = instanceManagment.instances();
        }

        instancesAddress = new address[](preferredInstances.length);
        values = new uint256[](preferredInstances.length);
        amounts = new uint256[](preferredInstances.length);

        uint256 amountLeft = amount;
        

        len = 0;
        uint256 amountToRedeem;

        // now calculate from which instances we should reduce tokens
        for (uint256 i = 0; i < preferredInstances.length; i++) {

            if (
                (strategy == ICommunityCoin.Strategy.UNSTAKE) &&
                (_instances[preferredInstances[i]].unstakeable[account] > 0)
            ) {
                amountToRedeem = 
                    amountLeft > _instances[preferredInstances[i]].unstakeable[account]
                    ?
                    _instances[preferredInstances[i]].unstakeable[account]
                        // _instances[preferredInstances[i]]._instanceStaked > users[account].unstakeable
                        // ? 
                        // users[account].unstakeable
                        // :
                        // _instances[preferredInstances[i]]._instanceStaked    
                    :
                    amountLeft;

            }  
            if (
                strategy == ICommunityCoin.Strategy.REDEEM
            ) {
                amountToRedeem = 
                    amountLeft > _instances[preferredInstances[i]]._instanceStaked
                    ? 
                    _instances[preferredInstances[i]]._instanceStaked
                    : 
                    amountLeft
                    ;
            }
                
            if (amountToRedeem > 0) {

                ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo;
                instancesAddress[len] = preferredInstances[i]; 
                instanceInfo =  instanceManagment.getInstanceInfoByPoolAddress(preferredInstances[i]); // todo is exist there?
                amounts[len] = amountToRedeem;
                //backward conversion( СС -> LP)
                values[len] = amountToRedeem * (instanceInfo.denominator) / (instanceInfo.numerator);
                
                len += 1;
                
                amountLeft -= amountToRedeem;
            }
        }
        
        if(amountLeft > 0) {revert ICommunityCoin.InsufficientAmount(account, amount);}

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CostManagerBase.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";

/**
* used for instances that have created(cloned) by factory with ERC2771 supports
*/
abstract contract CostManagerHelperERC2771Support is CostManagerBase, TrustedForwarder {
    function _sender() internal override view returns(address){
        return _msgSender();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777Upgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC777SenderUpgradeable.sol";
import "../ERC20/IERC20Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC777Upgradeable is Initializable, ContextUpgradeable, IERC777Upgradeable, IERC20Upgradeable {
    using AddressUpgradeable for address;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

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
    function __ERC777_init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        __ERC777_init_unchained(name_, symbol_, defaultOperators_);
    }

    function __ERC777_init_unchained(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
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
    function totalSupply() public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
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
     * will be called with the caller address as the `operator` and with
     * `userData` and `operatorData`.
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
            IERC777SenderUpgradeable(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
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
            IERC777RecipientUpgradeable(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
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
interface IERC777RecipientUpgradeable {
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
pragma solidity ^0.8.11;

interface ICommunity {
    
    function initialize(
        address implState,
        address implView,
        address hook, 
        address costManager, 
        string memory name, 
        string memory symbol
    ) external;
    
    function addressesCount(uint8 roleIndex) external view returns(uint256);
    function getRoles(address[] calldata accounts)external view returns(uint8[][] memory);
    function getAddresses(uint8[] calldata rolesIndexes) external view returns(address[][] memory);
    function hasRole(address account, uint8 roleIndex) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// using like an interface for external call to public mapping in community
abstract contract CommunityAccessMap {
    //receiver => sender
    mapping(address => address) public invitedBy;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IStructs {
    struct StructAddrUint256 {
        address account;
        uint256 amount;
    }

    struct CommunitySettings {
        uint256 invitedByFraction;
        address addr;
        uint8 redeemRoleId;
        uint8 circulationRoleId;
        uint8 tariffRoleId;
    }

    struct Total {
        uint256 totalUnstakeable;
        uint256 totalRedeemable;
        // it's how tokens will store in pools. without bonuses.
        // means totalReserves = SUM(pools.totalSupply)
        uint256 totalReserves;
    }

    enum InstanceType{ USUAL, ERC20, NONE }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

library MinimumsLib {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address internal constant ZERO_ADDRESS = address(0);

    struct Minimum {
     //   uint256 timestampStart; //ts start no need 
        //uint256 timestampEnd;   //ts end
        uint256 speedGradualUnlock;    
        uint256 amountGradualWithdrawn;
        //uint256 amountGradual;
        uint256 amountNoneGradual;
        //bool gradual;
    }

    struct Lockup {
        uint64 duration;
        //bool gradual; // does not used 
        bool exists;
    }

    struct UserStruct {
        EnumerableSetUpgradeable.UintSet minimumsIndexes;
        mapping(uint256 => Minimum) minimums;
        //mapping(uint256 => uint256) dailyAmounts;
        Lockup lockup;
    }


      /**
    * @dev adding minimum holding at sender during period from now to timestamp.
    *
    * @param amount amount.
    * @param intervalCount duration in count of intervals defined before
    * @param gradual true if the limitation can gradually decrease
    */
    function _minimumsAdd(
        UserStruct storage _userStruct,
        uint256 amount, 
        uint256 intervalCount,
        uint64 interval,
        bool gradual
    ) 
        // public 
        // onlyOwner()
        internal
        returns (bool)
    {
        uint256 timestampStart = getIndexInterval(block.timestamp, interval);
        uint256 timestampEnd = timestampStart + (intervalCount * interval);
        require(timestampEnd > timestampStart, "TIMESTAMP_INVALID");
        
        _minimumsClear(_userStruct, interval, false);
        
        _minimumsAddLow(_userStruct, timestampStart, timestampEnd, amount, gradual);
    
        return true;
        
    }
    
    /**
     * @dev removes all minimums from this address
     * so all tokens are unlocked to send
     *  UserStruct which should be clear restrict
     */
    function _minimumsClear(
        UserStruct storage _userStruct,
        uint64 interval
    )
        internal
        returns (bool)
    {
        return _minimumsClear(_userStruct, interval, true);
    }
    
    /**
     * from will add automatic lockup for destination address sent address from
     * @param duration duration in count of intervals defined before
     */
    function _automaticLockupAdd(
        UserStruct storage _userStruct,
        uint64 duration,
        uint64 interval
    )
        internal
    {
        _userStruct.lockup.duration = duration * interval;
        _userStruct.lockup.exists = true;
    }
    
    /**
     * remove automaticLockup from UserStruct
     */
    function _automaticLockupRemove(
        UserStruct storage _userStruct
    )
        internal
    {
        _userStruct.lockup.exists = false;
    }
    
    /**
    * @dev get sum minimum and sum gradual minimums from address for period from now to timestamp.
    *
    */
    function _getMinimum(
        UserStruct storage _userStruct
    ) 
        internal 
        view
        returns (uint256 amountLocked) 
    {
        
        uint256 mapIndex;
        uint256 tmp;
        for (uint256 i=0; i<_userStruct.minimumsIndexes.length(); i++) {
            mapIndex = _userStruct.minimumsIndexes.at(i);
            
            if (block.timestamp <= mapIndex) { // block.timestamp<timestampEnd
                tmp = _userStruct.minimums[mapIndex].speedGradualUnlock * (mapIndex - block.timestamp);
                
                amountLocked = amountLocked +
                                    (
                                        tmp < _userStruct.minimums[mapIndex].amountGradualWithdrawn 
                                        ? 
                                        0 
                                        : 
                                        tmp - (_userStruct.minimums[mapIndex].amountGradualWithdrawn)
                                    ) +
                                    (_userStruct.minimums[mapIndex].amountNoneGradual);
            }
        }
    }

    function _getMinimumList(
        UserStruct storage _userStruct
    ) 
        internal 
        view
        returns (uint256[][] memory ) 
    {
        
        uint256 mapIndex;
        uint256 tmp;
        uint256 len = _userStruct.minimumsIndexes.length();

        uint256[][] memory ret = new uint256[][](len);


        for (uint256 i=0; i<len; i++) {
            mapIndex = _userStruct.minimumsIndexes.at(i);
            
            if (block.timestamp <= mapIndex) { // block.timestamp<timestampEnd
                tmp = _userStruct.minimums[mapIndex].speedGradualUnlock * (mapIndex - block.timestamp);
                ret[i] = new uint256[](2);
                ret[i][1] = mapIndex;
                ret[i][0] = (
                                tmp < _userStruct.minimums[mapIndex].amountGradualWithdrawn 
                                ? 
                                0 
                                : 
                                tmp - _userStruct.minimums[mapIndex].amountGradualWithdrawn
                            ) +
                            _userStruct.minimums[mapIndex].amountNoneGradual;
            }
        }

        return ret;
    }
    
    /**
    * @dev clear expired items from mapping. used while addingMinimum
    *
    * @param deleteAnyway if true when delete items regardless expired or not
    */
    function _minimumsClear(
        UserStruct storage _userStruct,
        uint64 interval,
        bool deleteAnyway
    ) 
        internal 
        returns (bool) 
    {
        uint256 mapIndex = 0;
        uint256 len = _userStruct.minimumsIndexes.length();
        if (len > 0) {
            for (uint256 i=len; i>0; i--) {
                mapIndex = _userStruct.minimumsIndexes.at(i-1);
                if (
                    (deleteAnyway == true) ||
                    (getIndexInterval(block.timestamp, interval) > mapIndex)
                ) {
                    delete _userStruct.minimums[mapIndex];
                    _userStruct.minimumsIndexes.remove(mapIndex);
                }
                
            }
        }
        return true;
    }


        
    /**
     * added minimum if not exist by timestamp else append it
     * @param _userStruct destination user
     * @param timestampStart if empty get current interval or currente time. Using only for calculate gradual
     * @param timestampEnd "until time"
     * @param amount amount
     * @param gradual if true then lockup are gradually
     */
    //function _appendMinimum(
    function _minimumsAddLow(
        UserStruct storage _userStruct,
        uint256 timestampStart, 
        uint256 timestampEnd, 
        uint256 amount, 
        bool gradual
    )
        private
    {
        _userStruct.minimumsIndexes.add(timestampEnd);
        if (gradual == true) {
            // gradual
            _userStruct.minimums[timestampEnd].speedGradualUnlock = _userStruct.minimums[timestampEnd].speedGradualUnlock + 
                (
                amount / (timestampEnd - timestampStart)
                );
            //_userStruct.minimums[timestamp].amountGradual = _userStruct.minimums[timestamp].amountGradual.add(amount);
        } else {
            // none-gradual
            _userStruct.minimums[timestampEnd].amountNoneGradual = _userStruct.minimums[timestampEnd].amountNoneGradual + amount;
        }
    }
    
    /**
     * @dev reduce minimum by value  otherwise remove it 
     * @param _userStruct destination user struct
     * @param timestampEnd "until time"
     * @param value amount
     */
    function _reduceMinimum(
        UserStruct storage _userStruct,
        uint256 timestampEnd, 
        uint256 value,
        bool gradual
    )
        internal
    {
        
        if (_userStruct.minimumsIndexes.contains(timestampEnd) == true) {
            
            if (gradual == true) {
                
                _userStruct.minimums[timestampEnd].amountGradualWithdrawn = _userStruct.minimums[timestampEnd].amountGradualWithdrawn + value;
                
                uint256 left = (_userStruct.minimums[timestampEnd].speedGradualUnlock) * (timestampEnd - block.timestamp);
                if (left <= _userStruct.minimums[timestampEnd].amountGradualWithdrawn) {
                    _userStruct.minimums[timestampEnd].speedGradualUnlock = 0;
                    // delete _userStruct.minimums[timestampEnd];
                    // _userStruct.minimumsIndexes.remove(timestampEnd);
                }
            } else {
                if (_userStruct.minimums[timestampEnd].amountNoneGradual > value) {
                    _userStruct.minimums[timestampEnd].amountNoneGradual = _userStruct.minimums[timestampEnd].amountNoneGradual - value;
                } else {
                    _userStruct.minimums[timestampEnd].amountNoneGradual = 0;
                    // delete _userStruct.minimums[timestampEnd];
                    // _userStruct.minimumsIndexes.remove(timestampEnd);
                }
                    
            }
            
            if (
                _userStruct.minimums[timestampEnd].speedGradualUnlock == 0 &&
                _userStruct.minimums[timestampEnd].amountNoneGradual == 0
            ) {
                delete _userStruct.minimums[timestampEnd];
                _userStruct.minimumsIndexes.remove(timestampEnd);
            }
                
                
            
        }
    }
    
    /**
     * 
     
     * @param value amount
     */
    function minimumsTransfer(
        UserStruct storage _userStructFrom, 
        UserStruct storage _userStructTo, 
        bool isTransferToZeroAddress,
        //address to,
        uint256 value
    )
        internal
    {
        

        uint256 len = _userStructFrom.minimumsIndexes.length();
        uint256[] memory _dataList;
        //uint256 recieverTimeLeft;
    
        if (len > 0) {
            _dataList = new uint256[](len);
            for (uint256 i=0; i<len; i++) {
                _dataList[i] = _userStructFrom.minimumsIndexes.at(i);
            }
            _dataList = sortAsc(_dataList);
            
            uint256 iValue;
            uint256 tmpValue;
        
            for (uint256 i=0; i<len; i++) {
                
                if (block.timestamp <= _dataList[i]) {
                    
                    // try move none-gradual
                    if (value >= _userStructFrom.minimums[_dataList[i]].amountNoneGradual) {
                        iValue = _userStructFrom.minimums[_dataList[i]].amountNoneGradual;
                        value = value - iValue;
                    } else {
                        iValue = value;
                        value = 0;
                    }
                    
                    // remove from sender
                    _reduceMinimum(
                        _userStructFrom,
                        _dataList[i],//timestampEnd,
                        iValue,
                        false
                    );

                    // shouldn't add miniums for zero account.
                    // that feature using to drop minimums from sender
                    //if (to != ZERO_ADDRESS) {
                    if (!isTransferToZeroAddress) {
                        _minimumsAddLow(_userStructTo, block.timestamp, _dataList[i], iValue, false);
                    }
                    
                    if (value == 0) {
                        break;
                    }
                    
                    
                    // try move gradual
                    
                    // amount left in current minimums
                    tmpValue = _userStructFrom.minimums[_dataList[i]].speedGradualUnlock * (_dataList[i] - block.timestamp);
                        
                        
                    if (value >= tmpValue) {
                        iValue = tmpValue;
                        value = value - tmpValue;

                    } else {
                        iValue = value;
                        value = 0;
                    }
                    // remove from sender
                    _reduceMinimum(
                        _userStructFrom,
                        _dataList[i],//timestampEnd,
                        iValue,
                        true
                    );
                    // uint256 speed = iValue.div(
                        //     users[from].minimums[_dataList[i]].timestampEnd.sub(block.timestamp);
                        // );

                    // shouldn't add miniums for zero account.
                    // that feature using to drop minimums from sender
                    //if (to != ZERO_ADDRESS) {
                    if (!isTransferToZeroAddress) {
                        _minimumsAddLow(_userStructTo, block.timestamp, _dataList[i], iValue, true);
                    }
                    if (value == 0) {
                        break;
                    }
                    


                } // if (block.timestamp <= users[from].minimums[_dataList[i]].timestampEnd) {
            } // end for
            
   
        }
        
        // if (value != 0) {
            // todo 0: what this?
            // _appendMinimum(
            //     to,
            //     block.timestamp,//block.timestamp.add(minTimeDiff),
            //     value,
            //     false
            // );
        // }
     
        
    }

    /**
    * @dev gives index interval. here we deliberately making a loss precision(div before mul) to get the same index during interval.
    * @param ts unixtimestamp
    */
    function getIndexInterval(uint256 ts, uint64 interval) internal pure returns(uint256) {
        return ts / interval * interval;
    }
    
    // useful method to sort native memory array 
    function sortAsc(uint256[] memory data) private returns(uint[] memory) {
       quickSortAsc(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSortAsc(uint[] memory arr, int left, int right) private {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAsc(arr, left, j);
        if (i < right)
            quickSortAsc(arr, i, right);
    }

 


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IHook {
    // uses in initialing. fo example to link hook and caller of this hook
    function setupCaller() external;

    


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IHook.sol";
interface IRewards is IHook {

    function initialize(
        address sellingToken,
        uint256[] memory timestamps,
        uint256[] memory prices,
        uint256[] memory thresholds,
        uint256[] memory bonuses
    ) external;

    function onClaim(address account) external;

    function onUnstake(address instance, address account, uint64 duration, uint256 amount, uint64 rewardsFraction) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TrustedForwarder is Initializable {

    address private _trustedForwarder;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __TrustedForwarder_init() internal onlyInitializing {
        _trustedForwarder = address(0);
    }


    /**
    * @dev setup trusted forwarder address
    * @param forwarder trustedforwarder's address to set
    * @custom:shortd setup trusted forwarder
    * @custom:calledby owner
    */
    function _setTrustedForwarder(
        address forwarder
    ) 
        internal 
      //  onlyOwner 
        //excludeTrustedForwarder 
    {
        //require(owner() != forwarder, "FORWARDER_CAN_NOT_BE_OWNER");
        _trustedForwarder = forwarder;
    }
    function setTrustedForwarder(address forwarder) public virtual;
    /**
    * @dev checking if forwarder is trusted
    * @param forwarder trustedforwarder's address to check
    * @custom:shortd checking if forwarder is trusted
    */
    function isTrustedForwarder(
        address forwarder
    ) 
        external
        view 
        returns(bool) 
    {
        return _isTrustedForwarder(forwarder);
    }

    /**
    * @dev implemented EIP-2771
    */
    function _msgSender(
    ) 
        internal 
        view 
        virtual
        returns (address signer) 
    {
        signer = msg.sender;
        if (msg.data.length>=20 && _isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96,calldataload(sub(calldatasize(),20)))
            }
        }    
    }

    // function transferOwnership(
    //     address newOwner
    // ) public 
    //     virtual 
    //     override 
    //     onlyOwner 
    // {
    //     require(msg.sender != _trustedForwarder, "DENIED_FOR_FORWARDER");
    //     if (newOwner == _trustedForwarder) {
    //         _trustedForwarder = address(0);
    //     }
    //     super.transferOwnership(newOwner);
        
    // }

    function _isTrustedForwarder(
        address forwarder
    ) 
        internal
        view 
        returns(bool) 
    {
        return forwarder == _trustedForwarder;
    }


  

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICostManager.sol";
import "./interfaces/ICostManagerFactoryHelper.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract CostManagerBase is Initializable {
    using AddressUpgradeable for address;

    address public costManager;
    address public deployer;

    /** 
    * @dev sets the costmanager token
    * @param costManager_ new address of costmanager token, or 0
    */
    function overrideCostManager(address costManager_) external {
        // require factory owner or operator
        // otherwise needed deployer(!!not contract owner) in cases if was deployed manually
        require (
            (deployer.isContract()) 
                ?
                    ICostManagerFactoryHelper(deployer).canOverrideCostManager(_sender(), address(this))
                :
                    deployer == _sender()
            ,
            "cannot override"
        );
        
        _setCostManager(costManager_);
    }

    function __CostManagerHelper_init(address deployer_) internal onlyInitializing
    {
        deployer = deployer_;
    }

     /**
     * @dev Private function that tells contract to account for an operation
     * @param info uint256 The operation ID (first 8 bits). in other bits any else info
     * @param param1 uint256 Some more information, if any
     * @param param2 uint256 Some more information, if any
     */
    function _accountForOperation(uint256 info, uint256 param1, uint256 param2) internal {
        if (costManager != address(0)) {
            try ICostManager(costManager).accountForOperation(
                _sender(), info, param1, param2
            )
            returns (uint256 /*spent*/, uint256 /*remaining*/) {
                // if error is not thrown, we are fine
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
                revert(reason);
            } catch {
                revert("unknown error");
            }
        }
    }
    
    function _setCostManager(address costManager_) internal {
        costManager = costManager_;
    }
    
    function _sender() internal virtual returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICostManagerFactoryHelper {
    
    function canOverrideCostManager(address account, address instance) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICostManager/* is IERC165Upgradeable*/ {
    function accountForOperation(
        address sender, 
        uint256 info, 
        uint256 param1, 
        uint256 param2
    ) 
        external 
        returns(uint256, uint256);
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
interface IERC777Upgradeable {
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
interface IERC777SenderUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC1820RegistryUpgradeable {
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