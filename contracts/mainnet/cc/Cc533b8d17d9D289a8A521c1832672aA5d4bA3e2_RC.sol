// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IPair.sol";

contract RC is Ownable {
    using SafeERC20 for IERC20;

    struct Subscription {
        bool active;
        uint256 validityPeriod;
        uint256 priceInQuoteToken;
        address paymentToken;
        address exchangePair;
        uint256 recoveryTokenLimit;
        uint256 penaltyBP; //penalty for late payment (without an insured event)
        uint256 erc20FeeBP; // commission from all erc20 balances for late payment (insured event)
        uint256 erc20PenaltyBP; // penalty from all erc20 balances in case of an insured event (not exist if there is a commission above)
    }

    struct Insurance {
        bool autopayment;
        uint256 subscriptionID;
        uint256 expirationTime;
        uint256 voteQuorum;
        uint256 rcCount;
        address backupWallet;
        address[] validators;
    }

    struct NFTinfo {
        address nftAddress;
        uint256[] ids;
    }

    struct Propose {
        bool executed;
        address newBackupWallet;
        uint256 deadline;
        uint256 executionTime;
        uint256 votersBits;
    }

    enum ProposalState {
        Unknown,
        Failed,
        Executed,
        Active,
        Succeeded,
        ExecutionWaiting
    }

    uint256 public constant EXECUTION_LOCK_PERIOD = 1 days;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant BASE_POINT = 10000;
    uint256 public constant MAX_ERC20_PENALTY_BP = 2000; // 20%
    uint256 public constant MAX_ERC20_FEE_BP = 1000; // 10%
    uint256 public constant MAX_FEE_PENALTY_BP = 10000; // +100%
    uint256 public constant MAX_VALIDATORS = 30;
    uint256 public constant TRIAL_ID = 0;
    uint256 public constant PREMIUM_ID = 1;
    uint256 public constant FREEMIUM_ID = 2;
    uint256 private constant PREMIUM_PRICE = 7000; // in quoteToken without decimals
    address public immutable quoteTokenAddress;
    address public feeAddress;
    address public paymentAdmin;

    //   insurance creator => Insurance
    mapping(address => Insurance) public insurances;

    //   insurance creator => Propose
    mapping(address => Propose) public proposals;

    Subscription[] public subscriptions;

    modifier validSubscriptionID(uint256 _sid) {
        require(
            _sid < subscriptions.length && subscriptions[_sid].active,
            "subscription is not valid"
        );
        _;
    }

    event AutopaymentChanged(address user, bool active);
    event BackupWalletChanged(address user, address newBackupWallet);
    event SubscriptionsAdded(Subscription _subscription);
    event SubscriptionStateChanged(uint256 subscriptionID, bool active);
    event ValidatorsChanged(
        address user,
        uint256 newVoteQuorum,
        address[] newValidators
    );

    event CreateInsurance(
        address creator,
        uint256 priceInPaymentToken,
        Insurance userInsurance
    );
    event UpgradeInsurancePlan(
        address user,
        uint256 newSubscriptionID,
        uint256 expirationTime,
        uint256 priceInPaymentToken
    );
    event BillPayment(
        address payer,
        address insuranceOwner,
        uint256 amountInPaymentToken,
        uint256 newexpirationTime,
        bool withPenalty
    );
    event InsuranceEvent(
        address insuranceOwner,
        address backupWallet,
        uint256 recoveryTokensCount
    );
    event ProposalCreated(
        address insuranceOwner,
        address newBackupWallet,
        address proposer
    );
    event Vote(
        address insuranceOwner,
        address newBackupWallet,
        address validator
    );
    event ProposalConfirmed(address insuranceOwner, address newBackupWallet);
    event ProposalExecuted(address insuranceOwner, address newBackupWallet);

    constructor(
        address _feeAddress,
        address _paymentAdmin,
        address _quoteTokenAddress
    ) {
        // TRIAL
        subscriptions.push(
            Subscription(
                true,
                30 days,
                0,
                address(0),
                address(0),
                1, //recoveryTokenLimit
                0, // penaltyBP +100%
                200, //erc20FeeBP 2%
                0 // erc20PenaltyBP 20%
            )
        );

        uint256 premiumPrice = PREMIUM_PRICE *
            10 ** IERC20Metadata(_quoteTokenAddress).decimals();
        // PREMIUM
        subscriptions.push(
            Subscription(
                true,
                36500 days,
                premiumPrice,
                _quoteTokenAddress,
                address(0),
                0, //recoveryTokenLimit
                10000, // penaltyBP +100%
                200, //erc20FeeBP 2%
                2000 // erc20PenaltyBP 20%
            )
        );
        // FREEMIUM
        subscriptions.push(
            Subscription(
                true,
                300000 days,
                0,
                address(0),
                address(0),
                1, //recoveryTokenLimit
                0, // penaltyBP +100%
                200, //erc20FeeBP 2%
                0 // erc20PenaltyBP 20%
            )
        );

        feeAddress = _feeAddress;
        paymentAdmin = _paymentAdmin;
        quoteTokenAddress = _quoteTokenAddress;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @param _paymentAdmin: address of the auto payment bot
     */
    function setPaymentAdminAddress(address _paymentAdmin) external onlyOwner {
        paymentAdmin = _paymentAdmin;
    }

    /**
     * @notice add new payment plan
     */
    function addSubscription(
        Subscription calldata _subscription
    ) external onlyOwner {
        if (_subscription.priceInQuoteToken > 0) {
            //not free
            IPair pair = IPair(_subscription.exchangePair);
            address token0 = pair.token0();
            address token1 = pair.token1();
            require(
                (token0 == quoteTokenAddress &&
                    token1 == _subscription.paymentToken) ||
                    (token0 == _subscription.paymentToken &&
                        token1 == quoteTokenAddress),
                "bad exchangePair address"
            );
        }
        require(
            _subscription.validityPeriod > 0,
            "validityPeriod cannot be zero"
        );
        require(
            _subscription.erc20FeeBP <= MAX_ERC20_FEE_BP,
            "erc20FeeBP is too large"
        );
        require(
            _subscription.erc20PenaltyBP <= MAX_ERC20_PENALTY_BP,
            "erc20PenaltyBP is too large"
        );
        require(
            _subscription.penaltyBP <= MAX_FEE_PENALTY_BP,
            "penaltyBP is too large"
        );
        subscriptions.push(_subscription);
        emit SubscriptionsAdded(_subscription);
    }

    /**
     * @notice activate-deactivate a subscription
     */
    function subscriptionStateChange(
        uint256 _sId,
        bool _active
    ) external onlyOwner {
        subscriptions[_sId].active = _active;
        emit SubscriptionStateChanged(_sId, _active);
    }

    function getPriceInPaymentToken(
        address _pair,
        uint256 _priceInQuoteToken
    ) public view returns (uint256) {
        if (_priceInQuoteToken > 0) {
            IPair pair = IPair(_pair);
            (uint112 reserves0, uint112 reserves1, ) = pair.getReserves();
            (uint112 reserveQuote, uint112 reserveBase) = pair.token0() ==
                quoteTokenAddress
                ? (reserves0, reserves1)
                : (reserves1, reserves0);

            if (reserveQuote > 0 && reserveBase > 0) {
                return (_priceInQuoteToken * reserveBase) / reserveQuote + 1;
            } else {
                revert("can't determine price");
            }
        } else {
            return 0;
        }
    }

    function checkInsurance(
        address _insuranceOwner
    ) private view returns (Insurance memory) {
        Insurance memory userInsurance = insurances[_insuranceOwner];
        require(
            userInsurance.backupWallet != address(0),
            "insurance not found"
        );
        return userInsurance;
    }

    /**
     * @notice the weight of the validator's vote in case of repetition of the address in _validators increases
     */
    function setValidators(
        address[] calldata _validators,
        uint256 _voteQuorum
    ) external {
        require(_validators.length <= MAX_VALIDATORS, "too many validators");
        require(_validators.length >= _voteQuorum, "bad quorum value");
        Insurance memory userInsurance = checkInsurance(msg.sender);
        // reset current voting state
        delete proposals[msg.sender];
        userInsurance.validators = _validators;
        userInsurance.voteQuorum = _voteQuorum;
        insurances[msg.sender] = userInsurance;
        emit ValidatorsChanged(msg.sender, _voteQuorum, _validators);
    }

    // approve auto-renewal subscription ( auto payment )
    function setAutopayment(bool _autopayment) external {
        checkInsurance(msg.sender);
        insurances[msg.sender].autopayment = _autopayment;
        emit AutopaymentChanged(msg.sender, _autopayment);
    }

    function setBackupWallet(address _backupWallet) external {
        checkInsurance(msg.sender);
        insurances[msg.sender].backupWallet = _backupWallet;
        emit BackupWalletChanged(msg.sender, _backupWallet);
    }

    function createInsurance(
        address _backupWallet,
        address[] calldata _validators,
        uint256 _voteQuorum,
        uint256 _subscriptionID,
        bool _autopayment
    ) external validSubscriptionID(_subscriptionID) {
        Insurance memory userInsurance = insurances[msg.sender];
        Subscription memory paymentPlan = subscriptions[_subscriptionID];

        require(
            userInsurance.backupWallet == address(0) || // create new
                (userInsurance.subscriptionID == TRIAL_ID &&
                    _subscriptionID != TRIAL_ID), // after trial
            "already created"
        );
        require(
            _backupWallet != address(0),
            "backupWallet cannot be zero address"
        );

        require(_validators.length >= _voteQuorum, "bad _voteQuorum value");
        require(_validators.length <= MAX_VALIDATORS, "too many validators");

        delete proposals[msg.sender];

        uint256 priceInPaymentToken;

        if (_subscriptionID == PREMIUM_ID) {
            priceInPaymentToken = paymentPlan.priceInQuoteToken;
        } else if (paymentPlan.priceInQuoteToken > 0) {
            priceInPaymentToken = getPriceInPaymentToken(
                paymentPlan.exchangePair,
                paymentPlan.priceInQuoteToken
            );
        }

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
        }
        uint256 expirationTime = block.timestamp + paymentPlan.validityPeriod;
        userInsurance = Insurance({
            autopayment: _autopayment,
            subscriptionID: _subscriptionID,
            expirationTime: expirationTime,
            voteQuorum: _voteQuorum,
            rcCount: 0,
            backupWallet: _backupWallet,
            validators: _validators
        });

        insurances[msg.sender] = userInsurance;

        emit CreateInsurance(msg.sender, priceInPaymentToken, userInsurance);
    }

    function upgradeInsurancePlan(
        uint256 _subscriptionID
    ) external validSubscriptionID(_subscriptionID) {
        Insurance memory userInsurance = checkInsurance(msg.sender);

        require(_subscriptionID != TRIAL_ID, "can`t up to TRIAL");
        require(
            userInsurance.subscriptionID != _subscriptionID,
            "already upgraded"
        );
        
        require(
            block.timestamp <= userInsurance.expirationTime ||
                subscriptions[userInsurance.subscriptionID].priceInQuoteToken ==
                0,
            "current insurance expired,payment require"
        );

        Subscription memory paymentPlan = subscriptions[_subscriptionID];

        userInsurance.subscriptionID = _subscriptionID;
        userInsurance.expirationTime =
            block.timestamp +
            paymentPlan.validityPeriod;

        uint256 priceInPaymentToken;
        if (_subscriptionID == PREMIUM_ID) {
            priceInPaymentToken = paymentPlan.priceInQuoteToken;
        } else if (paymentPlan.priceInQuoteToken > 0) {
            priceInPaymentToken = getPriceInPaymentToken(
                paymentPlan.exchangePair,
                paymentPlan.priceInQuoteToken
            );
        }

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
        }
        insurances[msg.sender] = userInsurance;

        emit UpgradeInsurancePlan(
            msg.sender,
            _subscriptionID,
            userInsurance.expirationTime,
            priceInPaymentToken
        );
    }

    /**
     * @notice auto-renewal of the insurance subscription by the payment bot(paymentAdmin)
     */
    function autoPayment(address insuranceOwner) external {
        require(paymentAdmin == msg.sender, "paymentAdmin only");
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(block.timestamp > userInsurance.expirationTime, "too early");
        require(userInsurance.autopayment, "autopayment disabled");
        _billPayment(insuranceOwner, insuranceOwner, userInsurance, false);
        insurances[insuranceOwner] = userInsurance;
    }

    /**
     * @notice renewal of the insurance subscription by the creator
     */
    function billPayment() external {
        Insurance memory userInsurance = checkInsurance(msg.sender);
        _billPayment(msg.sender, msg.sender, userInsurance, false);
        insurances[msg.sender] = userInsurance;
    }

    function _billPayment(
        address payer,
        address insuranceOwner,
        Insurance memory userInsurance,
        bool penalty
    ) private {
        Subscription memory userPaymentPlan = subscriptions[
            userInsurance.subscriptionID
        ];
        require(
            userPaymentPlan.priceInQuoteToken > 0,
            "not allowed for a free subscription"
        );
        uint256 paymentDebtInQuoteToken;
        uint256 debtPeriods;
        if (block.timestamp > userInsurance.expirationTime) {
            unchecked {
                debtPeriods =
                    (block.timestamp - userInsurance.expirationTime) /
                    userPaymentPlan.validityPeriod;
            }
            paymentDebtInQuoteToken =
                debtPeriods *
                userPaymentPlan.priceInQuoteToken;
        }

        uint256 amountInPaymentToken;
        if (userInsurance.subscriptionID == PREMIUM_ID) {
            amountInPaymentToken =
                userPaymentPlan.priceInQuoteToken +
                paymentDebtInQuoteToken;
        } else {
            amountInPaymentToken = getPriceInPaymentToken(
                userPaymentPlan.exchangePair,
                userPaymentPlan.priceInQuoteToken + paymentDebtInQuoteToken
            );
        }

        if (penalty) {
            amountInPaymentToken += ((amountInPaymentToken *
                userPaymentPlan.penaltyBP) / BASE_POINT);
        }

        IERC20(userPaymentPlan.paymentToken).safeTransferFrom(
            payer,
            feeAddress,
            amountInPaymentToken
        );

        userInsurance.expirationTime +=
            userPaymentPlan.validityPeriod *
            (debtPeriods + 1);

        emit BillPayment(
            payer,
            insuranceOwner,
            amountInPaymentToken,
            userInsurance.expirationTime,
            penalty
        );
    }

    /**
     * @notice wallet recovery
     * call from backup wallet
     * @param insuranceOwner: recovery wallet address
     * withdrawal info:
     * @param erc20Tokens: array of erc20 tokens
     * @param erc721Tokens: array of {address nftAddress;uint256[] ids;} objects
     * @param erc1155Tokens: array of {address nftAddress;uint256[] ids;} objects
     */
    function insuranceEvent(
        address insuranceOwner,
        IERC20[] calldata erc20Tokens,
        NFTinfo[] calldata erc721Tokens,
        NFTinfo[] calldata erc1155Tokens
    ) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(userInsurance.backupWallet == msg.sender, "backupWallet only");
        Subscription memory userPaymentPlan = subscriptions[
            userInsurance.subscriptionID
        ];

        if (userPaymentPlan.recoveryTokenLimit > 0) {
            userInsurance.rcCount += erc20Tokens.length;
            for (uint256 i = 0; i < erc721Tokens.length; i++) {
                userInsurance.rcCount += erc721Tokens[i].ids.length;
            }
            for (uint256 i = 0; i < erc1155Tokens.length; i++) {
                userInsurance.rcCount += erc1155Tokens[i].ids.length;
            }
            require(
                userInsurance.rcCount <= userPaymentPlan.recoveryTokenLimit,
                "recoveryTokenLimit exceeded"
            );
        }

        bool penalty;

        if (userInsurance.subscriptionID == FREEMIUM_ID) {
            require(
                erc20Tokens.length == 1 &&
                    address(erc20Tokens[0]) == quoteTokenAddress &&
                    erc721Tokens.length == 0 &&
                    erc1155Tokens.length == 0,
                "invalid tokens, the current subscription does not allow recovering these tokens"
            );
        }
        if (block.timestamp > userInsurance.expirationTime) {
            require(
                userInsurance.subscriptionID != TRIAL_ID,
                "trial period expired"
            );

            if (userPaymentPlan.priceInQuoteToken > 0) {
                penalty = true;
                // backupWallet is payer
                _billPayment(
                    msg.sender,
                    insuranceOwner,
                    userInsurance,
                    penalty
                );
            }
        }

        insurances[insuranceOwner] = userInsurance;

        // ERC20
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            uint256 balance = erc20Tokens[i].balanceOf(insuranceOwner);
            uint256 erc20PenaltyAmount;

            if (balance > 0) {
                erc20PenaltyAmount =
                    (
                        penalty
                            ? (balance * userPaymentPlan.erc20PenaltyBP)
                            : (balance * userPaymentPlan.erc20FeeBP)
                    ) /
                    BASE_POINT;
                if (erc20PenaltyAmount > 0) {
                    erc20Tokens[i].safeTransferFrom(
                        insuranceOwner,
                        feeAddress,
                        erc20PenaltyAmount
                    );
                }
                erc20Tokens[i].safeTransferFrom(
                    insuranceOwner,
                    msg.sender,
                    balance - erc20PenaltyAmount
                );
            }
        }

        // ERC721
        for (uint256 i = 0; i < erc721Tokens.length; i++) {
            NFTinfo memory nft721 = erc721Tokens[i];
            for (uint256 x = 0; x < nft721.ids.length; x++) {
                IERC721(nft721.nftAddress).safeTransferFrom(
                    insuranceOwner,
                    msg.sender,
                    nft721.ids[x]
                );
            }
        }

        // ERC1155
        for (uint256 i = 0; i < erc1155Tokens.length; i++) {
            NFTinfo memory nft1155 = erc1155Tokens[i];
            uint256[] memory batchBalances = new uint256[](nft1155.ids.length);
            for (uint256 x = 0; x < nft1155.ids.length; ++x) {
                batchBalances[x] = IERC1155(nft1155.nftAddress).balanceOf(
                    insuranceOwner,
                    nft1155.ids[x]
                );
            }
            IERC1155(nft1155.nftAddress).safeBatchTransferFrom(
                insuranceOwner,
                msg.sender,
                nft1155.ids,
                batchBalances,
                ""
            );
        }

        emit InsuranceEvent(insuranceOwner, msg.sender, userInsurance.rcCount);
    }

    function _getVotersCount(
        uint256 confirmed
    ) private pure returns (uint256 voiceCount) {
        while (confirmed > 0) {
            voiceCount += confirmed & 1;
            confirmed >>= 1;
        }
    }

    function getVotersCount(
        address insuranceOwner
    ) external view returns (uint256 voiceCount) {
        Propose memory proposal = proposals[insuranceOwner];
        voiceCount = _getVotersCount(proposal.votersBits);
    }

    function getValidators(
        address insuranceOwner
    ) external view returns (address[] memory) {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        return userInsurance.validators;
    }

    function getVoters(
        address insuranceOwner
    ) external view returns (address[] memory) {
        Propose memory proposal = proposals[insuranceOwner];
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        address[] memory voters = new address[](
            userInsurance.validators.length
        );
        if (voters.length > 0 && proposal.votersBits > 0) {
            uint256 count;
            for (uint256 i = 0; i < userInsurance.validators.length; i++) {
                if (proposal.votersBits & (1 << i) != 0) {
                    voters[count] = userInsurance.validators[i];
                    count++;
                }
            }

            assembly {
                mstore(voters, count)
            }
        }
        return voters;
    }

    function proposeChangeBackupWallet(
        address insuranceOwner,
        address newBackupWallet
    ) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(
            getProposalState(insuranceOwner) < ProposalState.Active,
            "voting in progress"
        );
        Propose storage proposal = proposals[insuranceOwner];
        bool isValidator;
        for (uint256 i = 0; i < userInsurance.validators.length; i++) {
            if (msg.sender == userInsurance.validators[i]) {
                if (!isValidator) {
                    proposal.votersBits = 0;
                    isValidator = true;
                }
                proposal.votersBits |= (1 << i);
            }
        }
        if (isValidator) {
            proposal.executed = false;
            proposal.newBackupWallet = newBackupWallet;

            emit ProposalCreated(insuranceOwner, newBackupWallet, msg.sender);

            if (
                _getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum
            ) {
                proposal.deadline = block.timestamp + 1;
                proposal.executionTime =
                    block.timestamp +
                    EXECUTION_LOCK_PERIOD;
                emit ProposalConfirmed(
                    insuranceOwner,
                    proposal.newBackupWallet
                );
            } else {
                proposal.deadline = block.timestamp + VOTING_PERIOD;
                proposal.executionTime =
                    block.timestamp +
                    VOTING_PERIOD +
                    EXECUTION_LOCK_PERIOD;
            }
        } else {
            revert("validators only");
        }
    }

    function confirmProposal(address insuranceOwner) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(
            getProposalState(insuranceOwner) == ProposalState.Active,
            "voting is closed"
        );

        Propose storage proposal = proposals[insuranceOwner];

        for (uint256 i = 0; i < userInsurance.validators.length; i++) {
            if (
                msg.sender == userInsurance.validators[i] &&
                proposal.votersBits & (1 << i) == 0
            ) {
                proposal.votersBits |= (1 << i);
            }
        }

        if (_getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum) {
            proposal.deadline = block.timestamp + 1;
            proposal.executionTime = block.timestamp + EXECUTION_LOCK_PERIOD;
            emit ProposalConfirmed(insuranceOwner, proposal.newBackupWallet);
        }
    }

    function executeProposal(address insuranceOwner) external {
        require(
            getProposalState(insuranceOwner) == ProposalState.ExecutionWaiting,
            "not yet ready for execution"
        );
        Propose storage proposal = proposals[insuranceOwner];
        Insurance storage userInsurance = insurances[insuranceOwner];
        proposal.executed = true;
        userInsurance.backupWallet = proposal.newBackupWallet;
        emit ProposalExecuted(insuranceOwner, userInsurance.backupWallet);
    }

    function getProposalState(
        address insuranceOwner
    ) public view returns (ProposalState) {
        Propose memory proposal = proposals[insuranceOwner];
        Insurance memory userInsurance = insurances[insuranceOwner];

        if (proposal.newBackupWallet != address(0)) {
            if (
                _getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum
            ) {
                if (proposal.executed) {
                    return ProposalState.Executed;
                }

                if (block.timestamp < proposal.executionTime) {
                    return ProposalState.Succeeded;
                }

                return ProposalState.ExecutionWaiting;
            }

            if (block.timestamp < proposal.deadline) {
                return ProposalState.Active;
            }

            return ProposalState.Failed;
        }

        return ProposalState.Unknown;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}