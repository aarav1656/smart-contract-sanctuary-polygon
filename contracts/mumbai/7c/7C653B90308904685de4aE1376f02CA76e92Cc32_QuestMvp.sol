// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// These statuses represent the main stages in the lifecycle of a Gig.
// Proposed: the Gig has been proposed but needs to be accepted.
// Accepted: the Gig has been agreed by both parties and needs feedback or resolution.
// Completed: the Gig has been resolved.
// Cancelled: the Gig has been cancelled before it was accepted.
enum GigStatus {
    Proposed,
    Accepted,
    Completed,
    Cancelled
}

// These statuses represent whether and how a Gig can be resolved.
// NeedsAgreementOrFeedback: the Gig cannot be resolved because it is not agreed yet or further feedback may be submitted.
// NoFeedback: the Gig can be resolved because it is not possible for further feedback to appear.
// InDispute: the Gig can be resolved only by the dispute team or an admin.
// Success: the Gig can be resolved normally by any party and compensation will be distributed accordingly.
// Fail: the Gig can be resolved by any party. Staked RAIN will be refunded to the startup.
enum GigResolution {
    NeedsAgreementOrFeedback,
    NoFeedback,
    InDispute,
    Success,
    Fail
}

library Search {
    function exist(address[] storage self, address _address)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++)
            if (self[i] == _address) return true;
        return false;
    }

    function indexOf(address[] storage self, address _address)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < self.length; i++)
            if (self[i] == _address) return i;
        return (2**256 - 1);
    }

    function remove(address[] storage self, uint256 index) internal {
        if (self.length - 1 == index) {
            self.pop();
        } else {
            for (uint256 i = index; i < self.length; i++) {
                self[i] = self[i + 1];
            }
            self.pop();
        }
    }
}

library View {
    function getTimes(GigData storage self)
        internal
        view
        returns (uint256, uint256)
    {
        return (self.responseDeadline, self.feedbackDeadline);
    }

    function getStatus(GigData storage self)
        internal
        view
        returns (GigStatus status)
    {
        return self.status;
    }
}

struct Feedback {
    uint256 feedbackCounter;
    bool suSubmitFirst;
    bytes32 rmFeedbackHash;
    bool rmGigOccurred;
    bool rmRequestDispute;
    bytes32 suFeedbackHash;
    bool suGigOccurred;
    bool suRequestDispute;
}

struct GigData {
    address rmLead;
    address suAddress;
    address gigProposer;
    address gigAccepter;
    bytes32 gigStatementHash;
    uint256 rmLeadStakeRequired;
    uint256 suStakeRequired;
    bool rmLeadStaked;
    bool suStaked;
    address[] participants;
    uint16[] gigCapTable;
    uint256 feedbackTimeInterval;
    uint256 responseDeadline;
    uint256 feedbackDeadline;
    Feedback feedbacks;
    GigStatus status;
}

interface RainInterface {
    function isAccountFrozen(address account) external view returns (bool);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function paused() external view returns (bool);
}

interface CoinInterface {
    function isAccountFrozen(address account) external view returns (bool);
}

interface HubInterface {
    function getCoinFromSu(address su) external view returns (address);
}

