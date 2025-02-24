// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Authoriser.sol";
import "./INftAuthoriser.sol";

contract NftAuthoriser is INftAuthoriser, Authoriser {

    event NftRoleEdited(address indexed owner, address indexed _token, uint indexed _tokenId, uint8 _roleId, address[] _targets, address[] _filters);
    event NftRolesGranted(address indexed owner, address indexed _token, uint indexed _tokenId, uint8 _roleId, address[] _delegates);
    event NftRolesRevoked(address indexed owner, address indexed _token, uint indexed _tokenId, uint8 _roleId, address[] _delegates);

    function editNftRole(bool _anyOwner, address _token, uint _tokenId, uint8 _roleId, address[] calldata _targets, address[] calldata _filters) external {
        require(_targets.length == _filters.length, "_targets and _filters length mismatch");
        require(isAuthorisedForToken(_token, _tokenId, msg.sender, THIS, msg.data), "Unauthorised to edit NFT role");
        address owner = _anyOwner ? ANY : IERC721(_token).ownerOf(_tokenId);
        _editRole(getVirtualDelegator(owner, _token, _tokenId), _roleId, _targets, _filters);
        emit NftRoleEdited(owner, _token, _tokenId, _roleId, _targets, _filters);
    }

    function grantNftRoles(bool _anyOwner, address _token, uint _tokenId, uint8 _roleId, address[] calldata _delegates) external {
        require(isAuthorisedForToken(_token, _tokenId, msg.sender, THIS, msg.data), "Unauthorised to grant NFT role");
        address owner = _anyOwner ? ANY : IERC721(_token).ownerOf(_tokenId);
        _grantRoles(getVirtualDelegator(owner, _token, _tokenId), _roleId, _delegates);
        emit NftRolesGranted(owner, _token, _tokenId, _roleId, _delegates);
    }

    function revokeNftRoles(bool _anyOwner, address _token, uint _tokenId, uint8 _roleId, address[] calldata _delegates) external {
        require(isAuthorisedForToken(_token, _tokenId, msg.sender, THIS, msg.data), "Unauthorised to revoke NFT role");
        address owner = _anyOwner ? ANY : IERC721(_token).ownerOf(_tokenId);
        _revokeRoles(getVirtualDelegator(owner, _token, _tokenId), _roleId, _delegates);
        emit NftRolesRevoked(owner, _token, _tokenId, _roleId, _delegates);
    }

    function isAuthorisedForToken(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) public override view returns (bool authorised) {
        // check if _delegate has generic authorisation for this tokenId, regardless of who is the tokenId owner
        if(isAuthorised(getVirtualDelegator(ANY, _token, _tokenId), _delegate, _to, _data)) {
            return true;
        }
        // check if _delegate has specific authorisation for this tokenId granted for the current tokenId owner
        return isAuthorisedForTokenAndCurrentOwner(_token, _tokenId, _delegate, _to, _data);
    }

    function isAuthorisedForTokenAndCurrentOwner(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) public override view returns (bool authorised) {
        address owner = IERC721(_token).ownerOf(_tokenId);
        // check if _delegate has specific authorisation for this tokenId granted for the current tokenId owner
        if(isAuthorised(getVirtualDelegator(owner, _token, _tokenId), _delegate, _to, _data)) {
            return true;
        }
        // check if _delegate is a delegate of owner
        return isAuthorised(owner, _delegate, _to, _data);
    }

    function getVirtualDelegator(address _owner, address _token, uint _tokenId) public pure returns (address delegator) {
        return address(uint160(uint(keccak256(abi.encode(_owner, _token, _tokenId)))));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./IAuthoriser.sol";

interface INftAuthoriser is IAuthoriser {
    function isAuthorisedForToken(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
    function isAuthorisedForTokenAndCurrentOwner(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IFilter {
    function isAuthorised(address _delegator, address _delegate, uint8 _roleId, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IAuthoriser {
    function isAuthorised(address _delegator, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/MultiCall.sol";
import "./IAuthoriser.sol";
import "./IFilter.sol";

contract Authoriser is IAuthoriser, Multicall {

    address constant internal ANY = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address immutable internal THIS = address(this);

    mapping(address => mapping(uint8 => mapping(address => address))) public filters; // [delegator][role][to] => filter
    mapping(address => mapping(address => bytes32)) public roles; // [delegator][delegate] => roles

    event RoleEdited(address indexed _delegator, uint8 indexed _roleId, address indexed _target, address _filter);
    event RoleGranted(address indexed _delegator, uint8 indexed _roleId, address indexed _delegate);
    event RoleRevoked(address indexed _delegator, uint8 indexed _roleId, address indexed _delegate);

    function editRole(address _delegator, uint8 _roleId, address[] calldata _targets, address[] calldata _filters) public {
        require(isAuthorised(_delegator, msg.sender, THIS, msg.data), "Unauthorised to edit role");
        require(_targets.length == _filters.length, "_targets and _filters length mismatch");
        _editRole(_delegator, _roleId, _targets, _filters);
    }

    function grantRoles(address _delegator, uint8 _roleId, address[] calldata _delegates) public {
        require(isAuthorised(_delegator, msg.sender, THIS, msg.data), "Unauthorised to grant role");
        _grantRoles(_delegator, _roleId, _delegates);
    }

    function revokeRoles(address _delegator, uint8 _roleId, address[] calldata _delegates) public {
        require(isAuthorised(_delegator, msg.sender, THIS, msg.data), "Unauthorised to revoke role");
        _revokeRoles(_delegator, _roleId, _delegates);
    }

    function isAuthorised(address _delegator, address _delegate, address _to, bytes calldata _data) public override view returns (bool authorised) {
        if(_delegator == _delegate) {
            return true;
        }
        uint delegateRoles = uint(roles[_delegator][_delegate]);
        for(uint8 roleId = 0; (delegateRoles >> roleId) > 0; roleId++) {
            if(((delegateRoles >> roleId) & 1) > 0) {
                if(canRoleDo(_delegator, _delegate, roleId, _to, _data)) {
                    return true;
                }
            }
        }
    }

    function canRoleDo(address _delegator, address _delegate, uint8 _roleId, address _to, bytes calldata _data) public view returns (bool authorised) {
        address filter = filters[_delegator][_roleId][_to];
        if(filter == ANY) {
            return true;
        }
        return (filter != address(0) && IFilter(filter).isAuthorised(_delegator, _delegate, _roleId, _to, _data));
    }

    function _editRole(address _delegator, uint8 _roleId, address[] calldata _targets, address[] calldata _filters) internal {
        for(uint i = 0; i < _targets.length; i++) {
            filters[_delegator][_roleId][_targets[i]] = _filters[i];
            emit RoleEdited(_delegator, _roleId, _targets[i], _filters[i]);
        }
    }

    function _grantRoles(address _delegator, uint8 _roleId, address[] calldata _delegates) internal {
        for(uint i = 0; i < _delegates.length; i++) {
            roles[_delegator][_delegates[i]] |= bytes32(uint(1) << _roleId);
            emit RoleGranted(_delegator, _roleId, _delegates[i]);
        }
    }

    function _revokeRoles(address _delegator, uint8 _roleId, address[] calldata _delegates) internal {
        for(uint i = 0; i < _delegates.length; i++) {
            roles[_delegator][_delegates[i]] &= ~bytes32(uint(1) << _roleId);
            emit RoleRevoked(_delegator, _roleId, _delegates[i]);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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