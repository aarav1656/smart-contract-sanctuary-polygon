// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetV2.sol";

/// @title A library for encoding Witnet Data Requests.
/// @author The Witnet Foundation.
library WitnetEncodingLib {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];

    bytes internal constant WITNET_RADON_OPCODES_RESULT_TYPES =
        hex"10ffffffffffffffffffffffffffffff0401ff010203050406071311ff01ffff07ff02ffffffffffffffffffffffffff0703ffffffffffffffffffffffffffff0405070202ff04040404ffffffffffff05070402040205050505ff04ff04ffffff010203050406070101ffffffffffff02ff050404000106060707ffffffffff";
            // 10ffffffffffffffffffffffffffffff
            // 0401ff000203050406070100ff01ffff
            // 07ff02ffffffffffffffffffffffffff
            // 0703ffffffffffffffffffffffffffff
            // 0405070202ff04040404ffffffffffff
            // 05070402040205050505ff04ff04ffff
            // ff010203050406070101ffffffffffff
            // 02ff050404000106060707ffffffffff

    /// ===============================================================================================================
    /// --- WitnetLib internal methods --------------------------------------------------------------------------------

    function size(WitnetV2.RadonDataTypes _type) internal pure returns (uint16) {
        if (_type == WitnetV2.RadonDataTypes.Integer
            || _type == WitnetV2.RadonDataTypes.Float
        ) {
            return 9;
        } else if (_type == WitnetV2.RadonDataTypes.Bool) {
            return 1;
        } else {
            // undetermined
            return 0; 
        }
    }


    /// ===============================================================================================================
    /// --- WitnetLib public methods (if used library will have to linked to calling contracts) -----------------------

    /// @notice Encode bytes array into given major type (UTF-8 not yet supported)
    /// @param buf Bytes array
    /// @return Marshaled bytes
    function encode(bytes memory buf, uint majorType)
        public pure
        returns (bytes memory)
    {
        uint len = buf.length;
        if (len < 23) {
            return abi.encodePacked(
                uint8((majorType << 5) | uint8(len)),
                buf
            );
        } else {
            uint8 buf0 = uint8((majorType << 5));
            bytes memory buf1;
            if (len <= 0xff) {
                buf0 |= 24;
                buf1 = abi.encodePacked(uint8(len));                
            } else if (len <= 0xffff) {
                buf0 |= 25;
                buf1 = abi.encodePacked(uint16(len));
            } else if (len <= 0xffffffff) {
                buf0 |= 26;
                buf1 = abi.encodePacked(uint32(len));
            } else {
                buf0 |= 27;
                buf1 = abi.encodePacked(uint64(len));
            }
            return abi.encodePacked(
                buf0,
                buf1,
                buf
            );
        }
    }

    /// @notice Encode bytes array.
    /// @param buf Bytes array
    /// @return Mashaled bytes
    function encode(bytes memory buf)
        public pure
        returns (bytes memory)
    {
        return encode(buf, WitnetCBOR.MAJOR_TYPE_BYTES);
    } 

    /// @notice Encode string array (UTF-8 not yet supported).
    /// @param str String bytes.
    /// @return Mashaled bytes
    function encode(string memory str)
        public pure
        returns (bytes memory)
    {
        return encode(bytes(str), WitnetCBOR.MAJOR_TYPE_STRING);
    }

    /// @dev Encode uint64 into tagged varint.
    /// @dev See https://developers.google.com/protocol-buffers/docs/encoding#varints.
    /// @param n Number
    /// @param t Tag
    /// @return buf Marshaled bytes
    function encode(uint64 n, bytes1 t)
        public pure
        returns (bytes memory buf)
    {
        unchecked {
            // Count the number of groups of 7 bits
            // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
            uint64 tmp = n;
            uint64 numBytes = 2;
            while (tmp > 0x7F) {
                tmp = tmp >> 7;
                numBytes += 1;
            }
            buf = new bytes(numBytes);
            tmp = n;
            buf[0] = t;
            for (uint64 i = 1; i < numBytes; i++) {
                // Set the first bit in the byte for each group of 7 bits
                buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
                tmp = tmp >> 7;
            }
            // Unset the first bit of the last byte
            buf[numBytes - 1] &= 0x7F;
        }
    }   

    function encode(WitnetV2.RadonRetrieval memory source)
        public pure
        returns (bytes memory)
    {
        bytes memory _encodedMethod = encode(uint64(source.method), bytes1(0x08));
        bytes memory _encodedUrl;
        if (bytes(source.url).length > 0) {
            _encodedUrl = abi.encodePacked(
                encode(uint64(bytes(source.url).length), bytes1(0x12)),
                bytes(source.url)
            );
        }
        bytes memory _encodedScript;
        if (source.script.length > 0) {
            _encodedScript = abi.encodePacked(
                encode(uint64(source.script.length), bytes1(0x1a)),
                source.script
            );
        }
        bytes memory _encodedBody;
        if (bytes(source.body).length > 0) {
            _encodedBody = abi.encodePacked(
                encode(uint64(bytes(source.body).length), bytes1(0x22)),
                bytes(source.body)
            );
        }
        bytes memory _encodedHeaders;
        if (source.headers.length > 0) {
            for (uint _ix = 0; _ix < source.headers.length; _ix ++) {
                bytes memory _headers = abi.encodePacked(
                    encode(uint64(bytes(source.headers[_ix][0]).length), bytes1(0x0a)),
                    bytes(source.headers[_ix][0]),
                    encode(uint64(bytes(source.headers[_ix][1]).length), bytes1(0x12)),
                    bytes(source.headers[_ix][1])
                );
                _encodedHeaders = abi.encodePacked(
                    _encodedHeaders,
                    encode(uint64(_headers.length), bytes1(0x2a)),
                    _headers
                );
            }
        }
        uint _innerSize = (
            _encodedMethod.length
                + _encodedUrl.length
                + _encodedScript.length
                + _encodedBody.length
                + _encodedHeaders.length
        );
        return abi.encodePacked(
            encode(uint64(_innerSize), bytes1(0x12)),
            _encodedMethod,
            _encodedUrl,
            _encodedScript,
            _encodedBody,
            _encodedHeaders
        );
    }

    function encode(
            WitnetV2.RadonRetrieval[] memory sources,
            string[][] memory args,
            bytes memory aggregatorInnerBytecode,
            bytes memory tallyInnerBytecode,
            uint16 resultMaxSize
        )
        public pure
        returns (bytes memory)
    {
        bytes[] memory encodedSources = new bytes[](sources.length);
        for (uint ix = 0; ix < sources.length; ix ++) {
            replaceWildcards(sources[ix], args[ix]);
            encodedSources[ix] = encode(sources[ix]);
        }
        return abi.encodePacked(
            (resultMaxSize > 0
                ? encode(uint64(resultMaxSize), 0x08)
                : bytes("")
            ),
            WitnetBuffer.concat(encodedSources),
            encode(uint64(aggregatorInnerBytecode.length), bytes1(0x1a)),
            aggregatorInnerBytecode,
            encode(uint64(tallyInnerBytecode.length), bytes1(0x22)),
            tallyInnerBytecode
        );
    }

    function encode(WitnetV2.RadonReducer memory reducer)
        public pure
        returns (bytes memory bytecode)
    {
        if (reducer.script.length == 0) {
            for (uint ix = 0; ix < reducer.filters.length; ix ++) {
                bytecode = abi.encodePacked(
                    bytecode,
                    encode(reducer.filters[ix])
                );
            }
            bytecode = abi.encodePacked(
                bytecode,
                encode(reducer.opcode)
            );
        } else {
            return abi.encodePacked(
                encode(uint64(reducer.script.length), bytes1(0x18)),
                reducer.script
            );
        }
    }

    function encode(WitnetV2.RadonFilter memory filter)
        public pure
        returns (bytes memory bytecode)
    {        
        bytecode = abi.encodePacked(
            encode(uint64(filter.opcode), bytes1(0x08)),
            filter.args.length > 0
                ? abi.encodePacked(
                    encode(uint64(filter.args.length), bytes1(0x12)),
                    filter.args
                ) : bytes("")
        );
        return abi.encodePacked(
            encode(uint64(bytecode.length), bytes1(0x0a)),
            bytecode
        );
    }

    function encode(WitnetV2.RadonReducerOpcodes opcode)
        public pure
        returns (bytes memory)
    {
        
        return encode(uint64(opcode), bytes1(0x10));
    }

    function encode(WitnetV2.RadonSLA memory sla)
        public pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            encode(uint64(sla.witnessReward), bytes1(0x10)),
            encode(uint64(sla.numWitnesses), bytes1(0x18)),
            encode(uint64(sla.minerCommitRevealFee), bytes1(0x20)),
            encode(uint64(sla.minConsensusPercentage), bytes1(0x28)),
            encode(uint64(sla.witnessCollateral), bytes1(0x30))
        );
    }

    function replaceCborStringsFromBytes(
            bytes memory data,
            string[] memory args
        )
        public pure
        returns (bytes memory)
    {
        WitnetCBOR.CBOR memory cbor = WitnetCBOR.fromBytes(data);
        while (!cbor.eof()) {
            if (cbor.majorType == WitnetCBOR.MAJOR_TYPE_STRING) {
                _replaceCborWildcards(cbor, args);
            }
            cbor = cbor.skip().settle();
        }
        return cbor.buffer.data;
    }

    function replaceWildcards(WitnetV2.RadonRetrieval memory self, string[] memory args)
        public pure
    {
        self.url = string (WitnetBuffer.replace(bytes(self.url), args));
        self.body = string(WitnetBuffer.replace(bytes(self.body), args));
        self.script = replaceCborStringsFromBytes(self.script, args);
    }

    function validate(
            WitnetV2.DataRequestMethods method,
            string memory schema,
            string memory authority,
            string memory path,
            string memory query,
            string memory body,
            string[2][] memory headers,
            bytes memory script
        )
        public pure
        returns (bytes32)
    {
        if (!(
            (method == WitnetV2.DataRequestMethods.HttpGet || method == WitnetV2.DataRequestMethods.HttpPost)
                && bytes(authority).length > 0
                && (
                    bytes(schema).length == 0
                        || keccak256(bytes(schema)) == keccak256(bytes("https://")) 
                        || keccak256(bytes(schema)) == keccak256(bytes("http://"))
                )
            || method == WitnetV2.DataRequestMethods.Rng
                && bytes(schema).length == 0
                && bytes(authority).length == 0
                && bytes(path).length == 0
                && bytes(query).length == 0
                && bytes(body).length == 0
                && headers.length == 0
                && script.length >= 1
        )) {
            revert WitnetV2.UnsupportedDataRequestMethod(
                uint8(method),
                schema,
                body,
                headers
            );
        }
        return keccak256(abi.encode(
            method,
            schema,
            authority,
            path,
            query,
            body,
            headers,
            script
        ));
    }
    
    function validate(
            WitnetV2.RadonDataTypes dataType,
            uint16 maxDataSize
        )
        public pure
        returns (uint16)
    {
        if (
            dataType == WitnetV2.RadonDataTypes.Any
                || dataType == WitnetV2.RadonDataTypes.String
                || dataType == WitnetV2.RadonDataTypes.Bytes
                || dataType == WitnetV2.RadonDataTypes.Array
        ) {
            if (/*maxDataSize == 0 ||*/maxDataSize > 2048) {
                revert WitnetV2.UnsupportedRadonDataType(
                    uint8(dataType),
                    maxDataSize
                );
            }
            return maxDataSize;
        } else if (
            dataType == WitnetV2.RadonDataTypes.Integer
                || dataType == WitnetV2.RadonDataTypes.Float
                || dataType == WitnetV2.RadonDataTypes.Bool
        ) {
            return 0; // TBD: size(dataType);
        } else {
            revert WitnetV2.UnsupportedRadonDataType(
                uint8(dataType),
                size(dataType)
            );
        }
    }

    function validate(WitnetV2.RadonFilter memory filter)
        public pure
    {
        if (
            filter.opcode == WitnetV2.RadonFilterOpcodes.StandardDeviation
        ) {
            // check filters that require arguments
            if (filter.args.length == 0) {
                revert WitnetV2.RadonFilterMissingArgs(uint8(filter.opcode));
            }
        } else if (
            filter.opcode == WitnetV2.RadonFilterOpcodes.Mode
        ) {
            // check filters that don't require any arguments
            if (filter.args.length > 0) {
                revert WitnetV2.UnsupportedRadonFilterArgs(uint8(filter.opcode), filter.args);
            }
        } else {
            // reject unsupported opcodes
            revert WitnetV2.UnsupportedRadonFilterOpcode(uint8(filter.opcode));
        }
    }

    function validate(WitnetV2.RadonReducer memory reducer)
        public pure
    {
        if (reducer.script.length == 0) {
            if (!(
                reducer.opcode == WitnetV2.RadonReducerOpcodes.AverageMean 
                    || reducer.opcode == WitnetV2.RadonReducerOpcodes.StandardDeviation
                    || reducer.opcode == WitnetV2.RadonReducerOpcodes.Mode
                    || reducer.opcode == WitnetV2.RadonReducerOpcodes.ConcatenateAndHash
                    || reducer.opcode == WitnetV2.RadonReducerOpcodes.AverageMedian
            )) {
                revert WitnetV2.UnsupportedRadonReducerOpcode(uint8(reducer.opcode));
            }
            for (uint ix = 0; ix < reducer.filters.length; ix ++) {
                validate(reducer.filters[ix]);
            }
        } else {
            if (uint8(reducer.opcode) != 0xff || reducer.filters.length > 0) {
                revert WitnetV2.UnsupportedRadonReducerScript(
                    uint8(reducer.opcode),
                    reducer.script,
                    0
                );
            }
        }
    }

    function validate(WitnetV2.RadonSLA memory sla)
        public pure
    {
        if (sla.witnessReward == 0) {
            revert WitnetV2.RadonSlaNoReward();
        }
        if (sla.numWitnesses == 0) {
            revert WitnetV2.RadonSlaNoWitnesses();
        } else if (sla.numWitnesses > 127) {
            revert WitnetV2.RadonSlaTooManyWitnesses(sla.numWitnesses);
        }
        if (
            sla.minConsensusPercentage < 51 
                || sla.minConsensusPercentage > 99
        ) {
            revert WitnetV2.RadonSlaConsensusOutOfRange(sla.minConsensusPercentage);
        }
        if (sla.witnessCollateral < 10 ** 9) {
            revert WitnetV2.RadonSlaLowCollateral(sla.witnessCollateral);
        }
    }

    function verifyRadonScriptResultDataType(bytes memory script)
        public pure
        returns (WitnetV2.RadonDataTypes)
    {
        return _verifyRadonScriptResultDataType(
            WitnetCBOR.fromBytes(script),
            false
        );
    }


    /// ===============================================================================================================
    /// --- WitnetLib private methods ---------------------------------------------------------------------------------

    function _replaceCborWildcards(
            WitnetCBOR.CBOR memory self,
            string[] memory args
        ) private pure
    {
        uint _rewind = self.len;
        uint _start = self.buffer.cursor;
        bytes memory _peeks = bytes(self.readString());
        uint _dataLength = _peeks.length + _rewind;
        bytes memory _pokes = WitnetBuffer.replace(_peeks, args);
        if (keccak256(_pokes) != keccak256(bytes(_peeks))) {
            self.buffer.cursor = _start - _rewind;
            self.buffer.mutate(
                _dataLength,
                encode(string(_pokes))
            );
        }
        self.buffer.cursor = _start;
    }

    
    function _verifyRadonScriptResultDataType(WitnetCBOR.CBOR memory self, bool flip)
        private pure
        returns (WitnetV2.RadonDataTypes)
    {
        if (self.majorType == WitnetCBOR.MAJOR_TYPE_ARRAY) {
            WitnetCBOR.CBOR[] memory items = self.readArray();
            if (items.length > 1) {
                return flip
                    ? _verifyRadonScriptResultDataType(items[0], false)
                    : _verifyRadonScriptResultDataType(items[items.length - 2], true)
                ;
            } else {
                return WitnetV2.RadonDataTypes.Any;
            }
        } else if (self.majorType == WitnetCBOR.MAJOR_TYPE_INT) {            
            uint cursor = self.buffer.cursor;
            uint opcode = self.readUint();
            uint8 dataType = (opcode > WITNET_RADON_OPCODES_RESULT_TYPES.length
                ? 0xff
                : uint8(WITNET_RADON_OPCODES_RESULT_TYPES[opcode])
            );
            if (dataType > uint8(type(WitnetV2.RadonDataTypes).max)) {
                revert WitnetV2.UnsupportedRadonScriptOpcode(
                    self.buffer.data,
                    cursor,
                    uint8(opcode)
                );
            }
            return WitnetV2.RadonDataTypes(dataType);
        } else {
            revert WitnetCBOR.UnexpectedMajorType(
                WitnetCBOR.MAJOR_TYPE_INT,
                self.majorType
            );
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Witnet.sol";

library WitnetV2 {

    error IndexOutOfBounds(uint256 index, uint256 range);
    error InsufficientBalance(uint256 weiBalance, uint256 weiExpected);
    error InsufficientFee(uint256 weiProvided, uint256 weiExpected);
    error Unauthorized(address violator);

    error RadonFilterMissingArgs(uint8 opcode);

    error RadonRequestNoSources();
    error RadonRequestSourcesArgsMismatch(uint expected, uint actual);
    error RadonRequestMissingArgs(uint index, uint expected, uint actual);
    error RadonRequestResultsMismatch(uint index, uint8 read, uint8 expected);
    error RadonRequestTooHeavy(bytes bytecode, uint weight);

    error RadonSlaNoReward();
    error RadonSlaNoWitnesses();
    error RadonSlaTooManyWitnesses(uint256 numWitnesses);
    error RadonSlaConsensusOutOfRange(uint256 percentage);
    error RadonSlaLowCollateral(uint256 witnessCollateral);

    error UnsupportedDataRequestMethod(uint8 method, string schema, string body, string[2][] headers);
    error UnsupportedRadonDataType(uint8 datatype, uint256 maxlength);
    error UnsupportedRadonFilterOpcode(uint8 opcode);
    error UnsupportedRadonFilterArgs(uint8 opcode, bytes args);
    error UnsupportedRadonReducerOpcode(uint8 opcode);
    error UnsupportedRadonReducerScript(uint8 opcode, bytes script, uint256 offset);
    error UnsupportedRadonScript(bytes script, uint256 offset);
    error UnsupportedRadonScriptOpcode(bytes script, uint256 cursor, uint8 opcode);
    error UnsupportedRadonTallyScript(bytes32 hash);

    function toEpoch(uint _timestamp) internal pure returns (uint) {
        return 1 + (_timestamp - 11111) / 15;
    }

    function toTimestamp(uint _epoch) internal pure returns (uint) {
        return 111111+ _epoch * 15;
    }

    struct Beacon {
        uint256 escrow;
        uint256 evmBlock;
        uint256 gasprice;
        address relayer;
        address slasher;
        uint256 superblockIndex;
        uint256 superblockRoot;        
    }

    enum BeaconStatus {
        Idle
    }

    struct Block {
        bytes32 blockHash;
        bytes32 drTxsRoot;
        bytes32 drTallyTxsRoot;
    }
    
    enum BlockStatus {
        Idle
    }

    struct DrPost {
        uint256 block;
        DrPostStatus status;
        DrPostRequest request;
        DrPostResponse response;
    }
    
    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct DrPostRequest {
        uint256 epoch;
        address requester;
        address reporter;
        bytes32 radHash;
        bytes32 slaHash;
        uint256 weiReward;
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct DrPostResponse {
        address disputer;
        address reporter;
        uint256 escrowed;
        uint256 drCommitTxEpoch;
        uint256 drTallyTxEpoch;
        bytes32 drTallyTxHash;
        bytes   drTallyResultCborBytes;
    }

    enum DrPostStatus {
        Void,
        Deleted,
        Expired,
        Posted,
        Disputed,
        Reported,
        Finalized,
        Accepted,
        Rejected
    }

    struct DataProvider {
        string  authority;
        uint256 totalEndpoints;
        mapping (uint256 => bytes32) endpoints;
    }

    enum DataRequestMethods {
        /* 0 */ Unknown,
        /* 1 */ HttpGet,
        /* 2 */ Rng,
        /* 3 */ HttpPost
    }

    enum RadonDataTypes {
        /* 0x00 */ Any, 
        /* 0x01 */ Array,
        /* 0x02 */ Bool,
        /* 0x03 */ Bytes,
        /* 0x04 */ Integer,
        /* 0x05 */ Float,
        /* 0x06 */ Map,
        /* 0x07 */ String,
        Unused0x08, Unused0x09, Unused0x0A, Unused0x0B,
        Unused0x0C, Unused0x0D, Unused0x0E, Unused0x0F,
        /* 0x10 */ Same,
        /* 0x11 */ Inner,
        /* 0x12 */ Match,
        /* 0x13 */ Subscript
    }

    struct RadonFilter {
        RadonFilterOpcodes opcode;
        bytes args;
    }

    enum RadonFilterOpcodes {
        /* 0x00 */ GreaterThan,
        /* 0x01 */ LessThan,
        /* 0x02 */ Equals,
        /* 0x03 */ AbsoluteDeviation,
        /* 0x04 */ RelativeDeviation,
        /* 0x05 */ StandardDeviation,
        /* 0x06 */ Top,
        /* 0x07 */ Bottom,
        /* 0x08 */ Mode,
        /* 0x09 */ LessOrEqualThan
    }

    struct RadonReducer {
        RadonReducerOpcodes opcode;
        RadonFilter[] filters;
        bytes script;
    }

    enum RadonReducerOpcodes {
        /* 0x00 */ Minimum,
        /* 0x01 */ Maximum,
        /* 0x02 */ Mode,
        /* 0x03 */ AverageMean,
        /* 0x04 */ AverageMeanWeighted,
        /* 0x05 */ AverageMedian,
        /* 0x06 */ AverageMedianWeighted,
        /* 0x07 */ StandardDeviation,
        /* 0x08 */ AverageDeviation,
        /* 0x09 */ MedianDeviation,
        /* 0x0A */ MaximumDeviation,
        /* 0x0B */ ConcatenateAndHash
    }

    struct RadonRetrieval {
        uint8 argsCount;
        DataRequestMethods method;
        RadonDataTypes resultDataType;
        string url;
        string body;
        string[2][] headers;
        bytes script;
    }

    struct RadonSLA {
        uint numWitnesses;
        uint minConsensusPercentage;
        uint witnessReward;
        uint witnessCollateral;
        uint minerCommitRevealFee;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetBuffer.sol";

/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.
/// 
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

library WitnetCBOR {

  using WitnetBuffer for WitnetBuffer.Buffer;
  using WitnetCBOR for WitnetCBOR.CBOR;

  /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
  struct CBOR {
      WitnetBuffer.Buffer buffer;
      uint8 initialByte;
      uint8 majorType;
      uint8 additionalInformation;
      uint64 len;
      uint64 tag;
  }

  uint8 internal constant MAJOR_TYPE_INT = 0;
  uint8 internal constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 internal constant MAJOR_TYPE_BYTES = 2;
  uint8 internal constant MAJOR_TYPE_STRING = 3;
  uint8 internal constant MAJOR_TYPE_ARRAY = 4;
  uint8 internal constant MAJOR_TYPE_MAP = 5;
  uint8 internal constant MAJOR_TYPE_TAG = 6;
  uint8 internal constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint64 internal constant UINT64_MAX = type(uint64).max;
  
  error EmptyArray();
  error InvalidLengthEncoding(uint length);
  error UnexpectedMajorType(uint read, uint expected);
  error UnsupportedPrimitive(uint primitive);
  error UnsupportedMajorType(uint unexpected);  

  modifier isMajorType(
      WitnetCBOR.CBOR memory cbor,
      uint8 expected
  ) {
    if (cbor.majorType != expected) {
      revert UnexpectedMajorType(cbor.majorType, expected);
    }
    _;
  }

  modifier notEmpty(WitnetBuffer.Buffer memory buffer) {
    if (buffer.data.length == 0) {
      revert WitnetBuffer.EmptyBuffer();
    }
    _;
  }

  function eof(CBOR memory cbor)
    internal pure
    returns (bool)
  {
    return cbor.buffer.cursor >= cbor.buffer.data.length;
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is the main factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param bytecode Raw bytes representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBytes(bytes memory bytecode)
    internal pure
    returns (CBOR memory)
  {
    WitnetBuffer.Buffer memory buffer = WitnetBuffer.Buffer(bytecode, 0);
    return fromBuffer(buffer);
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is an alternate factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBuffer(WitnetBuffer.Buffer memory buffer)
    internal pure
    notEmpty(buffer)
    returns (CBOR memory)
  {
    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;
    uint256 len;
    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = buffer.readUint8();
      len ++;
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;
      // Early CBOR tag parsing.
      if (majorType == MAJOR_TYPE_TAG) {
        uint _cursor = buffer.cursor;
        tag = readLength(buffer, additionalInformation);
        len += buffer.cursor - _cursor;
      } else {
        isTagged = false;
      }
    }
    if (majorType > MAJOR_TYPE_CONTENT_FREE) {
      revert UnsupportedMajorType(majorType);
    }
    return CBOR(
      buffer,
      initialByte,
      majorType,
      additionalInformation,
      uint64(len),
      tag
    );
  }

  function fork(WitnetCBOR.CBOR memory self)
    internal pure
    returns (WitnetCBOR.CBOR memory)
  {
    return CBOR({
      buffer: self.buffer.fork(),
      initialByte: self.initialByte,
      majorType: self.majorType,
      additionalInformation: self.additionalInformation,
      len: self.len,
      tag: self.tag
    });
  }

  function settle(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (!self.eof()) {
      return fromBuffer(self.buffer);
    } else {
      return self;
    }
  }

  function skip(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (
      self.majorType == MAJOR_TYPE_INT
        || self.majorType == MAJOR_TYPE_NEGATIVE_INT
    ) {
      self.buffer.cursor += self.peekLength();
    } else if (
        self.majorType == MAJOR_TYPE_STRING
          || self.majorType == MAJOR_TYPE_BYTES
    ) {
      uint64 len = readLength(self.buffer, self.additionalInformation);
      self.buffer.cursor += len;
    } else if (
      self.majorType == MAJOR_TYPE_ARRAY
        || self.majorType == MAJOR_TYPE_MAP
    ) { 
      self.len = readLength(self.buffer, self.additionalInformation);      
    } else if (
       self.majorType != MAJOR_TYPE_CONTENT_FREE
        || (
          self.additionalInformation != 20
            && self.additionalInformation != 21
        )
    ) {
      revert("WitnetCBOR.skip: unsupported major type");
    }
    return self;
  }

  function peekLength(CBOR memory self)
    internal pure
    returns (uint64)
  {
    if (self.additionalInformation < 24) {
      return 0;
    } else if (self.additionalInformation < 28) {
      return uint64(1 << (self.additionalInformation - 24));
    } else {
      revert InvalidLengthEncoding(self.additionalInformation);
    }
  }

  function readArray(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_ARRAY)
    returns (CBOR[] memory items)
  {
    // read array's length and move self cursor forward to the first array element:
    uint64 len = readLength(self.buffer, self.additionalInformation);
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (self.majorType == MAJOR_TYPE_ARRAY) {
        CBOR[] memory _subitems = self.readArray();
        // move forward to the first element after inner array:
        self = _subitems[_subitems.length - 1];
      } else if (self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = self.readMap();
        // move forward to the first element after inner map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  function readMap(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_MAP)
    returns (CBOR[] memory items)
  {
    // read number of items within the map and move self cursor forward to the first inner element:
    uint64 len = readLength(self.buffer, self.additionalInformation) * 2;
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (ix % 2 == 0 && self.majorType != MAJOR_TYPE_STRING) {
        revert("heyhey");
      } else if (self.majorType == MAJOR_TYPE_ARRAY || self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = (self.majorType == MAJOR_TYPE_ARRAY
            ? self.readArray()
            : self.readMap()
        );
        // move forward to the first element after inner array or map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  /// Reads the length of the settle CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 additionalInformation
    ) 
    internal pure
    returns (uint64)
  {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert InvalidLengthEncoding(additionalInformation);
  }

  /// @notice Read a `CBOR` structure into a native `bool` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function readBool(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (bool)
  {
    if (cbor.additionalInformation == 20) {
      return false;
    } else if (cbor.additionalInformation == 21) {
      return true;
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `bytes` value.
  /// @param cbor An instance of `CBOR`.
  /// @return output The value represented by the input, as a `bytes` value.   
  function readBytes(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_BYTES)
    returns (bytes memory output)
  {
    cbor.len = readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
    if (cbor.len == UINT32_MAX) {
      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 length = uint32(_readIndefiniteStringLength(
        cbor.buffer,
        cbor.majorType
      ));
      if (length < UINT32_MAX) {
        output = abi.encodePacked(cbor.buffer.read(length));
        length = uint32(_readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        ));
        if (length < UINT32_MAX) {
          output = abi.encodePacked(
            output,
            cbor.buffer.read(length)
          );
        }
      }
    } else {
      return cbor.buffer.read(uint32(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readFloat16(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int32)
  {
    if (cbor.additionalInformation == 25) {
      return cbor.buffer.readFloat16();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128[]` value whose inner values follow the same convention 
  /// @notice as explained in `decodeFixed16`.
  /// @param cbor An instance of `CBOR`.
  function readFloat16Array(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int32[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new int32[](length);
      for (uint64 i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[i] = readFloat16(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readInt(CBOR memory cbor)
    internal pure
    returns (int)
  {
    if (cbor.majorType == 1) {
      uint64 _value = readLength(
        cbor.buffer,
        cbor.additionalInformation
      );
      return int(-1) - int(uint(_value));
    } else if (cbor.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int(readUint(cbor));
    }
    else {
      revert UnexpectedMajorType(cbor.majorType, 1);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int[]` value.
  /// @param cbor instance of `CBOR`.
  /// @return array The value represented by the input, as an `int[]` value.
  function readIntArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int[] memory array)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      array = new int[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        array[i] = readInt(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string` value.
  /// @param cbor An instance of `CBOR`.
  /// @return text The value represented by the input, as a `string` value.
  function readString(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_STRING)
    returns (string memory text)
  {
    cbor.len = readLength(cbor.buffer, cbor.additionalInformation);
    if (cbor.len == UINT64_MAX) {
      bool _done;
      while (!_done) {
        uint64 length = _readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        );
        if (length < UINT64_MAX) {
          text = string(abi.encodePacked(
            text,
            cbor.buffer.readText(length / 4)
          ));
        } else {
          _done = true;
        }
      }
    } else {
      return string(cbor.buffer.readText(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return strings The value represented by the input, as an `string[]` value.
  function readStringArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (string[] memory strings)
  {
    uint length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      strings = new string[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        strings[i] = readString(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `uint64` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function readUint(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_INT)
    returns (uint)
  {
    return readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
  }

  /// @notice Decode a `CBOR` structure into a native `uint64[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return values The value represented by the input, as an `uint64[]` value.
  function readUintArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (uint[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new uint[](length);
      for (uint ix = 0; ix < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[ix] = readUint(item);
        unchecked {
          ix ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }  

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function _readIndefiniteStringLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 majorType
    )
    private pure
    returns (uint64 len)
  {
    uint8 initialByte = buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    len = readLength(
      buffer,
      initialByte & 0x1f
    );
    if (len >= UINT64_MAX) {
      revert InvalidLengthEncoding(len);
    } else if (majorType != (initialByte >> 5)) {
      revert UnexpectedMajorType((initialByte >> 5), majorType);
    }
  }
 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  error EmptyBuffer();
  error IndexOutOfBounds(uint index, uint range);
  error MissingArgs(uint expected, uint given);

  /// Iterable bytes buffer.
  struct Buffer {
      bytes data;
      uint cursor;
  }

  // Ensures we access an existing index in an array
  modifier withinRange(uint index, uint _range) {
    if (index >= _range) {
      revert IndexOutOfBounds(index, _range);
    }
    _;
  }

  /// @notice Concatenate undefinite number of bytes chunks.
  /// @dev Faster than looping on `abi.encodePacked(output, _buffs[ix])`.
  function concat(bytes[] memory _buffs)
    internal pure
    returns (bytes memory output)
  {
    unchecked {
      uint destinationPointer;
      uint destinationLength;
      assembly {
        // get safe scratch location
        output := mload(0x40)
        // set starting destination pointer
        destinationPointer := add(output, 32)
      }      
      for (uint ix = 1; ix <= _buffs.length; ix ++) {  
        uint source;
        uint sourceLength;
        uint sourcePointer;        
        assembly {
          // load source length pointer
          source := mload(add(_buffs, mul(ix, 32)))
          // load source length
          sourceLength := mload(source)
          // sets source memory pointer
          sourcePointer := add(source, 32)
        }
        memcpy(
          destinationPointer,
          sourcePointer,
          sourceLength
        );
        assembly {          
          // increase total destination length
          destinationLength := add(destinationLength, sourceLength)
          // sets destination memory pointer
          destinationPointer := add(destinationPointer, sourceLength)
        }
      }
      assembly {
        // protect output bytes
        mstore(output, destinationLength)
        // set final output length
        mstore(0x40, add(mload(0x40), add(destinationLength, 32)))
      }
    }
  }

  function fork(WitnetBuffer.Buffer memory buffer)
    internal pure
    returns (WitnetBuffer.Buffer memory)
  {
    return Buffer(
      buffer.data,
      buffer.cursor
    );
  }

  function mutate(
      WitnetBuffer.Buffer memory buffer,
      uint length,
      bytes memory pokes
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor)
  {
    bytes[] memory parts = new bytes[](3);
    parts[0] = peek(
      buffer,
      0,
      buffer.cursor
    );
    parts[1] = pokes;
    parts[2] = peek(
      buffer,
      buffer.cursor + length,
      buffer.data.length - buffer.cursor - length
    );
    buffer.data = concat(parts);
  }

  /// @notice Read and consume the next byte from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length + 1)
    returns (bytes1)
  {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return buffer.data[buffer.cursor ++];
  }

  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint offset,
      uint length
    )
    internal pure
    withinRange(offset + length, buffer.data.length + 1)
    returns (bytes memory)
  {
    bytes memory data = buffer.data;
    bytes memory peeks = new bytes(length);
    uint destinationPointer;
    uint sourcePointer;
    assembly {
      destinationPointer := add(peeks, 32)
      sourcePointer := add(add(data, 32), offset)
    }
    memcpy(
      destinationPointer,
      sourcePointer,
      length
    );
    return peeks;
  }

  // @notice Extract bytes array from buffer starting from current cursor.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to peek from the Buffer.
  // solium-disable-next-line security/no-assign-params
  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint length
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor + 1)
    returns (bytes memory)
  {
    return peek(
      buffer,
      buffer.cursor,
      length
    );
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to read and consume from the buffer.
  /// @return output A `bytes memory` containing the first `length` bytes from the buffer, counting from the cursor position.
  function read(Buffer memory buffer, uint length)
    internal pure
    withinRange(buffer.cursor + length, buffer.data.length + 1)
    returns (bytes memory output)
  {
    // Create a new `bytes memory destination` value
    output = new bytes(length);
    // Early return in case that bytes length is 0
    if (length > 0) {
      bytes memory input = buffer.data;
      uint offset = buffer.cursor;
      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(input, 32), offset)
        destinationPointer := add(output, 32)
      }
      // Copy `length` bytes from source to destination
      memcpy(
        destinationPointer,
        sourcePointer,
        length
      );
      // Move the cursor forward by `length` bytes
      seek(
        buffer,
        length,
        true
      );
    }
  }
  
  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Buffer memory buffer)
    internal pure
    returns (int32 result)
  {
    uint32 value = readUint16(buffer);
    // Get bit at position 0
    uint32 sign = value & 0x8000;
    // Get bits 1 to 5, then normalize to the [-14, 15] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(value & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 significand = int32(value & 0x03ff);
    // Add 1024 to the fraction if the exponent is 0
    if (exponent == 15) {
      significand |= 0x400;
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = (
        int32((int256(1 << uint256(int256(exponent)))
          * 10000
          * int256(uint256(int256(significand)) | 0x400)) >> 10)
      );
    } else {
      result = (int32(
        ((int256(uint256(int256(significand)) | 0x400) * 10000)
          / int256(1 << uint256(int256(- exponent))))
          >> 10
      ));
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(
      WitnetBuffer.Buffer memory buffer,
      uint64 length
    )
    internal pure
    returns (bytes memory text)
  {
    text = new bytes(length);
    unchecked {
      for (uint64 index = 0; index < length; index ++) {
        uint8 char = readUint8(buffer);
        if (char & 0x80 != 0) {
          if (char < 0xe0) {
            char = (char & 0x1f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 1;
          } else if (char < 0xf0) {
            char  = (char & 0x0f) << 12
              | (readUint8(buffer) & 0x3f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 2;
          } else {
            char = (char & 0x0f) << 18
              | (readUint8(buffer) & 0x3f) << 12
              | (readUint8(buffer) & 0x3f) << 6  
              | (readUint8(buffer) & 0x3f);
            length -= 3;
          }
        }
        text[index] = bytes1(char);
      }
      // Adjust text to actual length:
      assembly {
        mstore(text, length)
      }
    }
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (uint8 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 1), offset))
    }
    buffer.cursor ++;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 1, buffer.data.length)
    returns (uint16 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 2), offset))
    }
    buffer.cursor += 2;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 3, buffer.data.length)
    returns (uint32 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 4), offset))
    }
    buffer.cursor += 4;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 7, buffer.data.length)
    returns (uint64 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 8), offset))
    }
    buffer.cursor += 8;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 15, buffer.data.length)
    returns (uint128 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 16), offset))
    }
    buffer.cursor += 16;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  function readUint256(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 31, buffer.data.length)
    returns (uint256 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 32), offset))
    }
    buffer.cursor += 32;
  }

  /// @notice Count number of required parameters for given bytes arrays
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param count Highest wildcard index found, plus 1.
  function argsCountOf(bytes memory input)
    internal pure
    returns (uint8 count)
  {
    if (input.length < 3) {
      return 0;
    }
    unchecked {
      uint ix = 0; 
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          uint8 ax = uint8(uint8(input[ix + 1]) - uint8(bytes1("0")) + 1);
          if (ax > count) {
            count = ax;
          }
          ix += 3;
        } else {
          ix ++;
        }
      }
    }
  }

  /// @notice Replace bytecode indexed wildcards by correspondent string.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param args String values for replacing existing indexed wildcards in input.
  function replace(bytes memory input, string[] memory args)
    internal pure
    returns (bytes memory output)
  {
    uint ix = 0; uint lix = 0;
    uint inputLength;
    uint inputPointer;
    uint outputLength;
    uint outputPointer;    
    uint source;
    uint sourceLength;
    uint sourcePointer;

    if (input.length < 3) {
      return input;
    }
    
    assembly {
      // set starting input pointer
      inputPointer := add(input, 32)
      // get safe output location
      output := mload(0x40)
      // set starting output pointer
      outputPointer := add(output, 32)
    }         

    unchecked {
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          inputLength = (ix - lix);
          if (ix > lix) {
            memcpy(
              outputPointer,
              inputPointer,
              inputLength
            );
            inputPointer += inputLength + 3;
            outputPointer += inputLength;
          } else {
            inputPointer += 3;
          }
          uint ax = uint(uint8(input[ix + 1]) - uint8(bytes1("0")));
          if (ax >= args.length) {
            revert MissingArgs(ax + 1, args.length);
          }
          assembly {
            source := mload(add(args, mul(32, add(ax, 1))))
            sourceLength := mload(source)
            sourcePointer := add(source, 32)      
          }        
          memcpy(
            outputPointer,
            sourcePointer,
            sourceLength
          );
          outputLength += inputLength + sourceLength;
          outputPointer += sourceLength;
          ix += 3;
          lix = ix;
        } else {
          ix ++;
        }
      }
      ix = input.length;    
    }
    if (outputLength > 0) {
      if (ix > lix ) {
        memcpy(
          outputPointer,
          inputPointer,
          ix - lix
        );
        outputLength += (ix - lix);
      }
      assembly {
        // set final output length
        mstore(output, outputLength)
        // protect output bytes
        mstore(0x40, add(mload(0x40), add(outputLength, 32)))
      }
    }
    else {
      return input;
    }
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param buffer An instance of `Buffer`.
  /// @param offset How many bytes to move the cursor forward.
  /// @param relative Whether to count `offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `offset` if `relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(
      Buffer memory buffer,
      uint offset,
      bool relative
    )
    internal pure
    withinRange(offset, buffer.data.length + 1)
    returns (uint)
  {
    // Deal with relative offsets
    if (relative) {
      offset += buffer.cursor;
    }
    buffer.cursor = offset;
    return offset;
  }

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param buffer An instance of `Buffer`.
  /// @param relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(
      Buffer memory buffer,
      uint relativeOffset
    )
    internal pure
    returns (uint)
  {
    return seek(
      buffer,
      relativeOffset,
      true
    );
  }

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param dest Address of the destination memory.
  /// @param src Address to the source memory.
  /// @param len How many bytes to copy.
  // solium-disable-next-line security/no-assign-params
  function memcpy(
      uint dest,
      uint src,
      uint len
    )
    private pure
  {
    unchecked {
      // Copy word-length chunks while possible
      for (; len >= 32; len -= 32) {
        assembly {
          mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
      }
      if (len > 0) {
        // Copy remaining bytes
        uint _mask = 256 ** (32 - len) - 1;
        assembly {
          let srcpart := and(mload(src), not(_mask))
          let destpart := and(mload(dest), _mask)
          mstore(dest, or(destpart, srcpart))
        }
      }
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IWitnetRequest.sol";
import "./WitnetCBOR.sol";

library Witnet {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        address addr;       // Address of the IWitnetRequest contract containing Witnet data request raw bytecode.
        bytes32 slaHash;    // Radon SLA hash of the Witnet data request.
        bytes32 radHash;    // Radon radHash of the Witnet data request.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        WitnetCBOR.CBOR value;  // Resulting value, in CBOR-serialized bytes.
    }

    /// Final query's result status from a requester's point of view.
    enum ResultStatus {
        Void,
        Awaiting,
        Ready,
        Error
    }

    /// Data struct describing an error when trying to fetch a Witnet-provided result to a Data Request.
    struct ResultError {
        ResultErrorCodes code;
        string reason;
    }

    enum ResultErrorCodes {
        /// 0x00: Unknown error. Something went really bad!
        Unknown, 
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Script format errors =============================================================================================
            /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
            SourceScriptNotCBOR, 
            /// 0x02: The CBOR value decoded from a source script is not an Array.
            SourceScriptNotArray,
            /// 0x03: The Array value decoded form a source script is not a valid Data Request.
            SourceScriptNotRADON,
            /// Unallocated
            ScriptFormat0x04, ScriptFormat0x05, ScriptFormat0x06, ScriptFormat0x07, ScriptFormat0x08, ScriptFormat0x09,
            ScriptFormat0x0A, ScriptFormat0x0B, ScriptFormat0x0C, ScriptFormat0x0D, ScriptFormat0x0E, ScriptFormat0x0F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Complexity errors ================================================================================================
            /// 0x10: The request contains too many sources.
            RequestTooManySources,
            /// 0x11: The script contains too many calls.
            ScriptTooManyCalls,
            /// Unallocated
            Complexity0x12, Complexity0x13, Complexity0x14, Complexity0x15, Complexity0x16, Complexity0x17, Complexity0x18,
            Complexity0x19, Complexity0x1A, Complexity0x1B, Complexity0x1C, Complexity0x1D, Complexity0x1E, Complexity0x1F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Operator errors ===================================================================================================
            /// 0x20: The operator does not exist.
            UnsupportedOperator,
            /// Unallocated
            Operator0x21, Operator0x22, Operator0x23, Operator0x24, Operator0x25, Operator0x26, Operator0x27, Operator0x28,
            Operator0x29, Operator0x2A, Operator0x2B, Operator0x2C, Operator0x2D, Operator0x2E, Operator0x2F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Retrieval-specific errors =========================================================================================
            /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
            HTTP,
            /// 0x31: Retrieval of at least one of the sources timed out.
            RetrievalTimeout,
            /// Unallocated
            Retrieval0x32, Retrieval0x33, Retrieval0x34, Retrieval0x35, Retrieval0x36, Retrieval0x37, Retrieval0x38, 
            Retrieval0x39, Retrieval0x3A, Retrieval0x3B, Retrieval0x3C, Retrieval0x3D, Retrieval0x3E, Retrieval0x3F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Math errors =======================================================================================================
            /// 0x40: Math operator caused an underflow.
            Underflow,
            /// 0x41: Math operator caused an overflow.
            Overflow,
            /// 0x42: Tried to divide by zero.
            DivisionByZero,
            /// Unallocated
            Math0x43, Math0x44, Math0x45, Math0x46, Math0x47, Math0x48, Math0x49, 
            Math0x4A, Math0x4B, Math0x4C, Math0x4D, Math0x4E, Math0x4F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Other errors ======================================================================================================
            /// 0x50: Received zero reveals
            NoReveals,
            /// 0x51: Insufficient consensus in tally precondition clause
            InsufficientConsensus,
            /// 0x52: Received zero commits
            InsufficientCommits,
            /// 0x53: Generic error during tally execution
            TallyExecution,
            /// Unallocated
            OtherError0x54, OtherError0x55, OtherError0x56, OtherError0x57, OtherError0x58, OtherError0x59,
            OtherError0x5A, OtherError0x5B, OtherError0x5C, OtherError0x5D, OtherError0x5E, OtherError0x5F,
            /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
            MalformedReveal,
            /// Unallocated
            OtherError0x61, OtherError0x62, OtherError0x63, OtherError0x64, OtherError0x65, OtherError0x66,
            OtherError0x67, OtherError0x68, OtherError0x69, OtherError0x6A, OtherError0x6B, OtherError0x6C,
            OtherError0x6D, OtherError0x6E,OtherError0x6F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Access errors =====================================================================================================
            /// 0x70: Tried to access a value from an index using an index that is out of bounds
            ArrayIndexOutOfBounds,
            /// 0x71: Tried to access a value from a map using a key that does not exist
            MapKeyNotFound,
            /// Unallocated
            OtherError0x72, OtherError0x73, OtherError0x74, OtherError0x75, OtherError0x76, OtherError0x77, OtherError0x78, 
            OtherError0x79, OtherError0x7A, OtherError0x7B, OtherError0x7C, OtherError0x7D, OtherError0x7E, OtherError0x7F, 
            OtherError0x80, OtherError0x81, OtherError0x82, OtherError0x83, OtherError0x84, OtherError0x85, OtherError0x86, 
            OtherError0x87, OtherError0x88, OtherError0x89, OtherError0x8A, OtherError0x8B, OtherError0x8C, OtherError0x8D, 
            OtherError0x8E, OtherError0x8F, OtherError0x90, OtherError0x91, OtherError0x92, OtherError0x93, OtherError0x94, 
            OtherError0x95, OtherError0x96, OtherError0x97, OtherError0x98, OtherError0x99, OtherError0x9A, OtherError0x9B,
            OtherError0x9C, OtherError0x9D, OtherError0x9E, OtherError0x9F, OtherError0xA0, OtherError0xA1, OtherError0xA2, 
            OtherError0xA3, OtherError0xA4, OtherError0xA5, OtherError0xA6, OtherError0xA7, OtherError0xA8, OtherError0xA9, 
            OtherError0xAA, OtherError0xAB, OtherError0xAC, OtherError0xAD, OtherError0xAE, OtherError0xAF, OtherError0xB0,
            OtherError0xB1, OtherError0xB2, OtherError0xB3, OtherError0xB4, OtherError0xB5, OtherError0xB6, OtherError0xB7,
            OtherError0xB8, OtherError0xB9, OtherError0xBA, OtherError0xBB, OtherError0xBC, OtherError0xBD, OtherError0xBE,
            OtherError0xBF, OtherError0xC0, OtherError0xC1, OtherError0xC2, OtherError0xC3, OtherError0xC4, OtherError0xC5,
            OtherError0xC6, OtherError0xC7, OtherError0xC8, OtherError0xC9, OtherError0xCA, OtherError0xCB, OtherError0xCC,
            OtherError0xCD, OtherError0xCE, OtherError0xCF, OtherError0xD0, OtherError0xD1, OtherError0xD2, OtherError0xD3,
            OtherError0xD4, OtherError0xD5, OtherError0xD6, OtherError0xD7, OtherError0xD8, OtherError0xD9, OtherError0xDA,
            OtherError0xDB, OtherError0xDC, OtherError0xDD, OtherError0xDE, OtherError0xDF,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Bridge errors: errors that only belong in inter-client communication ==============================================
            /// 0xE0: Requests that cannot be parsed must always get this error as their result.
            /// However, this is not a valid result in a Tally transaction, because invalid requests
            /// are never included into blocks and therefore never get a Tally in response.
            BridgeMalformedRequest,
            /// 0xE1: Witnesses exceeds 100
            BridgePoorIncentives,
            /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
            /// amount of value that is unjustifiably high when compared with the reward they will be getting
            BridgeOversizedResult,
            /// Unallocated
            OtherError0xE3, OtherError0xE4, OtherError0xE5, OtherError0xE6, OtherError0xE7, OtherError0xE8, OtherError0xE9,
            OtherError0xEA, OtherError0xEB, OtherError0xEC, OtherError0xED, OtherError0xEE, OtherError0xEF, OtherError0xF0,
            OtherError0xF1, OtherError0xF2, OtherError0xF3, OtherError0xF4, OtherError0xF5, OtherError0xF6, OtherError0xF7,
            OtherError0xF8, OtherError0xF9, OtherError0xFA, OtherError0xFB, OtherError0xFC, OtherError0xFD, OtherError0xFE,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }


    /// ===============================================================================================================
    /// --- 'Witnet.Result' helper methods ----------------------------------------------------------------------------

    modifier _isError(Result memory result) {
        require(!result.success, "Witnet: no actual errors");
        _;
    }

    modifier _isReady(Result memory result) {
        require(result.success, "Witnet: tried to decode value from errored result.");
        _;
    }

    /// @dev Decode an address from the Witnet.Result's CBOR value.
    function asAddress(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (address)
    {
        if (result.value.majorType == uint8(WitnetCBOR.MAJOR_TYPE_BYTES)) {
            return toAddress(result.value.readBytes());
        } else {
            // TODO
            revert("WitnetLib: reading address from string not yet supported.");
        }
    }

    /// @dev Decode a `bool` value from the Witnet.Result's CBOR value.
    function asBool(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bool)
    {
        return result.value.readBool();
    }

    /// @dev Decode a `bytes` value from the Witnet.Result's CBOR value.
    function asBytes(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(bytes memory)
    {
        return result.value.readBytes();
    }

    /// @dev Decode a `bytes4` value from the Witnet.Result's CBOR value.
    function asBytes4(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes4)
    {
        return toBytes4(asBytes(result));
    }

    /// @dev Decode a `bytes32` value from the Witnet.Result's CBOR value.
    function asBytes32(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes32)
    {
        return toBytes32(asBytes(result));
    }

    /// @notice Returns the Witnet.Result's unread CBOR value.
    function asCborValue(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR memory)
    {
        return result.value;
    }

    /// @notice Decode array of CBOR values from the Witnet.Result's CBOR value. 
    function asCborArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR[] memory)
    {
        return result.value.readArray();
    }

    /// @dev Decode a fixed16 (half-precision) numeric value from the Witnet.Result's CBOR value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    function asFixed16(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32)
    {
        return result.value.readFloat16();
    }

    /// @dev Decode an array of fixed16 values from the Witnet.Result's CBOR value.
    function asFixed16Array(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32[] memory)
    {
        return result.value.readFloat16Array();
    }

    /// @dev Decode an `int64` value from the Witnet.Result's CBOR value.
    function asInt(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int)
    {
        return result.value.readInt();
    }

    /// @dev Decode an array of integer numeric values from a Witnet.Result as an `int[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int[]` decoded from the Witnet.Result.
    function asIntArray(Witnet.Result memory result)
        internal pure
        returns (int[] memory)
    {
        return result.value.readIntArray();
    }

    /// @dev Decode a `string` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asText(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(string memory)
    {
        return result.value.readString();
    }

    /// @dev Decode an array of strings from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asTextArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (string[] memory)
    {
        return result.value.readStringArray();
    }

    /// @dev Decode a `uint64` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (uint)
    {
        return result.value.readUint();
    }

    /// @dev Decode an array of `uint64` values from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUintArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (uint[] memory)
    {
        return result.value.readUintArray();
    }


    /// ===============================================================================================================
    /// --- 'bytes' helper methods ------------------------------------------------------------------------------------

    /// @dev Witnet function that computes the hash of a CBOR-encoded Data Request.
    function hash(bytes memory _bytecode) internal view returns (bytes32) {
        if (
            block.chainid != 1101           // Polygon zkEVM mainnet
                && block.chainid != 1442    // Polygon zkEVM testnet
        ) {
            return sha256(_bytecode);
        } else {
            return 0x0;
        }
    }

    /// @dev Transform given bytes into a Witnet.Result instance.
    /// @param bytecode Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory bytecode)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(bytecode);
        return _resultFromCborValue(cborValue);
    }

    function toAddress(bytes memory _value) internal pure returns (address) {
        return address(toBytes20(_value));
    }

    function toBytes4(bytes memory _value) internal pure returns (bytes4) {
        return bytes4(toFixedBytes(_value, 4));
    }
    
    function toBytes20(bytes memory _value) internal pure returns (bytes20) {
        return bytes20(toFixedBytes(_value, 20));
    }
    
    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }


    /// ===============================================================================================================
    /// --- 'string' helper methods -----------------------------------------------------------------------------------

    function toLowerCase(string memory str)
        internal pure
        returns (string memory)
    {
        bytes memory lowered = new bytes(bytes(str).length);
        unchecked {
            for (uint i = 0; i < lowered.length; i ++) {
                uint8 char = uint8(bytes(str)[i]);
                if (char >= 65 && char <= 90) {
                    lowered[i] = bytes1(char + 32);
                } else {
                    lowered[i] = bytes1(char);
                }
            }
        }
        return string(lowered);
    }

    function tryUint(string memory str)
        internal pure
        returns (uint res, bool)
    {
        unchecked {
            for (uint256 i = 0; i < bytes(str).length; i++) {
                if (
                    (uint8(bytes(str)[i]) - 48) < 0
                        || (uint8(bytes(str)[i]) - 48) > 9
                ) {
                    return (0, false);
                }
                res += (uint8(bytes(str)[i]) - 48) * 10 ** (bytes(str).length - i - 1);
            }
            return (res, true);
        }   
    }


    /// ===============================================================================================================
    /// --- 'uint8' helper methods ------------------------------------------------------------------------------------

    /// @dev Convert a `uint8` into a 2 characters long `string` representing its two less significant hexadecimal values.
    function toHexString(uint8 _u)
        internal pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }

    /// @dev Convert a `uint8` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    function toString(uint8 _u)
        internal pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }


    /// ===============================================================================================================
    /// --- Witnet library private methods ----------------------------------------------------------------------------

    /// @dev Decode a CBOR value into a Witnet.Result instance.
    function _resultFromCborValue(WitnetCBOR.CBOR memory cbor)
        private pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = cbor.tag != 39;
        return Witnet.Result(success, cbor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    
    /// @notice A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// @notice a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// @notice Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}