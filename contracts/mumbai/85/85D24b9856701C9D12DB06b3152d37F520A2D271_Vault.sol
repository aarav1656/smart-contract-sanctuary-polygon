// // SPDX-License-Identifier: MIT
/*  
   _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OptInOptOut.sol";
contract Vault{

   error zeroAddressNotSupported();
   error adminAlreadyExist();
   error notAdminAddress();
   error percentageIsTooHigh();
   error maxCommisionReached();
   error packageValueMisMatch();

   uint packageId;
   address public owner;
   address private optInContractAd;
   mapping(uint => address) private tokenAddress;
   address[] private adminAddresses;
   mapping(uint => bool) private packDepositStatus;
   mapping(uint => uint) private packageTokensValue;
   mapping(address => bool) private adminAddress;
   mapping(uint => packageDetails) package;   
   mapping(uint => mapping(address => bool)) private userRewardStatus;

   struct packageDetails {
      uint fieldVal; // we will pass value in wei format.
      uint commission; // regualr 20.
   }

   event AdminWhitelisted(address indexed Admin);
   event ContractWhitelisted(address indexed Contract);
   event TokensDeposited(address indexed From, uint indexed Amount);
   event PackageId(uint indexed PackageId);

   constructor(){
      owner = msg.sender;
   }

   modifier onlyOwner {
      require(msg.sender == owner,"you are not the admin");
      _;
   }

    /**
      * whitelistAdmin. 
      * @param _admin Enter the admin address to be logged to the smart contract.
      * admin has the access to control most of the function in this contract.
    */
   function whitelistAdmin(address _admin) external onlyOwner{
      if(_admin == address(0)){ revert zeroAddressNotSupported();}
      if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
      adminAddress[_admin] = true;
      adminAddresses.push(_admin);
      emit AdminWhitelisted(_admin);
   }

   /**
      * whitelistUserContract.
      * @param _optInOptOutContractAd The deployede userContract address needs to be added by the admin.
   */
   function whitelistOptInOptOutContract(address _optInOptOutContractAd) external{
      if(_optInOptOutContractAd == address(0)){ revert zeroAddressNotSupported();}
      if(!adminAddress[msg.sender]){ revert notAdminAddress();}
      optInContractAd = _optInOptOutContractAd;
      emit ContractWhitelisted(_optInOptOutContractAd);
   }

   /**
      * createPackage.
      * @param _pcDetails - Enter the struct type.
   */
   function createPackage(packageDetails memory _pcDetails) external {
      if(!adminAddress[msg.sender]){ revert notAdminAddress();}
      if(_pcDetails.commission >= 100){ revert maxCommisionReached();}
      packageId += 1;
      uint id = packageId;
      package[id] = _pcDetails;
      emit PackageId(id);
   }

   /**
      * depositTokens
      * @param _contractAd - Enter the token contract address.
      * @param _tokens - Enter the solo tokens to the vault treasury. 
   */
   function depositTokens(uint _packageId, address _contractAd, uint _tokens) external{
      if(!adminAddress[msg.sender]){ revert notAdminAddress();}
      OptInOptOut opc = OptInOptOut(optInContractAd);
      uint totalFields = opc.packageTotalValue(_packageId);
      uint packageTotalValue = package[_packageId].fieldVal * totalFields; // field value is solo tokens per 1$. = 20 solo(currently passing in wei)
      packageTotalValue -= (packageTotalValue * package[_packageId].commission)/100; // reducing commision from the package value.
      // packageTotalValue *=  (10 ** 18);
      if(packageTotalValue != _tokens){ revert packageValueMisMatch();}
      packageTokensValue[_packageId] = _tokens;
      tokenAddress[_packageId] = _contractAd;
      packDepositStatus[_packageId] = true;
      IERC20(_contractAd).transferFrom(msg.sender,address(this),packageTokensValue[_packageId]);
      emit TokensDeposited(msg.sender, _tokens);
   }

   /**
      * transferpackageTokensValue
      * @param _packageId - Enter the package id.
   */
   function transferpackageTokensValue(uint _packageId) external{
      if(!adminAddress[msg.sender]){ revert notAdminAddress();}
      OptInOptOut opc = OptInOptOut(optInContractAd);
      address[] memory addresses = opc.packageUserAddresses(_packageId);
      for(uint i = 0; i < addresses.length; i++){
         if(!userRewardStatus[_packageId][addresses[i]]){
            uint userTotalFields = opc.userTransferredDataValue(addresses[i], _packageId); // eg: 15 
            uint userTotalValue = package[_packageId].fieldVal * userTotalFields; // 20(value will be passed in wei format for fields) * 20 = 300
            userTotalValue -= (userTotalValue * package[_packageId].commission)/100; // reducing commision from the user value.
            packageTokensValue[_packageId] -= userTotalValue;
            // userTotalValue *= (10 ** 18); // check 
            userRewardStatus[_packageId][addresses[i]] = true;
            IERC20(tokenAddress[_packageId]).transferFrom(address(this), addresses[i], userTotalValue);
         }
      }
   }

   function packageDetailInfo(uint _packageId) external view returns(packageDetails memory){
      return package[_packageId];
   }

   function packageDepositStatus(uint _packageId) external view returns(bool status, uint availablePackageFund){
      return (packDepositStatus[_packageId], packageTokensValue[_packageId]);
   }

   function userCreditStatus(uint _packageId, address _userAd) external view returns(bool rewardStatus){
      return userRewardStatus[_packageId][_userAd];
   }
}

