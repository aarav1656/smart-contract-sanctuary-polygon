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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity 0.8.10;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title wav3shack
 * @author Daniel Beltrán for wav3s
 * @notice A contract to transfer rewards to profiles that mirror a publication
 * on Lens Protocol that the user previously fund with a budget.
 */

/**
 * @notice A struct containing the necessary data to execute funded mirror actions on a given profile and post.
 *
 * @param budget The total budget to pay mirrorers.
 * @param reward The amount to be paid to each mirrorer.
 * @param currencyAddress The currency associated with this post.
 * @param profileAddress The address associated with the profile owner of the publication.
 * @param frontendAddress The address associated with the frontend implementing wav3s.
 * @param minFollowers The minimum amount of followers a user has to have to receive a reward from this post.
 * @param feePerMirror Fee per mirror acording to this budget and reward.

 */
struct PostData {
    uint256 budget;
    uint256 reward;
    address currencyAddress;
    address profileAddress;
    address frontendAddress;
    uint256 minFollowers;
    uint256 feePerMirror;
}

contract wav3sMirror {
    // Address of the deployer.
    address public owner;
    // The address of the wav3s multisig contract.
    address private s_multisig;
    // The addresses of whitelisted currencies.
    address private immutable i_wMatic;
    /*address private immutable i_wEther;
    address private immutable i_USDCoin;
    address private immutable i_DAI;
    address private immutable i_Toucan;*/

    // The address of the wav3sHub contract.
    address private s_wav3sHub;
    // The fee that will be charged in percentage.
    uint256 immutable i_fee;
    // The minimum reward possible.
    uint256 immutable i_minReward;
    // SafeERC20 to transfer tokens.
    using SafeERC20 for IERC20;
    // Post variables
    // The budget for the post pointed to
    uint256 private budget;
    // The reward for the post pointed to
    uint256 private reward;
    // The currency address for the post pointed to
    address private currency;
    // The minimum followers for the post pointed to
    uint256 private minFollowers;
    // Mapping to store the data associated with a post, indexed by the publication ID
    mapping(string => PostData) dataByPublication;
    // Mapping to store whether a given follower has mirrored a given post or not
    mapping(string => mapping(address => bool)) s_publicationToFollowerHasMirrored;
    // Mapping to track fees
    mapping(address => mapping(address => uint256)) s_appToCurrencyToFees;

    constructor(
        uint256 fee,
        address wMatic /*address wEther,
        address USDCoin,
        address DAI,
        address Toucan*/
    ) {
        i_fee = fee;
        i_wMatic = wMatic;
        /*i_wEther = wEther;
        i_USDCoin = USDCoin;
        i_DAI = DAI;
        i_Toucan = Toucan;*/
        i_minReward = 1E17;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner can call this function.');
        _;
    }

    /**
     * @dev Processes a mirror action. This will transfer funds to the owner of the profile that initiated the mirror.
     * @param pubId The ID of the post that was mirrored.
     * @param mirrorerAddress The address of the follower who mirrored the post.
     * @param followersCount The number of followers that the mirrorer has.

     */
    function processMirror(
        string memory pubId,
        address mirrorerAddress,
        uint256 followersCount,
        address appAddress
    ) external {
        // Get the budget for the post pointed to
        budget = dataByPublication[pubId].budget;
        // Get the reward for the post pointed to
        reward = dataByPublication[pubId].reward;
        // Get the currency address for the post pointed to
        currency = dataByPublication[pubId].currencyAddress;
        // Get the minimum followers for the post pointed to
        minFollowers = dataByPublication[pubId].minFollowers;

        // Check if the mirrorer is the wallet owner
        if (msg.sender != s_wav3sHub) {
            revert('wav3sMirror__OnlyWav3sCanCallThis()');
        }

        // Check if the follower has already mirrored this post
        if (s_publicationToFollowerHasMirrored[pubId][mirrorerAddress]) {
            revert('wav3sMirror__FollowerAlreadyMirrored()');
        }

        // Check that there is enough budget to pay the reward
        if (reward > budget) {
            revert('wav3sMirror__NotEnoughPostBudget()');
        }
        // Check if the mirrorer has enough followers
        if (minFollowers > followersCount) {
            revert('wav3sMirror__NeedMoreFollowers()');
        }

        // Transfer the reward to the mirror creator
        IERC20(currency).safeTransferFrom(address(this), mirrorerAddress, reward);
        // Update Budget
        dataByPublication[pubId].budget -= reward;
        // Set the flag indicating that the follower has mirrored this profile
        s_publicationToFollowerHasMirrored[pubId][mirrorerAddress] = true;
        // Record the fee to the app
        s_appToCurrencyToFees[appAddress][currency] += dataByPublication[pubId].feePerMirror;
    }

    /**
     * @dev Funds a Super Reach post. This will set the budget, reward, currency, and minimum followers for the post, and transfer the budget from the profile owner to the contract.
     * @param _budget The budget for the post.
     * @param _reward The reward for each mirror of the post.
     * @param currencyAddress The address of the currency to use for the post.
     * @param pubId The ID of the post.
     * @param profileAddress The address of the profile that owns the post.
     * @param frontendAddress The address of the frontend contract.
     * @param _minFollowers The minimum number of followers required to mirror the post.
     */
    function fundMySuperReach(
        uint256 _budget,
        uint256 _reward,
        address currencyAddress,
        string memory pubId,
        address profileAddress,
        address frontendAddress,
        uint256 _minFollowers
    ) public {
        // Separate budget from fees.
        uint256 fees = (_budget / (100 + i_fee)) * i_fee;
        // Set the budget.
        dataByPublication[pubId].budget += _budget - fees;

        // Check: Only the owner of the profile can fund the super reach.
        if (msg.sender != profileAddress) {
            revert('wav3sMirror__SenderNotOwner()');
        }
        // Check: Budget for the publication must be higher than the minimum reward.
        if (_budget <= i_minReward) {
            revert('wav3sMirror__InvalidBudget()');
        }
        // Check: Reward for mirroring must be higher than the minimum permitted.
        if (_reward < i_minReward) {
            revert('wav3sMirror__RewardBelowMinimum()');
        }
        // Check: Reward can't be higher than the budget for the publication.
        if (_reward > dataByPublication[pubId].budget) {
            revert('wav3sMirror__NotEnoughBudgetForThatReward()');
        }
        // Check: Minimum followers must be 0 or higher.
        if (_minFollowers < 0) {
            revert('wav3sMirror__InvalidMinimumFollowers()');
        }
        // Check: Only accept whitelisted currencies.
        if (!currencyWhitelisted(currencyAddress)) {
            revert('wav3sMirror__CurrencyNotWhitelisted()');
        }
        // Set the reward, currency, currency address, profile address and minimum followers of this publication.
        dataByPublication[pubId].reward = _reward;
        dataByPublication[pubId].currencyAddress = currencyAddress;
        dataByPublication[pubId].profileAddress = profileAddress;
        dataByPublication[pubId].minFollowers = _minFollowers;
        dataByPublication[pubId].feePerMirror = ((fees / 3) * _budget) / _reward;

        // Transfer funds from the budget owner to wav3s contract
        IERC20(currencyAddress).safeTransferFrom(profileAddress, address(this), _budget);

        // Transfer 2% to the wav3s multisig and keep 1% to frontends.
        IERC20(currencyAddress).safeTransferFrom(address(this), s_multisig, ((fees * 2) / 3));

        // Transfer the other half of the fees to the frontend contract
        //IERC20(currencyAddress).safeTransferFrom(address(this), frontendAddress, (fees / 2));
    }

    /**
     * @dev Gets the budget for a publication.
     * @param pubId The ID of the publication.
     * @return The budget for the publication.
     */
    function getMirrorBudget(string memory pubId) public view returns (uint256) {
        // Fetch budget for this publication
        return dataByPublication[pubId].budget;
    }

    /**
     * @dev Sets the wav3s hub address. This can only be called by the contract owner.
     * @param wav3sHub The new wav3s hub address.
     */
    function setWav3sHub(address wav3sHub) public onlyOwner {
        s_wav3sHub = wav3sHub;
    }

    /**
     * @dev Sets the multisig address. This can only be called by the contract owner.
     * @param multisig The new multisig address.
     */
    function setMultisig(address multisig) public onlyOwner {
        s_multisig = multisig;
    }

    /**
     * @dev Withdraws funds from the budget of a post.
     * @param pubId The ID of the post.
     *  amount The amount to withdraw.
     */
    function withdrawMirrorBudget(string memory pubId /*, uint256 amount*/) public {
        // Check that the sender is the owner of the given profile
        if (dataByPublication[pubId].profileAddress != msg.sender) {
            // Revert with NotSenderProfile error if the sender is not the owner of the profile
            revert('wav3sMirror__NotSenderProfileToWithdraw()');
        }

        // Get the post budget and currency for the given post
        budget = dataByPublication[pubId].budget;
        currency = dataByPublication[pubId].currencyAddress;

        // Check that there is enough funds in the post budget to withdraw
        if (budget > 0) {
            // Revert with the NotEnoughBudget error if there are not enough funds in the post budget
            revert('wav3sMirror__NotEnoughBudgetToWithdraw()');
        } else {
            // Transfer the specified amount from the contract to the sender's address
            IERC20(currency).safeTransferFrom(address(this), msg.sender, budget);

            // Update the post budget for the given profile and post
            dataByPublication[pubId].budget = 0;
            dataByPublication[pubId].reward = 0;
            dataByPublication[pubId].feePerMirror = 0;
            dataByPublication[pubId].minFollowers = 0;
        }
    }

    function currencyWhitelisted(address _currency) private view returns (bool) {
        if (
            _currency ==
            i_wMatic /* ||
            _currency == i_wEther ||
            _currency == i_USDCoin ||
            _currency == i_DAI ||
            _currency == i_Toucan*/
        ) return true;
        else {
            return false;
        }
    }

    function payApps(address appAddress) external {
        // Check if the mirrorer is the wallet owner
        if (msg.sender != s_wav3sHub) {
            revert('wav3sMirror__OnlyWav3sCanCallThis()');
        }
        // Transfer the reward to the mirror creator
        IERC20(currency).safeTransferFrom(
            address(this),
            appAddress,
            s_appToCurrencyToFees[appAddress][i_wMatic]
        );
        s_appToCurrencyToFees[appAddress][i_wMatic] = 0;
    }

    function getAppFees(address appAddress, address currency) public view returns (uint256) {
        // Fetch budget for this publication
        return s_appToCurrencyToFees[appAddress][currency];
    }

    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}