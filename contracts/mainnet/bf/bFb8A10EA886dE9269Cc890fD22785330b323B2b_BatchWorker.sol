// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Batch Worker 

import "SafeERC20.sol";
import "Ownable.sol";
import "ITrustedWrapper.sol";
import "IERC20Extended.sol";
import "Subscriber.sol";



pragma solidity 0.8.16;

contract BatchWorker is Ownable, Subscriber {
    using SafeERC20 for IERC20Extended;

    ITrustedWrapper public trustedWrapper;
    
    constructor (uint256 _code) 
        Subscriber(_code)
    {}

    function wrapBatch(
        ETypes.INData[] calldata _inDataS, 
        ETypes.AssetItem[] calldata _collateralERC20,
        address[] memory _receivers
    ) public payable {
        _checkAndFixSubscription(msg.sender);
        require(
            _inDataS.length == _receivers.length, 
            "Array params must have equal length"
        );
        // make wNFTs
        for (uint256 i = 0; i < _inDataS.length; i++) {
            // wrap
            trustedWrapper.wrapUnsafe{value: (msg.value / _receivers.length)}(
                _inDataS[i],
                _collateralERC20,
                _receivers[i]
            );
            
            // Transfer original NFTs  to wrapper
            if (_inDataS[i].inAsset.asset.assetType == ETypes.AssetType.ERC721 ||
                _inDataS[i].inAsset.asset.assetType == ETypes.AssetType.ERC1155 ) 
            {
                trustedWrapper.transferIn(
                    _inDataS[i].inAsset, 
                    msg.sender
                );
            }
        }

        ETypes.AssetItem memory totalERC20Collateral;
        uint256 totalNativeAmount;
        for (uint256 i = 0; i < _collateralERC20.length; i ++) {

            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.ERC20) {
            
                totalERC20Collateral.asset.assetType = _collateralERC20[i].asset.assetType;
                totalERC20Collateral.asset.contractAddress = _collateralERC20[i].asset.contractAddress; 
                totalERC20Collateral.tokenId = _collateralERC20[i].tokenId;
                // We need construct totalERC20Collateral due make one transfer
                // instead of maked wNFT counts
                totalERC20Collateral.amount = _collateralERC20[i].amount * _receivers.length;
                
                uint256 amountTransfered = trustedWrapper.transferIn(
                   totalERC20Collateral, 
                    msg.sender
                );
                require(amountTransfered == totalERC20Collateral.amount, "Check transfer ERC20 amount fail");
                
            }

            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.NATIVE) {
                    totalNativeAmount += _collateralERC20[i].amount * _receivers.length;    
                } 
        }

        require(totalNativeAmount == msg.value,  "Native amount check failed");
    }


    function addCollateralBatch(
        address[] calldata _wNFTAddress, 
        uint256[] calldata _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateralERC20
    ) public payable {
        _checkAndFixSubscription(msg.sender);
        require(_wNFTAddress.length == _wNFTTokenId.length, "Array params must have equal length");
        
        for (uint256 i = 0; i < _collateralERC20.length; i ++) {
            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.ERC20) {
                // 1. Transfer all erc20 tokens to BatchWorker        
                IERC20Extended(_collateralERC20[i].asset.contractAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _collateralERC20[i].amount * _wNFTAddress.length
                );
                // 2. approve for spending to wrapper
                IERC20Extended(_collateralERC20[i].asset.contractAddress).safeIncreaseAllowance(
                    address(trustedWrapper),
                    _collateralERC20[i].amount * _wNFTAddress.length
                );
            }
        }

            
        uint256 valuePerWNFT = msg.value / _wNFTAddress.length;
        for (uint256 i = 0; i < _wNFTAddress.length; i ++){
            trustedWrapper.addCollateral{value: valuePerWNFT}(
                _wNFTAddress[i],
                _wNFTTokenId[i],
                _collateralERC20
            );
        }

        if (valuePerWNFT * _wNFTAddress.length < msg.value ){
            address payable s = payable(msg.sender);
            s.transfer(msg.value - valuePerWNFT * _wNFTAddress.length);
        }
    }

    ////////////////////////////////////////
    //     Admin functions               ///
    ////////////////////////////////////////
    function setTrustedWrapper(address _wrapper) public onlyOwner {
        trustedWrapper = ITrustedWrapper(_wrapper);
        require(trustedWrapper.trustedOperator() == address(this), "Only for exact wrapper");
    }

    function setSubscriptionManager(address _manager) external onlyOwner {
        _setSubscriptionManager(_manager);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity 0.8.16;

import "IWrapper.sol";

interface ITrustedWrapper is IWrapper  {

    function trustedOperator() external view returns(address);    
    
    function wrapUnsafe(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external
        payable
        returns (ETypes.AssetItem memory); 

    function transferIn(
        ETypes.AssetItem memory _assetItem,
        address _from
    ) 
        external
        payable  
    returns (uint256 _transferedValue);
   
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IWrapper  {

    event WrappedV1(
        address indexed inAssetAddress,
        address indexed outAssetAddress, 
        uint256 indexed inAssetTokenId, 
        uint256 outTokenId,
        address wnftFirstOwner,
        uint256 nativeCollateralAmount,
        bytes2  rules
    );

    event UnWrappedV1(
        address indexed wrappedAddress,
        address indexed originalAddress,
        uint256 indexed wrappedId, 
        uint256 originalTokenId, 
        address beneficiary, 
        uint256 nativeCollateralAmount,
        bytes2  rules 
    );

    event CollateralAdded(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint8   assetType,
        address collateralAddress,
        uint256 collateralTokenId,
        uint256 collateralBalance
    );

    event PartialUnWrapp(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint256 lastCollateralIndex
    );
    event SuspiciousFail(
        address indexed wrappedAddress,
        uint256 indexed wrappedId, 
        address indexed failedContractAddress
    );

    event EnvelopFee(
        address indexed receiver,
        address indexed wNFTConatract,
        uint256 indexed wNFTTokenId,
        uint256 amount
    );

    function wrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external 
        payable 
    returns (ETypes.AssetItem memory);

    // function wrapUnsafe(
    //     ETypes.INData calldata _inData, 
    //     ETypes.AssetItem[] calldata _collateral, 
    //     address _wrappFor
    // ) 
    //     external 
    //     payable
    // returns (ETypes.AssetItem memory);

    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) external payable;

    // function addCollateralUnsafe(
    //     address _wNFTAddress, 
    //     uint256 _wNFTTokenId, 
    //     ETypes.AssetItem[] calldata _collateral
    // ) 
    //     external 
    //     payable;

    function unWrap(
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) external;

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        external  
        returns (bool);   

    ////////////////////////////////////////////////////////////////////// 
    
    function MAX_COLLATERAL_SLOTS() external view returns (uint256);
    function protocolTechToken() external view returns (address);
    function protocolWhiteList() external view returns (address);
    //function trustedOperators(address _operator) external view returns (bool); 
    //function lastWNFTId(ETypes.AssetType _assetType) external view returns (ETypes.NFTItem); 

    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns (ETypes.WNFT memory);

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns(string memory); 
    
    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) external view returns (uint256, uint256);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.16;

library ETypes {

    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}
    
    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    struct AssetItem {
        Asset asset;
        uint256 tokenId;
        uint256 amount;
    }

    struct NFTItem {
        address contractAddress;
        uint256 tokenId;   
    }

    struct Fee {
        bytes1 feeType;
        uint256 param;
        address token; 
    }

    struct Lock {
        bytes1 lockType;
        uint256 param; 
    }

    struct Royalty {
        address beneficiary;
        uint16 percent;
    }

    struct WNFT {
        AssetItem inAsset;
        AssetItem[] collateral;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        bytes2 rules;

    }

    struct INData {
        AssetItem inAsset;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        AssetType outType;
        uint256 outBalance;      //0- for 721 and any amount for 1155
        bytes2 rules;

    }

    struct WhiteListItem {
        bool enabledForFee;
        bool enabledForCollateral;
        bool enabledRemoveFromCollateral;
        address transferFeeModel;
    }

    struct Rules {
        bytes2 onlythis;
        bytes2 disabled;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IERC20.sol";

interface IERC20Extended is  IERC20 {
     function mint(address _to, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Subscriber 
// abstract contract implements subscribing features.
// For use in cases with subscription

/// @title Subscriber abstract contract 
/// @author Envelop project Team
/// @notice Abstract contract implements subscribing features.
/// For use in cases with subscription
/// @dev Using _serviceCode param:
///       0 - simple saftNFT subscription       
///     100 - mint service                      
/// also we can think about _serviceCode as uniq code of  service (saft, mint etc)
/// !!! use Ownable pattern for `setSubscriptionManager`
pragma solidity 0.8.16;

import "ISubscriptionManager.sol";

abstract contract Subscriber {

	uint256 immutable public SERVICE_CODE;
	ISubscriptionManager public subscriptionManager;

	constructor(uint256 _code) {
		SERVICE_CODE = _code;
	}

	function _setSubscriptionManager(address _manager) internal {
        require(_manager != address(0),'Non zero only');
        subscriptionManager = ISubscriptionManager(_manager);
    }
    

    function _checkAndFixSubscription(address _user) 
        internal 
        returns (bool ok) 
    {
        if (address(subscriptionManager) != address(0)){
            ok = subscriptionManager.checkAndFixUserSubscription(
                _user,
                SERVICE_CODE  
            );
            return ok;
        }
    }

    function _fixUserSubscription(
        address _user, 
        uint256 _tariffIndex
    ) internal {
    	if (address(subscriptionManager) != address(0)){
            subscriptionManager.fixUserSubscription(
                _user,
                _tariffIndex  
            );
        }
    }

    function _checkUserSubscription(address _user) 
        internal 
        view 
        returns (bool ok)
    {
        if (address(subscriptionManager) != address(0)){
            ok = subscriptionManager.checkUserSubscription(
                _user,
                SERVICE_CODE  
            );
            return ok;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


interface ISubscriptionManager   {

    
    function checkUserSubscription(
        address _userer, 
        uint256 _serviceCode
    ) external view returns (bool);

    function checkAndFixUserSubscription(
        address _userer, 
        uint256 _serviceCode
    ) external returns (bool); 

    function fixUserSubscription(
        address _user, 
        uint256 _tariffIndex
    ) external;
}