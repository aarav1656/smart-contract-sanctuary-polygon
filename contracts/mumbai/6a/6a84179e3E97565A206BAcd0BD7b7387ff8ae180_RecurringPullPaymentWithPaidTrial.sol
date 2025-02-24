// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../common/RegistryHelper.sol';
import '../common/KeeperCompatible.sol';

import './interfaces/IRecurringPPWithPaidTrial.sol';
import '../common/interfaces/IPullPaymentRegistry.sol';
import '../common/interfaces/IVersionedContract.sol';
import '../common/interfaces/IExecutor.sol';
import '../common/interfaces/IUniswapV2Router02.sol';

/**
 * @title RecurringPullPaymentWithPaidTrial - The billing model for subscription based payments with paid trial
 * @author The Pumapay Team
 * @notice A Subscription PullPayment with Paid Trial is a recurring payment subscription, that includes an option for merchants to set up a paid trial period before the recurring payments begin.
 * This billing model allows merchants the flexibility to offer customers a paid trial for a pre-defined interval of time before the full subscription payments begin.
 * A typical example of this type of billing model is a monthly membership payment of $50.00 for 12 months with a one-time registration fee of $10.00 paid first.
 */
contract RecurringPullPaymentWithPaidTrial is
	ReentrancyGuard,
	RegistryHelper,
	IRecurringPPWithPaidTrial,
	KeeperCompatible,
	IVersionedContract
{
	using Counters for Counters.Counter;
	/*
   	=======================================================================
   	======================== Structures ===================================
   	=======================================================================
 	*/
	struct PullPayment {
		uint256 paymentAmount;
		uint256 executionTimestamp;
	}

	struct Subscription {
		address subscriber;
		address paymentToken;
		uint256 numberOfPayments;
		uint256 startTimestamp;
		uint256 cancelTimestamp;
		uint256 nextPaymentTimestamp;
		uint256 lastPaymentTimestamp;
		uint256[] pullPaymentIDs;
		mapping(uint256 => PullPayment) pullPayments;
		string uniqueReference;
		address cancelledBy;
	}

	struct BillingModel {
		address payee;
		string name;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256 amount;
		address settlementToken;
		uint256 frequency;
		uint256 trialPeriod;
		uint256 initialAmount;
		uint256 numberOfPayments;
		uint256[] subscriptionIDs;
		mapping(uint256 => Subscription) subscriptions;
		uint256 creationTime;
	}

	struct PullPaymentData {
		uint256 paymentAmount;
		uint256 executionTimestamp;
		uint256 billingModelID;
		uint256 subscriptionID;
	}

	/*
   	=======================================================================
   	======================== Private Variables ============================
   	=======================================================================
 	*/
	/// @dev The couter for billing model ids
	Counters.Counter private _billingModelIDs;
	/// @dev The couter for subscription ids
	Counters.Counter private _subscriptionIDs;
	/// @dev The couter for pullpayment ids
	Counters.Counter private _pullPaymentIDs;

	/// @notice Mappings by ids

	/// @dev billing model ID => billing model details
	mapping(uint256 => BillingModel) private _billingModels;
	/// @dev subscription ID => billing model ID
	mapping(uint256 => uint256) private _subscriptionToBillingModel;
	/// @dev pull payment ID => subscription ID
	mapping(uint256 => uint256) private _pullPaymentToSubscription;

	/// @notice Mappings by address

	/// @dev Billing Model Creator => billing model IDs
	mapping(address => uint256[]) private _billingModelIdsByAddress;
	/// @dev Customer address => subscription IDs
	mapping(address => uint256[]) private _subscriptionIdsByAddress;
	/// @dev Customer address => pull payment IDs
	mapping(address => uint256[]) private _pullPaymentIdsByAddress;
	/// @dev customer address => list of inactive subscription Ids
	mapping(address => uint256[]) private _inactiveSubscriptionsByAddress;

	/// @notice Mappings by strings

	/// @dev bm unique reference => bmId
	mapping(string => uint256) private _bmReferences;
	/// @dev subscription unique reference => bmId
	mapping(string => uint256) private _subscriptionReferences;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/

	/**
	 * @dev This method initializes registry helper to be able to access method of core registry
	 */
	constructor(address registryAddress) RegistryHelper(registryAddress) {}

	/*
   	=======================================================================
   	======================== Events =======================================
    =======================================================================
 	*/
	event BillingModelCreated(uint256 indexed billingModelID, address indexed payee);
	event NewSubscription(
		uint256 indexed billingModelID,
		uint256 indexed subscriptionID,
		address payee,
		address payer
	);

	event PullPaymentExecuted(
		uint256 indexed subscriptionID,
		uint256 indexed pullPaymentID,
		uint256 indexed billingModelID,
		address payee,
		address payer,
		uint256 executionFee,
		uint256 userAmount,
		uint256 receiverAmount
	);

	event SubscriptionCancelled(
		uint256 indexed billingModelID,
		uint256 indexed subscriptionID,
		address payee,
		address payer
	);

	event BillingModelEdited(
		uint256 indexed billingModelID,
		address indexed newPayee,
		string indexed newName,
		string newMerchantName,
		address oldPayee
	);

	/*
   	=======================================================================
   	======================== Modifiers ====================================
    =======================================================================
 	*/
	modifier onlyValidSubscriptionId(uint256 _subscriptionID) {
		require(
			_subscriptionID > 0 && _subscriptionID <= _subscriptionIDs.current(),
			'RecurringPullPaymentWithPaidTrial: INVALID_SUBSCRIPTION_ID'
		);
		_;
	}

	modifier onlyValidBillingModelId(uint256 _billingModelID) {
		require(
			_billingModelID > 0 && _billingModelID <= _billingModelIDs.current(),
			'RecurringPullPaymentWithPaidTrial: INVALID_BILLING_MODEL_ID'
		);
		_;
	}

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @notice Allows merchants to create a new billing model with required configurations.
	 * here merchant specifies the paid trial duration and amount for paid trial.
	 * @dev _name, _merchantName, _reference and _merchantURL can be empty.
	 * @param _payee             - payee (receiver) address for pull payment
	 * @param _name              - name that can be injected from the creator of the billing model for any future reference
	 * @param _merchantName		 	 - name of the merchant
	 * @param _reference				 - unique refernce for billing model. unique reference is generated if external reference is not given.
	 * @param _merchantURL			 - merchant` personal url
	 * @param _amount            - amount that the payee requests / amount that the payer needs to pay
	 * @param _token             - token address in which the payee defines the amount
	 * @param _frequency         - billing cycle in seconds i.e. monthly = 30d * 24h * 60m * 60s
	 * @param _trialPeriod       - free trial period in seconds i.e monthly = 30d * 24h * 60m * 60s
	 * @param _initialAmount     - Initial amount for paid trial.
	 * @param _numberOfPayments  - number of payments the customer will pay i.e. 12 to cover a monthly subscription for a year.
	 * @return billingModelID 	 - newly generated billing model id
	 */
	function createBillingModel(
		address _payee,
		string memory _name,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL,
		uint256 _amount,
		address _token,
		uint256 _frequency,
		uint256 _trialPeriod,
		uint256 _initialAmount,
		uint256 _numberOfPayments
	) public virtual override returns (uint256 billingModelID) {
		require(_payee != address(0), 'RecurringPPWithPaidTrial: INVALID_PAYEE_ADDRESS');
		require(_amount > 0, 'RecurringPPWithPaidTrial: INVALID_AMOUNT');

		require(_frequency > 0, 'RecurringPPWithPaidTrial: INVALID_FREQUENCY');
		require(_trialPeriod > 0, 'RecurringPPWithPaidTrial: INVALID_TRIAL_PERIOD');
		require(_initialAmount > 0, 'RecurringPPWithPaidTrial: INVALID_INITIAL_AMOUNT');
		require(_numberOfPayments > 0, 'RecurringPPWithPaidTrial: INVALID_NO_OF_PAYMENTS');
		require(registry.isSupportedToken(_token), 'RecurringPPWithPaidTrial: UNSUPPORTED_TOKEN');

		_billingModelIDs.increment();
		uint256 newBillingModelID = _billingModelIDs.current();
		BillingModel storage bm = _billingModels[newBillingModelID];

		// Billing Model Details
		bm.payee = _payee;
		bm.name = _name;
		bm.merchantName = _merchantName;
		bm.amount = _amount;
		bm.settlementToken = _token;
		bm.frequency = _frequency;
		bm.trialPeriod = _trialPeriod;
		bm.initialAmount = _initialAmount;
		bm.numberOfPayments = _numberOfPayments;
		bm.creationTime = block.timestamp;
		bm.merchantURL = _merchantURL;

		// Owner/Creator of the billing model
		_billingModelIdsByAddress[msg.sender].push(newBillingModelID);

		if (bytes(_reference).length > 0) {
			require(
				_bmReferences[_reference] == 0,
				'RecurringPullPaymentWithPaidTrial: REFERENCE_ALREADY_EXISTS'
			);
			_bmReferences[_reference] = newBillingModelID;
			bm.uniqueReference = _reference;
		} else {
			string memory newReference = string(
				abi.encodePacked('RecurringPullPaymentWithPaidTrial_', Strings.toString(newBillingModelID))
			);
			_bmReferences[newReference] = newBillingModelID;
			bm.uniqueReference = newReference;
		}

		// emit event for new billing model
		emit BillingModelCreated(newBillingModelID, _payee);

		return newBillingModelID;
	}

	/**
	 * @notice Allows users to subscribe to a new billing model.
	 * @dev the paid trial payment is done at the time of subscription. The recurring payments are charged when paid trial ends
	 * @param _billingModelID    - the ID of the billing model
	 * @param _paymentToken      - the token address the customer wants to pay in
	 * @param _reference 				 - the unique reference for the subscription. if given empty, a unique reference is generated on chain
	 * @return subscriptionID 	 - newly generated subscription id
	 */
	function subscribeToBillingModel(
		uint256 _billingModelID,
		address _paymentToken,
		string memory _reference
	)
		public
		virtual
		override
		nonReentrant
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 subscriptionID)
	{
		_subscriptionIDs.increment();
		uint256 newSubscriptionID = _subscriptionIDs.current();

		BillingModel storage bm = _billingModels[_billingModelID];
		Subscription storage subscription = bm.subscriptions[newSubscriptionID];

		subscription.subscriber = msg.sender;
		subscription.paymentToken = _paymentToken;
		subscription.startTimestamp = block.timestamp;

		//set lastPaymentTimestamp to current time
		subscription.lastPaymentTimestamp = block.timestamp;
		//set the nextPaymentTimestamp to startTime + paid trial period
		subscription.nextPaymentTimestamp = block.timestamp + bm.trialPeriod;

		subscription.numberOfPayments = bm.numberOfPayments;
		bm.subscriptionIDs.push(newSubscriptionID);

		_subscriptionToBillingModel[newSubscriptionID] = _billingModelID;
		_subscriptionIdsByAddress[msg.sender].push(newSubscriptionID);

		if (bytes(_reference).length > 0) {
			require(
				_subscriptionReferences[_reference] == 0,
				'RecurringPullPaymentWithPaidTrial: REFERENCE_ALREADY_EXISTS'
			);
			_subscriptionReferences[_reference] = newSubscriptionID;
			subscription.uniqueReference = _reference;
		} else {
			string memory newReference = string(
				abi.encodePacked(
					'RecurringPullPaymentWithPaidTrial_',
					Strings.toString(_billingModelID),
					'_',
					Strings.toString(newSubscriptionID)
				)
			);
			_subscriptionReferences[newReference] = newSubscriptionID;
			subscription.uniqueReference = newReference;
		}

		//execute the payment for paid trial
		(uint256 executionFee, uint256 userAmount, uint256 receiverAmount) = IExecutor(
			registry.getExecutor()
		).execute(bm.settlementToken, _paymentToken, msg.sender, bm.payee, bm.initialAmount);

		emit NewSubscription(_billingModelID, newSubscriptionID, bm.payee, msg.sender);

		emit PullPaymentExecuted(
			newSubscriptionID,
			0,
			_billingModelID,
			bm.payee,
			msg.sender,
			executionFee,
			userAmount,
			receiverAmount
		);

		return newSubscriptionID;
	}

	/**
	 * @notice This method allows anyone to execute the recurring pullpayment for the subscription.
	 * The pullpayment for subscription will be executed only after the paid trial ends
	 * @dev our backend will call this method to execute the recurring payment for the subscription at regular interval of time.
	 * @param _subscriptionID 	- The subscription id for which recurring pullpayment to execute.
	 * @return pullPaymentID		- The newly generated pullPayment id
	 */
	function executePullPayment(uint256 _subscriptionID)
		public
		virtual
		override
		nonReentrant
		onlyValidSubscriptionId(_subscriptionID)
		returns (uint256 pullPaymentID)
	{
		return _executePullPayment(_subscriptionID);
	}

	/**
	 * @dev This method contains actual logic for executing the pull payment for the subscription.
	 * Requirements-
	 * 1. current time should exceed next payment` time. i.e paid trial should be completed
	 * 2. subscription is not cancelled.
	 * 3. total number of payments are not completed.
	 * @param _subscriptionID 	- The subscription id for which recurring pullpayment to execute.
	 * @return pullPaymentID		- The newly generated pullPayment id
	 */
	function _executePullPayment(uint256 _subscriptionID) private returns (uint256 pullPaymentID) {
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subscriptionID]];
		Subscription storage subscription = bm.subscriptions[_subscriptionID];
		uint256 billingModelID = _subscriptionToBillingModel[_subscriptionID];

		require(
			block.timestamp >= subscription.startTimestamp &&
				block.timestamp >= subscription.nextPaymentTimestamp,
			'RecurringPullPaymentWithPaidTrial: INVALID_EXECUTION_TIME'
		);
		require(
			subscription.cancelTimestamp == 0 || block.timestamp < subscription.cancelTimestamp,
			'RecurringPullPaymentWithPaidTrial: SUBSCRIPTION_CANCELED'
		);
		require(
			subscription.numberOfPayments > 0,
			'RecurringPullPaymentWithPaidTrial: NO_OF_PAYMENTS_EXCEEDED'
		);

		_pullPaymentIDs.increment();
		uint256 newPullPaymentID = _pullPaymentIDs.current();
		// update subscription
		subscription.numberOfPayments = subscription.numberOfPayments - 1;
		subscription.lastPaymentTimestamp = block.timestamp;
		subscription.nextPaymentTimestamp = subscription.nextPaymentTimestamp + bm.frequency;
		subscription.pullPaymentIDs.push(newPullPaymentID);
		// update pull payment
		subscription.pullPayments[newPullPaymentID].paymentAmount = bm.amount;
		subscription.pullPayments[newPullPaymentID].executionTimestamp = block.timestamp;
		// link pull payment with subscription
		_pullPaymentToSubscription[newPullPaymentID] = _subscriptionID;
		// link pull payment with "payer"
		_pullPaymentIdsByAddress[subscription.subscriber].push(newPullPaymentID);

		(uint256 executionFee, uint256 userAmount, uint256 receiverAmount) = IExecutor(
			registry.getExecutor()
		).execute(
				bm.settlementToken,
				subscription.paymentToken,
				subscription.subscriber,
				bm.payee,
				bm.amount
			);

		emit PullPaymentExecuted(
			_subscriptionID,
			newPullPaymentID,
			billingModelID,
			bm.payee,
			subscription.subscriber,
			executionFee,
			userAmount,
			receiverAmount
		);

		return newPullPaymentID;
	}

	/**
	 * @notice This method allows customer / merchant to cancel the on going subscription.
	 * @dev cancelling subscription adds the subscription to inactive subscriptions list of subscriber
	 * @param _subscriptionID - the id of the subscription to cancel
	 * @return subscriptionID - the id of the cancelled subscription
	 */
	function cancelSubscription(uint256 _subscriptionID)
		public
		virtual
		override
		onlyValidSubscriptionId(_subscriptionID)
		returns (uint256 subscriptionID)
	{
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subscriptionID]];
		Subscription storage subscription = bm.subscriptions[_subscriptionID];

		require(
			subscription.cancelTimestamp == 0,
			'RecurringPullPaymentWithPaidTrial: ALREADY_CANCELLED'
		);

		require(
			msg.sender == subscription.subscriber || msg.sender == bm.payee,
			'RecurringPullPaymentWithPaidTrial: INVALID_CANCELER'
		);

		subscription.cancelTimestamp = block.timestamp;
		subscription.cancelledBy = msg.sender;

		_inactiveSubscriptionsByAddress[msg.sender].push(_subscriptionID);

		emit SubscriptionCancelled(
			_subscriptionToBillingModel[_subscriptionID],
			_subscriptionID,
			bm.payee,
			bm.subscriptions[_subscriptionID].subscriber
		);

		return _subscriptionID;
	}

	/**
	 * @notice Edit a billing model
	 * Editing a billing model allows the creator of the billing model to update only attributes
	 * that does not affect the billing cycle of the customer, i.e. the name and the payee address.
	 * Any other changes are not allowed.
	 * @dev _newName, _newMerchantName and _newMerchantURL can be empty.
	 *
	 * @param _billingModelID 	- the ID of the billing model
	 * @param _newPayee 				- the address of new payee
	 * @param _newName 					- new name for billing model
	 * @param _newMerchantName 	- new name for merchant
	 * @param _newMerchantURL  	- merchant` new personal url
	 * @return billingModelID  	- billing model id edited
	 */
	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newName,
		string memory _newMerchantName,
		string memory _newMerchantURL
	)
		public
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 billingModelID)
	{
		BillingModel storage bm = _billingModels[_billingModelID];

		require(msg.sender == bm.payee, 'RecurringPullPaymentWithPaidTrial: INVALID_EDITOR');

		require(
			_newPayee != address(0) || bytes(_newName).length > 0,
			'RecurringPullPaymentWithPaidTrial: INVALID_OPERATION'
		);

		if (_newPayee != address(0)) {
			bm.payee = _newPayee;
		}

		if (bytes(_newName).length > 0) {
			require(
				keccak256(bytes(_newName)) != keccak256(bytes(bm.name)),
				'RecurringPullPaymentWithPaidTrial: NAME_EXISTS'
			);
			bm.name = _newName;
		}

		bm.merchantName = _newMerchantName;
		bm.merchantURL = _newMerchantURL;

		emit BillingModelEdited(_billingModelID, _newPayee, _newName, _newMerchantName, msg.sender);
		return _billingModelID;
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @dev This method is called by Keeper network nodes per block. This returns the list of subscription ids and their count which needs to be executed.
	 * @param checkData specified in the upkeep registration so it is always the same for a registered upkeep.
	 * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
	 * @return performData bytes that the keeper should call performUpkeep with, if upkeep is needed.
	 */
	function checkUpkeep(bytes calldata checkData)
		external
		view
		override
		returns (bool upkeepNeeded, bytes memory performData)
	{
		checkData;

		(uint256[] memory subsctionIds, uint256 subcriptionCount) = getSubscriptionIds();

		if (subcriptionCount > 0) {
			upkeepNeeded = true;
			performData = abi.encode(subsctionIds, subcriptionCount);
		}
	}

	/**
	 * @notice method that is actually executed by the keepers, via the registry.
	 * The data returned by the checkUpkeep simulation will be passed into this method to actually be executed.
	 * @param performData is the data which was passed back from the checkData
	 * simulation. If it is encoded, it can easily be decoded into other types by
	 * calling `abi.decode`. This data should not be trusted, and should be
	 * validated against the contract's current state.
	 */
	function performUpkeep(bytes calldata performData) external override {
		(uint256[] memory subsctionIds, uint256 subcriptionCount) = abi.decode(
			performData,
			(uint256[], uint256)
		);

		for (uint256 subIndex = 0; subIndex < subcriptionCount; subIndex++) {
			_executePullPayment(subsctionIds[subIndex]);
		}
	}

	/**
	 * @notice This method gets the list of subscription ids which needs to be executed
	 * @return subscriptionIds - indicates the list of subscrtipion ids
	 * count - indicates the total number of subscriptions to execute
	 */
	function getSubscriptionIds()
		public
		view
		returns (uint256[] memory subscriptionIds, uint256 count)
	{
		uint256 batchSize = IPullPaymentRegistry(registry.getPullPaymentRegistry()).BATCH_SIZE();
		subscriptionIds = new uint256[](batchSize);

		for (uint256 id = 1; id <= _subscriptionIDs.current(); id++) {
			if (isPullpayment(id) && count < batchSize) {
				subscriptionIds[count] = id;
				count++;
			}
		}
	}

	/**
	 * @notice This method checks whether to execute the pullpayment for the given subscription id or not.
	 * returns true if pullpayment is needed, otherwise returns false
	 * @param _subsctptionId - indicates the subscription id
	 */
	function isPullpayment(uint256 _subsctptionId) public view returns (bool) {
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subsctptionId]];
		Subscription storage subscription = bm.subscriptions[_subsctptionId];

		return (block.timestamp >= subscription.startTimestamp &&
			block.timestamp >= subscription.nextPaymentTimestamp &&
			subscription.cancelTimestamp == 0 &&
			subscription.numberOfPayments > 0);
	}

	/**
	 * @notice Retrieves a billing model
	 * @dev shows subscription ids of billing model to only bm creator
	 * @param _billingModelID - the ID of the billing model
	 * @return bm							- returns the Billing model data struct
	 */
	function getBillingModel(uint256 _billingModelID)
		external
		view
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (BillingModelData memory bm)
	{
		BillingModel storage bmDetails = _billingModels[_billingModelID];

		// If the caller is the address owning this billing model, then return the array with the
		// subscription IDs as well
		bm.payee = bmDetails.payee;
		bm.name = bmDetails.name;
		bm.merchantName = bmDetails.merchantName;
		bm.uniqueReference = bmDetails.uniqueReference;
		bm.amount = bmDetails.amount;
		bm.settlementToken = bmDetails.settlementToken;
		bm.frequency = bmDetails.frequency;
		bm.trialPeriod = bmDetails.trialPeriod;
		bm.initialAmount = bmDetails.initialAmount;
		bm.numberOfPayments = bmDetails.numberOfPayments;
		bm.creationTime = bmDetails.creationTime;
		bm.merchantURL = bmDetails.merchantURL;

		if (msg.sender == bmDetails.payee) {
			bm.subscriptionIDs = bmDetails.subscriptionIDs;
		} else {
			// Otherwise, return an empty array for `_bmSubscriptionIDs`
			uint256[] memory emptyArray;
			bm.subscriptionIDs = emptyArray;
		}
	}

	/**
	 * @notice Retrieves a billing model with given token as payment token
	 * @param _billingModelID - the ID of the billing model
	 * @param _token 					- the token used for payment
	 * @return bm							- returns the Billing model data struct which contains exact amount to pay in given token.
	 */
	function getBillingModel(uint256 _billingModelID, address _token)
		external
		view
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (SwappableBillingModel memory bm)
	{
		BillingModel storage bmDetails = _billingModels[_billingModelID];

		address[] memory path = new address[](2);
		path[0] = _token;
		path[1] = bmDetails.settlementToken;

		uint256 amount;
		if (_token != bmDetails.settlementToken) {
			uint256[] memory amountsIn = IUniswapV2Router02(registry.getUniswapRouter()).getAmountsIn(
				bmDetails.amount,
				path
			);
			amount = amountsIn[0];
		} else {
			amount = bmDetails.amount;
		}

		bm.name = bmDetails.name;
		bm.payee = bmDetails.payee;
		bm.settlementAmount = bmDetails.amount;
		bm.settlementToken = bmDetails.settlementToken;
		bm.paymentAmount = amount;
		bm.paymentToken = _token;
		bm.frequency = bmDetails.frequency;
		bm.trialPeriod = bmDetails.trialPeriod;
		bm.initialAmount = bmDetails.initialAmount;
		bm.numberOfPayments = bmDetails.numberOfPayments;
		bm.creationTime = bmDetails.creationTime;
		bm.merchantName = bmDetails.merchantName;
		bm.uniqueReference = bmDetails.uniqueReference;
		bm.merchantURL = bmDetails.merchantURL;

		return bm;
	}

	/**
	 * @notice Retrieves subscription details
	 * @dev shows pullpayment ids of subscription to merchant of bm and subscriber only
	 * @param _subscriptionID - the ID of the subscription
	 * @return sb 						- the subscription information
	 */
	function getSubscription(uint256 _subscriptionID)
		external
		view
		virtual
		override
		onlyValidSubscriptionId(_subscriptionID)
		returns (SubscriptionData memory sb)
	{
		uint256 bmID = _subscriptionToBillingModel[_subscriptionID];
		BillingModel storage bm = _billingModels[bmID];
		Subscription storage subscription = bm.subscriptions[_subscriptionID];

		sb.subscriber = subscription.subscriber;
		sb.amount = bm.amount;
		sb.settlementToken = bm.settlementToken;
		sb.paymentToken = subscription.paymentToken;
		sb.numberOfPayments = subscription.numberOfPayments;
		sb.startTimestamp = subscription.startTimestamp;
		sb.cancelTimestamp = subscription.cancelTimestamp;
		sb.nextPaymentTimestamp = subscription.nextPaymentTimestamp;
		sb.lastPaymentTimestamp = subscription.lastPaymentTimestamp;
		sb.uniqueReference = subscription.uniqueReference;
		sb.cancelledBy = subscription.cancelledBy;

		if (isPaidTrialEnded(_subscriptionID)) {
			sb.isPaidTrialEnded = true;
		} else {
			sb.isPaidTrialEnded = false;
		}

		if (msg.sender == bm.payee || msg.sender == subscription.subscriber) {
			sb.pullPaymentIDs = subscription.pullPaymentIDs;
		} else {
			// Return an empty array for `_subscriptionPullPaymentIDs`in case the caller is not
			// the payee or the subscriber
			uint256[] memory emptyArray;
			sb.pullPaymentIDs = emptyArray;
		}
		sb.billingModelID = bmID;
	}

	/**
	 * @notice Returns the details of a pull payment
	 * @dev shows pullpayment amount and timestamp to granted executor, bm creator and subscriber only
	 * @param _pullPaymentID 	- the Id of the pull payment
	 * @return pullPayment 		- the pullpayment informations
	 */
	function getPullPayment(uint256 _pullPaymentID)
		external
		view
		returns (PullPaymentData memory pullPayment)
	{
		require(
			_pullPaymentID > 0 && _pullPaymentID <= _pullPaymentIDs.current(),
			'RecurringPullPaymentWithPaidTrial: INVALID_PULLPAYMENT_ID'
		);
		uint256 bmID = _subscriptionToBillingModel[_pullPaymentToSubscription[_pullPaymentID]];
		BillingModel storage bm = _billingModels[bmID];
		Subscription storage subscription = bm.subscriptions[
			_pullPaymentToSubscription[_pullPaymentID]
		];
		pullPayment.paymentAmount = bm
			.subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
			.pullPayments[_pullPaymentID]
			.paymentAmount;
		pullPayment.executionTimestamp = bm
			.subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
			.pullPayments[_pullPaymentID]
			.executionTimestamp;

		if (
			msg.sender != bm.payee &&
			msg.sender != subscription.subscriber &&
			IPullPaymentRegistry(registry.getPullPaymentRegistry()).isExecutorGranted(msg.sender) == false
		) {
			pullPayment.paymentAmount = 0;
			pullPayment.executionTimestamp = 0;
		}

		pullPayment.billingModelID = bmID;
		pullPayment.subscriptionID = _pullPaymentToSubscription[_pullPaymentID];
	}

	/**
	 * @notice Retrieves billing model IDs for an address
	 * @dev Returns an array with the billing model IDs related with that address
	 * @param _creator 					- address that created the billing model
	 * @return billingModelIDs 	- returns list of billing model ids for merchant
	 */
	function getBillingModelIdsByAddress(address _creator)
		external
		view
		returns (uint256[] memory billingModelIDs)
	{
		return _billingModelIdsByAddress[_creator];
	}

	/**
	 * @notice Retrieves subscription ids for an address
	 * @dev Returns an array with the subscription IDs related with that address
	 * @param _subscriber 			- address the pull payment relates to
	 * @return subscriptionIDs 	- the list of subscription ids for subscriber
	 */
	function getSubscriptionIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory subscriptionIDs)
	{
		return _subscriptionIdsByAddress[_subscriber];
	}

	/**
	 * @notice Retrieves canceled subscription ids for an address
	 * @dev Returns an array with the subscription IDs related with that address
	 * @param _subscriber 			- address the pull payment relates to
	 * @return subscriptionIDs 	- contains the list of cancelled subscriptions
	 */
	function getCanceledSubscriptionIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory subscriptionIDs)
	{
		return _inactiveSubscriptionsByAddress[_subscriber];
	}

	/**
	 * @notice Retrieves pull payment ids for an address
	 * @dev Returns an array with the pull payment IDs related with that address
	 * @param _subscriber 		- address the pull payment relates to
	 * @return pullPaymentIDs - the list of pullpayment ids
	 */
	function getPullPaymentsIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory pullPaymentIDs)
	{
		return _pullPaymentIdsByAddress[_subscriber];
	}

	/**
	 *@notice This method tells you whether user`s paid trial is ended or not.
	 *@param _subscriptionID indicates the subscription ID.
	 *@return returns true if trial period ended. otherwise returns false.
	 */
	function isPaidTrialEnded(uint256 _subscriptionID)
		public
		view
		onlyValidSubscriptionId(_subscriptionID)
		returns (bool)
	{
		uint256 bmID = _subscriptionToBillingModel[_subscriptionID];
		BillingModel storage bm = _billingModels[bmID];
		Subscription storage subscription = bm.subscriptions[_subscriptionID];

		if (block.timestamp > (subscription.startTimestamp + bm.trialPeriod)) {
			return true;
		}
		return false;
	}

	/**
	 * @notice Gives current billing model id
	 */
	function getCurrentBillingModelId() external view virtual returns (uint256) {
		return _billingModelIDs.current();
	}

	/**
	 * @notice Gives current subscription id
	 */
	function getCurrentSubscriptionId() external view virtual returns (uint256) {
		return _subscriptionIDs.current();
	}

	/**
	 * @notice Gives current pullpayment id
	 */
	function getCurrentPullPaymentId() external view virtual returns (uint256) {
		return _pullPaymentIDs.current();
	}

	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		override
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0, 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRecurringPPWithPaidTrial {
	struct BillingModelData {
		address payee;
		string name;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256 amount;
		address settlementToken;
		uint256 frequency;
		uint256 trialPeriod;
		uint256 initialAmount;
		uint256 numberOfPayments;
		uint256[] subscriptionIDs;
		uint256 creationTime;
	}

	struct SwappableBillingModel {
		address payee;
		string name;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256 settlementAmount;
		address settlementToken;
		uint256 paymentAmount;
		address paymentToken;
		uint256 frequency;
		uint256 trialPeriod;
		uint256 initialAmount;
		uint256 numberOfPayments;
		uint256 creationTime;
	}
	struct SubscriptionData {
		address subscriber;
		uint256 amount;
		address settlementToken;
		address paymentToken;
		uint256 numberOfPayments;
		uint256 startTimestamp;
		uint256 cancelTimestamp;
		uint256 nextPaymentTimestamp;
		uint256 lastPaymentTimestamp;
		bool isPaidTrialEnded;
		uint256[] pullPaymentIDs;
		uint256 billingModelID;
		string uniqueReference;
		address cancelledBy;
	}

	function createBillingModel(
		address _payee,
		string memory _name,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL,
		uint256 _amount,
		address _token,
		uint256 _frequency,
		uint256 _trialPeriod,
		uint256 _initialAmount,
		uint256 _numberOfPayments
	) external returns (uint256 billingModelID);

	function subscribeToBillingModel(
		uint256 _billingModelID,
		address _paymentToken,
		string memory _reference
	) external returns (uint256 subscriptionID);

	function executePullPayment(uint256 _subscriptionID) external returns (uint256);

	function cancelSubscription(uint256 _subscriptionID) external returns (uint256);

	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newName,
		string memory _newMerchantName,
		string memory _newMerchantURL
	) external returns (uint256);

	function getBillingModel(uint256 _billingModelID) external view returns (BillingModelData memory);

	function getSubscription(uint256 _subscriptionID) external view returns (SubscriptionData memory);

	function getBillingModel(uint256 _billingModelID, address _token)
		external
		view
		returns (SwappableBillingModel memory bm);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICoreRegistry.sol';
