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
pragma solidity ^0.8.0;

/*
███████╗██████╗  ██████╗ ███████╗████████╗██╗   ██╗                 
██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝╚██╗ ██╔╝                 
█████╗  ██████╔╝██║   ██║███████╗   ██║    ╚████╔╝                  
██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║     ╚██╔╝                   
██║     ██║  ██║╚██████╔╝███████║   ██║      ██║                    
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝                    
                                                                    
███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗      █████╗ ██████╗        
████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔══██╗██╔══██╗       
██╔████╔██║██║   ██║██║  ██║██║   ██║██║     ███████║██████╔╝       
██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══██║██╔══██╗       
██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗██║  ██║██║  ██║       
╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       
                                                                    
██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗     
██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██╔═══██╗██║     
██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗╚██████╔╝███████╗
╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝
*/

/// ============ Imports ============

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFRSTSDK.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./storage/TokenGateConfig.sol";

contract FRSTVaultNFT is Ownable {
  /// ============ Immutable storage ============

  /// @notice implementation addresses for base contracts
  address public FRST721AImplementation;
  address public FRST4907AImplementation;
  address public FRSTCrescendoImplementation;
  address public FRSTVaultImplementation;
  address public FRSTStakingImplementation;
  address public ZKEditionImplementation;

  /// @notice address of the metadata renderer
  address public metadataRenderer;

  /// @notice address of the associated registry
  address public contractRegistry;

  /// @notice addresses for splits contract
  address public SplitMain;

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event Create(address nft, address vault);

  /// ============ Constructor ============

  /// @notice Creates a new FrostyVaultWrapped instance
  constructor(address _FRSTSDK) {
    IFRSTSDK sdk = IFRSTSDK(_FRSTSDK);
    FRST721AImplementation = sdk.FRST721AImplementation();
    FRST4907AImplementation = sdk.FRST4907AImplementation();
    FRSTVaultImplementation = sdk.FRSTVaultImplementation();
    metadataRenderer = sdk.metadataRenderer();
    contractRegistry = sdk.contractRegistry();
    SplitMain = sdk.SplitMain();
  }

  /// ============ Functions ============

  function create(
    address _FRSTSDK,
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig,
    address _vaultDistributionTokenAddress,
    uint256 _unlockDate,
    bool _supports4907
  ) external returns (address nft, address vault) {
    address deployedNFT;
    if (_supports4907) {
      (bool success1, bytes memory data1) = _FRSTSDK.delegatecall(
        abi.encodeWithSignature(
          "deployFRST4907A("
            "(string,string,bool,uint256,uint256,uint256,bytes32,uint256,uint256,uint256,uint256,uint256),"
            "(string,string,bytes,address),"
            "(address,uint88,uint8)"
          ")",
          _editionConfig,
          _metadataConfig,
          _tokenGateConfig
        )
      );

      require(success1);
      deployedNFT = abi.decode(data1, (address));
    } else {
      (bool success2, bytes memory data2) = _FRSTSDK.delegatecall(
        abi.encodeWithSignature(
          "deployFRST721A("
            "(string,string,bool,uint256,uint256,uint256,bytes32,uint256,uint256,uint256,uint256,uint256),"
            "(string,string,bytes,address),"
            "(address,uint88,uint8)"
          ")",
          _editionConfig,
          _metadataConfig,
          _tokenGateConfig
        )
      );

      require(success2);
      deployedNFT = abi.decode(data2, (address));
    }

    (bool success, bytes memory data) = _FRSTSDK.delegatecall(
      abi.encodeWithSignature(
        "deployFRSTVault(address,address,uint256,uint256)",
        _vaultDistributionTokenAddress,
        deployedNFT,
        _editionConfig.maxTokens,
        _unlockDate
      )
    );

    require(success);
    address deployedVault = abi.decode(data, (address));

    emit Create(deployedNFT, deployedVault);
    return (deployedNFT, deployedVault);
  }

  function bytesToAddress(bytes memory _bytes)
    private
    pure
    returns (address addr)
  {
    assembly {
      addr := mload(add(_bytes, 32))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFRSTSDK {
  /// @notice implementation addresses for base contracts
  function FRST721AImplementation() external returns (address);

  function FRST4907AImplementation() external returns (address);

  function FRSTCrescendoImplementation() external returns (address);

  function FRSTVaultImplementation() external returns (address);

  function FRSTStakingImplementation() external returns (address);

  function metadataRenderer() external returns (address);

  function contractRegistry() external returns (address);

  function SplitMain() external returns (address);

  /// ============ Functions ============

  // deploy and initialize an erc721a clone
  function deployFRST721A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize an erc4907a clone
  function deployFRST4907A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize a Crescendo clone
  function deployFRSTCrescendo(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _initialPrice,
    uint256 _step1,
    uint256 _step2,
    uint256 _hitch,
    uint256 _trNum,
    uint256 _trDenom,
    address payable _payouts
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployFRSTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployFRSTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  bool hasAdjustableCap;
  uint256 maxTokens;
  uint256 tokenPrice;
  uint256 maxTokenPurchase;
  bytes32 presaleMerkleRoot;
  uint256 presaleStart;
  uint256 presaleEnd;
  uint256 saleStart;
  uint256 saleEnd;
  uint256 royaltyBPS;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct MetadataConfig {
  string contractURI;
  string metadataURI;
  bytes metadataRendererInit;
  address parentIP;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum SaleType {
  ALL,
  PRESALE,
  PRIMARY
}

struct TokenGateConfig {
  address tokenAddress; 
  uint88 minBalance;
  SaleType saleType;
}