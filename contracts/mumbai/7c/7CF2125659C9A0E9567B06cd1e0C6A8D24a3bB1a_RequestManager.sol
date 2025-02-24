// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBetFoundationFactory {
    function provideBetData(address betAddress_)
        external
        view
        returns (
            address,
            address,
            uint256,
            bool,
            bool
        );

    function raiseDispute(address betAddress_) external returns (bool);

    function postDisputeProcess(address betAddress_) external returns (bool);

    function createBet(
        address parentBet_,
        address betId_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_
    ) external payable returns (bool _status, address _betTrendSetter);

    function joinBet(
        address betAddress_,
        uint256 tokenLiqidity_,
        uint256 selectedOptionByUser_,
        uint256 tokenId_
    ) external payable returns (bool);

    function withdrawLiquidity(address betAddress_)
        external
        payable
        returns (bool);

    function resolveBet(
        address betAddress_,
        uint256 finalOption_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        bool isCustomized_
    ) external returns (bool);

    function banBet(address betAddress_)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IBetLiquidityHolder {
    function receiveLiquidityCreator(
        uint256 tokenLiquidity_,
        address tokenAddress_,
        address betCreator_,
        address betTrendSetter_
    ) external;

    function receiveLiquidityTaker(
        uint256 tokenLiquidity_,
        address betTaker_,
        address registry_,
        bool forwarderFlag_
    ) external;

    function withdrawLiquidity(address user_) external payable;

    function claimReward(
        address betWinnerAddress_,
        address betLooserAddress_,
        address registry_,
        address agreegatorAddress_
    ) external payable returns (bool);

    function processDrawMatch(address registry_)
        external
        payable
        returns (bool);

    function processBan(address registry_)
        external
        payable
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IDisputeResolution {
    function stake() external returns (bool);

    function withdraw() external returns (bool);

    function createDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function createDispute(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function processVerdict(
        bytes32 hash_,
        bytes memory signature_,
        uint256 selectedVerdict_,
        address betAddress_
    ) external returns (bool);

    function brodcastFinalVerdict(
        address betAddress_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function adminResolution(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        address[] memory users_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function getUserStrike(address user_) external view returns (uint256);

    function getJuryStrike(address user_) external view returns (uint256);

    function getBetStatus(address betAddress_)
        external
        view
        returns (bool, bool);

    function forwardVerdict(address betAddress_)
        external
        view
        returns (uint256);

    function adminResolutionForUnavailableEvidance(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function getUserVoteStatus(address user_, address betAddress)
        external
        view
        returns (bool);

    function getJuryStatistics(address user_)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getJuryVersion(address user_) external view returns (uint256);

    function adminWithdrawal(address user_) external returns (bool status_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ILiquidityHolderDeployer {
    function deployHolder() external returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IRequestManager {
    function setFoundationFactoryAddress(address foundationFactory_)
        external
        returns (bool);

    function setConfigAddress(address config_) external returns (bool);

    function setAggregatorAddress(address aggregator_) external returns (bool);

    function setDisputeResolverAddress(address disputeResolver_)
        external
        returns (bool);

    function ForwardCreateBet(
        address parentBet_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_
    ) external payable returns (bool _status, address _betTrendSetter);

    function ForwardJoinBet(
        address betAddress_,
        uint256 tokenLiqidity_,
        uint256 selectedOptionByUser_,
        uint256 tokenId_
    ) external payable returns (bool);

    function ForwardResolveBet(
        address betAddress_,
        uint256 finalOption_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        bool isCustomized_
    ) external returns (bool);

    function ForwardWithdrawLiquidity(address betAddress_)
        external
        payable
        returns (bool);

    function ForwardBanBet(address betAddress_)
        external
        returns (bool _status);

    function ForwardCreateDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function ForwardBypassDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function ForwardStaking() external returns (bool);

    function ForwardWithdrawal() external returns (bool);

    function ForwardBroadcastFinalVerdict(
        address betAddress_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function ForwardAdminResolutionForUnavailableEvidance(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function ForwardAdminResolution(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        address[] memory users_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Interfaces/IBetFoundationFactory.sol";
import "../Interfaces/IBetLiquidityHolder.sol";
import "../Interfaces/IRequestManager.sol";
import "../Interfaces/IDisputeResolution.sol";
import "../Interfaces/ILiquidityHolderDeployer.sol";

contract RequestManager is IRequestManager {
    address public admin;

    address public FoundationFactory;
    address public Config;
    address public Aggregators;
    address public DisputeResolver;
    address public LiquidityHolderDeployer;

    constructor(address admin_) public {
        require(admin_ != address(0), "ZERO ADDRESS");
        admin = admin_;
    }

    receive() external payable {}

    function setAdmin(address admin_) external returns (bool) {
        require(tx.origin == admin, "Caller Is Not Owner");
        admin = admin_;

        return true;
    }

    function setFoundationFactoryAddress(address foundationFactory_)
        external
        override
        returns (bool)
    {
        require(tx.origin == admin, "Caller Is Not Owner");
        FoundationFactory = foundationFactory_;

        return true;
    }

    function setConfigAddress(address config_)
        external
        override
        returns (bool)
    {
        require(tx.origin == admin, "Caller Is Not Owner");
        Config = config_;

        return true;
    }

    function setAggregatorAddress(address aggregator_)
        external
        override
        returns (bool)
    {
        require(tx.origin == admin, "Caller Is Not Owner");
        Aggregators = aggregator_;

        return true;
    }

    function setDisputeResolverAddress(address disputeResolver_)
        external
        override
        returns (bool)
    {
        require(tx.origin == admin, "Caller Is Not Owner");
        DisputeResolver = disputeResolver_;

        return true;
    }

    function setLiquidityHolderDeployer(address holderDeployer_)
        external
        returns (bool)
    {
        require(tx.origin == admin, "Caller Is Not Owner");
        LiquidityHolderDeployer = holderDeployer_;

        return true;
    }

    function ForwardCreateBet(
        address parentBet_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_
    )
        external
        payable
        override
        returns (bool _status, address _betTrendSetter)
    {
        address __holder = ILiquidityHolderDeployer(LiquidityHolderDeployer)
            .deployHolder();
        (_status, _betTrendSetter) = IBetFoundationFactory(FoundationFactory)
            .createBet{value: msg.value}(
            parentBet_,
            __holder,
            betTakerRequiredLiquidity_,
            betEndingTime_,
            tokenId_,
            totalBetOptions_,
            selectedOptionByUser_,
            tokenLiqidity_
        );
        return (_status, _betTrendSetter);
    }

    function ForwardJoinBet(
        address betAddress_,
        uint256 tokenLiqidity_,
        uint256 selectedOptionByUser_,
        uint256 tokenId_
    ) external payable override returns (bool _status) {
        (_status) = IBetFoundationFactory(FoundationFactory).joinBet{
            value: msg.value
        }(betAddress_, tokenLiqidity_, selectedOptionByUser_, tokenId_);
        return _status;
    }

    function ForwardResolveBet(
        address betAddress_,
        uint256 finalOption_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        bool isCustomized_
    ) external override returns (bool _status) {
        (_status) = IBetFoundationFactory(FoundationFactory).resolveBet(
            betAddress_,
            finalOption_,
            hash_,
            maker_,
            taker_,
            isCustomized_
        );

        return _status;
    }

    function ForwardWithdrawLiquidity(address betAddress_)
        external
        payable
        override
        returns (bool _status)
    {
        (_status) = IBetFoundationFactory(FoundationFactory).withdrawLiquidity(
            betAddress_
        );

        return _status;
    }

    function ForwardBanBet(address betAddress_)
        external
        override
        returns (bool _status)
    {
        (_status) = IBetFoundationFactory(FoundationFactory).banBet(
            betAddress_
        );

        return _status;
    }

    function ForwardCreateDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).createDispute(
            betAddress_,
            disputedOption_,
            hash_,
            signature_
        );

        return _status;
    }

    function ForwardBypassDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).createDisputeRoom(
            betAddress_,
            disputedOption_,
            hash_,
            signature_
        );

        return _status;
    }

    function ForwardStaking() external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).stake();

        return _status;
    }

    function ForwardWithdrawal() external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).withdraw();

        return _status;
    }

    function ForwardProvideVerdict(
        bytes32 hash_,
        bytes memory signature_,
        uint256 selectedVerdict_,
        address betAddress_
    ) external returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).processVerdict(
            hash_,
            signature_,
            selectedVerdict_,
            betAddress_
        );

        return _status;
    }

    function ForwardBroadcastFinalVerdict(
        address betAddress_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).brodcastFinalVerdict(
            betAddress_,
            hash_,
            maker_,
            taker_
        );

        return _status;
    }

    function ForwardAdminResolutionForUnavailableEvidance(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver)
            .adminResolutionForUnavailableEvidance(
                betAddress_,
                finalVerdictByAdmin_,
                hash_,
                maker_,
                taker_
            );

        return _status;
    }

    function ForwardAdminResolution(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        address[] memory users_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external override returns (bool _status) {
        (_status) = IDisputeResolution(DisputeResolver).adminResolution(
            betAddress_,
            finalVerdictByAdmin_,
            users_,
            hash_,
            maker_,
            taker_
        );

        return _status;
    }

    function ForwardGetBetData(address betAddress_)
        external
        view
        returns (
            address _betInitiator,
            address _betTaker,
            uint256 _totalBetOptions,
            bool _isDisputed,
            bool _betStatus
        )
    {
        (
            _betInitiator,
            _betTaker,
            _totalBetOptions,
            _isDisputed,
            _betStatus
        ) = IBetFoundationFactory(FoundationFactory).provideBetData(
            betAddress_
        );
    }

    function ForwardGetUserStrike(address user_)
        external
        view
        returns (uint256 _strike)
    {
        (_strike) = IDisputeResolution(DisputeResolver).getUserStrike(user_);
    }

    function ForwardGetJuryStrike(address user_)
        external
        view
        returns (uint256 _strike)
    {
        (_strike) = IDisputeResolution(DisputeResolver).getJuryStrike(user_);
    }

    function ForwardGetBetStatus(address betAddress_)
        external
        view
        returns (bool _resolutionStatus, bool _isResolvedByAdim)
    {
        (_resolutionStatus, _isResolvedByAdim) = IDisputeResolution(
            DisputeResolver
        ).getBetStatus(betAddress_);
    }

    function ForwardGetUserVoteStatus(address user_, address betAddress)
        external
        view
        returns (bool _status)
    {
        (_status) = IDisputeResolution(DisputeResolver).getUserVoteStatus(
            user_,
            betAddress
        );
    }

    function ForwardGetJuryStatistics(address user_)
        external
        view
        returns (
            uint256 usersStake_,
            uint256 lastWithdrawal_,
            uint256 userInitialStake_,
            bool isActiveStaker_,
            uint256 juryVerion_
        )
    {
        (
            usersStake_,
            lastWithdrawal_,
            userInitialStake_,
            isActiveStaker_
        ) = IDisputeResolution(DisputeResolver).getJuryStatistics(user_);
        juryVerion_ = IDisputeResolution(DisputeResolver).getJuryVersion(user_);
    }

    function ForwardAdminWithdrawal(address user_)
        external
        returns (bool status_)
    {
        status_ = IDisputeResolution(DisputeResolver).adminWithdrawal(user_);
    }
}