// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {LPManualWhitelist} from "@ensuro/core/contracts/LPManualWhitelist.sol";
import {IPolicyPool} from "@ensuro/core/contracts/interfaces/IPolicyPool.sol";
import {PolicyPoolComponent} from "@ensuro/core/contracts/PolicyPoolComponent.sol";

import {IQuadReader} from "@quadrata/contracts/interfaces/IQuadReader.sol";
import {IQuadPassportStore} from "@quadrata/contracts/interfaces/IQuadPassportStore.sol";
import {QuadReaderUtils} from "@quadrata/contracts/utility/QuadReaderUtils.sol";

contract QuadrataWhitelist is LPManualWhitelist {
  using QuadReaderUtils for bytes32;

  bytes32 public constant QUADRATA_WHITELIST_ROLE = keccak256("QUADRATA_WHITELIST_ROLE");

  bytes32 internal constant ATTRIBUTE_COUNTRY = keccak256("COUNTRY");
  bytes32 internal constant ATTRIBUTE_AML = keccak256("AML");

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IQuadReader internal immutable _reader;

  WhitelistStatus internal _whitelistMode;

  bytes32[] internal _requiredAttributes;

  uint256 internal _requiredAMLScore;

  mapping(bytes32 => bool) internal _countryBlacklisted;

  event QuadrataWhitelistModeChanged(WhitelistStatus newMode);
  event RequiredAMLScoreChanged(uint256 requiredAMLScore);
  event CountryBlacklistChanged(bytes32 country, bool blacklisted);
  event RequiredAttributeAdded(bytes32 attribute);
  event RequiredAttributeRemoved(bytes32 attribute);
  event PassportAttribute(address indexed provider, bytes32 indexed attribute, bytes32 value);

  /**
   *
   * @param policyPool_ The policypool this whitelist belongs to
   * @param reader_ The QuadReader to be used
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(IPolicyPool policyPool_, IQuadReader reader_) LPManualWhitelist(policyPool_) {
    _reader = reader_;
  }

  /**
   *
   * @param defaultStatus The default status to use for undefined whitelist status
   * @param quadrataWhitelistMode The whitelist status to be used when whitelisting with quadrata
   * @param requiredAMLScore_ The minimum AML score required for whitelisting
   * @param requiredAttributes_ An array of attributes that are required for whitelisting.
   *                            Attributes are represented as the keccak hash of the attribute name.
   *                            Check quadrata's docs: https://docs.quadrata.com/integration/additional-information/constants#attributes
   */
  function initializeQuadrata(
    WhitelistStatus calldata defaultStatus,
    WhitelistStatus calldata quadrataWhitelistMode,
    uint256 requiredAMLScore_,
    bytes32[] calldata requiredAttributes_
  ) public initializer {
    __QuadrataWhitelist_init(
      defaultStatus,
      quadrataWhitelistMode,
      requiredAMLScore_,
      requiredAttributes_
    );
  }

  function initialize(WhitelistStatus calldata) public override initializer {
    revert("Parent initializer disabled");
  }

  // solhint-disable-next-line func-name-mixedcase
  function __QuadrataWhitelist_init(
    WhitelistStatus calldata defaultStatus,
    WhitelistStatus calldata quadrataWhitelistMode,
    uint256 requiredAMLScore_,
    bytes32[] calldata requiredAttributes_
  ) internal onlyInitializing {
    __LPManualWhitelist_init(defaultStatus);
    __QuadrataWhitelist_init_unchained(
      quadrataWhitelistMode,
      requiredAMLScore_,
      requiredAttributes_
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function __QuadrataWhitelist_init_unchained(
    WhitelistStatus calldata quadrataWhitelistMode,
    uint256 requiredAMLScore_,
    bytes32[] calldata requiredAttributes_
  ) internal onlyInitializing {
    for (uint256 i = 0; i < requiredAttributes_.length; i++) {
      _requiredAttributes.push(requiredAttributes_[i]);
      emit RequiredAttributeAdded(requiredAttributes_[i]);
    }

    _requiredAMLScore = requiredAMLScore_;
    emit RequiredAMLScoreChanged(_requiredAMLScore);

    _whitelistMode = quadrataWhitelistMode;
    emit QuadrataWhitelistModeChanged(_whitelistMode);
  }

  /**
   * @dev Validates that the attribute exists, and for some attributes performs additional validations.
   *      Current validations:
   *        - AML <= required AML score
   *        - Country not blacklisted
   * @param attributeKey The attribute that will be validated. See `requiredAttributes_` in `initializeQuadrata`
   * @param attribute The attribute itself as returned by QuadReader
   */
  function _validateRequiredAttribute(
    bytes32 attributeKey,
    IQuadPassportStore.Attribute memory attribute
  ) internal view {
    require(
      attribute.value != bytes32(0),
      "User has no passport or is missing required attributes"
    );

    if (attributeKey == ATTRIBUTE_AML) {
      require(uint256(attribute.value) <= _requiredAMLScore, "AML score > required AML score");
    } else if (attributeKey == ATTRIBUTE_COUNTRY) {
      require(!_countryBlacklisted[attribute.value], "Country not allowed");
    }
  }

  /**
   * @dev Whitelist a provider that has a Quadrata passport with the required attributes.
   *      The provider will be whitelisted according to the whitelistMode.
   * @param provider The provider address.
   */
  function quadrataWhitelist(address provider) public onlyComponentRole(QUADRATA_WHITELIST_ROLE) {
    require(provider != address(0), "Provider cannot be the zero address");

    IQuadPassportStore.Attribute[] memory attributes = _reader.getAttributesBulk(
      provider,
      _requiredAttributes
    );

    require(attributes.length == _requiredAttributes.length, "Sanity check failed");

    for (uint256 i = 0; i < attributes.length; i++) {
      _validateRequiredAttribute(_requiredAttributes[i], attributes[i]);
      emit PassportAttribute(provider, _requiredAttributes[i], attributes[i].value);
    }

    _whitelistAddress(provider, _whitelistMode);
  }

  function setWhitelistMode(
    WhitelistStatus calldata newMode
  ) public onlyComponentRole(LP_WHITELIST_ADMIN_ROLE) {
    _whitelistMode = newMode;
    emit QuadrataWhitelistModeChanged(_whitelistMode);
  }

  function reader() external view virtual returns (IQuadReader) {
    return _reader;
  }

  function requiredAMLScore() external view virtual returns (uint256) {
    return _requiredAMLScore;
  }

  function setRequiredAMLScore(
    uint256 requiredAMLScore_
  ) external onlyComponentRole(LP_WHITELIST_ADMIN_ROLE) {
    _requiredAMLScore = requiredAMLScore_;
    emit RequiredAMLScoreChanged(_requiredAMLScore);
  }

  function countryBlacklisted(bytes32 country) external view virtual returns (bool) {
    return _countryBlacklisted[country];
  }

  function setCountryBlacklisted(
    bytes32 country,
    bool blacklisted
  ) external onlyComponentRole(LP_WHITELIST_ADMIN_ROLE) {
    _countryBlacklisted[country] = blacklisted;
    emit CountryBlacklistChanged(country, blacklisted);
  }

  function requiredAttributes() external view virtual returns (bytes32[] memory) {
    return _requiredAttributes;
  }

  function addRequiredAttribute(
    bytes32 attribute
  ) external onlyComponentRole(LP_WHITELIST_ADMIN_ROLE) {
    for (uint256 i = 0; i < _requiredAttributes.length; i++)
      if (_requiredAttributes[i] == attribute) return;

    // TODO: validate the attribute?
    _requiredAttributes.push(attribute);
    emit RequiredAttributeAdded(attribute);
  }

  function removeRequiredAttribute(
    bytes32 attribute
  ) external onlyComponentRole(LP_WHITELIST_ADMIN_ROLE) {
    for (uint256 i = 0; i < _requiredAttributes.length; i++)
      if (_requiredAttributes[i] == attribute) {
        _requiredAttributes[i] = _requiredAttributes[_requiredAttributes.length - 1];
        _requiredAttributes.pop();
        emit RequiredAttributeRemoved(attribute);
        return;
      }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[46] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IPolicyPool} from "./interfaces/IPolicyPool.sol";
import {IPolicyPoolComponent} from "./interfaces/IPolicyPoolComponent.sol";
import {IAccessManager} from "./interfaces/IAccessManager.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {WadRayMath} from "./dependencies/WadRayMath.sol";

/**
 * @title Base class for PolicyPool components
 * @dev This is the base class of all the components of the protocol that are linked to the PolicyPool and created
 *      after it.
 *      Holds the reference to _policyPool as immutable, also provides access to common admin roles:
 *      - LEVEL1_ROLE: High impact changes like upgrades, adding or removing components or other critical operations
 *      - LEVEL2_ROLE: Mid-impact changes like changing some parameters
 *      - LEVEL3_ROLE: Low-impact changes like changing some parameters up to given percentage (tweaks)
 *      - GUARDIAN_ROLE: For emergency operations oriented to protect the protocol in case of attacks or hacking.
 *
 *      This contract also keeps track of the tweaks to avoid two tweaks of the same type are done in a short period.
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
abstract contract PolicyPoolComponent is
  UUPSUpgradeable,
  PausableUpgradeable,
  IPolicyPoolComponent
{
  using WadRayMath for uint256;

  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant LEVEL1_ROLE = keccak256("LEVEL1_ROLE");
  bytes32 public constant LEVEL2_ROLE = keccak256("LEVEL2_ROLE");
  bytes32 public constant LEVEL3_ROLE = keccak256("LEVEL3_ROLE");

  uint40 public constant TWEAK_EXPIRATION = 1 days;

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IPolicyPool internal immutable _policyPool;
  uint40 internal _lastTweakTimestamp;
  uint56 internal _lastTweakActions; // bitwise map of applied actions

  event GovernanceAction(IAccessManager.GovernanceActions indexed action, uint256 value);
  event ComponentChanged(IAccessManager.GovernanceActions indexed action, address value);

  modifier onlyPolicyPool() {
    require(_msgSender() == address(_policyPool), "The caller must be the PolicyPool");
    _;
  }

  modifier onlyComponentRole(bytes32 role) {
    _policyPool.access().checkComponentRole(address(this), role, _msgSender(), false);
    _;
  }

  modifier onlyGlobalOrComponentRole(bytes32 role) {
    _policyPool.access().checkComponentRole(address(this), role, _msgSender(), true);
    _;
  }

  modifier onlyGlobalOrComponentRole2(bytes32 role1, bytes32 role2) {
    _policyPool.access().checkComponentRole2(address(this), role1, role2, _msgSender(), true);
    _;
  }

  modifier onlyGlobalOrComponentRole3(
    bytes32 role1,
    bytes32 role2,
    bytes32 role3
  ) {
    IAccessManager access = _policyPool.access();
    if (!access.hasComponentRole(address(this), role1, _msgSender(), true)) {
      _policyPool.access().checkComponentRole2(address(this), role2, role3, _msgSender(), true);
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(IPolicyPool policyPool_) {
    require(
      address(policyPool_) != address(0),
      "PolicyPoolComponent: policyPool cannot be zero address"
    );
    _disableInitializers();
    _policyPool = policyPool_;
  }

  // solhint-disable-next-line func-name-mixedcase
  function __PolicyPoolComponent_init() internal onlyInitializing {
    __UUPSUpgradeable_init();
    __Pausable_init();
  }

  function _authorizeUpgrade(address newImpl)
    internal
    view
    override
    onlyGlobalOrComponentRole2(GUARDIAN_ROLE, LEVEL1_ROLE)
  {
    _upgradeValidations(newImpl);
  }

  function _upgradeValidations(address newImpl) internal view virtual {
    require(
      IPolicyPoolComponent(newImpl).policyPool() == _policyPool,
      "Can't upgrade changing the PolicyPool!"
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IPolicyPoolComponent).interfaceId;
  }

  function pause() public onlyGlobalOrComponentRole(GUARDIAN_ROLE) {
    _pause();
  }

  function unpause() public onlyGlobalOrComponentRole2(GUARDIAN_ROLE, LEVEL1_ROLE) {
    _unpause();
  }

  function policyPool() public view override returns (IPolicyPool) {
    return _policyPool;
  }

  function currency() public view returns (IERC20Metadata) {
    return _policyPool.currency();
  }

  function hasPoolRole(bytes32 role) internal view returns (bool) {
    return _policyPool.access().hasComponentRole(address(this), role, _msgSender(), true);
  }

  function _isTweakWad(
    uint256 oldValue,
    uint256 newValue,
    uint256 maxTweak
  ) internal pure returns (bool) {
    if (oldValue == newValue) return true;
    if (oldValue == 0) return maxTweak >= WadRayMath.WAD;
    if (newValue == 0) return false;
    if (oldValue < newValue) {
      return (newValue.wadDiv(oldValue) - WadRayMath.WAD) <= maxTweak;
    } else {
      return (WadRayMath.WAD - newValue.wadDiv(oldValue)) <= maxTweak;
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function _validateParameters() internal view virtual {} // Must be reimplemented with specific validations

  function _parameterChanged(
    IAccessManager.GovernanceActions action,
    uint256 value,
    bool tweak
  ) internal {
    _validateParameters();
    if (tweak) _registerTweak(action);
    emit GovernanceAction(action, value);
  }

  function _componentChanged(IAccessManager.GovernanceActions action, address value) internal {
    _validateParameters();
    emit ComponentChanged(action, value);
  }

  function lastTweak() external view returns (uint40, uint56) {
    return (_lastTweakTimestamp, _lastTweakActions);
  }

  function _registerTweak(IAccessManager.GovernanceActions action) internal {
    uint56 actionBitMap = uint56(1 << (uint8(action) - 1));
    if ((uint40(block.timestamp) - _lastTweakTimestamp) > TWEAK_EXPIRATION) {
      _lastTweakTimestamp = uint40(block.timestamp);
      _lastTweakActions = actionBitMap;
    } else {
      if ((actionBitMap & _lastTweakActions) == 0) {
        _lastTweakActions |= actionBitMap;
        _lastTweakTimestamp = uint40(block.timestamp); // Updates the expiration
      } else {
        revert("You already tweaked this parameter recently. Wait before tweaking again");
      }
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

interface IQuadPassportStore {

    /// @dev Attribute store infomation as it relates to a single attribute
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `value` Attribute value
    /// `epoch` timestamp when the attribute has been verified by an Issuer
    /// `issuer` address of the issuer issuing the attribute
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    /// @dev AttributeSetterConfig contains configuration for setting attributes for a Passport holder
    /// @notice This struct is used to abstract setAttributes function parameters
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `attrValues` Array of attributes values
    /// `attrTypes` Array of attributes types (ex: [keccak256("DID")]) used for validation
    /// `did` did of entity
    /// `tokenId` tokenId of the Passport
    /// `issuedAt` epoch when the passport has been issued by the Issuer
    /// `verifiedAt` epoch when the attribute has been attested by the Issuer
    /// `fee` Fee (in Native token) to pay the Issuer
    struct AttributeSetterConfig {
        bytes32[] attrKeys;
        bytes32[] attrValues;
        bytes32[] attrTypes;
        bytes32 did;
        uint256 tokenId;
        uint256 verifiedAt;
        uint256 issuedAt;
        uint256 fee;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "../storage/QuadPassportStore.sol";

interface IQuadReader {
    event QueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute);
    event QueryBulkEvent(address indexed _account, address indexed _caller, bytes32[] _attributes);
    event QueryFeeReceipt(address indexed _receiver, uint256 _fee);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function queryFee(
        address _account,
        bytes32 _attribute
    ) external view returns(uint256);

    function queryFeeBulk(
        address _account,
        bytes32[] calldata _attributes
    ) external view returns(uint256);

    function getAttribute(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute memory attribute);

    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute[] memory attributes);

    function getAttributesLegacy(
        address _account, bytes32 _attribute
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function getAttributesBulk(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(QuadPassportStore.Attribute[] memory);

    function getAttributesBulkLegacy(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function balanceOf(address _account, bytes32 _attribute) external view returns(uint256);

    function withdraw(address payable _to, uint256 _amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IPolicyPool} from "./interfaces/IPolicyPool.sol";
import {PolicyPoolComponent} from "./PolicyPoolComponent.sol";
import {ILPWhitelist} from "./interfaces/ILPWhitelist.sol";
import {IEToken} from "./interfaces/IEToken.sol";

/**
 * @title Manual Whitelisting contract
 * @dev LP addresses are whitelisted (and un-whitelisted) manually with transactions by user with given role
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
contract LPManualWhitelist is ILPWhitelist, PolicyPoolComponent {
  bytes32 public constant LP_WHITELIST_ROLE = keccak256("LP_WHITELIST_ROLE");
  bytes32 public constant LP_WHITELIST_ADMIN_ROLE = keccak256("LP_WHITELIST_ADMIN_ROLE");

  /**
   * @dev Enum with the different options for whitelisting status
   */
  enum WhitelistOptions {
    undefined,
    whitelisted,
    blacklisted
  }

  struct WhitelistStatus {
    WhitelistOptions deposit;
    WhitelistOptions withdraw;
    WhitelistOptions sendTransfer;
    WhitelistOptions receiveTransfer;
  }

  mapping(address => WhitelistStatus) private _wlStatus;

  event LPWhitelistStatusChanged(address provider, WhitelistStatus whitelisted);

  /// @custom:oz-upgrades-unsafe-allow constructor
  // solhint-disable-next-line no-empty-blocks
  constructor(IPolicyPool policyPool_) PolicyPoolComponent(policyPool_) {}

  /**
   * @dev Initializes the Whitelist contract
   */
  function initialize(WhitelistStatus calldata defaultStatus) public virtual initializer {
    __LPManualWhitelist_init(defaultStatus);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __LPManualWhitelist_init(WhitelistStatus calldata defaultStatus)
    internal
    onlyInitializing
  {
    __PolicyPoolComponent_init();
    __LPManualWhitelist_init_unchained(defaultStatus);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __LPManualWhitelist_init_unchained(WhitelistStatus calldata defaultStatus)
    internal
    onlyInitializing
  {
    _checkDefaultStatus(defaultStatus);
    _wlStatus[address(0)] = defaultStatus;
    emit LPWhitelistStatusChanged(address(0), defaultStatus);
  }

  function whitelistAddress(address provider, WhitelistStatus calldata newStatus)
    external
    onlyComponentRole(LP_WHITELIST_ROLE)
  {
    require(provider != address(0), "You can't change the defaults");
    _whitelistAddress(provider, newStatus);
  }

  function _checkDefaultStatus(WhitelistStatus calldata newStatus) internal pure {
    require(
      newStatus.deposit != WhitelistOptions.undefined &&
        newStatus.withdraw != WhitelistOptions.undefined &&
        newStatus.sendTransfer != WhitelistOptions.undefined &&
        newStatus.receiveTransfer != WhitelistOptions.undefined,
      "You need to define the default status for all the operations"
    );
  }

  function setWhitelistDefaults(WhitelistStatus calldata newStatus)
    external
    onlyComponentRole(LP_WHITELIST_ADMIN_ROLE)
  {
    _checkDefaultStatus(newStatus);
    _whitelistAddress(address(0), newStatus);
  }

  function getWhitelistDefaults() external view returns (WhitelistStatus memory) {
    return _wlStatus[address(0)];
  }

  function _whitelistAddress(address provider, WhitelistStatus memory newStatus) internal {
    _wlStatus[provider] = newStatus;
    emit LPWhitelistStatusChanged(provider, newStatus);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId) || interfaceId == type(ILPWhitelist).interfaceId;
  }

  function acceptsDeposit(
    IEToken,
    address provider,
    uint256
  ) external view override returns (bool) {
    WhitelistOptions wl = _wlStatus[provider].deposit;
    if (wl == WhitelistOptions.undefined) {
      wl = _wlStatus[address(0)].deposit;
    }
    return wl == WhitelistOptions.whitelisted;
  }

  function acceptsWithdrawal(
    IEToken,
    address provider,
    uint256
  ) external view override returns (bool) {
    WhitelistOptions wl = _wlStatus[provider].withdraw;
    if (wl == WhitelistOptions.undefined) {
      wl = _wlStatus[address(0)].withdraw;
    }
    return wl == WhitelistOptions.whitelisted;
  }

  function acceptsTransfer(
    IEToken,
    address providerFrom,
    address providerTo,
    uint256
  ) external view override returns (bool) {
    WhitelistOptions wl = _wlStatus[providerFrom].sendTransfer;
    if (wl == WhitelistOptions.undefined) {
      wl = _wlStatus[address(0)].sendTransfer;
    }
    if (wl != WhitelistOptions.whitelisted) return false;
    wl = _wlStatus[providerTo].receiveTransfer;
    if (wl == WhitelistOptions.undefined) {
      wl = _wlStatus[address(0)].receiveTransfer;
    }
    return wl == WhitelistOptions.whitelisted;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

library QuadReaderUtils {
  /// @dev Checks if IsBusiness return value is true
  /// @param _attrValue return value of query
  function isBusinessTrue(bytes32 _attrValue) public pure returns (bool) {
    return(_attrValue == keccak256("TRUE"));
  }

  /// @dev Checks if IsBusiness return value is false
  /// @param _attrValue return value of query
  function isBusinessFalse(bytes32 _attrValue) public pure returns (bool) {
    return(_attrValue == keccak256("FALSE") || _attrValue == bytes32(0));
  }

  /// @dev Checks if Country return value is equal to a given string value
  /// @param _attrValue return value of query
  /// @param _expectedString expected country value as string
  function countryIsEqual(bytes32 _attrValue, string memory _expectedString) public pure returns (bool) {
    return(_attrValue == keccak256(abi.encodePacked(_expectedString)));
  }

  /// @dev Checks if AML return value is equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _expectedInt expected AML value as uint256
  function amlIsEqual(bytes32 _attrValue, uint256 _expectedInt) public pure returns (bool) {
    return(uint256(_attrValue) == _expectedInt);
  }

  /// @dev Checks if AML return value is greater than a given uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound AML value as uint256
  function amlGreaterThan(bytes32 _attrValue, uint256 _lowerBound) public pure returns (bool) {
    return(uint256(_attrValue) > _lowerBound);
  }

  /// @dev Checks if AML return value is greater than or equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound AML value as uint256
  function amlGreaterThanEqual(bytes32 _attrValue, uint256 _lowerBound) public pure returns (bool) {
    return(uint256(_attrValue) >= _lowerBound);
  }

  /// @dev Checks if AML return value is less than a given uint256 value
  /// @param _attrValue return value of query
  /// @param _upperBound upper bound AML value as uint256
  function amlLessThan(bytes32 _attrValue, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) < _upperBound);
  }

  /// @dev Checks if AML return value is less than or equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _upperBound upper bound AML value as uint256
  function amlLessThanEqual(bytes32 _attrValue, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) <= _upperBound);
  }

  /// @dev Checks if AML return value is inclusively between two uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound AML value as uint256
  /// @param _upperBound upper bound AML value as uint256
  function amlBetweenInclusive(bytes32 _attrValue, uint256 _lowerBound, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) <= _upperBound && uint256(_attrValue) >= _lowerBound);
  }

  /// @dev Checks if AML return value is exlusively between two uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound AML value as uint256
  /// @param _upperBound upper bound AML value as uint256
  function amlBetweenExclusive(bytes32 _attrValue, uint256 _lowerBound, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) < _upperBound && uint256(_attrValue) > _lowerBound);
  }

  /// @dev Checks if supplied hash is above threshold of Vantage Score value
  /// @param _attrValue return value of query
  /// @param _startingHiddenScore starting hidden score hash
  /// @param _iteratorThreshold maximum number of hashing to meet criteria
  function vantageScoreIteratorGreaterThan(bytes32 _attrValue, bytes32 _startingHiddenScore, uint256 _iteratorThreshold) public pure returns (bool){
    if(_attrValue == bytes32(0)){
      return false;
    }

    uint256 count = 0 ;
    bytes32 hashIterator = _startingHiddenScore;

    for(uint256 i = 0; i < 25; i++){
      if(hashIterator==_attrValue){
        return(count > _iteratorThreshold);
      }
      hashIterator = keccak256(abi.encodePacked(hashIterator));
      count += 1;
    }

    return false;
  }

  /// @dev Checks if CredProtocolScore return value is equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _expectedInt expected CredProtocolScore value as uint256
  function credProtocolScoreIsEqual(bytes32 _attrValue, uint256 _expectedInt) public pure returns (bool) {
    return(uint256(_attrValue) == _expectedInt);
  }

  /// @dev Checks if CredProtocolScore return value is greater than a given uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound CredProtocolScore value as uint256
  function credProtocolScoreGreaterThan(bytes32 _attrValue, uint256 _lowerBound) public pure returns (bool) {
    return(uint256(_attrValue) > _lowerBound);
  }

  /// @dev Checks if CredProtocolScore return value is greater than or equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound CredProtocolScore value as uint256
  function credProtocolScoreGreaterThanEqual(bytes32 _attrValue, uint256 _lowerBound) public pure returns (bool) {
    return(uint256(_attrValue) >= _lowerBound);
  }

  /// @dev Checks if CredProtocolScore return value is less than a given uint256 value
  /// @param _attrValue return value of query
  /// @param _upperBound upper bound CredProtocolScore value as uint256
  function credProtocolScoreLessThan(bytes32 _attrValue, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) < _upperBound);
  }

  /// @dev Checks if CredProtocolScore return value is less than or equal to a given uint256 value
  /// @param _attrValue return value of query
  /// @param _upperBound upper bound CredProtocolScore value as uint256
  function credProtocolScoreLessThanEqual(bytes32 _attrValue, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) <= _upperBound);
  }

  /// @dev Checks if CredProtocolScore return value is inclusively between two uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound CredProtocolScore value as uint256
  /// @param _upperBound upper bound CredProtocolScore value as uint256
  function credProtocolScoreBetweenInclusive(bytes32 _attrValue, uint256 _lowerBound, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) <= _upperBound && uint256(_attrValue) >= _lowerBound);
  }

  /// @dev Checks if CredProtocolScore return value is exlusively between two uint256 value
  /// @param _attrValue return value of query
  /// @param _lowerBound lower bound CredProtocolScore value as uint256
  /// @param _upperBound upper bound CredProtocolScore value as uint256
  function credProtocolScoreBetweenExclusive(bytes32 _attrValue, uint256 _lowerBound, uint256 _upperBound) public pure returns (bool) {
    return(uint256(_attrValue) < _upperBound && uint256(_attrValue) > _lowerBound);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Policy} from "../Policy.sol";
