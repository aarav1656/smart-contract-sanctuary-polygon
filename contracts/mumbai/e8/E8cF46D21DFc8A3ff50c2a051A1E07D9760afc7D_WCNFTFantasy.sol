// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '../interfaces/IRetrieveRandomNumber.sol';
import "../interfaces/IFetchTeams.sol";
import "../interfaces/IWorldCupData.sol";
import "../interfaces/IMintTeams.sol";

 interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}
//User pays 25 matic if price is above 40 cents
//If Matic is below 40 cents, the user will pay 50 matic

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WCNFTFantasy is Ownable, ReentrancyGuard {
event Winners(address winnerOne, address winnerTwo, address winnerThree);
event AllPredictors(address smartContract, address predictor);
event TopPoints(uint indexed firstHighestPoints, uint indexed secondHighestPoints, uint indexed thirdHighestPoints);
AggregatorV3Interface internal priceFeed;
address public randomAddress;
address public mintTeamAddress;
address public worldCupData16Address;
address public worldCupData8Address;
address public worldCupData4Address;
address public changeOrderAddress;
address public fetchTeamAddress;
address payable[] predictorsWithBiggestPoints;
address payable[] predictorsWithSecondBiggestPoints;
address payable[] predictorsWithThirdBiggestPoints;
uint highestAmountOfPoints;
uint secondHighestAmountOfPoints;
uint thirdHighestAmountOfPoints;
//Amount of points rewarded for each correct guess when the 4 teams are finalized
uint public oneDay;
uint public fewMinutes;
uint public TOP_16_STARTS = 1670090400;
uint public TOP_8_STARTS = 1670608800;
uint public TOP_4_STARTS = 1670954400;
bool paused;
bool canReceiveRefund;
//An object that defined the prediction of the top teams
struct TopPredictions {
     bytes teamOne;
     bytes teamTwo;
     bytes teamThree;
     bytes teamFour;
     bytes teamFive;
     bytes teamSix;
     uint predictorIndex;
}
  struct Points {
     uint points;
     address payable predictor;
  }
    uint predictorPointIndex;
    Points[1000] predictorPoints;
    //An array that stores all the world cup teams
    bytes[32] worldCupTeams;
    mapping(address => TopPredictions) predictors; //keeps track of all users predictions
    mapping(address => bool) alreadyMinted; //checks if user has minted their first 4 teams for inital minting phase
    mapping(address => bool) extraTwoTeamsMinted; //check if user has minted extra 2 teams
    mapping(address => bool) changedOrderForTop32; //check if user has changed team order for top 32
    mapping(address => bool) changedOrderForTop16; //check if user has changed team order for top 16
    mapping(address => bool) changedOrderForTop8; //check if user has changed team order for top 8
    mapping(address => bool) changedOrderForTop4; //check if user has changed team order for top 4
    mapping(address => bool) depositedPoints; //checks if user has already deposited their points to potentially get chosen as winner
    mapping(address => uint) public balances; //keeps track of the amount of money each user has deposited


   //Used to keep track of the phases of the worldcup
   enum GamePhases {
    MINT, 
    TOP32,
    TOP16,
    TOP8,
    TOP4,
    CHOOSE_WINNERS,
    WORLD_CUP_FINISHED
}

   GamePhases public currentPhase;

//Makes sure you can only interact with function after the world cup finishes
   modifier afterEvent {
     require(currentPhase == GamePhases.WORLD_CUP_FINISHED,"CAN_WITHDRAW_ONLY_AFTER_EVENT");
     _;
   }

   modifier onlyWhenNotPaused {
     require(paused == false, "CONTRACT_IS_PAUSED");
     _;
   }

     constructor() {  
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        currentPhase = GamePhases.MINT;
        //Group A
         worldCupTeams[0] = abi.encode("Qatar");
         worldCupTeams[1] = abi.encode("Ecuador");
         worldCupTeams[2] = abi.encode("Senegal");
         worldCupTeams[3] = abi.encode("Netherlands");

        //Group B
         worldCupTeams[4] = abi.encode("England");
         worldCupTeams[5] = abi.encode("IR Iran");
         worldCupTeams[6] = abi.encode("USA");
         worldCupTeams[7] = abi.encode("Wales");

         //Group C
         worldCupTeams[8] = abi.encode("Argentina");
         worldCupTeams[9] = abi.encode("Saudi Arabia");
         worldCupTeams[10] = abi.encode("Mexico");
         worldCupTeams[11] = abi.encode("Poland");

         //Group D
         worldCupTeams[12] = abi.encode("France");
         worldCupTeams[13] = abi.encode("Australia");
         worldCupTeams[14] = abi.encode("Denmark");
         worldCupTeams[15] = abi.encode("Tunisia");

         //Group E
         worldCupTeams[16] = abi.encode("Spain");
         worldCupTeams[17] = abi.encode("Costa Rica");
         worldCupTeams[18] = abi.encode("Germany");
         worldCupTeams[19] = abi.encode("Japan");

         //Group F
         worldCupTeams[20] = abi.encode("Belgium");
         worldCupTeams[21] = abi.encode("Canada");
         worldCupTeams[22] = abi.encode("Morocco");
         worldCupTeams[23] = abi.encode("Croatia");

         //Group G
         worldCupTeams[24] = abi.encode("Brazil");
         worldCupTeams[25] = abi.encode("Serbia");
         worldCupTeams[26] = abi.encode("Switzerland");
         worldCupTeams[27] = abi.encode("Cameroon");

         //Group H
         worldCupTeams[28] = abi.encode("Portugal");
         worldCupTeams[29] = abi.encode("Ghana");
         worldCupTeams[30] = abi.encode("Uruguay");
         worldCupTeams[31] = abi.encode("Korea Republic");
    }
     modifier payEnoughForFirstFour {
      (uint maticPrice) = getLatestPrice();
     if(maticPrice >= 40000000) {
       require(msg.value >= 1 ether, "PAY_MORE_TO_MINT");
     } else {
      require(msg.value >= 50 ether, "PAY_MORE_TO_MINT");
     }
     _;
   }

    modifier payEnoughForExtraTwo {
      (uint maticPrice) = getLatestPrice();
     if(maticPrice >= 40000000) {
       require(msg.value > 1 ether, "PAY_MORE_TO_MINT");
     } else {
      require(msg.value > 25 ether, "PAY_MORE_TO_MINT");
     }
     _;
   }

  function getLatestPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

  //mint first 4 teams before the worldcup starts
   function mintTopFourTeams(string calldata _teamOne, string calldata _teamTwo, string calldata _teamThree, string calldata _teamFour) external payable payEnoughForFirstFour nonReentrant onlyWhenNotPaused {
     require(msg.sender == tx.origin, "NO_BOTS_ALLOWED");
     require(alreadyMinted[msg.sender] == false, "CANT_MINT_TEAMS_TWICE");
     require(currentPhase == GamePhases.MINT, "INITIAL_MINTING_PHASE_OVER");
    //Makes sure the user doesn't mint duplicate teams
     if(keccak256(abi.encode(_teamOne)) == keccak256(abi.encode(_teamTwo)) || keccak256(abi.encode(_teamOne)) == keccak256(abi.encode(_teamThree)) || keccak256(abi.encode(_teamOne)) == keccak256(abi.encode(_teamFour)) || keccak256(abi.encode(_teamTwo)) == keccak256(abi.encode(_teamThree)) || keccak256(abi.encode(_teamTwo)) == keccak256(abi.encode(_teamFour)) || keccak256(abi.encode(_teamThree)) == keccak256(abi.encode(_teamFour))) {
       revert("CANT_HAVE_DUPLICATE_TEAMS");
     }
     //boolean values have to equal true to confirm that the teams entered as arguments in the function are valid and are within the worldcupteam array
     bool teamOneConfirmed;
     bool teamTwoConfirmed;
     bool teamThreeConfirmed;
     bool teamFourConfirmed;
     for(uint i = 0; i < 32; i++) {
       if(teamOneConfirmed == false && keccak256(abi.encode(_teamOne)) == keccak256(worldCupTeams[i])) {
         teamOneConfirmed = true;
         predictors[msg.sender].teamOne = abi.encode(_teamOne);
       } 

       if(teamTwoConfirmed == false && keccak256(abi.encode(_teamTwo)) == keccak256(worldCupTeams[i])) {
         teamTwoConfirmed = true;
         predictors[msg.sender].teamTwo = abi.encode(_teamTwo);
       }

        if(teamThreeConfirmed == false && keccak256(abi.encode(_teamThree)) == keccak256(worldCupTeams[i])) {
         teamThreeConfirmed = true;
         predictors[msg.sender].teamThree = abi.encode(_teamThree);
       }

        if(teamFourConfirmed == false && keccak256(abi.encode(_teamFour)) == keccak256(worldCupTeams[i])) {
         teamFourConfirmed = true;
         predictors[msg.sender].teamFour = abi.encode(_teamFour);
       }

       if(teamOneConfirmed == true && teamTwoConfirmed == true && teamThreeConfirmed == true && teamFourConfirmed == true) break;
     }
     if(teamOneConfirmed != true || teamTwoConfirmed != true || teamThreeConfirmed != true || teamFourConfirmed != true) {
      revert("TEAMS_MUST_BE_VALID");
     } else {
      balances[msg.sender] += msg.value;
      Points storage playerPoints = predictorPoints[predictorPointIndex];
      playerPoints.predictor = payable(msg.sender);
      predictors[msg.sender].predictorIndex = predictorPointIndex;
      alreadyMinted[msg.sender] = true;
      unchecked {
         predictorPointIndex++;
      }
      changeThePhase();
      mintNFTs(msg.sender, _teamOne, _teamTwo, _teamThree, _teamFour, true);
      emit AllPredictors(address(this), msg.sender);
     }
   }

   function mintNFTs(address _predictor, string calldata _teamOne, string calldata _teamTwo, string calldata _teamThree, string calldata _teamFour, bool firstFourMinted) internal {
      IMintTeams(mintTeamAddress).claimLevel1Nft(_predictor, _teamOne, firstFourMinted);
      IMintTeams(mintTeamAddress).claimLevel1Nft(_predictor, _teamTwo, firstFourMinted);
      IMintTeams(mintTeamAddress).claimLevel1Nft(_predictor, _teamThree, firstFourMinted);
      IMintTeams(mintTeamAddress).claimLevel1Nft(_predictor, _teamFour, firstFourMinted);
   }
  
  //Same concept as the function above 
   function mintOtherTwoTeams(string calldata _teamFive, string calldata _teamSix) external payable payEnoughForExtraTwo nonReentrant onlyWhenNotPaused {
     require(msg.sender == tx.origin, "NO_BOTS_ALLOWED");
     require(extraTwoTeamsMinted[msg.sender] == false, "ALREADY_MINTED");
     require(alreadyMinted[msg.sender] == true, "MINT_FIRST_FOUR_TEAMS_FIRST");
     require(currentPhase == GamePhases.TOP32, "INITIAL_MINTING_PHASE_HASNT_FINISHED");
     require(keccak256(abi.encode(_teamFive)) != keccak256(predictors[msg.sender].teamOne) && keccak256(abi.encode(_teamFive)) != keccak256(predictors[msg.sender].teamTwo) && keccak256(abi.encode(_teamFive)) != keccak256(predictors[msg.sender].teamThree) && keccak256(abi.encode(_teamFive)) != keccak256(predictors[msg.sender].teamFour), "CANT_HAVE_DUPLICATE_TEAMS");
     require(keccak256(abi.encode(_teamSix)) != keccak256(predictors[msg.sender].teamOne) && keccak256(abi.encode(_teamSix)) != keccak256(predictors[msg.sender].teamTwo) && keccak256(abi.encode(_teamSix)) != keccak256(predictors[msg.sender].teamThree) && keccak256(abi.encode(_teamSix)) != keccak256(predictors[msg.sender].teamFour), "CANT_HAVE_DUPLICATE_TEAMS");
     require(keccak256(abi.encode(_teamFive)) != keccak256(abi.encode(_teamSix)), "CANT_HAVE_DUPLICATE_TEAMS");
     bool teamFiveConfirmed;
     bool teamSixConfirmed;
     for(uint i = 0; i < 32; i++) {
       if(teamFiveConfirmed == false && keccak256(abi.encode(_teamFive)) == keccak256(worldCupTeams[i])) {
         teamFiveConfirmed = true;
         predictors[msg.sender].teamFive = abi.encode(_teamFive);
       } 
       if(teamSixConfirmed == false && keccak256(abi.encode(_teamSix)) == keccak256(worldCupTeams[i])) {
         teamSixConfirmed = true;
         predictors[msg.sender].teamSix = abi.encode(_teamSix);
       } 
       if(teamFiveConfirmed == true && teamSixConfirmed == true) break;
     }
     if(teamFiveConfirmed != true || teamSixConfirmed != true) {
      revert("TEAMS_MUST_BE_VALID");
     } else {
       changeThePhase();
       balances[msg.sender] += msg.value;
       extraTwoTeamsMinted[msg.sender] = true;
       IMintTeams(mintTeamAddress).claimLevel1Nft(msg.sender, _teamFive, false);
       IMintTeams(mintTeamAddress).claimLevel1Nft(msg.sender, _teamSix, false);
     }
   }

   function checkUpkeep(bytes calldata /*checkData*/) external view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool hasLink = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB).balanceOf(address(this)) > 0.0001 * 10 ** 18;
        bool worldCupFinished = currentPhase != GamePhases.WORLD_CUP_FINISHED;
        bool phase = currentPhase == GamePhases.TOP16;
        upkeepNeeded = hasLink && worldCupFinished && phase;
    }

     function performUpkeep(bytes calldata /*performData*/) external {
         IRetrieveRandomNumber(randomAddress).requestRandomWords();
         fewMinutes = block.timestamp + 3 minutes;
  }

    function setAddresses(address _randomAddress, address _worldCupData16Address, address _changeOrderAddress, address _fetchTeamAddress, address _mintTeamAddress, address _worldCupData8Address, address _worldCupData4Address) external onlyOwner {
       setRandomAddress(_randomAddress);
       setWorldCupDataAddress(_worldCupData16Address, _worldCupData8Address, _worldCupData4Address);
       setChangeOrderAddress(_changeOrderAddress);
       setFetchTeamOne(_fetchTeamAddress);
       setMintTeamOneAddress(_mintTeamAddress);
    }

  function setRandomAddress(address _randomAddress) internal {
     randomAddress = _randomAddress;
  }

  function setWorldCupDataAddress(address _worldCupData16Address, address _worldCupData8Address, address _worldCupData4Address) internal {
    worldCupData16Address = _worldCupData16Address;
    worldCupData8Address = _worldCupData8Address;
    worldCupData4Address = _worldCupData4Address;
  }

  function setChangeOrderAddress(address _changeOrderAddress) internal {
    changeOrderAddress = _changeOrderAddress;
  }  

  function setFetchTeamOne(address _fetchTeamAddress) internal {
    fetchTeamAddress = _fetchTeamAddress;
  }

  function setMintTeamOneAddress(address _mintTeamAddress) internal {
     mintTeamAddress = _mintTeamAddress;
  }

  function changeThePhase() internal {
     if(currentPhase == GamePhases.MINT) {
       currentPhase = GamePhases.TOP32;
     } else if(currentPhase == GamePhases.TOP32) {
        currentPhase = GamePhases.TOP16;
     } else if(currentPhase == GamePhases.TOP16) {
       currentPhase = GamePhases.TOP8;
     }
  }

