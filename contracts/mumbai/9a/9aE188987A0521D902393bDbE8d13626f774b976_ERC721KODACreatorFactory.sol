// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ICollabFundsHandler} from "../handlers/ICollabFundsHandler.sol";
import {IERC721KODACreatorFactory} from "./interfaces/IERC721KODACreatorFactory.sol";
import {IKOAccessControlsLookup} from "../interfaces/IKOAccessControlsLookup.sol";

import {ERC721KODACreator} from "./ERC721KODACreator.sol";
import {KODASettings} from "../KODASettings.sol";

/// @notice Smart contract that facilitates the deployment of self sovereign ERC721 tokens
contract ERC721KODACreatorFactory is
    UUPSUpgradeable,
    PausableUpgradeable,
    IERC721KODACreatorFactory
{
    /// @notice Address of the access controls contract that track legitimate artists within the platform
    IKOAccessControlsLookup public accessControls;

    /// @notice global primary and secondary sale platform settings
    KODASettings public platformSettings;

    /// @notice Name of contract that will be deployed as the self sovereign unless otherwise specified
    string public defaultSelfSovereignContractName;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(string => address) public contractImplementations;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(address => string) public implementationIdentifiers;

    /// @notice Address of the cloneable fund handler contract
    address public receiverImplementation;

    /// @notice Funds handler ID and the smart contract address deployed to handle it
    mapping(bytes32 => address) public deployedHandler;

    /// @notice A simple on chain pointer to contracts which have been flagged
    mapping(address => bool) public flaggedContracts;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings
    ) external initializer {
        if (_erc721Implementation == address(0)) revert ZeroAddress();
        if (_receiverImplementation == address(0)) revert ZeroAddress();
        if (bytes(_erc721ImplementationName).length == 0) revert EmptyString();

        accessControls = _accessControls;
        receiverImplementation = _receiverImplementation;

        // when initialising the factory, configure the default self sovereign implementation that will be deployed
        // other self sovereign contracts can be configured and labelled offering the ability to deploy them by supplying the label on deploy
        contractImplementations[
            _erc721ImplementationName
        ] = _erc721Implementation;

        implementationIdentifiers[
            _erc721Implementation
        ] = _erc721ImplementationName;

        defaultSelfSovereignContractName = _erc721ImplementationName;

        platformSettings = _settings;

        __Pausable_init();
        __UUPSUpgradeable_init();

        emit ContractDeployed();
    }

    ///////////////
    /// External  /
    ///////////////

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier
        );
    }

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        address _fundsHandler,
        bytes32[] calldata _artistProof
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier
        );
    }

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused returns (address) {
        return
            _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
    }

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                contractImplementations[_nftIdentifier],
                _computeSalt(_artist, _name, _symbol),
                address(this)
            );
    }

    /// @notice The unique handler ID for a given list of recipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_recipients, _splitAmounts));
    }

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address) {
        bytes32 id = getHandlerId(_recipients, _splitAmounts);
        return deployedHandler[id];
    }

    ///////////////
    /// Admin     /
    ///////////////

    /// @dev Only authorize upgrade if user has admin role
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    function flagBannedContract(address _contract, bool _banned) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        flaggedContracts[_contract] = _banned;
        emit CreatorContractBanned(_contract, _banned);
    }

    /// @notice Disable certain actions
    function pause() external whenNotPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _pause();
    }

    /// @notice Enable all paused actions
    function unpause() external whenPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _unpause();
    }

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        accessControls = _access;
    }

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_receiver == address(0)) revert ZeroAddress();
        receiverImplementation = _receiver;
    }

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_newSettings == address(0)) revert ZeroAddress();
        platformSettings = KODASettings(_newSettings);
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier
        );
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier
        );
    }

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();

        if (contractImplementations[_identifier] != address(0))
            revert DuplicateIdentifier();
        if (bytes(implementationIdentifiers[_implementation]).length != 0)
            revert DuplicateImplementation();

        contractImplementations[_identifier] = _implementation;
        implementationIdentifiers[_implementation] = _identifier;

        emit NewImplementationAdded(_identifier);
    }

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        defaultSelfSovereignContractName = _default;
        emit DefaultImplementationUpdated(_default);
    }

    ///////////////
    /// Internal  /
    ///////////////

    /// @dev Deploy a fund handler for a given set of recipients or splits if one has not already been deployed
    function _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) internal returns (address) {
        // Deploy a fund handler if not already deployed
        bytes32 handlerId = getHandlerId(_recipients, _splitAmounts);

        address handler = deployedHandler[handlerId];
        if (handler == address(0)) {
            address receiverClone = Clones.clone(receiverImplementation);
            ICollabFundsHandler(receiverClone).init(_recipients, _splitAmounts);

            deployedHandler[handlerId] = receiverClone;

            emit FundsHandlerDeployed(receiverClone);

            return receiverClone;
        }

        return handler;
    }

    /// @dev Business logic for deploying a cloneable ERC721
    function _deploySelfSovereignERC721(
        address _artist,
        string calldata _name,
        string calldata _symbol,
        address _fundsHandler,
        uint256 _secondaryRoyaltyPercentage,
        string calldata _implementationName
    ) internal {
        // Deploy the NFT
        address erc721Clone = Clones.cloneDeterministic(
            contractImplementations[_implementationName],
            _computeSalt(_artist, _name, _symbol)
        );

        ERC721KODACreator(erc721Clone).initialize(
            _artist,
            _name,
            _symbol,
            _fundsHandler,
            platformSettings,
            _secondaryRoyaltyPercentage
        );

        emit SelfSovereignERC721Deployed(
            msg.sender,
            _artist,
            erc721Clone,
            contractImplementations[_implementationName],
            _fundsHandler
        );
    }

    /// @dev Compute a deployment salt based on an address and NFT metadata
    function _computeSalt(
        address _sender,
        string calldata _name,
        string calldata _symbol
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _name, _symbol));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IKOAccessControlsLookup} from "./interfaces/IKOAccessControlsLookup.sol";
import {IKODASettings} from "./interfaces/IKODASettings.sol";
import {ZeroAddress} from "./errors/KODAErrors.sol";
import {Konstants} from "./Konstants.sol";