import {IEToken} from "./IEToken.sol";
import {IAccessManager} from "./IAccessManager.sol";

interface IPolicyPool {
  /**
   * @dev Reference to the main currency (ERC20) used in the protocol
   * @return The address of the currency (e.g. USDC) token used in the protocol
   */
  function currency() external view returns (IERC20Metadata);

  /**
   * @dev Reference to the {AccessManager} contract, this contract manages the access controls.
   * @return The address of the AccessManager contract
   */
  function access() external view returns (IAccessManager);

  /**
   * @dev Address of the treasury, that receives protocol fees.
   * @return The address of the treasury
   */
  function treasury() external view returns (address);

  /**
   * @dev Creates a new Policy. Must be called from an active RiskModule
   *
   * Requirements:
   * - `msg.sender` must be an active RiskModule
   * - `caller` approved the spending of `currency()` for at least `policy.premium`
   * - `internalId` must be unique within `policy.riskModule` and not used before
   *
   * Events:
   * - {PolicyPool-NewPolicy}: with all the details about the policy
   * - {ERC20-Transfer}: does several transfers from caller address to the different receivers of the premium
   * (see Premium Split in the docs)
   *
   * @param policy A policy created with {Policy-initialize}
   * @param caller The pricer that's creating the policy and will pay for the premium
   * @param policyHolder The address of the policy holder and the payer of the premiums
   * @param internalId A unique id within the RiskModule, that will be used to compute the policy id
   * @return The policy id, identifying the NFT and the policy
   */
  function newPolicy(
    Policy.PolicyData memory policy,
    address caller,
    address policyHolder,
    uint96 internalId
  ) external returns (uint256);