import './IPullPaymentConfig.sol';

interface IRegistry is ICoreRegistry, IPullPaymentConfig {
	function getPMAToken() external view returns (address);

	function getWBNBToken() external view returns (address);

	function getFreezer() external view returns (address);

	function getExecutor() external view returns (address);

	function getUniswapFactory() external view returns (address);

	function getUniswapPair() external view returns (address);

	function getUniswapRouter() external view returns (address);

	function getPullPaymentRegistry() external view returns (address);

	function getKeeperRegistry() external view returns (address);

	function getTokenConverter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentRegistry {
	function grantExecutor(address _executor) external;

	function revokeExecutor(address _executor) external;

	function addPullPaymentContract(string calldata _identifier, address _addr) external;

	function getPPAddressForOrDie(bytes32 _identifierHash) external view returns (address);

	function getPPAddressFor(bytes32 _identifierHash) external view returns (address);

	function getPPAddressForStringOrDie(string calldata _identifier) external view returns (address);

	function getPPAddressForString(string calldata _identifier) external view returns (address);

	function isExecutorGranted(address _executor) external view returns (bool);

	function BATCH_SIZE() external view returns (uint256);

	function setUpkeepId(address upkeepAddress, uint256 upkeepId) external;

	function upkeepIds(address upkeepAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentConfig {
	function getSupportedTokens() external view returns (address[] memory);

	function isSupportedToken(address _tokenAddress) external view returns (bool isExists);

	function executionFeeReceiver() external view returns (address);

	function executionFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutor {
	function execute(
		address,
		address,
		address,
		address,
		uint256
	)
		external
		returns (
			uint256 executionFee,
			uint256 userAmount,
			uint256 receiverAmount
		);

	function execute(string calldata _bmType, uint256 _subscriptionId) external returns (uint256);
	//    function executePullPayment(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoreRegistry {
	function setAddressFor(string calldata, address) external;

	function getAddressForOrDie(bytes32) external view returns (address);

	function getAddressFor(bytes32) external view returns (address);

	function isOneOf(bytes32[] calldata, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IRegistry.sol';

/**
 * @title RegistryHelper - initializer for core registry
 * @author The Pumapay Team
 * @notice This contract helps to initialize the core registry contract in parent contracts.
 */
contract RegistryHelper is Ownable {
	/*
   	=======================================================================
   	======================== Public variatibles ===========================
   	=======================================================================
 	*/
	/// @notice The core registry contract
	IRegistry public registry;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @dev initializes the core registry with registry address
	 */
	constructor(address _registryAddress) {
		setRegistry(_registryAddress);
	}

	/*
   	=======================================================================
   	======================== Events =======================================
 	=======================================================================
 	*/
	event RegistrySet(address indexed registryAddress);

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Updates the address pointing to a Registry contract.
	 * @dev only owner can set the registry address.
	 * @param registryAddress - The address of a registry contract for routing to other contracts.
	 */
	function setRegistry(address registryAddress) public virtual onlyOwner {
		require(registryAddress != address(0), 'RegistryHelper: CANNOT_REGISTER_ZERO_ADDRESS');
		registry = IRegistry(registryAddress);
		emit RegistrySet(registryAddress);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './KeeperBase.sol';
import './interfaces/IKeeperCompatibleInterface.sol';

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
library Counters {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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