/// @title KnownOrigin Generalised Marketplace Settings For KODA Version 4 and beyond
/// @notice KODASettings grants flexibility in commission collected at primary and secondary point of sale
contract KODASettings is UUPSUpgradeable, Konstants, IKODASettings {
    /// @notice Address of the contract that defines who can update settings
    IKOAccessControlsLookup public accessControls;

    /// @notice Fee applied to all primary sales
    uint256 public platformPrimaryCommission;

    /// @notice Fee applied to all secondary sales
    uint256 public platformSecondaryCommission;

    /// @notice Address of the platform handler
    address public platform;

    /// @notice Base KO API endpoint
    string public baseKOApi;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external initializer {
        if (_platform == address(0)) revert ZeroAddress();
        if (address(_accessControls) == address(0)) revert ZeroAddress();

        __UUPSUpgradeable_init();

        platformPrimaryCommission = 15_00000;
        platformSecondaryCommission = 2_50000;

        platform = _platform;
        baseKOApi = _baseKOApi;
        accessControls = _accessControls;
    }

    /// @dev Only admins can trigger smart contract upgrades
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformPrimaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION) revert MaxCommissionExceeded();
        platformPrimaryCommission = _percentage;
        emit PlatformPrimaryCommissionUpdated(_percentage);
    }

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformSecondaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION) revert MaxCommissionExceeded();
        platformSecondaryCommission = _percentage;
        emit PlatformSecondaryCommissionUpdated(_percentage);
    }

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_platform == address(0)) revert ZeroAddress();
        platform = _platform;
        emit PlatformUpdated(_platform);
    }

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        baseKOApi = _baseKOApi;
        emit BaseKOAPIUpdated(_baseKOApi);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollabFundsHandler {

    function init(
        address[] calldata _recipients,
        uint256[] calldata _splits
    ) external;

    function totalRecipients() external view returns (uint256);

    function shareAtIndex(uint256 index) external view returns (address _recipient, uint256 _split);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(
        uint256 _index,
        address _account,
        bytes32[] calldata _merkleProof
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {KODASettings} from "../KODASettings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721KODAEditions} from "./ERC721KODAEditions.sol";
import {IERC721KODACreator} from "./interfaces/IERC721KODACreator.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
contract ERC721KODACreator is ERC721KODAEditions, IERC721KODACreator {
    /**
     * @notice KODA Settings
     * @dev Defines the global settings for the linked KODA platform
     */
    KODASettings public kodaSettings;

    /**
     * @notice Default Funds Handler
     * @dev Address of the fund handler that receives funds for all editions if an alternative has not been set in {_editionFundsHandler}
     */
    address public defaultFundsHandler;

    /**
     * @notice Additional address enabled as a minter
     * @dev returns true if the address has been enabled as an additional minter
     *
     * - requires addition logic in place in inherited minting contracts
     */
    mapping(address => bool) public additionalMinterEnabled;

    /// @dev mapping of edition ID => address of the fund handler for a specific edition
    mapping(uint256 => address) internal _editionFundsHandler;

    modifier onlyApprovedMinter() {
        _onlyApprovedMinter();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev initialize method that replaces constructor in upgradeable contract
     *
     * Requirements:
     *
     * - `_artistAndOwner` must not be the zero address
     * - `_name` and `_symbol` must not be empty strings
     * - `_defaultFundsHandler` must not be the zero address
     * - `_settings` must not be the zero address
     * - should call all upgradeable `__[ContractName]_init()` methods from inherited contracts
     *
     * @param _artistAndOwner Who will be assigned attribution as lead artist and initial owner of the contract.
     * @param _name the NFT name
     * @param _symbol the NFT symbol
     * @param _defaultFundsHandler the address of the default address for receiving funds for all editions
     * @param _settings address of the platform KODASettings contract
     * @param _secondaryRoyaltyPercentage the default percentage value used for calculating royalties for secondary sales
     */
    function initialize(
        address _artistAndOwner,
        string calldata _name,
        string calldata _symbol,
        address _defaultFundsHandler,
        KODASettings _settings,
        uint256 _secondaryRoyaltyPercentage
    ) external initializer {
        if (_artistAndOwner == address(0)) revert ZeroAddress();
        if (address(_settings) == address(0)) revert ZeroAddress();
        if (_defaultFundsHandler == address(0)) revert ZeroAddress();

        if (_artistAndOwner == address(this)) revert InvalidOwner();
        if (bytes(_name).length == 0 || bytes(_symbol).length == 0)
            revert EmptyString();

        name = _name;
        symbol = _symbol;

        defaultFundsHandler = _defaultFundsHandler;
        kodaSettings = _settings;
        nextEditionId = MAX_EDITION_SIZE;
        originalDeployer = _artistAndOwner;

        __KODABase_init(_secondaryRoyaltyPercentage);
        __Module_init();

        _transferOwnership(_artistAndOwner);
    }

    /// @dev Allow a module to define custom init logic
    function __Module_init() internal virtual {}

    // ********** //
    // * PUBLIC * //
    // ********** //

    function contractURI() public view returns (string memory) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            string.concat(
                kodaSettings.baseKOApi(),
                "/network/",
                Strings.toString(id),
                "/contracts/",
                Strings.toHexString(address(this))
            );
    }

    // * Contract Metadata * //

    /**
     * @notice Royalty Info for a Token Sale
     * @dev returns the royalty details for the edition a token belongs to - falls back to defaults
     * @param _tokenId the id of the token being sold
     * @param _salePrice currency/token agnostic sale price
     * @return receiver address to send royalty consideration to
     * @return royaltyAmount value to be sent to the receiver
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 editionId = _tokenEditionId(_tokenId);

        receiver = editionFundsHandler(editionId);
        royaltyAmount =
            (_salePrice * editionRoyaltyPercentage(editionId)) /
            MODULO;
    }

    /**
     * @notice Check for Interface Support
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * @param interfaceId the ID of the interface to check
     * @return bool the interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0xffffffff || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721 Metadata
            interfaceId == 0x2a55205a || // ERC2981
            interfaceId == type(IERC721KODACreator).interfaceId;
    }

    /**
     * @notice Version of the Contract used in combination with {description}
     * @dev Function value can be more easily updated in event of an upgrade
     * @return string semver version
     */
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    // * Editions * //

    /**
     * @notice Edition Funds Handler
     * @dev Returns the address that will receive sale proceeds for a given edition
     * @param _editionId the ID of an edition
     * @return address the funds handler address
     */
    function editionFundsHandler(uint256 _editionId)
        public
        view
        override
        returns (address)
    {
        address fundsHandler = _editionFundsHandler[_editionId];

        if (fundsHandler != address(0)) {
            return fundsHandler;
        }

        return defaultFundsHandler;
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(uint256 _editionId)
        public
        view
        override
        returns (uint256)
    {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return
            _getNextAvailablePrimarySaleToken(
                _editionId,
                _editionMaxTokenId(_editionId)
            );
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @param _startId the ID of the starting point to look for the next token to sell
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) public view override returns (uint256) {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return _getNextAvailablePrimarySaleToken(_editionId, _startId);
    }

    /**
     * @notice Mint An Open Edition Token
     * @dev allows the contract owner or additional minter to mint an open edition token
     * @param _editionId the ID of the edition to mint a token from
     * @param _recipient the address to transfer the token to
     */
    function mintOpenEditionToken(uint256 _editionId, address _recipient)
        public
        override
        onlyApprovedMinter
        returns (uint256)
    {
        return _mintSingleOpenEditionTo(_editionId, _recipient);
    }

    /**
     * @notice Mint Multiple Open Edition Tokens to the Edition Owner
     * @dev allows the contract owner or additional minter to mint
     * @param _editionId the ID of the edition to mint a token from
     * @param _quantity the number of tokens to mint
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) public virtual override onlyApprovedMinter {
        if (_recipient != editionOwner(_editionId)) revert InvalidRecipient();
        _mintMultipleOpenEditionToOwner(_editionId, _quantity);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Create a new Edition - optionally mint tokens and set a custom creator address and edition metadata URI
     * @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
     * @param _editionSize the initial maximum supply of tokens in the edition
     * @param _mintQuantity the number of tokens to mint upfront - minting less than the edition size is considered an open edition
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional creator address to reflected in edition details
     * @param _uri the URI for fixed edition metadata
     * @return uint256 the new edition ID
     */
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) public override onlyOwner returns (uint256) {
        // mint to the owner if address not specified
        address to = _recipient == address(0) ? owner() : _recipient;

        return _createEdition(_editionSize, _mintQuantity, to, _creator, _uri);
    }

    /**
     * @notice Create Edition and Mint All Tokens to Owner
     * @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) public override onlyOwner returns (uint256) {
        return
            _createEdition(
                _editionSize,
                _editionSize,
                owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Create Edition for Lazy Minting
     * @dev Allows the contract owner to create an edition of specified size for lazy minting
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createOpenEdition(uint32 _editionSize, string calldata _uri)
        public
        override
        onlyOwner
        returns (uint256)
    {
        return
            _createEdition(
                _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
                0,
                owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Enable/disable minting using an additional address
     * @dev allows the contract owner to enable/disable additional minting addresses
     * @param _minter address of the additional minter
     * @param _enabled whether the address is able to mint
     */
    function updateAdditionalMinterEnabled(address _minter, bool _enabled)
        external
        onlyOwner
    {
        additionalMinterEnabled[_minter] = _enabled;
        emit AdditionalMinterEnabled(_minter, _enabled);
    }

    /**
     * @notice Update Edition Funds Handler
     * @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
     * @param _editionId the ID of the edition
     * @param _fundsHandler the address of the new funds handler for the edition
     */
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) external override onlyOwner {
        if (_fundsHandler == address(0)) revert ZeroAddress();
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
        if (_editionFundsHandler[_editionId] != address(0)) revert AlreadySet();
        _editionFundsHandler[_editionId] = _fundsHandler;
        emit EditionFundsHandlerUpdated(_editionId, _fundsHandler);
    }

    /**
     * @notice Update Edition Size
     * @dev allows the contract owner to update the number of tokens that can be minted in an edition
     *
     * Requirements:
     *
     * - should not allow edition size to exceed {Konstants-MAX_EDITION_SIZE}
     * - should not allow edition size to be reduced to less than has already been minted
     *
     * @param _editionId the ID of the edition to change the size of
     * @param _editionSize the new size to set for the edition
     *
     * Emits an {EditionSizeUpdated} event.
     */
    function updateEditionSize(uint256 _editionId, uint32 _editionSize)
        public
        override
        onlyOwner
        onlyOpenEdition(_editionId)
    {
        // can't set edition size beyond maximum
        if (_editionSize > MAX_EDITION_SIZE) revert EditionSizeTooLarge();

        unchecked {
            // can't reduce edition size to less than what has been minted already
            if (_editionSize < editionMintedCount(_editionId))
                revert EditionSizeTooSmall();
        }

        _editions[_editionId].editionSize = _editionSize;
        emit EditionSizeUpdated(_editionId, _editionSize);
    }

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI)
        external
        override
        onlyOwner
    {
        if (isOpenEdition(_editionId)) {
            if (_owners[_editionId] != address(0)) revert PrimarySaleMade();
        }
        
        if (
            _owners[_editionId + editionMintedCount(_editionId) - 1] !=
            address(0)
        ) revert PrimarySaleMade();

        _editions[_editionId].uri = _newURI;

        emit EditionURIUpdated(_editionId);
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Contract Ownership * //

    // @dev Handle transferring and renouncing ownership in one go where owner always has a minimum balance
    // @dev See balanceOf for how the return value is adjusted. We just do this to reduce minting GAS
    function _transferOwnership(address _newOwner) internal override {
        // This is for keeping the balance slot of owner 'dirty'
        address _currentOwner = owner();
        if (_currentOwner != address(0)) {
            _balances[_currentOwner] -= 1;
        }
        if (_newOwner != address(0)) {
            _balances[_newOwner] += 1;
        }

        super._transferOwnership(_newOwner);
    }

    // * Sale Helpers * //

    function _facilitateNextPrimarySale(uint256 _editionId, address _recipient)
        internal
        virtual
        validateEdition(_editionId)
        returns (uint256 tokenId)
    {
        if (_editionSalesDisabled[_editionId]) revert EditionDisabled();

        // Process open edition sale
        if (isOpenEdition(_editionId)) {
            return _facilitateOpenEditionSale(_editionId, _recipient);
        }

        // process batch minted edition
        tokenId = getNextAvailablePrimarySaleToken(_editionId);

        // Re-enter this contract to make address(this) the sender for transferring which should be approved to transfer tokens
        ERC721KODACreator(address(this)).transferFrom(
            ownerOf(tokenId),
            _recipient,
            tokenId
        );
    }

    function _facilitateOpenEditionSale(uint256 _editionId, address _recipient)
        internal
        virtual
        returns (uint256)
    {
        // Mint the token on demand
        uint256 tokenId = _mintSingleOpenEditionTo(_editionId, _recipient);

        // Return the token ID
        return tokenId;
    }

    function _getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) internal view virtual returns (uint256) {
        unchecked {
            // high to low
            for (_startId; _startId >= _editionId; --_startId) {
                // if no owner set - assume primary if not moved
                if (_owners[_startId] == address(0)) {
                    return _startId;
                }
            }
        }

        revert("Primary market exhausted");
    }

    // * Validators * //

    /// @dev validates that msg.sender is the contract owner or additional minter
    function _onlyApprovedMinter() internal virtual {
        if (msg.sender == owner()) return;
        if (additionalMinterEnabled[msg.sender]) return;
        revert NotAuthorised();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "../../interfaces/IKOAccessControlsLookup.sol";
import {KODASettings} from "../../KODASettings.sol";

interface IERC721KODACreatorFactory {
    error DuplicateIdentifier();
    error DuplicateImplementation();
    error EmptyString();
    error OnlyAdmin();
    error OnlyVerifiedArtist();
    error ZeroAddress();

    /// @notice Emitted when the contract is deployed in order to capture initial params
    event ContractDeployed();

    /// @notice Emitted every time a self sovereign ERC721 contract is deployed
    event SelfSovereignERC721Deployed(
        address indexed deployer,
        address indexed artist,
        address indexed selfSovereignNFT,
        address implementation,
        address fundsHandler
    );

    /// @notice Emitted when a fund handler is deployed
    event FundsHandlerDeployed(address indexed _handler);

    /// @notice Emitted when a new deployable contract is added
    event NewImplementationAdded(string _identifier);

    /// @notice Emitted when default contract name that is deployed is updated
    event DefaultImplementationUpdated(string _identifier);

    /// @notice Emitted when a creator contract has been banned from participating in the platform marketplace
    event CreatorContractBanned(address indexed _contract, bool _banned);

    /// @notice The base deployment parameters of a self sovereign contract
    struct SelfSovereignDeployment {
        string name; // Name that will be assigned to the NFT
        string symbol; // Symbol that will be assigned to the NFT
        string contractIdentifier; // Factory identifier for the contract being deployed
        uint256 secondaryRoyaltyPercentage; // Artist specified secondary EIP2981 royalty for items sold outside platform
    }

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings
    ) external;

    ///////////////
    /// External  /
    ///////////////

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external;

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        address _fundsHandler,
        bytes32[] calldata _artistProof
    ) external;

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external returns (address);

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address);

    /// @notice The unique handler ID for a given list of receipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external pure returns (bytes32);

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address);

    function flagBannedContract(address _contract, bool _banned) external;

    /// @notice Disable certain actions
    function pause() external;

    /// @notice Enable all paused actions
    function unpause() external;

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external;

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external;

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external;

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external;

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