// // SPDX-License-Identifier: MIT
/*
   _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

import "./UserContract.sol";
contract OptInOptOut{
    /**
     * @dev OptIn/OptOut contract is used to log in the details from the solosecure application.
     * Location -> Network -> Oura ring(wearables).
    */
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notAdminAddress();
    error userContractError();

    address[] private adminAddresses;
    address public owner;
    address userContractAddress;

    mapping(address => bool) private adminAddress;
    mapping(address => optIns) private userOptIns;
    // mapping(address => optInsData[]) private userDataTx;
    mapping(uint => mapping(address => optInsData)) private userTxCount;
    mapping(uint => mapping(address => uint)) private userTxValue;
    mapping(uint => uint) private packageValue;
    mapping(uint => address[]) private packageUsers;

    event Location(address indexed User, bool indexed Status);
    event Network(address indexed User, bool indexed Status);
    event OuraRing(address indexed User, bool indexed Status);
    event UserTransaction(uint indexed PackageId, address indexed User, uint indexed userFieldsCount);

    struct optIns{
        bool location;
        bool network;
        bool ouraRing;
    }

    struct optInsData{
        uint location;
        uint network;
        ouraRingData ouraData;
        uint timeStamp;
    }

    struct ouraRingData{
        uint age;
        uint weight;
        uint height;
        uint biologicalSex;
        uint bodyTemperature;
        uint prevDayActivity;
        uint restingHeartRate;
        uint tempDeviation;
        uint bedTimeStart;
        uint bedTimeEnd;
        uint timeInBed;
        uint avgBreath;
        uint avgHeartRate;
        uint bpm;
        uint source;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    /**
        * whitelistAdmin. 
        * @param _admin Enter the admin address to be logged to the smart contract.
        * admin has the access to control most of the function in this contract.
    */
    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }

    /**
        * whitelistUserContract.
        * @param _userContractAd The deployede userContract address needs to be added by the admin.
    */
    function whitelistUserContract(address _userContractAd) external{
        if(_userContractAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        userContractAddress = _userContractAd;
    }

    /**
        * optLocation
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optLocation(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].location = _optStatus; 
        emit Location(_userAd,_optStatus);
    }

    /**
        * optNetwork
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optNetwork(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].network = _optStatus; 
        emit Network(_userAd,_optStatus);
    }

    /**
        * optOuraRing
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optOuraRing(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].ouraRing = _optStatus; 
        emit OuraRing(_userAd,_optStatus);
    }

    function userDataTransfer(address _userAd, uint _packageId, uint _location, uint _network, ouraRingData memory _ouraData) 
    external{
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        //$ oura data(start)
        uint count = 0;
        count += _location;
        count += _network;
        count += _ouraData.age;
        count += _ouraData.weight;
        count += _ouraData.height;
        count += _ouraData.biologicalSex;
        count += _ouraData.bodyTemperature;
        count += _ouraData.prevDayActivity;
        count += _ouraData.restingHeartRate;
        count += _ouraData.tempDeviation;
        count += _ouraData.bedTimeStart;
        count += _ouraData.bedTimeEnd;
        count += _ouraData.timeInBed;
        count += _ouraData.avgBreath;
        count += _ouraData.avgHeartRate;
        count += _ouraData.bpm;
        count += _ouraData.source;
        //$ oura data(end)
        optInsData memory data;
        data.location = _location;
        data.network = _network;
        data.ouraData = _ouraData;
        data.timeStamp = block.timestamp;
        userTxCount[_packageId][_userAd] = data;
        userTxValue[_packageId][_userAd] = count;
        packageValue[_packageId] += count; // package id is same but _userAd will be different.
        packageUsers[_packageId].push(_userAd); // assuming there will be no duplicate tx per user in the same package.
        emit UserTransaction(_packageId, _userAd, count);
    }

    //Read Functions:
    function userOptStatus(address _userAd) external view returns(optIns memory status){
        return userOptIns[_userAd];
    }

    function userTransferredData(address _userAd, uint _packageId) external view returns(optInsData memory data){
        return userTxCount[_packageId][_userAd];
    }

    function userTransferredDataValue(address _userAd, uint _packageId) external view returns(uint){
        return userTxValue[_packageId][_userAd];
    }

    function packageTotalValue(uint _packageId) external view returns(uint){
        return packageValue[_packageId];
    }

    function packageUserAddresses(uint _packageId) external view returns(address[] memory){
        return packageUsers[_packageId];
    }

    function allAdmins() external view returns(address[] memory){
        return adminAddresses;
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

// // SPDX-License-Identifier: MIT
/*  
   _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

contract UserContract{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error invalidType();
    
    address[] private pushUsers;
    address public admin;
    mapping(address => bool) private isUser;
    mapping(address => uint) private userTypeData;
    mapping(uint => string) public userTypes;

    /**
        * constructor
        * @param _setAdmin - Set the admin for the smart contract. 
    */
    constructor(address _setAdmin){
        admin = _setAdmin;
        userTypes[1] = "admin";
        userTypes[2] = "corporateUser";
        userTypes[3] = "appUser"; 
    }

    modifier onlyAdmin {
        require(msg.sender == admin,"you are not the admin");
        _;
    }

    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
        * @param _type - Enter the type, whether admin, corporate user, app user. 
    */
    function addUser(address _ad, uint _type) external onlyAdmin{
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        if(bytes(userTypes[_type]).length == 0){ revert invalidType();}
        isUser[_ad] = true;
        userTypeData[_ad] = _type;
        pushUsers.push(_ad);
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool, uint){
        if(isUser[_ad]){
            return (true, userTypeData[_ad]);
        }else{
            return (false, userTypeData[_ad]);
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }    
}