/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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


// File contracts/LayerZero/IOFTCore.sol




/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
  /**
   * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
   * _dstChainId - L0 defined chain id to send tokens too
   * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
   * _amount - amount of the tokens to transfer
   * _useZro - indicates to use zro to pay L0 fees
   * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
   */
  function estimateSendFee(
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _amount,
    bool _useZro,
    bytes calldata _adapterParams
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  /**
   * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
   * `_from` the owner of token
   * `_dstChainId` the destination chain identifier
   * `_toAddress` can be any size depending on the `dstChainId`.
   * `_amount` the quantity of tokens in wei
   * `_refundAddress` the address LayerZero refunds if too much message fee is sent
   * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
   * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
   */
  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _amount,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  /**
   * @dev returns the circulating amount of tokens on current chain
   */
  function circulatingSupply() external view returns (uint256);

  /**
   * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
   * `_nonce` is the outbound nonce
   */
  event SendToChain(
    uint16 indexed _dstChainId,
    address indexed _from,
    bytes indexed _toAddress,
    uint256 _amount
  );

  /**
   * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
   * `_nonce` is the inbound nonce.
   */
  event ReceiveFromChain(
    uint16 indexed _srcChainId,
    bytes indexed _srcAddress,
    address indexed _toAddress,
    uint256 _amount
  );
}


// File contracts/LayerZero/interfaces/ILayerZeroReceiver.sol



interface ILayerZeroReceiver {
  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) external;
}


// File contracts/LayerZero/interfaces/ILayerZeroUserApplicationConfig.sol




interface ILayerZeroUserApplicationConfig {
  // @notice set the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _configType - type of configuration. every messaging library has its own convention.
  // @param _config - configuration in the bytes. can encode arbitrary content.
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external;

  // @notice set the send() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setSendVersion(uint16 _version) external;

  // @notice set the lzReceive() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setReceiveVersion(uint16 _version) external;

  // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
  // @param _srcChainId - the chainId of the source chain
  // @param _srcAddress - the contract address of the source contract at the source chain
  function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
    external;
}


// File contracts/LayerZero/interfaces/ILayerZeroEndpoint.sol




interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  // @notice used by the messaging library to publish verified payload
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source contract (as bytes) at the source chain
  // @param _dstAddress - the address on destination chain
  // @param _nonce - the unbound message ordering nonce
  // @param _gasLimit - the gas limit for external contract execution
  // @param _payload - verified payload to send to the destination contract
  function receivePayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    address _dstAddress,
    uint64 _nonce,
    uint256 _gasLimit,
    bytes calldata _payload
  ) external;

  // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (uint64);

  // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
  // @param _srcAddress - the source chain contract address
  function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
    external
    view
    returns (uint64);

  // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
  // @param _dstChainId - the destination chain identifier
  // @param _userApplication - the user app address on this EVM chain
  // @param _payload - the custom message to send over LayerZero
  // @param _payInZRO - if false, user app pays the protocol fee in native token
  // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
  function estimateFees(
    uint16 _dstChainId,
    address _userApplication,
    bytes calldata _payload,
    bool _payInZRO,
    bytes calldata _adapterParam
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  // @notice get this Endpoint's immutable source identifier
  function getChainId() external view returns (uint16);

  // @notice the interface to retry failed message on this Endpoint destination
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _payload - the payload to be retried
  function retryPayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    bytes calldata _payload
  ) external;

  // @notice query if any STORED payload (message blocking) at the endpoint.
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (bool);

  // @notice query if the _libraryAddress is valid for sending msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getSendLibraryAddress(address _userApplication)
    external
    view
    returns (address);

  // @notice query if the _libraryAddress is valid for receiving msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getReceiveLibraryAddress(address _userApplication)
    external
    view
    returns (address);

  // @notice query if the non-reentrancy guard for send() is on
  // @return true if the guard is on. false otherwise
  function isSendingPayload() external view returns (bool);

  // @notice query if the non-reentrancy guard for receive() is on
  // @return true if the guard is on. false otherwise
  function isReceivingPayload() external view returns (bool);

  // @notice get the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _userApplication - the contract address of the user application
  // @param _configType - type of configuration. every messaging library has its own convention.
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address _userApplication,
    uint256 _configType
  ) external view returns (bytes memory);

  // @notice get the send() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getSendVersion(address _userApplication)
    external
    view
    returns (uint16);

  // @notice get the lzReceive() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getReceiveVersion(address _userApplication)
    external
    view
    returns (uint16);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)



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