function depositPoints() external onlyWhenNotPaused nonReentrant {
  require(block.timestamp > fewMinutes, "WAIT_FOR_CONFIRMATION");
  require(currentPhase == GamePhases.TOP16, "CANT_DEPOSITS_POINTS");
  require(depositedPoints[msg.sender] == false, "CANT_DEPOSIT_POINTS_TWICE");
  require(alreadyMinted[msg.sender] == true, "NEVER_MINTED");
  uint index = predictors[msg.sender].predictorIndex;
  Points storage predictor = predictorPoints[index];
  bytes memory firstPlaceTeam = IFetchTeams(fetchTeamAddress).getFirstPlaceTeam();
  bytes memory secondPlaceTeam = IFetchTeams(fetchTeamAddress).getSecondPlaceTeam();
  bytes memory thirdPlaceTeam = IFetchTeams(fetchTeamAddress).getThirdPlaceTeam();
  bytes memory fourthPlaceTeam = IFetchTeams(fetchTeamAddress).getFourthPlaceTeam();
  if(keccak256(predictors[msg.sender].teamOne) == keccak256(firstPlaceTeam)) {
     predictor.points += 1000;
  }
   if(keccak256(predictors[msg.sender].teamTwo) == keccak256(secondPlaceTeam)) {
     predictor.points += 500;
  }
   if(keccak256(predictors[msg.sender].teamThree) == keccak256(thirdPlaceTeam)) {
     predictor.points += 250;
  }
   if(keccak256(predictors[msg.sender].teamFour) == keccak256(fourthPlaceTeam)) {
     predictor.points += 125;
  }
  depositedPoints[msg.sender] = true;
  retrievePredictorPoints();
}

