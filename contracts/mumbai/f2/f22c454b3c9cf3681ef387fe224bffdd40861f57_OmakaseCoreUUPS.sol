// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./facets/AccessControlFacet.sol";
import "./facets/ClaimFacet.sol";
import "./facets/DataFacet.sol";
import "./facets/FlightStatusFacet.sol";
import "./facets/PolicyCreationFacet.sol";
import "./facets/ProductCreationFacet.sol";
import "./proxy/utils/Initializable.sol";
import "./proxy/utils/UUPSUpgradeable.sol";

contract OmakaseCoreUUPS is
    AccessControlFacet,
    ClaimFacet,
    DataFacet,
    FlightStatusFacet,
    PolicyCreationFacet,
    ProductCreationFacet,
    Initializable,
    UUPSUpgradeable
{
    function initialize(address admin_, address oracle_) external initializer {
        s.admin = admin_;
        s.claimExpireTime = 30 days;
        s.oracle = oracle_;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibValidations.sol";

contract AccessControlFacet is Modifiers, InheritedStorage {
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    function oracle() external view returns (address) {
        return s.oracle;
    }

    function setOracle(address _oracle) external onlyAdmin {
        LibValidations.validateAddress(_oracle);

        address oldOracle = s.oracle;
        s.oracle = _oracle;
        emit OracleChanged(oldOracle, _oracle);
    }

    function admin() external view returns (address) {
        return s.admin;
    }

    function setAdmin(address _admin) external onlyAdmin {
        LibValidations.validateAddress(_admin);

        address oldAdmin = s.admin;
        s.admin = _admin;
        emit AdminChanged(oldAdmin, _admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../enums/BenefitName.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/entities/BenefitFlightDelay.sol";
import "../libraries/LibValidations.sol";

contract ClaimFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibPolicy for Policy;
    using LibFlight for Flight;
    using LibBenefitFlightDelay for BenefitFlightDelay;

    error ClaimExpired(uint64 timeInitiated, uint64 expiredTime);
    error BenefitClaimNotImplemented(BenefitName benefitName);
    error FlightHasNotDeparted(bytes32 flightId);
    error ProductDoesNotHaveTheBenefit(
        bytes32 productId,
        BenefitName benefitName
    );
    error BenefitAlreadyClaimed(
        bytes32 policyId,
        bytes32 flightId,
        BenefitName benefitName
    );

    event ClaimExpireTimeChanged(uint64 previousTime, uint64 newTime);
    event BenefitClaimed(
        bytes32 indexed policyId,
        bytes32 indexed flightId,
        BenefitName indexed benefitName,
        uint64 amount
    );

    function setClaimExpireTime(uint64 claimExpireTime) external onlyAdmin {
        uint64 previousTime = s.claimExpireTime;
        s.claimExpireTime = claimExpireTime;

        emit ClaimExpireTimeChanged(previousTime, claimExpireTime);
    }

    function claimBenefit(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) external onlyOracle {
        LibValidations.ensureFlightExists(flightId);
        LibValidations.ensurePolicyExists(policyId);
        ensureClaimIsNotExpired(flightId);
        ensureHasNotBeenClaimed(flightId, policyId, benefitName);

        uint64 amount = calculateClaim(flightId, policyId, benefitName);
        s.policies[policyId].claimedAmounts[benefitName] += amount;
        s.policies[policyId].hasClaimed[flightId][benefitName] = true;

        emit BenefitClaimed(policyId, flightId, benefitName, amount);
    }

    function calculateClaim(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) public view returns (uint64) {
        Policy storage policy = s.policies[policyId];

        if (benefitName == BenefitName.FlightDelay) {
            return
                calculateClaimForFlightDelay(
                    flightId,
                    policy.productId,
                    policy.claimedAmounts[BenefitName.FlightDelay]
                );
        } else {
            revert BenefitClaimNotImplemented(benefitName);
        }
    }

    function calculateClaimForFlightDelay(
        bytes32 flightId,
        bytes32 productId,
        uint64 claimedAmount
    ) private view returns (uint64) {
        ensureProductHasBenefit(productId, BenefitName.FlightDelay);

        Flight storage flight = s.flights[flightId];

        if (!flight.hasDeparted()) revert FlightHasNotDeparted(flightId);

        return
            uint64(
                s.products[productId].benefitFlightDelay.calculateIndemnity(
                    claimedAmount,
                    flight.scheduledDepartureTime,
                    flight.actualDepartureTime
                )
            );
    }

    function ensureProductHasBenefit(bytes32 productId, BenefitName benefitName)
        private
        view
    {
        if (!s.products[productId].hasBenefit(benefitName)) {
            revert ProductDoesNotHaveTheBenefit(productId, benefitName);
        }
    }

    function ensureClaimIsNotExpired(bytes32 flightId) internal view {
        uint64 timeInitiated = s.flights[flightId].timeChecked;
        uint64 timeExpired = timeInitiated + s.claimExpireTime;
        if (block.timestamp >= timeExpired) {
            revert ClaimExpired(timeInitiated, timeExpired);
        }
    }

    function ensureHasNotBeenClaimed(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) internal view {
        if (s.policies[policyId].hasClaimed[flightId][benefitName]) {
            revert BenefitAlreadyClaimed(policyId, flightId, benefitName);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";
import "../libraries/entities/BenefitFlightDelay.sol";
import "../libraries/entities/BenefitBaggageDelay.sol";
import "../libraries/entities/BenefitFlightPostponement.sol";
import "../libraries/LibFlightsToCheck.sol";

contract DataFacet is InheritedStorage {
    using LibProduct for Product;
    using LibFlight for Flight;

    function hasProduct(bytes32 productId) external view returns (bool) {
        return !s.products[productId].isEmpty();
    }

    function getBenefitPersonalAccident(bytes32 productId)
        external
        view
        returns (BenefitPersonalAccident memory)
    {
        return s.products[productId].benefitPersonalAccident;
    }

    function getBenefitFlightDelay(bytes32 productId)
        external
        view
        returns (BenefitFlightDelay memory)
    {
        return s.products[productId].benefitFlightDelay;
    }

    function getBenefitBaggageDelay(bytes32 productId)
        external
        view
        returns (BenefitBaggageDelay memory)
    {
        return s.products[productId].benefitBaggageDelay;
    }

    function getBenefitFlightPostponement(bytes32 productId)
        external
        view
        returns (BenefitFlightPostponement memory)
    {
        return s.products[productId].benefitFlightPostponement;
    }

    function getProductBenefits(bytes32 productId)
        external
        view
        returns (BenefitName[] memory)
    {
        return s.products[productId].benefits;
    }

    /*-------------------------------------------------------------------------*/
    // Oracle

    function pendingRequest(bytes32 requestId) external view returns (uint256) {
        return s.pendingRequest[requestId];
    }

    /*-------------------------------------------------------------------------*/
    // Policy

    function getPolicyUserHash(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].userHash;
    }

    function getPolicyProductId(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].productId;
    }

    function totalPolicies() external view returns (uint256) {
        return s.totalPolicies;
    }

    /*-------------------------------------------------------------------------*/
    // Claim

    function getClaimedAmount(bytes32 policyId, BenefitName benefitName)
        external
        view
        returns (uint64)
    {
        return s.policies[policyId].claimedAmounts[benefitName];
    }

    /*-------------------------------------------------------------------------*/
    // Flight

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return s.flights[flightId];
    }

    function hasFlight(bytes32 flightId) external view returns (bool) {
        return !s.flights[flightId].isEmpty();
    }

    function totalFlights() external view returns (uint256) {
        return s.totalFlights;
    }

    function getFlightsToCheck() external pure returns (bytes32[] memory) {
        return LibFlightsToCheck.getArray();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../dependencies/KeeperCompatibleInterface.sol";
import "../libraries/LibFlightsToCheck.sol";
import "../libraries/LibOracle.sol";
import "../libraries/LibValidations.sol";
import "../libraries/helpers/LibBytes.sol";
import "../libraries/entities/Flight.sol";
import "../enums/FlightStatus.sol";

contract FlightStatusFacet is
    Modifiers,
    InheritedStorage,
    KeeperCompatibleInterface
{
    using LibFlight for Flight;
    using LibBytes for bytes;

    error FlightTimeHasAlreadyBeenAssigned(bytes32 id);
    error InvalidArrivalTime(bytes32 id, uint64 time);
    error InvalidScheduledDepartureTime(bytes32 id, uint64 time);
    error UpdateExceedsMaximumRetries(bytes32 flightId, uint8 nRetries);

    event MissingFlightStatus(bytes32 indexed flightId);
    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        FsFlightStatus status,
        uint256 actualDepartureTime
    );
    event FlightTimeChanged(
        bytes32 indexed id,
        uint64 newScheduledDepartureTime,
        uint64 newArrivalTime
    );

    function updateFlightTime(
        bytes32 id,
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) external onlyAdmin {
        if (
            scheduledDepartureTime == 0 ||
            scheduledDepartureTime == LibFlight.NULL_SCHEDULED_DEPARTURE_TIME
        ) {
            revert InvalidScheduledDepartureTime(id, scheduledDepartureTime);
        }
        if (arrivalTime == 0 || arrivalTime <= scheduledDepartureTime) {
            revert InvalidArrivalTime(id, arrivalTime);
        }

        LibValidations.ensureFlightExists(id);
        Flight storage flight = s.flights[id];

        if (
            flight.scheduledDepartureTime !=
            LibFlight.NULL_SCHEDULED_DEPARTURE_TIME
        ) {
            revert FlightTimeHasAlreadyBeenAssigned(id);
        }

        flight.scheduledDepartureTime = scheduledDepartureTime;
        LibFlightsToCheck.insert(id, arrivalTime);

        emit FlightTimeChanged(id, scheduledDepartureTime, arrivalTime);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32[] storage arr = LibFlightsToCheck.getArray();

        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 flightId = arr[i];
            if (!s.flights[flightId].needCheck()) {
                continue;
            } else if (performData.length / 32 > 60) {
                break;
            }

            performData = abi.encodePacked(performData, flightId);
        }

        upkeepNeeded = performData.length >= 32;
    }

    function performUpkeep(bytes memory performData) external override {
        performData.loopBytes32(checkFlight);
    }

    function checkFlight(bytes32 flightId) private {
        Flight storage flight = s.flights[flightId];

        if (!flight.needCheck()) {
            return;
        }

        LibOracle.requestStatusUpdate(flightId);
        LibFlightsToCheck.remove(flightId);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        FsFlightStatus status,
        uint256 actualDepartureTime
    ) external oracleCallback(requestId) {
        if (isCancelled(status)) {
            emit FlightStatusUpdate(
                requestId,
                flightId,
                status,
                actualDepartureTime
            );
            return;
        }

        Flight storage flight = s.flights[flightId];
        if (isDeparted(status)) {
            flight.actualDepartureTime = uint64(actualDepartureTime);
            flight.timeChecked = uint64(block.timestamp);
        } else if (flight.nRetries >= 4) {
            emit MissingFlightStatus(flightId);
        } else {
            LibFlightsToCheck.insert(
                flightId,
                uint64(block.timestamp + 12 hours)
            );
            flight.nRetries++;
        }

        emit FlightStatusUpdate(
            requestId,
            flightId,
            status,
            actualDepartureTime
        );
    }

    function isDeparted(FsFlightStatus status) private pure returns (bool) {
        return
            status == FsFlightStatus.Active || status == FsFlightStatus.Landed;
    }

    function isCancelled(FsFlightStatus status) private pure returns (bool) {
        return
            status == FsFlightStatus.Canceled ||
            status == FsFlightStatus.Diverted ||
            status == FsFlightStatus.Redirected;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/LibFlightsToCheck.sol";
import "../libraries/LibValidations.sol";

struct CreatePolicyInput {
    bytes32 userHash;
    bytes32 productId;
    bytes32 transactionId1;
    bytes32 transactionId2;
}

struct CreateFlightInput {
    bytes32 id;
    uint64 scheduledDepartureTime;
    uint64 arrivalTime;
}

contract PolicyCreationFacet is Modifiers, InheritedStorage {
    using LibPolicy for Policy;
    using LibProduct for Product;
    using LibFlight for Flight;

    error FlightPolicyHasAlreadyBeenClaimed(bytes32 flightId, bytes32 policyId);
    error PolicyAlreadyHasFlight(bytes32 id);
    error UnmatchedFlightsArrayLength(
        uint256 prevArrayLen,
        uint256 newArrayLen
    );
    error InvalidPolicyId(bytes32 id);
    error InvalidUserHash(bytes32 userHash);
    error InvalidFlightId(bytes32 id);
    error UnknownProduct(bytes32 id);
    error PolicyAlreadyExists(bytes32 id);
    error FlightPolicyAlreadyExists(bytes32 flightId, bytes32 policyId);
    error UnknownFlightPolicy(bytes32 flightId, bytes32 policyId);
    error InvalidDepartureTime(uint64 departureTime);

    event PolicyCreated(bytes32 indexed policyId);
    event NewFlight(bytes32 indexed flightId);

    event FlightPolicyUpdated(
        bytes32 indexed policyId,
        bytes32 previousFlightId,
        bytes32 newFlightId
    );
    event FlightPolicyAdded(bytes32 indexed policyId, bytes32 indexed flightId);

    function createPolicy(bytes32 policyId, CreatePolicyInput calldata input)
        external
        onlyOracle
    {
        _createPolicy(policyId, input);
    }

    function createPolicyWithFlights(
        bytes32 policyId,
        CreatePolicyInput calldata policyInput,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        _createPolicy(policyId, policyInput);
        _setFlightPolicies(policyId, flightsInput);
    }

    function setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        LibValidations.ensurePolicyExists(policyId);

        if (s.policies[policyId].hasFlight) {
            revert PolicyAlreadyHasFlight(policyId);
        }

        _setFlightPolicies(policyId, flightsInput);
    }

    function updateFlightPolicies(
        bytes32 policyId,
        bytes32[] calldata prevFlightIds,
        CreateFlightInput[] calldata newFlightsInput
    ) external onlyOracle {
        LibValidations.ensurePolicyExists(policyId);

        if (prevFlightIds.length != newFlightsInput.length) {
            revert UnmatchedFlightsArrayLength(
                prevFlightIds.length,
                newFlightsInput.length
            );
        }

        for (uint256 i = 0; i < prevFlightIds.length; i++) {
            removeFlightPolicy(policyId, prevFlightIds[i]);
            addFlightPolicy(policyId, newFlightsInput[i]);

            emit FlightPolicyUpdated(
                policyId,
                prevFlightIds[i],
                newFlightsInput[i].id
            );
        }
    }

    function _createPolicy(bytes32 id, CreatePolicyInput calldata input)
        private
    {
        if (id == 0) revert InvalidPolicyId(id);
        if (s.products[input.productId].isEmpty())
            revert UnknownProduct(input.productId);
        if (input.userHash == 0) revert InvalidUserHash(input.userHash);

        Policy storage policy = s.policies[id];
        if (!policy.isEmpty()) revert PolicyAlreadyExists(id);

        policy.initialize(
            input.userHash,
            input.productId,
            input.transactionId1,
            input.transactionId2
        );
        s.totalPolicies++;

        emit PolicyCreated(id);
    }

    function _setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) private {
        Policy storage policy = s.policies[policyId];

        for (uint256 i = 0; i < flightsInput.length; i++) {
            if (policy.hasParticularFlight[flightsInput[i].id]) {
                revert FlightPolicyAlreadyExists(flightsInput[i].id, policyId);
            }

            addFlightPolicy(policyId, flightsInput[i]);
        }

        policy.hasFlight = true;
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function addFlightPolicy(
        bytes32 policyId,
        CreateFlightInput calldata flightInput
    ) private {
        Flight storage flight = s.flights[flightInput.id];
        if (flight.isEmpty()) {
            createFlight(
                flightInput.id,
                flightInput.scheduledDepartureTime,
                flightInput.arrivalTime
            );
        }

        s.policies[policyId].hasParticularFlight[flightInput.id] = true;

        emit FlightPolicyAdded(policyId, flightInput.id);
    }

    /**
     * @dev Flight is expected to be empty
     */
    function createFlight(
        bytes32 id,
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) private {
        if (id == 0) revert InvalidFlightId(id);

        Flight storage flight = s.flights[id];

        if (
            scheduledDepartureTime != 0 &&
            scheduledDepartureTime != LibFlight.NULL_SCHEDULED_DEPARTURE_TIME &&
            arrivalTime != 0
        ) {
            flight.scheduledDepartureTime = scheduledDepartureTime;
            LibFlightsToCheck.insert(id, arrivalTime);
        } else {
            flight.scheduledDepartureTime = LibFlight
                .NULL_SCHEDULED_DEPARTURE_TIME;
        }

        s.totalFlights++;

        emit NewFlight(id);
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function removeFlightPolicy(bytes32 policyId, bytes32 flightId) private {
        Policy storage policy = s.policies[policyId];

        if (!policy.hasParticularFlight[flightId])
            revert UnknownFlightPolicy(flightId, policyId);
        if (policy.hasClaimed[flightId][BenefitName.FlightDelay])
            revert FlightPolicyHasAlreadyBeenClaimed(flightId, policyId);

        delete policy.hasParticularFlight[flightId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";

contract ProductCreationFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibBenefitPersonalAccident for BenefitPersonalAccident;

    error InvalidProductId(bytes32 id);
    error ProductAlreadyExists(bytes32 id);
    error MissingBenefitPersonalAccident();

    event NewProduct(bytes32 indexed productId, BenefitName[] benefits);

    function createProduct(
        bytes32 productId,
        BenefitInitInput[] calldata benefits
    ) external onlyOracle {
        if (productId == 0) revert InvalidProductId(productId);
        Product storage product = s.products[productId];

        if (!product.isEmpty()) revert ProductAlreadyExists(productId);

        product.initialize(benefits);

        if (product.benefitPersonalAccident.isEmpty()) {
            revert MissingBenefitPersonalAccident();
        }

        emit NewProduct(productId, product.benefits);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibOracle.sol";
import "../libraries/LibAppStorage.sol";

abstract contract Modifiers {
    error CallerIsNotAdmin(address caller);

    modifier onlyOracle() {
        LibOracle.enforceCallerIsOracle();
        _;
    }

    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        if (msg.sender != s.admin) revert CallerIsNotAdmin(msg.sender);
        _;
    }

    modifier oracleCallback(bytes32 requestId) {
        LibOracle.handleOracleCallback(requestId);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";

abstract contract InheritedStorage {
    AppStorage internal s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => Product) products;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
    address admin;
    uint64 claimExpireTime;
    // Oracle
    mapping(bytes32 => uint256) pendingRequest;
    uint256 requestCount;
    address oracle;
}

struct AddressSlot {
    address value;
}

struct BooleanSlot {
    bool value;
}

struct Bytes32Slot {
    bytes32 value;
}

struct Uint256Slot {
    uint256 value;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    /**
     * @notice manual import @openzeppelin/contracts/utils/StorageSlot.sol
     */
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LibAppStorage.sol";
import "./entities/Flight.sol";
import "./entities/Policy.sol";

library LibValidations {
    using LibFlight for Flight;
    using LibPolicy for Policy;

    error UnknownFlight(bytes32 id);
    error UnknownPolicy(bytes32 id);
    error InvalidAddress(address addr);

    function ensureFlightExists(bytes32 id) internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.flights[id].isEmpty()) {
            revert UnknownFlight(id);
        }
    }

    function ensurePolicyExists(bytes32 id) internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.policies[id].isEmpty()) {
            revert UnknownPolicy(id);
        }
    }

    function validateAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidAddress(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../enums/OracleJob.sol";
import "./LibAppStorage.sol";

library LibOracle {
    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);

    error CallerIsNotOracle(address caller);
    error UnknownOracleRequest(bytes32 id);

    function enforceCallerIsOracle() internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (msg.sender != s.oracle) revert CallerIsNotOracle(msg.sender);
    }

    function handleOracleCallback(bytes32 requestId) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        enforceCallerIsOracle();
        if (s.pendingRequest[requestId] == 0)
            revert UnknownOracleRequest(requestId);

        emit OracleFulfilled(requestId);
        delete s.pendingRequest[requestId];
    }

    function requestStatusUpdate(bytes32 flightId) internal {
        bytes32 requestId = createRequest();

        emit OracleRequested(
            requestId,
            OracleJob.StatusUpdate,
            abi.encodePacked(flightId)
        );
    }

    function createRequest() private returns (bytes32 requestId) {
        AppStorage storage s = LibAppStorage.appStorage();

        s.requestCount += 1;
        requestId = keccak256(abi.encodePacked(s.requestCount));
        s.pendingRequest[requestId] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum OracleJob {
    StatusUpdate
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../enums/BenefitName.sol";

struct Policy {
    bytes32 userHash;
    bytes32 productId;
    bytes32 transactionId1;
    bytes32 transactionId2;
    bool hasFlight;
    mapping(BenefitName => uint64) claimedAmounts;
    mapping(bytes32 => mapping(BenefitName => bool)) hasClaimed;
    mapping(bytes32 => bool) hasParticularFlight;
}

library LibPolicy {
    function initialize(
        Policy storage self,
        bytes32 userHash,
        bytes32 productId,
        bytes32 transactionId1,
        bytes32 transactionId2
    ) internal {
        self.userHash = userHash;
        self.productId = productId;
        self.transactionId1 = transactionId1;
        self.transactionId2 = transactionId2;
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.userHash == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../enums/BenefitName.sol";
import "./BenefitFlightDelay.sol";
import "./BenefitPersonalAccident.sol";
import "./BenefitBaggageDelay.sol";
import "./BenefitFlightPostponement.sol";

struct BenefitInitInput {
    BenefitName name;
    bytes data;
}

struct Product {
    BenefitName[] benefits;
    BenefitPersonalAccident benefitPersonalAccident;
    BenefitFlightDelay benefitFlightDelay;
    BenefitBaggageDelay benefitBaggageDelay;
    BenefitFlightPostponement benefitFlightPostponement;
}

library LibProduct {
    using LibBenefitPersonalAccident for BenefitPersonalAccident;
    using LibBenefitFlightDelay for BenefitFlightDelay;
    using LibBenefitBaggageDelay for BenefitBaggageDelay;
    using LibBenefitFlightPostponement for BenefitFlightPostponement;

    error DuplicateBenefit(BenefitName benefitName);
    error UnknownBenefitName(uint8 benefitName);

    function initialize(
        Product storage self,
        BenefitInitInput[] calldata benefits
    ) internal {
        for (uint256 i = 0; i < benefits.length; i++) {
            if (benefits[i].name == BenefitName.PersonalAccident) {
                if (!self.benefitPersonalAccident.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitPersonalAccident.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightDelay) {
                if (!self.benefitFlightDelay.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitFlightDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.BaggageDelay) {
                if (!self.benefitBaggageDelay.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitBaggageDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightPostponement) {
                if (!self.benefitFlightPostponement.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitFlightPostponement.initialize(benefits[i].data);
            } else if (
                benefits[i].name == BenefitName.TripCancellation
            ) {} else {
                revert UnknownBenefitName(uint8(benefits[i].name));
            }

            self.benefits.push(benefits[i].name);
        }
    }

    function hasBenefit(Product storage self, BenefitName benefitName)
        internal
        view
        returns (bool)
    {
        uint256 len = self.benefits.length;
        for (uint256 i = 0; i < len; i++) {
            if (self.benefits[i] == benefitName) {
                return true;
            }
        }

        return false;
    }

    function isEmpty(Product storage self) internal view returns (bool) {
        return self.benefitPersonalAccident.isEmpty();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Flight {
    uint64 scheduledDepartureTime;
    uint64 actualDepartureTime;
    uint64 timeChecked;
    uint64 nextCheck;
    uint8 nRetries;
    uint256 idxInFlightsToCheck;
}

library LibFlight {
    uint64 constant NULL_SCHEDULED_DEPARTURE_TIME = type(uint64).max;

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.scheduledDepartureTime == 0;
    }

    function needCheck(Flight storage self) internal view returns (bool) {
        if (self.actualDepartureTime != 0) {
            return false;
        }

        // Gas eficient way to check if flight is valid
        // since `nextCheck` will always be assigned in creation
        // Otherwise, actualDepartureTime won't be zero
        uint64 nextCheck = self.nextCheck;
        if (nextCheck == 0) {
            revert("Unknown flight");
        }

        return block.timestamp >= nextCheck;
    }

    function hasDeparted(Flight storage self) internal view returns (bool) {
        return self.actualDepartureTime != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum BenefitName {
    PersonalAccident,
    FlightDelay,
    BaggageDelay,
    TripCancellation,
    FlightPostponement
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitFlightDelay {
    uint8 delayInterval;
    uint64 maximumAmount;
    uint64 amountPerInterval;
}

library LibBenefitFlightDelay {
    error InvalidDelayInterval(uint8 delayInterval);
    error InvalidAmountPerInterval(uint64 amountPerInterval);

    function initialize(BenefitFlightDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayInterval;
        uint64 amountPerInterval;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayInterval := mload(add(data, 9))
            amountPerInterval := mload(add(data, 17))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }
        if (delayInterval == 0) revert InvalidDelayInterval(delayInterval);
        if (amountPerInterval == 0)
            revert InvalidAmountPerInterval(amountPerInterval);

        self.maximumAmount = uint64(maximumAmount);
        self.delayInterval = uint8(delayInterval);
        self.amountPerInterval = uint64(amountPerInterval);
    }

    /**
     * @dev Should only be called if it's `eligibleForClaim`.
     * Otherwise, it could throw a 'division by zero' error or
     * returns zero
     */
    function calculateIndemnity(
        BenefitFlightDelay storage self,
        uint64 claimedIndemnity,
        uint64 scheduledTime,
        uint64 actualTime
    ) internal view returns (uint64 indemnity) {
        int64 diff = int64(actualTime - scheduledTime);
        if (diff < 1 hours) return 0;

        indemnity = uint64(
            ((uint64(diff) / 1 hours) / self.delayInterval) *
                self.amountPerInterval
        );

        uint64 remaining = self.maximumAmount - claimedIndemnity;
        if (indemnity > remaining) {
            indemnity = remaining;
        }
    }

    function isEmpty(BenefitFlightDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitPersonalAccident {
    uint64 maximumAmount;
}

library LibBenefitPersonalAccident {
    function initialize(BenefitPersonalAccident storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
    }

    function isEmpty(BenefitPersonalAccident storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitBaggageDelay {
    uint8 delayHour;
    uint64 maximumAmount;
}

library LibBenefitBaggageDelay {
    error InvalidDelayHour(uint8 delayHour);

    function initialize(BenefitBaggageDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayHour;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayHour := mload(add(data, 9))
        }

        if (delayHour == 0) revert InvalidDelayHour(delayHour);
        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
        self.delayHour = delayHour;
    }

    function isEmpty(BenefitBaggageDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitFlightPostponement {
    uint64 maximumAmount;
}

library LibBenefitFlightPostponement {
    function initialize(
        BenefitFlightPostponement storage self,
        bytes memory data
    ) internal {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
    }

    function isEmpty(BenefitFlightPostponement storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error InvalidMaximumAmount(uint256 maximumAmount);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";
import "./entities/Flight.sol";

library LibFlightsToCheck {
    using LibFlight for Flight;

    bytes32 constant DATA_STORAGE_POSITION =
        keccak256("omakase.flight.lib_flights_to_check.storage");

    function getArray() internal pure returns (bytes32[] storage arr) {
        bytes32 position = DATA_STORAGE_POSITION;
        assembly {
            arr.slot := position
        }
    }

    function insert(bytes32 flightId, uint64 timeToCheck) internal {
        Flight storage flight = LibAppStorage.appStorage().flights[flightId];
        bytes32[] storage arr = getArray();

        flight.nextCheck = timeToCheck;
        flight.idxInFlightsToCheck = arr.length;

        arr.push(flightId);
    }

    function remove(bytes32 flightId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32[] storage arr = getArray();

        uint256 idx = s.flights[flightId].idxInFlightsToCheck;
        delete s.flights[flightId].idxInFlightsToCheck;

        uint256 lastIdx = arr.length - 1;
        if (idx != lastIdx) {
            bytes32 replacementData = arr[lastIdx];
            arr[idx] = replacementData;
            s.flights[replacementData].idxInFlightsToCheck = idx;
        }

        arr.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice checks if the contract requires work to be done.
     * @param checkData data passed to the contract when checking for upkeep.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with,
     * if upkeep is needed.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs work on the contract. Executed by the keepers, via the registry.
     * @param performData is the data which was passed back from the checkData
     * simulation.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibBytes {
    function loopBytes32(bytes memory self, function(bytes32) func) internal {
        uint256 len = self.length / 32;
        bytes32 dataStartPos;
        bytes32 dataEndPos;
        assembly {
            dataStartPos := add(self, 32)
            dataEndPos := add(dataStartPos, mul(sub(len, 1), 32))
        }

        while (dataStartPos <= dataEndPos) {
            bytes32 item;
            assembly {
                item := mload(dataStartPos)
                dataStartPos := add(dataStartPos, 32)
            }

            func(item);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum FsFlightStatus {
    Active,
    Landed,
    Canceled,
    Diverted,
    Unknown,
    Redirected,
    NotOperational,
    Scheduled,
    DataSourceNeeded
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";

import "../../libraries/LibAppStorage.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return LibAppStorage.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        LibAppStorage.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (LibAppStorage.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    // /**
    //  * @dev Storage slot with the admin of the contract.
    //  * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    //  * validated in the constructor.
    //  */
    // bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // /**
    //  * @dev Emitted when the admin account has changed.
    //  */
    // event AdminChanged(address previousAdmin, address newAdmin);

    // /**
    //  * @dev Returns the current admin.
    //  */
    // function _getAdmin() internal view returns (address) {
    //     return LibAppStorage.getAddressSlot(_ADMIN_SLOT).value;
    // }

    // /**
    //  * @dev Stores a new address in the EIP1967 admin slot.
    //  */
    // function _setAdmin(address newAdmin) private {
    //     require(newAdmin != address(0), "ERC1967: new admin is the zero address");
    //     LibAppStorage.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    // }

    // /**
    //  * @dev Changes the admin of the proxy.
    //  *
    //  * Emits an {AdminChanged} event.
    //  */
    // function _changeAdmin(address newAdmin) internal {
    //     emit AdminChanged(_getAdmin(), newAdmin);
    //     _setAdmin(newAdmin);
    // }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return LibAppStorage.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        LibAppStorage.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}