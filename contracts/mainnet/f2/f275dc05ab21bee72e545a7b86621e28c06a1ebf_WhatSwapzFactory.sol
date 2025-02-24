// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { WhatSwapzCollection } from "./WhatSwapzCollection.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title WhatSwapzFactory
/// @notice Factory to create WhatSwapzCollection instances and interact with Chainlink VRF for randomness.
contract WhatSwapzFactory is VRFConsumerBaseV2 {
	// ======================= ERRORS ==============================

	/// @notice The sender of the transaction must be WhatSwapzCollection created by this contract.
	error WhatSwapzFactory_SenderNotValidCollection();

	// ======================= CONSTANTS ===========================

	// How many confirmations the Chainlink node should wait before responding.
	uint16 private constant _VRF_REQUEST_CONFIRAMATIONS = 3;
	// Limit for how much gas to use for the callback request to fulfillRandomWords() function.
	uint32 private constant _VRF_CALLBACK_GAS_LIMIT = 1_000_000;

	// ======================= IMMUTABLES ==========================

	// Address of the Chainlink VRF Coordinator contract.
	VRFCoordinatorV2Interface private immutable _vrfCoordinator;
	// VRF subscription ID that this contract uses for funding requests.
	uint64 private immutable _vrfSubscriptionId;
	// VRF gas lane key hash value, which is the maximum gas price that will be paid for a request.
	bytes32 private immutable _vrfGasLane;

	// ======================= PRIVATE STORAGE =====================

	// WhatSwapzCollection => has been created by this contract.
	mapping(address => bool) private _isValidCollection;
	// VRF request ID => WhatSwapzCollection that requested it.
	mapping(uint256 => address) private _vrfRequestIdToCollectionAddress;

	// ======================= EVENTS ==============================

	/// @dev Emmited when a new collection is created.
	event CollectionCreated(
		address indexed addr,
		uint8[] packageUnits,
		uint256[] packagePrices,
		uint8[] rarity
	);

	// ======================= CONSTRUCTOR =========================

	/// @notice Constructor inherits VRFConsumerBaseV2.
	/// @param subscriptionId Subscription ID that this contract uses for funding VRF requests.
	/// @param vrfCoordinator VRF coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations.
	/// @param gasLane VRF gas lane to use, which specifies the maximum gas price to bump to.
	constructor(
		uint64 subscriptionId,
		address vrfCoordinator,
		bytes32 gasLane
	) VRFConsumerBaseV2(vrfCoordinator) {
		_vrfSubscriptionId = subscriptionId;
		_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
		_vrfGasLane = gasLane;
	}

	// ======================= CREATE COLLECTION ===================

	/// @notice Create a new instance of WhatSwapzCollection and store its address.
	/// @param owner - Owner of the new collection.
	/// @param name - Name of the new collection.
	/// @param uri - IPFS URI of the new collection.
	/// @param packageUnits - Array of the package sizes of the new collection.
	/// @param packagePrices - Array of the prices for the package sizes of the new collection.
	/// @param rarity - Array of the rarity values for each NFT of the new collection.
	function createCollection(
		address owner,
		string calldata name,
		string calldata uri,
		uint8[] calldata packageUnits,
		uint256[] calldata packagePrices,
		uint8[] calldata rarity
	) external {
		// Create new collection.
		address collection = address(
			new WhatSwapzCollection(
				owner,
				name,
				uri,
				packageUnits,
				packagePrices,
				rarity
			)
		);

		// Store address of the new collection.
		_isValidCollection[collection] = true;

		emit CollectionCreated(collection, packageUnits, packagePrices, rarity);
	}

	// ======================= RANDOM WORDS ========================

	/// @notice Request random words to Chainlink.
	/// @param numWords - Number of words requested.
	/// @return requestId - VRF request ID.
	function requestRandomWords(uint32 numWords)
		external
		returns (uint256 requestId)
	{
		// Only collection created by this factory can request random words.
		if (!_isValidCollection[msg.sender])
			revert WhatSwapzFactory_SenderNotValidCollection();

		// Request random words to VRF coordinator.
		requestId = _vrfCoordinator.requestRandomWords(
			_vrfGasLane,
			_vrfSubscriptionId,
			_VRF_REQUEST_CONFIRAMATIONS,
			_VRF_CALLBACK_GAS_LIMIT,
			numWords
		);

		// Map request ID to the collection that requested it.
		_vrfRequestIdToCollectionAddress[requestId] = msg.sender;
	}

	/// @notice Callback function used by VRF Coordinator.
	/// @param requestId - ID of the VRF request.
	/// @param randomWords - Array of random results from VRF Coordinator.
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
		internal
		override
	{
		// Send request ID and random words to collection contract to process the order.
		WhatSwapzCollection(_vrfRequestIdToCollectionAddress[requestId])
			.processOrder(requestId, randomWords);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IWhatSwapzFactory } from "./IWhatSwapzFactory.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";
import { Owned } from "solmate/auth/Owned.sol";

/// @title WhatSwapzCollection
/// @notice NFT collection with capabilities to mint packages of random NFTs and swap NFTs with
/// 		other NFT owners.
contract WhatSwapzCollection is ERC1155, Owned {
	// ======================= ERRORS ==============================

	/// @notice The name of the collection cannot be an empty string.
	error WhatSwapzCollection_EmptyName();
	/// @notice The URI cannot be an empty string.
	error WhatSwapzCollection_EmptyUri();
	/// @notice The package units and package prices arrays must have the same length and not be empty.
	error WhatSwapzCollection_InvalidNumOfPackages();
	/// @notice The rarity array cannot be empty.
	error WhatSwapzCollection_EmptyRariry();
	/// @notice The price of all packages must be greater than zero.
	error WhatSwapzCollection_InvalidPackagePrice();
	/// @notice The number of units of all packages must be between 1 and `_MAX_PACKAGE_UNITS`.
	error WhatSwapzCollection_InvalidPackageUnits();
	/// @notice The rarity valur of all NFTs must be between 1 and `_MAX_RARITY_VALUE`.
	error WhatSwapzCollection_InvalidRarityValue();
	/// @notice The value sent does not match the package price.
	error WhatSwapzCollection_InvalidValueSent();
	/// @notice The VRF request ID does not correspond to a pending order.
	error WhatSwapzCollection_PendingOrderNotFound();
	/// @notice The number of items offered and demanded must be between 1 and `_MAX_SWAP_ITEMS`.
	error WhatSwapzCollection_MaxSwapItemsExceeded();
	/// @notice The address does not own all the NFTs of the array.
	error WhatSwapzCollection_NotOwnerOfAll();
	/// @notice Only the creator of the offer is allowed to perform this action.
	error WhatSwapzCollection_NotOfferOwner();
	/// @notice Only the recipient of the offer is allowed to perform this action.
	error WhatSwapzCollection_NotDemandedOwner();
	/// @notice The offer is not in open state.
	error WhatSwapzCollection_NotOpenOffer();
	/// @notice The swap does not exist.
	error WhatSwapzCollection_SwapNotFound();
	/// @notice Only the factory contract is allowed to perform this action.
	error WhatSwapzCollection_SenderNotWhatSwapzFactory();
	/// @notice The tranfer of funds has failed.
	error WhatSwapzCollection_TransferFailed();

	// ======================= ENUMS ===============================

	/// @dev State of a swap.
	/// 	 0 (OFFERED) - Open swap offer.
	///		 1 (REJECTED) - Rejected by receiver of the offer.
	///		 2 (CANCELLED) - Cancelled by creator of the offer.
	///		 3 (EXECUTED) - Swap accepted and processed.
	enum SwapState {
		OFFERED,
		REJECTED,
		CANCELLED,
		EXECUTED
	}

	// ======================= STRUCTS =============================

	/// @dev Swap struct.
	/// 	 ownerA - Creator of the swap offer.
	///		 ownerB - Receiver of the swap offer.
	///		 nftsA - Array of NFTs offered by the creator.
	///		 nftsB - Array of NFTs demanded by the creator.
	///		 state - Current state of the swap.
	struct Swap {
		address ownerA;
		address ownerB;
		uint256[] nftsA;
		uint256[] nftsB;
		SwapState state;
	}

	// ======================= CONSTANTS ===========================

	// Max number of units allowed in a package.
	uint256 private constant _MAX_PACKAGE_UNITS = 100;
	// Max value allowed for the rarity of a NFT.
	uint256 private constant _MAX_RARITY_VALUE = 100;
	// Max number of offered and demanded NFTs allowed for a swap.
	uint256 private constant _MAX_SWAP_ITEMS = 100;
	// Swap ID => Swap struct.
	mapping(uint256 => Swap) private _swaps;

	// ======================= IMMUTABLES ==========================

	// Factory contract that created the collection.
	IWhatSwapzFactory private immutable _factory;
	// Summatory of the rarity values of all NFTs used to process a random ID.
	uint16 private immutable _raritySum;

	// ======================= PUBLIC STORAGE ======================

	// Name of the collection.
	string public name;
	// Last created swap ID.
	uint256 public swapCounter;

	// ======================= PRIVATE STORAGE =====================

	// URI for all token types by relying on ID substitution.
	string private _uri;
	// Array of the package sizes of the collection.
	uint8[] private _packageUnits;
	// Array of the prices for the package sizes of the collection.
	uint256[] private _packagePrices;
	// Array of the rarity values (from 1 to `_MAX_RARITY_VALUE`) for each NFT of the collection.
	// Each of the values represents the rarity of a specific NFT, corresponding the index 0 of the
	// array to the NFT with ID = 1. The lower the value, the more rare that NFT is.
	uint8[] private _rarity;
	// Package number of units => Package price.
	mapping(uint8 => uint256) private _packages;
	// VRF request ID => Buyer address. Keeps track of pending (waiting for randomness) orders.
	mapping(uint256 => address) private _pendingOrders;

	// ======================= MODIFIERS ===========================

	/// @dev Checks that all the `nftIds` are owned by `addr`.
	modifier ownsAll(address addr, uint256[] calldata nftIds) {
		uint256 nftIdsLength = nftIds.length;
		for (uint256 i = 0; i < nftIdsLength; ) {
			if (balanceOf[addr][nftIds[i]] == 0) {
				revert WhatSwapzCollection_NotOwnerOfAll();
			}
			unchecked {
				++i;
			}
		}
		_;
	}

	// ======================= EVENTS ==============================

	/// @dev Emmited when a buyer opens an order.
	event OrderCreated(address indexed buyer, uint8 units, uint256 requestId);

	/// @dev Emmited when an open order is processed.
	event OrderProcessed(
		address indexed buyer,
		uint256 requestId,
		uint256[] nfts
	);

	/// @dev Emmited when a new swap offer is created.
	event SwapOfferCreated(
		uint256 indexed swapId,
		address ownerA,
		address ownerB,
		uint256[] nftsA,
		uint256[] nftsB
	);

	/// @dev Emmited when an existing swap changes its state.
	event SwapOfferUpdated(uint256 swapId, SwapState state);

	// ======================= CONSTRUCTOR =========================

	/// @notice Constructor inherits Owned.
	/// @param owner_ - Owner of the collection.
	/// @param name_ - Name of the collection.
	/// @param uri_ - IPFS URI of the collection.
	/// @param packageUnits_ - Array of the package sizes of the collection.
	/// @param packagePrices_ - Array of the prices for the package sizes of the collection.
	/// @param rarity_ - Array of the rarity values for each NFT of the collection.
	constructor(
		address owner_,
		string memory name_,
		string memory uri_,
		uint8[] memory packageUnits_,
		uint256[] memory packagePrices_,
		uint8[] memory rarity_
	) Owned(owner_) {
		if (bytes(name_).length == 0) revert WhatSwapzCollection_EmptyName();
		if (bytes(uri_).length == 0) revert WhatSwapzCollection_EmptyUri();
		uint256 packageUnitsLength = packageUnits_.length;
		if (
			packageUnitsLength == 0 ||
			packageUnitsLength != packagePrices_.length
		) revert WhatSwapzCollection_InvalidNumOfPackages();
		uint256 rarityLength = rarity_.length;
		if (rarityLength == 0) revert WhatSwapzCollection_EmptyRariry();

		// Set state variables.
		_factory = IWhatSwapzFactory(msg.sender);
		name = name_;
		_uri = uri_;
		_packageUnits = packageUnits_;
		_packagePrices = packagePrices_;
		_rarity = rarity_;

		// Calculate and set _raritySum. Check for invalid rarity values.
		uint16 raritySumLocal;
		for (uint256 i = 0; i < rarityLength; ++i) {
			uint8 rarityValue = rarity_[i];
			if (rarityValue == 0 || rarityValue > _MAX_RARITY_VALUE)
				revert WhatSwapzCollection_InvalidRarityValue();
			raritySumLocal += rarity_[i];
		}
		_raritySum = raritySumLocal;

		// Set _packages mapping. Check for invalid package number of units of price.
		for (uint256 i = 0; i < packageUnitsLength; ++i) {
			uint256 packageUnits = packageUnits_[i];
			if (packageUnits == 0 || packageUnits > _MAX_PACKAGE_UNITS)
				revert WhatSwapzCollection_InvalidPackageUnits();

			uint256 packagePrice = packagePrices_[i];
			if (packagePrice == 0)
				revert WhatSwapzCollection_InvalidPackagePrice();
			_packages[packageUnits_[i]] = packagePrice;
		}
	}

	// ======================= GETTERS =============================

	/// @notice Get collection URI. It relies on the token type ID substitution mechanism:
	/// 	 	https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	/// 	 	Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
	/// @param id - ID of the NFT. This param is not used, but included in the function to comply with the EIP-1155.
	/// @return _uri - Shared URI for all NFTs of the collection
	function uri(uint256 id) public view override returns (string memory) {
		return _uri;
	}

	/// @notice Get units and prices of collection's available packages.
	/// @return packageUnits - Array of the package sizes of the collection.
	/// @return packagePrices - Array of the prices for the package sizes of the collection.
	function getPackageInfo()
		external
		view
		returns (uint8[] memory packageUnits, uint256[] memory packagePrices)
	{
		packageUnits = _packageUnits;
		packagePrices = _packagePrices;
	}

	/// @notice Get rarity values.
	/// @return _rarity - Array of the rarity values for each NFT of the collection.
	function getRarity() external view returns (uint8[] memory) {
		return (_rarity);
	}

	// ======================= PURCHASE ============================

	function testBuyPackage(uint8 units) external payable {
		// Check if `units` matches a valid package size and value sent is equal to the price of the package.
		if (msg.value == 0 || _packages[units] != msg.value)
			revert WhatSwapzCollection_InvalidValueSent();

		// Send MATIC to the owner of the collection.
		(bool success, ) = owner.call{ value: msg.value }("");
		if (!success) revert WhatSwapzCollection_TransferFailed();

		// Request random words to factory contract and store the VRF request ID.
		// uint256 requestId = _factory.requestRandomWords(units);
		// _pendingOrders[requestId] = msg.sender;

		emit OrderCreated(msg.sender, units, 1);
	}

	/// @notice Buy a package of random NFTs from the collection.
	/// @param units - Number of units of the package to buy.
	function buyPackage(uint8 units) external payable {
		// Check if `units` matches a valid package size and value sent is equal to the price of the package.
		if (msg.value == 0 || _packages[units] != msg.value)
			revert WhatSwapzCollection_InvalidValueSent();

		// Send MATIC to the owner of the collection.
		(bool success, ) = owner.call{ value: msg.value }("");
		if (!success) revert WhatSwapzCollection_TransferFailed();

		// Request random words to factory contract and store the VRF request ID.
		uint256 requestId = _factory.requestRandomWords(units);
		_pendingOrders[requestId] = msg.sender;

		emit OrderCreated(msg.sender, units, requestId);
	}

	/// @notice Process an open order. This function is to be called by the factory contract, once it has
	///			received the random words from Chainlink.
	/// @param requestId - VRF request ID.
	/// @param randomWords - Array of random words with a length equal to the number of units of the order.
	function processOrder(uint256 requestId, uint256[] memory randomWords)
		external
	{
		if (msg.sender != address(_factory))
			revert WhatSwapzCollection_SenderNotWhatSwapzFactory();

		address buyer = _pendingOrders[requestId];
		if (buyer == address(0))
			revert WhatSwapzCollection_PendingOrderNotFound();

		uint256 numWords = randomWords.length;
		uint256[] memory tokenIds = new uint256[](numWords);
		uint256[] memory amounts = new uint256[](numWords);

		// Get random IDs from the list of random words. The chance of getting a specific NFT is determined
		// by its corresponding value in the _rarity array.
		for (uint256 i = 0; i < numWords; ++i) {
			uint256 normalizedRandomNum = randomWords[i] % _raritySum;
			uint16 currValue;
			for (uint256 j = 0; j < _rarity.length; ++j) {
				currValue += _rarity[j];
				if (normalizedRandomNum < currValue) {
					tokenIds[i] = j + 1;
					amounts[i] = 1;
					break;
				}
			}
		}

		// Mint NFTs for the buyer of the package.
		_batchMint(buyer, tokenIds, amounts, "");

		// Update the order in the _pendingOrders mapping.
		_pendingOrders[requestId] = address(0x0);

		emit OrderProcessed(buyer, requestId, tokenIds);
	}

	// ======================= SWAP ================================

	/// @notice Process an open order. This function is to be called by the factory contract, once it has
	///			received the random words from Chainlink.
	/// @param nftsOffered - Array with the IDs of the NFTs offered by the creator of the swap offer.
	/// @param nftsDemanded - Array with the IDs of the NFTs demanded by the creator of the swap offer.
	/// @param to - Owner of the `nftsDemanded` to whom the offer is addressed.
	/// @return swapId - ID of the new swap offer.
	function createSwapOffer(
		uint256[] calldata nftsOffered,
		uint256[] calldata nftsDemanded,
		address to
	) external ownsAll(to, nftsDemanded) returns (uint256 swapId) {
		uint256 nftsOfferedLength = nftsOffered.length;
		uint256 nftsDemandedLength = nftsDemanded.length;
		if (
			nftsOfferedLength == 0 ||
			nftsOfferedLength > _MAX_SWAP_ITEMS ||
			nftsDemandedLength == 0 ||
			nftsDemandedLength > _MAX_SWAP_ITEMS
		) revert WhatSwapzCollection_MaxSwapItemsExceeded();

		// Lock offered NFTs in the contract.
		_lockNfts(nftsOffered);

		// Create Swap struct and store it.
		swapId = ++swapCounter;
		_swaps[swapId] = Swap({
			ownerA: msg.sender,
			ownerB: to,
			nftsA: nftsOffered,
			nftsB: nftsDemanded,
			state: SwapState.OFFERED
		});

		emit SwapOfferCreated(
			swapId,
			msg.sender,
			to,
			nftsOffered,
			nftsDemanded
		);
	}

	/// @notice Cancel an open swap offer. Only the creator of the swap offer is allowed.
	/// @param swapId - ID of the swap to be cancelled.
	function cancelSwapOffer(uint256 swapId) external {
		Swap memory swap = _swaps[swapId];
		if (swap.ownerA != msg.sender)
			revert WhatSwapzCollection_NotOfferOwner();
		if (_swaps[swapId].state != SwapState.OFFERED)
			revert WhatSwapzCollection_NotOpenOffer();

		// Unlock offered NFTs.
		_unlockNfts(msg.sender, swap.nftsA);

		// Update state of the Swap.
		_swaps[swapId].state = SwapState.CANCELLED;

		emit SwapOfferUpdated(swapId, SwapState.CANCELLED);
	}

	/// @notice Reject an open swap offer. Only the receiver of the swap is allowed.
	/// @param swapId - ID of the swap to be rejected.
	function rejectSwapOffer(uint256 swapId) external {
		Swap memory swap = _swaps[swapId];
		if (swap.ownerB != msg.sender)
			revert WhatSwapzCollection_NotDemandedOwner();
		if (_swaps[swapId].state != SwapState.OFFERED)
			revert WhatSwapzCollection_NotOpenOffer();

		// Unlock offered NFTs.
		_unlockNfts(swap.ownerA, swap.nftsA);

		// Update state of the Swap.
		_swaps[swapId].state = SwapState.REJECTED;

		emit SwapOfferUpdated(swapId, SwapState.REJECTED);
	}

	/// @notice Accept an open swap offer. Only the receiver of the swap is allowed.
	/// @param swapId - ID of the swap to be accepted.
	function acceptSwapOffer(uint256 swapId) external {
		Swap memory swap = _swaps[swapId];
		if (swap.ownerB != msg.sender)
			revert WhatSwapzCollection_NotDemandedOwner();
		if (_swaps[swapId].state != SwapState.OFFERED)
			revert WhatSwapzCollection_NotOpenOffer();

		// Transfer ownerB's NFTs to ownerA.
		uint256 id;
		uint256 nftIdsLength = swap.nftsB.length;
		for (uint256 i = 0; i < nftIdsLength; ) {
			id = swap.nftsB[i];
			balanceOf[msg.sender][id]--;
			balanceOf[swap.ownerA][id]++;
			unchecked {
				++i;
			}
		}

		// Transfer ownerA's locked NFTs to ownerB.
		_unlockNfts(msg.sender, swap.nftsA);

		// Update state of the Swap.
		_swaps[swapId].state = SwapState.EXECUTED;

		emit SwapOfferUpdated(swapId, SwapState.EXECUTED);
	}

	/// @notice Get all the data of a Swap.
	/// @param swapId - ID of the Swap to be retrieved.
	/// @return ownerA - Creator of the swap offer.
	/// @return ownerB - Receiver of the swap offer.
	/// @return nftsA - Array of NFTs offered by the creator.
	/// @return nftsB - Array of NFTs demanded by the creator.
	/// @return state - Current state of the swap.
	function getSwap(uint256 swapId)
		external
		view
		returns (
			address ownerA,
			address ownerB,
			uint256[] memory nftsA,
			uint256[] memory nftsB,
			SwapState state
		)
	{
		if (swapId == 0 || swapId > swapCounter)
			revert WhatSwapzCollection_SwapNotFound();

		Swap memory swap = _swaps[swapId];
		ownerA = swap.ownerA;
		ownerB = swap.ownerB;
		nftsA = swap.nftsA;
		nftsB = swap.nftsB;
		state = swap.state;
	}

	// ======================= PRIVATE FUNCTIONS ===================

	/// @notice Lock offered NFTs in the contract.
	/// @param nftIds - Array with the NFTs IDs to be locked.
	function _lockNfts(uint256[] calldata nftIds)
		private
		ownsAll(msg.sender, nftIds)
	{
		uint256 id;
		uint256 nftIdsLength = nftIds.length;

		for (uint256 i = 0; i < nftIdsLength; ) {
			id = nftIds[i];
			balanceOf[msg.sender][id]--;
			balanceOf[address(this)][id]++;
			unchecked {
				++i;
			}
		}
	}

	/// @notice Send back to `tokenOwner` the offered NFTs previusly locked in the contract.
	/// @param tokenOwner - Owner of the NFTs.
	/// @param nftIds - Array with the NFTs IDs to be unlocked.
	function _unlockNfts(address tokenOwner, uint256[] memory nftIds) private {
		uint256 id;
		uint256 nftIdsLength = nftIds.length;

		for (uint256 i = 0; i < nftIdsLength; ) {
			id = nftIds[i];
			balanceOf[address(this)][id]--;
			balanceOf[tokenOwner][id]++;
			unchecked {
				++i;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IWhatSwapzFactory
/// @notice Minimal interface of the WhatSwapzFactory contract, containing only the `requestRandomWords` function.
interface IWhatSwapzFactory {
	/// @notice Request random words to Chainlink.
	/// @param numWords - Number of words requested.
	/// @return requestId - VRF request ID.
	function requestRandomWords(uint32 numWords)
		external
		returns (uint256 requestId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}