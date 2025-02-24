//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "./SaloonWallet.sol";

//  OBS: Better suggestions for calculating the APY paid on a fortnightly basis are welcomed.

contract BountyPool is Ownable, Initializable {
    using SafeERC20 for IERC20;
    //#################### State Variables *****************\\

    //todo possibly make this a constant
    address public manager;

    bool public APYdropped;

    uint256 public constant VERSION = 1;
    uint256 public constant BOUNTY_COMMISSION = 12 * 1e18;
    uint256 public constant PREMIUM_COMMISSION = 2 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;
    uint256 public constant YEAR = 365 days;

    uint256 public projectDeposit;
    uint256 public stakersDeposit;
    uint256 public bountyBalance = projectDeposit + stakersDeposit;

    uint256 public saloonBountyCommission;
    // bountyBalance - % commission

    uint256 public saloonPremiumFees;
    uint256 public premiumBalance;
    uint256 public desiredAPY;
    uint256 public poolCap;
    uint256 public lastTimePaid;
    uint256 public requiredPremiumBalancePerPeriod;
    uint256 public poolPeriod = 2 weeks;
    // amount => timelock
    mapping(uint256 => uint256) public projectWithdrawalTimeLock;
    // staker => last time premium was claimed
    mapping(address => uint256) public lastClaimed;
    // staker address => stakerInfo array
    mapping(address => StakerInfo[]) public staker;

    address[] public stakerList;
    // staker address => amount => timelock time
    mapping(address => mapping(uint256 => uint256)) public stakerTimelock;

    struct StakerInfo {
        uint256 stakerBalance;
        uint256 balanceTimeStamp;
    }

    struct APYperiods {
        uint256 timeStamp;
        uint256 periodAPY;
    }

    APYperiods[] public APYrecords;

    //#################### State Variables End *****************\\

    function initializeImplementation(address _manager) public initializer {
        manager = _manager;
    }

    //#################### Modifiers *****************\\

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    //todo  maybe make this check at the manager level ????
    modifier onlyManagerOrSelf() {
        require(
            msg.sender == manager || msg.sender == address(this),
            "Only manager allowed"
        );
        _;
    }

    //#################### Modifiers END *****************\\

    //#################### Functions *******************\\

    // ADMIN PAY BOUNTY public
    // this implementation uses investors funds first before project deposit,
    // future implementation might use a more hybrid and sophisticated splitting of costs.
    // todo cache variables to make it more gas effecient
    function payBounty(
        address _token,
        address _saloonWallet,
        address _hunter,
        uint256 _amount
    ) public onlyManager returns (bool) {
        // check if stakersDeposit is enough
        if (stakersDeposit >= _amount) {
            // decrease stakerDeposit
            stakersDeposit -= _amount;
            // cache length
            uint256 length = stakerList.length;
            // if staker deposit == 0
            if (stakersDeposit == 0) {
                for (uint256 i; i < length; ++i) {
                    // update stakerInfo struct
                    StakerInfo memory newInfo;
                    newInfo.balanceTimeStamp = block.timestamp;
                    newInfo.stakerBalance = 0;

                    address stakerAddress = stakerList[i]; //todo cache stakerList before
                    staker[stakerAddress].push(newInfo);

                    // deduct saloon commission and transfer
                    calculateCommissioAndTransferPayout(
                        _token,
                        _hunter,
                        _saloonWallet,
                        _amount
                    );

                    // todo Emit event with timestamp and amount
                    return true;
                }

                // clean stakerList array
                delete stakerList;
            }
            // calculate percentage of stakersDeposit
            uint256 percentage = _amount / stakersDeposit;
            // loop through all stakers and deduct percentage from their balances
            for (uint256 i; i < length; ++i) {
                address stakerAddress = stakerList[i]; //todo cache stakerList before
                uint256 arraySize = staker[stakerAddress].length - 1;
                uint256 oldStakerBalance = staker[stakerAddress][arraySize]
                    .stakerBalance;

                // update stakerInfo struct
                StakerInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakerBalance =
                    oldStakerBalance -
                    ((oldStakerBalance * percentage) / DENOMINATOR);

                staker[stakerAddress].push(newInfo);
            }

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            // todo Emit event with timestamp and amount

            return true;
        } else {
            // reset baalnce of all stakers
            uint256 length = stakerList.length;
            for (uint256 i; i < length; ++i) {
                // update stakerInfo struct
                StakerInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakerBalance = 0;

                address stakerAddress = stakerList[i]; //todo cache stakerList before
                staker[stakerAddress].push(newInfo);
            }
            // clean stakerList array
            delete stakerList;
            // if stakersDeposit not enough use projectDeposit to pay the rest
            uint256 remainingCost = _amount - stakersDeposit;
            // descrease project deposit by the remaining amount
            projectDeposit -= remainingCost;

            // set stakers deposit to 0
            stakersDeposit = 0;

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            // todo Emit event with timestamp and amount
            return true;
        }
    }

    function calculateCommissioAndTransferPayout(
        address _token,
        address _hunter,
        address _saloonWallet,
        uint256 _amount
    ) internal returns (bool) {
        // deduct saloon commission
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // transfer to hunter
        IERC20(_token).safeTransfer(_hunter, hunterPayout); //todo maybe transfer to payout address
        // transfer commission to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonCommission);

        return true;
    }

    // ADMIN HARVEST FEES public
    function collectSaloonPremiumFees(address _token, address _saloonWallet)
        external
        onlyManager
        returns (uint256)
    {
        // send current fees to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonPremiumFees);
        uint256 totalCollected = saloonPremiumFees;
        // reset claimable fees
        saloonPremiumFees = 0;

        return totalCollected;

        // todo emit event
    }

    // PROJECT DEPOSIT
    // project must approve this address first.
    function bountyDeposit(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // transfer from project account
        IERC20(_token).safeTransferFrom(_projectWallet, address(this), _amount);

        // update deposit variable
        projectDeposit += _amount;

        return true;
    }

    // PROJECT SET CAP
    function setPoolCap(uint256 _amount) external onlyManager {
        // todo two weeks time lock?
        poolCap = _amount;
    }

    // PROJECT SET APY
    // project must approve this address first.
    // project will have to pay upfront cost of full period on the first time.
    // this will serve two purposes:
    // 1. sign of good faith and working payment system
    // 2. if theres is ever a problem with payment the initial premium deposit can be used as a buffer so users can still be paid while issue is fixed.
    function setDesiredAPY(
        address _token,
        address _projectWallet,
        uint256 _desiredAPY
    ) external onlyManager returns (bool) {
        // set timelock on this???
        // make sure APY has right amount of decimals (1e18)

        // ensure there is enough premium balance to pay stakers new APY for a month
        uint256 currentPremiumBalance = premiumBalance;
        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap * _desiredAPY) /
            DENOMINATOR) / YEAR) * poolPeriod;
        // this might lead to leftover premium if project decreases APY, we will see what to do about that later
        if (currentPremiumBalance < newRequiredPremiumBalancePerPeriod) {
            // calculate difference to be paid
            uint256 difference = newRequiredPremiumBalancePerPeriod -
                currentPremiumBalance;
            // transfer to this address
            IERC20(_token).safeTransferFrom(
                _projectWallet,
                address(this),
                difference
            );
            // increase premium
            premiumBalance += difference;
        }

        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;

        // register new APYperiod
        APYperiods memory newAPYperiod;
        newAPYperiod.timeStamp = block.timestamp;
        newAPYperiod.periodAPY = _desiredAPY;
        APYrecords.push(newAPYperiod);

        // set APY
        desiredAPY = _desiredAPY;

        // disable instant withdrawals
        APYdropped = false;

        return true;
    }

    // PROJECT PAY weekly/monthly PREMIUM to this address
    // this address needs to be approved first
    function billFortnightlyPremium(address _token, address _projectWallet)
        public
        onlyManagerOrSelf
        returns (bool)
    {
        uint256 currentPremiumBalance = premiumBalance;
        uint256 minimumRequiredBalance = requiredPremiumBalancePerPeriod;
        uint256 stakersDeposits = stakersDeposit;
        // check if current premium balance is less than required
        if (currentPremiumBalance < minimumRequiredBalance) {
            uint256 lastPaid = lastTimePaid;
            uint256 paymentPeriod = poolPeriod;

            // check when function was called last time and pay premium according to how much time has passed since then.
            uint256 sinceLastPaid = block.timestamp - lastPaid;

            if (sinceLastPaid > paymentPeriod) {
                // multiple by `sinceLastPaid` instead of two weeks
                uint256 fortnightlyPremiumOwed = ((
                    ((stakersDeposits * desiredAPY) / DENOMINATOR)
                ) / YEAR) * sinceLastPaid;

                if (
                    !IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        fortnightlyPremiumOwed
                    )
                ) {
                    // if transfer fails APY is reset and premium is paid with new APY
                    // register new APYperiod

                    APYperiods memory newAPYperiod;
                    newAPYperiod.timeStamp = block.timestamp;
                    newAPYperiod.periodAPY = viewcurrentAPY();
                    APYrecords.push(newAPYperiod);
                    // set new APY
                    desiredAPY = viewcurrentAPY();

                    uint256 newFortnightlyPremiumOwed = (((stakersDeposits *
                        desiredAPY) / DENOMINATOR) / YEAR) * sinceLastPaid;
                    {
                        // Calculate saloon fee
                        uint256 saloonFee = (newFortnightlyPremiumOwed *
                            PREMIUM_COMMISSION) / DENOMINATOR;

                        // update saloon claimable fee
                        saloonPremiumFees += saloonFee;

                        // update premiumBalance
                        premiumBalance += newFortnightlyPremiumOwed;

                        lastTimePaid = block.timestamp;

                        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap *
                                desiredAPY) / DENOMINATOR) / YEAR) *
                                paymentPeriod;

                        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;
                    }
                    // try transferring again...
                    IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        newFortnightlyPremiumOwed
                    );
                    // enable instant withdrawals
                    APYdropped = true;

                    return true;
                } else {
                    // Calculate saloon fee
                    uint256 saloonFee = (fortnightlyPremiumOwed *
                        PREMIUM_COMMISSION) / DENOMINATOR;

                    // update saloon claimable fee
                    saloonPremiumFees += saloonFee;

                    // update premiumBalance
                    premiumBalance += fortnightlyPremiumOwed;

                    lastTimePaid = block.timestamp;

                    // disable instant withdrawals
                    APYdropped = false;

                    return true;
                }
            } else {
                uint256 fortnightlyPremiumOwed = (((stakersDeposit *
                    desiredAPY) / DENOMINATOR) / YEAR) * paymentPeriod;

                if (
                    !IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        fortnightlyPremiumOwed
                    )
                ) {
                    // if transfer fails APY is reset and premium is paid with new APY
                    // register new APYperiod
                    APYperiods memory newAPYperiod;
                    newAPYperiod.timeStamp = block.timestamp;
                    newAPYperiod.periodAPY = viewcurrentAPY();
                    APYrecords.push(newAPYperiod);
                    // set new APY
                    desiredAPY = viewcurrentAPY();

                    uint256 newFortnightlyPremiumOwed = (((stakersDeposit *
                        desiredAPY) / DENOMINATOR) / YEAR) * paymentPeriod;
                    {
                        // Calculate saloon fee
                        uint256 saloonFee = (newFortnightlyPremiumOwed *
                            PREMIUM_COMMISSION) / DENOMINATOR;

                        // update saloon claimable fee
                        saloonPremiumFees += saloonFee;

                        // update premiumBalance
                        premiumBalance += newFortnightlyPremiumOwed;

                        lastTimePaid = block.timestamp;

                        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap *
                                desiredAPY) / DENOMINATOR) / YEAR) *
                                paymentPeriod;

                        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;
                    }
                    // try transferring again...
                    IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        newFortnightlyPremiumOwed
                    );
                    // enable instant withdrawals
                    APYdropped = true;

                    return true;
                } else {
                    // Calculate saloon fee
                    uint256 saloonFee = (fortnightlyPremiumOwed *
                        PREMIUM_COMMISSION) / DENOMINATOR;

                    // update saloon claimable fee
                    saloonPremiumFees += saloonFee;

                    // update premiumBalance
                    premiumBalance += fortnightlyPremiumOwed;

                    lastTimePaid = block.timestamp;

                    // disable instant withdrawals
                    APYdropped = false;

                    return true;
                }
            }
        }
        return false;
    }

    // PROJECT EXCESS PREMIUM BALANCE WITHDRAWAL -- NOT SURE IF SHOULD IMPLEMENT THIS
    // timelock on this?

    function scheduleprojectDepositWithdrawal(uint256 _amount) external {
        projectWithdrawalTimeLock[_amount] = block.timestamp + poolPeriod;

        //todo emit event -> necessary to predict payout payment in the following week
        //todo OR have variable that gets updated with new values? - forgot what we discussed about this
    }

    // PROJECT DEPOSIT WITHDRAWAL
    function projectDepositWithdrawal(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external returns (bool) {
        // timelock on this.
        require(
            projectWithdrawalTimeLock[_amount] < block.timestamp &&
                projectWithdrawalTimeLock[_amount] != 0,
            "Timelock not finished or started"
        );

        projectDeposit -= _amount;
        IERC20(_token).safeTransfer(_projectWallet, _amount);
        // todo emit event
        return true;
    }

    // STAKING
    // staker needs to approve this address first
    function stake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // dont allow staking if stakerDeposit >= poolCap
        require(
            stakersDeposit + _amount <= poolCap,
            "Staking Pool already full"
        );
        uint256 arraySize = staker[_staker].length - 1;

        // Push to stakerList array if previous balance = 0
        if (staker[_staker][arraySize].stakerBalance == 0) {
            stakerList.push(_staker);
        }

        // update stakerInfo struct
        StakerInfo memory newInfo;
        newInfo.balanceTimeStamp = block.timestamp;
        newInfo.stakerBalance =
            staker[_staker][arraySize].stakerBalance +
            _amount;

        // save info to storage
        staker[_staker].push(newInfo);

        // increase global stakersDeposit
        stakersDeposit += _amount;

        // transferFrom to this address
        IERC20(_token).safeTransferFrom(_staker, address(this), _amount);

        return true;
    }

    function askForUnstake(address _staker, uint256 _amount)
        external
        onlyManager
        returns (bool)
    {
        uint256 arraySize = staker[_staker].length - 1;
        require(
            staker[_staker][arraySize].stakerBalance >= _amount,
            "Insuficcient balance"
        );

        stakerTimelock[_staker][_amount] = block.timestamp + poolPeriod;
        return true;
        //todo emit event -> necessary to predict payout payment in the following week
        //todo OR have variable that gets updated with new values? - forgot what we discussed about this
    }

    // UNSTAKING
    // allow instant withdraw if stakerDeposit >= poolCap or APY = 0%
    // otherwise have to wait for timelock period
    function unstake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // allow for immediate withdrawal if APY drops from desired APY
        // going to need to create an extra variable for storing this when apy changes for worse
        if (desiredAPY != 0 || APYdropped == true) {
            require(
                stakerTimelock[_staker][_amount] < block.timestamp &&
                    stakerTimelock[_staker][_amount] != 0,
                "Timelock not finished or started"
            );
            uint256 arraySize = staker[_staker].length - 1;

            // decrease staker balance
            // update stakerInfo struct
            StakerInfo memory newInfo;
            newInfo.balanceTimeStamp = block.timestamp;
            newInfo.stakerBalance =
                staker[_staker][arraySize].stakerBalance -
                _amount;

            address[] memory stakersList = stakerList;
            if (newInfo.stakerBalance == 0) {
                // loop through stakerlist
                uint256 length = stakersList.length; // can you do length on memory arrays?
                for (uint256 i; i < length; ) {
                    // find staker
                    if (stakersList[i] == _staker) {
                        // exchange it with last address in array
                        address lastAddress = stakersList[length - 1];
                        stakerList[length - 1] = _staker;
                        stakerList[i] = lastAddress;
                        // pop it
                        stakerList.pop();
                        break;
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
            // save info to storage
            staker[_staker].push(newInfo);

            // decrease global stakersDeposit
            stakersDeposit -= _amount;

            // transfer it out
            IERC20(_token).safeTransfer(_staker, _amount);

            return true;
        }
    }

    // claim premium
    function claimPremium(
        address _token,
        address _staker,
        address _projectWallet
    ) external onlyManager returns (uint256, bool) {
        // how many chunks of time (currently = 2 weeks) since lastclaimed?
        uint256 lastTimeClaimed = lastClaimed[_staker];
        uint256 sinceLastClaimed = block.timestamp - lastTimeClaimed;
        uint256 paymentPeriod = poolPeriod;
        StakerInfo[] memory stakerInfo = staker[_staker];
        uint256 stakerLength = stakerInfo.length;
        // if last time premium was called > 1 period

        if (sinceLastClaimed > paymentPeriod) {
            uint256 totalPremiumToClaim = calculatePremiumToClaim(
                lastTimeClaimed,
                stakerInfo,
                stakerLength
            );
            // Calculate saloon fee
            uint256 saloonFee = (totalPremiumToClaim * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            totalPremiumToClaim -= saloonFee;
            uint256 owedPremium = totalPremiumToClaim;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billFortnightlyPremium(_token, _projectWallet);
                // if function above changes APY than accounting is going to get messed up,
                // because the APY used for for new transfer will be different than APY used to calculate totalPremiumToClaim
                // if function above fails then it fails...
            }

            // update premiumBalance
            premiumBalance -= totalPremiumToClaim;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        } else {
            // calculate currently owed for the week
            uint256 owedPremium = (((stakerInfo[stakerLength - 1]
                .stakerBalance * desiredAPY) / DENOMINATOR) / YEAR) *
                poolPeriod;
            // pay current period owed

            // Calculate saloon fee
            uint256 saloonFee = (owedPremium * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            owedPremium -= saloonFee;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billFortnightlyPremium(_token, _projectWallet);
                // if function above changes APY than accounting is going to get messed up,
                // because the APY used for for new transfer will be different than APY used to calculate totalPremiumToClaim
                // if function above fails then it fails...
            }

            // update premium
            premiumBalance -= owedPremium;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        }
    }

    function calculatePremiumToClaim(
        uint256 _lastTimeClaimed,
        StakerInfo[] memory _stakerInfo,
        uint256 _stakerLength
    ) internal view returns (uint256) {
        uint256 length = APYrecords.length;
        // loop through APY periods (reversely) until last missed period is found
        uint256 lastMissed;
        uint256 totalPremiumToClaim;
        for (uint256 i = length - 1; i == 0; --i) {
            if (APYrecords[i].timeStamp < _lastTimeClaimed) {
                lastMissed = i + 1;
            }
        }
        // loop through all missed periods
        for (uint256 i = lastMissed; i < length; ++i) {
            uint256 periodStart = APYrecords[i].timeStamp;
            // period end end is equal NOW for last APY that has been set
            uint256 periodEnd = APYrecords[i + 1].timeStamp != 0
                ? APYrecords[i + 1].timeStamp
                : block.timestamp;
            uint256 periodLength = periodEnd - periodStart;
            // loop through stakers balance fluctiation during this period

            uint256 periodTotalBalance;
            for (uint256 j; j < _stakerLength; ++j) {
                // check staker balance at that moment
                if (
                    _stakerInfo[j].balanceTimeStamp > periodStart &&
                    _stakerInfo[j].balanceTimeStamp < periodEnd
                ) {
                    // add it to that period total
                    periodTotalBalance += _stakerInfo[j].stakerBalance;
                }
            }

            //calcualte owed APY for that period: (APY * amount / Seconds in a year) * number of seconds in X period
            totalPremiumToClaim +=
                (((periodTotalBalance * desiredAPY) / DENOMINATOR) / YEAR) *
                periodLength;
        }

        return totalPremiumToClaim;
    }

    ///// VIEW FUNCTIONS /////

    // View currentAPY
    function viewcurrentAPY() public view returns (uint256) {
        uint256 apy = premiumBalance / poolCap;
        return apy;
    }

    // View total balance
    function viewHackerPayout() external view returns (uint256) {
        uint256 saloonCommission = (bountyBalance * BOUNTY_COMMISSION) /
            DENOMINATOR;
        return bountyBalance - saloonCommission;
    }

    // View stakersDeposit balance
    function viewStakersDeposit() external view returns (uint256) {
        return stakersDeposit;
    }

    // View deposit balance
    function viewProjecDeposit() external view returns (uint256) {
        return projectDeposit;
    }

    // view premium balance
    function viewPremiumBalance() external view returns (uint256) {
        return premiumBalance;
    }

    // view required premium balance
    function viewRequirePremiumBalance() external view returns (uint256) {
        return requiredPremiumBalancePerPeriod;
    }

    // View APY
    function viewDesireAPY() external view returns (uint256) {
        return desiredAPY;
    }

    // View Cap
    function viewPoolCap() external view returns (uint256) {
        return poolCap;
    }

    // View user staking balance
    function viewUserStakingBalance(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        uint256 length = staker[_staker].length;
        return (
            staker[_staker][length - 1].stakerBalance,
            staker[_staker][length - 1].balanceTimeStamp
        );
    }

    //todo view user current claimable premium ???

    //todo view version???

    ///// VIEW FUNCTIONS END /////
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        return true;
    }

    // THIS FUNCTION HAS BEEN EDITED TO RETURN A VALUE
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        return true;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SaloonWallet {
    using SafeERC20 for IERC20;

    uint256 public constant BOUNTY_COMMISSION = 12 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;

    address public immutable manager;

    // premium fees to collect
    uint256 public premiumFees;
    uint256 public saloonTotalBalance;
    uint256 public cummulativeCommission;
    uint256 public cummulativeHackerPayouts;

    // hunter balance per token
    // hunter address => token address => amount
    mapping(address => mapping(address => uint256)) public hunterTokenBalance;

    // saloon balance per token
    // token address => amount
    mapping(address => uint256) public saloonTokenBalance;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    // bountyPaid
    function bountyPaid(
        address _token,
        address _hunter,
        uint256 _amount
    ) external onlyManager {
        // calculate commision
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // update variables and mappings
        hunterTokenBalance[_hunter][_token] += hunterPayout;
        cummulativeHackerPayouts += hunterPayout;
        saloonTokenBalance[_token] += saloonCommission;
        saloonTotalBalance += saloonCommission;
        cummulativeCommission += saloonCommission;
    }

    function premiumFeesCollected(address _token, uint256 _amount)
        external
        onlyManager
    {
        saloonTokenBalance[_token] += _amount;
        premiumFees += _amount;
        saloonTotalBalance += _amount;
    }

    //
    // WITHDRAW FUNDS TO ANY ADDRESS saloon admin
    function withdrawSaloonFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyManager returns (bool) {
        require(_amount <= saloonTokenBalance[_token], "not enough balance");
        // decrease saloon funds
        saloonTokenBalance[_token] -= _amount;
        saloonTotalBalance -= _amount;

        IERC20(_token).safeTransfer(_to, _amount);

        return true;
    }

    ///////////////////////   VIEW FUNCTIONS  ////////////////////////

    // VIEW SALOON CURRENT TOTAL BALANCE
    function viewSaloonBalance() external view returns (uint256) {
        return saloonTotalBalance;
    }

    // VIEW COMMISSIONS PLUS PREMIUM
    function viewTotalEarnedSaloon() external view returns (uint256) {
        uint256 premiums = viewTotalPremiums();
        uint256 commissions = viewTotalSaloonCommission();

        return premiums + commissions;
    }

    // VIEW TOTAL PAYOUTS MADE - commission - fees
    function viewTotalHackerPayouts() external view returns (uint256) {
        return cummulativeHackerPayouts;
    }

    // view hacker payouts by hunter
    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return hunterTokenBalance[_hunter][_token];
    }

    // VIEW TOTAL COMMISSION
    function viewTotalSaloonCommission() public view returns (uint256) {
        return cummulativeCommission;
    }

    // VIEW TOTAL IN PREMIUMS
    function viewTotalPremiums() public view returns (uint256) {
        return premiumFees;
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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