  /**
   * @dev Resolves a policy with a payout. Must be called from an active RiskModule
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not
   *   resolved before and not expired (if payout > 0).
   * - `payout`: must be less than equal to `policy.payout`.
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with the payout
   * - {ERC20-Transfer}: to the policyholder with the payout
   *
   * @param policy A policy previously created with `newPolicy`
   * @param payout The amount to paid to the policyholder
   */
  function resolvePolicy(Policy.PolicyData calldata policy, uint256 payout) external;

  /**
   * @dev Resolves a policy with a payout that can be either 0 or the maximum payout of the policy
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not
   *   resolved before and not expired (if customerWon).
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with the payout
   * - {ERC20-Transfer}: to the policyholder with the payout
   *
   * @param policy A policy previously created with `newPolicy`
   * @param customerWon Indicated if the payout is zero or the maximum payout
   */
  function resolvePolicyFullPayout(Policy.PolicyData calldata policy, bool customerWon) external;

  /**
   * @dev Resolves a policy with a payout 0, unlocking the solvency. Can be called by anyone, but only after
   * `Policy.expiration`.
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not resolved
   * before
   * - Policy expired: `Policy.expiration` <= block.timestamp
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with payout == 0
   *
   * @param policy A policy previously created with `newPolicy`
   */
  function expirePolicy(Policy.PolicyData calldata policy) external;