pragma solidity 0.8.17;

contract Konstants {
    /// @notice Maximum Platform Commission for Primary and Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_PLATFORM_COMMISSION = 50_00000;

    /// @notice Maximum Royalty Percentage for Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_ROYALTY_PERCENTAGE = 50_00000;

    /// @notice Denominator used for percentage calculations
    /// @dev precision 100.00000%
    uint24 public constant MODULO = 100_00000;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "./IKOAccessControlsLookup.sol";

interface IKODASettings {
    error MaxCommissionExceeded();
    error OnlyAdmin();
    event PlatformPrimaryCommissionUpdated(uint256 _percentage);
    event PlatformSecondaryCommissionUpdated(uint256 _percentage);
    event PlatformUpdated(address indexed _platform);
    event BaseKOAPIUpdated(string _baseKOApi);

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external;

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformPrimaryCommission(uint256 _percentage) external;

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformSecondaryCommission(uint256 _percentage) external;

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external;

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

error AlreadyListed();
error AlreadySet();
error EditionDisabled();
error EditionNotListed();
error EditionSalesDisabled();
error EmptyString();
error InvalidListing();
error InvalidOwner();
error InvalidPrice();
error InvalidToken();
error IsOpenEdition();
error OnlyAdmin();
error OnlyVerifiedArtist();
error OwnerRevoked();
error PrimarySaleMade();
error TooEarly();
error TransferFailed();
error ZeroAddress();

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity 0.8.17;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IERC721KODAEditions} from "./interfaces/IERC721KODAEditions.sol";
import {ITokenUriResolver} from "../interfaces/ITokenUriResolver.sol";

import {KODABaseUpgradeable} from "../KODABaseUpgradeable.sol";

/**
 * @dev contract which extends the ERC721 NFT standards with edition-based minting logic
 *
 */
abstract contract ERC721KODAEditions is
    KODABaseUpgradeable,
    IERC721KODAEditions
{
    // * ERC721 State * //

    bytes4 internal constant ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    /// @dev Mapping of tokenId => owner - only set on first transfer (after mint) such as a primary sale and/or gift
    mapping(uint256 => address) internal _owners;

    /// @dev Mapping of owner => number of tokens owned
    mapping(address => uint256) internal _balances;

    /// @dev Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @dev Mapping of tokenId => approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // * Custom State * //

    /// @dev ownership of latest editions recorded when contract ownership is transferred
    EditionOwnership[] internal _editionOwnerships;

    /// @notice Token URI resolver
    ITokenUriResolver public tokenUriResolver;

    /// @notice Original deployer of the 721 NFT
    address public originalDeployer;

    /// @dev tokens are minted in batches - the first token ID used is representative of the edition ID
    mapping(uint256 => Edition) internal _editions;

    /// @dev Given an edition ID, if the result is not address(0) then a specific creator has been set for an edition
    mapping(uint256 => address) internal _editionCreator;

    /// @dev The number of tokens minted from an open edition
    mapping(uint256 => uint256) internal _editionMintedCount;

    /// @dev For any given edition ID will be non zero if set by the contract owner for an edition
    mapping(uint256 => uint256) internal _editionRoyaltyPercentage;

    /// @dev Allows a creator to disable sales of their edition
    mapping(uint256 => bool) internal _editionSalesDisabled;

    /// @dev determines the maximum size and the next starting ID for each edition i.e. each edition starts at a multiple of 100,000
    uint32 public constant MAX_EDITION_SIZE = 100_000;

    /**
     * @notice Next Edition ID
     * @dev the ID of the edition that will be created next
     */
    uint256 public nextEditionId;

    // ************* //
    // * MODIFIERS * //
    // ************* //

    modifier onlyEditionOwner(uint256 _editionId) {
        _onlyEditionOwner(_editionId);
        _;
    }

    modifier onlyExistingEdition(uint256 _editionId) {
        _onlyExistingEdition(_editionId);
        _;
    }

    modifier onlyExistingToken(uint256 _tokenId) {
        _onlyExistingToken(_tokenId);
        _;
    }

    modifier onlyOpenEdition(uint256 _editionId) {
        _onlyOpenEdition(_editionId);
        _;
    }

    modifier onlyOpenEditionFromTokenId(uint256 _tokenId) {
        uint256 editionId = _tokenEditionId(_tokenId);
        _onlyOpenEdition(editionId);
        _;
    }

    modifier validateEdition(uint256 _editionId) {
        _validateEdition(_editionId);
        _;
    }

    // ********** //
    // * PUBLIC * //
    // ********** //

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *      function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return uint256 The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "Invalid owner");
        return _owner == owner() ? _balances[_owner] - 1 : _balances[_owner];
    }

    // * Approvals * //

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *      Throws unless `msg.sender` is the current NFT owner, or an authorized
     *      operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external override {
        address owner = ownerOf(_tokenId);
        require(_approved != owner, "Approved is owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Invalid sender"
        );

        _approve(owner, _approved, _tokenId);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return address The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(_tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[_tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *         all of `msg.sender`"s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *      multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved)
        public
        override
    {
        require(_msgSender() != _operator, "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    // * Transfers * //

    /**
     * @notice An extension to the default ERC721 behaviour, derived from ERC-875.
     * @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
     * @param _from the address to transfer tokens from
     * @param _to the address to transfer tokens to
     * @param _tokenIds list of token IDs to transfer
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) public override {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _safeTransferFrom(_from, _to, _tokenIds[i], bytes(""));
        }
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *      operator, or the approved address for this NFT. Throws if `_from` is
     *      not the current owner. Throws if `_to` is the zero address. Throws if
     *      `_tokenId` is not a valid NFT. When transfer is complete, this function
     *      checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      {onERC721Received} on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *          TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *          THEY MAY BE PERMANENTLY LOST
     *  @dev Throws unless `_msgSender()` is the current owner, an authorized
     *       operator, or the approved address for this NFT. Throws if `_from` is
     *       not the current owner. Throws if `_to` is the zero address. Throws if
     *       `_tokenId` is not a valid NFT.
     *  @param _from The current owner of the NFT
     *  @param _to The new owner
     *  @param _tokenId The NFT to transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _transferFrom(_from, _to, _tokenId);
    }

    // * Editions * //

    /**
     * @notice Edition Creator Address
     * @dev returns the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @return address the address of the creator of the works associated with the edition
     */
    function editionCreator(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (address)
    {
        return
            _editionCreator[_editionId] == address(0)
                ? editionOwner(_editionId)
                : _editionCreator[_editionId];
    }

    /**
     * @notice Get Edition Details
     * @dev returns the full edition details
     * @param _editionId the ID of the edition
     * @return EditionDetails the full set of properties of the edition
     */
    function editionDetails(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (EditionDetails memory)
    {
        return
            EditionDetails(
                editionOwner(_editionId), // edition owner
                editionCreator(_editionId), // edition creator
                _editionId,
                editionMintedCount(_editionId),
                editionSize(_editionId),
                isOpenEdition(_editionId),
                editionURI(_editionId)
            );
    }

    /**
     * @notice Check if an Edition Exists
     * @dev returns whether edition with id `_editionId` exists or not
     * @param _editionId the ID of the edition
     * @return bool does the edition exist
     */
    function editionExists(uint256 _editionId)
        public
        view
        override
        returns (bool)
    {
        return _editionExists(_editionId);
    }

    /**
     * @notice Maximum Token ID of an Edition
     * @dev returns the last token ID of edition `_editionId` based on the edition's size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum possible token ID
     */
    function editionMaxTokenId(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (uint256)
    {
        return _editionMaxTokenId(_editionId);
    }

    /**
     * @notice Edition Minted Count
     * @dev returns the number of tokens minted for an edition - returns edition size if count is 0 but a token has been minted due to assumed batch mint
     * @param _editionId the id of the edition to get a count for
     * @return uint256 the number of tokens minted in the edition
     */
    function editionMintedCount(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (uint256)
    {
        uint256 count = _editionMintedCount[_editionId];
        if (count > 0) return count;

        if (!_editions[_editionId].isOpenEdition)
            return editionSize(_editionId);

        return 0;
    }

    /**
     * @notice Edition Owner
     * @dev calculates the owner of an edition from recorded ownerships - falls back to current contract owner
     * @param _editionId the id of the edition to get the owner of
     * @return address the address of the edition owner
     */
    function editionOwner(uint256 _editionId)
        public
        view
        override
        returns (address)
    {
        if (!_editionExists(_editionId)) return address(0);

        uint256 count = _editionOwnerships.length;
        if (count == 0) return owner();

        unchecked {
            // the maximum number of ownerships that need checking = the number of editions from the current one to the end
            uint256 toCheck = (nextEditionId - _editionId) / MAX_EDITION_SIZE;

            uint256 i;
            // if less (or equal) need checking than the number of ownerships recorded, only check the latest ownerships
            if (toCheck < count) {
                i = count - toCheck;
            }

            for (i; i < count; i++) {
                if (_editionId <= _editionOwnerships[i].editionId) {
                    return _editionOwnerships[i].editionOwner;
                }
            }
        }

        return owner();
    }

    /**
     * @notice Edition Royalty Percentage
     * @dev returns the default secondary sale royalty percentage or a stored override value if set
     * @param _editionId the id of the edition to get the royalty percentage for
     * @return uint256 the royalty percentage value for the edition
     */
    function editionRoyaltyPercentage(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (uint256)
    {
        uint256 royaltyOverride = _editionRoyaltyPercentage[_editionId];
        return
            royaltyOverride == 0 ? defaultRoyaltyPercentage : royaltyOverride;
    }

    /**
     * @notice Check if Edition Primary Sales are Disabled
     * @dev returns whether or not primary sales of an edition are disabled
     * @param _editionId the ID of the edition
     * @return bool primary sales are disabled
     */
    function editionSalesDisabled(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (bool)
    {
        return _editionSalesDisabled[_editionId];
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOut(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (bool)
    {
        return _editionSalesDisabled[_editionId] || _editionSoldOut(_editionId);
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOutFrom(uint256 _editionId, uint256 _startId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (bool)
    {
        return _editionSalesDisabled[_editionId] || _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition Size
     * @dev returns the maximum number of tokens that CAN BE minted in an edition
     *
     * - see {editionMintedCount} for the number of tokens minted in an edition so far
     *
     * @param _editionId the id of the edition
     * @return uint256 the size of the edition
     */
    function editionSize(uint256 _editionId)
        public
        view
        override
        returns (uint256)
    {
        return _editions[_editionId].editionSize;
    }

    /**
     * @notice Is the Edition Sold Out
     * @dev returns whether on not primary sales are still possible for an edition
     * @param _editionId the ID of the edition
     * @return bool the edition is sold out
     */
    function editionSoldOut(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (bool)
    {
        return _editionSoldOut(_editionId);
    }

    /**
     * @notice Is the Edition Sold Out after a specific tokenId
     * @dev returns whether on not all tokens have been sold or transferred after `_startId`
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool the edition is sold out from the startId pointer
     */
    function editionSoldOutFrom(uint256 _editionId, uint256 _startId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (bool)
    {
        return _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition URI
     * @dev returns the URI for edition metadata - possibly the metadata for the first token if an external resolver is set
     * @param _editionId the ID of the edition
     * @return string the URI for the edition metadata
     */
    function editionURI(uint256 _editionId)
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (string memory)
    {
        // Here we are checking only that the edition has a edition level resolver - there may be a overridden token level resolver
        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(_editionId, 0)
        ) {
            return tokenUriResolver.tokenURI(_editionId, 0);
        }

        return _editions[_editionId].uri;
    }

    /**
     * @notice Is Edition Open?
     * @dev returns whether or not an edition has tokens available to be minted
     * @param _editionId the ID of the edition check
     * @return bool is the edition open
     */
    function isOpenEdition(uint256 _editionId) public view returns (bool) {
        return editionMintedCount(_editionId) < editionSize(_editionId);
    }

    // * Tokens * //

    /**
     * @notice Check the Existence of a Token
     * @dev returns whether or not a token exists with ID `_tokenID`
     * @param _tokenId the ID of the token
     * @return bool the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return address The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        uint256 editionId = _tokenEditionId(_tokenId);
        address owner = _ownerOf(_tokenId, editionId);
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    /**
     * @notice Creator of the Works of an Edition Token
     * @dev returns the creator associated with the works of an edition
     * @param _tokenId the ID of the token in an edition
     * @return address the address of the creator
     */
    function tokenEditionCreator(uint256 _tokenId)
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (address)
    {
        return editionCreator(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get Edition Details for a Token
     * @dev returns the full edition details for a token
     * @param _tokenId the ID of a token in an edition
     * @return EditionDetails the full set of properties for the edition
     */
    function tokenEditionDetails(uint256 _tokenId)
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (EditionDetails memory)
    {
        return editionDetails(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the Edition ID of a Token
     * @dev returns the ID of the edition the token belongs to
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the ID of the edition the token belongs to
     */
    function tokenEditionId(uint256 _tokenId)
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (uint256)
    {
        return _tokenEditionId(_tokenId);
    }

    /**
     * @notice Get the Size of an Edition for a Token
     * @dev returns the size of the edition the token belongs to, see {editionSize}
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the size of the edition the token belongs to
     */
    function tokenEditionSize(uint256 _tokenId)
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (uint256)
    {
        return editionSize(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the URI of the Metadata for a Token
     * @dev returns the URI of the token metadata or the metadata for the edition the token belongs to if an external resolver is not set
     * @param _tokenId the ID of a token in an edition
     * @return string the URI of the token or edition metadata
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        onlyExistingToken(_tokenId)
        returns (string memory)
    {
        uint256 editionId = _tokenEditionId(_tokenId);

        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(editionId, _tokenId)
        ) {
            return tokenUriResolver.tokenURI(editionId, _tokenId);
        }

        return _editions[editionId].uri;
    }

    /**
     * @notice Token URI Resolver Active
     * @dev return whether or not an external URI resolver has been set
     * @return bool is a token URI resolver set
     */
    function tokenUriResolverActive() public view override returns (bool) {
        return address(tokenUriResolver) != address(0);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Enable/Disable Edition Sales
     * @dev allows the owner of the contract to enable/disable primary sales of an edition
     * @param _editionId the ID of the edition to enable/disable primary sales of
     *
     * Emits {EditionSalesDisabledUpdated}
     */
    function toggleEditionSalesDisabled(uint256 _editionId)
        public
        override
        onlyOwner
    {
        bool disabled = !_editionSalesDisabled[_editionId];
        _editionSalesDisabled[_editionId] = disabled;
        emit EditionSalesDisabledUpdated(_editionId, disabled);
    }

    /**
     * @notice Update Edition Creator
     * @dev allows the contact owner to provide edition attribution to another address
     * @param _editionId the ID of the edition to set a creator for
     * @param _creator the address of the creator associated with the works of an edition
     *
     * Emits {EditionCreatorUpdated}
     */
    function updateEditionCreator(uint256 _editionId, address _creator)
        public
        override
        onlyOwner
    {
        _updateEditionCreator(_editionId, _creator);
    }

    /**
     * @notice Update Secondary Royalty Percentage for an Edition
     * @dev allows the contract owner to set an edition level override for secondary royalties of a specific edition
     * @param _editionId the ID of the edition
     * @param _percentage the secondary royalty percentage using the same precision as {MODULO}
     *
     * Emits {EditionRoyaltyPercentageUpdated}
     */
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) public override onlyOwner {
        if (_percentage > MAX_ROYALTY_PERCENTAGE) revert MaxRoyaltyPercentageExceeded();
        _editionRoyaltyPercentage[_editionId] = _percentage;
        emit EditionRoyaltyPercentageUpdated(_editionId, _percentage);
    }

    /**
     * @notice Update Token URI Resolver
     * @dev allows the contract owner to update the token URI resolver for editions and tokens
     * @param _tokenUriResolver address of the token URI resolver contract
     *
     * Emits {TokenURIResolverUpdated}
     */
    function updateTokenURIResolver(ITokenUriResolver _tokenUriResolver)
        public
        override
        onlyOwner
    {
        tokenUriResolver = _tokenUriResolver;
        emit TokenURIResolverUpdated(address(_tokenUriResolver));
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Editions * //

    /**
     * @dev internal function for creating editions
     *
     * Requirements:
     *
     * - the parent contract should implement logic to decide who can use this
     * - `_editionSize` must not be 0 or greater than {Konstants-MAX_EDITION_SIZE}
     * - `_mintQuantity` must not be greater than `_editionSize`
     * - `_recipient` must not be `address(0)` if `mintQuantity` is greater than 0
     *
     * @param _editionSize the maximum number of tokens that can be minted in the edition
     * @param _mintQuantity the number of tokens to mint immediately
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional address to attribute the works of the edition to
     * @param _uri the URI for the edition metadata
     * @return uint256 the ID of the new edition that is created
     *
     * Emits {EditionCreated}
     * Emits {EditionCreatorUpdated} if a `_creator` is not `address(0)`
     * Emits {Transfer} for any tokens that are minted
     */
    function _createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) internal virtual returns (uint256) {
        if (_editionSize == 0 || _editionSize > MAX_EDITION_SIZE)
            revert InvalidEditionSize();
        if (_mintQuantity > _editionSize) revert InvalidMintQuantity();
        if (_recipient == address(0)) revert InvalidRecipient();

        // configure start token ID
        uint256 editionId = nextEditionId;
        bool isOpen = _mintQuantity < _editionSize;

        unchecked {
            nextEditionId += MAX_EDITION_SIZE;
        }

        _editions[editionId] = Edition(_editionSize, isOpen, _uri);

        emit EditionCreated(editionId);

        if (_creator != address(0)) {
            _updateEditionCreator(editionId, _creator);
        }

        if (_mintQuantity > 0) {
            if (isOpen) _editionMintedCount[editionId] = _mintQuantity;
            _mintConsecutive(_recipient, _mintQuantity, editionId);
        }

        return editionId;
    }

    /**
     * @dev calculates if an edition exists
     * - edition size is used to calculate the existence of an edition
     * - an existing edition can't have its size set to 0
     *
     * @param _editionId the ID of the edition
     * @return bool the edition exists
     */
    function _editionExists(uint256 _editionId) internal view returns (bool) {
        return editionSize(_editionId) > 0;
    }

    /**
     * @dev calculates the maximum token ID for an edition based on the edition's ID and size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum token ID that can be minted for the edition
     */
    function _editionMaxTokenId(uint256 _editionId)
        internal
        view
        returns (uint256)
    {
        return _editionId + editionSize(_editionId) - 1;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted
     * @param _editionId the ID of the edition
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOut(uint256 _editionId) internal view virtual returns (bool) {
        // isOpenEdition returns true if NOT ALL tokens in an edition have been minted, so sold out should always be false
        if(isOpenEdition(_editionId)) {
            return false;
        }

        // even for editions initially created as open,
        // we should check each token for an owner once all tokens have been minted
        // since they may have been minted by the owner to sell
        unchecked {
            for (uint256 tokenId = _editionId; tokenId <= _editionMaxTokenId(_editionId); tokenId++) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted in a range
     * @param _editionId the ID of the edition
     * @param _startId the tokenId to start checking from
     * @param _quantity the number of tokens to check - to check a smaller range
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOutFrom(uint256 _editionId, uint256 _startId, uint256 _quantity)
        internal
        view
        virtual
        returns (bool)
    {
        if (_startId < _editionId) revert InvalidRange();

        uint256 maxTokenId = _editionMaxTokenId(_editionId);
        if (_startId > maxTokenId) revert InvalidRange();

        // if quantity 0, check all the way to the end of the edition
        uint256 finishId = _quantity == 0 ? maxTokenId : _startId + _quantity - 1;

        // don't check beyond maxTokenId
        if (finishId > maxTokenId) finishId = maxTokenId;

        unchecked {
            for (uint256 tokenId = _startId; tokenId <= finishId; tokenId++) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev minting of multiple tokens of open edition `_editionId` to the edition owner
     * @dev optimised by not storing token ownership address which is accounted for in _ownerOf()
     *
     * Requirements:
     *
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _editionId the edition that the token is a member of
     * @param _quantity the number of tokens to mint
     */
    function _mintMultipleOpenEditionToOwner(uint256 _editionId, uint256 _quantity)
        internal
        virtual
    {
        if (!_editions[_editionId].isOpenEdition) revert BatchOrUnknownEdition();
        address _owner = editionOwner(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];
            if (mintedCount + _quantity > editionSize(_editionId)) revert EditionSizeExceeded();

            _editionMintedCount[_editionId] += _quantity;
            _balances[_owner] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            uint256 firstTokenId = _editionId + mintedCount;
            for (uint256 i = 0; i < _quantity; i++) {
                _mintTransferToOwner(_owner, firstTokenId + i);
            }
        }
    }

    /**
     * @dev mints a single token of open edition `_editionId` to `_recipient`
     *
     * Requirements:
     *
     * - recipient is not the zero address
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _recipient the address to transfer the minted token to
     * @param _editionId the edition that the token is a member of
     * @return uint256 the minted token ID
     */
    function _mintSingleOpenEditionTo(uint256 _editionId, address _recipient)
        internal
        virtual
        returns (uint256)
    {
        if (_recipient == address(0)) revert InvalidRecipient();
        _onlyOpenEdition(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];

            // Get next token ID for sale
            uint256 tokenId = _editionId + mintedCount;

            _editionMintedCount[_editionId] += 1;

            _mintSingle(_recipient, tokenId);
            return tokenId;
        }
    }

    /**
     * @dev sets the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @param _creator the address of the creator
     *
     * Emits {EditionCreatorUpdated}
     */
    function _updateEditionCreator(uint256 _editionId, address _creator)
        internal
        virtual
    {
        _editionCreator[_editionId] = _creator;
        emit EditionCreatorUpdated(_editionId, _creator);
    }

    // * Tokens * //

    /**
     * @dev Approve `_approved` to operate on `_tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address _owner,
        address _approved,
        uint256 _tokenId
    ) internal virtual {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook that is called after any token transfer. This includes minting and burning
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /**
     * @dev returns the existence of a token by checking for an owner
     * @param _tokenId the token ID to check
     * @return bool the token exists
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf(_tokenId, _tokenEditionId(_tokenId)) != address(0);
    }

    /**
     * @dev returns the address of the owner of a token
     * - Newly created editions and its tokens minted to a creator don't have the owner set until the token is sold on the primary market
     * - Therefore, if internally an edition exists and owner of token is zero address, then creator still owns the token
     * - Otherwise, the token owner is returned or the zero address if the token does not exist
     *
     * @param _tokenId the ID of the token to check
     * @param _editionId the ID of the edition the token belongs to
     * @return address the address of the token owner
     */
    function _ownerOf(uint256 _tokenId, uint256 _editionId)
        internal
        view
        virtual
        returns (address)
    {
        // If an owner assigned
        address _owner = _owners[_tokenId];
        if (_owner != address(0)) {
            return _owner;
        }

        address _editionOwner = editionOwner(_editionId);

        if (_editionOwner != address(0)) {
            // if not open edition, return owner
            if (!_editions[_editionId].isOpenEdition) {
                return _editionOwner;
            }

            // if open edition, return owner below minted count, return 0 above minted count
            if (_tokenId < _editionId + _editionMintedCount[_editionId]) {
                return _editionOwner;
            }
        }

        return address(0);
    }

    /**
     * @dev calculates the edition ID using the token ID given and MAX_EDITION_SIZE
     * @param _tokenId the ID of the token to get edition ID for
     * @return uint256 the ID of the edition the token is from
     */
    function _tokenEditionId(uint256 _tokenId)
        internal
        pure
        returns (uint256)
    {
        return (_tokenId / MAX_EDITION_SIZE) * MAX_EDITION_SIZE;
    }

    // * Contract Ownership * //

    /// @dev override {Ownable-_transferOwnership} to record the old owner as the current edition owner if not already recorded
    function _transferOwnership(address _newOwner) internal virtual override {
        // record the edition owner of the most recent edition
        if (nextEditionId > MAX_EDITION_SIZE) {
            _recordLatestEditionOwnership(owner());
        }

        super._transferOwnership(_newOwner);
    }

    // * Validators * //

    function _onlyEditionOwner(uint256 _editionId) internal view {
        if (msg.sender == editionOwner(_editionId)) return;
        revert NotAuthorised();
    }

    /// @dev reverts if the edition does not exist
    function _onlyExistingEdition(uint256 _editionId) internal view {
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
    }

    /// @dev reverts if the token does not exist
    function _onlyExistingToken(uint256 _tokenId) internal view {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();
    }

    /// @dev reverts if the edition is not open
    function _onlyOpenEdition(uint256 _editionId) internal view {
        if (!isOpenEdition(_editionId)) revert BatchOrUnknownEdition();
    }

    /// @dev reverts if the edition is not valid
    function _validateEdition(uint256 _editionId) internal view virtual {
        _onlyExistingEdition(_editionId);
    }

    // *********** //
    // * PRIVATE * //
    // *********** //

    // * Edition Ownership * //

    /**
     * @dev records the editionOwnership of the most recent edition if not already recorded
     *
     * - must only be used when at least one edition has been minted
     */
    function _recordLatestEditionOwnership(address _editionOwner) private {
        uint256 count = _editionOwnerships.length;
        uint256 _editionId = nextEditionId - MAX_EDITION_SIZE;

        if (count == 0) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
            return;
        }

        uint256 lastOwnershipId = _editionOwnerships[count - 1].editionId;
        bool ownershipNotRecorded = lastOwnershipId != _editionId;
        if (ownershipNotRecorded) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
        }
    }

    // * Minting * //

    /**
     * @dev Mints multiple consecutive tokens starting at and including the first specified ID - must be pre-validated
     * @param _recipient address to mint to
     * @param _quantity the number of tokens to mint
     * @param _firstTokenId the token to start minting from
     */
    function _mintConsecutive(
        address _recipient,
        uint256 _quantity,
        uint256 _firstTokenId
    ) private {
        unchecked {
            _balances[_recipient] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            if (_recipient == owner()) {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransferToOwner(_recipient, _firstTokenId + i);
                }
            } else {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransfer(_recipient, _firstTokenId + i);
                }
            }
        }
    }

    /**
     * @notice Mint a Single Token ID
     * @dev Mint a token with the specified tokenId and update the recipient balance - must be pre-validated
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintSingle(address _recipient, uint256 _tokenId) private {
        unchecked {
            _balances[_recipient] += 1; // unlikely to exceed 2 ^ 256 - 1
            _mintTransfer(_recipient, _tokenId);
        }
    }

    /**
     * @notice Mint Transfer
     * @dev Transfer logic of minting a token - should be pre-validated and update balance in parent function
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintTransfer(address _recipient, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _recipient, _tokenId);
        _owners[_tokenId] = _recipient;
        emit Transfer(address(0), _recipient, _tokenId);
        _afterTokenTransfer(address(0), _recipient, _tokenId);
    }

    /**
     * @notice Mint Transfer To Owner
     * @dev Transfer logic of minting a token to the edition owner - should be pre-validated and update balance in parent function
     * 
     * Requirements:
     * 
     * - `_owner` must only ever be the owner of the edition the token belongs to
     * 
     * @param _owner address of the edition owner
     * @param _tokenId id of the token to mint
     */
    function _mintTransferToOwner(address _owner, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _owner, _tokenId);
        emit Transfer(address(0), _owner, _tokenId);
        _afterTokenTransfer(address(0), _owner, _tokenId);
    }

    // * Token Transfers * //

    /// @dev performs a transfer of a token and checks for a correct response if the `_to` is a contract
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private {
        _transferFrom(_from, _to, _tokenId);

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            require(selector == ERC721_RECEIVED, "Invalid selector");
        }
    }

    /**
     * @dev custom implementation of logic to transfer a token from one address to another
     *
     * Requirements:
     *
     * - `_to` must not be the zero address - we have custom logic which is optimised for minting to the contract owner
     * - the token must have an owner i.e. CAN NOT BE USED FOR MINTING
     * - the msg.sender must be the the current token owner, approved for all, or approved for the specific token
     * - should call before and after transfer hooks
     * - should clear any existing token approval
     * - should adjust the balances of the existing and new token owner
     *
     * Emits {Approval}
     * Emits {Transfer}
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        // enforce not being able to send to zero as we have explicit rules what a minted but unbound owner is
        if (_to == address(0)) revert InvalidRecipient();

        // Ensure the owner is the sender
        address owner = _ownerOf(_tokenId, _tokenEditionId(_tokenId));
        if (owner == address(0)) revert TokenDoesNotExist();
        require(_from == owner, "Owner mismatch");

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);
        require(
            spender == owner || // sending to myself
                isApprovedForAll(owner, spender) || // is approved to send any behalf of owner
                approvedAddress == spender, // is approved to move this token ID
            "Invalid spender"
        );

        // do before transfer check
        _beforeTokenTransfer(_from, _to, _tokenId);

        // Ensure approval for token ID is cleared
        _approve(owner, address(0), _tokenId);

        unchecked {
            // Modify balances
            _balances[_from] -= 1;
            _balances[_to] += 1;
        }
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);

        // do after transfer check
        _afterTokenTransfer(_from, _to, _tokenId);
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

interface IERC721KODACreator {
    error AlreadySet();
    error EditionDisabled();
    error EditionSizeTooLarge();
    error EditionSizeTooSmall();
    error EmptyString();
    error InvalidOwner();
    error IsOpenEdition();
    error OwnerRevoked();
    error PrimarySaleMade();
    error ZeroAddress();

    event EditionSizeUpdated(uint256 indexed _editionId, uint256 _editionSize);
    event EditionFundsHandlerUpdated(
        uint256 indexed _editionId,
        address indexed _handler
    );

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    /// @dev Function value can be more easily updated in event of an upgrade
    function version() external pure returns (string memory);

    /// @dev Returns the address that will receive sale proceeds for a given edition
    function editionFundsHandler(uint256 _editionId)
        external
        view
        returns (address);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(uint256 _editionId)
        external
        view
        returns (uint256);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (uint256);

    /// @dev allows the owner or additional minter to mint open edition tokens
    function mintOpenEditionToken(uint256 _editionId, address _recipient)
        external
        returns (uint256);

    /**
     * @dev allows the contract owner or additional minter to mint multiple open edition tokens
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) external;

    /// @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) external returns (uint256);

    /// @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows the contract owner to create an edition of specified size for lazy minting
    function createOpenEdition(uint32 _editionSize, string calldata _uri)
        external
        returns (uint256);

    /// @dev Allows the contract owner to add additional minters if the appropriate minting logic is in place
    function updateAdditionalMinterEnabled(address _minter, bool _enabled)
        external;

    /// @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) external;

    /// @dev allows the contract owner to update the number of tokens that can be minted in an edition
    function updateEditionSize(uint256 _editionId, uint32 _editionSize)
        external;

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI)
        external;
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

pragma solidity 0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Konstants} from "./Konstants.sol";
import {IKODABaseUpgradeable} from "./interfaces/IKODABaseUpgradeable.sol";

/**
 * @dev Base contract for KnownOrigin Creator NFT minting contracts
 *
 * - requires IKODABaseUpgradable interface for errors and events
 * - requires OpenZeppelin upgradable contracts to make inheriting contracts ownable and pausable
 *
 * - includes storage of default secondary marketplace royalties and additionally enabled minting addresses managed by the owner
 */
abstract contract KODABaseUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Konstants,
    IKODABaseUpgradeable
{
    
    /**
     * @notice Default Royalty Percentage for Secondary Sales
     * @dev default percentage value used to calculate royalty consideration on secondary sales stored with the same precision as `MODULO`
     */
    uint256 public defaultRoyaltyPercentage;

    // * Upgradeable Init * //

    /**
     * @notice Initialise the base contract with the default royalty percentage
     * @dev the inheriting contract must call otherwise the secondary royalty will be zero
     * @param _initialRoyaltyPercentage percentage to initially set the contract default royalty
     */
    function __KODABase_init(uint256 _initialRoyaltyPercentage) internal {
        __ReentrancyGuard_init();
        _updateDefaultRoyaltyPercentage(_initialRoyaltyPercentage);
    }

    // * OWNER * //

    /// @notice Allows the owner to pause some contract actions
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Allows the owner to unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set the default royalty percentage to `_percentage`
     * @dev allows the owner to set {defaultRoyaltyPercentage}
     * @param _percentage the value to set with the same precision as {KODASettings-MODULO}
     */
    function updateDefaultRoyaltyPercentage(uint256 _percentage)
        external
        onlyOwner
    {
        _updateDefaultRoyaltyPercentage(_percentage);
    }

    // * INTERNAL * //

    /// @dev Internal method for updating the the secondary royalty percentage used for calculating royalty for external marketplaces
    function _updateDefaultRoyaltyPercentage(uint256 _percentage) internal {
        if (_percentage > MAX_ROYALTY_PERCENTAGE) revert MaxRoyaltyPercentageExceeded();
        defaultRoyaltyPercentage = _percentage;
        emit DefaultRoyaltyPercentageUpdated(_percentage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokenUriResolver {

    /// @notice Return the edition or token level URI - token level trumps edition level if found
    function tokenURI(uint256 _editionId, uint256 _tokenId) external view returns (string memory);

    /// @notice Do we have an edition level or token level token URI resolver set
    function isDefined(uint256 _editionId, uint256 _tokenId) external view returns (bool);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

// import {IERC721} from "./IERC721.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {ITokenUriResolver} from "../../interfaces/ITokenUriResolver.sol";

interface IERC721KODAEditions is IERC721 {
    error BatchOrUnknownEdition();
    error EditionDoesNotExist();
    error EditionSizeExceeded();
    error InvalidRange();
    error InvalidEditionSize();
    error InvalidMintQuantity();
    error InvalidRecipient();
    error NotAuthorised();
    error TokenAlreadyMinted();
    error TokenDoesNotExist();

    /// @dev emitted when a new edition is created
    event EditionCreated(uint256 indexed _editionId);

    /// @dev emitted when the creator address for an edition is updated
    event EditionCreatorUpdated(uint256 indexed _editionId, address _creator);

    /// @dev emitted when the owner updates the edition override for secondary royalty
    event EditionRoyaltyPercentageUpdated(
        uint256 indexed _editionId,
        uint256 _percentage
    );

    /// @dev emitted when edition sales are enabled/disabled
    event EditionSalesDisabledUpdated(
        uint256 indexed _editionId,
        bool _disabled
    );

    /// @dev emitted when the edition metadata URI is updated
    event EditionURIUpdated(uint256 indexed _editionId);

    /// @dev emitted when the external token metadata URI resolver is updated
    event TokenURIResolverUpdated(address indexed _tokenUriResolver);

    /// @dev Struct defining the properties of an edition stored internally
    struct Edition {
        uint32 editionSize; // on-chain edition size
        bool isOpenEdition; // true if not all tokens were minted at creation
        string uri; // the referenced metadata
    }

    /// @dev Struct defining the full property set of an edition exposed externally
    struct EditionDetails {
        address owner;
        address creator;
        uint256 editionId;
        uint256 mintedCount;
        uint256 size;
        bool isOpenEdition;
        string uri;
    }

    /// @dev struct defining the ownership record of an edition
    struct EditionOwnership {
        uint256 editionId;
        address editionOwner;
    }

    /// @dev returns the creator address for an edition used to indicate if the NFT creator is different to the contract creator/owner
    function editionCreator(uint256 _editionId) external view returns (address);

    /// @dev returns the full set of properties for an edition, see {EditionDetails}
    function editionDetails(uint256 _editionId)
        external
        view
        returns (EditionDetails memory);

    /// @dev returns whether the edition exists or not
    function editionExists(uint256 _editionId) external view returns (bool);

    /// @dev returns the maximum possible token ID that can be minted in an edition
    function editionMaxTokenId(uint256 _editionId)
        external
        view
        returns (uint256);

    /// @dev returns the number of tokens currently minted in an edition
    function editionMintedCount(uint256 _editionId)
        external
        view
        returns (uint256);

    /// @dev returns the owner of an edition, by default this will be the contract owner at the time the edition was first created
    function editionOwner(uint256 _editionId) external view returns (address);

    /// @dev returns the royalty percentage used for secondary sales of an edition
    function editionRoyaltyPercentage(uint256 _editionId)
        external
        view
        returns (uint256);

    /// @dev returns a boolean indicating whether sales are disabled or not for an edition
    function editionSalesDisabled(uint256 _editionId)
        external
        view
        returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOut(uint256 _editionId)
        external
        view
        returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOutFrom(uint256 _editionId, uint256 _startId)
        external
        view
        returns (bool);

    /// @dev returns the size (the maximum number of tokens that can be minted) of an edition
    function editionSize(uint256 _editionId) external view returns (uint256);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not
    function editionSoldOut(uint256 _editionId) external view returns (bool);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not in a range
    function editionSoldOutFrom(uint256 _editionId, uint256 _startId) external view returns (bool);

    /// @dev returns the metadata URI for an edition
    function editionURI(uint256 _editionId)
        external
        view
        returns (string memory);

    /// @dev returns the edition creator address for the edition that a token with `_tokenId` belongs to
    function tokenEditionCreator(uint256 _tokenId)
        external
        view
        returns (address);

    /// @dev returns the full set of properties of the edition that token `_tokenId` belongs to, see {EditionDetails}
    function tokenEditionDetails(uint256 _tokenId)
        external
        view
        returns (EditionDetails memory);

    /// @dev returns the ID of an edition that a token with ID `_tokenId` belongs to
    function tokenEditionId(uint256 _tokenId) external view returns (uint256);

    /// @dev returns the size of the edition that a token with `_tokenId` belongs to
    function tokenEditionSize(uint256 _tokenId) external view returns (uint256);

    /// @dev returns a boolean indicating whether an external token metadata URI resolver is active or not
    function tokenUriResolverActive() external view returns (bool);

    /// @dev used to execute a simultaneous transfer of multiple tokens with IDs `_tokenIds`
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external;

    /// @dev used to enabled/disable sales of an edition
    function toggleEditionSalesDisabled(uint256 _editionId) external;

    /// @dev used to update the address of the creator associated with the works of an edition
    function updateEditionCreator(uint256 _editionId, address _creator)
        external;

    /// @dev used to update the royalty percentage for external secondary sales of tokens belonging to a specific edition
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) external;

    /// @dev used to set an external token URI resolver for the contract
    function updateTokenURIResolver(ITokenUriResolver _tokenUriResolver)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

pragma solidity 0.8.17;

/**
 * @dev required interface for the base contract for KnownOrigin Creator Contracts
 */
interface IKODABaseUpgradeable {
    error MaxRoyaltyPercentageExceeded();

    /// @dev Emitted when additional minter addresses are enabled or disabled
    event AdditionalMinterEnabled(address indexed _minter, bool _enabled);

    /// @dev Emitted when the owner updates the default secondary royalty percentage
    event DefaultRoyaltyPercentageUpdated(uint256 _percentage);

    /// @dev Allows the owner to pause some contract actions
    function pause() external;

    /// @dev Allows the owner to unpause
    function unpause() external;

    /// @dev Allows the contract owner to update the default secondary sale royalty percentage
    function updateDefaultRoyaltyPercentage(uint256 _percentage) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}