function retrievePredictorPoints() private  {
 for(uint i = 0; i < predictorPointIndex+1; i++) {
  Points memory pointer = predictorPoints[i];
   if(pointer.points > highestAmountOfPoints) {
     highestAmountOfPoints = pointer.points;
   } else if(pointer.points > secondHighestAmountOfPoints) {
      secondHighestAmountOfPoints = pointer.points;
   } else if(pointer.points > thirdHighestAmountOfPoints) {
     thirdHighestAmountOfPoints = pointer.points;
   }
 }
 emit TopPoints(highestAmountOfPoints, secondHighestAmountOfPoints, thirdHighestAmountOfPoints);
 getWinnerCandidates();
}

function getWinnerCandidates() private {
 for(uint i = 0; i < predictorPointIndex+1; i++) {
  Points memory pointer = predictorPoints[i];
    if(pointer.points == highestAmountOfPoints) {
       predictorsWithBiggestPoints.push(pointer.predictor);
    } else if(pointer.points == secondHighestAmountOfPoints) {
       predictorsWithSecondBiggestPoints.push(pointer.predictor);
    } else if(pointer.points == thirdHighestAmountOfPoints) {
      predictorsWithThirdBiggestPoints.push(pointer.predictor);
    }
 }
 chooseWinners();
}

