/**
 *Submitted for verification at polygonscan.com on 2023-01-26
*/

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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
interface IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: Lensdrop/Lensdrop.sol


pragma solidity ^0.8.7;




contract Lensdrop {
    struct EscrowDetails {
        address user;
        address token;
        uint256[] tokenIds;
        bool paid;
        string rewardDetails;
        uint256 amount;
        uint256 noOfRecipients;
        uint256 deadline;
    }
    mapping(uint256 => EscrowDetails) public Escrows;
    mapping(address => uint256[]) Users;
    uint256 public totalEscrows;
    address payable public controller;
    bool initialized;

    receive() external payable {}

    event AdDetails(uint256 indexed postId, string rewardDetails, uint256 deadline, uint256 noOfRecipients, uint256 fee);

    function batchSendERC20(address[] memory recipients, uint256 amount, address tokenAddress) 
        public payable {
            uint256 fee = (recipients.length * 1 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            }
            require(msg.value == fee, "service fee unpaid");
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);

            for (uint256 i=0; i<recipients.length; i++) {
               token.transferFrom(msg.sender, recipients[i], amount);
            }

            controller.transfer(fee);
    }

    function batchSendERC721(address tokenAddress, address[] memory recipients, uint256[] memory tokenIds)
        public payable {
            uint256 fee = (recipients.length * 1 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            }
            require(msg.value == fee, "service fee unpaid");
            require(recipients.length == tokenIds.length, "number of recipients and token ids do not match");
            IERC721Upgradeable token = IERC721Upgradeable(tokenAddress);

            for (uint256 i=0; i<recipients.length; i++) {
                token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
            }

            controller.transfer(fee);
    }

    function batchSendERC1155(address tokenAddress, address[] memory recipients, uint256[] memory tokenIds)
        public payable {
            uint256 fee = (recipients.length * 1 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            }
            require(msg.value == fee, "service fee unpaid");
            require(recipients.length == tokenIds.length, "number of recipients and token ids do not match");
            IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);

            for (uint256 i=0; i<recipients.length; i++) {
                token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], 1, "");
            }

            controller.transfer(fee);
    }

    modifier nativeHelper (address[] memory recipients, uint256 amount) {    
        uint256 fee = (recipients.length * 1 ether)/100;
        if (fee > 1 ether) {
            fee = 1 ether;
        } 
        uint256 totalAmount = fee + (recipients.length * amount);
        require(msg.value >= totalAmount, "insufficient token");

        if (msg.value > totalAmount) {
            payable(msg.sender).transfer(msg.value - totalAmount);
        }
        controller.transfer(fee);
        _;
    }

    function batchSendNativeToken(address[] memory recipients, uint256 amount) payable
        nativeHelper(recipients, amount) public {
            for (uint256 i=0; i<recipients.length; i++) {
                payable(recipients[i]).transfer(amount);
            }   
    }

    function escrowTokens(address payable referrer, string memory rewardDetails, uint256 amount, uint256 noOfRecipients, uint256 deadline) 
        public payable {   
            require(deadline >= block.timestamp, "deadline needs to be in the future"); 
            uint256 fee = (noOfRecipients * 2 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            } 
            require(msg.value >= fee + (amount * noOfRecipients), "insufficient token");
            uint256 referrerFee = (10*fee)/100;
            fee = fee - referrerFee;

            uint256 postId = totalEscrows;
            Escrows[postId].user = msg.sender;
            Escrows[postId].rewardDetails = rewardDetails;
            Escrows[postId].amount = amount;
            Escrows[postId].noOfRecipients = noOfRecipients;
            Escrows[postId].deadline = deadline;

            Users[msg.sender].push(postId);
            totalEscrows++;

            controller.transfer(fee);
            referrer.transfer(referrerFee);
            
            emit AdDetails(postId, rewardDetails, deadline, noOfRecipients, fee);
    }

    function escrowErc20Tokens(address payable referrer, string memory rewardDetails, address tokenAddress, uint256 amount, uint256 noOfRecipients, uint256 deadline) 
        public payable {    
            require(deadline >= block.timestamp, "deadline needs to be in the future"); 
            uint256 fee = (noOfRecipients * 2 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            } 
            require(msg.value >= fee);
            uint256 referrerFee = (10*fee)/100;
            fee = fee - referrerFee;

            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
            token.transferFrom(msg.sender, address(this), amount * noOfRecipients);

            uint256 postId = totalEscrows;
            Escrows[postId].user = msg.sender;
            Escrows[postId].rewardDetails = rewardDetails;
            Escrows[postId].token = tokenAddress;
            Escrows[postId].amount = amount;
            Escrows[postId].noOfRecipients = noOfRecipients;
            Escrows[postId].deadline = deadline;

            Users[msg.sender].push(postId);
            totalEscrows++;

            controller.transfer(fee);
            referrer.transfer(referrerFee);

            emit AdDetails(postId, rewardDetails, deadline, noOfRecipients, fee);
    }

    function escrowErc721Tokens(address payable referrer, string memory rewardDetails, address tokenAddress, uint256[] memory tokenIds, uint256 noOfRecipients, uint256 deadline) 
        public payable {   
            require(deadline >= block.timestamp, "deadline needs to be in the future"); 
            require(tokenIds.length == noOfRecipients); 
            uint256 fee = (noOfRecipients * 2 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            } 
            require(msg.value >= fee);
            uint256 referrerFee = (10*fee)/100;
            fee = fee - referrerFee;

            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
            for (uint i = 0; i < tokenIds.length; i++) {
                token.transferFrom(msg.sender, address(this), tokenIds[i]);
            }

            uint256 postId = totalEscrows;
            Escrows[postId].user = msg.sender;
            Escrows[postId].rewardDetails = rewardDetails;
            Escrows[postId].token = tokenAddress;
            Escrows[postId].tokenIds = tokenIds;
            Escrows[postId].noOfRecipients = noOfRecipients;
            Escrows[postId].deadline = deadline;

            Users[msg.sender].push(postId);
            totalEscrows++;

            controller.transfer(fee);
            referrer.transfer(referrerFee);
            
            emit AdDetails(postId, rewardDetails, deadline, noOfRecipients, fee);
    }

   function escrowErc1155Tokens(address payable referrer, string memory rewardDetails, address tokenAddress, uint256[] memory tokenIds, uint256 noOfRecipients, uint256 deadline) 
        public payable {   
            require(deadline >= block.timestamp, "deadline needs to be in the future"); 
            require(tokenIds.length == noOfRecipients);    
            uint256 fee = (noOfRecipients * 2 ether)/100;
            if (fee > 1 ether) {
                fee = 1 ether;
            } 
            require(msg.value >= fee);
            uint256 referrerFee = (10*fee)/100;
            fee = fee - referrerFee;

            IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);
            for (uint i = 0; i < tokenIds.length; i++) {
                token.safeTransferFrom(msg.sender, address(this), tokenIds[i], 1, "");
            }

            uint256 postId = totalEscrows;
            Escrows[postId].user = msg.sender;
            Escrows[postId].rewardDetails = rewardDetails;
            Escrows[postId].token = tokenAddress;
            Escrows[postId].tokenIds = tokenIds;
            Escrows[postId].noOfRecipients = noOfRecipients;
            Escrows[postId].deadline = deadline;

            Users[msg.sender].push(postId);
            totalEscrows++;

            controller.transfer(fee);
            referrer.transfer(referrerFee);
            
            emit AdDetails(postId, rewardDetails, deadline, noOfRecipients, fee);
    }

    function reward(uint256 postId, address[] memory recipients) public {
        require(msg.sender == controller, "only controller can reward users");
        require(Escrows[postId].paid = false, "reward already paid");
        require(recipients.length <= Escrows[postId].noOfRecipients);
        require(Escrows[postId].deadline >= block.timestamp, "Contest still ongoing");
        for (uint256 i=0; i<recipients.length; i++) {
            payable(recipients[i]).transfer(Escrows[postId].amount);
        }
        if (recipients.length < Escrows[postId].noOfRecipients) {
            uint256 balance = Escrows[postId].amount * (Escrows[postId].noOfRecipients - recipients.length);
            payable(Escrows[postId].user).transfer(balance);
        }
        Escrows[postId].paid = true;
    }

    function rewardTokens(uint256 postId, address[] memory recipients) public {
        require(msg.sender == controller, "only controller can reward users");
        require(Escrows[postId].paid = false, "reward already paid");
        require(recipients.length <= Escrows[postId].noOfRecipients);
        require(Escrows[postId].deadline >= block.timestamp, "Contest still ongoing");

        IERC20Upgradeable token = IERC20Upgradeable(Escrows[postId].token);
        for (uint256 i=0; i<recipients.length; i++) {
            token.transferFrom(address(this), recipients[i], Escrows[postId].amount);
        }
        if (recipients.length < Escrows[postId].noOfRecipients) {
            uint256 balance = Escrows[postId].amount * (Escrows[postId].noOfRecipients - recipients.length);
            token.transferFrom(address(this), Escrows[postId].user, balance);
        }
        Escrows[postId].paid = true;
    }

    function rewardErc721Tokens(uint256 postId, address[] memory recipients) public {
        require(msg.sender == controller, "only controller can reward users");
        require(Escrows[postId].paid = false, "reward already paid");
        require(recipients.length <= Escrows[postId].noOfRecipients);
        require(Escrows[postId].deadline >= block.timestamp, "Contest still ongoing");

        IERC721Upgradeable token = IERC721Upgradeable(Escrows[postId].token);
        for (uint256 i=0; i<recipients.length; i++) {
            token.transferFrom(address(this), recipients[i], Escrows[postId].tokenIds[i]);
        }
        if (recipients.length < Escrows[postId].noOfRecipients) {
            uint256 balance = (Escrows[postId].noOfRecipients - recipients.length);
            for (uint256 i=0; i<balance; i++) {
                token.transferFrom(address(this), Escrows[postId].user, Escrows[postId].tokenIds[i]);
            }
        }
        Escrows[postId].paid = true;
    }

     function rewardErc1155Tokens(uint256 postId, address[] memory recipients) public {
        require(msg.sender == controller, "only controller can reward users");
        require(Escrows[postId].paid = false, "reward already paid");
        require(recipients.length <= Escrows[postId].noOfRecipients);
        require(Escrows[postId].deadline >= block.timestamp, "Contest still ongoing");

        IERC1155Upgradeable token = IERC1155Upgradeable(Escrows[postId].token);
        for (uint256 i=0; i<recipients.length; i++) {
            token.safeTransferFrom(address(this), recipients[i], Escrows[postId].tokenIds[i], 1, "");
        }
        if (recipients.length < Escrows[postId].noOfRecipients) {
            uint256 balance = (Escrows[postId].noOfRecipients - recipients.length);
            for (uint256 i=0; i<balance; i++) {
                token.safeTransferFrom(address(this), Escrows[postId].user, Escrows[postId].tokenIds[i], 1, "");
            }
        }
        Escrows[postId].paid = true;
    }

    function initialize(address payable _controller) public {
        require(!initialized);
        controller = _controller;
        initialized = true;
    }

    function getUserAds(address user) public view returns (uint256[] memory) {
        return Users[user];
    }
}