// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// ReetrancyGuard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Bucket.sol";

contract DistrictPower is ReentrancyGuard, Bucket {
    uint256 public constant PRINCIPAL_RATIO = 600000; // 60%  本金占比
    uint256 public constant INVEST_RATIO = 290000; // 29% 静态收益
    uint256 public constant PLATFORM_RATIO = 20000; // 2% 技术平台
    uint256 public constant REFERRER_RATIO = 50000; // 5% 团队
    uint256 public constant INCENTIVE_RATIO = 0; // 0% 激励
    uint256 public constant BUYBACK_RATIO = 20000; // 2% 代币回购
    uint256 public constant RECOMMENDREWARD_RATIO = 20000; // 2% 直推奖励
    uint256 public constant PRICE_PRECISION = 1e6; //1000000  100W比

    uint256 public constant ACCURACY = 1e18;//精度

    uint256 public constant DEFAULT_INVEST_RETURN_RATE = 10000; // 1% 默认投资回报率
    uint256 public constant BOOST_INVEST_RETURN_RATE = 5000; // 0.5% 提升投资回报率

    uint256 public constant MAX_INVEST = 1e3 * ACCURACY; // 1000 最大投资额
    uint256 public constant MIN_INVEST = 1e1 * ACCURACY; // 10 最小投资额

    uint256 public constant TIME_UNIT = 1 days;
    uint256[6] public DEFAULT_TARGET_AMOUNTS = [13e4 * ACCURACY, 25e4* ACCURACY, 35e4 * ACCURACY, 50e4 * ACCURACY, 75e4 * ACCURACY, 125e4 * ACCURACY]; //默认目标金额

    uint256 public constant MAX_SEARCH_DEPTH = 50;//最大搜索深度
    uint256 public constant RANKED_INCENTIVE = 60;//分级激励

    address public platformAddress; // will be paymentsplitter contract address  付款分割器合同地址  0x9ca75d0d97f0b86dea852eb0a626f7839673d9d9

    uint256[6] public currentEpochs; //当前纪元

    // ledge type => round epoch => address => position index => position info
    mapping(uint256 => mapping(address => PositionInfo[]))[6] public roundLedgers; //轮次数据
    //
    mapping(uint256 => RoundInfo)[6] public roundInfos;//轮次信息
    //
    mapping(address => UserRoundInfo[])[6] public userRoundsInfos;//轮次用户信息

    mapping(address => UserGlobalInfo) public userGlobalInfos;//用户全局信息

    mapping(address => address[]) public children; // used for easily retrieve the referrer tree structure from front-end 用于从前端轻松检索引用者树结构

    uint256 public totalFlowAmount;//资金总流水

    mapping(uint256 => uint256) public epochCurrentInvestAmount;

    // temp admin
    address public tempAdmin;//临时管理员
    address public operator;//操作人员
    bool public gamePaused;//游戏开关

    bool totalAmountMagicBox1000000;
    bool totalAmountMagicBox4000000;
    bool totalAmountMagicBox10000000;

    struct FundTarget {
        uint256 lastCheckTime;//最后办理时间
        uint256 amount;//数量
        uint256 achievedAmount;//完成的金额
    }

    struct UserGlobalInfo { //用户全局信息
        // referrer chain to record the referrer relationship 记录引用者关系的引用者链
        address referrer; //推荐人
        // referrer rearward vault
        uint256 totalReferrerReward; //总推荐奖励
        uint256 referrerRewardClaimed;//推荐人奖励认领
        // boost credit
        uint256 boostCredit;//提高金额
        // sales record
        uint256 maxChildrenSales;//最大下级销售量
        uint256 sales;//销售量
        uint256 totalPositionAmount;//总位置金额
        uint256 reportedSales;//公布的销售额
        uint8 salesLevel;//等级
    }

    struct PositionInfo { //位置信息
        uint256 amount;
        uint256 openTime;//开启时间
        uint256 expiryTime;//到期时间
        uint256 investReturnRate;//投资回报率
        uint256 withdrawnAmount;//退出金额
        uint256 incentiveAmount;//激励金额
        uint256 investReturnAmount;//投资回报金额
        uint256 index;//指数
        bool incentiveClaimable;//可申请索赔
    }

    struct LinkedPosition { //链接位置
        address user;
        uint256 userPositionIndex;//用户位置索引
    }

    struct RoundInfo { //轮次信息
        FundTarget fundTarget;
        uint256 totalPositionAmount; // total amount of all positions 所有职位的总金额
        uint256 currentPrincipalAmount; // current principal amount 当前本金金额
        uint256 currentInvestAmount; // current invest amount 当前剩余可提的金额
        uint256 totalPositionCount; // total count of all positions 所有职位总数
        uint256 currentPositionCount; // total count of all open positions 所有未平仓总计数
        uint256 currentIncentiveAmount; // current incentive amount 当前激励金额
        uint256 incentiveSnapshot; // check total position of last N positions 检查最后N个位置的总位置
        uint256 head; // head of linked position for last N positions 最后N个位置的链接位置头
        mapping(uint256 => LinkedPosition) linkedPositions; // used for incentive track 用于激励轨道
        mapping(address => uint256) ledgerRoundToUserRoundIndex; // 用户轮次信息 中的本轮索引
        bool stopLoss; // default false means the round is running 默认为false表示该轮正在运行
    }

    struct UserRoundInfo {//用户轮次信息
        uint256 epoch;//纪元
        uint256 totalPositionAmount;//总位置金额
        uint256 currentPrincipalAmount;//当前本金金额
        uint256 totalWithdrawnAmount;//总取款金额
        uint256 totalIncentiveClaimedAmount;//总激励申请金额
        uint256 totalClosedPositionCount;//总关闭位置计数
        uint256 returnRateBoostedAmount;//回报率提升金额
    }

    struct ReferrerSearch { //推荐人搜索
        uint256 currentUserSales; //当前用户销售额
        uint256 currentReferrerSales;//当前推荐销售
        address currentReferrer;//当前推荐人
        uint256 currentReferrerAmount;//当前参考金额
        uint256 levelDiffAmount;//极差金额
        uint256 leftLevelDiffAmount;//左极差金额
        uint256 levelDiffAmountPerLevel;//每个等级极差金额
        uint256 levelSearchAmount;//级别搜索金额
        uint256 leftLevelSearchAmount;//左级别搜索金额
        uint256 levelSearchAmountPerReferrer;//每个引用的搜索量级别
        uint256 levelSearchSales;//级别搜索销售
        uint256 currentReferrerMaxChildSales;//当前推荐人最大子销售额
        uint256 currentUserTotalPosAmount;//当前用户总位置金额
        uint256 currentUserReportedSales;//当前用户报告的销售额
        address currentUser;//当前用户
        uint8 depth;//深度
        uint8 levelSearchStep;//级别搜索步骤
        uint8 currentLevelDiff;//当前极差
        uint8 numLevelSearchCandidate;//等级搜索候选人数量
        uint8 baseSalesLevel;//基本销售等级
        uint8 currentReferrerLevel;//当前推荐人等级
        bool levelDiffDone;//极差
        bool levelSearchDone;//级别搜索
        bool levelSalesDone;//级别销售
    }

    struct OpenPositionParams { //打开位置参数
        uint256 principalAmount; //本金金额
        uint256 investAmount; //投资金额
        uint256 referrerAmount; //推荐人金额
        uint256 incentiveAmount;//激励金额
        uint256 investReturnRate;//投资回报率
    }

    event PositionOpened(//位置开放
        address indexed user,
        uint256 indexed ledgeType,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );

    event PositionClosed(//位置关闭
        address indexed user,
        uint256 indexed ledgeType,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );

    event NewReferrer(address indexed user, address indexed referrer);
    event NewRound(uint256 indexed epoch, uint256 indexed ledgeType);
    event ReferrerRewardAdded(address indexed user, uint256 amount, uint256 indexed rewardType); // type 0 for levelDiff, 1 for levelSearch, 2 for levelSearch
    event ReferrerRewardClaimed(address indexed user, uint256 amount);
    event SalesLevelUpdated(address indexed user, uint8 level);
    event IncentiveClaimed(address indexed user, uint256 amount);

    modifier notContract() {
        require(msg.sender == tx.origin, "Contract not allowed");
        _;
    }

    /**
     * @param _platformAddress The address of the platform
     * @param _tempAdmin The address of the temp admin
     * @param _operator The address of the operator
     */
    constructor(
        address _platformAddress,
        address _tempAdmin,
        address _operator
    ) {
        require(
            _platformAddress != address(0) && _tempAdmin != address(0) && _operator != address(0),
            "Invalid address provided"
        );
        emit NewRound(0, 0);
        emit NewRound(0, 1);
        emit NewRound(0, 2);
        emit NewRound(0, 3);
        emit NewRound(0, 4);
        emit NewRound(0, 5);

        //setStock(1, [2,3,4,5,6,7,8,9,10], [2,3,4,5,6,7,8,9,10]);
        (uint8[] memory typeDays1,uint16[] memory stock1) = generateTypeDaysAndStock(2, 10);
        setStock(1, typeDays1, stock1);
        // setStock(2,[11,12,13,14,15,16,17,18,19,20],[11,12,13,14,15,16,17,18,19,20]);
        (uint8[] memory typeDays2,uint16[] memory stock2) = generateTypeDaysAndStock(11, 20);
        setStock(2, typeDays2, stock2);
        // setStock(3,[21,22,23,24,25,26,27,28,29,30],[21,22,23,24,25,26,27,28,29,30]);
        (uint8[] memory typeDays3,uint16[] memory stock3) = generateTypeDaysAndStock(21, 30);
        setStock(3, typeDays3, stock3);

        tempAdmin = _tempAdmin;
        operator = _operator;
        platformAddress = _platformAddress;
        gamePaused = true;
    }

    function generateTypeDaysAndStock(uint8 start, uint8 end) internal pure returns (uint8[] memory, uint16[] memory) {
        require(start < end, "Invalid range");

        uint8 length = end - start + 1;
        uint8[] memory typeDays = new uint8[](length);
        uint16[] memory stock = new uint16[](length);

        for (uint8 i = start; i <= end; i++) {
            typeDays[i-start] = i;
            stock[i-start] = i;
        }

        return (typeDays, stock);
    }

    /**
     * @notice Set the game paused status
     * @param _paused: The game paused status
     */
    function setPause(bool _paused) external {
        require(msg.sender == operator, "Only operator");
        // make sure the admin has dropped when game is unpaused
        if (!_paused) {
            require(tempAdmin == address(0), "Temp admin not dropped");
        }
        gamePaused = _paused;
    }

    /**
     * @notice Transfer operator
     */
    function transferOperator(address _operator) external {
        require(msg.sender == operator, "Only operator");
        require(_operator != address(0), "Invalid address");
        operator = _operator;
    }

    /**
     * @notice Drop the temp admin privilege 放弃临时管理员
     */
    function dropTempAdmin() external {
        require(msg.sender == tempAdmin, "Only admin");
        tempAdmin = address(0);
    }

    /**
     * @notice Batch set referrer information for users
     * @param users: The users to set
     * @param referrers: The referrers to set
     * @param salesLevels: The sales levels to set
     */
    function batchSetReferrerInfo( //内定上级
        address[] calldata users,//要设置的用户
        address[] calldata referrers,//要设置的推荐人
        uint8[] calldata salesLevels//要设置的销售级别
    ) external {
        require(msg.sender == tempAdmin, "Only admin");
        require(users.length == referrers.length && users.length == salesLevels.length, "Invalid input");
        UserGlobalInfo storage userGlobalInfo;
        uint256 userLength = users.length;
        for (uint256 i = 0; i < userLength; ++i) {
            require(users[i] != address(0), "Invalid address provided");
            userGlobalInfo = userGlobalInfos[users[i]];
            require(userGlobalInfo.referrer == address(0), "Referrer already set");
            userGlobalInfo.referrer = referrers[i];
            userGlobalInfo.salesLevel = salesLevels[i];
            children[referrers[i]].push(users[i]);
        }
    }

    /**
     * @notice Set fixed stock distribution to specific ledger type
     * @param ledgerType: The ledger type to set
     * @param typeDays: The days to set
     * @param stock: The stock to set
     */
    function setStock(//设置盲盒
        uint256 ledgerType,
        uint8[] memory typeDays,
        uint16[] memory stock
    ) internal {
        require(ledgerType > 0, "Invalid ledger type");
        require(ledgerType < 6, "Invalid ledger type");
        // require(msg.sender == tempAdmin, "Only admin");
        require(stock.length > 0, "Invalid stock array");
        require(typeDays.length == stock.length, "Invalid params");

        _setStock(ledgerType, typeDays, stock);
    }

    function openPosition(
        address referrer //推荐人
    ) external payable notContract nonReentrant {
        require(msg.value >= MIN_INVEST, "Too small");
        require(msg.value <= MAX_INVEST, "Too large");
        require(!gamePaused, "Paused");

        // determine referrer 确定推荐人
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];
        address _referrer = userGlobalInfo.referrer;
        // if referrer is already set or msg.sender is the root user whose referrer is address(0)
        if (_referrer == address(0) && children[msg.sender].length == 0) {
            // if referrer is not set, set it and make sure it is a valid referrer
            require(referrer != address(0) && referrer != msg.sender, "Invalid referrer");
            // make sure referrer is registered already
            require(
                userGlobalInfos[referrer].referrer != address(0) || children[referrer].length > 0,
                "Invalid referrer"
            );

            // update storage 更新存储器
            userGlobalInfo.referrer = referrer;
            children[referrer].push(msg.sender);
            emit NewReferrer(msg.sender, referrer);
        }

        //发放直推奖励
        uint256 recommendReward = msg.value * RECOMMENDREWARD_RATIO / PRICE_PRECISION;
        (bool success, ) = msg.sender.call{value: recommendReward}("");
        require(success, "Transfer failed.");

        uint256 MagicBoxAmount1 =  msg.value * 35 / 100;
        uint256 MagicBoxAmount2 =  msg.value * 10 / 100;
        uint256 MagicBoxAmount3 =  msg.value * 15 / 100;
        uint256 MagicBoxAmount4 =  msg.value * 40 / 100;
        setPosition(MagicBoxAmount1,0);
        setPosition(MagicBoxAmount2,1);
        setPosition(MagicBoxAmount3,2);
        setPosition(MagicBoxAmount4,3);

        totalFlowAmount += msg.value;
        if(totalFlowAmount >= 1000000 * ACCURACY && !totalAmountMagicBox1000000){
            // setStock(2,[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]);
            (uint8[] memory typeDays2,uint16[] memory stock2) = generateTypeDaysAndStock(11, 30);
            setStock(2, typeDays2, stock2);
            // setStock(3,[31,32,33,34,35,36,37,38,39,40],[31,32,33,34,35,36,37,38,39,40]);
            (uint8[] memory typeDays3,uint16[] memory stock3) = generateTypeDaysAndStock(31, 40);
            setStock(3, typeDays3, stock3);
            totalAmountMagicBox1000000 = true;
        }
        if(totalFlowAmount >= 4000000 * ACCURACY && !totalAmountMagicBox4000000){
            // setStock(2,[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40],[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40]);
            (uint8[] memory typeDays2,uint16[] memory stock2) = generateTypeDaysAndStock(11, 40);
            setStock(2, typeDays2, stock2);
            // setStock(3,[41,42,43,44,45,46,47,48,49,50],[41,42,43,44,45,46,47,48,49,50]);
            (uint8[] memory typeDays3,uint16[] memory stock3) = generateTypeDaysAndStock(41, 50);
            setStock(3, typeDays3, stock3);
            totalAmountMagicBox4000000 = true;
        }
        if(totalFlowAmount >= 10000000 * ACCURACY && !totalAmountMagicBox10000000){
            // setStock(2,[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50],[11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50]);
            (uint8[] memory typeDays2,uint16[] memory stock2) = generateTypeDaysAndStock(11, 50);
            setStock(2, typeDays2, stock2);
            // setStock(3,[51,52,53,54,55,56,57,58,59,60],[51,52,53,54,55,56,57,58,59,60]);
            (uint8[] memory typeDays3,uint16[] memory stock3) = generateTypeDaysAndStock(51, 60);
            setStock(3, typeDays3, stock3);
            totalAmountMagicBox10000000 = true;
        }
    }

    /**
     * @notice Open a new position
     * @param ledgerType: The ledger type to open 要打开的分类帐类型
     */
    function setPosition ( //开盲盒  入金
        uint256 amountValue, //盲盒类型
        uint256 ledgerType //盲盒类型
    ) internal notContract nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");

        uint256 targetEpoch = currentEpochs[ledgerType];

        // load user global info 加载用户全局信息
        // UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];
        // load global round info 加载全局轮信息
        RoundInfo storage roundInfo = roundInfos[ledgerType][targetEpoch];
        // placeholder for user round info 用户轮信息占位符
        UserRoundInfo storage userRoundInfo;


        // calculate each part of the amount 计算每个部分的金额
        OpenPositionParams memory params = OpenPositionParams({
        principalAmount: (amountValue * PRINCIPAL_RATIO) / PRICE_PRECISION,//本金金额
        investAmount: (amountValue * INVEST_RATIO) / PRICE_PRECISION,//投资金额
        referrerAmount: (amountValue * REFERRER_RATIO) / PRICE_PRECISION,//推荐人金额
        incentiveAmount: (amountValue * INCENTIVE_RATIO) / PRICE_PRECISION,//激励金额
        investReturnRate: DEFAULT_INVEST_RETURN_RATE //投资回报率
        });

        // check target ratio 检查目标比率
        //        require(targetRate <= params.investReturnRate, "Invalid ratio");

        // update user's current ledger and current round info 更新用户的当前分类帐和本轮信息
        uint256 userRoundInfoLength = userRoundsInfos[ledgerType][msg.sender].length;
        if (
            userRoundInfoLength == 0 ||
            userRoundsInfos[ledgerType][msg.sender][userRoundInfoLength - 1].epoch < targetEpoch
        ) {
            // this is users first position in this round of this ledger type 这是此分类帐类型本轮中用户的第一个位置
            UserRoundInfo memory _userRoundInfo;
            _userRoundInfo = UserRoundInfo({
            epoch: targetEpoch,
            totalPositionAmount: 0,
            currentPrincipalAmount: 0,
            totalWithdrawnAmount: 0,
            totalIncentiveClaimedAmount: 0,
            totalClosedPositionCount: 0,
            returnRateBoostedAmount: 0
            });
            // push roundInfo to storage
            userRoundsInfos[ledgerType][msg.sender].push(_userRoundInfo);
            roundInfo.ledgerRoundToUserRoundIndex[msg.sender] = userRoundInfoLength;
            userRoundInfoLength += 1;
        }

        // fetch back the roundInfo from storage for further direct modification 从存储器中取回roundInfo以进行进一步的直接修改  修改用户数据
        userRoundInfo = userRoundsInfos[ledgerType][msg.sender][userRoundInfoLength - 1];
        userRoundInfo.totalPositionAmount += amountValue;
        userRoundInfo.currentPrincipalAmount += params.principalAmount;

        //update ledger round info 更新分类帐轮次信息
        roundInfo.totalPositionAmount += amountValue;
        roundInfo.currentPrincipalAmount += params.principalAmount;
        //roundInfo.currentInvestAmount += params.investAmount;
        epochCurrentInvestAmount[targetEpoch] += params.investAmount;
        roundInfo.currentPositionCount += 1;
        roundInfo.currentIncentiveAmount += params.incentiveAmount;
        roundInfo.incentiveSnapshot += amountValue;
        roundInfo.totalPositionCount += 1;

        uint256 userTotalPositionCount = roundLedgers[ledgerType][targetEpoch][msg.sender].length;
        // construct position info 构造位置信息
        {
            uint256 expiryTime = block.timestamp;
            if (ledgerType == 0) {
                expiryTime += TIME_UNIT;
            } else {
                expiryTime += _pickDay(ledgerType, roundInfo.totalPositionCount) * TIME_UNIT;
            }

            PositionInfo memory positionInfo = PositionInfo({
            amount: amountValue,
            openTime: block.timestamp,
            expiryTime: expiryTime,
            investReturnRate: params.investReturnRate,
            withdrawnAmount: 0,
            incentiveAmount: 0,
            investReturnAmount: 0,
            index: userTotalPositionCount,
            incentiveClaimable: true
            });

            if(expiryTime == TIME_UNIT){
                params.investReturnRate = 10000;
            }else if(expiryTime <= 10){
                params.investReturnRate = 6000;
            }else if(expiryTime <= 20){
                params.investReturnRate = 7000;
            }else if(expiryTime <= 30){
                params.investReturnRate = 8000;
            }else if(expiryTime <= 40){
                params.investReturnRate = 9000;
            }else if(expiryTime <= 50){
                params.investReturnRate = 9500;
            }else if(expiryTime <= 60){
                params.investReturnRate = 10000;
            }else{
                params.investReturnRate = 0;
            }

            // push position info to round ledgers 将位置信息推送到圆形账本
            roundLedgers[ledgerType][targetEpoch][msg.sender].push(positionInfo);
        }

        // distribute referrer funds 分配推荐人资金
        _distributeReferrerReward(amountValue, msg.sender, params.referrerAmount);

        {
            // ranked incentive track 排名激励轨道
            mapping(uint256 => LinkedPosition) storage linkedPositions = roundInfo.linkedPositions;

            // update the latest position (which is the current position) node
            LinkedPosition storage linkedPosition = linkedPositions[roundInfo.totalPositionCount - 1];
            linkedPosition.user = msg.sender;
            linkedPosition.userPositionIndex = userTotalPositionCount;

            // adjust head in order to keep track last N positions
            if (roundInfo.totalPositionCount - roundInfo.head > RANKED_INCENTIVE) {
                // fetch current head node
                LinkedPosition storage headLinkedPosition = linkedPositions[roundInfo.head];
                PositionInfo storage headPositionInfo = roundLedgers[ledgerType][targetEpoch][headLinkedPosition.user][
                headLinkedPosition.userPositionIndex
                ];
                // previous head position now is not eligible for incentive
                headPositionInfo.incentiveClaimable = false;
                // subtract head position amount, because we only keep the last RANKED_INCENTIVE positions
                roundInfo.incentiveSnapshot -= headPositionInfo.amount;
                // shift head to next global position to keep track the last N positions
                roundInfo.head += 1;
            }
        }

        // do transfer to platform
        {
            (bool success, ) = platformAddress.call{
            value: amountValue -
            params.principalAmount -
            params.investAmount -
            params.referrerAmount -
            params.incentiveAmount
            }("");
            require(success, "Transfer failed.");
        }
        // emit event
        emit PositionOpened(msg.sender, ledgerType, targetEpoch, userTotalPositionCount, amountValue);
    }

    /** 提出资金
     * @notice Close position
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndex: Position index of the user
     */
    function closePosition(
        uint256 ledgerType,
        uint256 epoch,
        uint256 positionIndex
    ) external notContract nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch <= currentEpochs[ledgerType], "Invalid epoch");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];
        require(positionIndex < positionInfos.length, "Invalid position index");

        // get position Info
        PositionInfo storage positionInfo = positionInfos[positionIndex];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        _safeClosePosition(ledgerType, epoch, positionIndex, positionInfo, roundInfo, userGlobalInfo);
    }

    /**
     * @notice Close a batch of positions
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClosePositions(
        uint256 ledgerType,
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch <= currentEpochs[ledgerType], "Invalid epoch");
        require(positionIndexes.length > 0, "Invalid position indexes");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // position info placeholder
        PositionInfo storage positionInfo;

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            require(positionIndexes[i] < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndexes[i]];
            _safeClosePosition(ledgerType, epoch, positionIndexes[i], positionInfo, roundInfo, userGlobalInfo);
        }
    }

    /** 批量索赔职位奖励
     * @notice Claim a batch of incentive claimable positions
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClaimPositionIncentiveReward(
        uint256 ledgerType,
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external notContract nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch < currentEpochs[ledgerType], "Epoch not finished");

        // get position infos
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];

        // get roundInfo
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // get user round info
        uint256 userRoundIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[ledgerType][msg.sender][userRoundIndex];

        // position info placeholder
        PositionInfo storage positionInfo;

        // collect payout
        uint256 payoutAmount;
        uint256 positionIndex;
        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            positionIndex = positionIndexes[i];
            require(positionIndex < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndex];
            require(positionInfo.incentiveClaimable, "Position not eligible");
            // update positionInfo
            payoutAmount += _safeProcessIncentiveAmount(positionInfo, roundInfo);
        }

        // transfer
        {
            (bool success, ) = msg.sender.call{value: payoutAmount}("");
            require(success, "Transfer failed.");
        }

        // update userRoundInfo
        userRoundInfo.totalIncentiveClaimedAmount += payoutAmount;
        emit IncentiveClaimed(msg.sender, payoutAmount);
    }

    /**
     * @notice Report a batch users' sales
     * @param users: list of users
     */
    function batchReportSales(address[] calldata users) external {
        uint256 usersLength = users.length;
        for (uint256 i = 0; i < usersLength; ++i) {
            _safeReportSales(users[i]);
        }
    }

    /** 索取推荐人奖励
     * @notice Claim referrer reward
     * @param referrer: referrer address
     */
    function claimReferrerReward(address referrer) external notContract nonReentrant {
        require(referrer != address(0), "Invalid referrer address");

        // get user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[referrer];

        // get claimable amount
        uint256 claimableAmount = userGlobalInfo.totalReferrerReward - userGlobalInfo.referrerRewardClaimed;

        require(claimableAmount > 0, "No claimable amount");

        // update state
        userGlobalInfo.referrerRewardClaimed += claimableAmount;

        // do transfer
        {
            (bool success, ) = referrer.call{value: claimableAmount}("");
            require(success, "Transfer failed.");
        }

        // emit event
        emit ReferrerRewardClaimed(referrer, claimableAmount);
    }

    function getLinkedPositionInfo(
        uint256 ledgerType,
        uint256 epoch,
        uint256 cursor,//数组下标
        uint256 size//返回的数组长度
    ) external view returns (LinkedPosition[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = roundInfos[ledgerType][epoch].totalPositionCount;
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }
        LinkedPosition[] memory linkedPositions = new LinkedPosition[](length);
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];
        for (uint256 i = 0; i < length; ++i) {
            linkedPositions[i] = roundInfo.linkedPositions[cursor + i];
        }
        return (linkedPositions, cursor + length);
    }

    //获取用户轮数
    function getUserRounds(
        uint256 ledgerType,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (UserRoundInfo[] memory, uint256) {
        uint256 length = size;
        uint256 roundCount = userRoundsInfos[ledgerType][user].length;
        if (cursor + length > roundCount) {
            length = roundCount - cursor;
        }

        UserRoundInfo[] memory userRoundInfos = new UserRoundInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            userRoundInfos[i] = userRoundsInfos[ledgerType][user][cursor + i];
        }

        return (userRoundInfos, cursor + length);
    }

    function getUserRoundsLength(uint256 ledgerType, address user) external view returns (uint256) {
        return userRoundsInfos[ledgerType][user].length;
    }

    function getUserRoundLedgers(
        uint256 ledgerType,
        uint256 epoch,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (PositionInfo[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = roundLedgers[ledgerType][epoch][user].length;
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }

        PositionInfo[] memory positionInfos = new PositionInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            positionInfos[i] = roundLedgers[ledgerType][epoch][user][cursor + i];
        }

        return (positionInfos, cursor + length);
    }

    //获取用户分类账长度
    function getUserRoundLedgersLength(
        uint256 ledgerType,
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundLedgers[ledgerType][epoch][user].length;
    }

    function getChildren(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256) {
        uint256 length = size;
        uint256 childrenCount = children[user].length;
        if (cursor + length > childrenCount) {
            length = childrenCount - cursor;
        }

        address[] memory _children = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            _children[i] = children[user][cursor + i];
        }

        return (_children, cursor + length);
    }

    function getLedgerRoundToUserRoundIndex(
        uint256 ledgerType,
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundInfos[ledgerType][epoch].ledgerRoundToUserRoundIndex[user];
    }

    function getChildrenLength(address user) external view returns (uint256) {
        return children[user].length;
    }

    function getUserDepartSalesAndLevel(address user) external view returns (uint256, uint8) {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        return (userGlobalInfo.sales - userGlobalInfo.maxChildrenSales, userGlobalInfo.salesLevel);
    }

    /** 安全关闭位置
     * @notice close a given position
     * @param ledgerType: ledger type
     * @param epoch: epoch of the ledger
     * @param positionIndex: position index of the user
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeClosePosition(
        uint256 ledgerType,
        uint256 epoch,
        uint256 positionIndex,
        PositionInfo storage positionInfo,
        RoundInfo storage roundInfo,
        UserGlobalInfo storage userGlobalInfo
    ) internal {
        require(positionInfo.withdrawnAmount == 0, "Position already claimed");
        require(positionInfo.expiryTime <= block.timestamp || roundInfo.stopLoss, "Position not expired");

        // get user round info from storage 从存储中获取用户轮次信息
        uint256 targetRoundInfoIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[ledgerType][msg.sender][targetRoundInfoIndex];

        // calculate the amount to withdraw 计算要提取的金额
        uint256 payoutAmount;
        uint256 principalAmount = (positionInfo.amount * PRINCIPAL_RATIO) / PRICE_PRECISION;

        // get back the principal amount 收回本金
        payoutAmount += principalAmount;

        // update roundInfo
        roundInfo.currentPositionCount -= 1;
        roundInfo.currentPrincipalAmount -= principalAmount;

        if (!roundInfo.stopLoss) {
            // calculate expected invest return amount 计算预期投资回报金额
            // how many days passed 多少天过去了
            uint256 daysPassed;
            if (ledgerType == 0) {
                // 1 day
                daysPassed = (block.timestamp - positionInfo.openTime);
            } else {
                daysPassed = (positionInfo.expiryTime - positionInfo.openTime);
            }
            uint256 expectedInvestReturnAmount = (positionInfo.amount * positionInfo.investReturnRate * daysPassed) /
            PRICE_PRECISION /
            TIME_UNIT;

            // calculate the amount should be paid back from invest pool 计算应从投资池中偿还的金额
            // 35% to total amount + expected return amount 占总金额的35%+预期回报金额
            uint256 investReturnAmount = positionInfo.amount - principalAmount + expectedInvestReturnAmount;

            // compare if current invest pool has enough amount 比较当前投资池是否有足够的金额
            if (epochCurrentInvestAmount[epoch] < investReturnAmount) {
                // not enough, then just pay back the current invest pool amount 不够，那么只需偿还当前的投资池金额
                investReturnAmount = epochCurrentInvestAmount[epoch];
                epochCurrentInvestAmount[epoch] = 0;
            } else {
                // update round info
            unchecked {
                epochCurrentInvestAmount[epoch] -= investReturnAmount;
            }
            }

            // check round is stop loss 检查回合为止损
            if (epochCurrentInvestAmount[epoch] == 0) {
                roundInfo.stopLoss = true;
                currentEpochs[ledgerType] += 1;
                _refillStock(ledgerType);
                emit NewRound(currentEpochs[ledgerType], ledgerType);
            }

            // update payout amount 更新支出金额
            payoutAmount += investReturnAmount;

            // update positionInfo 更新位置信息
            positionInfo.investReturnAmount = investReturnAmount;
        }

        uint256 incentiveAmount = 0;
        // calculate incentive amount if eligible
        /*if (roundInfo.stopLoss && positionInfo.incentiveClaimable) {
            incentiveAmount = _safeProcessIncentiveAmount(positionInfo, roundInfo);

            // update payout amount
            payoutAmount += incentiveAmount;

            // update incentive info to storage
            userRoundInfo.totalIncentiveClaimedAmount += incentiveAmount;

            emit IncentiveClaimed(msg.sender, incentiveAmount);
        }*/

        // update user round info
        userRoundInfo.totalWithdrawnAmount += payoutAmount;
        userRoundInfo.currentPrincipalAmount -= principalAmount;

        // update positionInfo
        positionInfo.withdrawnAmount = payoutAmount;

        // accumulate user's boost credit
        if (payoutAmount - incentiveAmount < positionInfo.amount) {
            userGlobalInfo.boostCredit += positionInfo.amount;
        }

        // do transfer 转账
        {
            (bool success, ) = msg.sender.call{value: payoutAmount}("");
            require(success, "Transfer failed.");
        }

        // emit event
        emit PositionClosed(msg.sender, ledgerType, epoch, positionIndex, payoutAmount);
    }

    /** 安全流程激励金额
     * @notice process positionInfo and return incentive amount
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeProcessIncentiveAmount(PositionInfo storage positionInfo, RoundInfo storage roundInfo)
    internal
    returns (uint256)
    {
        // calculate incentive amount
        uint256 incentiveAmount = (positionInfo.amount * roundInfo.totalPositionAmount * INCENTIVE_RATIO) / roundInfo.incentiveSnapshot / PRICE_PRECISION;

        // with PRICE_PRECISION is due to the precision of division may result in a few wei left over
        if (roundInfo.currentIncentiveAmount < incentiveAmount + PRICE_PRECISION) {
            // clean up incentive amount
            incentiveAmount = roundInfo.currentIncentiveAmount;
            roundInfo.currentIncentiveAmount = 0;
        } else {
            roundInfo.currentIncentiveAmount -= incentiveAmount;
        }

        // this position is no longer eligible for incentive
        positionInfo.incentiveClaimable = false;

        // update positionInfo
        positionInfo.incentiveAmount = incentiveAmount;

        return incentiveAmount;
    }

    /**
     * @notice process user's level info and return the current level
     * @param currentLevel: user current level
     * @param user: user address
     * @param currentSales: user current sales
     * @param userGlobalInfo: storage of the user global info
     */
    function _safeProcessSalesLevel(
        uint8 currentLevel,
        address user,
        uint256 currentSales,
        UserGlobalInfo storage userGlobalInfo
    ) internal returns (uint8) {
        uint8 newLevel = _getSalesToLevel(currentSales);
        if (newLevel > currentLevel) {
            userGlobalInfo.salesLevel = newLevel;
            emit SalesLevelUpdated(user, newLevel);
        } else {
            newLevel = currentLevel;
        }
        return newLevel;
    }

    /**
     * @notice report user's sales and update its referrer sales level
     * @param user: user address
     */
    function _safeReportSales(address user) internal {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        address referrer = userGlobalInfo.referrer;
        uint256 userSales = userGlobalInfo.sales;
        uint256 userReportedSales = userGlobalInfo.reportedSales;

        // get user's un-reported sales
        uint256 unreportedSales = userSales - userReportedSales;

        if (unreportedSales > 0) {
            // get referrer global info from storage
            UserGlobalInfo storage referrerGlobalInfo = userGlobalInfos[referrer];
            // fill up the sales to the referrer
            referrerGlobalInfo.sales += unreportedSales;
            // update user's reported sales
            userGlobalInfo.reportedSales = userSales;

            // all reported sales + user's own contributed position will be current user's final sales
            userSales += userGlobalInfo.totalPositionAmount;
            // current referrer's max children sales
            uint256 maxChildrenSales = referrerGlobalInfo.maxChildrenSales;
            // update max children sales if needed
            if (userSales > maxChildrenSales) {
                // referrer's max children sales is updated
                referrerGlobalInfo.maxChildrenSales = userSales;
                // update cache of max children sales
                maxChildrenSales = userSales;
            }
            // process referrer's sales level
            _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                referrer,
                referrerGlobalInfo.sales - maxChildrenSales, // sales for level calculation is sales - max children sales
                referrerGlobalInfo
            );
        }
    }

    /** 分发推荐奖励
     * @notice distribute referrer reward
     * @param user: user address
     * @param referrerAmount: total amount of referrer reward
     */
    function _distributeReferrerReward(uint256 amountValue, address user, uint256 referrerAmount) internal virtual {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        UserGlobalInfo storage referrerGlobalInfo;
        uint256 positionAmount = amountValue;

        // init all local variables as a search struct
        ReferrerSearch memory search;
        search.baseSalesLevel = 0;
        search.currentReferrer = userGlobalInfo.referrer;
        search.levelDiffAmount = referrerAmount; //级别差异金额100%
        search.leftLevelDiffAmount = search.levelDiffAmount;
        search.levelDiffAmountPerLevel = search.levelDiffAmount / 10; //每个级别的级别差异金额
        search.levelSearchAmount = referrerAmount - search.levelDiffAmount; //层级奖励
        search.leftLevelSearchAmount = search.levelSearchAmount;
        search.levelSearchAmountPerReferrer = search.levelSearchAmount / 10;
        search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount + positionAmount;
        userGlobalInfo.totalPositionAmount = search.currentUserTotalPosAmount;
        search.currentUser = user;

        while (search.depth < MAX_SEARCH_DEPTH) {
            // stop if current referrer is the root 如果当前引用者是根，则停止
            if (search.currentReferrer == address(0)) {
                break;
            }

            // this position does not counted as reported sales for first user himself 该职位不计入第一个用户本人的报告销售额
            if (search.depth > 0) userGlobalInfo.reportedSales += positionAmount;

            // cache current user information
            search.currentUserSales = userGlobalInfo.sales;
            search.currentUserReportedSales = userGlobalInfo.reportedSales;

            // cache current referrer information
            referrerGlobalInfo = userGlobalInfos[search.currentReferrer];

            // update referrer sales
            {
                search.currentReferrerSales = referrerGlobalInfo.sales;
                // add current sales to current referrer
                search.currentReferrerSales += positionAmount;
                // check unreported sales
                if (search.currentUserReportedSales < search.currentUserSales) {
                    // update referrerSales to include unreported sales
                    search.currentReferrerSales += search.currentUserSales - search.currentUserReportedSales;
                    // update current node storage for reported sales
                    userGlobalInfo.reportedSales = search.currentUserSales;
                }
                // update sales for current referrer
                referrerGlobalInfo.sales = search.currentReferrerSales;
            }

            // update referrer max children sales
            {
                // add current user's total position amount to current user's sales
                search.currentUserSales += search.currentUserTotalPosAmount;
                // check referrer's max child sales
                search.currentReferrerMaxChildSales = referrerGlobalInfo.maxChildrenSales;
                if (search.currentReferrerMaxChildSales < search.currentUserSales) {
                    // update max child sales
                    referrerGlobalInfo.maxChildrenSales = search.currentUserSales;
                    search.currentReferrerMaxChildSales = search.currentUserSales;
                }
            }

            // process referrer's sales level
            // @notice: current referrer sales level should ignore its max child sales
            search.currentReferrerLevel = _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                search.currentReferrer,
                search.currentReferrerSales - search.currentReferrerMaxChildSales,
                referrerGlobalInfo
            );

            // start level diff calculation
            if (!search.levelDiffDone) {
                // compare the current referrer's level with the base sales level
                if (search.currentReferrerLevel > search.baseSalesLevel) {
                    // level diff
                    search.currentLevelDiff = search.currentReferrerLevel - search.baseSalesLevel;

                    // update base level
                    search.baseSalesLevel = search.currentReferrerLevel;

                    // calculate the referrer amount
                    search.currentReferrerAmount = search.currentLevelDiff * search.levelDiffAmountPerLevel;

                    // check left referrer amount
                    if (search.currentReferrerAmount + PRICE_PRECISION > search.leftLevelDiffAmount) {
                        search.currentReferrerAmount = search.leftLevelDiffAmount;
                    }

                    // update referrer's referrer amount
                    referrerGlobalInfo.totalReferrerReward += search.currentReferrerAmount;
                    emit ReferrerRewardAdded(search.currentReferrer, search.currentReferrerAmount, 0);

                unchecked {
                    search.leftLevelDiffAmount -= search.currentReferrerAmount;
                }

                    if (search.leftLevelDiffAmount == 0) {
                        search.levelDiffDone = true;
                    }
                }
            }
            /*if (!search.levelSearchDone) {
                // level search use referrer's real level 水平搜索使用参考者的真实水平
                search.levelSearchStep = _getLevelToLevelSearchStep(
                    _getSalesToLevel(search.currentReferrerSales - search.currentReferrerMaxChildSales)
                );

                if (search.numLevelSearchCandidate + 1 <= search.levelSearchStep) {
                    search.numLevelSearchCandidate += 1;

                    // check left referrer amount 检查左侧引用人金额
                    if (search.levelSearchAmountPerReferrer + PRICE_PRECISION > search.leftLevelSearchAmount) {
                        search.levelSearchAmountPerReferrer = search.leftLevelSearchAmount;
                    }

                    // update referrer's referrer amount 更新推荐人的推荐人金额
                    referrerGlobalInfo.totalReferrerReward += search.levelSearchAmountPerReferrer;
                    emit ReferrerRewardAdded(search.currentReferrer, search.levelSearchAmountPerReferrer, 1);

                unchecked {
                    search.leftLevelSearchAmount -= search.levelSearchAmountPerReferrer;
                }

                    if (search.leftLevelSearchAmount == 0) {
                        search.levelSearchDone = true;
                    }
                }
            }*/

            search.currentUser = search.currentReferrer;
            search.currentReferrer = referrerGlobalInfo.referrer;

            userGlobalInfo = referrerGlobalInfo;
            search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount;

        unchecked {
            search.depth += 1;
        }
        }

        // check residual referrer amount
        if (search.leftLevelDiffAmount > 0) {
            userGlobalInfos[user].totalReferrerReward += search.leftLevelDiffAmount;
            emit ReferrerRewardAdded(user, search.leftLevelDiffAmount, 0);
        }
        if (search.leftLevelSearchAmount > 0) {
            userGlobalInfos[user].totalReferrerReward += search.leftLevelSearchAmount;
            emit ReferrerRewardAdded(user, search.leftLevelSearchAmount, 1);
        }
    }

    /** 获取销售目标级别
     * @notice get sales level from sales amount
     * @param amount: sales amount
     */
    function _getSalesToLevel(uint256 amount) internal pure virtual returns (uint8) {
        /* istanbul ignore else  */
        if (amount < 5000 ether) {
            return 0;
        } else if (amount < 30000 ether) {
            return 1;
        } else if (amount < 100000 ether) {
            return 2;
        } else if (amount < 300000 ether) {
            return 3;
        } else if (amount < 800000 ether) {
            return 4;
        } else if (amount < 2000000 ether) {
            return 5;
        } else if (amount < 5000000 ether) {
            return 6;
        } else if (amount < 15000000 ether) {
            return 7;
        } else if (amount < 30000000 ether) {
            return 8;
        } else if (amount < 80000000 ether) {
            return 9;
        }
        return 10;
    }

    /** 返回级别对应的层数
     * @notice level search step from level
     * @param level: sales level (0-10)
     */
    function _getLevelToLevelSearchStep(uint8 level) internal pure returns (uint8) {
    unchecked {
        if (level < 5) return level * 2;
    }
        return 10;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Bucket {
    struct BucketStock {
        uint8[] typeDays;
        uint16[] stockPrefixSum;
        uint16 currentBucketStock;//当前库存
        mapping(uint16 => uint16) ledgerStockIndex;
        uint256 stockSize;//库存大小
    }

    mapping(uint256 => BucketStock) public ledgerBucketStock;

    /**
     * @dev set an array of stock for the blind box
     */
    function _setStock(
        uint256 ledgerType,
        uint8[] memory typeDays,
        uint16[] memory stock
    ) internal {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        uint16 itemCount = 0;
        uint16[] storage stockPrefixSum = bucketStock.stockPrefixSum;
        uint8[] storage typeDaysStorage = bucketStock.typeDays;
        uint256 stockLength = stock.length;
        for (uint16 i = 0; i < stockLength; ++i) {
            itemCount += stock[i];
            stockPrefixSum.push(itemCount);//库存前缀总和
            typeDaysStorage.push(typeDays[i]);//类型天数存储
        }
        bucketStock.currentBucketStock = itemCount;
        bucketStock.stockSize = itemCount;
        require(stockPrefixSum.length <= 2e16, "stock length too long");
    }

    /** 补充库存
     * @dev refill the stock of the bucket
     * @param ledgerType the type of the ledger
     */
    function _refillStock(uint256 ledgerType) internal {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        bucketStock.currentBucketStock = uint16(bucketStock.stockSize);
    }

    /**选择位置
     * @dev Buy only one box
     */
    function _pickDay(uint256 ledgerType, uint256 seed) internal returns (uint16) {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        uint16 randIndex = _getRandomIndex(seed, bucketStock.currentBucketStock);
        uint16 location = _pickLocation(randIndex, bucketStock);
        uint16 category = binarySearch(bucketStock.stockPrefixSum, location);
        return bucketStock.typeDays[category];
    }

    //选择位置
    function _pickLocation(uint16 index, BucketStock storage bucketStock) internal returns (uint16) {
        uint16 location = bucketStock.ledgerStockIndex[index];
        if (location == 0) {
            location = index + 1;
        }
        uint16 lastIndexLocation = bucketStock.ledgerStockIndex[bucketStock.currentBucketStock - 1];

        if (lastIndexLocation == 0) {
            lastIndexLocation = bucketStock.currentBucketStock;
        }
        bucketStock.ledgerStockIndex[index] = lastIndexLocation;
        bucketStock.currentBucketStock--;
        bucketStock.ledgerStockIndex[bucketStock.currentBucketStock] = location;

        // refill the bucket
        if (bucketStock.currentBucketStock == 0) {
            bucketStock.currentBucketStock = uint16(bucketStock.stockSize);
        }
        return location - 1;
    }

    function _getRandomIndex(uint256 seed, uint16 size) internal view returns (uint16) {
        // NOTICE: We do not to prevent miner from front-running the transaction and the contract.
        return
        uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1),
                        seed,
                        size
                    )
                )
            ) % size
        );
    }

    function getBucketInfo(uint256 ledgerType) external view returns (uint8[] memory, uint16[] memory) {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        return (bucketStock.typeDays, bucketStock.stockPrefixSum);
    }

    function binarySearch(uint16[] storage array, uint16 target) internal view returns (uint16) {
        uint256 left = 0;
        uint256 right = array.length - 1;
        uint256 mid;
        while (left < right - 1) {
            mid = left + (right - left) / 2;
            if (array[mid] > target) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        if (target < array[left]) {
            return uint16(left);
        } else {
            return uint16(right);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}