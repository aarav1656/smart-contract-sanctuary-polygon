// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "./Ownable.sol";
import "./IERC20.sol";


contract WildGamesHuntTen is Ownable {
    IERC20 paymentToken;
    address public wildGamesVault;
    uint8 public arrayCounter;
    uint8 public amountGamesUntilExtraGame;
    mapping(address => uint256) public payments;
    mapping(uint256 => Game[]) public gameLogs;
    mapping(uint256 => Game[]) public extraGameLogs;
    mapping(address => mapping(uint256 => uint256[])) private addressToGameIndexToGames;

    struct Game {
        uint128 id;
        address[10] players;
        uint8 playersNow;
        uint8 extraGameFundCounter;
        uint256 extraGameFundBalance;
        address[] losers;
        uint256 betValue;
        uint256[10] playerNotes;
    }

    struct WinnerLog{
        address winner;
        uint256 gameId;
        uint256 betValue;
        uint256 winnerPayout;
    }

    Game[] public AllGames;
    WinnerLog[] public AllWinners;

    event UserEnteredGame(address indexed user, uint256 indexed betIndex, uint256 indexed gameIndex, address[10] participants);
    event GameFinished(uint256 indexed betIndex, uint256 indexed gameIndex, address looser, address[10] participants);

    constructor(address _paymentToken, address _vaultAddress) {
        paymentToken = IERC20(_paymentToken);
        
        wildGamesVault = _vaultAddress;
        amountGamesUntilExtraGame = 100;

        createGame(50000000000000000000); // 50
        createGame(100000000000000000000); // 100
        createGame(500000000000000000000); // 500
        createGame(1000000000000000000000); // 1000
        createGame(5000000000000000000000); // 5000
        createGame(10000000000000000000000); // 10000
        createGame(50000000000000000000000); // 50000
        createGame(100000000000000000000000); // 100000
    }

    function getTokenBalanceContract() external view returns(uint) {
        return paymentToken.balanceOf(address(this));
    }

    function createGame(uint256 _betValue) public onlyOwner {
        address[] memory emptyArr;
        address[10] memory playersArr;
        uint256[10] memory playersNotesArr;

        AllGames.push(Game(0, playersArr, 0, 0 ,0, emptyArr, _betValue, playersNotesArr));
    }

    function getPaymentTokenBalance(address _who) public view returns(uint256) {
        return paymentToken.balanceOf(_who);
    }

    function _DepositIntoContract( uint256 amount) internal  returns (bool) {
        paymentToken.transferFrom(tx.origin,address(this), amount);
        payments[tx.origin] += amount;
        return true;
    }

    function checkAllowanceFrom(address _who) public view returns(uint256) {
        return paymentToken.allowance(_who, address(this));
    }

    function withdrawContract() public onlyOwner {
        paymentToken.transfer( owner(),  paymentToken.balanceOf(address(this)));
    }

    function getLosersByGame(uint _indexGame) public view returns(address[] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.losers;
    }

    function isPlayerInGame(address _player, uint _indexGame) public view returns(bool) {
        Game memory currentGame = AllGames[_indexGame];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function enterinGame (uint _indexGame, uint256 _playerNote) public {
        Game storage currentGame = AllGames[_indexGame];
        require(!isPlayerInGame(msg.sender, _indexGame), "you're already entered");
        require(checkAllowanceFrom(msg.sender) >= currentGame.betValue, "not enough allowance");

        _DepositIntoContract(currentGame.betValue);
        pushPlayerIn(msg.sender, _indexGame, _playerNote);

        addressToGameIndexToGames[msg.sender][_indexGame].push(currentGame.id);

        currentGame.playersNow++;    

        // check occupancy of players array
        if(currentGame.playersNow == 10) {
            drawProcess(_indexGame);
            currentGame.extraGameFundCounter++;
        }

        if(currentGame.extraGameFundCounter == amountGamesUntilExtraGame) {
            extraGameDraw(_indexGame);
            currentGame.extraGameFundCounter = 0;
        }

        emit UserEnteredGame(msg.sender, _indexGame, currentGame.id, currentGame.players);
    }

    function viewPlayersByGame(uint _indexGame) public view returns(address[10] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.players;
    }

    function pushPlayerIn(address _player, uint _index, uint256 _playerNote) internal {
        Game storage currentGame = AllGames[_index];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == address(0) ) {
                currentGame.players[i] = _player;
                currentGame.playerNotes[i] = _playerNote ;
                break;
            }
        }
    }

    function cancelBet( uint _indexGame) public  returns (bool) {
        Game storage currentGame = AllGames[_indexGame];
        require(isPlayerInGame(msg.sender, _indexGame), "you're not a player");
        require(payments[msg.sender] >= currentGame.betValue, "not enough allowance for cancelBet");

        currentGame.playersNow--;    
        addressToGameIndexToGames[msg.sender][_indexGame].pop();

        for(uint i = 0; i < currentGame.players.length; i++) {
            if(msg.sender == currentGame.players[i]) {
                delete currentGame.players[i];
                delete currentGame.playerNotes[i];
            }
        }

        payments[msg.sender] -= currentGame.betValue;
        paymentToken.transfer(tx.origin, currentGame.betValue); //msg sender or tx origin?

        return true;        
    }

    function removeGame(uint _indexGame) public onlyOwner{
        delete AllGames[_indexGame];
    }
 
    function getAllGamesData() external view returns(Game[] memory) {
        return AllGames;
    }
    
    function getGameByIndex(uint _indexGame) external view returns(Game memory) {
        return AllGames[_indexGame];
    }

 ////////////////////////////////////////////
    receive() external payable {}
 ////////////////////////////////////////////

    function setAmountUntilExtra(uint8 _amount) public {
        amountGamesUntilExtraGame = _amount;
    }

    function checkBalanceWildGamesVault() public onlyOwner view returns(uint256) {
        return paymentToken.balanceOf(wildGamesVault);
    }

    function drawProcess(uint _indexGame) internal {
        Game storage currentGame = AllGames[_indexGame];
        // gameLogs[_indexGame].push(currentGame);
        uint payoutForWinner = (currentGame.betValue * 109) / 100; //81%
        uint indexLoser =  random(currentGame.players.length, _indexGame); 

        //send loser to losers list
        currentGame.losers.push(currentGame.players[indexLoser]);

        //distribute to winners
        for (uint i = 0; i < currentGame.players.length ; i++) {
            if(i != indexLoser ) {
                paymentToken.transfer( payable(currentGame.players[i]), payoutForWinner);
            }
        }

        // distribute for WildGamesFund
        paymentToken.transfer(wildGamesVault, (currentGame.betValue * 10/100)); //10%

        // distribute to extraGameFund
        currentGame.extraGameFundBalance += (currentGame.betValue * 9) / 100; //9%
        
        gameLogs[_indexGame].push(currentGame);

        emit GameFinished(_indexGame, currentGame.id++, currentGame.players[indexLoser], currentGame.players);

        delete currentGame.players;
        delete currentGame.playerNotes;
        currentGame.playersNow = 0;

        
    }

    function setWildGamesFuncReceiver(address _receiver) public onlyOwner {
        wildGamesVault = _receiver;
    }

    function getLastGameLog(uint256 _indexGame) external view returns(Game memory gameLogs_) {
        Game[] memory _gameLogs = gameLogs[_indexGame];
        return _gameLogs[_gameLogs.length - 1];
    }

    function getUserLastGame(address _user, uint256 _indexGame) external view returns (Game memory) {
        uint256[] memory games = addressToGameIndexToGames[_user][_indexGame];
        if (games.length == 0) return AllGames[_indexGame];
        return gameLogs[_indexGame][games.length - 1];
    }

    function getAllGameIdsUserParticipated(address _user, uint256 _indexGame) external view returns (uint256[] memory) {
        return addressToGameIndexToGames[_user][_indexGame];
    }

    function extraGameDraw(uint _indexGame) internal   {
        Game storage currentGame = AllGames[_indexGame];
        // extraGameLogs[_indexGame].push(currentGame);
        uint winnerIndex = random(currentGame.losers.length, _indexGame);
        paymentToken.transfer(currentGame.losers[winnerIndex], currentGame.extraGameFundBalance);
        AllWinners.push(WinnerLog(currentGame.losers[winnerIndex], currentGame.id, currentGame.betValue, currentGame.extraGameFundBalance));
        extraGameLogs[_indexGame].push(currentGame);
        delete currentGame.losers;
    }
        
    function random(uint _value, uint _indexGame) internal view returns(uint){
        Game memory currentGame = AllGames[_indexGame];
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,blockhash(block.number - 1), currentGame.playerNotes, msg.sender))) % _value; //11 + add -1 to block number
    }
}