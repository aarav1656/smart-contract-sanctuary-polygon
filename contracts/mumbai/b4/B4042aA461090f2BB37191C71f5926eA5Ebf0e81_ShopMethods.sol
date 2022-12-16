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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IViewDiscount {

    function viewDiscount(address requester) external view returns(uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract ShopMethods is Params {

    constructor(ShopConstructor.Struct memory input) Params(input) {}

    function calculateDiscount(
        address requester
    ) 
        external 
        whitelisted 
        returns(uint256) 
    {
        
        uint256 totalDiscount;

        for ( uint256 i = 1; i < id; ++i ) {

            // token type 1 is first to check to ensure the biggest discount will be applied
            // if user has a erc 1155 for discount
            if ( discounts[i].tokenType == 1 )
                for (uint j = 0; j < discounts[i].tokenIds.length ; ++j)
                    if ( ( totalDiscount > discounts[i].discount || totalDiscount == 1 ) && discounts[i].discount > 1 )
                        if ( ( discounts[i].dateStart <= block.timestamp && discounts[i].dateStop >= block.timestamp ) || ( discounts[i].dateStart == 0 && discounts[i].dateStop == 0 ) )
                            try IERC1155(discounts[i].tokenContract).balanceOf(requester,discounts[i].tokenIds[j]) returns (uint256 balanceOf) {
                                if ( balanceOf > 0 )
                                    if ( discounts[i].usable ) {
                                        IERC1155(discounts[i].tokenContract).safeTransferFrom(
                                            requester,
                                            control.discountsReceiverWallet,
                                            discounts[i].tokenIds[j],
                                            discounts[i].amountToUsePerUsableDiscount,
                                            '0x00'
                                        );
                                        totalDiscount = discounts[i].discount;
                                    } else {
                                        totalDiscount = discounts[i].discount;
                                    }
                            } catch (bytes memory) {
                                
                            }


            // if user has a geyser stake for discount
            if ( discounts[i].tokenType == 2 ) {
                if ( ( totalDiscount > discounts[i].discount || totalDiscount == 1 ) && discounts[i].discount > 1 ) {
                    if ( ( discounts[i].dateStart <= block.timestamp && discounts[i].dateStop >= block.timestamp ) || ( discounts[i].dateStart == 0 && discounts[i].dateStop == 0 ) ) {
                        try Geyser(discounts[i].tokenContract).totalStakedFor(requester) returns (uint256 totalStakedFor) {
                            if ( totalStakedFor > 0 ) {
                                totalDiscount = discounts[i].discount; 
                            }
                        } catch (bytes memory) {
                            
                        }
                    }
                }
            }


            if ( discounts[i].tokenType == 3 ) {
                if ( ( totalDiscount > discounts[i].discount || totalDiscount == 1 ) && discounts[i].discount > 1 ) {
                    if ( ( discounts[i].dateStart <= block.timestamp && discounts[i].dateStop >= block.timestamp ) || ( discounts[i].dateStart == 0 && discounts[i].dateStop == 0 ) ) {
                        try IERC20(discounts[i].tokenContract).balanceOf(requester) returns (uint256 balance) {
                            if ( balance > 0 ) {
                                if ( discounts[i].usable ) {
                                    IERC20(discounts[i].tokenContract).transferFrom(
                                        requester, 
                                        control.discountsReceiverWallet, 
                                        discounts[i].amountToUsePerUsableDiscount
                                    );
                                    totalDiscount = discounts[i].discount;
                                } else {
                                    totalDiscount = discounts[i].discount; 
                                }
                            }
                        } catch (bytes memory) {
                            
                        }
                    }
                }
            }

            // if user has a erc 721 for discount 
            if ( discounts[i].tokenType == 0 ) {
                for (uint j = 0; j < discounts[i].tokenIds.length ; ++j) {
                    if ( ( totalDiscount > discounts[i].discount || totalDiscount == 1 ) && discounts[i].discount > 1 ) {
                        if ( ( discounts[i].dateStart <= block.timestamp && discounts[i].dateStop >= block.timestamp ) || ( discounts[i].dateStart == 0 && discounts[i].dateStop == 0 ) ) {
                            try IERC721(discounts[i].tokenContract).ownerOf(discounts[i].tokenIds[j]) returns (address ownerOfToken) {
                                if ( ownerOfToken == requester ) {
                                    if ( discounts[i].usable ) {
                                        IERC721(discounts[i].tokenContract).safeTransferFrom(
                                            requester,
                                            control.discountsReceiverWallet,
                                            discounts[i].tokenIds[j]
                                        );
                                        totalDiscount = discounts[i].discount;
                                    } else {
                                        totalDiscount = discounts[i].discount;
                                    }
                                }
                            } catch (bytes memory) {
                                
                            }
                        }
                    }
                }
            }

        }

        return totalDiscount;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library ShopConstructor {
    
    struct Struct {
        address[] operators;
        address methods;
        address zerocost;
        address discounts;
        address restricted;
        address discountsReceiverWallet;
        bytes4[][] targets;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Discount {
    
    struct Struct {

        address tokenContract;

        uint256[] tokenIds;

        uint256 dateStart;

        uint256 dateStop;

        uint256 amountToUsePerUsableDiscount;

        uint32 discount;

        uint8 tokenType; // 0 - erc721 , 1 - erc1155 , 2 - geyser , 3 - erc20

        bool usable;

    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../whitelist/Index.sol';
import './Discount.sol';
import './Constructor.sol';
import '../interfaces/IViewDiscount.sol';
interface Geyser { function totalStakedFor(address addr) external view returns(uint256); }


contract Params is Whitelist {
    
    uint256 public id = 1;
    ShopConstructor.Struct public control;
    mapping(address => bool) allowed;
    mapping(uint256 => Discount.Struct) public discounts;
    event NewDiscount(uint256 indexed id, Discount.Struct discount);

    constructor(
        ShopConstructor.Struct memory input
    ) 
        Whitelist(input.operators, input.targets) 
    {
        control = input;
    }

    function totalDiscounts() external view returns(uint256) {
        return id;
    }

    function getDiscount(uint256 discountId) external view returns(Discount.Struct memory) {
        return discounts[discountId];
    }

    function setGlobalParameters(
        ShopConstructor.Struct memory globalParameters
    ) 
        external 
        onlyOwner 
    {
        control = globalParameters;
        updateWhitelist(globalParameters.operators, globalParameters.targets);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';


contract Whitelist is Ownable {

    mapping(address => bytes4[]) public whitelists;

    constructor(address[] memory operators, bytes4[][] memory targets) {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                whitelists[operators[i]].push(targets[i][j]);
            }
        }
    }

    function updateWhitelist(address[] memory operators, bytes4[][] memory targets) internal {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                if ( j >= whitelists[operators[i]].length ) {
                    whitelists[operators[i]].push(targets[i][j]);
                } else {
                    whitelists[operators[i]][j] = targets[i][j];
                }
            }
        }
    }

    modifier whitelisted() {
        bool found = false;
        for (uint256 i = 0; i < whitelists[msg.sender].length; ++i) {
            if ( whitelists[msg.sender][i] == msg.sig ) {
                found = true;
            }
        }
        require(found);
        _;
    }

}