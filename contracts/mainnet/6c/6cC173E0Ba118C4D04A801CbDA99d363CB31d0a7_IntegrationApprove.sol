// SPDX-License-Identifier: MIT
//pragma solidity >=0.8.0 <0.9.0;
pragma solidity 0.8.12;
import "UsersGroups.sol";
import "Bank.sol";
import "GovernorContract.sol";
import "Initializable.sol";

/// @title IntegrationApprove
/// @notice IntegrationApprove Contract stored Integration Approve.
/// @dev  IntegrationApprove Contract stored Integration Approve.
contract IntegrationApprove is Initializable{

    /// @notice Total Number of Integration.
    /// @dev Total Number of Integration.
    uint256 private totalNumber=0;

    /// @notice Reference to UsersGroups contract.
    /// @dev Reference to UsersGroups contract.
    UsersGroups private roles;

    /// @notice Reference to Bank contract.
    /// @dev Reference to Bank contract.
    Bank private bank;

    /// @notice Reference to Governor contract.
    /// @dev Reference to Governor contract.
    GovernorContract private governor;


    /// @notice Event emmited when Integration Approve is added.
    /// @dev Event emmited when Integration Approve is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveAdded(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is approved by user.
    /// @dev Event emmited when Integration Approve is approved by user.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveApproved(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is updated.
    /// @dev Event emmited when Integration Approve is updated.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveUpdated(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is approved by one user group required group.
    /// @dev Event emmited when Integration Approve is approved by one user group required group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    /// @return group Group confirmed.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveGroup(bool status,string message,uint id, bytes32 group, bool confirmation_status);

    /// @notice Event emmited when Integration Approve is executed.
    /// @dev Event emmited when Integration Approve is executed.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveExecute(bool status,string message,uint id);

    /// @notice Event emmited when user send confirmation.
    /// @dev Event emmited when user send confirmation.
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return account ID of integraition approve.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveUser(bool status,string message,address account, bool confirmation_status);

    /// @notice Structure of integration Approve.
    /// @dev Structure of integration Approve.
    /// @param status Status
    /// @param ipfs_hash IPFS CID of integration Approve
    /// @param to_user User to transfer money, when integration approve is confirmed.
    /// @param amount Amount of WEI to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Block for Start Confirmation Process
    /// @param block_end Block for End Confirmation Process
    /// @param confirmation_status Current Status
    struct IntegrationsApprove {
        uint256 id; // Proposal ID
        bool status; //if its blocked
        string ipfs_hash; // ipfs CID
        address payable to_user; // user transfer ether
        uint256 amount; // amoun to tranfer to that user
        bytes32[] groups; // groups should all confirm
        bytes32 group_for_vote; // group for vote on integration events
        uint256 block_start; // when start confirm
        uint256 block_end; // when stop confirm
        Confirmation confirmation_status;
    }

    /// @notice Structure of integration Approve Aggregate.
    /// @dev Structure of integration Approve Aggregate.
    /// @param status Status
    /// @param ipfs_hash IPFS CID of integration Approve
    /// @param to_user User to transfer money, when integration approve is confirmed.
    /// @param amount Amount of WEI to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Block for Start Confirmation Process
    /// @param block_end Block for End Confirmation Process
    /// @param confirmation_status Current Status
    /// @param hasConfirm If User Confrim Approve.
    struct IntegrationsApproveAggregate {
        uint256 id; // Proposal ID
        bool status; //if its blocked
        string ipfs_hash; // ipfs CID
        address payable to_user; // user transfer ether
        uint256 amount; // amoun to tranfer to that user
        bytes32[] groups; // groups should all confirm
        bytes32 group_for_vote; // group for vote on integration events
        uint256 block_start; // when start confirm
        uint256 block_end; // when stop confirm
        Confirmation confirmation_status;
        bool hasConfirm;
    }

    /// @notice Current status of confirmation.
    /// @dev Current status of confirmation.
    /// @common 123
    enum Confirmation {
        Pending,
        Confirmed,
        Execute,
        Defeted,
        Active,
        Waiting
    }

    /// @notice Constructor.
    /// @dev Constructor.
    /// @param roleContract Address UsersGroups contract
    /// @param bankContract Address Bank contract
    /// @param groups for future
    constructor (address roleContract,address payable bankContract,bytes32[] memory groups,address payable governorContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
        governor = GovernorContract(governorContract);
    }


     /// @notice Initializer.
    /// @dev Initializer.
    /// @param roleContract Address UsersGroups contract
    /// @param bankContract Address Bank contract
    /// @param groups for future
    function initialize (address roleContract,address payable bankContract,bytes32[] memory groups,address payable governorContract) initializer public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
        governor = GovernorContract(governorContract);
        
    }

    /// @notice Array of Integration Approve.
    /// @dev Array of Integration Approve.
    IntegrationsApprove[] private integrationsApprove;

    /// @notice map ID to index in array in integration Approve.
    /// @dev map ID to index in array in integration Approve.
    mapping(uint256 => uint256) integrationIndexMap;

    /// @notice map ID to status if exist.
    /// @dev map ID to status if exist.
    mapping(uint256 => bool) integrationExistMap;

    /// @notice mapping id of integration approve to group and bool; //true - confirmed
    /// @dev mapping id of integration approve to group and bool; //true - confirmed
    mapping(uint256 => mapping(bytes32 => bool)) groupStatusMap; //mapping id of integration approve to group and bool; //true - confirmed
    
    /// @notice mapping id of integration approve to user and bool; //true - confirmed
    /// @dev mapping id of integration approve to user and bool; //true - confirmed
    mapping(uint256 => mapping(address => bool)) userStatusMap; //mapping id of integration approve to user and bool; //true - confirmed
    
    /// @notice mapping  of integration approve to its approved status.
    /// @dev mapping  of integration approve to its approved status.
    mapping(uint256 => bool) groupApprovedMap; // mapping  of integration approve to its status
    
    /// @notice mapping  of integration approve to its excution status.
    /// @dev mapping  of integration approve to its excution status.
    mapping(uint256 => bool) groupApprovedExecutionMap; // mapping  of integration approve to its status

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    modifier onlyIntegration()
    {
        require(roles.isIntegration(msg.sender), "Restricted to integration contract.");
        _;
    }

    /// @notice Add integration approve.
    /// @dev Add integration approve.
    /// @param _hash CID IPFS to integration Approve
    /// @param _account Account to transfer WEI, when integration approve is confirmed
    /// @param amount Amount USD to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Timestamp of Start Confirmation Process
    /// @param block_end Timestamp of Emd Confirmation Process
    /// @return integratipnApproveID ID of integration Approve
    function addIntegrationApprove(string memory _hash, address payable _account, uint256 amount, bytes32[] memory groups,bytes32 group_for_vote,uint256 block_start,uint256 block_end)
    public
    onlyIntegration
    returns (uint256) {
        
        
        uint256 _id= governor.getSingleProposalIdByCID(_hash);
        integrationsApprove.push(IntegrationsApprove(_id,false,_hash,_account,amount,groups,group_for_vote,block_start,block_end,Confirmation.Pending));
        totalNumber++;
        integrationIndexMap[_id] = integrationsApprove.length -1;
        groupApprovedExecutionMap[_id] = false;
        integrationExistMap[_id] = true;
        for(uint256 i=0;i<groups.length;i++){
            groupStatusMap[_id][groups[i]] = false;
        }
        emit IntegrationApproveAdded(true,"IntegrationApprove added",_id);
        return _id;
    }

    /// @notice Update IPFS CID.
    /// @dev Update IPFS CID.
    /// @param _id ID Integration Approve
    /// @param _hash New IPFS CID
    function updateHash(uint _id,string memory _hash)
    public
    onlyMember {
        require(integrationExistMap[_id],"Proposal not exist");
        if(integrationsApprove[integrationIndexMap[_id]].status== false)
        {
            integrationsApprove[integrationIndexMap[_id]].status== true;
            integrationsApprove[integrationIndexMap[_id]].ipfs_hash = _hash;
            emit IntegrationApproveUpdated(true,"IntegrationApproved updated",_id);
            integrationsApprove[integrationIndexMap[_id]].status== false;
        }
        else
        {
            emit IntegrationApproveUpdated(false,"IntegrationApproved update blocked by other task.",_id);
        }
    }

    /// @notice Get Total Integration Approve.
    /// @dev Get Total Integration Approve.
    /// @return count Count oF Integration Approve
    function getTotalIntegrationsNumber()
    public
    view
    returns (uint256)  {
        return totalNumber;
    }

    /// @notice Get Integration Approve By ID.
    /// @dev Get Integration Approve By ID.
    /// @param _id Integration Approve ID 
    /// @return struct of Integration
    function getIntegration(uint256 _id)
    public
    view
    returns (IntegrationsApprove memory)  {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]];
    }

    /// @notice Get Integration Approve CID IPFS.
    /// @dev Get Integration Approve CID IPFS.
    /// @param _id ID of Integration Approve
    /// @return cid_ipfs IPFS CID
    function getIntegrationHash(uint256 _id)
    public
    view
    returns (string memory) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].ipfs_hash;
    }

    /// @notice Get All Integration Approve.
    /// @dev Get All Integration Approve.
    /// @return list [] Array of Struct integration Approve.
    function getAllIntegrations()
    public
    view
    returns (IntegrationsApprove[] memory) {
        return integrationsApprove;
    }

    /// @notice Get Groups for Integration Approve.
    /// @dev Get Groups for Integration Approve.
    /// @param _id ID of Integration Approve.
    /// @return array Array fo Groups Names.
    function getGroupsAll(uint256 _id)
    public
    view
    returns (bytes32[] memory) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].groups;
    }

    /// @notice Validate if Inetgration Approve Exist.
    /// @dev Validate if Inetgration Approve Exist.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function ifIntegrationExist(uint256 _id)
    public
    view
    returns (bool) {
        return integrationExistMap[_id];
    }

    /// @notice Get Process status - not use, because of bug.
    /// @dev Get Process status - not use, because of bug.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function getProcessStatus(uint256 _id)
    public
    view
    returns (Confirmation) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].confirmation_status;
    }


    /// @notice Validate if confirmation is in progress.
    /// @dev Validate if confirmation is in progress.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function getConfirmStatus(uint256 _id)
    public
    view
    returns (Confirmation) {
        require(integrationExistMap[_id],"Proposal not exist");
        if( block.timestamp < integrationsApprove[integrationIndexMap[_id]].block_start){
            return Confirmation.Pending;
        }
        if( block.timestamp >= integrationsApprove[integrationIndexMap[_id]].block_start && block.timestamp <=integrationsApprove[integrationIndexMap[_id]].block_end )
        {
            return Confirmation.Active;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Execute)
        {
            return Confirmation.Execute;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Defeted)
        {
            return Confirmation.Defeted;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Confirmed)
        {
            return Confirmation.Confirmed;
        }
        return Confirmation.Waiting;
    }

    /// @notice Validate if group is confirmed.
    /// @dev Validate if group is confirmed.
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @return status Status of confirmation.
    function ifGroupConfirmed(uint256 _id,bytes32 _group)
    public
    view
    returns (bool) {
        require(integrationExistMap[_id],"Proposal not exist");
        return groupStatusMap[_id][_group];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }
    
    /// @notice Confirm Integration Approve by Group.
    /// @dev Confirm Integration Approve by Group.
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @param status True - For, False - Against.
    /// @return status Status of execution.
    function setGroupMap(uint256 _id,bytes32 _group,bool status)
    public
    
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveGroup(false,"Integration not exist.",_id,_group,status);
            return false;
        }
        
        if(ifGroup(_id, _group))
        {
            if(getConfirmStatus(_id) != Confirmation.Active)
            {
                emit IntegrationApproveGroup(false,"Confirmation not ready.",_id,_group,status);
                return false;
            }

            if(!roles.isRole(msg.sender, _group)){
                emit IntegrationApproveGroup(false,"User is not in required group.",_id,_group,status);
                return false;
            }

            groupStatusMap[_id][_group] = status;
            emit IntegrationApproveGroup(true,"Group was changed",_id,_group,status);
            return true;
        }
        else
        {
            //walidate if one from given group, who should vote can vote
            emit IntegrationApproveGroup(false,"This group not exist for this IntegrationApprove.",_id,_group,status);
            return false;
        }    
    }

    /// @notice Execute Integration Approve by User.
    /// @dev Execute Integration Approve by User.
    /// @param _id ID of Integration Approve.
    /// @return status Status of execution.
    function execute(uint256 _id)
    public
    onlyMember
    returns (bool){

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveExecute(false,"Integration not exist.",_id);
            return false;
        }

        if(block.timestamp > integrationsApprove[integrationIndexMap[_id]].block_end && block.timestamp > integrationsApprove[integrationIndexMap[_id]].block_start)
        {  
            if(groupApprovedExecutionMap[_id]){
                emit IntegrationApproveExecute(false,"Approve already executed.",_id);
                return false;
            }
            
            for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){            
                if(groupStatusMap[_id][integrationsApprove[integrationIndexMap[_id]].groups[i]] == false)            
                {         
                    groupApprovedExecutionMap[_id] = true;  
                    integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;     
                    emit IntegrationApproveExecute(false,"Not all group approved.",_id);
                    return false;
                
                }            
            }

            address[] memory users = roles.getUsersInGroup(integrationsApprove[integrationIndexMap[_id]].group_for_vote);
            //emit IntegrationApproveExecute(false,"Members",users.length);
            uint256 confirmed_Status = 0;

            for(uint i=0; i<users.length;i++){          
                if(userStatusMap[_id][users[i]] == true)            
                {                
                    confirmed_Status=confirmed_Status+1;
                }            
            }

            if((confirmed_Status *100)/(users.length) < 50)
            {
                groupApprovedExecutionMap[_id] = true;
                integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;
                emit IntegrationApproveExecute(false,"Required number of users not confirmed this approve.",confirmed_Status*100/users.length);
                return false;
            }

            groupApprovedExecutionMap[_id] = true;
            integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Confirmed;
            bank.internalTransfer(integrationsApprove[integrationIndexMap[_id]].to_user,integrationsApprove[integrationIndexMap[_id]].amount);
            //integrationsApprove[_id].amount
            emit IntegrationApproveExecute(true,"Execute completed.",_id);
            return true;
        }
        else
        {
            emit IntegrationApproveExecute(false,"Confirmation in not ended.",_id);
            return false;
        }
    }
    
    /// @notice Validate if group exist in list of groups for this integration.
    /// @dev Validate if group exist in list of groups for this integration.
    /// @param _id ID of Integration Approve.
    /// @param group Group Name.
    /// @return status Status of execution.
    function ifGroup(uint256 _id,bytes32 group)
    public
    view
    returns (bool) {
        require(integrationExistMap[_id],"Proposal not exist");
        for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){
            if(integrationsApprove[integrationIndexMap[_id]].groups[i] == group)
            {
                return true;
            }
        }
        return false;
    }

    /// @notice Get if User is confirm application approve.
    /// @dev Get if User is confirm application approve.
    /// @param _id ID of Integration Approve.
    /// @param _user Group Name.
    /// @return status Status of execution.
    function ifUserConfirmed(uint256 _id,address _user)
    public
    view
    returns (bool) {
        require(integrationExistMap[_id],"Proposal not exist");
        return userStatusMap[_id][_user];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }

    /// @notice Confirm Integration Approve by user.
    /// @dev Confirm Integration Approve by user.
    /// @param _id ID of Integration Approve.
    /// @param status True - yes, False - no
    /// @return status Status of execution.
    function setConfirmUser(uint256 _id,bool status)
    public
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveUser(false,"Integration not exist.",msg.sender,status);
            return false;
        }
        
            if(getConfirmStatus(_id) != Confirmation.Active)
            {
                emit IntegrationApproveUser(false,"Confirmation not ready.",msg.sender,status);
                return false;
            }

            if(!roles.isRole(msg.sender, integrationsApprove[integrationIndexMap[_id]].group_for_vote)){
                 emit IntegrationApproveUser(false,"User is not in required group for confirmation.",msg.sender,status);
                return false;
            }

            userStatusMap[_id][msg.sender] = status;
            emit IntegrationApproveUser(true,"User was changed",msg.sender,status);
            return true;
        
    }

    /// @notice Get Aggregate Info of Integration Approve.
    /// @dev Get Aggregate Info of Integration Approve.
    /// @return list List of Aggregation Appprove.
    /// , _id Proposal ID.
    /// , status Status.
    /// , ipfs_hash IPFS CID of integration Approve.
    /// , to_user User to transfer money, when integration approve is confirmed.
    /// , amount Amount of WEI to transfer.
    /// , groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// , group_for_vote Group for users, who can confirm.
    /// , block_start Block for Start Confirmation Process.
    /// , block_end Block for End Confirmation Process.
    /// , confirmation_status Current Status.
    /// , hasConfirm If User Confrim Approve.
    function getAllIntegrationAggregate()
    public
    view
    returns (IntegrationsApproveAggregate[] memory) {
        IntegrationsApproveAggregate[] memory  integration_aggregate = new IntegrationsApproveAggregate[](integrationsApprove.length);
        for(uint256 i=0; i<integrationsApprove.length;i++){
            integration_aggregate[i].id = integrationsApprove[i].id;
            integration_aggregate[i].status = integrationsApprove[i].status;
            integration_aggregate[i].ipfs_hash = integrationsApprove[i].ipfs_hash;
            integration_aggregate[i].to_user = integrationsApprove[i].to_user;
            integration_aggregate[i].amount = integrationsApprove[i].amount;
            integration_aggregate[i].groups = integrationsApprove[i].groups;
            integration_aggregate[i].group_for_vote = integrationsApprove[i].group_for_vote;
            integration_aggregate[i].block_start = integrationsApprove[i].block_start;
            integration_aggregate[i].block_end = integrationsApprove[i].block_end;
            integration_aggregate[i].confirmation_status = getConfirmStatus(integrationsApprove[i].id);
            integration_aggregate[i].hasConfirm =ifUserConfirmed(integrationsApprove[i].id, msg.sender);
        }

        return integration_aggregate;
    }


    /// @notice Get Aggregate Info of Integration Approve Single.
    /// @dev Get Aggregate Info of Integration Approve Single.
    /// @param _id ID of Integration Approve.
    /// @return list List of Aggregation Appprove.
    /// , _id Proposal ID.
    /// , status Status.
    /// , ipfs_hash IPFS CID of integration Approve.
    /// , to_user User to transfer money, when integration approve is confirmed.
    /// , amount Amount of WEI to transfer.
    /// , groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// , group_for_vote Group for users, who can confirm.
    /// , block_start Block for Start Confirmation Process.
    /// , block_end Block for End Confirmation Process.
    /// , confirmation_status Current Status.
    /// , hasConfirm If User Confrim Approve.
    function getSingleIntegrationAggregate(uint256 _id)
    public
    view
    returns (IntegrationsApproveAggregate memory) {
        IntegrationsApproveAggregate memory  integration_aggregate = IntegrationsApproveAggregate(
            _id,
            integrationsApprove[integrationIndexMap[_id]].status,
            integrationsApprove[integrationIndexMap[_id]].ipfs_hash,
            integrationsApprove[integrationIndexMap[_id]].to_user,
            integrationsApprove[integrationIndexMap[_id]].amount,
            integrationsApprove[integrationIndexMap[_id]].groups,
            integrationsApprove[integrationIndexMap[_id]].group_for_vote,
            integrationsApprove[integrationIndexMap[_id]].block_start,
            integrationsApprove[integrationIndexMap[_id]].block_end,
            getConfirmStatus(_id),
            ifUserConfirmed(_id,msg.sender)
            );

        return integration_aggregate;
    }

    /// @notice Set Timestamp for start and end.
    /// @dev Set Timestamp for start and end.
    /// @param _id ID of Integration Approve.
    /// @param timestamp_start Timestam start vote.
    /// @param timestamp_end Timestamp stop vote.
    /// @return status Status of execution
    /// @return message Message of execution
    function setIntegrationApproveTimestamp(uint256 _id,uint256 timestamp_start, uint256 timestamp_end)
    public
    onlyAdmin
    returns (bool,string memory,Confirmation) {

        Confirmation status = getConfirmStatus(_id);

        if(timestamp_start > timestamp_end)
        {
            return (false,"Start timestamp is grather than end timestamp.",status);
        }

        if(timestamp_start < block.timestamp)
        {
            return (false,"Start timestamp is lower than current block timestamp.",status);
        }

        if(getConfirmStatus(_id) != Confirmation.Pending)
        {
            return (false,"You can only change timestamp, before vote is started.",status);
        }

        integrationsApprove[integrationIndexMap[_id]].block_start = timestamp_start;
        integrationsApprove[integrationIndexMap[_id]].block_end = timestamp_end;
        return (true,"New timestamp is set.",status);
    }

    /// @notice Get current Reference to UsersGroups Address.
    /// @dev Get current Reference to UsersGroups Address.
    /// @return address DataFeed Address.
    function getUsersGroups() 
    onlyAdmin
    public view returns (address) {
        return address(roles);
    }
        

}

// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
pragma solidity 0.8.12;
import "Initializable.sol";

/// @title RequestMembers.
/// @notice Contract stored User and groum membership.
/// @dev Contract stored User and groum membership.
contract UsersGroups is Initializable {

    /// @notice Array of static group.
    /// @dev Array of static group.
    bytes32[] private static_group = [
      
      bytes32("DAO_EXECUTE"),
      bytes32("Bank"),
      bytes32("Integration"),
      bytes32("Member"),
      bytes32("Admin")
    ];

    /// @notice Event emmited when new group is added.
    /// @dev Event emmited when new group is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupAdd(bool status, string message,bytes32 group);

    /// @notice Event emmited when new group is deleted.
    /// @dev Event emmited when new group is deleted.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupRemove(bool status, string message,bytes32 group);

    /// @notice Event emmited when group budget is calculated.
    /// @dev Event emmited when group budget is calculated.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupCalculate(bool status, string message,bytes32 group);

    /// @notice Event emmited when group timestam is set.
    /// @dev Event emmited when group timestam is set.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    /// @return timestamp Timestamp for integration to set.
    event GroupIntegrationTimestamp(bool status, string message,bytes32 group,uint256 timestamp);

    /// @notice Event emmited when new user is added.
    /// @dev Event emmited when new user is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    event UserAdd(bool status, string message,address user);

    /// @notice Event emmited when new user is added to group.
    /// @dev Event emmited when new user is added to group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    /// @return group Group Name.
    event UserToGroupAdd(bool status, string message,address user,bytes32 group);

    /// @notice Event emmited when new user is removed from group.
    /// @dev Event emmited when new user is removed from group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    /// @return group Group Name.
    event UserToGroupRemove(bool status, string message,address user,bytes32 group);

    /// @notice Event emmited when new user is deleted.
    /// @dev Event emmited when new user is deleted.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    event UserRemove(bool status, string message,address user);



    /// @notice Owner address.
    /// @dev Owner address.
    address private owner;

    /// @notice Array of groups.
    /// @dev Array of groups.
    Group[] private groups; 

    /// @notice Array of users.
    /// @dev Array of users.
    User[] private users;

    /// @notice User count.
    /// @dev User count.
    uint256 private UserCount=0;

    /// @notice Group count.
    /// @dev Group count.
    uint256 private GroupCount=0;

    /// @notice Map user address to: map group to status if added to this group.
    /// @dev Map user address to: map group to status if added to this group.
    mapping(address => mapping(bytes32 => bool)) userToGroupMap;

    /// @notice Map user address to status if exist.
    /// @dev Map user address to status if exist.
    mapping(address => bool) usersMap; 

     /// @notice Map user address to index in users array.
    /// @dev Map user address to index in users array.
    mapping(address => uint256) userIndex; 

    /// @notice Map group to status if exist.
    /// @dev Map group to status if exist.
    mapping(bytes32 => bool) groupsMap; 

    /// @notice Map group to index in group array.
    /// @dev Map group to index in group array.
    mapping(bytes32 => uint256) groupIndex; 

    /// @notice Map group to array of membership users.
    /// @dev Map group to array of membership users.
    mapping(bytes32 => address[]) groupToUserAddressMap; 

    /// @notice Structure of group.
    /// @dev Structure of group.
    /// @param group_name Group name.
    /// @param current_balance For future use.
    /// @param blocked_balance For future use.
    /// @param timestamp_created Timestamp Creation.
    /// @param timestamp_last_integration Timestamp for last integration.
    struct Group {
        bytes32 group_name;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        uint256 timestamp_last_integration;
    }

    /// @notice Structure of users.
    /// @dev Structure of users.
    /// @param userID User Address.
    /// @param current_balance For future use.
    /// @param blocked_balance  For future use.
    /// @param timestamp_status Timestamp Creation.
    struct User {
        address userID;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        bool timestamp_status;
    }

  /// @notice Contructor.
  /// @dev Contructor.
  /// @param _owner Owner Address 
  constructor (address _owner) public  {
    owner = _owner;
    addUser(owner);
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      addGroup(static_group[i]);
    }
    setUserToGroup(owner, static_group[4]);
    //addUser(owner);
    //setUserToGroup(owner, static_group[0]);
  }

  /// @notice Initializer for proxy contract migration - future release.
  /// @dev Initializer for proxy contract migration - future release.
  /// @param _owner Owner Address.
  function initialize (address _owner) initializer public {
    static_group.push(bytes32("DAO_EXECUTE"));
    static_group.push(bytes32("Bank"));
    static_group.push(bytes32("Integration"));
    static_group.push(bytes32("Member"));
    static_group.push(bytes32("Admin"));

    users.push(User(_owner,0 ,0,block.timestamp, false));
    usersMap[_owner] = true;
    userIndex[_owner] = UserCount;
    userToGroupMap[_owner][static_group[3]] = true;
    groupToUserAddressMap[static_group[3]].push(_owner);
    UserCount=UserCount+1;

    for(uint256 i=0;i<static_group.length;i++)
    {
      groups.push(Group(static_group[i],0,0,block.timestamp,0));
      groupsMap[static_group[i]] = true;
      groupIndex[static_group[i]] = GroupCount;
      GroupCount=GroupCount+1;
    }

    userToGroupMap[_owner][static_group[4]]=true;
    groupToUserAddressMap[static_group[4]].push(_owner);
    
  }

  modifier onlyAdmin()
  {
    require((owner == msg.sender || isAdmin(msg.sender)), "Restricted to admins or owner.");
    _;
  }

  modifier onlyPost()
  {
    require((isPost(msg.sender)), "Restricted to posts.");
    _;
  }

  /// @notice Check if User exist.
  /// @dev Check if User exist.
  /// @param user Account Address.
  /// @return status True/False if exist.
  function ifUserExist(address user)
  public
  view
  returns (bool)
  {
    return usersMap[user];
  }

  /// @notice Check if group exist.
  /// @dev Check if group exist.
  /// @param group Group Name.
  /// @return status True/False if exist.
  function ifGroupExist(bytes32 group)
  public
  view
  returns (bool)
  {
    return groupsMap[group];
  }

  /// @notice Check if User is in Group.
  /// @dev e Check if User is in Group.
  /// @param user Account Address.
  /// @param group Group Name.
  /// @return status True/False if exist.
  function ifUserHasGroup(address user,bytes32 group)
  internal
  view
  returns (bool)
  {
    if(!ifUserExist(user)||!ifGroupExist(group))
    {
      return false;
    }

    return userToGroupMap[user][group];
  }

  /// @notice Get data of user.
  /// @dev Get data of user.
  /// @param user Account Address.
  /// @return [balance,blocked_balance,timestamp_created,timestamp_status]
  function getUser(address user)
  public
  view
  onlyAdmin
  returns (uint256,uint256,uint256,bool)
  {
    require(ifUserExist(user),"User not exist");
    return (users[userIndex[user]].current_balance,users[userIndex[user]].blocked_balance,users[userIndex[user]].timestamp_created,users[userIndex[user]].timestamp_status);
  }

  /// @notice Get User Address by User Index.
  /// @dev Get User Address by User Index.
  /// @param _index User Index.
  /// @return [userID,balance,blocked_balance,timestamp_created,timestamp_status].
  function getUserByIndex(uint256 _index)
  public
  view
  onlyAdmin
  returns (address)
  {
    return (users[_index].userID);
  }

  /// @notice Get user Index.
  /// @dev Get user Index.
  /// @param user Account Address.
  /// @return struct_of_user User Enum.
  function getUserindex(address user)
  public
  view
  onlyAdmin
  returns (uint256)
  {
    require(ifUserExist(user),"User not exist");
    return userIndex[user];
  }

  /// @notice Get array of Struct User.
  /// @dev Get array of Struct User.
  /// @return list_of_struct_of_userGet List User Enum.
  function getUsers()
  public
  view 
  onlyAdmin
  returns (User[] memory)
  {
    return users;
  }

  /// @notice Get group members.
  /// @dev Get group members.
  /// @param group Group Name
  /// @return array_of_address Array of accounts.
  function getUsersInGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (address[] memory)
  {
    return groupToUserAddressMap[group];
  }

  /// @notice Get total number of users.
  /// @dev Get total number of users.
  /// @return count Number Of Users.
  function getUsersCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return UserCount;
  }

  /// @notice Get total number of groups.
  /// @dev Get total number of groups.
  /// @return count Number Of Groups.
  function getGroupsCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return GroupCount;
  }

  /// @notice Get All Group.
  /// @dev Get All Group.
  /// @return list_of_struct_group List of Group Enum.
  function getGroups()
  public
  view
  returns (Group[] memory)
  {
    return groups;
  }
  /// @notice Get group.
  /// @dev Get group.
  /// @param group Group Name.
  /// @return group_data  Array of group data [group_name,timestamp_created,timestamp_last_integration]
  function getGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (bytes32,uint256,uint256)
  {
    //require(ifGroupExist(group),"Group not exist");
    return (groups[groupIndex[group]].group_name,
    groups[groupIndex[group]].timestamp_created,
    groups[groupIndex[group]].timestamp_last_integration);
  }

  /// @notice Add group.
  /// @dev Add group.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function addGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifGroupExist(group)){
      emit GroupAdd(false,"Group Exist.",group);
      return false;
    }
    groups.push(Group(group,0,0,block.timestamp,0));
    groupsMap[group] = true;
    groupIndex[group] = GroupCount;
    GroupCount=GroupCount+1;
    emit GroupAdd(true,"Group added successfully.",group);
    return true;
  }

  /// @notice Remove group.
  /// @dev Remove group.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function removeGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    for(uint256 i=0;i<static_group.length;i++)
    {
      if(static_group[i] == group)
      {
        emit GroupRemove(false,"Group can't be removed.",group);
        return false;
      }
    }
    if(ifGroupExist(group))
    {
      
      for(uint256 i=0;i<users.length;i++)
      {
        if(ifUserHasGroup(users[i].userID,group))
        {
          emit GroupRemove(false,"Group has members, Please delete members from group.",group);
          return false;
        }
      }

      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        for(uint256 i=groupIndex[group];i<groups.length-1;i++)
        {
          groups[i]=groups[i+1];
          groupIndex[groups[i+1].group_name]=i;
        }
        groups.pop();
      }
        delete groupIndex[group];
        delete groupsMap[group];
        GroupCount=GroupCount-1;
        emit GroupRemove(true,"group removed successfully.",group);
        return true;
    }
    else
    {
      emit GroupRemove(false,"Group Not Exist.",group);
      return false;
    }
  }
  /// @notice Set last Integration Timestamp.
  /// @dev Set last Integration Timestamp.
  /// @param group Group Name.
  /// @param timestamp_last_integration Integration Timestamp.
  /// @return status True/False - status of excution.
  function setIntegrationTimestamp(bytes32 group,uint256 timestamp_last_integration)
  public
  onlyPost
  returns (bool){
    if(!ifGroupExist(group))
    {
      emit GroupIntegrationTimestamp(false,"Group not exist.",group, timestamp_last_integration);
      return false;
    }
    else
    {
      if(groups[groupIndex[group]].timestamp_last_integration < timestamp_last_integration){
        groups[groupIndex[group]].timestamp_last_integration = timestamp_last_integration;
        emit GroupIntegrationTimestamp(true,"Timestamp is set.",group, timestamp_last_integration);
        return true;
      }
      else{
        emit GroupIntegrationTimestamp(true,"Timestamp is not set, because is less than current timestamp for this group.",group, timestamp_last_integration);
        return true;
      }
    }
  }
  /// @notice Add User.
  /// @dev Add User.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function addUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user)){
      emit UserAdd(false,"User Exist.",user);
      return false;
    }
    
    users.push(User(user,0,0,block.timestamp, false));
    usersMap[user] = true;
    userIndex[user] = UserCount;
    userToGroupMap[user][static_group[3]] = true;
    groupToUserAddressMap[static_group[3]].push(user);
    UserCount=UserCount+1;
    emit UserAdd(true,"User added successfully.",user);
    return true;
  }
  /// @notice Add Smart Contract to Users, beacuse they need permissions based on groups.
  /// @dev Add Smart Contract to Users, beacuse they need permissions based on groups.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function addSmartContract(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user)){
      emit UserAdd(false,"User Exist.",user);
      return false;
    }
    
    users.push(User(user,0,0,block.timestamp, false));
    usersMap[user] = true;
    userIndex[user] = UserCount;
    UserCount=UserCount+1;
    emit UserAdd(true,"User added successfully.",user);
    return true;
  }

  /// @notice Remove group.
  /// @dev Remove group.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function removeUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user))
    {
      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        uint256 user_index = userIndex[user];
        for(uint256 i=user_index;i<users.length-1;i++)
        {
          users[i]=users[i+1];
          userIndex[users[i+1].userID]=i;
        }
        users.pop();
      }
        delete userIndex[user];
        delete usersMap[user];
        for(uint i=0;i<groups.length;i++){
          if(ifUserHasGroup(user,groups[i].group_name))
          {
            delete userToGroupMap[user][groups[i].group_name];
          }
        }
        
        UserCount=UserCount-1;
        emit UserRemove(true,"User removed.",user);
        return true;
    }
    else
    {
      emit UserRemove(false,"User Not Exist.",user);
      return false;
    }
  }

  /// @notice Add user to group.
  /// @dev Add user to group.
  /// @param user User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function setUserToGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupAdd(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupAdd(false,"Group not Exist.",user,group);
      return false;
    }

    if(ifUserHasGroup(user,group))
    {
      emit UserToGroupAdd(false,"User is in group.",user,group);
      return false;
    }

    userToGroupMap[user][group]=true;
    groupToUserAddressMap[group].push(user);
    emit UserToGroupAdd(true,"User added to group successfully.",user,group);
    return true;
  }

  /// @notice Remove user from group.
  /// @dev Remove user from group.
  /// @param user User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function removeUserFromGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupRemove(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupRemove(false,"Group not Exist.",user,group);
      return false;
    }

    if(!ifUserHasGroup(user,group)){
      emit UserToGroupRemove(false,"User is not in group.",user,group);
      return false;
    }

    
    uint256 index = 0;
    uint256 long = groupToUserAddressMap[group].length-1;
    address[] memory assets = new address[](groupToUserAddressMap[group].length-1);

    for(uint i=0;i<groupToUserAddressMap[group].length;i++)
    {
      if(groupToUserAddressMap[group][i] == user){
        for(uint ii=i; ii<long;ii++){
            emit UserToGroupRemove(true,"Finded user.",groupToUserAddressMap[group][ii] ,group);
        }
        
        //groupToUserAddressMap[group].pop();
      }
      else
      {
        assets[index]=groupToUserAddressMap[group][i];
        index++;
      }
      
    }
    userToGroupMap[user][group]=false;
    groupToUserAddressMap[group] = assets;
    emit UserToGroupRemove(true,"User removed group successfully.",user,group);
    return true;
  }

  /// @notice Check if user is admin.
  /// @dev Check if user is admin.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isAdmin(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[4].group_name);
  }

  /// @notice Check if user is in group Integration.
  /// @dev Check if user is in group Integration.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isIntegration(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[2].group_name);
  }

  /// @notice Check if user is in group who can add Blog Post.
  /// @dev Check if user is in group who can add Blog Post.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isPost(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[0].group_name);
  }

  /// @notice Check if user is in group who can transfer from Bank.
  /// @dev Check if user is in group who can transfer from Bank.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isBank(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[1].group_name);
  }

  /// @notice Check if user is in group Member.
  /// @dev Check if user is in group Member.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isMember(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[3].group_name);
  }

  /// @notice Check if user is in this group.
  /// @dev Check if user is in this group.
  /// @param account User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function isRole(address account,bytes32 group)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,group);
  }

  /// @notice Calculate, if group can add Integration.
  /// @dev Calculate, if group can add Integration.
  /// @param group User Address.
  /// @param future_integration_timestamp Future Integration timestamp.
  /// @param integration_budget Budget needed for integration.
  /// @return status True/False - status of excution
  function groupCalculate(bytes32 group,uint256 future_integration_timestamp, uint256 integration_budget)
  public
  onlyPost
  returns (bool)
  {
    if(!ifGroupExist(group)){
      emit GroupCalculate(false,"Group not Exist.",group);
      return false;
    }
    //if date was in past
    if(future_integration_timestamp < block.timestamp)
    {
      //uint256 diff_time = future_integration_timestamp - block.timestamp;
      emit GroupCalculate(false,"Integration timestamp is wrong.",group);
      //emit GroupCalculateBlock(false,"Timestamp block.",block.timestamp);
      //emit GroupCalculateBlock(false,"Timestamp integration.",future_integration_timestamp);
      //emit GroupCalculateBlock(false,"Timestamp difference.",diff_time);
      return false;
    }

    //if less than 60days
    uint diff = (future_integration_timestamp - groups[groupIndex[group]].timestamp_last_integration) / 60 / 60 / 24;
    //emit GroupCalculateBlock(false,"Timestamp difference day.",diff);
    if(diff < 60){
      emit GroupCalculate(false,"Beetween integrations is less than 60days.",group);
      return false;
    }

    //if budget is to hight
    if(integration_budget > groupToUserAddressMap[group].length * 25)
    {
      emit GroupCalculate(false,"Budget is too hight.",group);
      return false;
    }


    emit GroupCalculate(true,"Group can organize integration.",group);
    return true;
  }






}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.12;

