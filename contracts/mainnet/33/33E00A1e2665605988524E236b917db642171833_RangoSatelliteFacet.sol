// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../interfaces/IWETH.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IRango.sol";
import "../../interfaces/IAxelarExecutable.sol";
import "../../interfaces/IAxelarGasService.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";
import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../libraries/LibDiamond.sol";


/// @title The root contract that handles Rango's interaction with satellite
/// @author 0xiden
/// @dev This is deployed as a separate contract from RangoV1
contract RangoSatelliteFacet is IRango, ReentrancyGuard, IRangoSatellite, IAxelarExecutable {
    /// @notice The address of satellite contract
    address private gatewayAddress;
    address private gasService;

    /// @notice Emits when the satellite gateway address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGatewayAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Emits when the satellite gasService address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGasServiceAddressUpdated(address _oldAddress, address _newAddress);

    /// Constructor ///

    /// @notice Initialize the contract.
    /// @param _gatewayAddress The address of whitelist contracts for bridge
    /// @param _gasServiceAddress The address of whitelist contracts for bridge
    constructor(address _gatewayAddress, address _gasServiceAddress) {
        updateSatelliteGatewayInternal(_gatewayAddress);
        updateSatelliteGasServiceInternal(_gasServiceAddress);
    }

    /// @notice Updates the address of satellite gateway contract
    /// @param _address The new address of satellite gateway contract
    function updateSatelliteGatewayAddress(address _address) public {
        LibDiamond.enforceIsContractOwner();
        updateSatelliteGatewayInternal(_address);
    }

    /// @notice Updates the address of satellite gasService contract
    /// @param _address The new address of satellite gasService contract
    function updateSatelliteGasServiceAddress(address _address) public {
        LibDiamond.enforceIsContractOwner();
        updateSatelliteGasServiceInternal(_address);
    }

    /// @notice Emits when an ERC20 token (non-native) bridge request is sent to satellite bridge
    /// @param _dstChainId The network id of destination chain, ex: 56 for BSC
    /// @param _token The requested token to bridge
    /// @param _receiver The receiver address in the destination chain
    /// @param _amount The requested amount to bridge
    event SatelliteSendTokenCalled(uint256 _dstChainId, address _token, address _receiver, uint256 _amount);
    
    /// @notice A series of events with different status value to help us track the progress of cross-chain swap
    /// @param token The token address in the current network that is being bridged
    /// @param outputAmount The latest observed amount in the path, aka: input amount for source and output amount on dest
    /// @param status The latest status of the overall flow
    /// @param source The source address that initiated the transaction
    /// @param destination The destination address that received the money, ZERO address if not sent to the end-user yet
    event SatelliteSwapStatusUpdated(
        address token, 
        uint256 outputAmount, 
        LibInterchain.OperationStatus status, 
        address source,
        address destination
    );

    /// @notice Executes a bridging via satellite
    /// @param request The extra fields required by the satellite bridge
    /// @param token The requested token to bridge
    /// @param amount The requested amount to bridge
    function doSatelliteBridge(
        SatelliteBridgeRequest memory request,
        address token,
        uint256 amount
    ) public payable nonReentrant {
        address receiver = request.receiver;
        uint dstChainId = request.toChainId;

        require(gatewayAddress != LibSwapper.ETH, 'Satellite gateway address not set');
        require(block.chainid != dstChainId, 'Invalid destination Chain! Cannot bridge to the same network.');
        require(token != LibSwapper.ETH, 'Source token address is null! Not supported by axelar!');
        
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        LibSwapper.approve(token, gatewayAddress, amount);

        if (request.bridgeType == SatelliteBridgeType.TRANSFER) {
            IAxelarGateway(gatewayAddress).sendToken(request.toChain, toString(request.receiver), request.symbol, amount);
            emit SatelliteSendTokenCalled(dstChainId, token, receiver, amount);
        } else {
            require(gasService != LibSwapper.ETH, 'Satellite gasService address not set');
            require(request.relayerGas > 0, 'axelar needs native fee for relayer');
            require(msg.value >= request.relayerGas, 'relayer gas is not provided');

            bytes memory payload = request.bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE
                ? abi.encode(request.imMessage)
                : new bytes(0);
    
            IAxelarGasService(gasService).payNativeGasForContractCallWithToken{value: request.relayerGas}(
                address(this),
                request.toChain,
                toString(request.receiver),
                payload,
                request.symbol,
                amount,
                address(this) // fixme: set rango fee add
            );
                
            IAxelarGateway(gatewayAddress).callContractWithToken(
                request.toChain,
                toString(request.receiver),
                payload,
                request.symbol,
                amount
            );
            emit SatelliteSwapStatusUpdated(
                token,
                amount,
                LibInterchain.OperationStatus.Created,
                request.imMessage.originalSender,
                request.imMessage.recipient
            );
        }
    }

    /// @notice Executes a DEX (arbitrary) call + a Satellite bridge call
    /// @dev The Satellite part is handled in the RangoSatellite.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function satelliteBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable nonReentrant {
        (uint out, uint value) = LibSwapper.onChainSwapsPreBridge(request, calls, 0);
        doSatelliteBridge(bridgeRequest, request.toToken, out);
    } 

    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = '0123456789abcdef';
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = '0';
        byteString[1] = 'x';

        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) override internal virtual {
        Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
        address _token = IAxelarGateway(gatewayAddress).tokenAddresses(tokenSymbol);
        (address receivedToken, uint dstAmount, LibInterchain.OperationStatus status) = LibInterchain.handleDestinationMessage(_token, amount, m);

        emit SatelliteSwapStatusUpdated(receivedToken, dstAmount, status, m.originalSender, m.recipient);
    }

    function updateSatelliteGatewayInternal(address _address) private {
        address oldAddress = gatewayAddress;
        gatewayAddress = _address;
        IAxelarExecutable.gateway = IAxelarGateway(_address);
        emit SatelliteGatewayAddressUpdated(oldAddress, _address);
    }

    function updateSatelliteGasServiceInternal(address _address) private {
        address oldAddress = gasService;
        gasService = _address;
        emit SatelliteGasServiceAddressUpdated(oldAddress, _address);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IAxelarGateway } from './IAxelarGateway.sol';

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    //constructor(address gateway_) {
    //    gateway = IAxelarGateway(gateway_);
    //}

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import './IUpgradable.sol';

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService is IUpgradable {
    error NothingReceived();
    error TransferFailed();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IAxelarGateway {

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    function tokenAddresses(string memory symbol) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/// @title An interface to interchain message types
/// @author Uchiha Sasuke
interface Interchain {
    enum ActionType { NO_ACTION, UNI_V2, UNI_V3, WRAP, UNWRAP, CALL }
    enum CallSubActionType { WRAP, UNWRAP, NO_ACTION }

    struct RangoInterChainMessage {
        uint64 dstChainId;
        address bridgeRealOutput;
        address toToken;
        address originalSender;
        address recipient;
        ActionType actionType;
        bytes action;
        CallSubActionType postAction;

        // Extra message
        bytes dAppMessage;
        address dAppSourceContract;
        address dAppDestContract;
    }

    struct UniswapV2Action {
        address dexAddress;
        uint amountOutMin;
        address[] path;
        uint deadline;
    }

    struct UniswapV3ActionExactInputSingleParams {
        address dexAddress;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct CallAction { 
        address tokenIn;
        address spender; 
        CallSubActionType preAction;
        address payable target;
        bytes callData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRango {
    /// Structs ///
    struct BridgeDataXY {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    /// Events ///

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IRangoMessageReceiver {
    enum ProcessStatus { SUCCESS, REFUND_IN_SOURCE, REFUND_IN_DESTINATION }

    function handleRangoMessage(
        address token,
        uint amount,
        ProcessStatus status,
        bytes memory message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Interchain.sol";
import "../libraries/LibSwapper.sol";


/// @title An interface to RangoSatellite.sol contract to improve type hinting
/// @author 0xiden
interface IRangoSatellite {

    enum SatelliteBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    struct SatelliteBridgeRequest {
        SatelliteBridgeType bridgeType;

        address receiver;
        uint256 toChainId;
        string toChain;
        string symbol;
        uint256 relayerGas;
        Interchain.RangoInterChainMessage imMessage;
    }

    function satelliteBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./IStargateRouter.sol";
import "./Interchain.sol";
import "../libraries/LibSwapper.sol";


/// @title An interface to RangoStargate.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoStargate {
    enum StargateBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    struct StargateRequest {
        StargateBridgeType bridgeType;
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address payable refundAddress;
        uint256 minAmountLD;

        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;

        bytes to;
        uint stgFee;
        
        Interchain.RangoInterChainMessage payload;
    }

    function stargateSwap(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoStargate.StargateRequest memory stargateRequest
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IStargateReceiver {
    function sgReceive(
        uint16 chainId,
        bytes memory srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function swapETH(
        uint16 _dstChainId,
        address payable _refundAddress,
        bytes calldata _toAddress,
        uint256 _amountLD,
        uint256 _minAmountLD
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.16;

/// @dev based on swap router of uniswap v2 https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapexactethfortokens
interface IUniswapV2 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.16;
/// @dev based on IswapRouter of UniswapV3 https://docs.uniswap.org/protocol/reference/periphery/interfaces/ISwapRouter
interface IUniswapV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();
    error UintOutOfBounds();

    // -------------------------

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        if (_bytes.length < _start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        if (_bytes.length < _start + 1) {
            revert UintOutOfBounds();
        }
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        if (_bytes.length < _start + 2) {
            revert UintOutOfBounds();
        }
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        if (_bytes.length < _start + 4) {
            revert UintOutOfBounds();
        }
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        if (_bytes.length < _start + 8) {
            revert UintOutOfBounds();
        }
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        if (_bytes.length < _start + 12) {
            revert UintOutOfBounds();
        }
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        if (_bytes.length < _start + 16) {
            revert UintOutOfBounds();
        }
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        if (_bytes.length < _start + 32) {
            revert UintOutOfBounds();
        }
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        if (_bytes.length < _start + 32) {
            revert UintOutOfBounds();
        }
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibUtil } from "../libraries/LibUtil.sol";
import { OnlyContractOwner } from "../utils/Errors.sol";

/// Implementation of EIP-2535 Diamond Standard
/// https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    /// @dev keccak256("diamond.standard.diamond.storage");
    bytes32 internal constant DIAMOND_STORAGE_POSITION = hex"c8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c";

    // Diamond specific errors
    error IncorrectFacetCutAction();
    error NoSelectorsInFace();
    error FunctionAlreadyExists();
    error FacetAddressIsZero();
    error FacetAddressIsNotZero();
    error FacetContainsNoCode();
    error FunctionDoesNotExist();
    error FunctionIsImmutable();
    error InitZeroButCalldataNotEmpty();
    error CalldataEmptyButInitNotZero();
    error InitReverted();
    // ----------------

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) revert OnlyContractOwner();
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert IncorrectFacetCutAction();
            }
            unchecked {
                ++facetIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (!LibUtil.isZeroAddress(oldFacetAddress)) {
                revert FunctionAlreadyExists();
            }
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert FunctionAlreadyExists();
            }
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (!LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsNotZero();
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FunctionDoesNotExist();
        }
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) {
            revert FunctionIsImmutable();
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (LibUtil.isZeroAddress(_init)) {
            if (_calldata.length != 0) {
                revert InitZeroButCalldataNotEmpty();
            }
        } else {
            if (_calldata.length == 0) {
                revert CalldataEmptyButInitNotZero();
            }
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitReverted();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert FacetContainsNoCode();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2.sol";
import "../interfaces/IUniswapV3.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IRangoStargate.sol";
import "../interfaces/IStargateReceiver.sol";
import "../interfaces/IRangoMessageReceiver.sol";
import "./LibSwapper.sol";

library LibInterchain {

    /// @dev keccak256("exchange.rango.library.interchain")
    bytes32 internal constant BASE_MESSAGING_CONTRACT_NAMESPACE = hex"ff95014231b901d2b22bd69b4e83dacd84ac05e8c2d1e9fba0c7e2f3ed0db0eb";

    struct BaseInterchainStorage {
        mapping (address => bool) whitelistMessagingContracts;
    }

    /// @notice Status of cross-chain swap
    /// @param Created It's sent to bridge and waiting for bridge response
    /// @param Succeeded The whole process is success and end-user received the desired token in the destination
    /// @param RefundInSource Bridge was out of liquidity and middle asset (ex: USDC) is returned to user on source chain
    /// @param RefundInDestination Our handler on dest chain this.executeMessageWithTransfer failed and we send middle asset (ex: USDC) to user on destination chain
    /// @param SwapFailedInDestination Everything was ok, but the final DEX on destination failed (ex: Market price change and slippage)
    enum OperationStatus {
        Created,
        Succeeded,
        RefundInSource,
        RefundInDestination,
        SwapFailedInDestination
    }

    // @notice Adds a contract to the whitelisted messaging dApps that can be called
    /// @param _dapp The address of dApp
    function addMessagingDApp(address _dapp) internal {
        BaseInterchainStorage storage baseStorage = getBaseMessagingContractStorage();
        baseStorage.whitelistMessagingContracts[_dapp] = true;
    }

    /// @notice Removes a contract from dApps that can be called
    /// @param _dapp The address of dApp
    function removeMessagingDApp(address _dapp) internal {
        BaseInterchainStorage storage baseStorage = getBaseMessagingContractStorage();

        require(baseStorage.whitelistMessagingContracts[_dapp], "Factory not found");
        delete baseStorage.whitelistMessagingContracts[_dapp];
    }

    /// @notice This event indicates that a dApp used Rango messaging (dAppMessage field) and we delivered the message to it
    /// @param _receiverContract The address of dApp's contract that was called
    /// @param _token The address of the token that is sent to the dApp, ETH for native token
    /// @param _amount The amount of the token sent to them
    /// @param _status The status of operation, informing the dApp that the whole process was a success or refund
    /// @param _appMessage The custom message that the dApp asked Rango to deliver
    /// @param success Indicates that the function call to the dApp encountered error or not
    /// @param failReason If success = false, failReason will be the string reason of the failure (aka message of require)
    event CrossChainMessageCalled(
        address _receiverContract,
        address _token,
        uint _amount,
        IRangoMessageReceiver.ProcessStatus _status,
        bytes _appMessage,
        bool success,
        string failReason
    );

    event ActionDone(Interchain.ActionType actionType, address contractAddress, bool success, string reason);
    event SubActionDone(Interchain.CallSubActionType subActionType, address contractAddress, bool success, string reason);

    function handleDestinationMessage(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory m
    ) internal returns (address receivedToken, uint256 dstAmount, OperationStatus status) {

        LibSwapper.BaseSwapperStorage storage baseStorage = LibSwapper.getBaseSwapperStorage();
        address sourceToken = m.bridgeRealOutput == LibSwapper.ETH && _token == baseStorage.WETH ? LibSwapper.ETH : _token;

        bool ok = true;
        address outToken = sourceToken;
        dstAmount = _amount;

        if (m.actionType == Interchain.ActionType.UNI_V2)
            (ok, dstAmount, outToken) = _handleUniswapV2(sourceToken, _amount, m, baseStorage);
        else if (m.actionType == Interchain.ActionType.UNI_V3)
            (ok, dstAmount, outToken) = _handleUniswapV3(sourceToken, _amount, m, baseStorage);
        else if (m.actionType == Interchain.ActionType.CALL)
            (ok, dstAmount, outToken) = _handleCall(sourceToken, _amount, m, baseStorage);
        else if (m.actionType != Interchain.ActionType.NO_ACTION)
            revert("Unsupported actionType");

        if (ok && m.postAction != Interchain.CallSubActionType.NO_ACTION) {
            (ok, dstAmount, outToken) = _handlePostAction(outToken, dstAmount, m.postAction, baseStorage);
        }

        status = ok ? OperationStatus.Succeeded : OperationStatus.SwapFailedInDestination;
        IRangoMessageReceiver.ProcessStatus dAppStatus = ok 
            ? IRangoMessageReceiver.ProcessStatus.SUCCESS 
            : IRangoMessageReceiver.ProcessStatus.REFUND_IN_DESTINATION;

        _sendTokenWithDApp(outToken, dstAmount, m.recipient, m.dAppMessage, m.dAppDestContract, dAppStatus);

        return (receivedToken, dstAmount, status);
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUniswapV2(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        Interchain.UniswapV2Action memory action = abi.decode((_message.action), (Interchain.UniswapV2Action));
        require(baseStorage.whitelistContracts[action.dexAddress] == true, "Dex address is not whitelisted");
        require(action.path.length >= 2, "Invalid uniswap-V2 path");

        bool shouldDeposit = _token == LibSwapper.ETH && action.path[0] == baseStorage.WETH;
        if (!shouldDeposit)
            require(_token == action.path[0], "bridged token must be the same as the first token in destination swap path");
        else {
            require(action.path[0] == baseStorage.WETH, "Invalid uniswap-V2 path");
            IWETH(baseStorage.WETH).deposit{value: _amount}();
        }

        LibSwapper.approve(action.path[0], action.dexAddress, _amount);

        try
            IUniswapV2(action.dexAddress).swapExactTokensForTokens(
                _amount,
                action.amountOutMin,
                action.path,
                address(this),
                action.deadline
            )
        returns (uint256[] memory amounts) {
            emit ActionDone(Interchain.ActionType.UNI_V2, action.dexAddress, true, "");
            return (true, amounts[amounts.length - 1], action.path[action.path.length - 1]);
        } catch {
            emit ActionDone(Interchain.ActionType.UNI_V2, action.dexAddress, true, "Uniswap-V2 call failed");
            return (false, _amount, shouldDeposit ? baseStorage.WETH : _token);
        }
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUniswapV3(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool, uint256, address) {
        Interchain.UniswapV3ActionExactInputSingleParams memory action = abi
            .decode((_message.action), (Interchain.UniswapV3ActionExactInputSingleParams));

        require(baseStorage.whitelistContracts[action.dexAddress] == true, "Dex address is not whitelisted");

        bool shouldDeposit = _token == LibSwapper.ETH && action.tokenIn == baseStorage.WETH;
        if (!shouldDeposit)
            require(_token == action.tokenIn, "bridged token must be the same as the tokenIn in uniswapV3");
        else {
            require(action.tokenIn == baseStorage.WETH, "Invalid uniswap-V2 path");
            IWETH(baseStorage.WETH).deposit{value: _amount}();
        }

        LibSwapper.approve(action.tokenIn, action.dexAddress, _amount);

        try
            IUniswapV3(action.dexAddress).exactInputSingle(IUniswapV3.ExactInputSingleParams({
                tokenIn : action.tokenIn,
                tokenOut : action.tokenOut,
                fee : action.fee,
                recipient : address(this),
                deadline : action.deadline,
                amountIn : _amount,
                amountOutMinimum : action.amountOutMinimum,
                sqrtPriceLimitX96 : action.sqrtPriceLimitX96
            }))
        returns (uint amountOut) {
            emit ActionDone(Interchain.ActionType.UNI_V3, action.dexAddress, true, "");
            return (true, amountOut, action.tokenOut);
        } catch {
            emit ActionDone(Interchain.ActionType.UNI_V3, action.dexAddress, false, "Uniswap-V3 call failed");
            return (false, _amount, shouldDeposit ? baseStorage.WETH : _token);
        }
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleCall(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        Interchain.CallAction memory action = abi.decode((_message.action), (Interchain.CallAction));

        require(baseStorage.whitelistContracts[action.target] == true, "Action.target is not whitelisted");
        require(baseStorage.whitelistContracts[action.spender] == true, "Action.spender is not whitelisted");

        address sourceToken = _token;

        if (action.preAction == Interchain.CallSubActionType.WRAP) {
            require(_token == LibSwapper.ETH, "Cannot wrap non-native");
            require(action.tokenIn == baseStorage.WETH, "action.tokenIn must be WETH");
            (ok, amountOut, sourceToken) = _handleWrap(_token, _amount, baseStorage);
        } else if (action.preAction == Interchain.CallSubActionType.UNWRAP) {
            require(_token == baseStorage.WETH, "Cannot unwrap non-WETH");
            require(action.tokenIn == LibSwapper.ETH, "action.tokenIn must be ETH");
            (ok, amountOut, sourceToken) = _handleUnwrap(_token, _amount, baseStorage);
        } else {
            require(action.tokenIn == _token, "_message.tokenIn mismatch in call");
        }
        if (!ok)
            return (false, _amount, _token);

        if (sourceToken != LibSwapper.ETH)
            LibSwapper.approve(sourceToken, action.spender, _amount);

        uint value = sourceToken == LibSwapper.ETH ? _amount : 0;
        uint toBalanceBefore = LibSwapper.getBalanceOf(_message.toToken);

        (bool success, bytes memory ret) = action.target.call{value: value}(action.callData);
        if (success) {
            emit ActionDone(Interchain.ActionType.CALL, action.target, true, "");

            uint toBalanceAfter = LibSwapper.getBalanceOf(_message.toToken);
            return (true, toBalanceAfter - toBalanceBefore, _message.toToken);
        } else {
            emit ActionDone(Interchain.ActionType.CALL, action.target, false, LibSwapper._getRevertMsg(ret));
            return (false, _amount, _token);
        }
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _postAction The type of action to perform such as WRAP, UNWRAP
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handlePostAction(
        address _token,
        uint _amount,
        Interchain.CallSubActionType _postAction,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool ok, uint256 amountOut, address outToken) {

        if (_postAction == Interchain.CallSubActionType.WRAP) {
            require(_token == LibSwapper.ETH, "Cannot wrap non-native");
            (ok, amountOut, outToken) = _handleWrap(_token, _amount, baseStorage);
        } else if (_postAction == Interchain.CallSubActionType.UNWRAP) {
            require(_token == baseStorage.WETH, "Cannot unwrap non-WETH");
            (ok, amountOut, outToken) = _handleUnwrap(_token, _amount, baseStorage);
        } else {
            revert("Unsupported post-action");
        }
        if (!ok)
            return (false, _amount, _token);
        return (ok, amountOut, outToken);
    }

    /// @notice Performs a WETH.deposit operation
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleWrap(
        address _token,
        uint _amount,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        require(_token == LibSwapper.ETH, "Cannot wrap non-ETH tokens");

        IWETH(baseStorage.WETH).deposit{value: _amount}();
        emit SubActionDone(Interchain.CallSubActionType.WRAP, baseStorage.WETH, true, "");

        return (true, _amount, baseStorage.WETH);
    }

    /// @notice Performs a WETH.deposit operation
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUnwrap(
        address _token,
        uint _amount,
        LibSwapper.BaseSwapperStorage storage baseStorage
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        if (_token != baseStorage.WETH)
            revert("Non-WETH tokens unwrapped");

        IWETH(baseStorage.WETH).withdraw(_amount);
        emit SubActionDone(Interchain.CallSubActionType.UNWRAP, baseStorage.WETH, true, "");

        return (true, _amount, LibSwapper.ETH);
    }
    
    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @dev If there is a message from a dApp it sends the money to the contract instead of the end-user and calls its handleRangoMessage
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    function _sendTokenWithDApp(
        address _token,
        uint256 _amount,
        address _receiver,
        bytes memory _dAppMessage,
        address _dAppReceiverContract,
        IRangoMessageReceiver.ProcessStatus processStatus
    ) internal {
        bool thereIsAMessage = _dAppReceiverContract != LibSwapper.ETH;
        address immediateReceiver = thereIsAMessage ? _dAppReceiverContract : _receiver;
        BaseInterchainStorage storage messagingStorage = getBaseMessagingContractStorage();
        emit LibSwapper.SendToken(_token, _amount, immediateReceiver);

        if (_token == LibSwapper.ETH) {
            LibSwapper._sendNative(immediateReceiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), immediateReceiver, _amount);
        }

        if (thereIsAMessage) {
            require(
                messagingStorage.whitelistMessagingContracts[_dAppReceiverContract],
                "3rd-party contract not whitelisted"
            );

            try IRangoMessageReceiver(_dAppReceiverContract)
                .handleRangoMessage(_token, _amount, processStatus, _dAppMessage)
            {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, true, "");
            } catch Error(string memory reason) {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, false, reason);
            } catch (bytes memory lowLevelData) {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, false, LibSwapper._getRevertMsg(lowLevelData));
            }
        }
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseMessagingContractStorage() internal pure returns (BaseInterchainStorage storage s) {
        bytes32 namespace = BASE_MESSAGING_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

/// @title BaseSwapper
/// @author 0xiden
/// @notice library to provide swap functionality
library LibSwapper {

    /// @dev keccak256("exchange.rango.library.swapper")
    bytes32 internal constant BASE_SWAPPER_NAMESPACE = hex"43da06808a8e54e76a41d6f7b48ddfb23969b1387a8710ef6241423a5aefe64a";

    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    /// @notice The maximum possible percent of fee that Rango will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_FEE_PERCENT_x_10000 = 300;

    /// @notice The maximum possible percent of fee that third-party dApp will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_AFFILIATE_PERCENT_x_10000 = 300;

    struct BaseSwapperStorage {
        address payable feeContractAddress;
        address WETH;
        mapping (address => bool) whitelistContracts;
    }

    /// @notice Rango received a fee reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event FeeReward(address token, address wallet, uint amount);

    /// @notice Some money is sent to dApp wallet as affiliate reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event AffiliateReward(address token, address wallet, uint amount);

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);


    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call { address spender; address payable target; bytes callData; }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param feeIn The amount of fee charged by Rango
    /// @param affiliateIn The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    struct SwapRequest {
        address fromToken;
        address toToken;
        uint amountIn;
        uint feeIn;
        uint affiliateIn;
        address payable affiliatorAddress;
    }

    /// @notice initializes the base swapper and sets the init params (such as Wrapped token address)
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function setWeth(address _weth) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.WETH = _weth; 
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) internal {
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        address oldAddress = baseSwapperStorage.feeContractAddress;
        baseSwapperStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// Whitelist ///

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param _factory The address of the DEX
    function addWhitelist(address _factory) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.whitelistContracts[_factory] = true;
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param _factory The address of the DEX or dApp
    function removeWhitelist(address _factory) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        require(baseStorage.whitelistContracts[_factory], 'Factory not found');
        delete baseStorage.whitelistContracts[_factory];
    }

    function onChainSwapsPreBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out, uint value) {

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls);

        value = (request.toToken == ETH ? (out > 0 ? out : request.amountIn) : 0) + extraFee;
        return (out, value);
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(SwapRequest memory request, Call[] calldata calls) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);

        bytes[] memory result = callSwapsAndFees(request, calls);

        uint toBalanceAfter = getBalanceOf(request.toToken);
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        if (request.fromToken != ETH)
            require(fromBalanceAfter >= fromBalanceBefore, 'Source token balance on contract must not decrease after swap');
        else
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, 'Source token balance on contract must not decrease after swap');

        uint secondaryBalance;
        if (calls.length > 0) {
            require(toBalanceAfter - toBalanceBefore > 0, "No balance found after swaps");

            secondaryBalance = toBalanceAfter - toBalanceBefore;
            emit DexOutput(request.toToken, secondaryBalance);
        } else {
            secondaryBalance = toBalanceAfter > toBalanceBefore ? toBalanceAfter - toBalanceBefore : request.amountIn;
        }

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @dev It checks the max threshold for fee/affiliate
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();
        
        // validate
        require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");

        for(uint256 i = 0; i < calls.length; i++) {
            require(baseSwapperStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseSwapperStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
        }

        // Get all the money from user
        uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;
        if (isSourceNative)
            require(msg.value >= totalInputAmount, "Not enough ETH provided to contract");

        // Check max fee/affiliate is respected
        uint maxFee = totalInputAmount * MAX_FEE_PERCENT_x_10000 / 10000;
        uint maxAffiliate = totalInputAmount * MAX_AFFILIATE_PERCENT_x_10000 / 10000;
        require(request.feeIn <= maxFee, 'Requested fee exceeded max threshold');
        require(request.affiliateIn <= maxAffiliate, 'Requested affiliate reward exceeded max threshold');

        // Transfer from wallet to contract
        if (!isSourceNative) {
            for(uint256 i = 0; i < calls.length; i++) {
                approve(request.fromToken, calls[i].spender, totalInputAmount);
            }

            uint balanceBefore = getBalanceOf(request.fromToken);
            SafeERC20.safeTransferFrom(IERC20(request.fromToken), msg.sender, address(this), totalInputAmount);
            uint balanceAfter = getBalanceOf(request.fromToken);

            if(balanceAfter > balanceBefore && balanceAfter - balanceBefore < totalInputAmount)
                revert("Deflationary tokens are not supported by Rango contract");
        }

        // Get Platform fee
        if (request.feeIn > 0) {
            _sendToken(request.fromToken, request.feeIn, baseSwapperStorage.feeContractAddress, isSourceNative, false);
            emit FeeReward(request.fromToken, baseSwapperStorage.feeContractAddress, request.feeIn);
        }

        // Get affiliator fee
        if (request.affiliateIn > 0) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateIn, request.affiliatorAddress, isSourceNative, false);
            emit AffiliateReward(request.fromToken, request.affiliatorAddress, request.affiliateIn);
        }

        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = isSourceNative
                ? calls[i].target.call{value: request.amountIn}(calls[i].callData)
                : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            if (!success)
                revert(_getRevertMsg(ret));
            returnData[i] = ret;
        }

        return returnData;
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param to The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseSwapperStorage() internal pure returns (BaseSwapperStorage storage s) {
        bytes32 namespace = BASE_SWAPPER_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        IERC20 ercToken = IERC20(token);
        return token == ETH ? address(this).balance : ercToken.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(bytes memory _res) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

error TokenAddressIsZero();
error TokenNotSupported();
error CannotBridgeToSameNetwork();
error ZeroPostSwapBalance();
error NoSwapDataProvided();
error NativeValueWithERC();
error ContractCallNotAllowed();
error NullAddrIsNotAValidSpender();
error NullAddrIsNotAnERC20Token();
error NoTransferToNullAddress();
error NativeAssetTransferFailed();
error InvalidBridgeConfigLength();
error InvalidAmount();
error InvalidContract();
error InvalidConfig();
error UnsupportedChainId(uint256 chainId);
error InvalidReceiver();
error InvalidDestinationChain();
error InvalidSendingToken();
error InvalidCaller();
error AlreadyInitialized();
error NotInitialized();
error OnlyContractOwner();
error CannotAuthoriseSelf();
error RecoveryAddressCannotBeZero();
error CannotDepositNativeToken();
error InvalidCallData();
error NativeAssetNotSupported();
error UnAuthorized();
error NoSwapFromZeroBalance();
error InvalidFallbackAddress();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error InsufficientBalance(uint256 required, uint256 balance);
error ZeroAmount();
error InvalidFee();
error InformationMismatch();
error NotAContract();
error NotEnoughBalance(uint256 requested, uint256 available);

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/// @title Reentrancy Guard
/// @author 
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    /// @dev keccak256("exchange.rango.reentrancyguard");
    bytes32 private constant NAMESPACE = hex"4fe94118b1030ac5f570795d403ee5116fd91b8f0b5d11f2487377c2b0ab2559";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage() private pure returns (ReentrancyStorage storage data) {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}