// File contracts/LayerZero/lzApp/LzApp.sol







/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
  Ownable,
  ILayerZeroReceiver,
  ILayerZeroUserApplicationConfig
{
  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  mapping(uint16 => mapping(uint256 => uint256)) public minDstGasLookup;

  event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
  event SetMinDstGasLookup(
    uint16 _dstChainId,
    uint256 _type,
    uint256 _dstGasAmount
  );

  constructor(address _endpoint) {
    lzEndpoint = ILayerZeroEndpoint(_endpoint);
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public virtual override {
    // lzReceive must be called by the endpoint for security
    require(
      _msgSender() == address(lzEndpoint),
      "LzApp: invalid endpoint caller"
    );

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    require(
      _srcAddress.length == trustedRemote.length &&
        keccak256(_srcAddress) == keccak256(trustedRemote),
      "LzApp: invalid source sending contract"
    );

    _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function _lzSend(
    uint16 _dstChainId,
    bytes memory _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) internal virtual {
    bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
    require(
      trustedRemote.length != 0,
      "LzApp: destination chain is not a trusted source"
    );
    lzEndpoint.send{ value: msg.value }(
      _dstChainId,
      trustedRemote,
      _payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _checkGasLimit(
    uint16 _dstChainId,
    uint256 _type,
    bytes memory _adapterParams,
    uint256 _extraGas
  ) internal view {
    uint256 providedGasLimit = getGasLimit(_adapterParams);
    uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
    require(minGasLimit > 0, "LzApp: minGasLimit not set");
    require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
  }

  function getGasLimit(bytes memory _adapterParams)
    internal
    pure
    returns (uint256 gasLimit)
  {
    require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
    assembly {
      gasLimit := mload(add(_adapterParams, 34))
    }
  }

  //---------------------------UserApplication config----------------------------------------
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address,
    uint256 _configType
  ) external view returns (bytes memory) {
    return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
  }

  // generic config for LayerZero user Application
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external override onlyOwner {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setSendVersion(_version);
  }

  function setReceiveVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setReceiveVersion(_version);
  }

  function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    override
    onlyOwner
  {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }

  // allow owner to set it multiple times.
  function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    onlyOwner
  {
    trustedRemoteLookup[_srcChainId] = _srcAddress;
    emit SetTrustedRemote(_srcChainId, _srcAddress);
  }

  function setMinDstGasLookup(
    uint16 _dstChainId,
    uint256 _type,
    uint256 _dstGasAmount
  ) external onlyOwner {
    require(_dstGasAmount > 0, "LzApp: invalid _dstGasAmount");
    minDstGasLookup[_dstChainId][_type] = _dstGasAmount;
    emit SetMinDstGasLookup(_dstChainId, _type, _dstGasAmount);
  }

  //--------------------------- VIEW FUNCTION ----------------------------------------
  function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (bool)
  {
    bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
    return keccak256(trustedSource) == keccak256(_srcAddress);
  }
}


// File contracts/LayerZero/lzApp/NonblockingLzApp.sol




/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
  constructor(address _endpoint) LzApp(_endpoint) {}

  mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
    public failedMessages;

  event MessageFailed(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes _payload
  );

  // overriding the virtual function in LzReceiver
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual override {
    // try-catch all errors/exceptions
    try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
    }
  }

  function nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public virtual {
    // only internal transaction
    require(
      _msgSender() == address(this),
      "NonblockingLzApp: caller must be LzApp"
    );
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  //@notice override this function
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function retryMessage(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public payable virtual {
    // assert there is message to retry
    bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
    require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
    require(
      keccak256(_payload) == payloadHash,
      "NonblockingLzApp: invalid payload"
    );
    // clear the stored message
    failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
    // execute the message. revert if it fails again
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File contracts/LayerZero/OFTCore.sol






abstract contract OFTCore is NonblockingLzApp, ERC165, IOFTCore {
  uint256 public constant NO_EXTRA_GAS = 0;
  uint256 public constant FUNCTION_TYPE_SEND = 1;
  bool public useCustomAdapterParams;

  event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

  constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IOFTCore).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function estimateSendFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _amount,
    bool _useZro,
    bytes memory _adapterParams
  ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
    // mock the payload for send()
    bytes memory payload = abi.encode(_toAddress, _amount);
    return
      lzEndpoint.estimateFees(
        _dstChainId,
        address(this),
        payload,
        _useZro,
        _adapterParams
      );
  }

  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _amount,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable virtual override {
    _send(
      _from,
      _dstChainId,
      _toAddress,
      _amount,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64, /*_nonce*/
    bytes memory _payload
  ) internal virtual override {
    // decode and load the toAddress
    (bytes memory toAddressBytes, uint256 amount) = abi.decode(
      _payload,
      (bytes, uint256)
    );
    address toAddress;
    assembly {
      toAddress := mload(add(toAddressBytes, 20))
    }

    _creditTo(_srcChainId, toAddress, amount);

    emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, amount);
  }

  function _send(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _amount,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) internal virtual {
    _debitFrom(_from, _dstChainId, _toAddress, _amount);

    bytes memory payload = abi.encode(_toAddress, _amount);
    if (useCustomAdapterParams) {
      _checkGasLimit(
        _dstChainId,
        FUNCTION_TYPE_SEND,
        _adapterParams,
        NO_EXTRA_GAS
      );
    } else {
      require(
        _adapterParams.length == 0,
        "LzApp: _adapterParams must be empty."
      );
    }
    _lzSend(
      _dstChainId,
      payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );

    emit SendToChain(_dstChainId, _from, _toAddress, _amount);
  }

  function setUseCustomAdapterParams(bool _useCustomAdapterParams)
    external
    onlyOwner
  {
    useCustomAdapterParams = _useCustomAdapterParams;
    emit SetUseCustomAdapterParams(_useCustomAdapterParams);
  }

  function _debitFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _amount
  ) internal virtual;

  function _creditTo(
    uint16 _srcChainId,
    address _toAddress,
    uint256 _amount
  ) internal virtual;
}


// File contracts/LayerZero/IOFT.sol





/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20 {

}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)



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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)





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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
}