import "AggregatorV3Interface.sol";
import "UsersGroups.sol";
import "Initializable.sol";

/// @title Bank.
/// @notice Contract, who store ether and transfer it to winner.
/// @dev
contract Bank is Initializable{
    /// @notice address UserRoles Contract.
    /// @dev address UserRoles Contract.
    UsersGroups private roles;
    
    /// @notice address Bank Contract Owner.
    /// @dev address Bank Contract Owner.
    address payable private owner;

    uint private contractBalance;//contract value 
    uint private ownerBalance;
    uint private balanceTo;

    /// @notice Event emited, when transfer to bank
    /// @dev Event emited, when transfer to bank
    /// @return address Address transfer from.
    /// @return amount Amount transfer.
    event Received(address, uint);

    /// @notice Event emited, when transfer from bank
    /// @dev Event emited, when transfer from bank
    /// @return address Address transfer to.
    /// @return amount Amount transfer
    event Send(address, uint);

    /// @notice Aggregator to calculate current price.
    /// @dev Aggregator to calculate current price.
    AggregatorV3Interface internal priceFeed;

    /// @notice Address for Aggregator to calculate current price.
    /// @dev Address for Aggregator to calculate current price.
    address addressDataFeed;


    /// @notice constructor Bank Contract.
    /// @dev constructor Bank Contract.
    /// @param roleContract - address of UserRoles Contract.
    /// @param dataFeed - address of AggregatorV3Interface Contract.
    constructor (address roleContract, address dataFeed)  {
        owner=payable(msg.sender);   
        roles = UsersGroups(roleContract);
        priceFeed = AggregatorV3Interface(dataFeed);
        addressDataFeed = dataFeed;

    }

    /// @notice Initialize contrace Bank Contract by Proxy.
    /// @dev Initialize contrace Bank Contract by Proxy.
    /// @param roleContract - address of UserRoles Contract.
    /// @param dataFeed - address of AggregatorV3Interface Contract.
    function initialize (address roleContract, address dataFeed) initializer public {
        owner=payable(msg.sender);   
        roles = UsersGroups(roleContract);
        priceFeed = AggregatorV3Interface(dataFeed);
        addressDataFeed = dataFeed;
    }
    
    modifier onlyBank()
    {
        require(roles.isBank(msg.sender), "Restricted to bank.");
        _;
    }

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    /// @notice Transfer ether from bank to another account.
    /// @dev Transfer from bank to another account.
    /// @param _to - account for transfer in 0.01, its mean 1 is 0.01, if you want transfer 10, input is 100*10=1000,etc.
    /// @param _value - amount for transfer in 0.01, its mean 1 is 0.01, if you want transfer 10, input is 100*10=1000,etc.
    function internalTransfer(address payable _to,uint _value)
    public
    payable
    onlyBank
    {
        uint denominator = uint(getLatestPrice()); 
        uint256 ethInUsdAmount = _value * 1000000000000000000000/denominator * 100000/100; 
        emit Send(_to, ethInUsdAmount);
        (bool sent,)=_to.call{value: ethInUsdAmount}("");
        ownerBalance=owner.balance;
        balanceTo=_to.balance;
        contractBalance=address(this).balance;
        require(sent,"failed to send");
    }
    /// @notice For receive money for another account.
    /// @dev For receive money for another account.
    receive()
    external
    payable
    {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Get Bank Balance.
    /// @dev Get Bank Balance.
    /// @return balance Bank balance.
    function getCurrentStatus()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

    /// @notice Get calculated price.
    /// @dev Get calculated price.
    /// @return price Price from V3Aggregator.
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice Get dataFeed Address.
    /// @dev Get dataFeed Address.
    /// @return address DataFeed Address.
    function getDataFeedAddress() 
    public view returns (address) {
        return addressDataFeed;
    }

    /// @notice Get current Reference to UsersGroups Address.
    /// @dev Get current Reference to UsersGroups Address.
    /// @return address DataFeed Address.
    function getUsersGroups() 
    onlyAdmin
    public view returns (address) {
        return address(roles);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.8.2;


import "GovernorUpgradeable.sol";
import "GovernorSettingsUpgradeable.sol";
import "GovernorCountingSimpleUpgradeable.sol";
import "GovernorVotesUpgradeable.sol";
import "GovernorVotesQuorumFractionUpgradeable.sol";
import "GovernorTimelockControlUpgradeable.sol";
import "ERC20VotesUpgradeable.sol";
import "Initializable.sol";

import "UsersGroups.sol";
import "GovernorContractProposal.sol";


/// @title GovernorContract
/// @notice GovernorContract implementation from openzeppelin
/// @dev GovernorContract implementation from openzeppelin
contract GovernorContract is
    Initializable, 
    GovernorUpgradeable, 
    GovernorSettingsUpgradeable, 
    GovernorCountingSimpleUpgradeable, 
    GovernorVotesUpgradeable, 
    GovernorVotesQuorumFractionUpgradeable, 
    GovernorTimelockControlUpgradeable,
    GovernorContractProposal
{
    /// @notice Delay before voting shoud start.
    /// @dev Delay before voting shoud start.
    uint256 public s_votingDelay;

    /// @notice Voting period.
    /// @dev Voting period.
    uint256 public s_votingPeriod;

    /// @notice Reference to UsersGroups contract.
    /// @dev Reference to UsersGroups contract.
    UsersGroups roles;


    /// @notice Proposal list.
    /// @dev Proposal list.
    Proposal[] public proposals;

    /// @notice Mapping proposalID to status if exist.
    /// @dev Mapping proposalID to status if exist.
    mapping(uint256 => bool) proposalsMap;

    /// @notice Mapping proposal ID to index in array of Proposals.
    /// @dev Mapping proposal ID to index in array of Proposals.
    mapping(uint256 => uint256) proposalsIndexMap;

    /// @notice Total number of proposals.
    /// @dev Total number of proposals.
    uint256 numberOfProposals = 0;


    /// @notice Event emmited when proposal is added.
    /// @dev Event emmited when proposal is added.
    /// @return status True/False - status of excution
    /// @return proposalID Proposal ID
    /// @return message Information with Error or Successfull execution.
    event ProposalAdd(bool status, uint256 proposalID, string message);

    /// @notice Event emmited when proposal is updated.
    /// @dev Event emmited when proposal is updated.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event ProposalUpdated(bool status, uint256 proposalID, string message);

    /// @notice Event emmited when user is voted.
    /// @dev Event emmited when user is voted.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event GCVote(bool status,string message, address account);

    /// @notice Event emmited when proposal is added.
    /// @dev Event emmited when proposal is added.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event GCPropose(bool status,string message, address account);


    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins GovernanceContract.");
        _;
    }
    /// @notice Constructor.
    /// @dev Constructor.
    constructor() {
        _disableInitializers();
    }
    /// @notice Initializer.
    /// @dev Initializer.
    /// @param _quorumPercentage Quorum number beetween 1-100;
    /// @param _votingPeriod Number of block for delay to start voting.
    /// @param _votingDelay Number of block for voting.
    /// @param roleContract Refernece to UsersRoles Contract.
    function initialize(
        IVotesUpgradeable _token,
        TimelockControllerUpgradeable _timelock,
        uint256 _quorumPercentage,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        address roleContract)
        initializer public
    {
        __Governor_init("GovernorContract");
        __GovernorSettings_init(_votingDelay, _votingPeriod, 0);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(_quorumPercentage);
        __GovernorTimelockControl_init(_timelock);
        s_votingDelay = _votingDelay;
        s_votingPeriod = _votingPeriod;
        roles = UsersGroups(roleContract);
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    /// @notice Get voting delay.
    /// @dev Get voting delay.
    /// @return s_votingDelay Voting delay.
    function votingDelay() public view 
    override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256) {
        return s_votingDelay; // 1 = 1 block
    }

    /// @notice Get voting period.
    /// @dev Get voting period.
    /// @return s_votingPeriod Voting period.
    function votingPeriod() public view 
    override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256) {
        return s_votingPeriod; // 45818 = 1 week
    }

    /// @notice Calculate All Tokens at start of voting.
    /// @dev Calculate All Tokens at start of voting.
    /// @return status Amount of tokens per group.   
    function TokensPerGroup(uint256 proposalId) public view  
    returns (uint256) {

        //uint256 blockNumber = proposalSnapshot(proposalId);
        bytes32 group = proposals[proposalsIndexMap[proposalId]].groups;
        address [] memory members = roles.getUsersInGroup(group);

        uint256 totalSupply = 0;
        for (uint8 i=0; i< members.length;i++){
            totalSupply = totalSupply + getVotes(members[i],proposalSnapshot(proposalId));
        }

        return totalSupply;

    }

    /// @notice Calculate quorum for group - sum of tokens for memebers * quorumNumerator/quorumDenumerator, when vote is starting.
    /// @dev Calculate quorum for group - sum of tokens for memebers * quorumNumerator/quorumDenumerator, when vote is starting.
    /// @return quorum Quorum per group.(0-100%)
    function quorumPerGroup(uint256 proposalId) public view  
    returns (uint256) {
        return TokensPerGroup(proposalId) * quorumNumerator() / quorumDenominator();
    }

    /// @notice Override validate quorum needed per group, it is members token, when vote is starting;
    /// @dev Override validate quorum needed per group, it is members token, when vote is starting;
    /// @return status Status of execution.
    function _quorumReached(uint256 proposalId) internal view  
    override(GovernorUpgradeable,GovernorCountingSimpleUpgradeable) 
    returns (bool) {
        (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        ) = proposalVotes(proposalId);

        return quorumPerGroup(proposalId) <= forVotes + abstainVotes;

        //return quorum(proposalSnapshot(proposalId)) <= forVotes + abstainVotes;
    }


    /// @notice Get quorum.
    /// @dev Get quorum.
    /// @param blockNumber - block number for validate quorum.
    /// @return quorum Quorum.
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    
    }

    /// @notice Get votes for account on block(number of tokens).
    /// @dev Get votes for account on block(number of tokens).
    /// @param account Account.
    /// @param blockNumber Block number for validate vote.
    /// @return number_of_tokens  Number of tokens voted in blockNumber in format: (against,for,not interested).
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable,GovernorUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @notice Get status of proposal ID.
    /// @dev Get status of proposal ID.
    /// @param proposalId Proposal ID.
    /// @return state Status of proposal.
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @notice Add proposal.
    /// @dev Add proposal.
    /// @param targets addrees for execute.
    /// @param values amount to transfer.
    /// @param calldatas encoded function with arg to execute.
    /// @param description Proposal Description.
    /// @return proposalID Proposal ID.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public 
    override(GovernorUpgradeable, IGovernorUpgradeable)
    returns (uint256) 
    {
        return super.propose(targets, values, calldatas, description);
    }
    
    /// @notice Add proposal for Integration.
    /// @dev Add proposal for Integration.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas encoded function with arg to execute.
    /// @param description Proposal Description.
    /// @param group Group for integration.
    /// @param owner Accout sended this Proposal.
    /// @param future_integration_timestamp Timestamp, when Integration will be.
    /// @param integration_budget Budget in USD for integration.
    /// @param hash_ipfs_proposal Proposal CID IPFS.
    /// @param _typ_proposal Proposal type: 0 - Blog, 1 - Integration.
    /// @return status True if Added, False if Not Added.
    function proposeIntegration(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        bytes32 group,
        address owner,
        uint256 future_integration_timestamp,
        uint256 integration_budget,
        string memory hash_ipfs_proposal,
        uint8 _typ_proposal
    )
    public
    onlyMember 
    returns (bool) {
        //uint256 proposalID = super.propose(targets, values, calldatas, description);
        for(uint i=0;i<proposals.length; i++){
            if( proposals[i].groups == group){
                //uint256 last_block = this.proposalDeadline(proposals[i].proposalID);
                if(this.proposalDeadline(proposals[i].proposalID) > block.number)
                {
                    emit ProposalAdd(false,0,"For group exist another proposal with status active pr pending.");
                    return false;
                }
                ProposalState st = state(proposals[i].proposalID);
                if(st == ProposalState.Succeeded || st == ProposalState.Queued)
                {
                    emit ProposalAdd(false,0,"For group exist another proposal with status Succeeded or Queued.");
                    return false;
                }
            }

        }
        
        uint256 proposalId = uint256(keccak256(abi.encode(targets, values, calldatas, keccak256(bytes(description)))));
        //uint256 proposalID = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        if(!proposalsMap[proposalId]){
            //bool status = roles.groupCalculate(group,future_integration_timestamp,integration_budget);
            if(roles.groupCalculate(group,future_integration_timestamp,integration_budget))
            {
                uint256 proposalID = super.propose(targets, values, calldatas, description);
                proposals.push(Proposal(proposalID, hash_ipfs_proposal,_typ_proposal,owner,group));
                proposalsMap[proposalID]=true;
                proposalsIndexMap[proposalID] = numberOfProposals;
                numberOfProposals++;
                emit ProposalAdd(true,proposalID,"Proposall added.");
                //emit ProposalAdd(true,proposalId,"Proposall added.");
                return true;
            }
            else
            {
                emit ProposalAdd(false,0,"Problem with budget.");
                return false;
            }
        }
        else
        {
            emit ProposalAdd(false,proposalId,"Proposall exist.");
            return false;
        }
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
    
    /// @notice Execute proposal.
    /// @dev Execute proposal.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas Encoded function with arg to execute.
    /// @param descriptionHash Proposal Description.
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal 
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /// @notice Cancel proposal.
    /// @dev Cancel proposal.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas encoded Function with arg to execute.
    /// @param descriptionHash Proposal Description.
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal 
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (uint256) 
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    /// @notice Vote for Proposal with Reason.
    /// @dev Vote for Proposal with Reason.
    /// @param proposalID Proposal ID.
    /// @param support Vote: 0 - agains, 1 - for, 2 - Another. 
    /// @param reason Reason For Vote.
    function castVoteWithReason(
        uint256 proposalID, 
        uint8 support, 
        string calldata reason
    )
        public override(GovernorUpgradeable,IGovernorUpgradeable)
        returns (uint256)
    {

        if(msg.sender == proposals[proposalsIndexMap[proposalID]].owner){
            emit GCVote(false, "Owner can't vote!", msg.sender);
            return 0;  
        }

        if(!roles.isRole(msg.sender, proposals[proposalsIndexMap[proposalID]].groups))
        {
            emit GCVote(false, "User don'h have permissions to vote!", msg.sender);  
            return 0;
        }

        emit GCVote(true, "User has permissions to vote!", msg.sender);
        return super.castVoteWithReason(proposalID,support,reason);
    }

    /// @notice Vote for Proposal with Reason.
    /// @dev Vote for Proposal with Reason.
    /// @param proposalID Proposal ID.
    /// @param support Vote: 0 - agains, 1 - for, 2 - Another. 
    function castVote(
        uint256 proposalID, 
        uint8 support
    )
        public override(GovernorUpgradeable,IGovernorUpgradeable)
        returns (uint256)
    {

        if(msg.sender == proposals[proposalsIndexMap[proposalID]].owner){
            emit GCVote(false, "Owner can't vote!", msg.sender);
            return 0;  
        }

        if(!roles.isRole(msg.sender, proposals[proposalsIndexMap[proposalID]].groups))
        {
            emit GCVote(false, "User don'h have permissions to vote!", msg.sender);  
            return 0;
        }

        emit GCVote(true, "User has permissions to vote!", msg.sender);
        return super.castVote(proposalID,support);
    }

    /// @notice Update Quorum.
    /// @dev Update Quorum.
    /// @param newQuorumNumerator Quorum numberator
    function updateQuorumNumerator(
        uint256 newQuorumNumerator
    )
        
        public
        override(GovernorVotesQuorumFractionUpgradeable)
    {
        return super._updateQuorumNumerator(newQuorumNumerator);
    }

    /// @notice Update Voting Delay
    /// @dev Update Voting Delay
    /// @param _votingDelay Number of Block
    function updateVotingDelay(
        uint256 _votingDelay
    )
        public
        onlyAdmin
    {
        s_votingDelay = _votingDelay;
    }

    /// @notice Update Voting Period
    /// @dev Update Voting Period
    /// @param _votingPeriod Number of Block
    function updateVotingPeriod(
        uint256 _votingPeriod
    )
        public
        onlyAdmin
    {
        s_votingPeriod = _votingPeriod;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Update IPFS CID of Proposal.
    /// @dev Update IPFS CID of Proposal.
    /// @param proposalID Proposal ID.
    /// @param _hash IPFS CID.
    /// @return status True/False - status of update.
    function updateSingleProposalHash(uint256 proposalID,string memory _hash)
    public
    onlyMember 
    returns (bool){
        if(proposalsMap[proposalID]){
            proposals[proposalsIndexMap[proposalID]].hash = _hash ;
            emit ProposalUpdated(true,proposalID,"Proposall updated.");
            return true;
        }
        else
        {
            emit ProposalUpdated(false,proposalID,"Proposall not exist.");
            return false;
        }
    }


    /// @notice Get Single Proposal Data.
    /// @dev Get Single Proposal Data.
    /// @param proposalID Proposal ID.
    /// @return proposal [hash,type,owner,groups] Get Structure of single Proposal.
    function getSingleProposal(uint256 proposalID)
    public
    view
    returns (string memory,uint8,address,bytes32) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].hash,proposals[proposalsIndexMap[proposalID]].typ, proposals[proposalsIndexMap[proposalID]].owner,proposals[proposalsIndexMap[proposalID]].groups);
    }

    /// @notice Get Single Proposal Group for vote on this proposal.
    /// @dev Get Single Proposal Group for vote on this proposal.
    /// @param proposalID Proposal ID.
    /// @return groups Groups for vote on this proposal.
    function getSingleProposalGroup(uint256 proposalID)
    public
    view
    returns (bytes32) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].groups) ;
    }

    /// @notice Get Single Proposal Owner.
    /// @dev Get Single Proposal Owner.
    /// @param proposalID Proposal ID.
    /// @return groups Owner for this proposal.
    function getSingleProposalOwner(uint256 proposalID)
    public
    view
    returns (address) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].owner) ;
    }

    /// @notice Get All Proposals.
    /// @dev Get All Proposals.
    /// @return proposals List of proposals with elements[hash,type,owner,groups].
    function getAllProposals()
    public
    view
    returns (Proposal[] memory) {
        return proposals;
    }

    /// @notice Get Proposal ID by CID.
    /// @dev Get Single Proposal Owner.
    /// @param ipfs_CID Proposal ID.
    /// @return proposalID Proposal ID.
    function getSingleProposalIdByCID(string memory ipfs_CID)
    public
    view
    returns (uint256) {
        for(uint256 i=0;i<proposals.length;i++)
        {
            if(keccak256(abi.encodePacked(proposals[i].hash)) ==  keccak256(abi.encodePacked(ipfs_CID))){
                return proposals[i].proposalID;
            }
        }
        revert("Proposal not exist for this IPFS CID.");
    }

    /// @notice Get Proposal ID by CID.
    /// @dev Get Single Proposal Owner.
    /// @param proposalID Proposal ID.
    /// @return index Proposal Index ID.
    function getProposalIndex(uint256 proposalID)
    public
    view
    returns (uint256) {
        return proposalsIndexMap[proposalID];
    }

    /// @notice Get Proposals Array length;
    /// @dev Proposals Array length;
    /// @return length Proposal Length;
    function getProposalsLength()
    public
    view
    returns (uint256) {
        return proposals.length;
    }


    /// @notice Cancel proposal.
    /// @dev Cancel proposal.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas encoded Function with arg to execute.
    /// @param descriptionHash Proposal Description.
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )  
    public
    onlyAdmin
    returns (uint256) 
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    

    

    
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/Governor.sol)

