// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Interfaces/IMultiLogicProxy.sol";
import "./Interfaces/AggregatorV3Interface.sol";

contract StorageV3 is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //struct
    struct DepositStruct {
        mapping(address => uint256) amount;
        mapping(address => int256) tokenTime; // 1: flag, 0: BNB
        uint256 iterate;
        uint256 balanceBLID;
        mapping(address => uint256) depositIterate;
    }

    struct EarnBLID {
        uint256 allBLID;
        uint256 timestamp;
        uint256 usd;
        uint256 tdt;
        mapping(address => uint256) rates;
    }

    struct BoostInfo {
        uint256 blidDeposit;
        uint256 rewardDebt;
        uint256 blidOverDeposit;
    }

    struct LeaveTokenPolicy {
        uint256 limit;
        uint256 leavePercentage;
        uint256 leaveFixed;
    }

    /*** events ***/

    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address depositor, address token, uint256 amount);
    event UpdateTokenBalance(uint256 balance, address token);
    event TakeToken(address token, uint256 amount);
    event ReturnToken(address token, uint256 amount);
    event AddEarn(uint256 amount);
    event UpdateBLIDBalance(uint256 balance);
    event InterestFee(address depositor, uint256 amount);
    event SetBLID(address blid);
    event AddToken(address token, address oracle);
    event SetMultiLogicProxy(address multiLogicProxy);
    event SetBoostingInfo(
        uint256 maxBlidPerUSD,
        uint256 blidPerBlock,
        uint256 maxActiveBLID
    );
    event DepositBLID(address depositor, uint256 amount);
    event WithdrawBLID(address depositor, uint256 amount);
    event ClaimBoostBLID(address depositor, uint256 amount);
    event SetBoostingAddress(address boostingAddress);
    event SetAdmin(address admin);
    event UpgradeVersion(string version, string purpose);
    event SetLeaveTokenPolicy(
        uint256 limit,
        uint256 leavePerentage,
        uint256 leaveFixed
    );

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
    }

    mapping(uint256 => EarnBLID) private earnBLID;
    uint256 private countEarns;
    uint256 private countTokens;
    mapping(uint256 => address) private tokens;
    mapping(address => uint256) private tokenBalance;
    mapping(address => address) private oracles;
    mapping(address => bool) private tokensAdd;
    mapping(address => DepositStruct) private deposits;
    mapping(address => uint256) private tokenDeposited;
    mapping(address => int256) private tokenTime;
    uint256 private reserveBLID;
    address public logicContract; // MultiLogicProxy : V3
    address private BLID;
    mapping(address => mapping(uint256 => uint256))
        public accumulatedRewardsPerShare;

    // ****** Add from V21 ******

    // Boost2.0
    mapping(address => BoostInfo) private userBoosts;
    uint256 public maxBlidPerUSD;
    uint256 public blidPerBlock;
    uint256 public accBlidPerShare;
    uint256 public lastRewardBlock;
    address public boostingAddress;
    uint256 public totalSupplyBLID;
    uint256 public maxActiveBLID;
    uint256 private activeSupplyBLID;

    address private constant ZERO_ADDRESS = address(0);

    // ****** Add from V3 ******

    // Adminable, Versionable
    address private _admin;
    string private _version;
    string private _purpose;

    // Leave Token Policy
    LeaveTokenPolicy private leaveTokenPolicy;

    // Deactivate token
    mapping(address => bool) private tokensActivate;

    // ETH Strategy
    receive() external payable {}

    /*** modifiers ***/

    modifier onlyUsedToken(address _token) {
        require(tokensAdd[_token], "E1");
        _;
    }

    modifier onlyMultiLogicProxy() {
        require(msg.sender == logicContract, "E8");
        _;
    }

    modifier isBLIDToken(address _token) {
        require(BLID == _token, "E1");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /*** Adminable/Versionable function ***/

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(
        string memory version,
        string memory purpose
    ) external onlyOwner {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }

    /*** Owner functions ***/

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        BLID = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set blid in contract
     * @param _boostingAddress address of expense
     */
    function setBoostingAddress(address _boostingAddress) external onlyOwner {
        boostingAddress = _boostingAddress;

        emit SetBoostingAddress(boostingAddress);
    }

    /**
     * @notice Set boosting parameters
     * @param _maxBlidperUSD max value of BLID per USD
     * @param _blidperBlock blid per Block
     * @param _maxActiveBLID max active BLID limit
     */
    function setBoostingInfo(
        uint256 _maxBlidperUSD,
        uint256 _blidperBlock,
        uint256 _maxActiveBLID
    ) external onlyOwner {
        // Initialize lastRewardBlock
        if (lastRewardBlock == 0) {
            lastRewardBlock = block.number;
        }

        _boostingUpdateAccBlidPerShare();

        maxBlidPerUSD = _maxBlidperUSD;
        blidPerBlock = _blidperBlock;
        maxActiveBLID = _maxActiveBLID;

        emit SetBoostingInfo(_maxBlidperUSD, _blidperBlock, _maxActiveBLID);
    }

    /**
     * @notice Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Add token and token's oracle
     * @param _token Address of Token
     * @param _oracles Address of token's oracle(https://docs.chain.link/docs/binance-smart-chain-addresses/
     */
    function addToken(address _token, address _oracles) external onlyOwner {
        require(_token != address(1) && _oracles != address(1));
        require(!tokensAdd[_token], "E6");
        oracles[_token] = _oracles;
        tokens[countTokens++] = _token;
        tokensAdd[_token] = true;
        tokensActivate[_token] = true;

        emit AddToken(_token, _oracles);
    }

    /**
     * @notice Set token activate / deactivate
     * @param _token Address of Token
     * @param status true : token is activate, false : token is deactivate
     */
    function setTokenActivate(address _token, bool status) external onlyOwner {
        tokensActivate[_token] = status;
    }

    /**
     * @notice Set MultiLogicProxy in contract(only for upgradebale contract,use only whith DAO)
     * @param _multiLogicProxy Address of MultiLogicProxy Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        logicContract = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /**
     * @notice Set LeaveTokenPolicy
     * @param limit Token limit for leavePercentage
     * @param leavePercentage Leave percentage before limit (0 - 9999)
     * @param leaveFixed Leave fixed after limit
     */
    function setLeaveTokenPolicy(
        uint256 limit,
        uint256 leavePercentage,
        uint256 leaveFixed
    ) external onlyOwner {
        require((limit * leavePercentage) / 10000 <= leaveFixed, "E15");

        leaveTokenPolicy.limit = limit;
        leaveTokenPolicy.leavePercentage = leavePercentage;
        leaveTokenPolicy.leaveFixed = leaveFixed;

        emit SetLeaveTokenPolicy(limit, leavePercentage, leaveFixed);
    }

    /*** User functions ***/

    /**
     * @notice Deposit amount of token for msg.sender
     * @param amount amount of token
     * @param token address of token
     */
    function deposit(
        uint256 amount,
        address token
    ) external payable onlyUsedToken(token) whenNotPaused {
        depositInternal(amount, token, msg.sender);
    }

    /**
     * @notice Deposit amount of token on behalf of depositor wallet
     * @param amount amount of token
     * @param token address of token
     * @param accountAddress Address of depositor
     */
    function depositOnBehalf(
        uint256 amount,
        address token,
        address accountAddress
    ) external payable onlyUsedToken(token) whenNotPaused {
        depositInternal(amount, token, accountAddress);
    }

    /**
     * @notice Withdraw amount of token  from Strategy and receiving earned tokens.
     * @param amount Amount of token
     * @param token Address of token
     */
    function withdraw(
        uint256 amount,
        address token
    ) external onlyUsedToken(token) whenNotPaused {
        uint8 decimals;

        if (token == address(0)) {
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 countEarns_ = countEarns;
        uint256 amountExp18 = amount * 10 ** (18 - decimals);
        DepositStruct storage depositor = deposits[msg.sender];
        require(depositor.amount[token] >= amountExp18 && amount > 0, "E4");
        if (amountExp18 > tokenBalance[token]) {
            uint256 requireReturnAmount = amount -
                (tokenBalance[token] / (10 ** (18 - decimals)));
            IMultiLogicProxy(logicContract).releaseToken(
                requireReturnAmount,
                token
            );
            interestFee(msg.sender);

            if (token == address(0)) {
                require(address(this).balance >= amount, "E9");
                _send(payable(msg.sender), amount);
            } else {
                IERC20Upgradeable(token).safeTransferFrom(
                    logicContract,
                    address(this),
                    requireReturnAmount
                );
                IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
            }

            tokenDeposited[token] -= amountExp18;
            tokenTime[token] -= int256(block.timestamp * (amountExp18));
            tokenBalance[token] = 0;

            // Because balance = 0, set Available to be 0
            IMultiLogicProxy(logicContract).setLogicTokenAvailable(0, token, 2);
        } else {
            interestFee(msg.sender);
            if (token == address(0)) {
                _send(payable(msg.sender), amount);
            } else {
                IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
            }

            // Calculate requiredLeave and set available for strategy
            uint256 requiredLeaveOld = _calcRequiredTokenLeave(
                token,
                tokenDeposited[token]
            );
            uint256 requiredLeaveNow = _calcRequiredTokenLeave(
                token,
                tokenDeposited[token] - amountExp18
            );

            if (requiredLeaveNow > (tokenBalance[token] - amountExp18)) {
                // If withdraw can't reach to requiredLeave, make Avaliable to be zero
                IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                    0,
                    token,
                    2
                );
            } else {
                // if withdraw can reach to requiredLeave
                if (requiredLeaveOld <= requiredLeaveNow + amountExp18) {
                    // In normal case, amount will be decreased the gap between old/new requiredLeave
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        amount -
                            (requiredLeaveOld - requiredLeaveNow) /
                            10 ** (18 - decimals),
                        token,
                        0
                    );
                } else {
                    // If requiredLeave is decreased too much, available will be increased
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        (requiredLeaveOld - requiredLeaveNow) /
                            10 ** (18 - decimals) -
                            amount,
                        token,
                        1
                    );
                }
            }

            // Update balance, deposited
            tokenTime[token] -= int256(block.timestamp * (amountExp18));
            tokenBalance[token] -= amountExp18;
            tokenDeposited[token] -= amountExp18;
        }
        if (depositor.depositIterate[token] == countEarns_) {
            depositor.tokenTime[token] -= int256(
                block.timestamp * (amountExp18)
            );
        } else {
            depositor.tokenTime[token] =
                int256(
                    depositor.amount[token] *
                        earnBLID[countEarns_ - 1].timestamp
                ) -
                int256(block.timestamp * (amountExp18));
            depositor.depositIterate[token] = countEarns_;
        }
        depositor.amount[token] -= amountExp18;

        // Claim BoostingRewardBLID
        _claimBoostingRewardBLIDInternal(msg.sender, true);

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Withdraw(msg.sender, token, amountExp18);
    }

    /**
     * @notice Claim BLID to accountAddress
     * @param accountAddress account address for claim
     */
    function interestFee(address accountAddress) public {
        uint256 balanceUser = balanceEarnBLID(accountAddress);
        require(reserveBLID >= balanceUser, "E5");
        IERC20Upgradeable(BLID).safeTransfer(accountAddress, balanceUser);
        DepositStruct storage depositor = deposits[accountAddress];
        depositor.balanceBLID = balanceUser;
        depositor.iterate = countEarns;
        //unchecked is used because a check was made in require
        unchecked {
            depositor.balanceBLID = 0;
            reserveBLID -= balanceUser;
        }

        emit UpdateBLIDBalance(reserveBLID);
        emit InterestFee(accountAddress, balanceUser);
    }

    /*** Boosting User function ***/

    /**
     * @notice Deposit BLID token for boosting.
     * @param amount amount of token
     */
    function depositBLID(uint256 amount) external whenNotPaused {
        require(amount > 0, "E3");
        uint256 usdDepositAmount = balanceOf(msg.sender);
        require(usdDepositAmount > 0, "E11");

        BoostInfo storage userBoost = userBoosts[msg.sender];

        _claimBoostingRewardBLIDInternal(msg.sender, false);

        // Adjust blidOverDeposit
        uint256 totalAmount = userBoost.blidDeposit + amount;
        uint256 blidDepositLimit = (usdDepositAmount * maxBlidPerUSD) / 1e18;
        uint256 depositAmount = amount;
        if (totalAmount > blidDepositLimit) {
            uint256 overAmount = totalAmount - blidDepositLimit;
            userBoost.blidOverDeposit += overAmount;
            depositAmount = amount - overAmount;
        }

        userBoost.blidDeposit += depositAmount;
        totalSupplyBLID += amount;
        activeSupplyBLID += depositAmount;

        // Save rewardDebt
        userBoost.rewardDebt = (userBoost.blidDeposit * accBlidPerShare) / 1e18;

        // Interaction
        IERC20Upgradeable(BLID).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit DepositBLID(msg.sender, amount);
    }

    /**
     * @notice WithDraw BLID token for boosting.
     * @param amount amount of token
     */
    function withdrawBLID(uint256 amount) external whenNotPaused {
        require(amount > 0, "E3");
        BoostInfo storage userBoost = userBoosts[msg.sender];
        uint256 usdDepositAmount = balanceOf(msg.sender);
        require(
            amount <= userBoost.blidDeposit + userBoost.blidOverDeposit,
            "E12"
        );

        _claimBoostingRewardBLIDInternal(msg.sender, false);

        // Adjust blidOverDeposit
        uint256 oldBlidDeposit = userBoost.blidDeposit;
        uint256 totalAmount = oldBlidDeposit +
            userBoost.blidOverDeposit -
            amount;
        uint256 blidDepositLimit = (usdDepositAmount * maxBlidPerUSD) / 1e18;
        if (totalAmount > blidDepositLimit) {
            userBoost.blidDeposit = blidDepositLimit;
            userBoost.blidOverDeposit = totalAmount - blidDepositLimit;
        } else {
            userBoost.blidDeposit = totalAmount;
            userBoost.blidOverDeposit = 0;
        }

        totalSupplyBLID -= amount;
        activeSupplyBLID -= oldBlidDeposit - userBoost.blidDeposit;

        // Save rewardDebt
        userBoost.rewardDebt = (userBoost.blidDeposit * accBlidPerShare) / 1e18;

        // Interaction
        IERC20Upgradeable(BLID).safeTransfer(msg.sender, amount);

        emit WithdrawBLID(msg.sender, amount);
    }

    /**
     * @notice Claim Boosting Reward BLID to msg.sender
     */
    function claimBoostingRewardBLID() external {
        _claimBoostingRewardBLIDInternal(msg.sender, true);
    }

    /**
     * @notice get deposited Boosting BLID amount of user
     * @param _user address of user
     */
    function getBoostingBLIDAmount(
        address _user
    ) public view returns (uint256) {
        BoostInfo storage userBoost = userBoosts[_user];
        uint256 amount = userBoost.blidDeposit + userBoost.blidOverDeposit;
        return amount;
    }

    /*** MultiLogicProxy function ***/

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeToken(
        uint256 amount,
        address token
    ) external onlyMultiLogicProxy onlyUsedToken(token) {
        uint8 decimals;

        if (token == address(0)) {
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 amountExp18 = amount * 10 ** (18 - decimals);

        require(tokenBalance[token] >= amountExp18, "E18");
        tokenBalance[token] = tokenBalance[token] - amountExp18;

        // Interaction
        if (token == address(0)) {
            _send(payable(logicContract), amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(logicContract, amount);
        }

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit TakeToken(token, amountExp18);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnToken(
        uint256 amount,
        address token
    ) external onlyMultiLogicProxy onlyUsedToken(token) {
        uint8 decimals;

        if (token == address(0)) {
            require(address(this).balance >= amount, "E9");
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 amountExp18 = amount * 10 ** (18 - decimals);

        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransferFrom(
                logicContract,
                address(this),
                amount
            );
        }

        tokenBalance[token] = tokenBalance[token] + amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit ReturnToken(token, amountExp18);
    }

    /**
     * @notice Claim all BLID(from strategy and boost) for user
     */
    function claimAllRewardBLID() external {
        interestFee(msg.sender);
        _claimBoostingRewardBLIDInternal(msg.sender, true);
    }

    /**
     * @notice Take amount BLID from Logic contract  and distributes earned BLID
     * @param amount Amount of distributes earned BLID
     */
    function addEarn(uint256 amount) external onlyMultiLogicProxy {
        IERC20Upgradeable(BLID).safeTransferFrom(
            logicContract,
            address(this),
            amount
        );
        reserveBLID += amount;
        int256 _dollarTime = 0;
        uint256 countTokens_ = countTokens;
        uint256 countEarns_ = countEarns;
        EarnBLID storage thisEarnBLID = earnBLID[countEarns_];
        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            (, int256 latestAnswer, , , ) = oracle.latestRoundData();

            thisEarnBLID.rates[token] = (uint256(latestAnswer) *
                10 ** (18 - oracle.decimals()));

            // count all deposited token in usd
            thisEarnBLID.usd +=
                tokenDeposited[token] *
                thisEarnBLID.rates[token];

            // convert token time to dollar time
            _dollarTime += tokenTime[token] * int256(thisEarnBLID.rates[token]);
        }
        require(_dollarTime != 0, "E16");
        thisEarnBLID.allBLID = amount;
        thisEarnBLID.timestamp = block.timestamp;
        thisEarnBLID.tdt = uint256(
            (int256(((block.timestamp) * thisEarnBLID.usd)) - _dollarTime) /
                (1 ether)
        ); // count delta of current token time and all user token time

        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            tokenTime[token] = int256(tokenDeposited[token] * block.timestamp); // count curent token time
            updateAccumulatedRewardsPerShareById(token, countEarns_);
        }
        thisEarnBLID.usd /= (1 ether);
        countEarns++;

        emit AddEarn(amount);
        emit UpdateBLIDBalance(reserveBLID);
    }

    /*** External function ***/

    /**
     * @notice Counts the number of accrued СSR
     * @param account Address of Depositor
     */
    function _upBalance(address account) external {
        deposits[account].balanceBLID = balanceEarnBLID(account);
        deposits[account].iterate = countEarns;
    }

    /***  Public View function ***/

    /**
     * @notice Return earned blid
     * @param account Address of Depositor
     */
    function balanceEarnBLID(address account) public view returns (uint256) {
        DepositStruct storage depositor = deposits[account];
        if (depositor.tokenTime[address(1)] == 0 || countEarns == 0) {
            return 0;
        }
        if (countEarns == depositor.iterate) return depositor.balanceBLID;

        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        uint256 depositorIterate = depositor.iterate;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            //if iterate when user deposited
            if (depositorIterate == depositor.depositIterate[token]) {
                sum += getEarnedInOneDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
                sum += getEarnedInOneNotDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
            } else {
                sum += getEarnedInOneNotDepositedIterate(
                    depositorIterate - 1,
                    token,
                    account
                );
            }
        }

        return sum + depositor.balanceBLID;
    }

    /**
     * @notice Return usd balance of account
     * @param account Address of Depositor
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            sum += _calcUSDPrice(token, deposits[account].amount[token]);
        }
        return sum;
    }

    /**
     * @notice Return sums of all distribution BLID.
     */
    function getBLIDReserve() external view returns (uint256) {
        return reserveBLID;
    }

    /**
     * @notice Return deposited usd
     */
    function getTotalDeposit() external view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            sum += _calcUSDPrice(token, tokenDeposited[token]);
        }
        return sum;
    }

    /**
     * @notice Returns the balance of token on this contract
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return tokenBalance[token];
    }

    /**
     * @notice Return deposited token from account
     */
    function getTokenDeposit(
        address account,
        address token
    ) external view returns (uint256) {
        return deposits[account].amount[token];
    }

    /**
     * @notice Return true if _token  is in token list
     * @param _token Address of Token
     */
    function _isUsedToken(address _token) external view returns (bool) {
        return tokensAdd[_token];
    }

    /**
     * @notice Return true if _token  is in activated
     * @param _token Address of Token
     */
    function isActivatedToken(address _token) external view returns (bool) {
        return (tokensAdd[_token] && tokensActivate[_token]);
    }

    /**
     * @notice Return count distribution BLID token.
     */
    function getCountEarns() external view returns (uint256) {
        return countEarns;
    }

    /**
     * @notice Return data on distribution BLID token.
     * First return value is amount of distribution BLID token.
     * Second return value is a timestamp when  distribution BLID token completed.
     * Third return value is an amount of dollar depositedhen  distribution BLID token completed.
     */
    function getEarnsByID(
        uint256 id
    ) external view returns (uint256, uint256, uint256) {
        return (earnBLID[id].allBLID, earnBLID[id].timestamp, earnBLID[id].usd);
    }

    /**
     * @notice Return amount of all deposited token
     * @param token Address of Token
     */
    function getTokenDeposited(address token) external view returns (uint256) {
        return tokenDeposited[token];
    }

    /**
     * @notice Return all added tokens
     */
    function getUsedTokens() external view returns (address[] memory) {
        uint256 countTokens_ = countTokens;
        address[] memory ret = new address[](countTokens_);
        for (uint256 i = 0; i < countTokens_; i++) {
            ret[i] = tokens[i];
        }
        return ret;
    }

    /**
     * @notice Get LeaveTokenPolicy
     */
    function getLeaveTokenPolicy()
        external
        view
        returns (LeaveTokenPolicy memory)
    {
        return leaveTokenPolicy;
    }

    /**
     * @notice Return pending BLID amount for boost to see on frontend
     * @param _user address of user
     */

    function getBoostingClaimableBLID(
        address _user
    ) external view returns (uint256) {
        BoostInfo storage userBoost = userBoosts[_user];
        uint256 _accBLIDpershare = accBlidPerShare;
        if (block.number > lastRewardBlock) {
            uint256 passedBlockCount = block.number - lastRewardBlock + 1; // When claim, 1 block is added because of mining
            _accBLIDpershare =
                accBlidPerShare +
                (
                    activeSupplyBLID <= maxActiveBLID
                        ? (passedBlockCount * blidPerBlock)
                        : ((passedBlockCount * blidPerBlock * maxActiveBLID) /
                            activeSupplyBLID)
                );
        }
        uint256 calcAmount = (userBoost.blidDeposit * _accBLIDpershare) / 1e18;
        return
            calcAmount > userBoost.rewardDebt
                ? calcAmount - userBoost.rewardDebt
                : 0;
    }

    /*** Private Function ***/

    /**
     * @notice deposit token
     * @param amount Amount of deposit token
     * @param token Address of token
     * @param accountAddress Address of depositor
     */
    function depositInternal(
        uint256 amount,
        address token,
        address accountAddress
    ) internal {
        require(tokensActivate[token], "E14");
        require(amount > 0, "E3");
        uint8 decimals;

        if (token == address(0)) {
            require(msg.value >= amount, "E9");
            decimals = 18; // For BNB we fix decimals as 18 - chainlink shows 8
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        DepositStruct storage depositor = deposits[accountAddress];

        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        uint256 amountExp18 = amount * 10 ** (18 - decimals);
        if (depositor.tokenTime[address(1)] == 0) {
            depositor.iterate = countEarns;
            depositor.depositIterate[token] = countEarns;
            depositor.tokenTime[address(1)] = 1;
            depositor.tokenTime[token] += int256(
                block.timestamp * (amountExp18)
            );
        } else {
            interestFee(accountAddress);
            if (depositor.depositIterate[token] == countEarns) {
                depositor.tokenTime[token] += int256(
                    block.timestamp * (amountExp18)
                );
            } else {
                depositor.tokenTime[token] = int256(
                    depositor.amount[token] *
                        earnBLID[countEarns - 1].timestamp +
                        block.timestamp *
                        (amountExp18)
                );

                depositor.depositIterate[token] = countEarns;
            }
        }
        depositor.amount[token] += amountExp18;

        // Calculate requiredLeave and set available for strategy
        uint256 requiredLeaveOld = _calcRequiredTokenLeave(
            token,
            tokenDeposited[token]
        );

        uint256 requiredLeaveNow = _calcRequiredTokenLeave(
            token,
            tokenDeposited[token] + amountExp18
        );

        if (requiredLeaveNow > (tokenBalance[token] + amountExp18)) {
            // If deposit can't reach to requiredLeave, make Avaliable to be zero
            IMultiLogicProxy(logicContract).setLogicTokenAvailable(0, token, 2);
        } else {
            // if deposit can to reach requiredLeave
            if (tokenBalance[token] >= requiredLeaveOld) {
                // If the previous balance is more then requiredLeave, amount will be decreased the gap between old/new requiredLeave
                if (amountExp18 >= (requiredLeaveNow - requiredLeaveOld)) {
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        amount -
                            (requiredLeaveNow - requiredLeaveOld) /
                            10 ** (18 - decimals),
                        token,
                        1
                    );
                } else {
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        (requiredLeaveNow - requiredLeaveOld) /
                            10 ** (18 - decimals) -
                            amount,
                        token,
                        0
                    );
                }
            } else {
                // If the preivous balance is less than requiredLeave, amount will be decreased to reach to requiredLeaveNew
                if (amountExp18 >= (requiredLeaveNow - tokenBalance[token])) {
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        amount -
                            (requiredLeaveNow - tokenBalance[token]) /
                            10 ** (18 - decimals),
                        token,
                        1
                    );
                } else {
                    IMultiLogicProxy(logicContract).setLogicTokenAvailable(
                        (requiredLeaveNow - tokenBalance[token]) /
                            10 ** (18 - decimals) -
                            amount,
                        token,
                        0
                    );
                }
            }
        }

        // Update balance, deposited
        tokenTime[token] += int256(block.timestamp * (amountExp18));
        tokenBalance[token] += amountExp18;
        tokenDeposited[token] += amountExp18;

        // Claim BoostingRewardBLID
        _claimBoostingRewardBLIDInternal(accountAddress, true);

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Deposit(accountAddress, token, amountExp18);
    }

    // Safe blid transfer function, just in case if rounding error causes pool to not have enough BLIDs.
    function safeBlidTransfer(address _to, uint256 _amount) internal {
        IERC20Upgradeable(BLID).safeTransferFrom(boostingAddress, _to, _amount);
    }

    /**
     * @notice Count accumulatedRewardsPerShare
     * @param token Address of Token
     * @param id of accumulatedRewardsPerShare
     */
    function updateAccumulatedRewardsPerShareById(
        address token,
        uint256 id
    ) private {
        EarnBLID storage thisEarnBLID = earnBLID[id];
        //unchecked is used because if id = 0 then  accumulatedRewardsPerShare[token][id-1] equal zero
        unchecked {
            accumulatedRewardsPerShare[token][id] =
                accumulatedRewardsPerShare[token][id - 1] +
                ((thisEarnBLID.allBLID *
                    (thisEarnBLID.timestamp - earnBLID[id - 1].timestamp) *
                    thisEarnBLID.rates[token]) / thisEarnBLID.tdt);
        }
    }

    /**
     * @notice Count user rewards in one iterate, when he  deposited
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function getEarnedInOneDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        EarnBLID storage thisEarnBLID = earnBLID[depositIterate];
        DepositStruct storage thisDepositor = deposits[account];
        return
            (// all distibution BLID multiply to
            thisEarnBLID.allBLID *
                // delta of  user dollar time and user dollar time if user deposited in at the beginning distibution
                uint256(
                    int256(
                        thisDepositor.amount[token] *
                            thisEarnBLID.rates[token] *
                            thisEarnBLID.timestamp
                    ) -
                        thisDepositor.tokenTime[token] *
                        int256(thisEarnBLID.rates[token])
                )) /
            //div to delta of all users dollar time and all users dollar time if all users deposited in at the beginning distibution
            thisEarnBLID.tdt /
            (1 ether);
    }

    /**
     * @notice Claim Boosting Reward BLID to msg.sender
     * @param userAccount address of account
     * @param isAdjust true : adjust userBoost.blidDeposit, false : not update userBoost.blidDeposit
     */
    function _claimBoostingRewardBLIDInternal(
        address userAccount,
        bool isAdjust
    ) private {
        _boostingUpdateAccBlidPerShare();
        BoostInfo storage userBoost = userBoosts[userAccount];
        uint256 calcAmount;
        if (userBoost.blidDeposit > 0) {
            calcAmount = (userBoost.blidDeposit * accBlidPerShare) / 1e18;
            if (calcAmount > userBoost.rewardDebt) {
                calcAmount -= userBoost.rewardDebt;
                safeBlidTransfer(userAccount, calcAmount);
            }
        }

        // Adjust blidDeposit
        if (isAdjust) {
            uint256 usdDepositAmount = balanceOf(userAccount);
            uint256 blidDepositLimit = (usdDepositAmount * maxBlidPerUSD) /
                1e18;
            uint256 totalAmount = userBoost.blidDeposit +
                userBoost.blidOverDeposit;

            // Update boosting info
            if (totalAmount > blidDepositLimit) {
                userBoost.blidDeposit = blidDepositLimit;
                userBoost.blidOverDeposit = totalAmount - blidDepositLimit;
            } else {
                userBoost.blidDeposit = totalAmount;
                userBoost.blidOverDeposit = 0;
            }

            // Update rewards debt
            userBoost.rewardDebt =
                (userBoost.blidDeposit * accBlidPerShare) /
                1e18;
        }

        emit ClaimBoostBLID(userAccount, calcAmount);
    }

    /**
     * @notice update Accumulated BLID per share
     */
    function _boostingUpdateAccBlidPerShare() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 passedBlockCount = block.number - lastRewardBlock;
        accBlidPerShare =
            accBlidPerShare +
            (
                activeSupplyBLID <= maxActiveBLID
                    ? (passedBlockCount * blidPerBlock)
                    : ((passedBlockCount * blidPerBlock * maxActiveBLID) /
                        activeSupplyBLID)
            );
        lastRewardBlock = block.number;
    }

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "E10");
    }

    /*** Private View Function ***/

    /**
     * @notice Count user rewards in one iterate, when he was not deposit
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function getEarnedInOneNotDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        return
            ((accumulatedRewardsPerShare[token][countEarns - 1] -
                accumulatedRewardsPerShare[token][depositIterate]) *
                deposits[account].amount[token]) / (1 ether);
    }

    /**
     * @notice Calculate price in USD
     * returns USD in Exp18 format
     * @param token Address of Token with Exp18 expression
     * @param amountExp18 token amount with Exp18 expression
     */
    function _calcUSDPrice(
        address token,
        uint256 amountExp18
    ) private view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(oracles[token]);
        (, int256 latestAnswer, , , ) = oracle.latestRoundData();
        return ((amountExp18 *
            uint256(latestAnswer) *
            10 ** (18 - oracle.decimals())) / (1 ether));
    }

    /**
     * @notice Calculate required leave token base on totalDeposit amount
     * returns requiredTokenLeave balance in Exp18 expression
     * @param token Address of Token
     * @param depositTotalExp18 total token depositedwith Exp18 expression
     */
    function _calcRequiredTokenLeave(
        address token,
        uint256 depositTotalExp18
    ) private view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(oracles[token]);
        (, int256 latestAnswer, , , ) = oracle.latestRoundData();
        uint8 decimals = oracle.decimals();

        uint256 limit = (leaveTokenPolicy.limit *
            10 ** (decimals) *
            (1 ether)) / uint256(latestAnswer);

        // 0 - limit : return leavePerentage %
        if (depositTotalExp18 <= limit)
            return
                (depositTotalExp18 * leaveTokenPolicy.leavePercentage) / 10000;

        // > limit : return leaveFixed
        return
            (leaveTokenPolicy.leaveFixed * 10 ** (decimals) * (1 ether)) /
            uint256(latestAnswer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);

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

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenAvailable(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getTokenTaken(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getUsedTokensStorage() external view returns (address[] memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
interface IERC20PermitUpgradeable {
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