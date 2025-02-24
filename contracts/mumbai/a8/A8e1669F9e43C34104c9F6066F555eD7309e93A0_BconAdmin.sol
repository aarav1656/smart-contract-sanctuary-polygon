// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import './BconContract.sol';
import './libraries/SharedStates.sol';

contract BconAdmin is Ownable {
    // TODO FUTURE: create proxy contract that holds a list of previousAddresses and currentAddress
    // for a given smartContractId
    mapping(string => address) private _bconContracts;
    string[] private _bconContractIds;

    event BconContractContractCreated(string bconContractId, address bconContractAddr);

    constructor(address customOwner) payable {
        // set BIMcontracts admin as contract owner
        transferOwnership(customOwner);
    }

    // add new bconcontract (is called by constructor of a new bconContract)
    // TODO add onlyOwner or other security checks
    function addBconContract(string memory bconContractId, address contractAddr) public {
        // TODO check if bconContractId is empty
        //require(bconContractId != '', "bconContractId invalid");

        // TODO check if bconContractId is already used

        // save mapping for bconContractId
        _bconContracts[bconContractId] = contractAddr;
        _bconContractIds.push(bconContractId);

        // create event after adding bconcontract
        emit BconContractContractCreated(bconContractId, contractAddr);
    }

    function getBconContract(string memory bconContractId) public view returns (address) {
        return _bconContracts[bconContractId];
    }

    function getBconContractIds() public view returns (string[] memory) {
        return _bconContractIds;
    }

    function getStatus(string memory bconContractId) public view returns (string memory) {
        address bconContractAddress = _bconContracts[bconContractId];

        if (
            BconContract(bconContractAddress).getStatus() == SharedStates.BconContractState.Created
        ) {
            return 'Created';
        } else if (
            BconContract(bconContractAddress).getStatus() == SharedStates.BconContractState.Signed
        ) {
            return 'Signed';
        } else if (
            BconContract(bconContractAddress).getStatus() == SharedStates.BconContractState.Finished
        ) {
            return 'Finished';
        }

        return 'Unknown';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import './factories/BillingUnitFactory.sol';
import './factories/DocumentFactory.sol';

import './interfaces/IBconContract.sol';
import './interfaces/IConfigurationHandler.sol';
import './interfaces/IBillingUnits.sol';

import 'hardhat/console.sol';

// BconContract represents a single legal contractual relation between "client" (Auftraggeber)
// and "contractor" (Auftragnehmer) with multiple BillingUnits (Abrechnungseinheiten) which consists
// of multiple BillingUnitItems (LV-Positionen)
contract BconContract is IBconContract {
    Contract bconContract;

    address public documents; // required legal documents as the base for this contract
    address public billingUnits;

    address public documentFactory;

    address public billingUnitFactory;

    address public defaultReportHandler;
    address public defaultConfirmationHandler;
    address public defaultPaymentHandler;
    address public defaultChangeHandler;
    address public configurationHandler;

    /*
     ---- Contract Events ----
    */

    event ContractInitialized(
        ContractEventPayload payload,
        string billOfQuantitiesDocument,
        string billingPlan,
        string bimModel,
        string paperContract
    );

    event ContractSigned(ContractEventPayload payload);

    event ContractDocumentsUpdated(
        ContractEventPayload payload,
        string billOfQuantitiesDocument,
        string billingPlan,
        string bimModel,
        string paperContract
    );

    event ContractNewMessage(IBillingUnits.Message message);

    /*
     ---- BillingUnit Events ----
    */

    event BillingUnitCreated(IBillingUnits.BillingUnit billingUnit, string bconContractId);

    event BillingUnitPaymentClaimed(BillingUnitEventPayload payload, uint256 paymentClaimed);

    event BillingUnitPaymentTriggered(
        BillingUnitEventPayload payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 securityDeposit
    );

    event BillingUnitSplit(BillingUnitEventPayload payload);

    /*
     ---- BillingUnitItem Events ----
    */

    event BillingUnitItemCreated(IBillingUnits.BillingUnitItem billingUnitItem);

    event BillingUnitItemReported(
        BillingUnitItemEventPayload payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    );

    event BillingUnitItemCompletionClaimed(
        BillingUnitItemEventPayload payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    );

    event BillingUnitItemConfirmed(BillingUnitItemEventPayload payload);

    event BillingUnitItemConfirmedWithIssueReduction(
        BillingUnitItemEventPayload payload,
        uint256 issueReductionAmount
    );

    event BillingUnitItemRejected(BillingUnitItemEventPayload payload);

    event BillingUnitItemPaymentTriggered(
        BillingUnitItemEventPayload payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 paymentPrice,
        uint256 securityDeposit
    );

    event BillingUnitItemPaymentConfirmed(
        BillingUnitItemEventPayload payload,
        uint256 paymentQuantity,
        uint256 paymentPrice
    );

    // Rectification
    event RectificationWorkReported(BillingUnitItemEventPayload payload);

    event RectificationWorkRejected(BillingUnitItemEventPayload payload);

    event RectificationWorkConfirmed(BillingUnitItemEventPayload payload);

    // Change Management (contract amandments)
    event BillingUnitItemChangedAddAmandment(IBillingUnits.BillingUnitItemInit billingUnitItem);

    event BillingUnitItemChangedReplaceAmandment(IBillingUnits.BillingUnitItem billingUnitItem);

    event BillingUnitItemChangedRemoveAmandment(IBillingUnits.BillingUnitItem billingUnitItem);

    /*
     ---- Modifier ----
    */
    modifier onlyClient() {
        require(msg.sender == bconContract.client);
        _;
    }

    modifier onlyContractor() {
        require(msg.sender == bconContract.contractor);
        _;
    }

    /*
     ---- Public functions ----
    */
    constructor(
        address _clientAddr,
        address _contractorAddr,
        address _billingUnitFactory,
        address _documentFactory,
        address _configurationHandler
    ) {
        bconContract.status = SharedStates.BconContractState.Created;
        bconContract.client = _clientAddr;
        bconContract.contractor = _contractorAddr;

        billingUnitFactory = _billingUnitFactory;
        documentFactory = _documentFactory;
        configurationHandler = _configurationHandler;
    }

    function initContract(
        string memory _id,
        string memory _projectId,
        address _client,
        address _contractor,
        string calldata _billOfQuantitiesDocument,
        string calldata _billingPlan,
        string calldata _bimModel,
        string memory _paperContract,
        IConfigurationHandler.ConfigurationItem[] memory _configurationItems
    ) external onlyClient {
        bconContract.id = _id;
        bconContract.projectId = _projectId;
        bconContract.client = _client;
        bconContract.contractor = _contractor;

        documents = DocumentFactory(documentFactory).createDocumentContract(
            address(this),
            _billOfQuantitiesDocument,
            _billingPlan,
            _bimModel,
            _paperContract
        );
        billingUnits = BillingUnitFactory(billingUnitFactory).createBillingUnitContract(
            _client,
            _contractor,
            address(this)
        );

        bconContract.reportConfig = IConfigurationHandler(configurationHandler).extractConfig(
            _configurationItems
        );

        defaultReportHandler = bconContract.reportConfig.reportHandler;
        defaultConfirmationHandler = bconContract.reportConfig.confirmationHandler;
        defaultPaymentHandler = bconContract.reportConfig.paymentHandler;
        defaultChangeHandler = bconContract.reportConfig.changeHandler;

        emit ContractInitialized(
            ContractEventPayload(bconContract, block.timestamp),
            _billOfQuantitiesDocument,
            _billingPlan,
            _bimModel,
            _paperContract
        );
    }

    // confirmation method to be called by the contractor
    function signContract() external onlyContractor {
        // can only be called by the contractor
        // can only be called after contract was created
        require(bconContract.status == SharedStates.BconContractState.Created);

        // update status
        bconContract.status = SharedStates.BconContractState.Signed;

        emit ContractSigned(ContractEventPayload(bconContract, block.timestamp));
    }

    /*
        Entry Points for Handler Interaction
    */

    function reportProgress(IBillingUnits.Message[] memory _messages) external {
        require(msg.sender == bconContract.contractor, 'sender must be contractor');

        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.reportHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.reportHandler);
    }

    function confirmProgress(IBillingUnits.Message[] memory _messages) external {
        require(msg.sender == bconContract.client, 'sender must be client');

        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.confirmationHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.confirmationHandler);
    }

    function requestChange(IChangeHandler.ChangeRequestInit memory _request) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    function requestDocumentChange(IChangeHandler.ChangeRequestInit memory _request) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    function requestConfigChange(IChangeHandler.ChangeRequestInit memory _request) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    function approveChange(string calldata _changeRequestId) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    function approveDocumentChange(string calldata _changeRequestId) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    function approveConfigChange(string calldata _changeRequestId) external {
        console.log(
            '[BconContract] addresses of this, billingUnits, handler',
            address(this),
            billingUnits,
            bconContract.reportConfig.changeHandler
        );
        console.logBytes(msg.data);

        forwardCallToHandler(bconContract.reportConfig.changeHandler);
    }

    /*
        Event Callbacks
    */

    function throwDocumentsUpdated() public override {
        require(msg.sender == documents, 'sender must be documents contract');

        (
            string memory billOfQuantitiesDocument,
            string memory billingPlan,
            string memory bimModel,
            string memory paperContract
        ) = Documents(documents).getDocuments();

        emit ContractDocumentsUpdated(
            ContractEventPayload(bconContract, block.timestamp),
            billOfQuantitiesDocument,
            billingPlan,
            bimModel,
            paperContract
        );
    }

    function throwNewMessage(IBillingUnits.Message memory message) public override {
        // TODO: require

        emit ContractNewMessage(message);
    }

    function throwBillingUnitCreated(IBillingUnits.BillingUnit memory billingUnit) public override {
        require(msg.sender == billingUnits, 'sender must be billingUnits');

        emit BillingUnitCreated(billingUnit, bconContract.id);
    }

    function throwBillingUnitPaymentClaimed(
        BillingUnitEventPayload memory payload,
        uint256 paymentClaimed
    ) public override {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation handler'
        );

        emit BillingUnitPaymentClaimed(payload, paymentClaimed);
    }

    function throwBillingUnitPaymentTriggered(
        BillingUnitEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 securityDeposit
    ) public override {
        require(
            msg.sender == defaultPaymentHandler || msg.sender == billingUnits,
            'sender must be payment handler'
        );

        emit BillingUnitPaymentTriggered(
            payload,
            paymentTriggerTimestamp,
            paymentQuantity,
            securityDeposit
        );
    }

    function throwBillingUnitSplit(BillingUnitEventPayload memory payload) public override {
        require(msg.sender == billingUnits, 'sender must be billingUnits');

        emit BillingUnitSplit(payload);
    }

    function throwBillingUnitItemCreated(IBillingUnits.BillingUnitItem memory billingUnitItem)
        public
        override
    {
        require(msg.sender == billingUnits, 'sender must be billingUnits');

        emit BillingUnitItemCreated(billingUnitItem);
    }

    function throwBillingUnitItemReported(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public override {
        require(
            msg.sender == defaultReportHandler || msg.sender == billingUnits,
            'sender must be reportHandler'
        );

        emit BillingUnitItemReported(payload, completionQuantity, completionPrice, completionRate);
    }

    function throwBillingUnitItemCompleted(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public override {
        require(
            msg.sender == defaultReportHandler || msg.sender == billingUnits,
            'sender must be reportHandler'
        );

        emit BillingUnitItemCompletionClaimed(
            payload,
            completionQuantity,
            completionPrice,
            completionRate
        );
    }

    function throwBillingUnitItemConfirmed(BillingUnitItemEventPayload memory payload)
        public
        override
    {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit BillingUnitItemConfirmed(payload);
    }

    function throwBillingUnitItemConfirmedWithIssueReductionAmount(
        BillingUnitItemEventPayload memory payload,
        uint256 issueReductionAmount
    ) public override {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit BillingUnitItemConfirmedWithIssueReduction(payload, issueReductionAmount);
    }

    function throwBillingUnitItemRejected(BillingUnitItemEventPayload memory payload)
        public
        override
    {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit BillingUnitItemRejected(payload);
    }

    function throwBillingUnitItemPaymentTriggered(
        BillingUnitItemEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 paymentPrice,
        uint256 securityDeposit
    ) public override {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation handler'
        );

        emit BillingUnitItemPaymentTriggered(
            payload,
            paymentTriggerTimestamp,
            paymentQuantity,
            paymentPrice,
            securityDeposit
        );
    }

    function throwRectificationWorkReported(BillingUnitItemEventPayload memory payload)
        public
        override
    {
        require(
            msg.sender == defaultReportHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit RectificationWorkReported(payload);
    }

    function throwRectificationWorkRejected(BillingUnitItemEventPayload memory payload)
        public
        override
    {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit RectificationWorkRejected(payload);
    }

    function throwRectificationWorkConfirmed(BillingUnitItemEventPayload memory payload)
        public
        override
    {
        require(
            msg.sender == defaultConfirmationHandler || msg.sender == billingUnits,
            'sender must be confirmation Handler'
        );

        emit RectificationWorkConfirmed(payload);
    }

    function throwBillingUnitItemChangedAddAmandment(
        IBillingUnits.BillingUnitItemInit memory billingUnitItem
    ) public override {
        require(msg.sender == billingUnits, 'sender must be changeHandler');

        emit BillingUnitItemChangedAddAmandment(billingUnitItem);
    }

    function throwBillingUnitItemChangedReplaceAmandment(
        IBillingUnits.BillingUnitItem memory billingUnitItem
    ) public override {
        require(msg.sender == billingUnits, 'sender must be changeHandler');

        emit BillingUnitItemChangedReplaceAmandment(billingUnitItem);
    }

    function throwBillingUnitItemChangedRemoveAmandment(
        IBillingUnits.BillingUnitItem memory billingUnitItem
    ) public override {
        require(msg.sender == billingUnits, 'sender must be changeHandler');

        emit BillingUnitItemChangedRemoveAmandment(billingUnitItem);
    }

    /*
     ---- View functions ----
    */

    function getId() public view override returns (string memory) {
        return bconContract.id;
    }

    function getProjectId() public view override returns (string memory) {
        return bconContract.projectId;
    }

    function getStatus() external view override returns (SharedStates.BconContractState) {
        return bconContract.status;
    }

    function getReportConfig()
        public
        view
        override
        returns (IConfigurationHandler.ReportConfig memory config)
    {
        config = bconContract.reportConfig;
        config.bconContract = address(this);
        config.billingUnits = billingUnits;
        config.client = bconContract.client;
        config.contractor = bconContract.contractor;
    }

    function getClient() public view override returns (address) {
        return bconContract.client;
    }

    function getContractor() public view override returns (address) {
        return bconContract.contractor;
    }

    function getHandler() public view override returns (address[4] memory) {
        // explicit size specification required for compilation;
        // in case of changes modify: IBconContract + BillingUnits(onlyHandler modifier)
        address[4] memory handlerList = [
            defaultReportHandler,
            defaultConfirmationHandler,
            defaultPaymentHandler,
            defaultChangeHandler
        ];
        return handlerList;
    }

    function getConfigHandler() public view override returns (address) {
        return configurationHandler;
    }

    function getDocuments() public view override returns (address) {
        return documents;
    }

    /*
     ---- Internal functions ----
    */

    function forwardCallToHandler(address _handler) internal {
        address _billingUnits = billingUnits;

        assembly {
            // add handler address to calldata
            // call of fallback => (targetCalldata,targetAddress)

            // copy calldata to memory
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize())

            // calc storage position after calldata
            let size := add(free_ptr, calldatasize())

            // add handler address after calldata
            mstore(size, _handler)

            // calc storage position after handler
            // 32 = size of address
            size := add(calldatasize(), 32)

            // execute function call to billingUnits
            let result := call(
                gas(), // allocate remaining gas
                _billingUnits, // send call to billingUnits contract
                0, // no value
                free_ptr, // storage start position of input
                size, // size of input data (calldata + handler)
                0, //output position in storage
                0
            ) // output length

            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// this contract is needed to be able to interpret state between different contract types,
// which is needed for having dependant state machines
library SharedStates {
    // Level: BconAdmin > BconContract
    // TODO update
    enum BconContractState {
        Created,
        Signed,
        Finished
    }

    // Level: BconAdmin > BconContract > BillingUnits
    // == transient, i.e., derived state based on all contained BillingUnitItems
    // TODO update
    enum BillingUnitState {
        Open,
        PartiallyCompleted,
        Completed,
        Rectification,
        Paid,
        Replaced,
        Removed
    }

    // Level: BconAdmin > BconContract > BillingUnits > BillingUnitItems
    // == actively changed based on progress reporting, progress confirmation and payment handling
    // TODO update
    enum BillingUnitItemState {
        Open,
        CompletionStarted,
        CompletionReady,
        CompletionClaimed,
        RectificationProcess,
        CompletionConfirmed,
        CompletionPartiallyConfirmed,
        FPApproved,
        FPClaimed,
        PPApproved,
        PPClaimed,
        PaymentConfirmed,
        DiscountConfirmed,
        Cancelled,
        CancelledWithIssue,
        Replaced,
        Removed
    }

    enum MessageType {
        Notice,
        ReportDone,
        CompletionClaimed,
        ReportRejected,
        ConfirmationOkay,
        ConfirmationNotOkay,
        Issue,
        PaymentRequest,
        PaymentCancelled,
        PaymentConfirmation
    }

    enum Origin {
        Contract, // Ursprungsvertrag
        Issue, // Mängel
        Addition //Nachtrag
    }

    enum ChangeType {
        Add,
        Replace,
        Remove
    }

    enum ChangeElement {
        BillingUnit,
        BillingUnitItem,
        BillOfQuantities,
        BillingPlan,
        BimModel,
        PaperContract,
        BillingUnitConfig,
        ContractConfig
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import '../BillingUnits.sol';

contract BillingUnitFactory {
    function createBillingUnitContract(
        address _client,
        address _contractor,
        address _bconContract
    ) public returns (address) {
        BillingUnits newBillingUnit = new BillingUnits(_client, _contractor, _bconContract);
        return address(newBillingUnit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import '../Documents.sol';

contract DocumentFactory {
    function createDocumentContract(
        address _bconContract,
        string calldata _billOfQuantitiesDocument,
        string calldata _billingPlan,
        string calldata _bimModel,
        string calldata _paperContract
    ) public returns (address) {
        Documents newDocument = new Documents(
            _bconContract,
            _billOfQuantitiesDocument,
            _billingPlan,
            _bimModel,
            _paperContract
        );
        return address(newDocument);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import '../libraries/SharedStates.sol';
import './IConfigurationHandler.sol';
import './IBillingUnits.sol';

abstract contract IBconContract {
    struct Contract {
        string id; // ID of the bconContract
        string projectId; // project ID for the bconContract
        address client; // Client of the bconContract, also called 'Auftraggeber'
        address contractor; // Contractor of the bconContract, also called 'Auftragnehmer'/'Generalunternehmer'
        // global configuration items for the whole contract
        IConfigurationHandler.ConfigurationItem[] configurationItems;
        SharedStates.BconContractState status; // status of bconContract
        IConfigurationHandler.ReportConfig reportConfig;
        IConfigurationHandler.ConfirmConfig confirmConfig;
    }

    struct ContractEventPayload {
        Contract bconContract;
        uint256 timestamp;
    }

    struct BillingUnitEventPayload {
        IBillingUnits.BillingUnit billingUnit;
        uint256 timestamp;
        address sender;
        SharedStates.MessageType reportType;
    }

    struct BillingUnitItemEventPayload {
        IBillingUnits.BillingUnitItem billingUnitItem;
        uint256 timestamp;
        string reportId;
        address sender;
        SharedStates.MessageType reportType;
        string[] fileIds;
    }

    // emit events
    function throwDocumentsUpdated() public virtual;

    function throwNewMessage(IBillingUnits.Message memory payload) public virtual;

    function throwBillingUnitCreated(IBillingUnits.BillingUnit memory billingUnit) public virtual;

    function throwBillingUnitPaymentTriggered(
        BillingUnitEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 securityDeposit
    ) public virtual;

    function throwBillingUnitPaymentClaimed(
        BillingUnitEventPayload memory payload,
        uint256 paymentClaimed
    ) public virtual;

    function throwBillingUnitSplit(BillingUnitEventPayload memory payload) public virtual;

    function throwBillingUnitItemCreated(IBillingUnits.BillingUnitItem memory billingUnitItem)
        public
        virtual;

    function throwBillingUnitItemReported(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public virtual;

    function throwBillingUnitItemCompleted(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public virtual;

    function throwBillingUnitItemConfirmed(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwBillingUnitItemConfirmedWithIssueReductionAmount(
        BillingUnitItemEventPayload memory payload,
        uint256 issueReductionAmount
    ) public virtual;

    function throwBillingUnitItemRejected(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwBillingUnitItemPaymentTriggered(
        BillingUnitItemEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 paymentPrice,
        uint256 securityDeposit
    ) public virtual;

    function throwRectificationWorkReported(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwRectificationWorkRejected(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwRectificationWorkConfirmed(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwBillingUnitItemChangedAddAmandment(
        IBillingUnits.BillingUnitItemInit memory billingUnitItem
    ) public virtual;

    function throwBillingUnitItemChangedReplaceAmandment(
        IBillingUnits.BillingUnitItem memory billingUnitItem
    ) public virtual;

    function throwBillingUnitItemChangedRemoveAmandment(
        IBillingUnits.BillingUnitItem memory billingUnitItem
    ) public virtual;

    // view functions
    function getId() public view virtual returns (string memory);

    function getProjectId() public view virtual returns (string memory);

    function getStatus() external view virtual returns (SharedStates.BconContractState);

    function getReportConfig()
        public
        view
        virtual
        returns (IConfigurationHandler.ReportConfig memory);

    function getClient() public view virtual returns (address);

    function getContractor() public view virtual returns (address);

    function getHandler() public view virtual returns (address[4] memory);

    function getConfigHandler() public view virtual returns (address);

    function getDocuments() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

abstract contract IConfigurationHandler {
    struct ConfigurationItem {
        string configType;
        string configValue;
    }

    struct ReportConfig {
        // Stammdaten
        address bconContract;
        address billingUnits;
        address client;
        address contractor;
        // Konfiguration
        uint256 minStageOfCompletion;
        bool partialPayment;
        uint256 paymentInterval;
        uint256 securityDeposit;
        uint256 maxNumberOfRectifications;
        // Handler basierend auf Konfiguration
        address reportHandler;
        address confirmationHandler;
        address paymentHandler;
        address changeHandler;
    }

    struct ConfirmConfig {
        uint256 minStageOfCompletion;
        bool partialPayment;
    }

    function extractConfig(ConfigurationItem[] memory _configItems)
        public
        virtual
        returns (ReportConfig memory reportConfig);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import '../libraries/SharedStates.sol';
import '../interfaces/IConfigurationHandler.sol';

abstract contract IBillingUnits {
    struct Message {
        string id;
        string billingUnitItemId;
        string relatedMessageId;
        SharedStates.MessageType msgType;
        address sender; // who is sending the message?
        uint256 timestamp;
        // reportDone / confirmationOkay / confirmationNotOkay / paymentRequest
        uint256 completionQuantity;
        uint256 completionPrice;
        uint256 completionRate;
        // issue
        uint256 issueReductionAmount; // "Mängeleinbehalt" which will be considered during payment handling
        string[] fileIds; // file references (e.g. for photos, notes, etc.)
    }

    struct BillingUnitItem {
        string id; // BillingUnitItemId
        string billingUnitId; // ID of parent BilligUnit
        // provided during initialization / update
        uint256 price;
        uint256 quantity;
        SharedStates.Origin origin;
        // provided during lifecycle (BillingUnitConsensusItem)
        uint256 quantityTotal; // quantityCompleted
        uint256 paymentTotal; // paid
        uint256 completionRateTotal; // completionRate
        uint256 completionRateClaimed; // claimed completionRate = reported but not yet confirmed
        uint256 outstandingReports;
        uint256 rectificationCounter;
        string[] fileIds;
        SharedStates.BillingUnitItemState state;

        // TODO
        // add addresses of customized billing unit handler (report, confirm, payment,...?)
        //ConfirmationHandler confirmationHandler;
    }

    struct BillingUnit {
        // provided by smart contract config
        string id; // BillingUnitId
        //IConfigurationHandler.ConfigurationItem[] configurationItems;
        IConfigurationHandler.ReportConfig config;
        BillingUnitItem[] items; // refers to all BillingUnitItems of this BillingUnit
        SharedStates.Origin origin;
        string issueUnitId;
        uint256 completionRateTotal; // completionRate = number of items * 100%
        uint256 paymentTotal; // paymentTotal = sum of (price * quantitiy) for each subitem
        // provided during lifecycle (BillingUnitConsensus)
        string[] fileIds;
        SharedStates.BillingUnitState state;
        uint256 completionRateClaimed; // completionRate provided during building phase
        uint256 paymentClaimed; // completionRate provided during building phase

        // action handler

        // TODO?
        // address reportHandler;
        // address confirmationHandler;
        // address rectificationHandler;
        // address paymentHandler;
    }

    struct BillingUnitInit {
        // provided by smart contract config
        string id; // BillingUnitId
        IConfigurationHandler.ConfigurationItem[] configurationItems;
        BillingUnitItemInit[] items; // refers to all BillingUnitItems of this BillingUnit
    }

    struct BillingUnitItemInit {
        string id; // BillingUnitItemId
        string billingUnitId; // ID of parent BilligUnit
        // provided during initialization / update
        uint256 price;
        uint256 quantity;
    }

    function getMessageById(string memory messageId, string memory itemId)
        public
        view
        virtual
        returns (Message memory m);

    function getMessageByIndex(uint256 index, string memory itemId)
        public
        view
        virtual
        returns (Message memory m);

    function getBillingUnit(string memory _billingUnitId)
        public
        view
        virtual
        returns (BillingUnit memory);

    function getBillingUnitItem(string memory _billingUnitItemId)
        public
        view
        virtual
        returns (BillingUnitItem memory);

    function getBillingUnitItemIdByIndex(uint256 index) public view virtual returns (string memory);

    function getBillingUnitStageOfCompletion(string memory _billingUnitId)
        public
        view
        virtual
        returns (uint256);

    function getBillingUnitItemLength() public view virtual returns (uint256);

    function getMessageLengthOfBillingUnitItem(string memory itemId)
        public
        view
        virtual
        returns (uint256);

    function splitBillingUnitWithIssue(string memory _itemId, uint256 issueReductionAmount)
        public
        virtual;

    function changeRequestAddBillingUnits(BillingUnitInit[] memory _billingUnits) public virtual;

    function changeRequestAddBillingUnitItems(BillingUnitInit[] memory _billingUnits)
        public
        virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import './libraries/SharedStates.sol';
import './interfaces/IBillingUnits.sol';
import './interfaces/IConfigurationHandler.sol';
import './interfaces/IBconContract.sol';
import './interfaces/IStorage.sol';

import 'hardhat/console.sol';

// BconContract represents a single legal contractual relation between "client" (Auftraggeber)
// and "contractor" (Auftragnehmer) with multiple BillingUnits (Abrechnungseinheiten) which consists of
// multiple BillingUnitItems (LV-Positionen)
contract BillingUnits is IBillingUnits, IStorage {
    address public client; // Client of the bconContract, also called 'Auftraggeber'
    address public contractor; // Contractor of the bconContract, also called 'Auftragnehmer'/'Generalunternehmer'
    address public bconContract; // Contractor of the bconContract, also called 'Auftragnehmer'/'Generalunternehmer'

    constructor(
        address _client,
        address _contractor,
        address _bconContract
    ) {
        client = _client;
        contractor = _contractor;
        bconContract = _bconContract;

        Metadata storage md = metadata();
        md.bconContract = _bconContract;
        md.client = _client;
        md.contractor = _contractor;
    }

    /*
     ---- Structs ----
    */

    /*struct BillingUnitInit {
        // provided by smart contract config
        string id; // BillingUnitId
        IConfigurationHandler.ConfigurationItem[] configurationItems;
        BillingUnitItemInit[] items; // refers to all BillingUnitItems of this BillingUnit
    }

    struct BillingUnitItemInit {
        string id; // BillingUnitItemId
        string billingUnitId; // ID of parent BilligUnit
        // provided during initialization / update
        uint256 price;
        uint256 quantity;
    }*/

    /*
     ---- Modifier ----
    */

    modifier onlyClient() {
        // TODO soll der client immer wieder neu abgerufen werden?

        //address _client = IBconContract(bconContract).getClient();
        require(msg.sender == client);
        _;
    }

    modifier onlyHandler() {
        // change array size in case of additional handlers!
        address[4] memory handlerList = IBconContract(bconContract).getHandler();
        bool isHandler = false;
        for (uint256 i = 0; i < handlerList.length; i++) {
            //console.log("comparing",msg.sender,handlerList[i]);
            if (handlerList[i] == msg.sender) {
                isHandler = true;
                console.log('[BillingUnits] sender is handler', msg.sender);
                break;
            }
        }
        require(
            isHandler == true || msg.sender == address(this),
            'sender is no registered handler'
        );
        _;
    }

    /*
     ---- Public functions ----
    */

    function initBillingUnits(BillingUnitInit[] memory _billingUnits) public onlyClient {
        BillingData storage bd = billingData();

        for (uint256 i = 0; i < _billingUnits.length; i++) {
            BillingUnitInit memory _billingUnit = _billingUnits[i];

            _initBillingUnit(bd, _billingUnit, SharedStates.Origin.Contract);
        }
    }

    function changeRequestAddBillingUnits(BillingUnitInit[] memory _billingUnits)
        public
        override
        onlyHandler
    {
        BillingData storage bd = billingData();

        for (uint256 i = 0; i < _billingUnits.length; i++) {
            BillingUnitInit memory _billingUnit = _billingUnits[i];

            _initBillingUnit(bd, _billingUnit, SharedStates.Origin.Addition);
        }
    }

    function changeRequestAddBillingUnitItems(BillingUnitInit[] memory _billingUnits)
        public
        override
        onlyHandler
    {
        BillingData storage bd = billingData();

        // add items to unit
        for (
            uint256 billingUnitCounter = 0;
            billingUnitCounter < _billingUnits.length;
            billingUnitCounter++
        ) {
            BillingUnitInit memory _unit = _billingUnits[billingUnitCounter];

            for (uint256 i = 0; i < _unit.items.length; i++) {
                BillingUnitItemInit memory _billingUnitItem = _unit.items[i];
                // creates billingUnitItem and does update paymentTotal of billingUnit aswell
                _initBillingUnitItem(bd, _billingUnitItem, SharedStates.Origin.Addition);
            }

            // add to billing unit completion rate
            // 1000000000 = 100%
            bd.billingUnits[_unit.id].completionRateTotal += (1000000000 * _unit.items.length);
        }
    }

    function splitBillingUnitWithIssue(string memory _itemId, uint256 issueReductionAmount)
        public
        override
        onlyHandler
    {
        BillingData storage bd = billingData();

        BillingUnitItem storage _oldItem = bd.billingUnitItems[_itemId];
        BillingUnit storage _oldUnit = bd.billingUnits[_oldItem.billingUnitId];

        string memory newItemId = string(abi.encodePacked(_oldItem.id, '-issue'));
        string memory newUnitId = string(abi.encodePacked(_oldUnit.id, '-issue'));

        BillingUnitItemInit memory _newItem = BillingUnitItemInit({
            id: newItemId,
            billingUnitId: newUnitId,
            price: issueReductionAmount,
            quantity: 1
        });
        BillingUnitInit memory _newUnit = BillingUnitInit({
            id: newUnitId,
            configurationItems: new IConfigurationHandler.ConfigurationItem[](0),
            items: new BillingUnitItemInit[](1)
        });
        _newUnit.items[0] = _newItem;

        // generate new unit + item + link them
        _initBillingUnit(bd, _newUnit, SharedStates.Origin.Issue);

        // link old unit config with new unit
        bd.billingUnits[newUnitId].config = _oldUnit.config;

        // set newUnitId to old unit
        bd.billingUnits[_oldUnit.id].issueUnitId = newUnitId;
    }

    /*
     ---- View functions ----
    */

    /*function getBillingUnitItem(string memory _billingUnitItemId)
        public override view returns(string memory,string memory,string memory,uint256,uint256,uint256,
                                     uint256,uint256,uint256,uint256,SharedStates.BillingUnitItemState){
        BillingUnitItem memory item = billingUnitItems[_billingUnitItemId];       
        return (_billingUnitItemId, item.billingUnitId, contractId, item.price, item.quantity, item.quantityTotal,
                item.completionRateTotal, item.completionRateClaimed,
                item.outstandingReports, item.paymentTotal, item.state);
    }*/

    // TODO name return values for better output on Etherscan
    // ---- BillingUnit ----
    function getBillingUnit(string memory _billingUnitId)
        public
        view
        override
        returns (BillingUnit memory)
    {
        BillingData storage bd = billingData();
        return bd.billingUnits[_billingUnitId];
    }

    function getBillingUnitStageOfCompletion(string memory _billingUnitId)
        public
        view
        override
        returns (uint256 completionStage)
    {
        BillingData storage bd = billingData();
        BillingUnit memory unit = bd.billingUnits[_billingUnitId];

        completionStage = (unit.completionRateClaimed * 100) / unit.completionRateTotal;
    }

    function getBillingUnitState(string memory _billingUnitId)
        public
        view
        returns (SharedStates.BillingUnitState unitState)
    {
        BillingData storage bd = billingData();
        BillingUnit memory unit = bd.billingUnits[_billingUnitId];
        uint256 confirmedCounter = unit.items.length;
        uint256 replacedCounter = unit.items.length;
        uint256 removedCounter = unit.items.length;

        for (uint256 i = 0; i < unit.items.length; i++) {
            BillingUnitItem memory item = unit.items[i];

            // mind. 1 Item ist im issue process
            if (item.state == SharedStates.BillingUnitItemState.RectificationProcess) {
                unitState = SharedStates.BillingUnitState.Rectification;
            }
            // mind. 1 Item ist noch nicht gestartet
            if (item.state == SharedStates.BillingUnitItemState.Open) {
                unitState = SharedStates.BillingUnitState.Open;
            }

            // alle items completion confirmed => alle items müssen vom AG abgenommen sein
            if (item.state == SharedStates.BillingUnitItemState.CompletionConfirmed) {
                confirmedCounter--;
            }

            // alle items replaced => billing unit wurde replaced!
            if (item.state == SharedStates.BillingUnitItemState.Replaced) {
                replacedCounter--;
            }

            // alle items removed => billing unit wurde removed!
            if (item.state == SharedStates.BillingUnitItemState.Removed) {
                removedCounter--;
            }
        }

        // alle items sind vom AG abgenommen
        if (confirmedCounter == 0) {
            unitState = SharedStates.BillingUnitState.Completed;
        }

        if (replacedCounter == 0) {
            unitState = SharedStates.BillingUnitState.Replaced;
        }

        if (removedCounter == 0) {
            unitState = SharedStates.BillingUnitState.Removed;
        }
    }

    function getBillingUnitLength() public view returns (uint256 billingUnitLength) {
        BillingData storage bd = billingData();
        billingUnitLength = bd.billingUnitIds.length;
    }

    // ---- BillingUnitItem ----

    function getBillingUnitItem(string memory _billingUnitItemId)
        public
        view
        override
        returns (BillingUnitItem memory)
    {
        BillingData storage bd = billingData();
        return bd.billingUnitItems[_billingUnitItemId];
    }

    function getBillingUnitItemIdByIndex(uint256 index)
        public
        view
        override
        returns (string memory)
    {
        BillingData storage bd = billingData();
        return bd.billingUnitItemIds[index];
    }

    function getMessageById(string memory messageId, string memory itemId)
        public
        view
        override
        returns (Message memory message)
    {
        BillingData storage bd = billingData();
        Message[] memory _messages = bd.itemMessages[itemId];
        for (uint256 i = 0; i < _messages.length; i++) {
            if (isStringEqual(_messages[i].id, messageId) == true) {
                message = _messages[i];
            }
        }
    }

    function getMessageByIndex(uint256 index, string memory itemId)
        public
        view
        override
        returns (Message memory message)
    {
        BillingData storage bd = billingData();
        Message[] memory _messages = bd.itemMessages[itemId];
        message = _messages[index];
    }

    function getBillingUnitItemLength()
        public
        view
        override
        returns (uint256 billingUnitItemLength)
    {
        BillingData storage bd = billingData();
        billingUnitItemLength = bd.billingUnitItemIds.length;
    }

    function getMessageLengthOfBillingUnitItem(string memory itemId)
        public
        view
        override
        returns (uint256 messageLength)
    {
        BillingData storage bd = billingData();
        messageLength = bd.itemMessages[itemId].length;
    }

    /*
     ---- Internal functions ----
    */

    function _initBillingUnit(
        BillingData storage bd,
        BillingUnitInit memory _billingUnit,
        SharedStates.Origin origin
    ) internal {
        string memory _id = _billingUnit.id; // billingUnitId

        bd.billingUnits[_id].id = _id;
        bd.billingUnits[_id].state = SharedStates.BillingUnitState.Open;
        bd.billingUnits[_id].origin = origin;

        if (origin == SharedStates.Origin.Contract) {
            address _configHandler = IBconContract(bconContract).getConfigHandler();
            bd.billingUnits[_id].config = IConfigurationHandler(_configHandler).extractConfig(
                _billingUnit.configurationItems
            );
        }

        bd.billingUnitIds.push(_id);

        // add items to unit
        for (uint256 i = 0; i < _billingUnit.items.length; i++) {
            BillingUnitItemInit memory _billingUnitItem = _billingUnit.items[i];
            // creates billingUnitItem and does update paymentTotal of billingUnit aswell
            _initBillingUnitItem(bd, _billingUnitItem, SharedStates.Origin.Contract);
        }

        // add to billing unit completion rate
        // 1000000000 = 100%
        bd.billingUnits[_id].completionRateTotal += (1000000000 * _billingUnit.items.length);

        IBconContract(bconContract).throwBillingUnitCreated(bd.billingUnits[_id]);
    }

    function _initBillingUnitItem(
        BillingData storage bd,
        BillingUnitItemInit memory _billingUnitItem,
        SharedStates.Origin _origin
    ) internal {
        // fetch values
        string memory _id = _billingUnitItem.id; // billingUnitId
        string memory _billingUnitId = _billingUnitItem.billingUnitId; // billingUnitId

        // set values
        bd.billingUnitItems[_id].id = _id;
        bd.billingUnitItems[_id].billingUnitId = _billingUnitId;

        bd.billingUnitItems[_id].price = _billingUnitItem.price;
        bd.billingUnitItems[_id].quantity = _billingUnitItem.quantity;

        bd.billingUnitItems[_id].state = SharedStates.BillingUnitItemState.Open;
        bd.billingUnitItems[_id].origin = _origin;

        // link billingUnitItem and billingUnit
        bd.billingUnitItemIds.push(_id);
        bd.billingUnits[_billingUnitId].items.push(bd.billingUnitItems[_id]);

        IBconContract(bconContract).throwBillingUnitItemCreated(bd.billingUnitItems[_id]);

        // add price*quantity to unit payment total
        // TODO check if valid assumption!
        bd.billingUnits[_billingUnitId].paymentTotal += (_billingUnitItem.price *
            _billingUnitItem.quantity);

        //console.log("### BconContract.sol | Added new billing unit item: unit %s >> item %s",_billingUnitId,_id);
    }

    function getBillingData() internal returns (BillingData storage) {
        return billingData();
    }

    /*
     ---- Util functions ----
    */

    function isStringEqual(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /*
     ---- Fallback ----
    */

    // delegate call to handler in order to manipulate billingUnits directly without message calls
    fallback() external {
        address targetAddress;

        console.log('[BillingUnits] msg.data');
        console.logBytes(msg.data);

        assembly {
            // get target address from calldata
            // call of fallback => (targetCalldata,targetAddress)
            let base := calldatasize()
            let off := sub(base, 32)
            targetAddress := calldataload(off)
        }

        console.log('targetAddress => ', targetAddress);

        assembly {
            // copy function selector and any arguments;
            // ignore last 32 bytes because they represent targetAddress
            let real_calldatasize := sub(calldatasize(), 32)
            calldatacopy(0, 0, real_calldatasize)

            // execute function call using the facet
            let result := delegatecall(gas(), targetAddress, 0, real_calldatasize, 0, 0)

            // get any return value
            returndatacopy(0, 0, returndatasize())

            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import './IBillingUnits.sol';
import './IChangeHandler.sol';

contract IStorage {
    struct Metadata {
        address bconContract;
        address billingUnits;
        address client;
        address contractor;
    }

    struct BillingData {
        // flat mapping of all billing units and their items
        string[] billingUnitIds;
        mapping(string => IBillingUnits.BillingUnit) billingUnits; // key isSharedDataStructure.BillingUnitId
        string[] billingUnitItemIds;
        mapping(string => IBillingUnits.BillingUnitItem) billingUnitItems; // key is BillingUnitItemId
        mapping(string => IBillingUnits.Message[]) itemMessages; // key is BillingUnitItemId
        mapping(string => IChangeHandler.ChangeRequest) changeRequests; // key is ChangeRequestId
    }

    // Creates and returns the storage pointer to the struct.
    function metadata() internal pure returns (Metadata storage md) {
        // ms_slot = keccak256("com.bimcontracts.metadata")
        assembly {
            md.slot := 0xbcfb861c0730ee4b5fe9b5b25c0f539409034f4c093e24d3e2d5f4d7de6d350b
        }
    }

    // Creates and returns the storage pointer to the struct.
    function billingData() internal pure returns (BillingData storage bd) {
        // ms_slot = keccak256("com.bimcontracts.billingdata")
        assembly {
            bd.slot := 0xcf7b695609d6d7fd9b16adf6e30bd628f41637d562a731f68a6a9799aad3b048
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import './IBillingUnits.sol';
import '../libraries/SharedStates.sol';

abstract contract IChangeHandler {
    struct ChangeRequest {
        ChangeRequestInit init;
        // both parties must approve the change; initiating party implicitly approves the request
        bool approvalClient;
        bool approvalContractor;
    }

    struct ChangeRequestInit {
        string id;
        SharedStates.ChangeType changeType; // add, replace, remove
        SharedStates.ChangeElement changeElement; // billing unit, billing unit item, paper contract, etc.
        string referencedElementId; // the referenced element can be a billing unit or a billing unit item
        IBillingUnits.BillingUnitInit[] newBillingUnits;
        IConfigurationHandler.ConfigurationItem[] configurationItems;
        string newDocumentHash;
    }

    function requestChange(ChangeRequestInit memory _request) external virtual;

    function approveChange(string calldata _changeRequestId) external virtual;

    function requestDocumentChange(ChangeRequestInit memory _request) external virtual;

    function approveDocumentChange(string calldata _changeRequestId) external virtual;

    function requestConfigChange(ChangeRequestInit memory _request) external virtual;

    function approveConfigChange(string calldata _changeRequestId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import './interfaces/IBconContract.sol';
import './interfaces/IDocuments.sol';

// BconContract represents a single legal contractual relation between "client" (Auftraggeber)
// and "contractor" (Auftragnehmer) with multiple BillingUnits (Abrechnungseinheiten) which consists of
// multiple BillingUnitItems (LV-Positionen)
contract Documents is IDocuments {
    // required legal documents as the base for this contract
    string public billOfQuantitiesDocument;
    string public billingPlan;
    string public bimModel;
    string public paperContract;

    address public bconContract;

    constructor(
        address _bconContract,
        string memory _billOfQuantitiesDocument,
        string memory _billingPlan,
        string memory _bimModel,
        string memory _paperContract
    ) {
        bconContract = _bconContract;
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
        billingPlan = _billingPlan;
        bimModel = _bimModel;
        paperContract = _paperContract;
    }

    function getDocuments()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (billOfQuantitiesDocument, billingPlan, bimModel, paperContract);
    }

    function setBillOfQuantitiesDocument(string calldata _billOfQuantitiesDocument)
        public
        override
    {
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setBillingPlan(string calldata _billingPlan) public override {
        billingPlan = _billingPlan;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setBimModel(string calldata _bimModel) public override {
        bimModel = _bimModel;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setPaperContract(string calldata _paperContract) public override {
        paperContract = _paperContract;
        IBconContract(bconContract).throwDocumentsUpdated();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

// BconContract represents a single legal contractual relation between "client" (Auftraggeber)
// and "contractor" (Auftragnehmer) with multiple BillingUnits (Abrechnungseinheiten) which consists of
// multiple BillingUnitItems (LV-Positionen)
abstract contract IDocuments {
    function setBillOfQuantitiesDocument(string calldata _billOfQuantitiesDocument) public virtual;

    function setBillingPlan(string calldata _billingPlan) public virtual;

    function setBimModel(string calldata _bimModel) public virtual;

    function setPaperContract(string calldata _paperContract) public virtual;
}