// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INFTMarketPlace {
    // Struct

    struct Auction {
        address seller;
        address owner;
        uint256 initialPrice;
        address highestBidder;
        uint256 highestBid;
        uint256 closeTimestamp;
        uint256 tokenId;
        address nftContractAddress;
    }

    // Events

    event AuctionCreated(
        address seller,
        address owner,
        uint256 initialPrice,
        address highestBidder,
        uint256 highestBid,
        uint256 closeTimestamp,
        uint256 indexed tokenId,
        address nftContractAddress
    );

    event AuctionCancelled(
        address nftContractAddress,
        uint256 indexed tokenId,
        address seller
    );

    event AuctionFinished(
        address nftContractAddress,
        uint256 indexed tokenId,
        address finisher,
        address highestBidder,
        uint256 highestBid
    );

    event BidCreated(
        address bidder,
        uint256 bidPrice,
        uint256 indexed tokenId,
        address nftContractAddress
    );

    // Read-only functions

    function getAuctionDetails(
        address _nftContractAddress,
        uint256 _tokenId
    ) external view returns (Auction memory);

    // State-changing functions

    function listMyNFTToSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _auctionDuration
    ) external returns (bool);

    function bidForNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external payable returns (bool);

    function cancelAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) external payable returns (bool);

    function finishAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) external payable returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/INFTMarketPlace.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketPlaceTest is INFTMarketPlace, Ownable {
    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "NFTMarketPlace: zero address");
        _;
    }

    modifier nonZeroValue(uint _value) {
        require(_value > 0, "NFTMarketPlace: zero value");
        _;
    }

    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice                    Returns an auction details
    /// @param _nftContractAddress Address of NFT token contract
    /// @param _tokenId            A number that identify the NFT within the NFT token contract
    function getAuctionDetails(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
        override
        view
        nonZeroAddress(_nftContractAddress)
        returns (Auction memory)
    {
        Auction memory auctionItem = auctions[_nftContractAddress][_tokenId];
        return auctionItem;
    }

    /// @notice                     List NFT to auction List for sale
    /// @dev                        Call approve function of Nft Contract before the call this func
    /// @param _nftContractAddress  Address of NFT token contract
    /// @param _tokenId             A number that identify the NFT within the NFT token contract
    /// @param _initialPrice        The initial price value that can be bid on an action
    /// @param _auctionDuration     The period of time (timestamp) each user can bid on an action
    /// @return                     True if auction is added successfully
    function listMyNFTToSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _auctionDuration
    )
        external
        override
        nonZeroAddress(_nftContractAddress)
        nonZeroValue(_initialPrice)
        returns (bool)
    {
        IERC721(_nftContractAddress).transferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );

        Auction memory item;
        item.seller = _msgSender();
        item.owner = address(this);
        item.initialPrice = _initialPrice;
        item.closeTimestamp = block.timestamp + _auctionDuration;

        auctions[_nftContractAddress][_tokenId] = item;

        emit AuctionCreated(
            item.seller,
            item.owner,
            item.initialPrice,
            item.highestBidder,
            item.highestBid,
            item.closeTimestamp,
            item.tokenId,
            item.nftContractAddress
        );

        return true;
    }

    /// @notice                     Bid on an auction to get a NFT
    /// @dev                        Submit the asking price in order to complete the bid on ( msg value )
    /// @param _nftContractAddress  Address of NFT token contract
    /// @param _tokenId             A number that identify the NFT within the NFT token contract
    /// @param _bidPrice            The price that is bigger than the initial price and last bid price is on this action
    function bidForNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _bidPrice
    )
        external
        override
        payable
        nonZeroAddress(_nftContractAddress)
        nonZeroValue(_bidPrice)
        returns (bool)
    {
        Auction memory auctionItem = auctions[_nftContractAddress][_tokenId];

        require(
            block.timestamp < auctionItem.closeTimestamp,
            "auction is closed"
        );

        require(
            _bidPrice > auctionItem.highestBid &&
                _bidPrice >= auctionItem.initialPrice,
            "bid price is low"
        );

        require(
            msg.value == _bidPrice,
            "please submit the asking price in order to complete the bid, incompatible msg value"
        );

        if (auctionItem.highestBidder != address(0)) {
            Address.sendValue(
                payable(auctionItem.highestBidder),
                auctionItem.highestBid
            );
        }

        auctions[_nftContractAddress][_tokenId].highestBidder = _msgSender();
        auctions[_nftContractAddress][_tokenId].highestBid = _bidPrice;

        emit BidCreated(_msgSender(), _bidPrice, _tokenId, _nftContractAddress);

        return true;
    }

    /// @notice                    Cancel an auction
    /// @dev                       Only seller can cancel
    /// @param _nftContractAddress Address of NFT token contract
    /// @param _tokenId            A number that identify the NFT within the NFT token contract
    function cancelAuction(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
        override
        payable
        nonZeroAddress(_nftContractAddress)
        returns (bool success)
    {
        Auction memory auctionItem = auctions[_nftContractAddress][_tokenId];

        require(_msgSender() == auctionItem.seller, "only seller can cancel");

        require(
            block.timestamp < auctionItem.closeTimestamp,
            "auction is closed"
        );

        if (auctionItem.highestBidder != address(0)) {
            Address.sendValue(
                payable(auctionItem.highestBidder),
                auctionItem.highestBid
            );
        }
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            auctionItem.seller,
            _tokenId
        );

        emit AuctionCancelled(_nftContractAddress, _tokenId, _msgSender());

        delete auctions[_nftContractAddress][_tokenId];

        return true;
    }

    /// @notice                      Finish an auction
    /// @dev                         Only seller can cancel , Call this func after auction is closed
    /// @param _nftContractAddress   Address of NFT token contract
    /// @param _tokenId              A number that identify the NFT within the NFT token contract
    function finishAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) external override payable nonZeroAddress(_nftContractAddress) returns (bool) {
        Auction memory auctionItem = auctions[_nftContractAddress][_tokenId];

        require(
            block.timestamp > auctionItem.closeTimestamp,
            "auction is not closed yet"
        );

        if (auctionItem.highestBidder != address(0)) {
            Address.sendValue(
                payable(auctionItem.seller),
                auctionItem.highestBid
            );

            //TODO update fee management

            // Address.sendValue(
            //     payable(auctionItem.seller),
            //     (auctionItem.highestBid * 99) / 100
            // );
            // Address.sendValue(payable(owner()), auctionItem.highestBid / 100);

            IERC721(_nftContractAddress).transferFrom(
                address(this),
                auctionItem.highestBidder,
                _tokenId
            );
        } else {
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                auctionItem.seller,
                _tokenId
            );
        }

        emit AuctionFinished(
            _nftContractAddress,
            _tokenId,
            _msgSender(),
            auctionItem.highestBidder,
            auctionItem.highestBid
        );

        delete auctions[_nftContractAddress][_tokenId];

        return true;
    }
}