function chooseWinners() private {
  address payable winnerOne;
  address payable winnerTwo;
  address payable winnerThree;
   
  if(predictorsWithBiggestPoints.length == 0) {
      (bool fulfilled, uint[] memory randomWords) = IRetrieveRandomNumber(randomAddress).getRequestStatus();
      if(fulfilled == true) {
        winnerOne = predictorPoints[randomWords[0] % predictorPointIndex].predictor;
        winnerTwo = predictorPoints[randomWords[1] % predictorPointIndex].predictor;
        winnerThree = predictorPoints[randomWords[2] % predictorPointIndex].predictor;
        (bool sent, ) = winnerOne.call{value: ((address(this).balance * 30)/100)}("");
        require(sent, "Failed to send Funds");
        (bool sentTwo, ) = winnerTwo.call{value: ((address(this).balance * 30)/100)}("");
        require(sentTwo, "Failed to send Funds"); 
        (bool sentThree, ) = winnerThree.call{value: ((address(this).balance * 30)/100)}("");
        require(sentThree, "Failed to send Funds");
        emit Winners(winnerOne, winnerTwo, winnerThree);
      }
  } else if(predictorsWithSecondBiggestPoints.length == 0) {
    (bool fulfilled, uint[] memory randomWords) = IRetrieveRandomNumber(randomAddress).getRequestStatus();
    if(fulfilled == true) {
       winnerOne = predictorsWithBiggestPoints[randomWords[0] % predictorsWithBiggestPoints.length];
       winnerTwo = predictorsWithBiggestPoints[randomWords[1] % predictorsWithBiggestPoints.length];
       winnerThree = predictorsWithBiggestPoints[randomWords[2] % predictorsWithBiggestPoints.length];
      (bool sent, ) = winnerOne.call{value: ((address(this).balance * 30)/100)}("");
      require(sent, "Failed to send Funds");
      (bool sentTwo, ) = winnerTwo.call{value: ((address(this).balance * 30)/100)}("");
      require(sentTwo, "Failed to send Funds"); 
      (bool sentThree, ) = winnerThree.call{value: ((address(this).balance * 30)/100)}("");
      require(sentThree, "Failed to send Funds");
      emit Winners(winnerOne, winnerTwo, winnerThree);
    }
  } else if(predictorsWithThirdBiggestPoints.length == 0) {
     (bool fulfilled, uint[] memory randomWords) = IRetrieveRandomNumber(randomAddress).getRequestStatus();
    if(fulfilled == true) {
       winnerOne = predictorsWithBiggestPoints[randomWords[0] % predictorsWithBiggestPoints.length];
       winnerTwo = predictorsWithSecondBiggestPoints[randomWords[1] % predictorsWithSecondBiggestPoints.length];
       winnerThree = predictorsWithSecondBiggestPoints[randomWords[2] % predictorsWithSecondBiggestPoints.length];
      (bool sent, ) = winnerOne.call{value: ((address(this).balance * 40)/100)}("");
      require(sent, "Failed to send Funds");
      (bool sentTwo, ) = winnerTwo.call{value: ((address(this).balance * 25)/100)}("");
      require(sentTwo, "Failed to send Funds"); 
      (bool sentThree, ) = winnerThree.call{value: ((address(this).balance * 25)/100)}("");
      require(sentThree, "Failed to send Funds");
      emit Winners(winnerOne, winnerTwo, winnerThree);
    }
  } else {
     (bool fulfilled, uint[] memory randomWords) = IRetrieveRandomNumber(randomAddress).getRequestStatus();
     if(fulfilled == true) {
       winnerOne = predictorsWithBiggestPoints[randomWords[0] % predictorsWithBiggestPoints.length];
       winnerTwo = predictorsWithSecondBiggestPoints[randomWords[1] % predictorsWithSecondBiggestPoints.length];
       winnerThree = predictorsWithThirdBiggestPoints[randomWords[2] % predictorsWithThirdBiggestPoints.length];
      (bool sent, ) = winnerOne.call{value: ((address(this).balance * 40)/100)}("");
      require(sent, "Failed to send Funds");
      (bool sentTwo, ) = winnerTwo.call{value: ((address(this).balance * 30)/100)}("");
      require(sentTwo, "Failed to send Funds"); 
      (bool sentThree, ) = winnerThree.call{value: ((address(this).balance * 20)/100)}("");
      require(sentThree, "Failed to send Funds");
      emit Winners(winnerOne, winnerTwo, winnerThree);
    }
  }
}