// File contracts/LayerZero/OFT.sol







// override decimal() function is needed
contract OFT is OFTCore, ERC20, IOFT {
  constructor(
    string memory _name,
    string memory _symbol,
    address _lzEndpoint
  ) ERC20(_name, _symbol) OFTCore(_lzEndpoint) {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(OFTCore, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IOFT).interfaceId ||
      interfaceId == type(IERC20).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function circulatingSupply() public view virtual override returns (uint256) {
    return totalSupply();
  }

  function _debitFrom(
    address _from,
    uint16,
    bytes memory,
    uint256 _amount
  ) internal virtual override {
    address spender = _msgSender();
    if (_from != spender) _spendAllowance(_from, spender, _amount);
    _burn(_from, _amount);
  }

  function _creditTo(
    uint16,
    address _toAddress,
    uint256 _amount
  ) internal virtual override {
    _mint(_toAddress, _amount);
  }
}


// File contracts/LayerZero/BasedOFT.sol




contract BasedOFT is OFT {
  constructor(
    string memory _name,
    string memory _symbol,
    address _lzEndpoint
  ) OFT(_name, _symbol, _lzEndpoint) {}

  function circulatingSupply() public view virtual override returns (uint256) {
    unchecked {
      return totalSupply() - balanceOf(address(this));
    }
  }

  function _debitFrom(
    address _from,
    uint16,
    bytes memory,
    uint256 _amount
  ) internal virtual override {
    address spender = _msgSender();
    if (_from != spender) _spendAllowance(_from, spender, _amount);
    _transfer(_from, address(this), _amount);
  }

  function _creditTo(
    uint16,
    address _toAddress,
    uint256 _amount
  ) internal virtual override {
    _transfer(address(this), _toAddress, _amount);
  }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)




/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}


// File contracts/BaseToken.sol




contract TestToken is
  BasedOFT,
  ERC20Burnable
{

  uint256 public constant MAX_SUPPLY = 1_000_000;
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _layerZeroEndpoint
  ) BasedOFT(_tokenName, _tokenSymbol, _layerZeroEndpoint) {
  }

  function mint(address _recipient, uint256 _amount)
    public
  {
    _mint(_recipient, _amount);
  }
}