  /**
   * @dev Returns whether a policy is active, i.e., it's still in the PolicyPool, not yet resolved or expired.
   *      Be aware that a policy might be active but the `block.timestamp` might be after the expiration date, so it
   *      can't be triggered with a payout.
   *
   * @param policyId The id of the policy queried
   * @return Whether the policy is active or not
   */
  function isActive(uint256 policyId) external view returns (bool);

  /**
   * @dev Returns the stored hash of the policy. It's `bytes32(0)` is the policy isn't active.
   *
   * @param policyId The id of the policy queried
   * @return Returns the hash of a given policy id
   */
  function getPolicyHash(uint256 policyId) external view returns (bytes32);

  /**
   * @dev Deposits liquidity into an eToken. Forwards the call to {EToken-deposit}, after transferring the funds.
   * The user will receive etokens for the same amount deposited.
   *
   * Requirements:
   * - `msg.sender` approved the spending of `currency()` for at least `amount`
   * - `eToken` is an active eToken installed in the pool.
   *
   * Events:
   * - {EToken-Transfer}: from 0x0 to `msg.sender`, reflects the eTokens minted.
   * - {ERC20-Transfer}: from `msg.sender` to address(eToken)
   *
   * @param eToken The address of the eToken to which the user wants to provide liquidity
   * @param amount The amount to deposit
   */
  function deposit(IEToken eToken, uint256 amount) external;