pragma solidity ^0.8.0;

import "IERC721ReceiverUpgradeable.sol";
import "IERC1155ReceiverUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "draft-EIP712Upgradeable.sol";
import "ERC165Upgradeable.sol";
import "SafeCastUpgradeable.sol";
import "DoubleEndedQueueUpgradeable.sol";
import "AddressUpgradeable.sol";
import "ContextUpgradeable.sol";
import "TimersUpgradeable.sol";
import "IGovernorUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {_getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract GovernorUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, EIP712Upgradeable, IGovernorUpgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
    using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueueUpgradeable.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    function __Governor_init(string memory name_) internal onlyInitializing {
        __EIP712_init_unchained(name_, version());
        __Governor_init_unchained(name_);
    }

    function __Governor_init_unchained(string memory name_) internal onlyInitializing {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IGovernorUpgradeable).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            interfaceId == type(IGovernorUpgradeable).interfaceId ||
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory, /* values */
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            for (uint256 i = 0; i < targets.length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256, /* proposalId */
        address[] memory, /* targets */
        uint256[] memory, /* values */
        bytes[] memory, /* calldatas */
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * @dev See {IGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, params);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = _getVotes(account, proposal.voteStart.getDeadline(), params);
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(
        address target,
        uint256 value,
        bytes calldata data
    ) external virtual onlyGovernance {
        AddressUpgradeable.functionCallWithValue(target, data, value);
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "ECDSAUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "SafeCastUpgradeable.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueueUpgradeable {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCastUpgradeable.toInt128(int256(deque._begin) + SafeCastUpgradeable.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library TimersUpgradeable {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "ERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorUpgradeable is Initializable, IERC165Upgradeable {
    function __IGovernor_init() internal onlyInitializing {
    }

    function __IGovernor_init_unchained() internal onlyInitializing {
    }
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "GovernorUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettingsUpgradeable is Initializable, GovernorUpgradeable {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    function __GovernorSettings_init(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        __GovernorSettings_init_unchained(initialVotingDelay, initialVotingPeriod, initialProposalThreshold);
    }

    function __GovernorSettings_init_unchained(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "GovernorUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimpleUpgradeable is Initializable, GovernorUpgradeable {
    function __GovernorCountingSimple_init() internal onlyInitializing {
    }

    function __GovernorCountingSimple_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "GovernorUpgradeable.sol";
import "IVotesUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 *
 * @custom:storage-size 51
 */
abstract contract GovernorVotesUpgradeable is Initializable, GovernorUpgradeable {
    IVotesUpgradeable public token;

    function __GovernorVotes_init(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        __GovernorVotes_init_unchained(tokenAddress);
    }

    function __GovernorVotes_init_unchained(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "GovernorVotesUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFractionUpgradeable is Initializable, GovernorVotesUpgradeable {
    uint256 private _quorumNumerator;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    function __GovernorVotesQuorumFraction_init(uint256 quorumNumeratorValue) internal onlyInitializing {
        __GovernorVotesQuorumFraction_init_unchained(quorumNumeratorValue);
    }

    function __GovernorVotesQuorumFraction_init_unchained(uint256 quorumNumeratorValue) internal onlyInitializing {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumerator;
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = _quorumNumerator;
        _quorumNumerator = newQuorumNumerator;

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "IGovernorTimelockUpgradeable.sol";
import "GovernorUpgradeable.sol";
import "TimelockControllerUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (and ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * WARNING: Setting up the TimelockController to have additional proposers besides the governor is very risky, as it
 * grants them powers that they must be trusted or known not to use: 1) {onlyGovernance} functions like {relay} are
 * available to them through the timelock, and 2) approved governance proposals can be blocked by them, effectively
 * executing a Denial of Service attack. This risk will be mitigated in a future release.
 *
 * _Available since v4.3._
 */
abstract contract GovernorTimelockControlUpgradeable is Initializable, IGovernorTimelockUpgradeable, GovernorUpgradeable {
    TimelockControllerUpgradeable private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    function __GovernorTimelockControl_init(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        __GovernorTimelockControl_init_unchained(timelockAddress);
    }

    function __GovernorTimelockControl_init_unchained(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, GovernorUpgradeable) returns (bool) {
        return interfaceId == type(IGovernorTimelockUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overridden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else if (_timelock.isOperationPending(queueid)) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Canceled;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overridden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overridden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    // This function can reenter through the external call to the timelock, but we assume the timelock is trusted and
    // well behaved (according to TimelockController) and this will not happen.
    // slither-disable-next-line reentrancy-no-eth
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through governance proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.
     */
    function updateTimelock(TimelockControllerUpgradeable newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockControllerUpgradeable newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "IGovernorUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelockUpgradeable is Initializable, IGovernorUpgradeable {
    function __IGovernorTimelock_init() internal onlyInitializing {
    }

    function __IGovernorTimelock_init_unchained() internal onlyInitializing {
    }
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "AccessControlUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "IERC1155ReceiverUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockControllerUpgradeable is Initializable, AccessControlUpgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`, and a list of
     * initial proposers and executors. The proposers receive both the
     * proposer and the canceller role (for backward compatibility). The
     * executors receive the executor role.
     *
     * NOTE: At construction, both the deployer and the timelock itself are
     * administrators. This helps further configuration of the timelock by the
     * deployer. After configuration is done, it is recommended that the
     * deployer renounces its admin position and relies on timelocked
     * operations to perform future maintenance.
     */
    function __TimelockController_init(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal onlyInitializing {
        __TimelockController_init_unchained(minDelay, proposers, executors);
    }

    function __TimelockController_init_unchained(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal onlyInitializing {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], payloads[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControlUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "draft-ERC20PermitUpgradeable.sol";
import "MathUpgradeable.sol";
import "IVotesUpgradeable.sol";
import "SafeCastUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20VotesUpgradeable is Initializable, IVotesUpgradeable, ERC20PermitUpgradeable {
    function __ERC20Votes_init() internal onlyInitializing {
    }

    function __ERC20Votes_init_unchained() internal onlyInitializing {
    }
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "draft-IERC20PermitUpgradeable.sol";
import "ERC20Upgradeable.sol";
import "draft-EIP712Upgradeable.sol";
import "ECDSAUpgradeable.sol";
import "CountersUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "GovernorUpgradeable.sol";
import "GovernorSettingsUpgradeable.sol";
import "GovernorCountingSimpleUpgradeable.sol";
import "GovernorVotesUpgradeable.sol";
import "GovernorVotesQuorumFractionUpgradeable.sol";
import "GovernorTimelockControlUpgradeable.sol";
import "ERC20VotesUpgradeable.sol";
import "Initializable.sol";

import "GovernorContract.sol";
/// @title GovernorContract
/// @notice GovernorContract implementation from openzeppelin
/// @dev GovernorContract implementation from openzeppelin
contract GovernorContractProposal 
{

    /// @notice Structure of single proposal.
    /// @dev Structure of single proposal.
    /// @param proposalID Proposal ID.
    /// @param hash IPFS CID of Proposal.
    /// @param typ Proposal Type: 0 - blog, 1 - integration.
    /// @param owner Accout sended Proposal.
    /// @param groups group for Vote on proposal.
    struct Proposal {
        uint256 proposalID;
        string hash;
        uint8 typ;
        address owner;
        bytes32 groups;
    }

}