function setPause(bool _paused) external onlyOwner {
     paused = _paused;
   }

function setRefund(bool _canReceiveRefund) external onlyOwner {
    canReceiveRefund = _canReceiveRefund;
  }


 function receiveBackMoney() external {
     require(balances[msg.sender] != 0, "YOU_HAVE_NO_BALANCE");
     require(canReceiveRefund == true, "NO_REFUNDS_AT_THIS_TIME");
     uint amount = balances[msg.sender];
     balances[msg.sender] = 0;
     (bool sent, ) = payable(msg.sender).call{value:amount}("");
     require(sent, "FAILED_TO_SEND_FUNDS");
   }

   function withdraw() external onlyOwner afterEvent {
        require(canReceiveRefund == false, "NO_BALANCE_TO_RECEIVE");
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: ((amount * 10)/100)}("");
        require(sent, "Failed to send Funds");
  }

    function getPrediction(address _predictor, uint _num) public view returns(bytes memory team) {
      if(_num == 1) {
        return predictors[_predictor].teamOne;
      } else if(_num == 2) {
         return predictors[_predictor].teamTwo;
      }  else if(_num == 3) {
         return predictors[_predictor].teamThree;
      }  else if(_num == 4) {
         return predictors[_predictor].teamFour;
      }  else if(_num == 5) {
         return predictors[_predictor].teamFive;
      }  else if(_num == 6) {
         return predictors[_predictor].teamSix;
      }
    }

    function setFirstPrediction(address _predictor, bytes memory _team) public {
      require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamOne = _team;
    }

    function setSecondPrediction(address _predictor, bytes memory _team) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamTwo = _team;
    }

    function setThirdPrediction(address _predictor, bytes memory _team) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamThree = _team;
    }

    function setFourthPrediction(address _predictor, bytes memory _team) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamFour = _team;
    }

    function setFifthPrediction(address _predictor, bytes memory _team) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamFive = _team;
    }

    function setSixthPrediction(address _predictor, bytes memory _team) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
      predictors[_predictor].teamSix = _team;
    }

    function isPhase32() public view returns(bool) {
      return currentPhase == GamePhases.TOP32;
    }

    function isPhase16() public view returns(bool) {
      return currentPhase == GamePhases.TOP16;
    }

    function isPhase8() public view returns(bool) {
      return currentPhase == GamePhases.TOP8;
    }
    
    function isPhase4() public view returns(bool) {
      return currentPhase == GamePhases.TOP4;
    }

    function haveYouMinted(address _predictor) public view returns(bool) {
      return alreadyMinted[_predictor];
    }
    
    function mintedExtraTwo(address _predictor) public view returns(bool) {
      return extraTwoTeamsMinted[_predictor];
    }

    function hasItBeenThreeMinutes() public view returns(bool) {
      return block.timestamp > fewMinutes;
    }

    function viewPoints() external view returns(uint) {
       uint index = predictors[msg.sender].predictorIndex;
      Points storage predictor = predictorPoints[index];
      return predictor.points;
    }

    function setOrder(address _predictor, uint _num) public {
       require(msg.sender == changeOrderAddress, "USER_CANT_USE_FUNCTION");
        if(_num == 32) {
        changedOrderForTop32[_predictor] = true;
      } else if(_num == 16) {
        changedOrderForTop16[_predictor] = true;
      } else if(_num == 8) {
         changedOrderForTop8[_predictor] = true;
      } else if(_num == 4) {
       changedOrderForTop4[_predictor] = true;
      }
    } 

    function changedOrder(address _predictor, uint _num) public view returns(bool orderChanged) {
      if(_num == 32) {
        return changedOrderForTop32[_predictor];
      } else if(_num == 16) {
        return changedOrderForTop16[_predictor];
      } else if(_num == 8) {
        return changedOrderForTop8[_predictor];
      } else if(_num == 4) {
        return changedOrderForTop4[_predictor];
      }
    }
    
    receive() external payable{}
    fallback() external payable{}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFetchTeams {
    function setFirstPlaceTeam(string memory _teamId) external;
    function setSecondPlaceTeam(string memory _teamId) external;
    function setThirdPlaceTeam(string memory _teamId) external;
    function setFourthPlaceTeam(string memory _teamId) external;
    function setFifthPlaceTeam(string memory _teamId) external;
    function setSixthPlaceTeam(string memory _teamId) external;
    function setSeventhPlaceTeam(string memory _teamId) external;
    function setEighthPlaceTeam(string memory _teamId) external;
    function setNinthPlaceTeam(string memory _teamId) external;
    function setTenthPlaceTeam(string memory _teamId) external;
    function setEleventhPlaceTeam(string memory _teamId) external;
    function setTwelfthPlaceTeam(string memory _teamId) external;
    function setThirteenthPlaceTeam(string memory _teamId) external;
    function setFourteenthPlaceTeam(string memory _teamId) external;
    function setFifteenthPlaceTeam(string memory _teamId) external;
    function setSixteenthPlaceTeam(string memory _teamId) external;
    function getFirstPlaceTeam() external view returns(bytes memory team);
    function getSecondPlaceTeam() external view returns(bytes memory team);
    function getThirdPlaceTeam() external view returns(bytes memory team);
    function getFourthPlaceTeam() external view returns(bytes memory team);
    function getFifthPlaceTeam() external view returns(bytes memory team);
    function getSixthPlaceTeam() external view returns(bytes memory team);
    function getSeventhPlaceTeam() external view returns(bytes memory team);
    function getEighthPlaceTeam() external view returns(bytes memory team);
    function getNinthPlaceTeam() external view returns(bytes memory team);
    function getTenthPlaceTeam() external view returns(bytes memory team);
    function getEleventhPlaceTeam() external view returns(bytes memory team);
    function getTwelfthPlaceTeam() external view returns(bytes memory team);
    function getThirteenthPlaceTeam() external view returns(bytes memory team);
    function getFourteenthPlaceTeam() external view returns(bytes memory team);
    function getFifteenthPlaceTeam() external view returns(bytes memory team);
    function getSixteenthPlaceTeam() external view returns(bytes memory team);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintTeams {
    function claimLevel1Nft(address _predictor, string calldata _teamName, bool firstFourMinted) external;
    function claimLevel2Nft(address _predictor, string calldata _teamName) external;
    function claimLevel3Nft(address _predictor, string calldata _teamName) external;
    function claimLevel4Nft(address _predictor, string calldata _teamName) external;
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint id, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRetrieveRandomNumber {
    function requestRandomWords() external returns (uint256 requestId);
    function getRequestStatus() external view returns (bool fulfilled, uint256[] memory randomWords);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWorldCupData {
     function fetchTop16Teams() external;
     function fetchTop8Teams() external;
     function fetchTop4Teams() external;
}