  /**
   * @dev Withdraws an amount from an eToken. Forwards the call to {EToken-withdraw}.
   * `amount` of eTokens will be burned and the user will receive the same amount in `currency()`.
   *
   * Requirements:
   * - `eToken` is an active (or deprecated) eToken installed in the pool.
   *
   * Events:
   * - {EToken-Transfer}: from `msg.sender` to `0x0`, reflects the eTokens burned.
   * - {ERC20-Transfer}: from address(eToken) to `msg.sender`
   *
   * @param eToken The address of the eToken from where the user wants to withdraw liquidity
   * @param amount The amount to withdraw. If equal to type(uint256).max, means full withdrawal.
   *               If the balance is not enough or can't be withdrawn (locked as SCR), it withdraws
   *               as much as it can, but doesn't fails.
   * @return Returns the actual amount withdrawn.
   */
  function withdraw(IEToken eToken, uint256 amount) external returns (uint256);
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
interface IERC165 {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IPolicyPool} from "./IPolicyPool.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IPolicyPoolComponent interface
 * @dev Interface for Contracts linked (owned) by a PolicyPool. Useful to avoid cyclic dependencies
 * @author Ensuro
 */
interface IPolicyPoolComponent is IERC165 {
  /**
   * @dev Returns the address of the PolicyPool (see {PolicyPool}) where this component belongs.
   */
  function policyPool() external view returns (IPolicyPool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title IAccessManager - Interface for the contract that handles roles for the PolicyPool and components
 * @dev Interface for the contract that handles roles for the PolicyPool and components
 * @author Ensuro
 */
interface IAccessManager is IAccessControlUpgradeable {
  /**
   * @dev Enum with the different governance actions supported in the protocol.
   *      It's good to keep actions of the same component consecutive, parts of the code relay on that,
   *      so we put some fillers in case new actions are added.
   */
  enum GovernanceActions {
    none,
    setTreasury, // Changes PolicyPool treasury address
    setAssetManager, // Change in the asset manager strategy of a reserve
    setAssetManagerForced, // Change in the asset manager strategy of a reserve, forced (deinvest failed)
    ppFiller1, // Reserve space for future PolicyPool or AccessManager actions
    ppFiller2, // Reserve space for future PolicyPool or AccessManager actions
    ppFiller3, // Reserve space for future PolicyPool or AccessManager actions
    ppFiller4, // Reserve space for future PolicyPool or AccessManager actions
    // RiskModule Governance Actions
    setMoc,
    setJrCollRatio,
    setCollRatio,
    setEnsuroPpFee,
    setEnsuroCocFee,
    setJrRoc,
    setSrRoc,
    setMaxPayoutPerPolicy,
    setExposureLimit,
    setMaxDuration,
    setWallet,
    rmFiller1, // Reserve space for future RM actions
    rmFiller2, // Reserve space for future RM actions
    rmFiller3, // Reserve space for future RM actions
    rmFiller4, // Reserve space for future RM actions
    // EToken Governance Actions
    setLPWhitelist, // Changes EToken Liquidity Providers Whitelist
    setLiquidityRequirement,
    setMinUtilizationRate,
    setMaxUtilizationRate,
    setInternalLoanInterestRate,
    etkFiller1, // Reserve space for future EToken actions
    etkFiller2, // Reserve space for future EToken actions
    etkFiller3, // Reserve space for future EToken actions
    etkFiller4, // Reserve space for future EToken actions
    // PremiumsAccount Governance Actions
    setDeficitRatio,
    setDeficitRatioWithAdjustment,
    setJrLoanLimit,
    setSrLoanLimit,
    paFiller3, // Reserve space for future PremiumsAccount actions
    paFiller4, // Reserve space for future PremiumsAccount actions
    // AssetManager Governance Actions
    setLiquidityMin,
    setLiquidityMiddle,
    setLiquidityMax,
    amFiller1, // Reserve space for future Asset Manager actions
    amFiller2, // Reserve space for future Asset Manager actions
    amFiller3, // Reserve space for future Asset Manager actions
    amFiller4, // Reserve space for future Asset Manager actions
    last
  }

  /**
   * @dev Gets a role identifier mixing the hash of the global role and the address of the component
   *
   * @param component The component where this role will apply
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @return A new role, mixing (XOR) the component address and the role.
   */
  function getComponentRole(address component, bytes32 role) external view returns (bytes32);

  /**
   * @dev Tells if a user has been granted a given role for a component
   *
   * @param component The component where this role will apply
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will return if the users has either the component role, or the role itself.
   *                   If false, only the component role is accepted
   * @return Whether the user has or not any of the roles
   */
  function hasComponentRole(
    address component,
    bytes32 role,
    address account,
    bool alsoGlobal
  ) external view returns (bool);

  /**
   * @dev Checks if a user has been granted a given role and reverts if it doesn't
   *
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   */
  function checkRole(bytes32 role, address account) external view;

  /**
   * @dev Checks if a user has been granted any of the two roles specified and reverts if it doesn't
   *
   * @param role1 A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param role2 Another role such as `keccak256("GUARDIAN_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   */
  function checkRole2(
    bytes32 role1,
    bytes32 role2,
    address account
  ) external view;

  /**
   * @dev Checks if a user has been granted a given component role and reverts if it doesn't
   *
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will accept not only the component role, but also the (global) `role` itself.
   *                   If false, only the component role is accepted
   */
  function checkComponentRole(
    address component,
    bytes32 role,
    address account,
    bool alsoGlobal
  ) external view;

  /**
   * @dev Checks if a user has been granted any of the two component roles specified and reverts if it doesn't
   *
   * @param role1 A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param role2 Another role such as `keccak256("GUARDIAN_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will accept not only the component roles, but also the global ones.
   *                   If false, only the component roles are accepted
   */
  function checkComponentRole2(
    address component,
    bytes32 role1,
    bytes32 role2,
    address account,
    bool alsoGlobal
  ) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;
import {WadRayMath} from "./dependencies/WadRayMath.sol";
import {IRiskModule} from "./interfaces/IRiskModule.sol";

/**
 * @title Policy library
 * @dev Library for PolicyData struct. This struct represents an active policy, how the premium is
 *      distributed, the probability of payout, duration and how the capital is locked.
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
library Policy {
  using WadRayMath for uint256;

  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  // Active Policies
  struct PolicyData {
    uint256 id;
    uint256 payout;
    uint256 premium;
    uint256 jrScr;
    uint256 srScr;
    uint256 lossProb; // original loss probability (in wad)
    uint256 purePremium; // share of the premium that covers expected losses
    // equal to payout * lossProb * riskModule.moc
    uint256 ensuroCommission; // share of the premium that goes for Ensuro
    uint256 partnerCommission; // share of the premium that goes for the RM
    uint256 jrCoc; // share of the premium that goes to junior liquidity providers (won or not)
    uint256 srCoc; // share of the premium that goes to senior liquidity providers (won or not)
    IRiskModule riskModule;
    uint40 start;
    uint40 expiration;
  }

  function initialize(
    IRiskModule riskModule,
    IRiskModule.Params memory rmParams,
    uint256 premium,
    uint256 payout,
    uint256 lossProb,
    uint40 expiration
  ) internal view returns (PolicyData memory newPolicy) {
    require(premium <= payout, "Premium cannot be more than payout");
    PolicyData memory policy;

    policy.riskModule = riskModule;
    policy.premium = premium;
    policy.payout = payout;
    policy.lossProb = lossProb;
    policy.start = uint40(block.timestamp);
    policy.expiration = expiration;
    policy.purePremium = payout.wadMul(lossProb.wadMul(rmParams.moc));
    // Calculate Junior and Senior SCR
    policy.jrScr = payout.wadMul(rmParams.jrCollRatio);
    if (policy.jrScr > policy.purePremium) {
      policy.jrScr -= policy.purePremium;
    } else {
      policy.jrScr = 0;
    }
    policy.srScr = payout.wadMul(rmParams.collRatio);
    if (policy.srScr > (policy.purePremium + policy.jrScr)) {
      policy.srScr -= policy.purePremium + policy.jrScr;
    } else {
      policy.srScr = 0;
    }
    // Calculate CoCs
    policy.jrCoc = policy.jrScr.wadMul(
      (rmParams.jrRoc * (policy.expiration - policy.start)) / SECONDS_PER_YEAR
    );
    policy.srCoc = policy.srScr.wadMul(
      (rmParams.srRoc * (policy.expiration - policy.start)) / SECONDS_PER_YEAR
    );
    uint256 coc = policy.jrCoc + policy.srCoc;
    policy.ensuroCommission =
      policy.purePremium.wadMul(rmParams.ensuroPpFee) +
      coc.wadMul(rmParams.ensuroCocFee);
    require(
      (policy.purePremium + policy.ensuroCommission + coc) <= premium,
      "Premium less than minimum"
    );
    policy.partnerCommission = premium - policy.purePremium - coc - policy.ensuroCommission;
    return policy;
  }

  function jrInterestRate(PolicyData memory policy) internal pure returns (uint256) {
    return
      ((policy.jrCoc * SECONDS_PER_YEAR) / (policy.expiration - policy.start)).wadDiv(policy.jrScr);
  }

  function jrAccruedInterest(PolicyData memory policy) internal view returns (uint256) {
    return (policy.jrCoc * (block.timestamp - policy.start)) / (policy.expiration - policy.start);
  }

  function srInterestRate(PolicyData memory policy) internal pure returns (uint256) {
    return
      ((policy.srCoc * SECONDS_PER_YEAR) / (policy.expiration - policy.start)).wadDiv(policy.srScr);
  }

  function srAccruedInterest(PolicyData memory policy) internal view returns (uint256) {
    return (policy.srCoc * (block.timestamp - policy.start)) / (policy.expiration - policy.start);
  }

  function hash(PolicyData memory policy) internal pure returns (bytes32 retHash) {
    retHash = keccak256(abi.encode(policy));
    require(retHash != bytes32(0), "Policy: hash cannot be 0");
    return retHash;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IEToken interface
 * @dev Interface for EToken smart contracts, these are the capital pools.
 * @author Ensuro
 */
interface IEToken is IERC20 {
  /**
   * @dev Enum of the different parameters that are configurable in an EToken.
   */
  enum Parameter {
    liquidityRequirement,
    minUtilizationRate,
    maxUtilizationRate,
    internalLoanInterestRate
  }

  /**
   * @dev Event emitted when part of the funds of the eToken are locked as solvency capital.
   * @param interestRate The annualized interestRate paid for the capital (wad)
   * @param value The amount locked
   */
  event SCRLocked(uint256 interestRate, uint256 value);

  /**
   * @dev Event emitted when the locked funds are unlocked and no longer used as solvency capital.
   * @param interestRate The annualized interestRate that was paid for the capital (wad)
   * @param value The amount unlocked
   */
  event SCRUnlocked(uint256 interestRate, uint256 value);

  /**
   * @dev Returns the amount of capital that's locked as solvency capital for active policies.
   */
  function scr() external view returns (uint256);

  /**
   * @dev Locks part of the liquidity of the EToken as solvency capital.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   * - `scrAmount` <= `fundsAvailableToLock()`
   *
   * Events:
   * - Emits {SCRLocked}
   *
   * @param scrAmount The amount to lock
   * @param policyInterestRate The annualized interest rate (wad) to be paid for the `scrAmount`
   */
  function lockScr(uint256 scrAmount, uint256 policyInterestRate) external;

  /**
   * @dev Unlocks solvency capital previously locked with `lockScr`. The capital no longer needed as solvency.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   * - `scrAmount` <= `scr()`
   *
   * Events:
   * - Emits {SCRUnlocked}
   *
   * @param scrAmount The amount to unlock
   * @param policyInterestRate The annualized interest rate that was paid for the `scrAmount`, must be the same that was
   * sent in `lockScr` call.
   */
  function unlockScr(
    uint256 scrAmount,
    uint256 policyInterestRate,
    int256 adjustment
  ) external;

  /**
   * @dev Registers a deposit of liquidity in the pool. Called from the PolicyPool, assumes the amount has already been
   * transferred. `amount` of eToken are minted and given to the provider in exchange of the liquidity provided.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   * - The amount was transferred
   * - `utilizationRate()` after the deposit is >= `minUtilizationRate()`
   *
   * Events:
   * - Emits {Transfer} with `from` = 0x0 and to = `provider`
   *
   * @param provider The address of the liquidity provider
   * @param amount The amount deposited.
   * @return The actual balance of the provider
   */
  function deposit(address provider, uint256 amount) external returns (uint256);

  /**
   * @dev Withdraws an amount from an eToken. `withdrawn` eTokens are be burned and the user receives the same amount
   * in `currency()`. If the asked `amount` can't be withdrawn, it withdraws as much as possible
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {Transfer} with `from` = `provider` and to = `0x0`
   *
   * @param provider The address of the liquidity provider
   * @param amount The amount to withdraw. If `amount` == `type(uint256).max`, then tries to withdraw all the balance.
   * @return withdrawn The actual amount that withdrawn. `withdrawn <= amount && withdrawn <= balanceOf(provider)`
   */
  function withdraw(address provider, uint256 amount) external returns (uint256 withdrawn);

  /**
   * @dev Returns the total amount that can be withdrawn
   */
  function totalWithdrawable() external view returns (uint256);

  /**
   * @dev Adds an authorized _borrower_ to the eToken. This _borrower_ will be allowed to lock/unlock funds and to take
   * loans.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {InternalBorrowerAdded}
   *
   * @param borrower The address of the _borrower_, a PremiumsAccount that has this eToken as senior or junior eToken.
   */
  function addBorrower(address borrower) external;

  /**
   * @dev Removes an authorized _borrower_ to the eToken. The _borrower_ can't no longer lock funds or take loans.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {InternalBorrowerRemoved} with the defaulted debt
   *
   * @param borrower The address of the _borrower_, a PremiumsAccount that has this eToken as senior or junior eToken.
   */
  function removeBorrower(address borrower) external;

  /**
   * @dev Lends `amount` to the borrower (msg.sender), transferring the money to `receiver`. This reduces the
   * `totalSupply()` of the eToken, and stores a debt that will be repaid (hopefully) with `repayLoan`.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   *
   * Events:
   * - Emits {InternalLoan}
   * - Emits {ERC20-Transfer} transferring `lent` to `receiver`
   *
   * @param amount The amount required
   * @param receiver The received of the funds lent. This is usually the policyholder if the loan is used for a payout.
   * @return Returns the amount that wasn't able to fulfil. `amount - lent`
   */
  function internalLoan(uint256 amount, address receiver) external returns (uint256);

  /**
   * @dev Repays a loan taken with `internalLoan`.
   *
   * Requirements:
   * - `msg.sender` approved the spending of `currency()` for at least `amount`

   * Events:
   * - Emits {InternalLoanRepaid}
   * - Emits {ERC20-Transfer} transferring `amount` from `msg.sender` to `this`
   *
   * @param amount The amount to repaid, that will be transferred from `msg.sender` balance.
   * @param onBehalfOf The address of the borrower that took the loan. Usually `onBehalfOf == msg.sender` but we keep it
   * open because in some cases with might need someone else pays the debt.
   */
  function repayLoan(uint256 amount, address onBehalfOf) external;

  /**
   * @dev Returns the updated debt (principal + interest) of the `borrower`.
   */
  function getLoan(address borrower) external view returns (uint256);

  /**
   * @dev The annualized interest rate at which the `totalSupply()` grows
   */
  function tokenInterestRate() external view returns (uint256);

  /**
   * @dev The weighted average annualized interest rate paid by the currently locked `scr()`.
   */
  function scrInterestRate() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IPremiumsAccount} from "./IPremiumsAccount.sol";

/**
 * @title IRiskModule interface
 * @dev Interface for RiskModule smart contracts. Gives access to RiskModule configuration parameters
 * @author Ensuro
 */
interface IRiskModule {
  /**
   * @dev Enum with the different parameters of the risk module, used in {RiskModule-setParam}.
   */
  enum Parameter {
    moc,
    jrCollRatio,
    collRatio,
    ensuroPpFee,
    ensuroCocFee,
    jrRoc,
    srRoc,
    maxPayoutPerPolicy,
    exposureLimit,
    maxDuration
  }

  /**
   * Struct of the parameters of the risk module that are used to calculate the different Policy fields (see
   * {Policy-PolicyData}.
   */
  struct Params {
    /**
     * @dev MoC (Margin of Conservativism) is a factor that multiplies the lossProb to increase or decrease the pure
     * premium.
     */
    uint256 moc;
    /**
     * @dev Junior Collateralization Ratio is the percentage of policy exposure (payout) that will be covered with the
     * purePremium and the Junior EToken
     */
    uint256 jrCollRatio;
    /**
     * @dev Collateralization Ratio is the percentage of policy exposure (payout) that will be covered by the
     * purePremium and the Junior and Senior EToken. Usually is calculated as the relation between VAR99.5% and VAR100
     * (full collateralization).
     */
    uint256 collRatio;
    /**
     * @dev Ensuro PurePremium Fee is the percentage that will be multiplied by the pure premium to obtain the part of
     * the Ensuro Fee that's proportional to the pure premium.
     */
    uint256 ensuroPpFee;
    /**
     * @dev Ensuro Cost of Capital Fee is the percentage that will be multiplied by the cost of capital (CoC) to
     * obtain the part of the Ensuro Fee that's proportional to the CoC.
     */
    uint256 ensuroCocFee;
    /**
     * @dev Junior Return on Capital is the annualized interest rate that's charged for the capital locked in the Junior
     * EToken.
     */
    uint256 jrRoc;
    /**
     * @dev Senior Return on Capital is the annualized interest rate that's charged for the capital locked in the Senior
     * EToken.
     */
    uint256 srRoc;
  }

  /**
   * @dev A readable name of this risk module. Never changes.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns different parameters of the risk module (see {Params})
   */
  function params() external view returns (Params memory);

  /**
   * @dev Returns the maximum duration (in hours) of the policies of this risk module.
   *      The `expiration` of the policies has to be `<= (block.timestamp + 3600 * maxDuration())`
   */
  function maxDuration() external view returns (uint256);

  /**
   * @dev Returns the maximum payout accepted for new policies.
   */
  function maxPayoutPerPolicy() external view returns (uint256);

  /**
   * @dev Returns sum of the (maximum) payout of the active policies of this risk module, i.e. the maximum possible
   * amount of money that's exposed for this risk module.
   */
  function activeExposure() external view returns (uint256);

  /**
   * @dev Returns maximum exposure (sum of the (maximum) payout of the active policies) of this risk module.
   * `activeExposure() <= exposureLimit()` always
   */
  function exposureLimit() external view returns (uint256);

  /**
   * @dev Returns the address of the partner that receives the partnerCommission
   */
  function wallet() external view returns (address);

  /**
   * @dev Called when a policy expires or is resolved to update the exposure.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * @param payout The exposure (maximum payout) of the policy
   */
  function releaseExposure(uint256 payout) external;

  /**
   * @dev Returns the {PremiumsAccount} where the premiums of this risk module are collected. Never changes.
   */
  function premiumsAccount() external view returns (IPremiumsAccount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IEToken} from "./IEToken.sol";
import {Policy} from "../Policy.sol";

/**
 * @title IPremiumsAccount interface
 * @dev Interface for Premiums Account contracts.
 * @author Ensuro
 */
interface IPremiumsAccount {
  /**
   * @dev Adds a policy to the PremiumsAccount. Stores the pure premiums and locks the aditional funds from junior and
   * senior eTokens.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {EToken-SCRLocked}
   *
   * @param policy The policy to add (created in this transaction)
   */
  function policyCreated(Policy.PolicyData memory policy) external;

  /**
   * @dev The PremiumsAccount is notified that the policy was resolved and issues the payout to the policyHolder.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {ERC20-Transfer}: `to == policyHolder`, `amount == payout`
   * - {EToken-InternalLoan}: optional, if a loan needs to be taken
   * - {EToken-SCRUnlocked}
   *
   * @param policyHolder The one that will receive the payout
   * @param policy The policy that was resolved
   * @param payout The amount that has to be transferred to `policyHolder`
   */
  function policyResolvedWithPayout(
    address policyHolder,
    Policy.PolicyData memory policy,
    uint256 payout
  ) external;

  /**
   * @dev The PremiumsAccount is notified that the policy has expired, unlocks the SCR and earns the pure premium.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {ERC20-Transfer}: `to == policyHolder`, `amount == payout`
   * - {EToken-InternalLoanRepaid}: optional, if a loan was taken before
   *
   * @param policy The policy that has expired
   */
  function policyExpired(Policy.PolicyData memory policy) external;

  /**
   * @dev The senior eToken, the secondary source of solvency, used if the premiums account is exhausted and junior too
   */
  function seniorEtk() external view returns (IEToken);

  /**
   * @dev The junior eToken, the primary source of solvency, used if the premiums account is exhausted.
   */
  function juniorEtk() external view returns (IEToken);

  /**
   * @dev The total amount of premiums hold by this PremiumsAccount
   */
  function purePremiums() external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "../interfaces/IQuadPassportStore.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadPassportStore is IQuadPassportStore, QuadConstant {

    IQuadGovernance public governance;
    address public pendingGovernance;

    // SignatureHash => bool
    mapping(bytes32 => bool) internal _usedSigHashes;

    string public symbol;
    string public name;

    // Key could be:
    // 1) keccak256(userAddress, keccak256(attrType))
    // 2) keccak256(DID, keccak256(attrType))
    mapping(bytes32 => Attribute[]) internal _attributes;

    // Key could be:
    // 1) keccak256(keccak256(userAddress, keccak256(attrType)), issuer)
    // 1) keccak256(keccak256(DID, keccak256(attrType)), issuer)
    mapping(bytes32 => uint256) internal _position;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "../storage/QuadGovernanceStore.sol";

interface IQuadGovernance {
    event AttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event BusinessAttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event EligibleTokenUpdated(uint256 _tokenId, bool _eligibleStatus);
    event EligibleAttributeUpdated(bytes32 _attribute, bool _eligibleStatus);
    event EligibleAttributeByDIDUpdated(bytes32 _attribute, bool _eligibleStatus);
    event IssuerAdded(address indexed _issuer, address indexed _newTreasury);
    event IssuerDeleted(address indexed _issuer);
    event IssuerStatusChanged(address indexed issuer, bool newStatus);
    event IssuerAttributePermission(address indexed issuer, bytes32 _attribute,  bool _permission);
    event PassportAddressUpdated(address indexed _oldAddress, address indexed _address);
    event RevenueSplitIssuerUpdated(uint256 _oldSplit, uint256 _split);
    event TreasuryUpdated(address indexed _oldAddress, address indexed _address);
    event PreapprovalUpdated(address indexed _account, bool _status);

    function setTreasury(address _treasury) external;

    function setPassportContractAddress(address _passportAddr) external;

    function updateGovernanceInPassport(address _newGovernance) external;

    function setEligibleTokenId(uint256 _tokenId, bool _eligibleStatus, string memory _uri) external;

    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) external;

    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) external;

    function setAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setBusinessAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setRevSplitIssuer(uint256 _split) external;

    function addIssuer(address _issuer, address _treasury) external;

    function deleteIssuer(address _issuer) external;

    function setIssuerStatus(address _issuer, bool _status) external;

    function setIssuerAttributePermission(address _issuer, bytes32 _attribute, bool _permission) external;

    function getEligibleAttributesLength() external view returns(uint256);

    function getMaxEligibleTokenId() external view returns(uint256);

    function eligibleTokenId(uint256) external view returns(bool);

    function issuersTreasury(address) external view returns (address);

    function eligibleAttributes(bytes32) external view returns(bool);

    function eligibleAttributesByDID(bytes32) external view returns(bool);

    function eligibleAttributesArray(uint256) external view returns(bytes32);

    function setPreapprovals(address[] calldata, bool[] calldata) external;

    function preapproval(address) external view returns(bool);

    function pricePerAttributeFixed(bytes32) external view returns(uint256);

    function pricePerBusinessAttributeFixed(bytes32) external view returns(uint256);

    function revSplitIssuer() external view returns (uint256);

    function treasury() external view returns (address);

    function getIssuersLength() external view returns (uint256);

    function getAllIssuersLength() external view returns (uint256);

    function getIssuers() external view returns (address[] memory);

    function getAllIssuers() external view returns (address[] memory);

    function issuers(uint256) external view returns(address);

    function getIssuerStatus(address _issuer) external view returns(bool);

    function getIssuerAttributePermission(address _issuer, bytes32 _attribute) external view returns(bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

contract QuadConstant {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant DIGEST_TO_SIGN = 0x37937bf5ff1ecbf00bbd389ab7ca9a190d7e8c0a084b2893ece7923be1d2ec85;
    bytes32 internal constant ATTRIBUTE_DID = 0x09deac0378109c72d82cccd3c343a90f7020f0f1af78dcd4fc949c6301aa9488;
    bytes32 internal constant ATTRIBUTE_IS_BUSINESS = 0xaf369ce728c816785c72f1ff0222ca9553b2cb93729d6a803be6af0d2369239b;
    bytes32 internal constant ATTRIBUTE_COUNTRY = 0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;
    bytes32 internal constant ATTRIBUTE_AML = 0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    uint256[47] private __gap;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "../interfaces/IQuadPassport.sol";

import "./QuadConstant.sol";

contract QuadGovernanceStore is QuadConstant {
    // Attributes
    bytes32[] internal _eligibleAttributesArray;
    mapping(bytes32 => bool) internal _eligibleAttributes;
    mapping(bytes32 => bool) internal _eligibleAttributesByDID;

    // TokenId
    mapping(uint256 => bool) internal _eligibleTokenId;

    // Pricing
    mapping(bytes32 => uint256) internal _pricePerBusinessAttributeFixed;
    mapping(bytes32 => uint256) internal _pricePerAttributeFixed;

    // Issuers
    mapping(address => address) internal _issuerTreasury;
    mapping(address => bool) internal _issuerStatus;
    mapping(bytes32 => bool) internal _issuerAttributePermission;
    address[] internal _issuers;

    // Others
    uint256 internal _revSplitIssuer; // 50 means 50%;
    uint256 internal _maxEligibleTokenId;
    IQuadPassport internal _passport;
    address internal _treasury;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "./IQuadPassportStore.sol";
import "./IQuadSoulbound.sol";

interface IQuadPassport is IQuadSoulbound {
    event GovernanceUpdated(address indexed _oldGovernance, address indexed _governance);
    event SetPendingGovernance(address indexed _pendingGovernance);
    event SetAttributeReceipt(address indexed _account, address indexed _issuer, uint256 _fee);
    event BurnPassportsIssuer(address indexed _issuer, address indexed _account);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function setAttributes(
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttributesBulk(
        IQuadPassportStore.AttributeSetterConfig[] memory _configs,
        bytes[] calldata _sigIssuers,
        bytes[] calldata _sigAccounts
    ) external payable;


    function setAttributesIssuer(
        address _account,
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) external payable;

    function attributeKey(
        address _account,
        bytes32 _attribute,
        address _issuer
    ) external view returns (bytes32);

    function attributeMetadata(
        address _account,
        bytes32[] memory _attributes
    ) external view returns (bytes32[] memory attributeTypes, address[] memory issuers, uint256[] memory issuedAts);

    function attributesExist(
        address _account,
        bytes32[] memory _attributes
    ) external view returns (bool[] memory);

    function burnPassports() external;

    function burnPassportsIssuer(address _account) external;

    function setGovernance(address _governanceContract) external;

    function acceptGovernance() external;

    function attribute(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute memory);

    function attributes(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute[] memory);

    function withdraw(address payable _to, uint256 _amount) external;

    function passportPaused() external view returns(bool);

    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

interface IQuadSoulbound  {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    function uri(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev ERC1155 balanceOf implementation
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IEToken} from "./IEToken.sol";

/**
 * @title ILPWhitelist - Interface that handles the whitelisting of Liquidity Providers
 * @author Ensuro
 */
interface ILPWhitelist {
  /**
   * @dev Indicates whether or not a liquidity provider can do a deposit in an eToken.
   *
   * @param etoken The eToken (see {EToken}) where the provider wants to deposit money.
   * @param provider The address of the liquidity provider (user) that wants to deposit
   * @param amount The amount of the deposit
   * @return true if `provider` deposit is accepted, false if not
   */
  function acceptsDeposit(
    IEToken etoken,
    address provider,
    uint256 amount
  ) external view returns (bool);

  /**
   * @dev Indicates whether or not the eTokens can be transferred from `providerFrom` to `providerTo`
   *
   * @param etoken The eToken (see {EToken}) that the LPs have the intention to transfer.
   * @param providerFrom The current owner of the tokens
   * @param providerTo The destination of the tokens if the transfer is accepted
   * @param amount The amount of tokens to be transferred
   * @return true if the transfer operation is accepted, false if not.
   */
  function acceptsTransfer(
    IEToken etoken,
    address providerFrom,
    address providerTo,
    uint256 amount
  ) external view returns (bool);

  /**
   * @dev Indicates whether or not a liquidity provider can withdraw an eToken.
   *
   * @param etoken The eToken (see {EToken}) where the provider wants to withdraw money.
   * @param provider The address of the liquidity provider (user) that wants to withdraw
   * @param amount The amount of the withdrawal
   * @return true if `provider` withdraw request is accepted, false if not
   */
  function acceptsWithdrawal(
    IEToken etoken,
    address provider,
    uint256 amount
  ) external view returns (bool);
}