// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FootballBets is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint8;

    ERC20 public tokenAddress;
    uint256 public maxBetAmount = 10000000 ether;
    uint256 public standardPrice  = 10 ether;
    uint16 public oddsRate = 10000;
    uint256 public totalFundAmount = 0;
    uint16 public fee = 20; // rate 1000  - 2%
    address public feeAddress;

    struct MatchInfo {
        uint256 matchId;
        string title;
        string teamA;
        string teamB;
        uint256 startBettingTime;
        uint256 endBettingTime;
        uint256 timeMatchStart;
        uint8 homeTeamGoals;
        uint8 awayTeamGoals;
        uint8 status; // 0-NEW 1-FINISH 9-CANCEL/POSTPONE
    }

    struct BetType { // id 0,1,2  1x2, handicap, over-under
        string description;
        uint8 numDoors;
        uint32[] odds;
        uint8[] doorResults; // 0-PENDING 1-WIN 2-LOSE 3-WIN-HALF 4-LOSE-HALF 5-DRAW
        int32 goalRate;
        uint8 status; // 0-NEW 1-FINISH 9-CANCEL/POSTPONE
    }

    struct Ticket {
        uint256 index;
        address player;
        uint256 matchId;
        uint8 betTypeId;
        uint8 betDoor;
        uint32 betOdd;
        uint256 betAmount;
        uint256 payout;
        uint256 bettingTime;
        uint256 claimedTime;
        uint8 status; // 0-PENDING 1-WIN 2-LOSE 3-WIN-HALF 4-LOSE-HALF 9-REFUND , 10 CANCEL
    }

    struct PlayerStat {
        uint256 totalBet;
        uint256 payout;
    }

    mapping(uint256 => MatchInfo) public matchInfos; // All matches
    mapping(uint256 => BetType[]) public matchBetTypes; // Store all match bet types: matchId => array of BetType
    Ticket[] public tickets; // All tickets of player

    mapping(address => uint256[]) public ticketsOf; // Store all ticket of player: player => ticket_id

    mapping(address => PlayerStat) public playerStats;
    mapping(address => bool) public blackLists;

    mapping(address=>bool) public admin;
    uint256 public totalBetAmount;

    // event log
    event AddMatchInfo(uint256 matchId, string title, string teamA, string teamB, uint256 startBettingTime, uint256 endBettingTime, uint256 timeMatchStart);
    event AddBetType(uint256 matchId, uint8 betTypeId, string betDescription, uint8 numDoors, uint32[] odds, int32 goalRate);
    event EditBetTypeOdds(uint256 matchId, uint8 betTypeId, uint32[] odds);
    event EditBetOddsByMatch(uint256 matchId,uint32[] odds1x2, uint32[] oddsHandicap, uint32[] oddsOverUnder, int32 goalRateHandicap, int32 goalRateOverUnder, uint256 timestamp);
    event CancelMatch(uint256 matchId);
    event SettleMatchResult(uint256 matchId, uint8 betTypeId, uint8 _homeTeamGoals, uint8 _awayTeamGoals, uint256 timestamp);
    event NewTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 betAmount,uint256 betDoor, uint256 betOdd, uint256 bettingTime);
    event DrawTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 payout, uint256 fee, uint256 claimedTime);
    event DrawAllTicket(address player, uint256 payout, uint256 fee, uint256 claimedTime);
    event SetLimitBetAmount(string name, uint256 amount, uint256 timestamp);
    event WithdrawFund(uint256 amount, uint256 timestamp);
    event CancelTicket(uint256 ticketId, uint256 matchId, uint256 timestamp);

    constructor(ERC20 _token, address _feeAddress) {
        admin[msg.sender] = true;
        tokenAddress = _token;
        feeAddress = _feeAddress;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "!admin");
        _;
    }

    modifier checkBlackList(){
        require(blackLists[msg.sender] != true, "player in black list");
        _;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin[_admin] = true;
    }

    function setFee(uint16 _fee) external onlyOwner {
        require(_fee >= 0, "fee must greater 0");
        fee = _fee;
    }

    function addNewMatch(uint256 _matchId, string memory _title, string memory _teamA, string memory _teamB, uint256 _startBettingTime,
        uint256 _endBettingTime, uint256 _timeMatchStart, uint32[] memory _odds1x2, uint32[] memory _oddsHandicap, uint32[] memory _oddsOverUnder, int32 _goalRateHandicap, int32 _goalRateOverUnder) external onlyAdmin {
        // _goalRateHandicap x oddsRate, _goalRateOverUnder x oddsRate
        require(_odds1x2.length == 3, "Invalid _odds1x2 length");
        require(_oddsHandicap.length == 2, "Invalid _oddsHandicap length");
        require(_oddsOverUnder.length == 2, "Invalid _oddsOverUnder length");

        require(_odds1x2[0] >= 0 && _odds1x2[1] >=0 && _odds1x2[2] >=0, "_odds1x2 must be greater than 0");
        require(_oddsHandicap[0] >=0 && _oddsHandicap[1] >=0, "_oddsHandicap must be greater than 0");
        require(_oddsOverUnder[0] >=0 && _oddsOverUnder[1] >=0, "_oddsOverUnder must be greater than 0");

        require(_goalRateOverUnder >= 0, "_goalRateOverUnder must be greater than 0");

        require(bytes(_title).length > 0, "_title required");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(bytes(matchInfo.title).length == 0, "_matchId already exist");

        // add matchinfo
        matchInfos[_matchId] = MatchInfo({
            matchId: _matchId,
            title: _title,
            teamA: _teamA,
            teamB: _teamB,
            startBettingTime: _startBettingTime,
            endBettingTime: _endBettingTime,
            timeMatchStart: _timeMatchStart,
            homeTeamGoals: 0,
            awayTeamGoals: 0,
            status: 0
        });

        // add bet 1x2
        matchBetTypes[_matchId].push(
            BetType({
                description: "Bet 1x2",
                numDoors: 3,
                odds: _odds1x2,
                doorResults: new uint8[](3),
                goalRate: 0,
                status : 0
            })
        );

        // add bet handicap
        matchBetTypes[_matchId].push(
            BetType({
                    description: "Bet Handicap",
                    numDoors: 2,
                    odds: _oddsHandicap,
                    doorResults: new uint8[](2),
                    goalRate: _goalRateHandicap, // home/away = 1 1/2:0 <=> 15000, 0:1 <=> -10000
                    status : 0
            })
        );

        // add bet up/down
        matchBetTypes[_matchId].push(
            BetType({
                description: "Bet Over/Under",
                numDoors: 2,
                odds: _oddsOverUnder,
                doorResults: new uint8[](2),
                goalRate: _goalRateOverUnder, // 2 goal <=> 20000
                status : 0
            })
        );
        emit AddMatchInfo(_matchId, _title, _teamA, _teamB, _startBettingTime, _endBettingTime, _timeMatchStart);
        emit AddBetType(_matchId, 0, "Bet 1x2", 3, _odds1x2, 0);
        emit AddBetType(_matchId, 1, "Bet Handicap", 2, _oddsHandicap, _goalRateHandicap);
        emit AddBetType(_matchId, 2, "Bet Over/Under", 2, _oddsOverUnder, _goalRateOverUnder);
    }

    function editMatchBetTypeOdds(uint256 _matchId, uint8 _betTypeId, uint32[] memory _odds, int32 goalRate) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp <= matchInfo.endBettingTime, "Late");

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(betType.odds.length == _odds.length, "Invalid _odds");

        uint256 _numDoors = _odds.length;
        for (uint256 i = 0; i < _numDoors; i++) {
            require(_odds[i] > oddsRate, "Odd must be greater than x1");
        }
        betType.odds = _odds;
        if(_betTypeId != 0) betType.goalRate = goalRate; // not type 1x2
        emit EditBetTypeOdds(_matchId, _betTypeId, _odds);
    }

    // edit 3 type bet
    function editMatchBetByMatch(uint256 _matchId, uint32[] memory _odds1x2, uint32[] memory _oddsHandicap, uint32[] memory _oddsOverUnder, int32 _goalRateHandicap, int32 _goalRateOverUnder) external onlyAdmin {
        require(_odds1x2.length == 3, "Invalid _odds1x2 length");
        require(_oddsHandicap.length == 2, "Invalid _oddsHandicap length");
        require(_oddsOverUnder.length == 2, "Invalid _oddsOverUnder length");

        require(_odds1x2[0] >= 0 && _odds1x2[1] >=0 && _odds1x2[2] >=0, "_odds1x2 must be greater than 0");
        require(_oddsHandicap[0] >=0 && _oddsHandicap[1] >=0, "_oddsHandicap must be greater than 0");
        require(_oddsOverUnder[0] >=0 && _oddsOverUnder[1] >=0, "_oddsOverUnder must be greater than 0");

        require(_goalRateOverUnder >= 0, "_goalRateOverUnder must be greater than 0");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp <= matchInfo.endBettingTime, "Too late");

        BetType storage betType1x2 = matchBetTypes[_matchId][0];
        BetType storage betTypeHandicap = matchBetTypes[_matchId][1];
        BetType storage betTypeOverUder = matchBetTypes[_matchId][2];

        betType1x2.odds = _odds1x2;

        betTypeHandicap.odds = _oddsHandicap;
        betTypeHandicap.goalRate = _goalRateHandicap;

        betTypeOverUder.odds = _oddsOverUnder;
        betTypeOverUder.goalRate = _goalRateOverUnder;

        emit EditBetOddsByMatch(_matchId, _odds1x2, _oddsHandicap, _oddsOverUnder, _goalRateHandicap, _goalRateOverUnder, block.timestamp);
    }

    function setStartBettingTime(uint256 _matchId, uint256 _startBettingTime) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.startBettingTime = _startBettingTime;
    }

    function setEndBettingTime(uint256 _matchId, uint256 _endBettingTime) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.endBettingTime = _endBettingTime;
    }

    function setTimeMatchStart(uint256 _matchId, uint256 _timeMatchStart) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.timeMatchStart = _timeMatchStart;
    }

    function setAndRemoveBlackList(address _player, bool _value) external onlyAdmin {
        blackLists[_player] = !!_value;
    }

    function setMaxBetAmount(uint256 _amount) external onlyAdmin {
        require(_amount > 0, "Amount must > 0");
        maxBetAmount = _amount;
        emit SetLimitBetAmount("Set max bet", _amount, block.timestamp);
    }

    function setMinBetAmount(uint256 _amount) external onlyAdmin {
        require(_amount > 0, "Amount must > 0");
        standardPrice = _amount;
        emit SetLimitBetAmount("Set min bet", _amount, block.timestamp);
    }

    function depositFund(uint256 _amount) external {
        require(_amount > 0, "Amount must > 0");
        SafeERC20.safeTransferFrom(tokenAddress, msg.sender, address(this), _amount);
        totalFundAmount += _amount;
    }

    function withdrawFund(uint256 _amount) external onlyOwner{
        require(_amount > 0, "Amount must > 0");
        SafeERC20.safeTransfer(tokenAddress, msg.sender, _amount);
        emit WithdrawFund(_amount, block.timestamp);
    }

    function cancelMatch(uint256 _matchId) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 9-CANCEL/POSTPONE
        matchInfo.status = 9;
        emit CancelMatch(_matchId);
    }

    function settleMatchResult(uint256 _matchId, uint8 _homeTeamGoals, uint8 _awayTeamGoals) external onlyAdmin {
        // 0-PENDING 1-WIN 2-LOSE 3-WIN-HALF 4-LOSE-HALF 5-DRAW 9-REFUND
        require(_homeTeamGoals >= 0, "Invalid _homeTeamGoals");
        require(_awayTeamGoals >= 0, "Invalid _awayTeamGoals");

        MatchInfo storage matchInfo = matchInfos[_matchId];

        require(block.timestamp > matchInfo.endBettingTime, "settleMatchResult too early");

        matchInfo.status = 1;
        matchInfo.homeTeamGoals = _homeTeamGoals;
        matchInfo.awayTeamGoals = _awayTeamGoals;

        // bet 1x2
        BetType storage betType = matchBetTypes[_matchId][0];
        if(_homeTeamGoals > _awayTeamGoals) betType.doorResults = [1,2,2]; // win, lost, lost
        if(_homeTeamGoals == _awayTeamGoals) betType.doorResults = [2,1,2]; // lost, win, lost
        if(_homeTeamGoals < _awayTeamGoals) betType.doorResults = [2,2,1]; // lost, lost, win
        betType.status = 1;

        // bet handicap
        betType = matchBetTypes[_matchId][1];
        int64 delta = int64(_homeTeamGoals * uint64(oddsRate)) + int64(betType.goalRate) - int64(_awayTeamGoals * uint64(oddsRate));
        if(delta == 0) betType.doorResults = [5,5]; // draw
        else if(delta > 0 && delta < 5000) betType.doorResults = [3,4]; // win half / lost half
        else if(delta >= 5000) betType.doorResults = [1,2]; // win/lost
        else if(delta < 0 && delta > -5000) betType.doorResults = [4,3]; // lost half / win half
        else if(delta <= -5000) betType.doorResults = [2, 1]; // lost / win
        betType.status = 1;

        // bet over/under
        betType = matchBetTypes[_matchId][2];
        uint32 totalGoal = (_homeTeamGoals + _awayTeamGoals) * oddsRate;
        if(uint32(betType.goalRate) == totalGoal) betType.doorResults = [5,5]; // draw
        else if(uint32(betType.goalRate) > totalGoal) betType.doorResults = [2,1]; // under win
        else if(uint32(betType.goalRate) < totalGoal) betType.doorResults = [1,2]; // over win
        betType.status = 1;

        emit SettleMatchResult(_matchId, 0, _homeTeamGoals, _awayTeamGoals, block.timestamp);
        emit SettleMatchResult(_matchId, 1, _homeTeamGoals, _awayTeamGoals, block.timestamp);
        emit SettleMatchResult(_matchId, 2, _homeTeamGoals, _awayTeamGoals, block.timestamp);
    }

    // user function bet
    function buyTicket(uint256 _matchId, uint8 _betTypeId, uint8 _betDoor, uint32 _betOdd, uint256 _betAmount) public checkBlackList  returns (uint256 _ticketIndex) {
        require(_betAmount >= standardPrice, "_betAmount less than standard price");

        uint256 _maxBetAmount = maxBetAmount;
        require(_betAmount <= _maxBetAmount, "_betAmount exceeds _maxBetAmount");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp >= matchInfo.startBettingTime, "early");
        require(block.timestamp <= matchInfo.endBettingTime, "late");
        require(matchInfo.status == 0, "Match not opened for ticket"); // 0-NEW 1-FINISH 9-CANCEL/POSTPONE

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(_betDoor < betType.numDoors, "Invalid _betDoor");
        require(_betOdd > 0, "_betOdd must be greater than 0"); // <=> betType.odds[_betDoor] > 0
        require(_betOdd == betType.odds[_betDoor], "Invalid _betOdd");

        address _player = msg.sender;
        SafeERC20.safeTransferFrom(tokenAddress, _player, address(this), _betAmount);

        _ticketIndex = tickets.length;

        tickets.push(
            Ticket({
                index : _ticketIndex,
                player : _player,
                matchId : _matchId,
                betTypeId : _betTypeId,
                betDoor : _betDoor,
                betOdd : _betOdd,
                betAmount : _betAmount,
                bettingTime : block.timestamp,
                payout: 0,
                claimedTime : 0,
                status : 0 // 0-PENDING 1-WIN 2-LOSE 3-REFUND
            })
        );

        totalBetAmount = totalBetAmount.add(_betAmount);
        playerStats[_player].totalBet = playerStats[_player].totalBet.add(_betAmount);
        ticketsOf[_player].push(_ticketIndex);

        emit NewTicket(_player, _ticketIndex, _matchId, _betTypeId, _betAmount, _betDoor, _betOdd, block.timestamp);
    }

    // cancel buyticket
    function cancelBuyTicket(uint256 _ticketId) external checkBlackList {

        require(_ticketId < tickets.length, "_ticketIndex out of range");
        Ticket storage ticketInfo = tickets[_ticketId];
        uint256 _matchId = ticketInfo.matchId;
        MatchInfo memory matchInfo = matchInfos[_matchId];

        require(msg.sender == ticketInfo.player, "User not owner ticket");
        require(ticketInfo.status == 0, "Ticket settled");
        require(block.timestamp < matchInfo.endBettingTime, "cancel ticket late");
        SafeERC20.safeTransfer(tokenAddress, msg.sender, ticketInfo.betAmount);
        ticketInfo.status = 10; // CANCEL
        emit CancelTicket(_ticketId, ticketInfo.matchId, block.timestamp);
    }

    // get payout
    function getPayoutOfTicket(uint256 _ticketIndex) external view returns (uint256 _payout) {
        if(_ticketIndex >= tickets.length) return 0;

        Ticket storage ticket = tickets[_ticketIndex];
        if(ticket.status != 0) return 0;

        uint256 _matchId = ticket.matchId;

        MatchInfo memory matchInfo = matchInfos[_matchId];
        if(block.timestamp <= matchInfo.endBettingTime) return 0;

        uint8 _betTypeId = ticket.betTypeId;
        BetType storage betType = matchBetTypes[_matchId][_betTypeId];

        uint256 _betAmount = ticket.betAmount;

        // Ticket status: 0-PENDING 1-WIN 2-LOSE 3-REFUND
        if (matchInfo.status == 9) { // CANCEL/POSTPONE
            _payout = _betAmount;
        } else if (matchInfo.status == 1) { // FINISH
            uint8 _betDoor = ticket.betDoor;
            uint8 _betDoorResult = betType.doorResults[_betDoor];
            if (_betDoorResult == 1) {
                _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
            } else if(_betDoorResult == 2){
                _payout = 0;
            } else if (_betDoorResult == 3) {
                uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
            } else if (_betDoorResult == 4) {
                _payout = _betAmount.div(2);
            } else if (_betDoorResult == 5) {
                _payout = _betAmount;
            }
        }
        return _payout;
    }

    // user function claim
    function claimPayout(uint256 _ticketIndex) external checkBlackList returns (address _player, uint256 _payout) {
        require(_ticketIndex < tickets.length, "_ticketIndex out of range");

        Ticket storage ticket = tickets[_ticketIndex];
        require(ticket.status == 0, "Ticket settled");

        uint256 _matchId = ticket.matchId;
        MatchInfo memory matchInfo = matchInfos[_matchId];
        require(block.timestamp > matchInfo.endBettingTime, "Early");

        uint8 _betTypeId = ticket.betTypeId;
        BetType storage betType = matchBetTypes[_matchId][_betTypeId];

        uint256 _betAmount = ticket.betAmount;
        // Ticket status: 0-PENDING 1-WIN 2-LOSE 3-REFUND
        if (matchInfo.status == 9) { // CANCEL/POSTPONE
            _payout = _betAmount;
            ticket.status = 9; // REFUND
        } else if (matchInfo.status == 1) { // FINISH
            uint8 _betDoor = ticket.betDoor;
            uint8 _betDoorResult = betType.doorResults[_betDoor];
            if (_betDoorResult == 1) {
                _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                ticket.status = 1; // WIN
            } else if(_betDoorResult == 2){
                _payout = 0;
                ticket.status = 1; // LOSE
            } else if (_betDoorResult == 3) {
                uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                ticket.status = 3; // WIN-HALF
            } else if (_betDoorResult == 4) {
                _payout = _betAmount.div(2);
                ticket.status = 4; // LOSE-HALF
            } else if (_betDoorResult == 5) {
                _payout = _betAmount; // draw
                ticket.status = 5; // draw
            } else {
                revert("No bet door result");
            }
        } else {
            revert("Match is not opened for settling");
        }
        _player = ticket.player;
        ticket.claimedTime = block.timestamp;
        uint256 _fee = _payout.mul(fee).div(1000); // fee
        _payout = _payout - _fee;
        if (_payout > 0) {
            SafeERC20.safeTransfer(tokenAddress, _player, _payout);
            playerStats[_player].payout = playerStats[_player].payout.add(_payout);
            SafeERC20.safeTransfer(tokenAddress, feeAddress, _fee);
        }
        emit DrawTicket(_player, _ticketIndex, _matchId, _betTypeId, _payout, _fee, block.timestamp);
    }

    // get value user claim all
    function getTotalPayout(address _address) external view returns (uint256){
        uint256 _payout = 0;
        for(uint k=0; k<ticketsOf[_address].length; k++){
            Ticket storage ticket = tickets[ticketsOf[_address][k]];

            uint256 _matchId = ticket.matchId;
            MatchInfo memory matchInfo = matchInfos[_matchId];

            uint8 _betTypeId = ticket.betTypeId;
            BetType storage betType = matchBetTypes[_matchId][_betTypeId];

            uint256 _betAmount = ticket.betAmount;
            if(ticket.status == 0 && block.timestamp > matchInfo.endBettingTime){
                if (matchInfo.status == 9) { // CANCEL/POSTPONE
                    _payout+= _betAmount;
                } else if (matchInfo.status == 1) { // FINISH
                    uint8 _betDoor = ticket.betDoor;
                    uint8 _betDoorResult = betType.doorResults[_betDoor];
                    if (_betDoorResult == 1) {
                        _payout+= _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                    } else if(_betDoorResult == 2){
                    } else if (_betDoorResult == 3) {
                        uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                        _payout+= _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                    } else if (_betDoorResult == 4) {
                        _payout+= _betAmount.div(2);
                    } else if (_betDoorResult == 5) {
                        _payout+= _betAmount; // draw
                    }
                }
            }
        }
        return _payout;
    }
    // user function claim all
    function claimAllPayout() external checkBlackList {
         uint256 _payout = 0;
         for(uint k=0; k<ticketsOf[msg.sender].length; k++){
             Ticket storage ticket = tickets[ticketsOf[msg.sender][k]];

             uint256 _matchId = ticket.matchId;
             MatchInfo memory matchInfo = matchInfos[_matchId];

             uint8 _betTypeId = ticket.betTypeId;
             BetType storage betType = matchBetTypes[_matchId][_betTypeId];

             uint256 _betAmount = ticket.betAmount;
             if(ticket.status == 0 && block.timestamp > matchInfo.endBettingTime){
                 if (matchInfo.status == 9) { // CANCEL/POSTPONE
                     _payout+= _betAmount;
                     ticket.status = 9; // REFUND
                 } else if (matchInfo.status == 1) { // FINISH
                     uint8 _betDoor = ticket.betDoor;
                     uint8 _betDoorResult = betType.doorResults[_betDoor];
                     if (_betDoorResult == 1) {
                         _payout+= _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                         ticket.status = 1; // WIN
                     } else if(_betDoorResult == 2){
                         ticket.status = 1; // LOSE
                     } else if (_betDoorResult == 3) {
                         uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                         _payout+= _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                         ticket.status = 3; // WIN-HALF
                     } else if (_betDoorResult == 4) {
                         _payout+= _betAmount.div(2);
                         ticket.status = 4; // LOSE-HALF
                     } else if (_betDoorResult == 5) {
                         _payout+= _betAmount; // draw
                         ticket.status = 5; // draw
                     }
                 }
             }
         }

        uint256 _fee = _payout.mul(fee).div(1000); // fee
        _payout = _payout - _fee;
        if (_payout > 0) {
            SafeERC20.safeTransfer(tokenAddress, msg.sender, _payout);
            playerStats[msg.sender].payout = playerStats[msg.sender].payout.add(_payout);
            SafeERC20.safeTransfer(tokenAddress, feeAddress, _fee);
        }
        emit DrawAllTicket(msg.sender, _payout, _fee, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
library SafeMath {
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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