contract QuestMvp is Pausable, AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // This modifier tests that the referenced gig exists (already has been proposed).
    modifier validIndex(uint8 gigIndex) {
        require(gigIndex < nextGigIndex, "Gig index invalid");
        _;
    }

    // This modifier tests that the transaction sender is one of the startups associated with the Quest.
    modifier onlySu() {
        require(suMultisigs.exist(msg.sender), "Caller is not an SU");
        _;
    }

    // This modifier tests that the transaction sender is an ADMIN. This role is defined in the RAIN$ contract.
    modifier onlyAdmin() {
        require(
            RainInterface(rainTokenAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ),
            "Caller is not an ADMIN"
        );
        _;
    }

    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    bytes32 public constant ACCOUNT_EXEC_ROLE = keccak256("ACCOUNT_EXEC_ROLE");

    address public foundationAddress;
    address public rainTokenAddress;
    address public hubAddress;
    address public rmLead;
    address[] public suMultisigs;
    address[] public allRMS;
    uint8 public nextGigIndex;
    uint256 public proposalInterval;

    mapping(address => address[]) private suMultisigNomineeList;
    mapping(uint8 => GigData) gigList;

    string public oracleUrl;
    bytes32 public externalJobId;
    uint256 public oraclePayment;

    using Search for address[];
    using View for GigData;

    event GigProposed(
        uint256 gigIndex,
        bytes32 gigStatementHash,
        address rmLead,
        address suAddress,
        address gigProposer,
        uint256 rmLeadStakeRequired,
        uint256 suStakeRequired,
        uint256 responseDeadline,
        uint256 feedbackTimeInterval
    );

    event GigFulfilled(uint256 gigIndex);

    event GigAccepted(uint256 gigIndex, address sender, uint256 acceptedTime);
    event GigCanceled(uint256 gigIndex, address sender);
    event GigResolved(uint256 gigIndex, uint256 resolveResult);
    event GigDisputeExecuted(uint256 gigIndex, uint8 disputeChoice);

    event RmLeadUpdated(address new_rmLead);
    event SuNominated(address su, address nominator);
    event SuDenominated(address su, address nominator);
    event FeedbackSubmitted(
        uint256 gigIndex,
        bytes32 feedbackHash,
        address submitor,
        bool has_su_party_submitted,
        bool has_rm_party_submitted,
        bool has_gigOccurred,
        bool is_disputed
    );

    constructor(
        address _rmLead,
        address[] memory _suMultisigs,
        address[] memory _allRMS,
        address _rainTokenAddress,
        address _hubAddress,
        address _disputeMultisig,
        address _accountExec,
        address _foundationAddress,
        address[] memory _su_nominees,
        uint256 _proposalInterval
    ) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xedaa6962Cf1368a92e244DdC11aaC49c0A0acC37);
        externalJobId = "90ec64e83b32429b958deb238a23eeed";
        oraclePayment = (0.0 * LINK_DIVISIBILITY);
        
        // Below is a dummy testing URL. This will be changed in production.
        oracleUrl = "https://my-json-server.typicode.com/311923/myJsonServer/db";
        
        proposalInterval = _proposalInterval;

        rmLead = _rmLead;
        suMultisigs = _suMultisigs;
        allRMS = _allRMS;
        nextGigIndex = 0;
        rainTokenAddress = _rainTokenAddress;
        hubAddress = _hubAddress;
        foundationAddress = _foundationAddress;
        suMultisigNomineeList[suMultisigs[0]] = _su_nominees;

        _grantRole(DISPUTE_ROLE, _disputeMultisig);
        _grantRole(ACCOUNT_EXEC_ROLE, _accountExec);
    }

    /// @notice This function is for proposing new gigs. It can only be called by the rmLead, any startup, or any nominee of _suAddress.
    /// @param _suAddress The startup multisig address
    /// @param _gigStatementHash The hash of the Gig statement of purpose
    /// @param _rmLeadStakeRequired The amount of RAIN$ that rmLead must stake
    /// @param _suStakeRequired The amount of RAIN$ that the startup party must stake
    /// @param _participants The addresses of all RM participants in the Gig
    /// @param _gigCapTable The cap table of the Gig, which assigns a proportion of compensation to each RM in _participants
    /// @param _timeForFeedback The time interval for submitting feedback if the Gig is accepted
    function proposeNewGig(
        address _suAddress,
        bytes32 _gigStatementHash,
        uint256 _rmLeadStakeRequired,
        uint256 _suStakeRequired,
        address[] calldata _participants,
        uint16[] calldata _gigCapTable,
        uint256 _timeForFeedback
    ) external whenNotPaused {
        bool proposerIsSu = false;
        bool proposerIsSuNominee = false;
        bool proposerIsRm = false;
        address gigSuAddress = _suAddress;

        // Check that the proposer is the lead RM, any SU, or a nominee of the SU
        {
            if (msg.sender == rmLead) {
                proposerIsRm = true;
            }

            if (suMultisigs.exist(msg.sender)) {
                proposerIsSu = true;
            }

            if (suMultisigNomineeList[gigSuAddress].exist(msg.sender)) {
                proposerIsSuNominee = true;
            }

            require(
                proposerIsRm || proposerIsSu || proposerIsSuNominee,
                "You are not allowed to propose this Gig."
            );
        }

        {
            require(
                suMultisigs.exist(gigSuAddress),
                "The SU address is not valid."
            );

            require(
                _participants.length == _gigCapTable.length,
                "The cap table and list of participants have different lengths."
            );

            for (uint256 i = 0; i < _participants.length; i++) {
                require(
                    allRMS.exist(_participants[i]),
                    "A participant is not an RM."
                );
            }
        }

        GigData memory newGig;
        newGig.gigProposer = msg.sender;
        newGig.gigStatementHash = _gigStatementHash;
        newGig.responseDeadline = block.timestamp + proposalInterval;
        newGig.feedbacks = Feedback(
            0,
            false,
            bytes32(0),
            false,
            false,
            bytes32(0),
            false,
            false
        );

        {
            newGig.feedbackTimeInterval = _timeForFeedback;
            newGig.rmLeadStakeRequired = _rmLeadStakeRequired;
            newGig.suStakeRequired = _suStakeRequired;
            newGig.rmLead = rmLead;
            newGig.suAddress = gigSuAddress;
            newGig.participants = _participants;
            newGig.gigCapTable = _gigCapTable;
        }

        if (proposerIsSu || proposerIsSuNominee) {
            _contractSpendFrom(
                msg.sender,
                address(this),
                newGig.suStakeRequired
            );
            newGig.suStaked = true;
        } else {
            _contractSpendFrom(
                msg.sender,
                address(this),
                newGig.rmLeadStakeRequired
            );
            newGig.rmLeadStaked = true;
        }

        gigList[nextGigIndex] = newGig;

        emit GigProposed(
            nextGigIndex,
            newGig.gigStatementHash,
            newGig.rmLead,
            newGig.suAddress,
            msg.sender,
            newGig.rmLeadStakeRequired,
            newGig.suStakeRequired,
            newGig.responseDeadline,
            newGig.feedbackTimeInterval
        );
        nextGigIndex += 1;
    }

    /// @notice This function is used to repropose a gig, which involves updating certain characteristics of the proposal.
    /// @param _suAddress The startup multisig address
    /// @param _gigStatementHash The hash of the Gig statement of purpose
    /// @param _rmLeadStakeRequired The amount of RAIN$ that rmLead must stake
    /// @param _suStakeRequired The amount of RAIN$ that the startup party must stake
    /// @param _participants The addresses of all RM participants in the Gig
    /// @param _gigCapTable The cap table of the Gig, which assigns a proportion of compensation to each RM in _participants
    /// @param _timeForFeedback The time interval for submitting feedback if the Gig is accepted.
    /// @param _gigIndex The index of the Gig to be reproposed
    function reproposeGig(
        address _suAddress,
        bytes32 _gigStatementHash,
        uint256 _rmLeadStakeRequired,
        uint256 _suStakeRequired,
        address[] calldata _participants,
        uint16[] calldata _gigCapTable,
        uint256 _timeForFeedback,
        uint8 _gigIndex
    ) external whenNotPaused validIndex(_gigIndex) {
        GigData memory newGig;
        {
            newGig.suAddress = _suAddress;
            newGig.gigProposer = msg.sender;
            newGig.gigStatementHash = _gigStatementHash;
        }

        bool reproposerIsSu = false;
        bool reproposerIsSuNominee = false;
        bool reproposerIsGigRm = false;
        bool reproposerIsRm = false;

        {
            require(
                gigList[_gigIndex].status == GigStatus.Proposed,
                "The Gig's status must be Proposed"
            );
            require(
                suMultisigs.exist(newGig.suAddress),
                "SU address is not valid"
            );
        }

        if (msg.sender == rmLead) {
            reproposerIsRm = true;
        }

        if (msg.sender == gigList[_gigIndex].rmLead) {
            reproposerIsGigRm = true;
        }

        if (msg.sender == newGig.suAddress) {
            reproposerIsSu = true;
        }

        if (suMultisigNomineeList[newGig.suAddress].exist(msg.sender)) {
            reproposerIsSuNominee = true;
        }

        require(
            reproposerIsSu ||
                reproposerIsSuNominee ||
                reproposerIsGigRm ||
                reproposerIsRm,
            "You are not allowed to repropose this Gig."
        );

        {
            require(
                _participants.length == _gigCapTable.length,
                "The cap table and list of participants have different lengths."
            );

            for (uint256 i = 0; i < _participants.length; i++) {
                require(
                    allRMS.exist(_participants[i]),
                    "A participant is not an RM."
                );
            }
        }

        require(
            block.timestamp < gigList[_gigIndex].responseDeadline,
            "The acceptance deadline has been exceeded."
        );

        {
            newGig.rmLeadStakeRequired = _rmLeadStakeRequired;
            newGig.suStakeRequired = _suStakeRequired;
            newGig.rmLead = rmLead;
            newGig.participants = _participants;
            newGig.gigCapTable = _gigCapTable;
            newGig.responseDeadline = gigList[_gigIndex].responseDeadline;
            newGig.feedbacks = gigList[_gigIndex].feedbacks;
            newGig.feedbackTimeInterval = _timeForFeedback;
            newGig.status = gigList[_gigIndex].status;
        }

        if (
            gigList[_gigIndex].gigProposer == rmLead ||
            gigList[_gigIndex].gigProposer == gigList[_gigIndex].rmLead
        ) {
            // If the Gig was proposed by the current RM lead or the RM lead at proposal time
            _transferRainTo(
                gigList[_gigIndex].gigProposer,
                gigList[_gigIndex].rmLeadStakeRequired
            );
            newGig.rmLeadStaked = false;
            if (reproposerIsRm || reproposerIsGigRm) {
                _contractSpendFrom(
                    msg.sender,
                    address(this),
                    newGig.rmLeadStakeRequired
                );
                newGig.rmLeadStaked = true;
            } else {
                _contractSpendFrom(
                    msg.sender,
                    address(this),
                    newGig.suStakeRequired
                );
                newGig.suStaked = true;
            }
        } else {
            // if the Gig was proposed by a SU or SU nominee before
            _transferRainTo(
                gigList[_gigIndex].gigProposer,
                gigList[_gigIndex].suStakeRequired
            );
            newGig.suStaked = false;
            if (reproposerIsGigRm || reproposerIsRm) {
                _contractSpendFrom(
                    msg.sender,
                    address(this),
                    newGig.rmLeadStakeRequired
                );
                newGig.rmLeadStaked = true;
            } else {
                _contractSpendFrom(
                    msg.sender,
                    address(this),
                    newGig.suStakeRequired
                );
                newGig.suStaked = true;
            }
        }

        gigList[_gigIndex] = newGig;

        emit GigProposed(
            _gigIndex,
            newGig.gigStatementHash,
            newGig.rmLead,
            newGig.suAddress,
            msg.sender,
            newGig.rmLeadStakeRequired,
            newGig.suStakeRequired,
            newGig.responseDeadline,
            newGig.feedbackTimeInterval
        );
    }

    /// @notice This function is used to submit feedback to an accepted Gig.
    /// @param _gigIndex The Gig index
    /// @param _feedbackHash The hash of the feedback statement
    /// @param _gigOccurred Boolean value denoting whether the party agrees that the Gig succeeded
    /// @param _requestDispute Boolean value denoting whether the party wants the Gig to be resolved by the dispute team
    function submitFeedback(
        uint8 _gigIndex,
        bytes32 _feedbackHash,
        bool _gigOccurred,
        bool _requestDispute
    ) external whenNotPaused validIndex(_gigIndex) {
        require(
            gigList[_gigIndex].status == GigStatus.Accepted,
            "The Gig must be Accepted."
        );

        require(
            block.timestamp < gigList[_gigIndex].feedbackDeadline,
            "The deadline for feedback has been exceeded."
        );

        require(
            gigList[_gigIndex].feedbacks.feedbackCounter < 2,
            "All feedback has been submitted already."
        );

        bool isRmPartySubmit;
        bool isSuPartySubmit;

        if (msg.sender == rmLead || msg.sender == gigList[_gigIndex].rmLead) {
            isRmPartySubmit = true;
        }

        if (msg.sender == gigList[_gigIndex].suAddress) {
            isSuPartySubmit = true;
        }

        if (
            suMultisigNomineeList[gigList[_gigIndex].suAddress].exist(
                msg.sender
            )
        ) {
            isSuPartySubmit = true;
        }

        require(
            isRmPartySubmit || isSuPartySubmit,
            "You are not authorised to submit feedback."
        );

        if (gigList[_gigIndex].feedbacks.feedbackCounter == 0) {
            gigList[_gigIndex].feedbacks.suSubmitFirst = isSuPartySubmit;
        } else {
            require(
                gigList[_gigIndex].feedbacks.suSubmitFirst != isSuPartySubmit,
                "Feedback from the startup has already been submitted."
            );
        }

        if (isSuPartySubmit) {
            gigList[_gigIndex].feedbacks.suFeedbackHash = _feedbackHash;
            gigList[_gigIndex].feedbacks.suGigOccurred = _gigOccurred;
            gigList[_gigIndex].feedbacks.suRequestDispute = _requestDispute;
        } else {
            gigList[_gigIndex].feedbacks.rmFeedbackHash = _feedbackHash;
            gigList[_gigIndex].feedbacks.rmGigOccurred = _gigOccurred;
            gigList[_gigIndex].feedbacks.rmRequestDispute = _requestDispute;
        }

        gigList[_gigIndex].feedbacks.feedbackCounter += 1;

        emit FeedbackSubmitted(
            _gigIndex,
            _feedbackHash,
            msg.sender,
            isSuPartySubmit,
            isRmPartySubmit,
            _gigOccurred,
            _requestDispute
        );
    }

    /// @notice This function is a view function for obtaining the Gig resolution status.
    /// @param _gigIndex The Gig index
    function getResolutionOutcome(uint8 _gigIndex)
        public
        view
        validIndex(_gigIndex)
        returns (GigResolution result)
    {
        if (gigList[_gigIndex].status == GigStatus.Proposed) {
            return GigResolution.NeedsAgreementOrFeedback;
        }

        if (
            gigList[_gigIndex].feedbacks.feedbackCounter != 2 &&
            block.timestamp < gigList[_gigIndex].feedbackDeadline
        ) {
            return GigResolution.NeedsAgreementOrFeedback;
        }

        if (gigList[_gigIndex].feedbacks.feedbackCounter == 0) {
            return GigResolution.NoFeedback;
        }

        if (
            gigList[_gigIndex].feedbacks.suRequestDispute ||
            gigList[_gigIndex].feedbacks.rmRequestDispute
        ) {
            return GigResolution.InDispute;
        }

        if (gigList[_gigIndex].feedbacks.feedbackCounter == 1) {
            bool gig_happened = gigList[_gigIndex].feedbacks.suGigOccurred ||
                gigList[_gigIndex].feedbacks.rmGigOccurred;
            if (gig_happened) {
                return GigResolution.Success;
            } else {
                return GigResolution.Fail;
            }
        }

        if (gigList[_gigIndex].feedbacks.feedbackCounter == 2) {
            if (
                gigList[_gigIndex].feedbacks.suGigOccurred !=
                gigList[_gigIndex].feedbacks.rmGigOccurred
            ) {
                return GigResolution.InDispute;
            } else {
                if (gigList[_gigIndex].feedbacks.rmGigOccurred) {
                    return GigResolution.Success;
                } else {
                    return GigResolution.Fail;
                }
            }
        }

        return GigResolution.InDispute;
    }

    /// @notice This function allows anyone to resolve a Gig.
    /// @param _gigIndex The Gig index
    function resolveGig(uint8 _gigIndex)
        external
        whenNotPaused
        validIndex(_gigIndex)
    {
        require(
            gigList[_gigIndex].status == GigStatus.Accepted,
            "The Gig must be in the Accepted state."
        );

        GigResolution outcome = getResolutionOutcome(_gigIndex);

        if (outcome == GigResolution.NoFeedback) {
            _resolveGig(_gigIndex, 3);
        } else if (outcome == GigResolution.Fail) {
            _resolveGig(_gigIndex, 1);
        } else if (outcome == GigResolution.Success) {
            _resolveGig(_gigIndex, 0);
        } else {
            revert("The Gig cannot be resolved with this method.");
        }
    }

    /// @notice This function is used by the dispute resolution team to resolve a disputed Gig.
    /// @param _gigIndex The Gig index
    /// @param _disputeChoice The dispute resolution team's chosen Gig outcome
    // This function takes _disputeChoice as an argument. Interpretations of _disputeChoice codes:
    // 0 represents resolution as if the Gig status is Success
    // 1 represents resolution as if the Gig status is Fail
    // 2 represents an outcome in which all stakes are returned to the original staker
    // 3 represents resolution as if the Gig status is NoFeedback
    function resolveGigInDispute(uint8 _gigIndex, uint8 _disputeChoice)
        external
        whenNotPaused
        validIndex(_gigIndex)
    {
        require(
            gigList[_gigIndex].status == GigStatus.Accepted,
            "The Gig must be in the Accepted state."
        );

        require(
            hasRole(DISPUTE_ROLE, msg.sender),
            "This function must be called by the dispute resolution team."
        );

        GigResolution outcome = getResolutionOutcome(_gigIndex);

        require(
            outcome == GigResolution.InDispute,
            "The Gig must be disputed."
        );

        _resolveGig(_gigIndex, _disputeChoice);
    }

    /// @notice Internal function for resolving Gigs
    /// @param _gigIndex The Gig index
    /// @param _outcome The resolution outcome
    function _resolveGig(uint8 _gigIndex, uint8 _outcome)
        internal
        validIndex(_gigIndex)
    {
        address suStakingAddress;
        address rmStakingAddress;

        address proposer = gigList[_gigIndex].gigProposer;
        address accepter = gigList[_gigIndex].gigAccepter;

        if (proposer == rmLead || proposer == gigList[_gigIndex].rmLead) {
            rmStakingAddress = proposer;
            suStakingAddress = gigList[_gigIndex].gigAccepter;
        } else {
            suStakingAddress = proposer;
            rmStakingAddress = accepter;
        }

        if (_outcome == 0) {
            requestOracle(_gigIndex);
        } else if (_outcome == 1) {
            _transferRainTo(
                suStakingAddress,
                gigList[_gigIndex].suStakeRequired
            );
            _transferRainTo(
                foundationAddress,
                gigList[_gigIndex].rmLeadStakeRequired
            );
        } else if (_outcome == 2) {
            _transferRainTo(
                rmStakingAddress,
                gigList[_gigIndex].rmLeadStakeRequired
            );
            _transferRainTo(
                suStakingAddress,
                gigList[_gigIndex].suStakeRequired
            );
        } else {
            _transferRainTo(
                foundationAddress,
                gigList[_gigIndex].rmLeadStakeRequired +
                    gigList[_gigIndex].suStakeRequired
            );
        }

        if (_outcome != 0) {
            gigList[_gigIndex].status = GigStatus.Completed;
        }

        emit GigResolved(_gigIndex, _outcome);
    }

    /// @notice This function is used to cancel a Gig proposal.
    /// @param _gigIndex The Gig index
    function cancelGig(uint8 _gigIndex) external validIndex(_gigIndex) {
        require(
            (gigList[_gigIndex].status == GigStatus.Proposed) &&
                (block.timestamp >= gigList[_gigIndex].responseDeadline ||
                    gigList[_gigIndex].gigProposer == msg.sender ||
                    hasRole(ACCOUNT_EXEC_ROLE, msg.sender)),
            "You cannot cancel this Gig."
        );

        if (gigList[_gigIndex].rmLeadStaked) {
            _transferRainTo(
                gigList[_gigIndex].gigProposer,
                gigList[_gigIndex].rmLeadStakeRequired
            );
            gigList[_gigIndex].rmLeadStaked = false;
        } else {
            _transferRainTo(
                gigList[_gigIndex].gigProposer,
                gigList[_gigIndex].suStakeRequired
            );
            gigList[_gigIndex].suStaked = false;
        }

        gigList[_gigIndex].status = GigStatus.Cancelled;
    }

    /// @notice This function is used to accept a Gig proposal.
    /// @param _gigIndex The Gig index
    function acceptGig(uint8 _gigIndex)
        external
        whenNotPaused
        validIndex(_gigIndex)
    {
        GigData memory selectedGig = gigList[_gigIndex];

        require(
            selectedGig.status == GigStatus.Proposed,
            "The Gig must be in the proposed state."
        );

        require(
            block.timestamp < selectedGig.responseDeadline,
            "It is past the deadline to accept this Gig."
        );

        bool senderIsSuNominee = suMultisigNomineeList[selectedGig.suAddress]
            .exist(msg.sender);

        require(
            msg.sender == rmLead ||
                msg.sender == selectedGig.rmLead ||
                msg.sender == selectedGig.suAddress ||
                senderIsSuNominee,
            "You are not authorised to accept this Gig."
        );

        if (
            selectedGig.gigProposer == selectedGig.rmLead ||
            selectedGig.gigProposer == rmLead
        ) {
            require(
                msg.sender == selectedGig.suAddress || senderIsSuNominee,
                "You are not authorised to accept this Gig."
            );
            _contractSpendFrom(
                msg.sender,
                address(this),
                selectedGig.suStakeRequired
            );
            selectedGig.suStaked = true;
        } else {
            require(
                msg.sender == rmLead || msg.sender == selectedGig.rmLead,
                "You are not authorised to accept this Gig."
            );
            _contractSpendFrom(
                msg.sender,
                address(this),
                selectedGig.rmLeadStakeRequired
            );

            selectedGig.rmLeadStaked = true;
        }

        selectedGig.gigAccepter = msg.sender;
        selectedGig.status = GigStatus.Accepted;
        selectedGig.feedbackDeadline =
            block.timestamp +
            selectedGig.feedbackTimeInterval;
        gigList[_gigIndex] = selectedGig;

        emit GigAccepted(_gigIndex, msg.sender, block.timestamp);
    }

    /// @notice This function is used to update the proposal interval of Gig proposed within this Quest.
    /// @param _proposalInterval The interval of time, in seconds.
    function updateProposalInterval(uint256 _proposalInterval)
        external
        onlyAdmin
    {
        proposalInterval = _proposalInterval;
    }

    /// @notice This function is used to exxtend Gig acceptance and Gig feedback deadlines.
    /// @param _gigIndex  The Gig index
    /// @param _acceptExtendInterval The interval of time to extend the acceptance deadline, in seconds.
    /// @param _feedbackExtendInterval The interval of time to extend the feedback deadline, in seconds.
    function updateGigTime(
        uint8 _gigIndex,
        uint256 _acceptExtendInterval,
        uint256 _feedbackExtendInterval
    ) external validIndex(_gigIndex) {
        require(
            hasRole(ACCOUNT_EXEC_ROLE, msg.sender),
            "You must hold ACCOUNT_EXEC role."
        );
        gigList[_gigIndex].responseDeadline += _acceptExtendInterval;
        gigList[_gigIndex].feedbackDeadline += _feedbackExtendInterval;
    }

    /// @notice This function is used to update the hash value of the purpose statement of a Gig.
    /// @param _gigIndex  The Gig index
    /// @param _gigHash The new hash value capturing the new statement of purpose of the Gig
    function updateGigHash(uint8 _gigIndex, bytes32 _gigHash)
        external
        validIndex(_gigIndex)
    {
        require(
            hasRole(ACCOUNT_EXEC_ROLE, msg.sender),
            "You must hold ACCOUNT_EXEC role."
        );
        gigList[_gigIndex].gigStatementHash = _gigHash;
    }

    /// @notice This function is used to add new RM addresses to the Quest contract.
    /// @param _newAllRMS The new array of RM addresses
    function addNewRMs(address[] calldata _newAllRMS) external whenNotPaused {
        require(
            suMultisigs.exist(msg.sender) || msg.sender == rmLead,
            "You must be the lead RM or a startup associated with this Quest."
        );
        for (uint256 i = 0; i < _newAllRMS.length; i++) {
            if (!allRMS.exist(_newAllRMS[i])) {
                allRMS.push(_newAllRMS[i]);
            }
        }
    }

    /// @notice This function is used to update the Hub contract address.
    /// @param _newHubAddress  The new Hub contract address
    function updateHubAddress(address _newHubAddress) external onlyAdmin {
        hubAddress = _newHubAddress;
    }

    /// @notice This function is used to update the RAIN$ contract address.
    /// @param _newRainAddress  The new RAIN$ contract address
    function updateRainAddress(address _newRainAddress) external onlyAdmin {
        rainTokenAddress = _newRainAddress;
    }

    /// @notice This function is used to update the Foundation wallet address.
    /// @param _newFoundationAddress  The new Foundation wallet address
    function updateFoundationAddress(address _newFoundationAddress)
        external
        onlyAdmin
    {
        foundationAddress = _newFoundationAddress;
    }

    /// @notice This function is used to update the oracle settings.
    /// @param _oracleAddress  The oracle contract address
    /// @param _newUrl  The url used by the oracle to fetch the result
    /// @param _newExternalJobId  The oracle job id
    /// @param _newOraclePayment  The payment amount needed to call the oracle
    function updateOracleSetting(
        address _oracleAddress,
        string calldata _newUrl,
        bytes32 _newExternalJobId,
        uint256 _newOraclePayment
    ) external onlyAdmin {
        setChainlinkOracle(_oracleAddress);
        oracleUrl = _newUrl;
        externalJobId = _newExternalJobId;
        oraclePayment = _newOraclePayment;
    }

    /// @notice This function is used by an ADMIN to request a Gig resolution using the oracle mechanism.
    /// @param _gigIndex  The Gig index
    function requestOracleFromAdmin(uint8 _gigIndex) external onlyAdmin {
        require(
            gigList[_gigIndex].status == GigStatus.Accepted,
            "The Gig must be Accepted."
        );
        requestOracle(_gigIndex);
    }

    /// @notice Internal function to request the oracle
    /// @param _gigIndex  The Gig index
    function requestOracle(uint256 _gigIndex) internal {
        Chainlink.Request memory req = buildChainlinkRequest(
            externalJobId,
            address(this),
            this.fulfillOracle.selector
        );
        
        // Use the below code for production
        // original request format
        // req.add(
        //     "get",
        //     string.concat(
        //         oracleUrl,
        //         "/",
        //         Strings.toHexString(uint160(address(this)), 20),
        //         "/",
        //         Strings.toString(_gigIndex)
        //     )
        // );

        // use these lines for testing with the dummy URL
        req.add("get", oracleUrl);
        req.add("path", "data");
        // end of code for testing with dummy URL
        
        sendOperatorRequest(req, oraclePayment);
    }

    /// @notice This function is used by the oracle service to fulfill requests.
    /// @param requestId  The oracle request id
    /// @param _array  The result array fetched by oracle
    function fulfillOracle(bytes32 requestId, uint256[] calldata _array)
        public
        whenNotPaused
        recordChainlinkFulfillment(requestId)
    {
        fulfillLogic(_array);
    }

    /// @notice This function is used by an ADMIN to manually distribute RAIN$ and COIN$, without using the oracle.
    /// @param _array  The result array that defines the compensation distribution
    function fulfillManually(uint256[] calldata _array) external onlyAdmin {
        uint8 gigIndex = uint8(_array[0]);
        require(
            gigList[gigIndex].status == GigStatus.Accepted,
            "The Gig must be Accepted."
        );
        fulfillLogic(_array);
    }

    /// @notice This function is the logic that interprets an input array as transactions that distribute compensation for a Gig.
    /// @param _array  The result array that defines the compensation distribution
    function fulfillLogic(uint256[] calldata _array) internal {
        uint8 gigIndex = uint8(_array[0]);
        require(
            gigList[gigIndex].status != GigStatus.Completed,
            "The Gig must not already be completed."
        );

        address rmStakingAddress;
        address proposer = gigList[gigIndex].gigProposer;
        address accepter = gigList[gigIndex].gigAccepter;

        if (proposer == rmLead || proposer == gigList[gigIndex].rmLead) {
            rmStakingAddress = proposer;
        } else {
            rmStakingAddress = accepter;
        }

        _transferRainTo(
            rmStakingAddress,
            gigList[gigIndex].rmLeadStakeRequired
        );

        bool hasCrewCompensation = false;
        bool hasCoinCompensation = false;
        address suAddress;
        uint256 suNumber;

        for (uint256 i = 1; i < _array.length; i += 2) {
            address wallet = address(uint160(_array[i]));
            uint256 amount = _array[i + 1];

            if (
                RainInterface(rainTokenAddress).isAccountFrozen(wallet) ||
                RainInterface(rainTokenAddress).paused()
            ) {
                revert(
                    string.concat(
                        Strings.toString(gigIndex),
                        ": An address associated with this Gig is frozen."
                    )
                );
            }

            if (!hasCrewCompensation && !hasCoinCompensation) {
                if (wallet == address(0) && amount == 0) {
                    hasCrewCompensation = true;
                    continue;
                } else {
                    _transferRainTo(wallet, amount);
                }
            } else if (hasCrewCompensation && !hasCoinCompensation) {
                if (wallet == address(0) && amount == 1) {
                    hasCoinCompensation = true;
                    continue;
                } else {
                    _contractSpendFrom(foundationAddress, wallet, amount);
                }
            } else {
                HubInterface hub = HubInterface(hubAddress);
                if (suNumber == 0) {
                    suAddress = wallet;
                    suNumber = amount;
                } else {
                    IERC20 coin_token = IERC20(hub.getCoinFromSu(suAddress));
                    require(
                        coin_token.balanceOf(foundationAddress) >= amount,
                        "The Foundation address has insufficient funds."
                    );
                    coin_token.transferFrom(foundationAddress, wallet, amount);
                    suNumber -= 1;
                }
            }
        }
        gigList[gigIndex].suStaked = false;
        gigList[gigIndex].rmLeadStaked = false;
        gigList[gigIndex].status = GigStatus.Completed;
        emit GigFulfilled(gigIndex);
    }

    /// @notice This function is used to add a nominee for an SU.
    /// @param _nominee  The nominee address
    function suNominate(address _nominee) external onlySu whenNotPaused {
        if (!suMultisigNomineeList[msg.sender].exist(_nominee)) {
            suMultisigNomineeList[msg.sender].push(_nominee);
            emit SuNominated(msg.sender, _nominee);
        }
    }

    /// @notice This function is used to remove a nominee.
    /// @param _nomineeToRemove  The nominee address
    function suDeNominate(address _nomineeToRemove)
        external
        whenNotPaused
        onlySu
    {
        if (suMultisigNomineeList[msg.sender].exist(_nomineeToRemove)) {
            uint256 index = suMultisigNomineeList[msg.sender].indexOf(
                _nomineeToRemove
            );
            suMultisigNomineeList[msg.sender].remove(index);
            emit SuDenominated(msg.sender, _nomineeToRemove);
        }
    }

    /// @notice This function is used to transfer the rmLead to another address.
    /// @param _newRmLead  The new rmLead address
    function transferRmLead(address _newRmLead) external whenNotPaused {
        require(
            msg.sender == rmLead || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "You are not authorised to transfer the RM lead."
        );
        rmLead = _newRmLead;
        emit RmLeadUpdated(_newRmLead);
    }

    /// @notice This function is used to transfer RAIN$ from the Quest to another address.
    /// @param to  The receiving address
    /// @param value  The transfer amount
    function _transferRainTo(address to, uint256 value) internal {
        IERC20 rainToken = IERC20(rainTokenAddress);
        require(
            rainToken.balanceOf(address(this)) >= value,
            "The Quest contract has insufficient funds."
        );
        if (value > 0) {
            rainToken.transfer(to, value);
        }
    }

    /// @notice This function is used to transfer RAIN$ from sender to receiver using the allowance mechanism.
    /// @param from  The sending address
    /// @param to  The receiving address
    /// @param value  The transfer amount
    function _contractSpendFrom(
        address from,
        address to,
        uint256 value
    ) internal {
        IERC20 rainToken = IERC20(rainTokenAddress);
        require(
            rainToken.balanceOf(from) >= value,
            "The sender has insufficient balance."
        );
        if (value > 0) {
            rainToken.transferFrom(from, to, value);
        }
    }

    /// @notice This function is used to pause the Quest contract.
    function pause() external whenNotPaused {
        require(
            RainInterface(rainTokenAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ) ||
                RainInterface(rainTokenAddress).hasRole(
                    COMPLIANCE_ROLE,
                    msg.sender
                ),
            "You must hold either ADMIN or COMPLIANCE role."
        );
        _pause();
    }

    /// @notice This function is used to unpause the Quest contract.
    function unpause() external whenPaused {
        require(
            RainInterface(rainTokenAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ) ||
                RainInterface(rainTokenAddress).hasRole(
                    COMPLIANCE_ROLE,
                    msg.sender
                ),
            "You must hold either ADMIN or COMPLIANCE role."
        );
        _unpause();
    }

    /// @notice This function is used to grant access control roles defined in the Quest contract.
    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _grantRole(role, account);
    }

    /// @notice This function is used to revoke access control roles definedin the Quest contract.
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _revokeRole(role, account);
    }

    /// @notice This function is used to view the response and feedback deadlines of the Gig.
    /// @param gigIndex  The Gig index
    function getGigTime(uint8 gigIndex)
        external
        view
        validIndex(gigIndex)
        returns (uint256 responseDeadline, uint256 feedbackDeadline)
    {
        return (gigList[gigIndex].getTimes());
    }

    /// @notice This function is used to view the status of the Gig.
    /// @param gigIndex  The Gig index
    function getGigStatus(uint8 gigIndex)
        external
        view
        validIndex(gigIndex)
        returns (uint256 status)
    {
        return uint256(gigList[gigIndex].getStatus());
    }

    /// @notice This function is used to check whether the address is an RM.
    /// @param _address  The address to check
    function addressIsRm(address _address) external view returns (bool) {
        if (allRMS.exist(_address)) {
            return true;
        } else {
            return false;
        }
    }
}