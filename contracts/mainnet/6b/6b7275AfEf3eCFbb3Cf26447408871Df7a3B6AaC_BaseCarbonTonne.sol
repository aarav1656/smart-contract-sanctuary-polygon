// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import '../cross-chain/interfaces/IToucanCrosschainMessenger.sol';
import '../interfaces/ICarbonOffsetBatches.sol';
import '../interfaces/IToucanCarbonOffsets.sol';
import '../interfaces/IToucanContractRegistry.sol';
import '../libraries/Errors.sol';
import './BaseCarbonTonneStorage.sol';

/// @notice Base Carbon Tonne for KlimaDAO
/// Contract is an ERC20 compliant token that acts as a pool for TCO2 tokens
/// It is possible to whitelist Toucan Protocol external tokenized carbon
contract BaseCarbonTonne is
    ContextUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    BaseCarbonTonneStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ----------------------------------------
    //      Constants
    // ----------------------------------------

    string public constant VERSION = '1.5.0';
    uint256 public constant VERSION_RELEASE_CANDIDATE = 2;
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    /// @dev fees redeem percentage with 2 fixed decimals precision
    uint256 public constant feeRedeemDivider = 1e4;

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    event Deposited(address erc20Addr, uint256 amount);
    event Redeemed(address account, address erc20, uint256 amount);
    event ExternalAddressWhitelisted(address erc20addr);
    event ExternalAddressRemovedFromWhitelist(address erc20addr);
    event InternalAddressWhitelisted(address erc20addr);
    event InternalAddressBlacklisted(address erc20addr);
    event InternalAddressRemovedFromBlackList(address erc20addr);
    event InternalAddressRemovedFromWhitelist(address erc20addr);
    event AttributeStandardAdded(string standard);
    event AttributeStandardRemoved(string standard);
    event AttributeMethodologyAdded(string methodology);
    event AttributeMethodologyRemoved(string methodology);
    event AttributeRegionAdded(string region);
    event AttributeRegionRemoved(string region);
    event RedeemFeePaid(address redeemer, uint256 fees);
    event RedeemFeeBurnt(address redeemer, uint256 fees);
    event ToucanRegistrySet(address ContractRegistry);
    event MappingSwitched(string mappingName, bool accepted);
    event SupplyCapUpdated(uint256 newCap);
    event MinimumVintageStartTimeUpdated(uint256 minimumVintageStartTime);
    event TCO2ScoringUpdated(address[] tco2s);
    event AddFeeExemptedTCO2(address tco2);
    event RemoveFeeExemptedTCO2(address tco2);
    event RouterUpdated(address router);
    event TCO2Bridged(uint32 destinationDomain, address tco2, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize() external virtual initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained('Toucan Protocol: Base Carbon Tonne', 'BCT');
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address) internal virtual override {
        onlyPoolOwner();
    }

    // ------------------------
    // Poor person's modifiers
    // ------------------------

    /// @dev function that checks whether the caller is the
    /// contract owner
    function onlyPoolOwner() internal view virtual {
        require(owner() == msg.sender, Errors.CP_ONLY_OWNER);
    }

    /// @dev function that only lets the contract's owner and granted role to execute
    function onlyWithRole(bytes32 role) internal view virtual {
        require(
            hasRole(role, msg.sender) || owner() == msg.sender,
            Errors.CP_UNAUTHORIZED
        );
    }

    /// @dev function that checks whether the contract is paused
    function onlyUnpaused() internal view {
        require(!paused(), Errors.CP_PAUSED_CONTRACT);
    }

    // ------------------------
    //      Admin functions
    // ------------------------

    /// @notice Emergency function to disable contract's core functionality
    /// @dev wraps _pause(), only Admin
    function pause() external virtual {
        onlyWithRole(PAUSER_ROLE);
        _pause();
    }

    /// @dev unpause the system, wraps _unpause(), only Admin
    function unpause() external virtual {
        onlyWithRole(PAUSER_ROLE);
        _unpause();
    }

    function setToucanContractRegistry(address _address) external virtual {
        onlyPoolOwner();
        contractRegistry = _address;
        emit ToucanRegistrySet(_address);
    }

    /// @notice Generic function to switch attributes mappings into either
    /// acceptance or rejection criteria
    /// @param _mappingName attribute mapping of project-vintage data
    /// @param accepted determines if mapping works as black or whitelist
    function switchMapping(string memory _mappingName, bool accepted)
        external
        virtual
    {
        onlyPoolOwner();
        if (strcmp(_mappingName, 'regions')) {
            accepted
                ? regionsIsAcceptedMapping = true
                : regionsIsAcceptedMapping = false;
        } else if (strcmp(_mappingName, 'standards')) {
            accepted
                ? standardsIsAcceptedMapping = true
                : standardsIsAcceptedMapping = false;
        } else if (strcmp(_mappingName, 'methodologies')) {
            accepted
                ? methodologiesIsAcceptedMapping = true
                : methodologiesIsAcceptedMapping = false;
        }
        emit MappingSwitched(_mappingName, accepted);
    }

    /// @notice Function to add attributes for filtering (does not support complex AttributeSets)
    /// @param addToList determines whether attribute should be added or removed
    /// Other params are arrays of attributes to be added
    function addAttributes(
        bool addToList,
        string[] memory _regions,
        string[] memory _standards,
        string[] memory _methodologies
    ) external virtual {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < _standards.length; ++i) {
            if (addToList == true) {
                standards[_standards[i]] = true;
                emit AttributeStandardAdded(_standards[i]);
            } else {
                standards[_standards[i]] = false;
                emit AttributeStandardRemoved(_standards[i]);
            }
        }

        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < _methodologies.length; ++i) {
            if (addToList == true) {
                methodologies[_methodologies[i]] = true;
                emit AttributeMethodologyAdded(_methodologies[i]);
            } else {
                methodologies[_methodologies[i]] = false;
                emit AttributeMethodologyRemoved(_methodologies[i]);
            }
        }

        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < _regions.length; ++i) {
            if (addToList == true) {
                regions[_regions[i]] = true;
                emit AttributeRegionAdded(_regions[i]);
            } else {
                regions[_regions[i]] = false;
                emit AttributeRegionRemoved(_regions[i]);
            }
        }
    }

    /// @notice Function to whitelist selected external non-TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToExternalWhiteList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            externalWhiteList[erc20Addr[i]] = true;
            emit ExternalAddressWhitelisted(erc20Addr[i]);
        }
    }

    /// @notice Function to whitelist certain TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToInternalWhiteList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            internalWhiteList[erc20Addr[i]] = true;
            emit InternalAddressWhitelisted(erc20Addr[i]);
        }
    }

    /// @notice Function to blacklist certain TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToInternalBlackList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            internalBlackList[erc20Addr[i]] = true;
            emit InternalAddressBlacklisted(erc20Addr[i]);
        }
    }

    /// @notice Function to remove ERC20 addresses from external whitelist
    /// @param erc20Addr accepts an array of contract addresses
    function removeFromExternalWhiteList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            externalWhiteList[erc20Addr[i]] = false;
            emit ExternalAddressRemovedFromWhitelist(erc20Addr[i]);
        }
    }

    /// @notice Function to remove TCO2 addresses from internal blacklist
    /// @param erc20Addr accepts an array of contract addresses
    function removeFromInternalBlackList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            internalBlackList[erc20Addr[i]] = false;
            emit InternalAddressRemovedFromBlackList(erc20Addr[i]);
        }
    }

    /// @notice Function to remove TCO2 addresses from internal whitelist
    /// @param erc20Addr accepts an array of contract addressesc
    function removeFromInternalWhiteList(address[] memory erc20Addr) external {
        onlyPoolOwner();
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < erc20Addr.length; ++i) {
            internalWhiteList[erc20Addr[i]] = false;
            emit InternalAddressRemovedFromWhitelist(erc20Addr[i]);
        }
    }

    /// @notice Update the fee redeem percentage
    /// @param _feeRedeemPercentageInBase percentage of fee in base
    function setFeeRedeemPercentage(uint256 _feeRedeemPercentageInBase)
        external
        virtual
    {
        onlyPoolOwner();
        require(
            _feeRedeemPercentageInBase < feeRedeemDivider,
            Errors.CP_INVALID_FEE
        );
        feeRedeemPercentageInBase = _feeRedeemPercentageInBase;
    }

    /// @notice Update the fee redeem receiver
    /// @param _feeRedeemReceiver address to transfer the fees
    function setFeeRedeemReceiver(address _feeRedeemReceiver) external virtual {
        onlyPoolOwner();
        require(_feeRedeemReceiver != address(0), Errors.CP_EMPTY_ADDRESS);
        feeRedeemReceiver = _feeRedeemReceiver;
    }

    /// @notice Update the fee redeem burn percentage
    /// @param _feeRedeemBurnPercentageInBase percentage of fee in base
    function setFeeRedeemBurnPercentage(uint256 _feeRedeemBurnPercentageInBase)
        external
        virtual
    {
        onlyPoolOwner();
        require(
            _feeRedeemBurnPercentageInBase < feeRedeemDivider,
            Errors.CP_INVALID_FEE
        );
        feeRedeemBurnPercentageInBase = _feeRedeemBurnPercentageInBase;
    }

    /// @notice Update the fee redeem burn address
    /// @param _feeRedeemBurnAddress address to transfer the fees to burn
    function setFeeRedeemBurnAddress(address _feeRedeemBurnAddress)
        external
        virtual
    {
        onlyPoolOwner();
        require(_feeRedeemBurnAddress != address(0), Errors.CP_EMPTY_ADDRESS);
        feeRedeemBurnAddress = _feeRedeemBurnAddress;
    }

    /// @notice Adds a new address for redeem fees exemption
    /// @param _address address to be exempted on redeem fees
    function addRedeemFeeExemptedAddress(address _address) external virtual {
        onlyPoolOwner();
        redeemFeeExemptedAddresses[_address] = true;
    }

    /// @notice Removes an address from redeem fees exemption
    /// @param _address address to be removed from exemption
    function removeRedeemFeeExemptedAddress(address _address) external virtual {
        onlyPoolOwner();
        redeemFeeExemptedAddresses[_address] = false;
    }

    /// @notice Adds a new TCO2 for redeem fees exemption
    /// @param _tco2 TCO2 to be exempted on redeem fees
    function addRedeemFeeExemptedTCO2(address _tco2) external virtual {
        onlyPoolOwner();
        redeemFeeExemptedTCO2s[_tco2] = true;
        emit AddFeeExemptedTCO2(_tco2);
    }

    /// @notice Removes a TCO2 from redeem fees exemption
    /// @param _tco2 TCO2 to be removed from exemption
    function removeRedeemFeeExemptedTCO2(address _tco2) external virtual {
        onlyPoolOwner();
        redeemFeeExemptedTCO2s[_tco2] = false;
        emit RemoveFeeExemptedTCO2(_tco2);
    }

    /// @notice Function to limit the maximum BCT supply
    /// @dev supplyCap is initially set to 0 and must be increased before deposits
    function setSupplyCap(uint256 newCap) external virtual {
        onlyPoolOwner();
        supplyCap = newCap;
        emit SupplyCapUpdated(newCap);
    }

    /// @notice Determines the minimum vintage start time acceptance criteria of TCO2s
    /// @param _minimumVintageStartTime unix time format
    function setMinimumVintageStartTime(uint64 _minimumVintageStartTime)
        external
        virtual
    {
        onlyPoolOwner();
        minimumVintageStartTime = _minimumVintageStartTime;
        emit MinimumVintageStartTimeUpdated(_minimumVintageStartTime);
    }

    /// @notice Allows MANAGERs or the owner to pass an array to hold TCO2 contract addesses that are
    /// ordered by some form of scoring mechanism
    /// @param tco2s array of ordered TCO2 addresses
    function setTCO2Scoring(address[] calldata tco2s) external {
        onlyWithRole(MANAGER_ROLE);
        require(tco2s.length != 0, Errors.CP_EMPTY_ARRAY);
        scoredTCO2s = tco2s;
        emit TCO2ScoringUpdated(tco2s);
    }

    // -------------------------------------
    //   ToucanCrosschainMessenger functions
    // -------------------------------------

    function onlyRouter() internal view {
        require(msg.sender == router, Errors.CP_ONLY_ROUTER);
    }

    /// @notice method to set router address
    /// @dev use this method to set router address
    /// @param _router address of ToucanCrosschainMessenger
    function setRouter(address _router) external {
        onlyPoolOwner();
        // router address can be set to zero to make bridgeMint and bridgeBurn unusable
        router = _router;
        emit RouterUpdated(_router);
    }

    /// @notice mint tokens to receiver account that were cross-chain bridged
    /// @dev invoked only by the ToucanCrosschainMessenger (Router)
    /// @param _account account that will be minted with corss-chain bridged tokens
    /// @param _amount amount of tokens that will be minted
    function bridgeMint(address _account, uint256 _amount) external {
        onlyRouter();
        _mint(_account, _amount);
    }

    /// @notice burn tokens from account to be cross-chain bridged
    /// @dev invoked only by the ToucanCrosschainMessenger (Router)
    /// @param _account account that will be burned with corss-chain bridged tokens
    /// @param _amount amount of tokens that will be burned
    function bridgeBurn(address _account, uint256 _amount) external {
        onlyRouter();
        _burn(_account, _amount);
    }

    /// @notice Allows MANAGER or the owner to bridge TCO2s into
    /// another domain.
    /// @param destinationDomain The domain to bridge TCO2s to
    /// @param tco2s The TCO2s to bridge
    /// @param amounts The amounts of TCO2s to bridge
    function bridgeTCO2s(
        uint32 destinationDomain,
        address[] calldata tco2s,
        uint256[] calldata amounts
    ) external {
        onlyWithRole(MANAGER_ROLE);
        uint256 tco2Length = tco2s.length;
        require(tco2Length != 0, Errors.CP_EMPTY_ARRAY);
        require(tco2Length == amounts.length, Errors.CP_LENGTH_MISMATCH);

        // TODO: Disallow bridging more TCO2s than an amount that
        // would bring the pool to imbalance, ie., end up with more
        // pool tokens than TCO2s in the pool in the source chain.

        // Read the address of the remote pool from ToucanCrosschainMessenger
        // and set that as a recipient in our cross-chain messages.
        address tcm = router;
        RemoteTokenInformation memory remoteInfo = IToucanCrosschainMessenger(
            tcm
        ).remoteTokens(address(this), destinationDomain);
        address recipient = remoteInfo.tokenAddress;
        require(recipient != address(0), Errors.CP_EMPTY_ADDRESS);

        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < tco2Length; ++i) {
            IToucanCrosschainMessenger(tcm).sendMessageWithRecipient(
                destinationDomain,
                tco2s[i],
                amounts[i],
                recipient
            );
            emit TCO2Bridged(destinationDomain, tco2s[i], amounts[i]);
        }
    }

    // ----------------------------
    //   Permissionless functions
    // ----------------------------

    /// @notice Deposit function for BCT pool that accepts TCO2s and mints BCT 1:1
    /// @param erc20Addr ERC20 contract address to be deposited, requires approve
    /// @dev Eligibility is checked via `checkEligible`, balances are tracked
    /// for each TCO2 separately
    function deposit(address erc20Addr, uint256 amount) external virtual {
        onlyUnpaused();
        checkEligible(erc20Addr);

        uint256 remainingSpace = getRemaining();
        require(remainingSpace != 0, Errors.CP_FULL_POOL);

        if (amount > remainingSpace) amount = remainingSpace;

        _mint(msg.sender, amount);
        emit Deposited(erc20Addr, amount);

        IERC20Upgradeable(erc20Addr).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /// @notice Checks if token to be deposited is eligible for this pool
    function checkEligible(address erc20Addr)
        public
        view
        virtual
        returns (bool)
    {
        bool isToucanContract = IToucanContractRegistry(contractRegistry)
            .checkERC20(erc20Addr);

        if (isToucanContract) {
            if (internalWhiteList[erc20Addr]) {
                return true;
            }

            require(!internalBlackList[erc20Addr], Errors.CP_BLACKLISTED);

            checkAttributeMatching(erc20Addr);
        } else {
            /// @dev If not Toucan native contract, check if address is whitelisted
            require(externalWhiteList[erc20Addr], Errors.CP_NOT_WHITELISTED);
        }

        return true;
    }

    /// @notice checks whether incoming project-vintage-ERC20 token matches the accepted criteria/attributes
    function checkAttributeMatching(address erc20Addr)
        public
        view
        virtual
        returns (bool)
    {
        ProjectData memory projectData;
        VintageData memory vintageData;
        (projectData, vintageData) = IToucanCarbonOffsets(erc20Addr)
            .getAttributes();

        /// @dev checks if any one of the attributes are blacklisted.
        /// If mappings are set to "whitelist"-mode, require the opposite
        require(
            vintageData.startTime >= minimumVintageStartTime,
            Errors.CP_START_TIME_TOO_OLD
        );
        require(
            regions[projectData.region] == regionsIsAcceptedMapping,
            Errors.CP_REGION_NOT_ACCEPTED
        );
        require(
            standards[projectData.standard] == standardsIsAcceptedMapping,
            Errors.CP_STANDARD_NOT_ACCEPTED
        );
        require(
            methodologies[projectData.methodology] ==
                methodologiesIsAcceptedMapping,
            Errors.CP_METHODOLOGY_NOT_ACCEPTED
        );

        return true;
    }

    /// @notice View function to calculate fees pre-execution
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// @return Total fees amount
    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) external view virtual returns (uint256) {
        onlyUnpaused();
        if (redeemFeeExemptedAddresses[msg.sender]) {
            return 0;
        }
        uint256 tco2Length = tco2s.length;
        require(tco2Length == amounts.length, Errors.CP_LENGTH_MISMATCH);

        //slither-disable-next-line uninitialized-local
        uint256 totalFee;
        uint256 _feeRedeemPercentageInBase = feeRedeemPercentageInBase;

        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < tco2Length; ++i) {
            uint256 feeAmount = (amounts[i] * _feeRedeemPercentageInBase) /
                feeRedeemDivider;
            totalFee += feeAmount;
        }
        return totalFee;
    }

    /// @notice Redeem a whitelisted TCO2 without paying any fees and burn
    /// the TCO2. Initially added to burn HFC-23 credits, can be used in the
    /// future to dispose of any other whitelisted credits.
    /// @dev User needs to approve the pool contract in the TCO2 contract for
    /// the amount to be burnt before executing this function.
    /// @param tco2 TCO2 to redeem and burn
    /// @param amount Amount to redeem and burn
    function redeemAndBurn(address tco2, uint256 amount) external {
        onlyUnpaused();
        require(redeemFeeExemptedTCO2s[tco2], Errors.CP_NOT_EXEMPTED);
        redeemSingle(tco2, amount);
        // User has to approve the pool contract in the TCO2 contract
        // in order for this function to successfully burn the tokens
        IToucanCarbonOffsets(tco2).burnFrom(msg.sender, amount);
    }

    /// @notice Redeems Pool tokens for multiple underlying TCO2s 1:1 minus fees
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// BCT Pool token in user's wallet get burned
    function redeemMany(address[] memory tco2s, uint256[] memory amounts)
        external
        virtual
    {
        onlyUnpaused();
        uint256 tco2Length = tco2s.length;
        require(tco2Length == amounts.length, Errors.CP_LENGTH_MISMATCH);

        //slither-disable-next-line uninitialized-local
        uint256 totalFee;
        uint256 _feeRedeemPercentageInBase = feeRedeemPercentageInBase;
        bool isExempted = redeemFeeExemptedAddresses[msg.sender];
        //slither-disable-next-line uninitialized-local
        uint256 feeAmount;

        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < tco2Length; ++i) {
            if (!isExempted) {
                feeAmount =
                    (amounts[i] * _feeRedeemPercentageInBase) /
                    feeRedeemDivider;
                totalFee += feeAmount;
            } else {
                feeAmount = 0;
            }
            redeemSingle(tco2s[i], amounts[i] - feeAmount);
        }
        if (totalFee != 0) {
            uint256 burnAmount = (totalFee * feeRedeemBurnPercentageInBase) /
                feeRedeemDivider;
            totalFee -= burnAmount;
            transfer(feeRedeemReceiver, totalFee);
            emit RedeemFeePaid(msg.sender, totalFee);
            if (burnAmount > 0) {
                transfer(feeRedeemBurnAddress, burnAmount);
                emit RedeemFeeBurnt(msg.sender, burnAmount);
            }
        }
    }

    /// @notice Automatically redeems an amount of Pool tokens for underlying
    /// TCO2s from an array of ranked TCO2 contracts
    /// starting from contract at index 0 until amount is satisfied
    /// @param amount Total amount to be redeemed
    /// @dev BCT Pool tokens in user's wallet get burned
    function redeemAuto(uint256 amount) external virtual {
        redeemAuto2(amount);
    }

    /// @notice Automatically redeems an amount of Pool tokens for underlying
    /// TCO2s from an array of ranked TCO2 contracts starting from contract at
    /// index 0 until amount is satisfied.
    /// @param amount Total amount to be redeemed
    /// @return tco2s amounts The addresses and amounts of the TCO2s that were
    /// automatically redeemed
    function redeemAuto2(uint256 amount)
        public
        virtual
        returns (address[] memory tco2s, uint256[] memory amounts)
    {
        onlyUnpaused();
        require(amount != 0, Errors.CP_ZERO_AMOUNT);
        //slither-disable-next-line uninitialized-local
        uint256 i;
        // Non-zero count tracks TCO2s with a balance
        //slither-disable-next-line uninitialized-local
        uint256 nonZeroCount;

        uint256 scoredTCO2Len = scoredTCO2s.length;
        while (amount > 0 && i < scoredTCO2Len) {
            address tco2 = scoredTCO2s[i];
            uint256 balance = tokenBalances(tco2);
            //slither-disable-next-line uninitialized-local
            uint256 amountToRedeem;

            // Only TCO2s with a balance should be included for a redemption.
            if (balance != 0) {
                amountToRedeem = amount > balance ? balance : amount;
                amount -= amountToRedeem;
                unchecked {
                    ++nonZeroCount;
                }
            }

            unchecked {
                ++i;
            }

            // Create return arrays statically since Solidity does not
            // support dynamic arrays or mappings in-memory (EIP-1153).
            // Do it here to avoid having to fill out the last indexes
            // during the second iteration.
            //slither-disable-next-line incorrect-equality
            if (amount == 0) {
                tco2s = new address[](nonZeroCount);
                amounts = new uint256[](nonZeroCount);

                tco2s[nonZeroCount - 1] = tco2;
                amounts[nonZeroCount - 1] = amountToRedeem;
                redeemSingle(tco2, amountToRedeem);
            }
        }

        require(amount == 0, Errors.CP_NON_ZERO_REMAINING);

        // Execute the second iteration by avoiding to run the last index
        // since we have already executed that in the first iteration.
        nonZeroCount = 0;
        //slither-disable-next-line uninitialized-local
        for (uint256 j; j < i - 1; ++j) {
            address tco2 = scoredTCO2s[j];
            // This second loop only gets called when the `amount` is larger
            // than the first tco2 balance in the array. Here, in every iteration the
            // tco2 balance is smaller than the remaining amount while the last bit of
            // the `amount` which is smaller than the tco2 balance, got redeemed
            // in the first loop.
            uint256 balance = tokenBalances(tco2);

            // Ignore empty balances so we don't generate redundant transactions.
            //slither-disable-next-line incorrect-equality
            if (balance == 0) continue;

            tco2s[nonZeroCount] = tco2;
            amounts[nonZeroCount] = balance;
            redeemSingle(tco2, balance);
            unchecked {
                ++nonZeroCount;
            }
        }
    }

    /// @dev Internal function that redeems a single underlying token
    function redeemSingle(address erc20, uint256 amount) internal virtual {
        _burn(msg.sender, amount);
        IERC20Upgradeable(erc20).safeTransfer(msg.sender, amount);
        emit Redeemed(msg.sender, erc20, amount);
    }

    /// @dev Implemented in order to disable transfers when paused
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        onlyUnpaused();
    }

    /// @dev Returns the remaining space in pool before hitting the cap
    function getRemaining() public view returns (uint256) {
        return (supplyCap - totalSupply());
    }

    /// @notice Returns the balance of the TCO2 found in the pool
    function tokenBalances(address tco2) public view returns (uint256) {
        return IERC20Upgradeable(tco2).balanceOf(address(this));
    }

    // -----------------------------
    //      Locked ERC20 safety
    // -----------------------------

    /// @dev Function to disallowing sending tokens to either the 0-address
    /// or this contract itself
    function validDestination(address to) internal view {
        require(to != address(0x0), Errors.CP_INVALID_DESTINATION_ZERO);
        require(to != address(this), Errors.CP_INVALID_DESTINATION_SELF);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        validDestination(recipient);
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        validDestination(recipient);
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    // -----------------------------
    //      Helper Functions
    // -----------------------------

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    function getScoredTCO2s() external view returns (address[] memory) {
        return scoredTCO2s;
    }
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

import '../CarbonOffsetBatchesTypes.sol';

interface ICarbonOffsetBatches {
    function getConfirmationStatus(uint256 tokenId)
        external
        view
        returns (RetirementStatus);

    function getBatchNFTData(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            RetirementStatus
        );
}

// SPDX-FileCopyrightText: 2022 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

import '../CarbonProjectVintageTypes.sol';
import '../CarbonProjectTypes.sol';

interface IToucanCarbonOffsets {
    function burnFrom(address account, uint256 amount) external;

    function getAttributes()
        external
        view
        returns (ProjectData memory, VintageData memory);
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

interface IToucanContractRegistry {
    function carbonOffsetBatchesAddress() external view returns (address);

    function carbonProjectsAddress() external view returns (address);

    function carbonProjectVintagesAddress() external view returns (address);

    function toucanCarbonOffsetsFactoryAddress()
        external
        view
        returns (address);

    function carbonOffsetBadgesAddress() external view returns (address);

    function checkERC20(address _address) external view returns (bool);

    function addERC20(address _address) external;
}

// SPDX-FileCopyrightText: 2022 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the Toucan protocol
 * @dev Inspired by the AAVE error library:
 * https://github.com/aave/protocol-v2/blob/5df59ec74a0c635d877dc1c5ee4a165d41488352/contracts/protocol/libraries/helpers/Errors.sol
 * Error messages prefix glossary:
 *  - CP = CarbonPool
 */
library Errors {
    // User is not authorized
    string public constant CP_UNAUTHORIZED = '1';
    // Empty array provided as input
    string public constant CP_EMPTY_ARRAY = '2';
    // Pool is full of TCO2s
    string public constant CP_FULL_POOL = '3';
    // ERC20 is blacklisted in the pool. This error
    // is returned for TCO2s that have been blacklisted
    // like the HFC-23 project.
    string public constant CP_BLACKLISTED = '4';
    // ERC20 is not whitelisted in the pool
    // This error is returned in case the ERC20 is
    // not a TCO2 in which case it has to be manually
    // whitelisted in order to be allowed in the pool.
    string public constant CP_NOT_WHITELISTED = '5';
    // Vintage start time of a TCO2 is too old
    string public constant CP_START_TIME_TOO_OLD = '6';
    string public constant CP_REGION_NOT_ACCEPTED = '7';
    string public constant CP_STANDARD_NOT_ACCEPTED = '8';
    string public constant CP_METHODOLOGY_NOT_ACCEPTED = '9';
    // Provided fee is invalid, not in a basis points format: [0,10000)
    string public constant CP_INVALID_FEE = '10';
    // Provided address needs to be non-zero
    string public constant CP_EMPTY_ADDRESS = '11';
    // Validation check to ensure array lengths match
    string public constant CP_LENGTH_MISMATCH = '12';
    // TCO2 not exempted from redeem fees
    string public constant CP_NOT_EXEMPTED = '13';
    // A contract has been paused
    string public constant CP_PAUSED_CONTRACT = '14';
    // Redemption has leftover unredeemed value
    string public constant CP_NON_ZERO_REMAINING = '15';
    // Redemption exceeds deposited TCO2 supply
    string public constant CP_EXCEEDS_TCO2_SUPPLY = '16';
    // User must be a router
    string public constant CP_ONLY_ROUTER = '17';
    // User must be the owner
    string public constant CP_ONLY_OWNER = '18';
    // Zero destination address is invalid for pool token transfers
    string public constant CP_INVALID_DESTINATION_ZERO = '19';
    // Self destination address is invalid for pool token transfers
    string public constant CP_INVALID_DESTINATION_SELF = '20';
    // Zero amount provided as an input (eg., in redemptions) in invalid
    string public constant CP_ZERO_AMOUNT = '21';
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

/// @dev Storage for UUPS Proxy upgradable BaseCarbonTonne
abstract contract BaseCarbonTonneStorageV1 {
    /// @notice The supply cap is used as a measure to guard deposits
    /// in the pool. It is meant to minimize the impact a potential
    /// compromise in the source registry (eg. Verra) can have to the pool.
    uint256 public supplyCap;
    mapping(address => uint256) private DEPRECATED_tokenBalances;
    address public contractRegistry;

    uint64 public minimumVintageStartTime;

    /// @dev Mappings for attributes that can be included or excluded
    /// if set to `false`, attribute-values are blacklisted/rejected
    /// if set to `true`, attribute-values are whitelisted/accepted
    bool public regionsIsAcceptedMapping;
    mapping(string => bool) public regions;

    bool public standardsIsAcceptedMapping;
    mapping(string => bool) public standards;

    bool public methodologiesIsAcceptedMapping;
    mapping(string => bool) public methodologies;

    /// @dev mapping to whitelist external non-TCO2 contracts by address
    mapping(address => bool) public externalWhiteList;

    /// @dev mapping to include certain TCO2 contracts by address,
    /// overriding attribute matching checks
    mapping(address => bool) public internalWhiteList;

    /// @dev mapping to exclude certain TCO2 contracts by address,
    /// even if the attribute matching would pass
    mapping(address => bool) public internalBlackList;
}

abstract contract BaseCarbonTonneStorageV1_1 {
    /// @dev fees redeem receiver address
    address public feeRedeemReceiver;

    uint256 public feeRedeemPercentageInBase;

    /// @dev fees redeem burn address
    address public feeRedeemBurnAddress;

    /// @dev fees redeem burn percentage with 2 fixed decimals precision
    uint256 public feeRedeemBurnPercentageInBase;
}

abstract contract BaseCarbonTonneStorageV1_2 {
    /// @notice End users exempted from redeem fees
    mapping(address => bool) public redeemFeeExemptedAddresses;

    /// @notice array used to read from when redeeming TCO2s automatically
    address[] public scoredTCO2s;
}

abstract contract BaseCarbonTonneStorageV1_3 {
    /// @notice TCO2s exempted from redeem fees
    mapping(address => bool) public redeemFeeExemptedTCO2s;
}

abstract contract BaseCarbonTonneStorageV1_4 {
    /// @notice bridge router who has access to the bridgeMint & bridgeBurn functions which
    /// mint/burn pool tokens for cross chain messenges
    address public router;
}

abstract contract BaseCarbonTonneStorage is
    BaseCarbonTonneStorageV1,
    BaseCarbonTonneStorageV1_1,
    BaseCarbonTonneStorageV1_2,
    BaseCarbonTonneStorageV1_3,
    BaseCarbonTonneStorageV1_4
{}

// SPDX-FileCopyrightText: 2022 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity 0.8.14;

import {RemoteTokenInformation} from '../ToucanCrosschainMessengerStorage.sol';

interface IToucanCrosschainMessenger {
    function sendMessage(
        uint32 destinationDomain,
        address token,
        uint256 amount
    ) external payable;

    function sendMessageWithRecipient(
        uint32 destinationDomain,
        address token,
        uint256 amount,
        address recipient
    ) external payable;

    function remoteTokens(address _token, uint32 _destinationDomain)
        external
        view
        returns (RemoteTokenInformation memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth

pragma solidity 0.8.14;

enum RetirementStatus {
    Pending, // 0
    Rejected, // 1
    Confirmed // 2
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth

pragma solidity 0.8.14;

struct VintageData {
    /// @dev A human-readable string which differentiates this from other vintages in
    /// the same project, and helps build the corresponding TCO2 name and symbol.
    string name;
    uint64 startTime; // UNIX timestamp
    uint64 endTime; // UNIX timestamp
    uint256 projectTokenId;
    uint64 totalVintageQuantity;
    bool isCorsiaCompliant;
    bool isCCPcompliant;
    string coBenefits;
    string correspAdjustment;
    string additionalCertification;
    string uri;
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth

pragma solidity 0.8.14;

/// @dev CarbonProject related data and attributes
struct ProjectData {
    string projectId;
    string standard;
    string methodology;
    string region;
    string storageMethod;
    string method;
    string emissionType;
    string category;
    string uri;
    address beneficiary;
}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earthz
pragma solidity 0.8.14;

struct RemoteTokenInformation {
    /// @notice address of the token in the remote chain
    address tokenAddress;
    /// @notice timer keeps track of when the token pair
    /// was created in order to disallow updates to the
    /// pair after a specific amount of time elapses
    uint256 timer;
}

/// @dev Separate storage contract to improve upgrade safety
abstract contract ToucanCrosschainMessengerStorageV1 {
    enum BridgeRequestType {
        NOT_REGISTERED, // 0
        SENT, // 1
        RECEIVED // 2
    }

    enum MessageTypes {
        MINT
    }

    struct BridgeRequest {
        bool isReverted; // this state is added for future addition of revert functionality
        uint256 timestamp;
        BridgeRequestType requestType;
        MessageTypes messageType;
    }

    /// @dev nonce is used to serialize requests executed
    /// by the source chain in order to avoid duplicates
    /// from being processed in the remote chain
    uint256 public nonce;
    //slither-disable-next-line constable-states
    bytes32 private DEPRECATED_DOMAIN_SEPARATOR;
    /// @dev requests keeps track of a hash of the request
    /// to the request info in order to avoid duplicates
    /// from being processed in the remote chain
    mapping(bytes32 => BridgeRequest) public requests;
    /// @notice remoteTokens maps a token (address) in the source
    /// chain to the domain id of the remote chain (uint32)
    /// to info about the token in the remote chain (RemoteTokenInformation)
    mapping(address => mapping(uint32 => RemoteTokenInformation))
        public remoteTokens;
}

abstract contract ToucanCrosschainMessengerStorage is
    ToucanCrosschainMessengerStorageV1
{}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}