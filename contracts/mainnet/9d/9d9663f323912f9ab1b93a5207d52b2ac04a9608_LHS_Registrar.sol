/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

/*
 _        _______  _______ _________            _______  _______  _______ 
( \      (  ___  )(  ____ \\__   __/  |\     /|(  ___  )(  ____ )(  ____ \
| (      | (   ) || (    \/   ) (     | )   ( || (   ) || (    )|| (    \/
| |      | |   | || (_____    | |     | (___) || |   | || (____)|| (__    
| |      | |   | |(_____  )   | |     |  ___  || |   | ||  _____)|  __)   
| |      | |   | |      ) |   | |     | (   ) || |   | || (      | (      
| (____/\| (___) |/\____) |   | |     | )   ( || (___) || )      | (____/\
(_______/(_______)\_______)   )_(     |/     \|(_______)|/       (_______/
                                                                          
     _______  _______  _______ _________ _______ _________                
     (  ____ \(  ___  )(  ____ \\__   __/(  ____ \\__   __/|\     /|       
     | (    \/| (   ) || (    \/   ) (   | (    \/   ) (   ( \   / )       
     | (_____ | |   | || |         | |   | (__       | |    \ (_) /        
     (_____  )| |   | || |         | |   |  __)      | |     \   /         
           ) || |   | || |         | |   | (         | |      ) (          
     /\____) || (___) || (____/\___) (___| (____/\   | |      | |          
     \_______)(_______)(_______/\_______/(_______/   )_(      \_/   

       ____                                      _ _         
      / ___|___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ 
     | |   / _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | |
     | |__| (_) | | | | | | | | | | | |_| | | | | | |_| |_| |
      \____\___/|_| |_| |_|_|_|_| |_|\__,_|_| |_|_|\__|\__, |
             ____                                       |___/
            |  _ \ ___  __ _(_)___| |_ _ __ __ _ _ __   
            | |_) / _ \/ _` | / __| __| '__/ _` | '__|       
            |  _ <  __/ (_| | \__ \ |_| | | (_| | |          
            |_| \_\___|\__, |_|___/\__|_|  \__,_|_|          
                       |___/                                                                                  
                                                        
                          by 0xPioneers                                                           
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface for ERC20Recyclable - Recyclable Token Protocol.
 */
interface IERC20Recyclable {
    function mint(address account, uint256 amount) external returns (bool);
}

/**
 * @dev Community Registrar Protocol
 * 
 * - Individual Account Registration
 * - Partner Collection Registration
 *
 * - Everyone registered is whitelisted for project mints.
 * - Everyone registered can claim an initial token release.
 * 
 */
contract CommunityRegistrar is Ownable {

    mapping(address => bool) public registered;
    address[] public registered721;
    
    IERC20Recyclable public immutable token;
    uint256 public claimAmount;
    mapping(address => bool) public hasClaimed;

    bool private reentrancyLock = false;
    modifier nonreentrant {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier onlyEOA {
        require(_msgSender() == tx.origin, "CommunityRegistrar: EOA only.");
        _;
    }

    constructor(
        address _token,
        uint256 _claim
    ) {
        token = IERC20Recyclable(_token);
        claimAmount = _claim;
    }

    /**
     * @dev Set `amount` of token claim.
     * - Requires Owner Account
     */
    function setClaimAmount(
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "CommunityRegistrar: Invalid amount.");
        claimAmount = amount;
    }

    /**
     * @dev Register `account`.
     * - Requires Owner Account
     */
    function registerAccount(
        address account
    ) external onlyOwner {
        require(account != address(0), "CommunityRegistrar: Invalid account.");
        registered[account] = true;
    }

    /**
     * @dev Register an array of `accounts`.
     * - Requires Owner Account
     */
    function registerAccounts(
        address[] memory accounts
    ) external onlyOwner {
        require(accounts.length > 0, "CommunityRegistrar: Invalid accounts list.");
        uint16 index;
        address account;
        while (index < accounts.length) {
            account = accounts[index];
            if (account != address(0) && !registered[account]) {
                registered[account] = true;
            }
            index++;
        }
    }

    /**
     * @dev Register an array of 721 `collections` by contract address.
     * - Requires Owner Account
     */
    function registerCollections(
        address[] memory collections
    ) external onlyOwner {
        require(collections.length > 0, "CommunityRegistrar: Invalid collections list.");
        registered721 = collections;
    }

    /**
     * @dev Claim tokens for sender account.
     * - Requires EOA, once per registered account.
     */
    function claim(
    ) external nonreentrant onlyEOA {
        require(isRegistered(_msgSender()), "CommunityRegistrar: Account not registered.");
        require(!hasClaimed[_msgSender()], "CommunityRegistrar: Account already claimed.");

        token.mint(_msgSender(), claimAmount);
        hasClaimed[_msgSender()] = true;
    }

    /**
     * @dev Check if `account` is registered.
     * - Either by registered account, or by ownership in registered collection.
     */
    function isRegistered(
        address account
    ) public view returns (bool) {
        if (registered[account]) {
            return true;
        }
        uint8 collection;
        while (collection < registered721.length) {
            if (IERC721(registered721[collection]).balanceOf(account) > 0) {
                return true;
            }
            collection++;
        }
        return false;
    }

}

/**
 * @dev Lost Hope Society Community Registrar
 */
contract LHS_Registrar is CommunityRegistrar {
    constructor() CommunityRegistrar(
        0xC15B6939E9941B3E6a9bE9Be172B4456878B7a62,
        420 ether
    ) {}
}