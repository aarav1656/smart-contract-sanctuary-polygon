// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IERC20} from "../standard/ERC/ERC20/IERC20.sol";
import {Unsafe} from "../utils/Unsafe.sol";
import {Counters} from "../utils/Counters.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";
import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";

import {IOWCurrency} from "./IOWCurrency.sol";
import {CurrencyBase} from "./CurrencyBase.sol";
import {IOWProxy} from "../proxy/IOWProxy.sol";
import {IOWProviding} from "../providing/IOWProviding.sol";

contract OWCurrencyV1 is IOWCurrency, CurrencyBase, UUPSUpgradeable {
    using Unsafe for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    function initialize(
        IOWProxy _proxyContract,
        uint256 _accessVersion,
        uint256 _providingVersion,
        address _WMATIC,
        address _WETH
    ) public initializer {
        __Ownable_init();

        /******** proxyController setting ********/
        proxyContract = _proxyContract;

        /******** contract version setting ********/
        string[] memory types = new string[](2);
        types[0] = "Access";
        types[1] = "Providing";
        uint256[] memory versions = new uint256[](2);
        versions[0] = _accessVersion;
        versions[1] = _providingVersion;
        _initialSetContractVersion(types, versions);

        /******** contractController setting ********/
        isActive = true;

        /******** WMATIC setting ********/
        _initialSetCurrency(_WMATIC, _WETH);
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    //////////////
    // Currency //
    //////////////

    function _initialSetCurrency(address _WMATIC, address _WETH) private {
        currencyIds.increment();
        uint256 maticId = currencyIds.current();

        currencies[maticId] = Currency(
            maticId,
            0,
            block.timestamp,
            _WMATIC,
            "",
            true
        );

        currencyOfProject[0].add(maticId);
        currencyByTokenContract[0][_WMATIC] = maticId;

        currencyIds.increment();
        uint256 etherId = currencyIds.current();

        currencies[etherId] = Currency(
            etherId,
            0,
            block.timestamp,
            _WETH,
            "",
            true
        );

        currencyOfProject[0].add(etherId);
        currencyByTokenContract[0][_WETH] = etherId;

        emitCreate("Currency", maticId);
        emitCreate("Currency", etherId);
    }

    function addCurrency(
        uint256 _projectId,
        address _tokenContract,
        string calldata _URL
    ) external virtual whenContractActive onlyAdmin {
        if (_projectId != 0) {
            if (
                !IOWProviding(
                    proxyContract.getOWContractByType(
                        "Providing",
                        contractVersion["Providing"]
                    )
                ).isActiveProject(_projectId)
            ) {
                revert InvalidProjectId();
            }
        }

        if (
            IERC20(_tokenContract).totalSupply() < 0 ||
            IERC20(_tokenContract).allowance(address(this), address(this)) < 0
        ) {
            revert InvalidTokenContract();
        }

        if (isExistCurrencyByToken(_projectId, _tokenContract)) {
            revert AlreadyExistToken();
        }

        currencyIds.increment();
        uint256 currencyId = currencyIds.current();

        currencies[currencyId] = Currency(
            currencyId,
            _projectId,
            block.timestamp,
            _tokenContract,
            _URL,
            false
        );

        currencyOfProject[_projectId].add(currencyId);
        currencyByTokenContract[_projectId][_tokenContract] = currencyId;

        emitCreate("Currency", currencyId);
    }

    //////////////////
    // Currency Set //
    //////////////////

    function setCurrencyProject(uint256 _currencyId, uint256 _projectId)
        external
        onlyAdmin
    {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }

        if (_projectId != 0) {
            if (
                !IOWProviding(
                    proxyContract.getOWContractByType(
                        "Providing",
                        contractVersion["Providing"]
                    )
                ).isActiveProject(_projectId)
            ) {
                revert InvalidProjectId();
            }
        }

        if (
            isExistCurrencyByToken(
                _projectId,
                currencies[_currencyId].tokenContract
            )
        ) {
            revert AlreadyExistToken();
        }

        Currency storage currency = currencies[_currencyId];
        currencyOfProject[currency.projectId].remove(_currencyId);
        delete currencyByTokenContract[currency.projectId][
            currency.tokenContract
        ];

        currency.projectId = _projectId;
        currency.isActive = false;
        currencyOfProject[_projectId].add(_currencyId);
        currencyByTokenContract[_projectId][
            currency.tokenContract
        ] = _currencyId;
    }

    function setCurrencyURL(uint256 _currencyId, string calldata _URL)
        external
        onlyAdmin
    {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }

        currencies[_currencyId].URL = _URL;
    }

    function setCurrencyActive(uint256 _currencyId, bool _isActive)
        external
        onlyAdmin
    {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }

        currencies[_currencyId].isActive = _isActive;
    }

    function setCurrencyTokenContract(
        uint256 _currencyId,
        address _tokenContract
    ) external virtual onlyAdmin {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }
        if (
            IERC20(_tokenContract).totalSupply() < 0 ||
            IERC20(_tokenContract).allowance(address(this), address(this)) < 0
        ) {
            revert InvalidTokenContract();
        }
        if (
            isExistCurrencyByToken(
                currencies[_currencyId].projectId,
                _tokenContract
            )
        ) {
            revert AlreadyExistToken();
        }

        Currency storage currency = currencies[_currencyId];
        delete currencyByTokenContract[currency.projectId][
            currency.tokenContract
        ];

        currency.tokenContract = _tokenContract;
        currencyByTokenContract[currency.projectId][
            _tokenContract
        ] = _currencyId;
    }

    //////////////////
    // Currency Get //
    //////////////////

    function isExistCurrencyById(uint256 _currencyId)
        public
        view
        returns (bool)
    {
        return _currencyId != 0 && _currencyId <= currencyIds.current();
    }

    function isExistCurrencyByToken(uint256 _projectId, address _tokenContract)
        public
        view
        returns (bool)
    {
        uint256 currencyId = currencyByTokenContract[_projectId][
            _tokenContract
        ];

        return currencyId != 0 ? true : false;
    }

    function getCurrencyById(uint256 _currencyId)
        external
        view
        returns (Currency memory)
    {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }

        return currencies[_currencyId];
    }

    function getTokenContractByCurrencyId(uint256 _currencyId)
        external
        view
        returns (address)
    {
        if (!isExistCurrencyById(_currencyId)) {
            revert InvalidCurrencyId();
        }

        return currencies[_currencyId].tokenContract;
    }

    function getCurrencyOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (Currency[] memory)
    {
        if (_projectId != 0) {
            if (
                !IOWProviding(
                    proxyContract.getOWContractByType(
                        "Providing",
                        contractVersion["Providing"]
                    )
                ).isExistProjectById(_projectId)
            ) {
                revert InvalidProjectId();
            }
        }

        uint256 currencyCount;
        uint256[] memory currencyOfProject = currencyOfProject[_projectId]
            .values();

        if (_activeFilter) {
            for (
                uint256 i = 0;
                i < currencyOfProject.length;
                i = i.increment()
            ) {
                if (currencies[currencyOfProject[i]].isActive) {
                    currencyCount = currencyCount.increment();
                }
            }
        } else {
            currencyCount = currencyOfProject.length;
        }

        Currency[] memory result = new Currency[](currencyCount);
        uint256 index;

        for (uint256 i = 0; i < currencyOfProject.length; i = i.increment()) {
            if (_activeFilter) {
                if (currencies[currencyOfProject[i]].isActive) {
                    result[index] = currencies[currencyOfProject[i]];
                    index = index.increment();
                }
            } else {
                result[index] = currencies[currencyOfProject[i]];
                index = index.increment();
            }
        }

        return result;
    }

    function getCurrencyIdOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (uint256[] memory)
    {
        if (_projectId != 0) {
            if (
                !IOWProviding(
                    proxyContract.getOWContractByType(
                        "Providing",
                        contractVersion["Providing"]
                    )
                ).isExistProjectById(_projectId)
            ) {
                revert InvalidProjectId();
            }
        }

        uint256[] memory currencyOfProject = currencyOfProject[_projectId]
            .values();

        if (!_activeFilter) {
            return currencyOfProject;
        }

        uint256 currencyCount;

        for (uint256 i = 0; i < currencyOfProject.length; i = i.increment()) {
            if (currencies[currencyOfProject[i]].isActive) {
                currencyCount = currencyCount.increment();
            }
        }

        uint256[] memory activeCurrencyOfProject = new uint256[](currencyCount);
        uint256 index;

        for (uint256 i = 0; i < currencyOfProject.length; i = i.increment()) {
            if (currencies[currencyOfProject[i]].isActive) {
                activeCurrencyOfProject[index] = currencyOfProject[i];
                index = index.increment();
            }
        }

        return activeCurrencyOfProject;
    }

    function isValidCurrency(uint256 _currencyId, uint256 _projectId)
        external
        view
        returns (bool)
    {
        if (
            currencies[_currencyId].projectId == 0 &&
            currencies[_currencyId].isActive
        ) {
            return true;
        }

        return
            currencyOfProject[_projectId].contains(_currencyId) &&
            currencies[_currencyId].isActive;
    }

    function isActiveCurrency(uint256 _currencyId)
        external
        view
        returns (bool)
    {
        return currencies[_currencyId].isActive;
    }

    function isServiceCurrency(uint256 _currencyId)
        external
        view
        returns (bool)
    {
        return
            currencies[_currencyId].projectId == 0 &&
            isExistCurrencyById(_currencyId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../../openzeppelin/contracts/token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Unsafe {
    function increment(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Counters.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/proxy/utils/UUPSUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CurrencyBase} from "./CurrencyBase.sol";

interface IOWCurrency {
    //////////////
    // Currency //
    //////////////

    function addCurrency(
        uint256 _projectId,
        address _tokenContract,
        string calldata _URL
    ) external;

    //////////////////
    // Currency Set //
    //////////////////

    function setCurrencyProject(uint256 _currencyId, uint256 _projectId)
        external;

    function setCurrencyURL(uint256 _currencyId, string calldata _URL) external;

    function setCurrencyActive(uint256 _currencyId, bool _isActive) external;

    function setCurrencyTokenContract(
        uint256 _currencyId,
        address _tokenContract
    ) external;

    //////////////////
    // Currency Get //
    //////////////////

    function isExistCurrencyById(uint256 _currencyId)
        external
        view
        returns (bool);

    function isExistCurrencyByToken(uint256 _projectId, address _tokenContract)
        external
        view
        returns (bool);

    function getCurrencyOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (CurrencyBase.Currency[] memory);

    function getCurrencyIdOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (uint256[] memory);

    function getCurrencyById(uint256 _currencyId)
        external
        view
        returns (CurrencyBase.Currency memory);

    function getTokenContractByCurrencyId(uint256 _currencyId)
        external
        view
        returns (address);

    function isValidCurrency(uint256 _currencyId, uint256 _projectId)
        external
        view
        returns (bool);

    function isActiveCurrency(uint256 _currencyId) external view returns (bool);

    function isServiceCurrency(uint256 _currencyId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";

import {OWBase} from "../core/OWBase.sol";
import {OWControllerUpgradeable} from "../core/OWControllerUpgradeable.sol";
import {CurrencyError} from "../errors/CurrencyError.sol";

abstract contract CurrencyBase is
    OWBase,
    OWControllerUpgradeable,
    CurrencyError
{
    Counters.Counter public currencyIds;

    struct Currency {
        uint256 id;
        uint256 projectId;
        uint256 createdTimestamp;
        address tokenContract;
        string URL;
        bool isActive;
    }

    mapping(uint256 => Currency) internal currencies;

    mapping(uint256 => EnumerableSet.UintSet) internal currencyOfProject;
    mapping(uint256 => mapping(address => uint256))
        internal currencyByTokenContract;
}

// SPDX-License-Identifier: MIT

import {ProxyBase} from "./ProxyBase.sol";

pragma solidity ^0.8.9;

interface IOWProxy {
    ///////////////////
    // Contract Type //
    ///////////////////

    function addContractType(string calldata _type) external;

    ///////////////////////
    // Contract Type Set //
    ///////////////////////

    function setContractType(uint256 _typeId, string calldata _type) external;

    function removeContractType(uint256 _typeId) external;

    ///////////////////////
    // Contract Type Get //
    ///////////////////////

    function isExistContractTypeById(uint256 _typeId)
        external
        view
        returns (bool);

    function isExistContractType(string calldata _type)
        external
        view
        returns (bool);

    function getContractTypeId(string calldata _type)
        external
        view
        returns (uint256);

    function getContractTypeById(uint256 _typeId)
        external
        view
        returns (string memory);

    function getContractTypeIds() external view returns (uint256[] memory);

    function getContractTypes() external view returns (string[] memory);

    //////////////
    // Contract //
    //////////////

    function addContract(uint256 _typeId, address _OWContract) external;

    //////////////////
    // Contract Set //
    //////////////////

    function setContract(
        uint256 _typeId,
        uint256 _version,
        address _OWContract
    ) external;

    function removeLatestContract(uint256 _typeId) external;

    //////////////////
    // Contract Get //
    //////////////////

    function getOWContractByTypeId(uint256 _typeId, uint256 _version)
        external
        view
        returns (address);

    function isValidVersion(uint256 _typeId, uint256 _version)
        external
        view
        returns (bool);

    function getLatestVersion(uint256 _typeId) external view returns (uint256);

    function getOWContractByType(string calldata _type, uint256 _version)
        external
        view
        returns (address);

    function getContractOfType(uint256 _typeId)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {OWBase} from "../core/OWBase.sol";
import {ProvidingBase} from "./ProvidingBase.sol";
import {OfferingBase} from "../offering/OfferingBase.sol";
import {IOWDAOWalletFactory} from "../wallet/DAOWallet/IOWDAOWalletFactory.sol";

interface IOWProviding {
    /////////////
    // Royalty //
    /////////////

    function setRoyaltyInfo(
        uint96 _denominator,
        uint96 _providerRate,
        uint96 _operatorRate,
        uint96 _associatorRate,
        uint96 _creatorRate,
        uint96 _DAORate
    ) external;

    function getRoyaltyInfo()
        external
        view
        returns (ProvidingBase.RoyaltyInfo memory);

    /////////////
    // Project //
    /////////////

    function addProject(
        uint256 _operatorExpirationTimestamp,
        address payable _operator,
        address payable _associator,
        address payable _DAO,
        string calldata _URL
    ) external;

    /////////////////
    // Project Set //
    /////////////////

    function setProjectURL(uint256 _projectId, string calldata _URL) external;

    function setProjectOperator(uint256 _projectId, address payable _operator)
        external;

    function setProjectOperatorEXPTime(
        uint256 _projectId,
        uint256 _operatorExpirationTimestamp
    ) external;

    function setProjectNextOperator(
        uint256 _projectId,
        address payable _operator,
        uint256 _operatorExpirationTimestamp
    ) external;

    function setProjectAssociator(
        uint256 _projectId,
        address payable _associator
    ) external;

    function setProjectDAO(uint256 _projectId, address payable _DAO) external;

    function setProjectActive(uint256 _projectId, bool _isActive) external;

    /////////////////
    // Project Get //
    /////////////////

    function isExistProjectById(uint256 _projectId)
        external
        view
        returns (bool);

    function isActiveProject(uint256 _projectId) external view returns (bool);

    function getProjectById(uint256 _projectId)
        external
        view
        returns (ProvidingBase.Project memory);

    function getActiveProjectIds() external view returns (uint256[] memory);

    function getProjectIdByCollectionId(uint256 _collectionId)
        external
        view
        returns (uint256);

    //////////////
    // Universe //
    //////////////

    function addUniverse(uint256 _projectId, string calldata _URL) external;

    //////////////////
    // Universe Set //
    //////////////////

    function setUniverseURL(uint256 _universeId, string calldata _URL) external;

    function setUniverseProject(uint256 _universeId, uint256 _projectId)
        external;

    function setUniverseActive(uint256 _universeId, bool _isActive) external;

    function addCollectionOfUniverse(uint256 _universeId, uint256 _collectionId)
        external;

    function removeCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external;

    //////////////////
    // Universe Get //
    //////////////////

    function isExistUniverseById(uint256 _universeId)
        external
        view
        returns (bool);

    function isActiveUniverse(uint256 _universeId) external view returns (bool);

    function isValidUniverse(uint256 _universeId, uint256 _projectId)
        external
        view
        returns (bool);

    function getUniverseById(uint256 _universeId)
        external
        view
        returns (ProvidingBase.Universe memory, uint256[] memory);

    function getUniverseIdOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (uint256[] memory);

    ////////////////
    // Collection //
    ////////////////

    function addCollection(
        uint256 _projectId,
        address _tokenContract,
        address payable _creator,
        string calldata _URL
    ) external;

    ////////////////////
    // Collection Set //
    ////////////////////

    function setCollectionURL(uint256 _collectionId, string calldata _URL)
        external;

    function setCollectionProject(uint256 _collectionId, uint256 _projectId)
        external;

    function setCollectionTokenContract(
        uint256 _collectionId,
        address _tokenContract
    ) external;

    function setCollectionCreator(
        uint256 _collectionId,
        address payable _creator
    ) external;

    function setCollectionActive(uint256 _collectionId, bool _isActive)
        external;

    ////////////////////
    // Collection Get //
    ////////////////////

    function isExistCollectionById(uint256 _collectionId)
        external
        view
        returns (bool);

    function isExistTokenContract(address _tokenContract)
        external
        view
        returns (bool);

    function isActiveCollection(uint256 _collectionId)
        external
        view
        returns (bool);

    function isValidCollectionOfProject(
        uint256 _collectionId,
        uint256 _projectId
    ) external view returns (bool);

    function isValidCollectionOfUniverse(
        uint256 _collectionId,
        uint256 _universeId
    ) external view returns (bool);

    function getCollectionById(uint256 _collectionId)
        external
        view
        returns (ProvidingBase.Collection memory);

    function getCollectionIdByToken(address _tokenContract)
        external
        view
        returns (uint256);

    function getCollectionIdOfProject(uint256 _projectId, bool _activeFilter)
        external
        view
        returns (uint256[] memory);

    function getCollectionIdOfUniverse(uint256 _universeId, bool _activeFilter)
        external
        view
        returns (uint256[] memory);

    function getCollectionByToken(address _tokenContract)
        external
        view
        returns (ProvidingBase.Collection memory);

    function getTokenContractByCollectionId(uint256 _collectionId)
        external
        view
        returns (address);

    function getCollectionTypeByCollectionId(uint256 _collectionId)
        external
        view
        returns (ProvidingBase.TokenType);

    ////////////////////
    // MiniCollection //
    ////////////////////

    function addMiniCollection(
        uint256 _collectionId,
        uint256[] calldata _tokenIds
    ) external;

    function removeMiniCollection(uint256 _miniCollectionId) external;

    function setMiniCollectionActive(uint256 _miniCollectionId, bool _isActive)
        external;

    ////////////////////////
    // MiniCollection Get //
    ////////////////////////

    function isExistMiniCollectionById(uint256 _miniCollectionId)
        external
        view
        returns (bool);

    function isExistCollectionMultiToken(
        uint256 _collectionId,
        uint256 _tokenId
    ) external view returns (bool);

    function isActiveMiniCollection(uint256 _miniCollection)
        external
        view
        returns (bool);

    function isValidMiniCollectionOfProject(
        uint256 _miniCollectionId,
        uint256 _projectId
    ) external view returns (bool);

    function isValidMiniCollectionOfUniverse(
        uint256 _miniCollectionId,
        uint256 _universeId
    ) external view returns (bool);

    function isValidMiniCollectionOfCollection(
        uint256 _miniCollectionId,
        uint256 _collectionId
    ) external view returns (bool);

    function getMiniCollectionById(uint256 _miniCollectionId)
        external
        view
        returns (ProvidingBase.MiniCollection memory);

    function getMiniCollectionIdByCollectionTokenId(
        uint256 _collectionId,
        uint256 _tokenId
    ) external view returns (uint256);

    function getMiniCollectionIdOfCollection(
        uint256 _collectionId,
        bool _activeFilter
    ) external view returns (uint256[] memory);

    /////////////
    // Account //
    /////////////

    function getAccountsByCollectionId(uint256 _collectionId)
        external
        view
        returns (address payable[5] memory);

    function getAccountByAccountType(
        uint256 _collectionId,
        OWBase.AccountType _type
    ) external view returns (address payable);

    function getAccountByMintingType(
        uint256 _collectionId,
        OfferingBase.MintingType _type
    ) external view returns (address payable);

    //////////
    // Base //
    //////////

    function setProvider(address payable _provider) external;

    function setNLS(address payable _NLS) external;

    function setDAOWalletFactory(IOWDAOWalletFactory _DAOWalletFactory)
        external;

    function getProvider() external view returns (address payable);

    function getNLS() external view returns (address payable);

    function getDAOWalletFactory() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
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
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
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
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
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

pragma solidity ^0.8.9;

abstract contract OWBase {
    enum AccountType {
        Provider,
        Operator,
        Associator,
        Creator,
        DAO
    }

    event Create(string target, uint256 targetId, uint256 timestamp);

    function emitCreate(string memory _target, uint256 _targetId) internal {
        emit Create(_target, _targetId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "../utils/OwnableUpgradeable.sol";

import {AccessControllerUpgradeable} from "./controllerUpgradeable/AccessControllerUpgradeable.sol";
import {ContractControllerUpgradeable} from "./controllerUpgradeable/ContractControllerUpgradeable.sol";
import {ProxyController} from "./controller/ProxyController.sol";
import {VersionController} from "./controller/VersionController.sol";
import {IOWProxy} from "../proxy/IOWProxy.sol";

abstract contract OWControllerUpgradeable is
    AccessControllerUpgradeable,
    ContractControllerUpgradeable,
    OwnableUpgradeable
{
    function setProxyContract(IOWProxy _proxyContract)
        public
        override(ProxyController)
        onlyOwner
    {
        super.setProxyContract(_proxyContract);
    }

    function contractActive()
        public
        override(ContractControllerUpgradeable)
        onlyAdmin
    {
        super.contractActive();
    }

    function contractUnActive()
        public
        override(ContractControllerUpgradeable)
        onlyAdmin
    {
        super.contractUnActive();
    }

    function setContractVersion(string memory _type, uint256 _version)
        public
        override(VersionController)
        onlyAdmin
    {
        super.setContractVersion(_type, _version);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface CurrencyError {
    /////////////
    // Project //
    /////////////

    error InvalidProjectId();

    //////////////
    // Currency //
    //////////////

    error InvalidTokenContract();
    error AlreadyExistToken();
    error InvalidCurrencyId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/access/OwnableUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";

import {VersionController} from "../controller/VersionController.sol";
import {AccessControllerError} from "../../errors/AccessControllerError.sol";
import {IOWAccessLookup} from "../../access/IOWAccessLookup.sol";

abstract contract AccessControllerUpgradeable is
    VersionController,
    AccessControllerError,
    ContextUpgradeable
{
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        if (
            !IOWAccessLookup(
                proxyContract.getOWContractByType(
                    "Access",
                    contractVersion["Access"]
                )
            ).isAdmin(_msgSender())
        ) {
            revert Unauthorized();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";

import {ContractControllerError} from "../../errors/ContractControllerError.sol";

abstract contract ContractControllerUpgradeable is
    ContractControllerError,
    ContextUpgradeable
{
    bool public isActive;

    event ContractActive(address account, uint256 timestamp);
    event ContractUnActive(address account, uint256 timestamp);

    /////////////////////
    // Contract Active //
    /////////////////////

    modifier whenContractActive() {
        if (!isActive) {
            revert UnActive();
        }
        _;
    }

    function contractUnActive() public virtual {
        if (!isActive) {
            revert AlreadyUnActive();
        }

        isActive = false;
        emit ContractUnActive(_msgSender(), block.timestamp);
    }

    function contractActive() public virtual {
        if (isActive) {
            revert AlreadyActive();
        }

        isActive = true;
        emit ContractActive(_msgSender(), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IOWProxy} from "../../proxy/IOWProxy.sol";

abstract contract ProxyController {
    IOWProxy internal proxyContract;

    ///////////
    // Proxy //
    ///////////

    function setProxyContract(IOWProxy _proxyContract) public virtual {
        proxyContract = _proxyContract;
    }

    function getProxyContract() external view returns (address) {
        return address(proxyContract);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ProxyController} from "./ProxyController.sol";
import {ProxyError} from "../../errors/ProxyError.sol";

abstract contract VersionController is ProxyController, ProxyError {
    mapping(string => uint256) internal contractVersion;

    //////////////////////
    // Contract Version //
    //////////////////////

    function _initialSetContractVersion(
        string[] memory _types,
        uint256[] memory _versions
    ) internal {
        require(_types.length == _versions.length);

        for (uint256 i = 0; i < _types.length; i++) {
            if (!proxyContract.isExistContractType(_types[i])) {
                revert InvalidType();
            }
            contractVersion[_types[i]] = _versions[i];
        }
    }

    function setContractVersion(string memory _type, uint256 _version)
        public
        virtual
    {
        if (!proxyContract.isExistContractType(_type)) {
            revert InvalidType();
        }
        uint256 typeId = proxyContract.getContractTypeId(_type);

        if (!proxyContract.isValidVersion(typeId, _version)) {
            revert InvalidVersion();
        }

        contractVersion[_type] = _version;
    }

    function getContractVersion(string calldata _type)
        external
        view
        returns (uint256)
    {
        return contractVersion[_type];
    }
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/ContextUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface AccessControllerError {
    error Unauthorized();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOWAccessLookup {
    function isAdmin(address _member) external view returns (bool);

    function isStaking(address _member) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ProxyError {
    //////////////////
    // ContractType //
    //////////////////

    error AlreadyExistType();
    error InvalidType();
    error InvalidTypeId();

    //////////////
    // Contract //
    //////////////

    error InvalidVersion();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";

import {OWBase} from "../core/OWBase.sol";
import {ProxyError} from "../errors/ProxyError.sol";
import {ContractController} from "../core/controller/ContractController.sol";

contract ProxyBase is OWBase, ContractController, ProxyError {
    Counters.Counter public typeIds;

    mapping(uint256 => string) internal contractTypes;
    mapping(uint256 => Counters.Counter) internal versions;
    mapping(uint256 => mapping(uint256 => address)) internal contracts;

    mapping(bytes32 => uint256) internal typeByName;

    event ContractAdded(
        uint256 typeId,
        uint256 version,
        address OWContract,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Context} from "../../utils/Context.sol";

import {ContractControllerError} from "../../errors/ContractControllerError.sol";

abstract contract ContractController is ContractControllerError, Context {
    bool public isActive;

    event ContractActive(address account, uint256 timestamp);
    event ContractUnActive(address account, uint256 timestamp);

    /////////////////////
    // Contract Active //
    /////////////////////

    modifier whenContractActive() {
        if (!isActive) {
            revert UnActive();
        }
        _;
    }

    function contractUnActive() public virtual {
        if (!isActive) {
            revert AlreadyUnActive();
        }

        isActive = false;
        emit ContractUnActive(_msgSender(), block.timestamp);
    }

    function contractActive() public virtual {
        if (isActive) {
            revert AlreadyActive();
        }

        isActive = true;
        emit ContractActive(_msgSender(), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ContractControllerError {
    error UnActive();
    error AlreadyUnActive();
    error AlreadyActive();
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

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";

import {OWBase} from "../core/OWBase.sol";
import {OWControllerUpgradeable} from "../core/OWControllerUpgradeable.sol";
import {ProvidingError} from "../errors/ProvidingError.sol";
import {IOWDAOWalletFactory} from "../wallet/DAOWallet/IOWDAOWalletFactory.sol";

abstract contract ProvidingBase is
    OWBase,
    OWControllerUpgradeable,
    ProvidingError
{
    Counters.Counter public projectIds;
    Counters.Counter public universeIds;
    Counters.Counter public collectionIds;
    Counters.Counter public miniCollectionIds;

    address payable internal provider;
    address payable internal NLS;
    IOWDAOWalletFactory internal DAOWalletFactory;

    struct RoyaltyInfo {
        uint96 denominator;
        uint96 providerRate;
        uint96 operatorRate;
        uint96 associatorRate;
        uint96 creatorRate;
        uint96 DAORate;
    }

    struct Project {
        uint256 id;
        uint256 operatorExpirationTimestamp;
        uint256 operatorSequence;
        uint256 createdTimestamp;
        address payable operator;
        address payable associator;
        address payable DAO;
        string URL;
        bool NLSOperation;
        bool NLSAssociation;
        bool isActive;
    }

    struct Universe {
        uint256 id;
        uint256 projectId;
        uint256 createdTimestamp;
        string URL;
        bool isActive;
    }

    struct Collection {
        uint256 id;
        uint256 projectId;
        uint256 createdTimestamp;
        address tokenContract;
        address payable creator;
        string URL;
        bool NLSCreation;
        bool isActive;
        TokenType tokenType;
    }

    struct MiniCollection {
        uint256 id;
        uint256 collectionId;
        uint256 tokenId;
        uint256 createdTimestamp;
        bool isActive;
    }

    mapping(uint256 => Project) internal projects;
    mapping(uint256 => Universe) internal universes;
    mapping(uint256 => Collection) internal collections;
    mapping(uint256 => MiniCollection) internal miniCollections;

    mapping(uint256 => EnumerableSet.UintSet) internal universeOfProject;
    mapping(uint256 => EnumerableSet.UintSet) internal collectionOfProject;
    mapping(uint256 => EnumerableSet.UintSet) internal collectionOfUniverse;
    mapping(uint256 => EnumerableSet.UintSet)
        internal miniCollectionOfCollection;
    mapping(address => uint256) internal collectionByTokenContract;
    mapping(uint256 => mapping(uint256 => uint256))
        internal multiTokenByCollection;

    enum TokenType {
        ERC721,
        ERC1155
    }

    RoyaltyInfo internal royaltyInfo;

    event SetRoyaltyInfo(
        uint96 denominator,
        uint96 providerRate,
        uint96 operatorRate,
        uint96 associatorRate,
        uint96 creatorRate,
        uint96 DAORate,
        uint256 timestamp
    );
    event SetProvider(address provider, uint256 timestamp);
    event SetNLS(address NLS, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";

import {OWBase} from "../core/OWBase.sol";
import {OWControllerUpgradeable} from "../core/OWControllerUpgradeable.sol";
import {OfferingError} from "../errors/OfferingError.sol";

abstract contract OfferingBase is
    OWBase,
    OWControllerUpgradeable,
    OfferingError
{
    Counters.Counter public offeringIds;

    struct Offering {
        uint256 id;
        uint256 collectionId;
        uint256 multiTokenId;
        uint256 currencyId;
        uint256 supply;
        uint256 price;
        uint256[7] supplyTo;
        uint256 accountMaxSupply;
    }

    struct Timestamp {
        uint256 startTimestamp;
        uint256 whitelistExpirationTimestamp;
        uint256 endTimestamp;
    }

    struct MintingCount {
        uint256 offeringId;
        uint256 totalMinting;
        uint256 byProvider;
        uint256 byOperator;
        uint256 byAssociator;
        uint256 byCreator;
        uint256 byDAO;
        uint256 byWhitelist;
        uint256 byPublic;
        uint256 remaining;
    }

    struct OfferingInput {
        uint256 collectionId;
        uint256 multiTokenId;
        uint256 currencyId;
        uint256 supply;
        uint256 price;
        uint256[6] supplyTo;
        uint256 accountMaxSupply;
        uint256 startTimestamp;
        uint256 whitelistExpirationTimestamp;
        uint256 endTimestamp;
    }

    mapping(uint256 => Offering) internal offerings;
    mapping(uint256 => Timestamp) internal timestampOfOffering;
    mapping(uint256 => MintingCount) internal mintingCountOfOffering;
    mapping(uint256 => bytes32) internal whitelistMerkleRoot;
    mapping(uint256 => mapping(address => uint256))
        internal accountMintingCountOfOffering;
    mapping(uint256 => uint256) internal supplyOfCollection;
    mapping(uint256 => mapping(uint256 => uint256)) internal supplyOfMultiToken;

    mapping(uint256 => EnumerableSet.UintSet) internal offeringOfCollection;
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet))
        internal offeringOfMultiToken;

    enum MintingType {
        Provider,
        Operator,
        Associator,
        Creator,
        DAO,
        Whitelist,
        Public,
        Remaining
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOWDAOWalletFactory {
    function deployDAOWallet(uint256 _projectId)
        external
        returns (address payable _deployed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ProvidingError {
    /////////////
    // Project //
    /////////////

    error InvalidProjectId();

    //////////////
    // Universe //
    //////////////

    error InvalidUniverseId();

    ////////////////
    // Collection //
    ////////////////

    error InvalidCollectionId();
    error AlreadyExistTokenContract();
    error AlreadyExistMiniCollection();
    error InvalidTokenContract();
    error InvalidGovernanceWeight();
    error InvalidArgument();

    ////////////////////
    // MiniCollection //
    ////////////////////

    error InvalidMiniCollectionId();
    error InvalidCollectionTokenType();
    error AlreadyExistMultiTokenId();

    /////////////
    // Royalty //
    /////////////

    error ExceedDenominator();

    /////////////
    // Account //
    /////////////

    error InvalidAccountType();
    error InvalidMintingType();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface OfferingError {
    ////////////////
    // Collection //
    ////////////////

    error InvalidCollectionId();

    //////////////
    // Currency //
    //////////////

    error InvalidCurrencyId();

    //////////////
    // Offering //
    //////////////

    error InvalidMultiTokenId();
    error InvalidTimestamp();
    error InvalidSupply();
    error InvalidOfferingId();
    error AlreadyStartOffering();
    error FreeOffering();

    //////////////////
    // MintingCount //
    //////////////////

    error InvalidMintingType();
    error OnlyMintingContract();
    error ExceedSupply();
    error ExceedSupplyLimitOfAccount();
}