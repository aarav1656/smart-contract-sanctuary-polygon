// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./muon/MuonClient.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

contract MuonClientExample is MuonClient {

    constructor(
        uint256 _muonAppId,
        PublicKey memory _muonPublicKey
    ) MuonClient(_muonAppId, _muonPublicKey){
    }

    function toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function testFunc(string memory manualData, bytes calldata data) external {
        (uint256[5] memory decodedData) = abi.decode(data, (uint256[5]));

        uint256 signature = decodedData[0];
        address owner = address(uint160(decodedData[1]));
        address nonce = address(uint160(decodedData[2]));
        bytes memory reqId = toBytes(decodedData[3]);
        
        SchnorrSign memory sign = SchnorrSign(signature, owner, nonce);

        verifyTSS(manualData, reqId, sign);
        
        // SUCCESS!
        // TRANSACTION SUCCESSFULLY PASSES IN THIS CASE
    }

    function verifyTSS(
        string memory data,
        bytes memory reqId,
        SchnorrSign memory sign
    ) public{
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonAppId,
                reqId,
                data
            )
        );

        bool verified = muonVerify(reqId, uint256(hash), sign, muonPublicKey);
        require(verified, "TSS not verified");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MuonClientBase.sol";

contract MuonClient is MuonClientBase {

    constructor(
        uint256 _muonAppId,
        PublicKey memory _muonPublicKey
    ){
        validatePubKey(_muonPublicKey.x);

        muonAppId = _muonAppId;
        muonPublicKey = _muonPublicKey;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SchnorrSECP256K1Verifier.sol";

contract MuonClientBase is SchnorrSECP256K1Verifier{

    struct SchnorrSign {
        uint256 signature;
        address owner;
        address nonce;
    }

    struct PublicKey {
        uint256 x;
        uint8 parity;
    }

    event MuonTX(bytes reqId, PublicKey pubKey);

    uint256 public muonAppId;
    PublicKey public muonPublicKey;

    function muonVerify(
        bytes memory reqId,
        uint256 hash, 
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) public returns (bool) {
        if(!verifySignature(pubKey.x, pubKey.parity, 
                signature.signature, 
                hash, signature.nonce)){
            return false;
        }
        emit MuonTX(reqId, pubKey);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract SchnorrSECP256K1Verifier {
  // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
  uint256 constant public Q = // Group order of secp256k1
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  uint256 constant public HALF_Q = (Q >> 1) + 1;

  /** **************************************************************************
      @notice verifySignature returns true iff passed a valid Schnorr signature.
      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.
      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD
      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256
      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.
      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)
      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.
      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.
      @dev 6. Let x be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE
      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:
      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.
      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q. 
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1 
             if it's odd.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param msgHash is a 256-bit hash of the message being signed.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */
  function verifySignature(
    uint256 signingPubKeyX,
    uint8 pubKeyYParity,
    uint256 signature,
    uint256 msgHash,
    address nonceTimesGeneratorAddress) internal pure returns (bool) {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
    require(signature < Q, "signature must be reduced modulo Q");

    // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
    // avoid is something which causes ecrecover to return 0x0: then trivial
    // signatures could be constructed with the nonceTimesGeneratorAddress input
    // set to 0x0.
    //
    require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
      signature > 0 && msgHash > 0, "no zero inputs allowed");

    uint256 msgChallenge = // "e"
      uint256(keccak256(abi.encodePacked(nonceTimesGeneratorAddress, msgHash)));

    // Verify msgChallenge * signingPubKey + signature * generator ==
    //        nonce * generator
    //
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // The point corresponding to the address returned by
    // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
    // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
    //
    address recoveredAddress = ecrecover(
      bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
      // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
      // value 27 represents an even y value and 28 represents an odd
      // y value."
      (pubKeyYParity == 0) ? 27 : 28,
      bytes32(signingPubKeyX),
      bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
    return nonceTimesGeneratorAddress == recoveredAddress;
  }

  function validatePubKey (uint256 signingPubKeyX) internal pure {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
  }
}