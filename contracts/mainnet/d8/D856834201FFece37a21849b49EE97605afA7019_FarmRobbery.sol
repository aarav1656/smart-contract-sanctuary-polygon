// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface CrowChest {
    function mint(uint256 _tokenId, address _to) external;
}

interface CrowOracle {
    function getRank(uint256 _tokenId) external view returns (string memory);

    function setStrike(uint256 _tokenId) external;

    function getStrikes(uint256 _tokenId) external view returns (uint256);
}

contract FarmRobbery is Ownable {
    address public oracleAddress;
    address public crowsAddress;
    address public chestAddress;
    uint256 public questTime = 60;
    uint256 public smallPotionLimit = 5000;
    uint256 public mediumPotionLimit = 2500;
    uint256 public branchesLimit = 27000;
    uint256 public smallPotionCounter;
    uint256 public mediumPotionCounter;
    uint256 public branchesCounter;
    mapping(uint256 => bool) public isQuesting;
    mapping(uint256 => uint256) private startTime;

    constructor(
        address _oracle,
        address _crows,
        address _chest
    ) {
        oracleAddress = _oracle;
        crowsAddress = _crows;
        chestAddress = _chest;
    }

    function startQuest(uint256 _tokenId) public {
        require(
            IERC721(crowsAddress).ownerOf(_tokenId) == msg.sender,
            "not an owner"
        );
        require(!isQuesting[_tokenId], "already questing");
        // TODO: change to 5
        require(
            CrowOracle(oracleAddress).getStrikes(_tokenId) < 3,
            "too many strikes"
        );
        isQuesting[_tokenId] = true;
        startTime[_tokenId] = block.timestamp;
    }

    function finishQuest(uint256 _tokenId) public {
        require(
            IERC721(crowsAddress).ownerOf(_tokenId) == msg.sender,
            "not an owner"
        );
        require(isQuesting[_tokenId], "not questing");
        require(
            block.timestamp - questTime >= startTime[_tokenId],
            "still questing"
        );
        uint256 outcome = calculateOutcome(_tokenId);
        isQuesting[_tokenId] = false;
        if (outcome <= 2) {
            if (outcome == 0) {
                require(smallPotionCounter < smallPotionLimit, "limit reached");
                CrowChest(chestAddress).mint(outcome, msg.sender);
                smallPotionCounter++;
            } else if (outcome == 1) {
                require(
                    mediumPotionCounter < mediumPotionLimit,
                    "limit reached"
                );
                CrowChest(chestAddress).mint(outcome, msg.sender);
                mediumPotionCounter++;
            } else {
                require(branchesCounter < branchesLimit, "limit reached");
                CrowChest(chestAddress).mint(outcome, msg.sender);
                branchesCounter++;
            }
        } else if (outcome == 3) {
            CrowOracle(oracleAddress).setStrike(_tokenId);
        }
    }

    function calculateOutcome(uint256 _tokenId)
        public
        view
        returns (uint256 itemId)
    {
        string memory rank = CrowOracle(oracleAddress).getRank(_tokenId);
        uint256 randomNumber = random();
        if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Chick"))
        ) {
            if (randomNumber <= 40) {
                return 4;
            } else if (randomNumber <= 70) {
                return 2;
            } else if (randomNumber <= 85) {
                return 3;
            } else if (randomNumber <= 95) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Apprentice"))
        ) {
            if (randomNumber <= 37) {
                return 4;
            } else if (randomNumber <= 70) {
                return 2;
            } else if (randomNumber <= 85) {
                return 3;
            } else if (randomNumber <= 95) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Artisan"))
        ) {
            if (randomNumber <= 34) {
                return 4;
            } else if (randomNumber <= 70) {
                return 2;
            } else if (randomNumber <= 85) {
                return 3;
            } else if (randomNumber <= 95) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Master"))
        ) {
            if (randomNumber <= 30) {
                return 4;
            } else if (randomNumber <= 69) {
                return 2;
            } else if (randomNumber <= 84) {
                return 3;
            } else if (randomNumber <= 95) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Lord"))
        ) {
            if (randomNumber <= 27) {
                return 4;
            } else if (randomNumber <= 67) {
                return 2;
            } else if (randomNumber <= 82) {
                return 3;
            } else if (randomNumber <= 94) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Scholar"))
        ) {
            if (randomNumber <= 26) {
                return 4;
            } else if (randomNumber <= 67) {
                return 2;
            } else if (randomNumber <= 81) {
                return 3;
            } else if (randomNumber <= 94) {
                return 0;
            } else {
                return 1;
            }
        } else if (
            keccak256(abi.encodePacked(rank)) ==
            keccak256(abi.encodePacked("Ruler"))
        ) {
            if (randomNumber <= 24) {
                return 4;
            } else if (randomNumber <= 66) {
                return 2;
            } else if (randomNumber <= 80) {
                return 3;
            } else if (randomNumber <= 93) {
                return 0;
            } else {
                return 1;
            }
        }
    }

    // utils

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % 100;
    }

    // setters

    function setOracle(address _address) public onlyOwner {
        oracleAddress = _address;
    }

    function setCrows(address _address) public onlyOwner {
        crowsAddress = _address;
    }

    function setQuestTime(uint256 _time) public onlyOwner {
        questTime = _time;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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