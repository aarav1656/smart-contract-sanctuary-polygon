// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/MultiWhitelist.sol";
import "./ApeironPlanetGenerator.sol";
import "./interfaces/IApeironPlanet.sol";

contract ApeironPlanetPresaleFactory is MultiWhitelist, ApeironPlanetGenerator {
    using ECDSA for bytes32;
    address private immutable systemAddress;

    using Address for address;

    event Reserved(uint256 _tokenId, address _reserver);
    event Sold(uint256 _tokenId, address _buyer, uint256 _price);
    event PresaleEnable(bool _isEnabled);
    event TypeCounterUpdated(uint256[] _typeCounter);

    modifier onlyDuringSale() {
        require(isEnabled, "Sale is not enabled");
        _;
    }

    IERC20 public immutable token;
    IApeironPlanet public immutable planetContract;
    bool public isEnabled;

    mapping(CoreType => uint256) public prices;
    mapping(CoreType => uint256) public typeCounter;
    mapping(CoreType => uint256) public typeMax;

    constructor(
        address _nftAddress,
        address _tokenAddress,
        address _systemAddress,
        uint256[] memory _prices,
        uint256[] memory _mintCountPerType
    ) ApeironPlanetGenerator() {
        require(_nftAddress.isContract(), "_nftAddress must be a contract");
        require(_tokenAddress.isContract(), "_tokenAddress must be a contract");
        require(_systemAddress != address(0), "invalid _systemAddress");
        require(_prices.length == 5, "Invalid prices count");
        require(_mintCountPerType.length == 5, "Invalid mint count");

        // NFT + FT Address
        planetContract = IApeironPlanet(_nftAddress);
        token = IERC20(_tokenAddress);
        systemAddress = _systemAddress;

        // PRICES
        prices[CoreType.Elemental] = _prices[0];
        prices[CoreType.Mythic] = _prices[1];
        prices[CoreType.Arcane] = _prices[2];
        prices[CoreType.Divine] = _prices[3];
        prices[CoreType.Primal] = _prices[4];

        // TYPE COUNTER + MAX
        typeCounter[CoreType.Primal] = 0;
        typeMax[CoreType.Primal] =
            typeCounter[CoreType.Primal] +
            _mintCountPerType[4] -
            1;

        typeCounter[CoreType.Divine] = typeMax[CoreType.Primal] + 1;
        typeMax[CoreType.Divine] =
            typeCounter[CoreType.Divine] +
            _mintCountPerType[3] -
            1;

        typeCounter[CoreType.Arcane] = typeMax[CoreType.Divine] + 1;
        typeMax[CoreType.Arcane] =
            typeCounter[CoreType.Arcane] +
            _mintCountPerType[2] -
            1;

        typeCounter[CoreType.Mythic] = typeMax[CoreType.Arcane] + 1;
        typeMax[CoreType.Mythic] =
            typeCounter[CoreType.Mythic] +
            _mintCountPerType[1] -
            1;

        typeCounter[CoreType.Elemental] = typeMax[CoreType.Mythic] + 1;
        typeMax[CoreType.Elemental] =
            typeCounter[CoreType.Elemental] +
            _mintCountPerType[0] -
            1;
    }

    /**
     * Reserve NFTs
     *
     * @param _reservedAddress: reserved address
     * @param _reserveCountPerType: array for reserve count per core type
     */
    function reserve(
        address _reservedAddress,
        uint256[] memory _reserveCountPerType
    ) public onlyOwner {
        require(_reservedAddress != address(0), "Invalid address");
        require(_reserveCountPerType.length == 5, "Invalid reserve count");

        //reserve some planets
        for (
            uint256 typeIdx = uint256(CoreType.Elemental);
            typeIdx <= uint256(CoreType.Primal);
            typeIdx++
        ) {
            for (
                uint256 nftId = typeCounter[CoreType(typeIdx)];
                nftId <
                typeCounter[CoreType(typeIdx)] + _reserveCountPerType[typeIdx];
                nftId++
            ) {
                uint256[] memory parents = new uint256[](0);
                planetContract.safeMint(
                    _generateGeneId(CoreType(typeIdx)),
                    parents,
                    _reservedAddress,
                    nftId
                );

                emit Reserved(nftId, _reservedAddress);
            }
            typeCounter[CoreType(typeIdx)] += _reserveCountPerType[typeIdx];
        }
    }

    /**
     * Purchase NFT
     *
     * @param coreType - Type of NFT
     */
    function purchase(
        CoreType coreType,
        uint256 time,
        bytes memory signature
    ) external onlyLimited onlyDuringSale onlyWhitelisted {
        if (getCurrentForSaleType() == ForSaleType.PublicSale) {
            bytes32 hash = keccak256(
                abi.encodePacked(uint256(coreType), time, msg.sender)
            );
            require(
                hash.toEthSignedMessageHash().recover(signature) ==
                    systemAddress &&
                    time + 600 >= block.timestamp, //valid signature period is 10 minutes
                "Invalid signature for Public Sale"
            );
        }

        uint256 price = prices[coreType];
        require(
            token.allowance(_msgSender(), address(this)) >= price,
            "Grant token approval to Sale Contract"
        );
        require(getAvailableCount(coreType) > 0, "Sold out");
        address buyer = _msgSender();
        uint256 nftId = typeCounter[coreType];

        token.transferFrom(buyer, address(this), price);
        uint256[] memory parents = new uint256[](0);
        planetContract.safeMint(
            _generateGeneId(coreType),
            parents,
            msg.sender,
            nftId
        );

        typeCounter[coreType] += 1;

        userPurchaseCounter[msg.sender] += 1;

        emit Sold(nftId, buyer, price);
    }

    /**
     * @notice - get available count for nft
     *
     * @param coreType - Type of NFT
     */
    function getAvailableCount(CoreType coreType)
        public
        view
        returns (uint256)
    {
        return 1 + typeMax[coreType] - typeCounter[coreType];
    }

    /**
     * @notice - Enable/Disable Sales
     * @dev - callable only by owner
     *
     * @param _isEnabled - enable? sales
     */
    function setEnabled(bool _isEnabled) external onlyOwner {
        isEnabled = _isEnabled;
        emit PresaleEnable(_isEnabled);
    }

    /**
     * @notice - set TypeCounter
     * @dev - callable only by owner
     *
     * @param _typeCounter - [ Elemental's counter, Mythic's counter, Arcane's counter, Divine's counter, Primal's counter ]
     */
    function setTypeCounter(uint256[] memory _typeCounter) external onlyOwner {
        require(_typeCounter.length == 5, "Invalid Type Counter");
        typeCounter[CoreType.Primal] = _typeCounter[4];
        typeCounter[CoreType.Divine] = _typeCounter[3];
        typeCounter[CoreType.Arcane] = _typeCounter[2];
        typeCounter[CoreType.Mythic] = _typeCounter[1];
        typeCounter[CoreType.Elemental] = _typeCounter[0];
        emit TypeCounterUpdated(_typeCounter);
    }

    /**
     * Withdraw any ERC20
     *
     * @param tokenAddress - ERC20 token address
     * @param amount - amount to withdraw
     * @param wallet - address to withdraw to
     */
    function withdrawFunds(
        address tokenAddress,
        uint256 amount,
        address wallet
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(wallet, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "./AccessProtected.sol";

abstract contract MultiWhitelist is AccessProtected {
    mapping(address => Whitelist) private _whitelisted;
    mapping(address => uint256) public userPurchaseCounter;
    mapping(WhitelistType => uint256) public purchaseLimits;

    enum WhitelistType {
        NON,
        WHITELIST,
        VIP_WHITELIST
    }
    struct Whitelist {
        bool isWhitelisted;
        WhitelistType whitelistType;
    }
    enum ForSaleType {
        NotForSale,
        ForVipOnly,
        ForWhitelist,
        PublicSale
    }
    mapping(ForSaleType => uint256) forSaleSchedule;

    event Whitelisted(address _user, WhitelistType whitelistType);
    event Blacklisted(address _user);
    event SaleScheduleUpdated(uint256[] _saleSchedule);

    /**
     * @notice Set the NFT purchase limits
     *
     * @param _purchaseLimits - NFT purchase limits
     */
    function setPurchaseLimits(uint256[] memory _purchaseLimits) external onlyAdmin {
        require(_purchaseLimits.length == 3, "Invalid purchase limits");
        purchaseLimits[WhitelistType.NON] = _purchaseLimits[0];
        purchaseLimits[WhitelistType.WHITELIST] = _purchaseLimits[1];
        purchaseLimits[WhitelistType.VIP_WHITELIST] = _purchaseLimits[2];
    }

    /**
     * @notice Whitelist User
     *
     * @param user - Address of User
     * @param whitelistType - Type of Whitelisting
     */
    function whitelist(address user, WhitelistType whitelistType)
        public
        onlyAdmin
    {
        _whitelisted[user].isWhitelisted = true;
        _whitelisted[user].whitelistType = whitelistType;
        emit Whitelisted(user, whitelistType);
    }

    /**
     * @notice Whitelist Users
     *
     * @param users - Addresses of Users
     */
    function whitelistBatch(
        address[] memory users,
        WhitelistType[] memory whitelistTypes
    ) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist(users[i], whitelistTypes[i]);
        }
    }

    /**
     * @notice Blacklist User
     *
     * @param user - Address of User
     */
    function blacklist(address user) public onlyAdmin {
        _whitelisted[user].isWhitelisted = false;
        _whitelisted[user].whitelistType = WhitelistType.NON;
        emit Blacklisted(user);
    }

    /**
     * @notice Blacklist Users
     *
     * @param users - Addresses of Users
     */
    function blacklistBatch(address[] memory users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            blacklist(users[i]);
        }
    }

    /**
     * @notice Check if Whitelisted
     *
     * @param user - Address of User
     * @return whether user is whitelisted
     */
    function isWhitelisted(address user)
        public
        view
        returns (Whitelist memory)
    {
        return _whitelisted[user];
    }

    /**
     * @notice Check if reached purchase limit
     *
     * @param user - Address of User
     * @return whether user is reached the purchase limit
     */
    function isReachedPurchaseLimit(address user)
        public
        view
        returns (bool)
    {
        return userPurchaseCounter[user] >= purchaseLimits[_whitelisted[user].whitelistType];
    }

    /**
     * @notice set for sale schedule
     *
     * @param _forSaleSchedule - for sale schedules [ ForVipOnly, ForWhitelist, PublicSale ]
     */
    function setForSaleSchedule(uint256[] memory _forSaleSchedule) external onlyAdmin {
        require(
            _forSaleSchedule.length == 3 &&
                _forSaleSchedule[2] >= _forSaleSchedule[1] &&
                _forSaleSchedule[1] >= _forSaleSchedule[0],
            'Invalid for sale schedule'
        );
        forSaleSchedule[ForSaleType.ForVipOnly] = _forSaleSchedule[0];
        forSaleSchedule[ForSaleType.ForWhitelist] = _forSaleSchedule[1];
        forSaleSchedule[ForSaleType.PublicSale] = _forSaleSchedule[2];

        emit SaleScheduleUpdated(_forSaleSchedule);
    }

    /**
     * @notice get current for sale type
     *
     * @return whether current for sale type
     */
    function getCurrentForSaleType()
        public
        view
        returns (ForSaleType)
    {
        if (forSaleSchedule[ForSaleType.PublicSale] > 0
            && forSaleSchedule[ForSaleType.PublicSale] <= block.timestamp) {
            return ForSaleType.PublicSale;
        }
        else if (forSaleSchedule[ForSaleType.ForWhitelist] > 0
                && forSaleSchedule[ForSaleType.ForWhitelist] <= block.timestamp) {
            return ForSaleType.ForWhitelist;
        }
        else if (forSaleSchedule[ForSaleType.ForVipOnly] > 0
                && forSaleSchedule[ForSaleType.ForVipOnly] <= block.timestamp) {
            return ForSaleType.ForVipOnly;
        }

        return ForSaleType.NotForSale;
    }

    /**
     * Throws if NFT purchase limit has exceeded.
     */
    modifier onlyLimited() {
        require(
            !isReachedPurchaseLimit(_msgSender()),
            "Purchase limit reached"
        );
        _;
    }

    /**
     * Throws if called by any account other than Whitelisted.
     */
    modifier onlyWhitelisted() {
        require(
            getCurrentForSaleType() == ForSaleType.PublicSale ||
            (
                getCurrentForSaleType() == ForSaleType.ForWhitelist &&
                _whitelisted[_msgSender()].whitelistType >= WhitelistType.WHITELIST &&
                _whitelisted[_msgSender()].isWhitelisted
            ) ||
            (
                getCurrentForSaleType() == ForSaleType.ForVipOnly &&
                _whitelisted[_msgSender()].whitelistType == WhitelistType.VIP_WHITELIST &&
                _whitelisted[_msgSender()].isWhitelisted
            ) ||
            _admins[_msgSender()] ||
            _msgSender() == owner(),
            "Caller is not Whitelisted"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./utils/Random.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ApeironPlanetGenerator is Random {
    enum CoreType {
        Elemental,
        Mythic,
        Arcane,
        Divine,
        Primal
    }
    // enum Bloodline {
    //     Pure,    //0
    //     Duo,     //1
    //     Tri,     //2
    //     Mix      //3
    // }
    mapping(CoreType => mapping(uint256 => uint256)) bloodlineRatioPerCoreType;
    mapping(CoreType => uint256) haveTagRatioPerCoreType;

    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }
    mapping(uint256 => PlanetTag[]) planetTagsPerBloodline;

    // enum ElementType {
    //     Fire,   //0
    //     Water,  //1
    //     Air,    //2
    //     Earth   //3
    // }

    event GenerateGeneId(
        uint256 bloodline,
        uint256[] elementOrders,
        uint256[] attributes,
        uint256 geneId
    );

    constructor() {
        bloodlineRatioPerCoreType[CoreType.Primal][
            0 /*Bloodline.Pure*/
        ] = 100;

        bloodlineRatioPerCoreType[CoreType.Divine][
            0 /*Bloodline.Duo*/
        ] = 10;
        bloodlineRatioPerCoreType[CoreType.Divine][
            1 /*Bloodline.Duo*/
        ] = 90;

        bloodlineRatioPerCoreType[CoreType.Arcane][
            0 /*Bloodline.Pure*/
        ] = 2;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            1 /*Bloodline.Duo*/
        ] = 30;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            2 /*Bloodline.Tri*/
        ] = 68;

        bloodlineRatioPerCoreType[CoreType.Mythic][
            0 /*Bloodline.Pure*/
        ] = 1;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            1 /*Bloodline.Duo*/
        ] = 9;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            2 /*Bloodline.Tri*/
        ] = 72;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            3 /*Bloodline.Mix*/
        ] = 18;

        bloodlineRatioPerCoreType[CoreType.Elemental][
            2 /*Bloodline.Tri*/
        ] = 70;
        bloodlineRatioPerCoreType[CoreType.Elemental][
            3 /*Bloodline.Mix*/
        ] = 30;

        haveTagRatioPerCoreType[CoreType.Primal] = 0;
        haveTagRatioPerCoreType[CoreType.Divine] = 20;
        haveTagRatioPerCoreType[CoreType.Arcane] = 10;
        haveTagRatioPerCoreType[CoreType.Mythic] = 10;
        haveTagRatioPerCoreType[CoreType.Elemental] = 10;

        //18 tags for Duo
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(1, 0, 55, 0, 55)); //Archipelago
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(2, 0, 0, 0, 75)); //Tallmountain Falls
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(3, 0, 75, 0, 0)); //Deep Sea
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(4, 55, 0, 0, 55)); //Redrock Mesas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(5, 0, 0, 0, 65)); //Mega Volcanoes
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(6, 75, 0, 0, 0)); //Pillars of Flame
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(7, 0, 0, 55, 55)); //Karsts
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(8, 0, 0, 0, 60)); //Hidden Caves
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(9, 0, 0, 75, 0)); //Floating Lands
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(10, 55, 55, 0, 0)); //Ghostlight Swamp
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(11, 0, 65, 0, 0)); //Boiling Seas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(12, 65, 0, 0, 0)); //Flametouched Oasis
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(13, 0, 55, 55, 0)); //White Frost
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(14, 0, 50, 0, 0)); //Monsoon
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(15, 0, 0, 65, 0)); //Frozen Gale
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(16, 55, 0, 55, 0)); //Anticyclonic Storm
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(17, 60, 0, 0, 0)); //Conflagration
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(18, 0, 0, 60, 0)); //Hurricane

        //28 tags for Tri
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(19, 35, 35, 0, 35)); //Rainforest
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(20, 0, 0, 0, 55)); //Jungle Mountains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(21, 0, 55, 0, 0)); //Tallest Trees
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(22, 55, 0, 0, 0)); //Steamwoods
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(23, 0, 40, 0, 40)); //Alpine
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(24, 40, 0, 0, 40)); //Sandy Jungle
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(25, 40, 40, 0, 0)); //Mangrove
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(26, 0, 35, 35, 35)); //Tundra
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(27, 0, 0, 0, 40)); //Snow-capped Peaks
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(28, 0, 40, 0, 0)); //Frozen Lakes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(29, 0, 0, 55, 0)); //Taiga
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(30, 0, 35, 0, 35)); //Hibernia
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(31, 0, 0, 40, 40)); //Prairie
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(32, 0, 40, 40, 0)); //Hailstorm
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(33, 35, 0, 35, 35)); //Wasteland
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(34, 0, 0, 0, 40)); //Sheerstone Spires
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(35, 40, 0, 0, 0)); //Lava Fields
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(36, 0, 0, 40, 0)); //Howling Gales
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(37, 35, 0, 0, 35)); //Dunes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(38, 0, 0, 35, 35)); //Barren Valleys
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(39, 40, 0, 40, 0)); //Thunder Plains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(40, 35, 35, 35, 0)); //Salt Marsh
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(41, 0, 40, 0, 0)); //Coral Reef
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(42, 40, 0, 0, 0)); //Fire Swamp
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(43, 0, 0, 40, 0)); //Windswept Heath
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(44, 35, 35, 0, 0)); //Beachside Mire
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(45, 0, 35, 35, 0)); //Gentlesnow Bog
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(46, 35, 0, 35, 0)); //Stormy Night Swamp

        //16 tags for Mix
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(47, 35, 35, 35, 35)); //Utopia
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(48, 30, 30, 30, 30)); //Garden
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(49, 0, 0, 0, 35)); //Mountain
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(50, 0, 35, 0, 0)); //Ocean
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(51, 35, 0, 0, 0)); //Wildfire
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(52, 0, 0, 35, 0)); //Cloud
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(53, 0, 30, 0, 30)); //Forest
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(54, 30, 0, 0, 30)); //Desert
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(55, 0, 0, 30, 30)); //Hill
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(56, 30, 30, 0, 0)); //Swamp
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(57, 0, 30, 30, 0)); //Snow
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(58, 30, 0, 30, 0)); //Plains
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(59, 0, 0, 0, 30)); //Dryland
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(60, 0, 30, 0, 0)); //Marsh
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(61, 30, 0, 0, 0)); //Drought
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(62, 0, 0, 30, 0)); //Storm
    }

    function _getBloodline(CoreType coreType, uint256 randomBaseValue)
        internal
        view
        returns (uint256)
    {
        uint256 picked = 3; //Bloodline.Mix;

        uint256 baseValue = 0;
        for (
            uint256 idx = 0; /*Bloodline.Pure*/
            idx <= 3; /*Bloodline.Mix*/
            idx++
        ) {
            // from Pure to Mix
            baseValue += bloodlineRatioPerCoreType[coreType][idx];
            if (_randomRangeByBaseValue(randomBaseValue, 1, 100) <= baseValue) {
                picked = idx;
                break;
            }
        }

        return picked;
    }

    function _getPlanetTag(
        CoreType coreType,
        uint256 bloodline,
        uint256[2] memory randomBaseValues
    ) internal view returns (PlanetTag memory) {
        PlanetTag memory planetTag;
        //exclude if it is pure
        if (
            bloodline != 0 && /*Bloodline.Pure*/
            //according to ratio
            haveTagRatioPerCoreType[coreType] >=
            _randomRangeByBaseValue(randomBaseValues[0], 1, 100)
        ) {
            //random pick a tag from pool
            planetTag = planetTagsPerBloodline[bloodline][
                _randomByBaseValue(
                    randomBaseValues[1],
                    planetTagsPerBloodline[bloodline].length
                )
            ];
        }
        return planetTag;
    }

    function _getElementOrders(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[4] memory randomBaseValues
    ) internal pure returns (uint256[] memory) {
        uint256[4] memory orders;
        uint256[] memory results = new uint256[](1 + uint256(bloodline));
        uint256 pickedIndex;

        //have not any tag
        if (planetTag.id == 0) {
            //dominant element index
            pickedIndex = _randomByBaseValue(randomBaseValues[0], 4);
        }
        //have any tag
        else {
            uint256 possibleElementSize;
            if (planetTag.fire > 0) {
                orders[possibleElementSize++] = 0; //ElementType.Fire
            }
            if (planetTag.water > 0) {
                orders[possibleElementSize++] = 1; //ElementType.Water
            }
            if (planetTag.air > 0) {
                orders[possibleElementSize++] = 2; //ElementType.Air
            }
            if (planetTag.earth > 0) {
                orders[possibleElementSize++] = 3; //ElementType.Earth
            }

            //dominant element index (random pick from possibleElements)
            pickedIndex = orders[
                _randomByBaseValue(randomBaseValues[0], possibleElementSize)
            ];
        }

        orders[0] = 0; //ElementType.Fire
        orders[1] = 1; //ElementType.Water
        orders[2] = 2; //ElementType.Air
        orders[3] = 3; //ElementType.Earth

        //move the specified element to 1st place
        (orders[0], orders[pickedIndex]) = (orders[pickedIndex], orders[0]);
        //assign the value as result
        results[0] = orders[0];

        //process the remaining elements
        for (uint256 i = 1; i <= bloodline; i++) {
            //random pick the index from remaining elements
            pickedIndex = i + _randomByBaseValue(randomBaseValues[i], 4 - i);
            //move the specified element to {i}nd place
            (orders[i], orders[pickedIndex]) = (orders[pickedIndex], orders[i]);
            //assign the value as result
            results[i] = orders[i];
        }

        return results;
    }

    function _getMaxBetweenValueAndPlanetTag(
        uint256 value,
        uint256 elementType,
        PlanetTag memory planetTag
    ) internal pure returns (uint256) {
        if (planetTag.id > 0) {
            if (
                elementType == 0 /*ElementType.Fire*/
            ) {
                return Math.max(value, planetTag.fire);
            } else if (
                elementType == 1 /*ElementType.Water*/
            ) {
                return Math.max(value, planetTag.water);
            } else if (
                elementType == 2 /*ElementType.Air*/
            ) {
                return Math.max(value, planetTag.air);
            } else if (
                elementType == 3 /*ElementType.Earth*/
            ) {
                return Math.max(value, planetTag.earth);
            }
        }

        return value;
    }

    function _getElementValues(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[] memory elementOrders,
        uint256[3] memory randomBaseValues
    ) internal pure returns (uint256[4] memory) {
        require(elementOrders.length == bloodline + 1, "invalid elementOrders");

        uint256[4] memory values;

        if (
            bloodline == 0 /*Bloodline.Pure*/
        ) {
            values[uint256(elementOrders[0])] = 100;
        } else if (
            bloodline == 1 /*Bloodline.Duo*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 50, 59),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] =
                100 -
                values[uint256(elementOrders[0])];
        } else if (
            bloodline == 2 /*Bloodline.Tri*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 33, 43),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                23,
                Math.min(43, 95 - values[uint256(elementOrders[0])])
            );
            values[uint256(elementOrders[2])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])];
        } else if (
            bloodline == 3 /*Bloodline.Mix*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 25, 35),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                20,
                34
            );
            values[uint256(elementOrders[2])] = _randomRangeByBaseValue(
                randomBaseValues[2],
                20,
                Math.min(
                    34,
                    95 -
                        values[uint256(elementOrders[0])] -
                        values[uint256(elementOrders[1])]
                )
            );
            values[uint256(elementOrders[3])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])] -
                values[uint256(elementOrders[2])];
        }

        return values;
    }

    function _generateGeneId(CoreType coreType) internal returns (uint256) {
        uint256 bloodline = _getBloodline(coreType, _getRandomBaseValue());
        PlanetTag memory planetTag = _getPlanetTag(
            coreType,
            bloodline,
            [_getRandomBaseValue(), _getRandomBaseValue()]
        );
        uint256[] memory elementOrders = _getElementOrders(
            bloodline,
            planetTag,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[4] memory elementValues = _getElementValues(
            bloodline,
            planetTag,
            elementOrders,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementValues[0]; //element: fire
        attributes[1] = elementValues[1]; //element: water
        attributes[2] = elementValues[2]; //element: air
        attributes[3] = elementValues[3]; //element: earth
        attributes[4] = planetTag.id; //primeval legacy tag
        attributes[5] = _randomRange(0, 1); //body: sex
        attributes[6] = _randomRange(0, 11); //body: weapon
        attributes[7] = _randomRange(0, 3); //body: body props
        attributes[8] = _randomRange(0, 5); //body: head props
        attributes[9] = _randomRange(0, 23); //skill: cskill1
        attributes[10] = (attributes[9] + _randomRange(1, 23)) % 24; //skill: cskill2
        attributes[11] = (attributes[10] + _randomRange(1, 22)) % 24; //skill: cskill3
        if (attributes[11] == attributes[9]) {
            attributes[11] = (attributes[11] + 1) % 24;
        }
        attributes[12] = _randomRange(0, 31); //skill: pskill1
        attributes[13] = (attributes[12] + _randomRange(1, 31)) % 32; //skill: pskill2
        attributes[14] = _randomRange(0, 2); //class
        attributes[15] = _randomRange(0, 31); //special gene
        // attributes[16] = 0; //generation 1st digit
        // attributes[17] = 0; //generation 2nd digit
        uint256 geneId = _convertToGeneId(attributes);
        emit GenerateGeneId(bloodline, elementOrders, attributes, geneId);
        return geneId;
    }

    function _convertToGeneId(uint256[] memory attributes)
        internal
        pure
        returns (uint256)
    {
        uint256 geneId = 0;
        for (uint256 id = 0; id < attributes.length; id++) {
            geneId += attributes[id] << (8 * id);
        }

        return geneId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironPlanet is IERC721 {
    function safeMint(
        uint256 gene,
        // uint256 parentA,
        // uint256 parentB,
        uint256[] calldata parents,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity 0.8.12;

contract Random {
    uint256 randomNonce;

    function __getRandomBaseValue(uint256 _nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce
        )));
    }

    function _getRandomBaseValue() internal returns (uint256) {
        randomNonce++;
        return __getRandomBaseValue(randomNonce);
    }

    function __random(uint256 _nonce, uint256 _modulus) internal view returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return __getRandomBaseValue(_nonce) % _modulus;
    }

    function _random(uint256 _modulus) internal returns (uint256) {
        randomNonce++;
        return __random(randomNonce, _modulus);
    }

    function _randomByBaseValue(uint256 _baseValue, uint256 _modulus) internal pure returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return _baseValue % _modulus;
    }

    function __randomRange(uint256 _nonce, uint256 _start, uint256 _end) internal view returns (uint256) {
        if (_end > _start) {
            return _start + __random(_nonce, _end + 1 - _start);
        }
        else {
            return _end + __random(_nonce, _start + 1 - _end);
        }
    }

    function _randomRange(uint256 _start, uint256 _end) internal returns (uint256) {
        randomNonce++;
        return __randomRange(randomNonce, _start, _end);
    }

    function _randomRangeByBaseValue(uint256 _baseValue, uint256 _start, uint256 _end) internal pure returns (uint256) {
        if (_end > _start) {
            return _start + _randomByBaseValue(_baseValue, _end + 1 - _start);
        }
        else {
            return _end + _randomByBaseValue(_baseValue, _start + 1 - _end);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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