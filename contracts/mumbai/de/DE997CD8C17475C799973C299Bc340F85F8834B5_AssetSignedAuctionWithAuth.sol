// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import {IERC20} from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts-0.8/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import {SigUtil} from "../common/Libraries/SigUtil.sol";
import {PriceUtil} from "../common/Libraries/PriceUtil.sol";
import {TheSandbox712} from "../common/Base/TheSandbox712.sol";
import {MetaTransactionReceiver} from "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import {ERC1271} from "../common/interfaces/ERC1271.sol";
import {ERC1271Constants} from "../common/interfaces/ERC1271Constants.sol";
import {ERC1654} from "../common/interfaces/ERC1654.sol";
import {ERC1654Constants} from "../common/interfaces/ERC1654Constants.sol";
import {IAuthValidator} from "../common/interfaces/IAuthValidator.sol";
import {IERC1155} from "../common/interfaces/IERC1155.sol";

contract AssetSignedAuctionWithAuth is
    ReentrancyGuard,
    ERC1654Constants,
    ERC1271Constants,
    TheSandbox712,
    MetaTransactionReceiver
{
    struct ClaimSellerOfferRequest {
        address buyer;
        address payable seller;
        address token;
        uint256[] purchase;
        uint256[] auctionData;
        uint256[] ids;
        uint256[] amounts;
        bytes signature;
        bytes backendSignature;
    }

    enum SignatureType {DIRECT, EIP1654, EIP1271}

    bytes32 public constant BACKEND_TYPEHASH =
        keccak256(
            "Auction(address to,address from,address token,bytes auctionData,bytes ids,bytes amounts,bytes purchase)"
        );

    bytes32 public constant AUCTION_TYPEHASH =
        keccak256("Auction(address from,address token,bytes auctionData,bytes ids,bytes amounts)");

    event OfferClaimed(
        address indexed seller,
        address indexed buyer,
        uint256 indexed offerId,
        uint256 amount,
        uint256 pricePaid,
        uint256 feePaid
    );
    event OfferCancelled(address indexed seller, uint256 indexed offerId);
    event NewFeeLimit(uint256 feeLimit);

    uint256 public constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Stack too deep, grouping parameters
    // AuctionData:
    uint256 public constant AuctionData_OfferId = 0;
    uint256 public constant AuctionData_StartingPrice = 1;
    uint256 public constant AuctionData_EndingPrice = 2;
    uint256 public constant AuctionData_StartedAt = 3;
    uint256 public constant AuctionData_Duration = 4;
    uint256 public constant AuctionData_Packs = 5;

    mapping(address => mapping(uint256 => uint256)) public claimed;

    IAuthValidator public _authValidator;
    IERC1155 public _asset;
    uint256 public _fee10000th = 0;
    uint256 public _feeLimit = 500;
    uint256 public _maxfeeLimit = 500; // 5%
    address payable public _feeCollector;

    event FeeSetup(address feeCollector, uint256 fee10000th);

    constructor(
        IERC1155 asset,
        address admin,
        address initialMetaTx,
        address payable feeCollector,
        uint256 fee10000th,
        address authValidator
    ) TheSandbox712() {
        require(fee10000th <= _feeLimit, "Fee above the limit");
        _asset = asset;
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
        _admin = admin;
        _setMetaTransactionProcessor(initialMetaTx, true);
        _authValidator = IAuthValidator(authValidator);
    }

    // check backend signature to avoid front-running
    modifier isAuthValid(bytes memory signature, bytes32 hashedData) {
        require(_authValidator.isAuthValid(signature, hashedData), "INVALID_AUTH");
        _;
    }

    /// @notice set fee parameters
    /// @param feeCollector address receiving the fee
    /// @param fee10000th fee in 10,000th
    function setFee(address payable feeCollector, uint256 fee10000th) external {
        require(feeCollector != address(0), "feeCollector cannot be Zero address");
        require(msg.sender == _admin, "only admin can change fee");
        require(fee10000th <= _feeLimit, "Fee above the limit");
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
    }

    /// @notice setFeeLimit parameters
    /// @param newFeeLimit new fee limit
    function setFeeLimit(uint256 newFeeLimit) external {
        require(msg.sender == _admin, "only admin can change fee limit");
        require(newFeeLimit <= _maxfeeLimit, "new limit above max limit");

        _feeLimit = newFeeLimit;

        emit NewFeeLimit(newFeeLimit);
    }

    /// @notice claim offer using EIP712
    /// @param input Claim Seller Offer Request
    function claimSellerOffer(ClaimSellerOfferRequest memory input)
        external
        payable
        isAuthValid(
            input.backendSignature,
            _hashBackendSig(
                input.buyer,
                input.seller,
                input.token,
                input.auctionData,
                input.ids,
                input.amounts,
                input.purchase
            )
        )
    {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.DIRECT
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1271 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1271(ClaimSellerOfferRequest memory input)
        external
        payable
        isAuthValid(
            input.backendSignature,
            _hashBackendSig(
                input.buyer,
                input.seller,
                input.token,
                input.auctionData,
                input.ids,
                input.amounts,
                input.purchase
            )
        )
    {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1271
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1654 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1654(ClaimSellerOfferRequest memory input)
        external
        payable
        isAuthValid(
            input.backendSignature,
            _hashBackendSig(
                input.buyer,
                input.seller,
                input.token,
                input.auctionData,
                input.ids,
                input.amounts,
                input.purchase
            )
        )
    {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1654
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice cancel a offer previously signed, new offer need to use a id not used yet
    /// @param offerId offer to cancel
    function cancelSellerOffer(uint256 offerId) external {
        require(claimed[msg.sender][offerId] != MAX_UINT256, "Sell offer was already cancelled");
        claimed[msg.sender][offerId] = MAX_UINT256;
        emit OfferCancelled(msg.sender, offerId);
    }

    function _executeDeal(
        address token,
        uint256[] memory purchase,
        address buyer,
        address payable seller,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal nonReentrant {
        uint256 offer =
            PriceUtil.calculateCurrentPrice(
                auctionData[AuctionData_StartingPrice],
                auctionData[AuctionData_EndingPrice],
                auctionData[AuctionData_Duration],
                block.timestamp - auctionData[AuctionData_StartedAt]
            ) * purchase[0];
        claimed[seller][auctionData[AuctionData_OfferId]] =
            claimed[seller][auctionData[AuctionData_OfferId]] +
            purchase[0];

        uint256 fee = 0;
        if (_fee10000th > 0) {
            fee = PriceUtil.calculateFee(offer, _fee10000th);
        }

        uint256 total = offer + fee;
        require(total <= purchase[1], "offer exceeds max amount to spend");

        if (token != address(0)) {
            require(IERC20(token).transferFrom(buyer, seller, offer), "failed to transfer token price");
            if (fee > 0) {
                require(IERC20(token).transferFrom(buyer, _feeCollector, fee), "failed to collect fee");
            }
        } else {
            require(msg.value >= total, "ETH < total");
            if (msg.value > total) {
                Address.sendValue(payable(msg.sender), msg.value - total);
            }
            Address.sendValue(seller, offer);
            if (fee > 0) {
                Address.sendValue(_feeCollector, fee);
            }
        }

        uint256[] memory packAmounts = new uint256[](amounts.length);
        for (uint256 i = 0; i < packAmounts.length; i++) {
            packAmounts[i] = amounts[i] * purchase[0];
        }
        _asset.safeBatchTransferFrom(seller, buyer, ids, packAmounts, "");
        emit OfferClaimed(seller, buyer, auctionData[AuctionData_OfferId], purchase[0], offer, fee);
    }

    function _ensureCorrectSigner(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory signature,
        SignatureType signatureType
    ) internal view {
        bytes memory dataToHash;

        dataToHash = abi.encodePacked(
            "\x19\x01",
            _DOMAIN_SEPARATOR,
            _hashAuction(from, token, auctionData, ids, amounts)
        );

        if (signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(from).isValidSignature(dataToHash, signature) == ERC1271_MAGICVALUE,
                "invalid 1271 signature"
            );
        } else if (signatureType == SignatureType.EIP1654) {
            require(
                ERC1654(from).isValidSignature(keccak256(dataToHash), signature) == ERC1654_MAGICVALUE,
                "invalid 1654 signature"
            );
        } else {
            address signer = SigUtil.recover(keccak256(dataToHash), signature);
            require(signer == from, "signer != from");
        }
    }

    function _verifyParameters(
        address buyer,
        address payable seller,
        address token,
        uint256 buyAmount,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal view {
        require(ids.length == amounts.length, "ids and amounts length not matching");
        require(
            buyer == msg.sender || (token != address(0) && _metaTransactionContracts[msg.sender]),
            "not authorized"
        );
        uint256 amountAlreadyClaimed = claimed[seller][auctionData[AuctionData_OfferId]];
        require(amountAlreadyClaimed != MAX_UINT256, "Auction cancelled");

        uint256 total = amountAlreadyClaimed + buyAmount;
        require(total <= auctionData[AuctionData_Packs], "Buy amount exceeds sell amount");

        require(auctionData[AuctionData_StartedAt] <= block.timestamp, "Auction didn't start yet");
        require(
            auctionData[AuctionData_StartedAt] + auctionData[AuctionData_Duration] > block.timestamp,
            "Auction finished"
        );
    }

    function _hashAuction(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AUCTION_TYPEHASH,
                    from,
                    token,
                    keccak256(abi.encodePacked(auctionData)),
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts))
                )
            );
    }

    function _hashBackendSig(
        address to,
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory purchase
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BACKEND_TYPEHASH,
                    to,
                    from,
                    token,
                    keccak256(abi.encodePacked(auctionData)),
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts)),
                    keccak256(abi.encodePacked(purchase))
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract TheSandbox712 {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable _DOMAIN_SEPARATOR;

    constructor() {
        _DOMAIN_SEPARATOR = keccak256(
            // chainId 137 = Polygon
            abi.encode(EIP712DOMAIN_TYPEHASH, keccak256("The Sandbox"), keccak256("1"), block.chainid, address(this))
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract MetaTransactionReceiver is WithAdmin {
    mapping(address => bool) internal _metaTransactionContracts;
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) external {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library PriceUtil {
    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 secondsPassed
    ) internal pure returns (uint256) {
        if (secondsPassed > duration) {
            return endingPrice;
        }
        if (endingPrice == startingPrice) {
            return endingPrice;
        } else if (endingPrice > startingPrice) {
            return startingPrice + ((endingPrice - startingPrice) * secondsPassed) / duration;
        } else {
            return startingPrice - ((startingPrice - endingPrice) * secondsPassed) / duration;
        }
    }

    function calculateFee(uint256 price, uint256 fee10000th) internal pure returns (uint256) {
        // _fee < 10000, so the result will be <= price
        return (price * fee10000th) / 10000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65, "incorrect signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "version of signature should be 27 or 28");

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0), "incorrect address");
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param data Arbitrary length data signed on the behalf of address(this)
     * @param signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory data, bytes memory signature) external view returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract ERC1271Constants {
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ERC1654 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param hash 32 bytes hash to be signed
     * @param signature Signature byte array associated with hash
     * @return magicValue - 0x1626ba7e if valid else 0x00000000
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract ERC1654Constants {
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IAuthValidator {
    function isAuthValid(bytes calldata signature, bytes32 hashedData) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}