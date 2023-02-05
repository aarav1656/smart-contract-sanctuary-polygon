// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {utils} from "./lib/utils.sol";
import {choice} from "./lib/choice.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

// ------------- errors

error NotActive();
error NoSupplyLeft();
error InvalidOrder();
error NotAuthorized();
error InvalidSigner();
error InvalidReceiver();
error DeadlineExpired();
error InvalidEthAmount();
error InsufficientValue();
error InvalidPaymentToken();
error MaxPurchasesReached();
error InvalidMarketItemHash();
error ContractCallNotAllowed();
error RandomSeedAlreadyChosen();
//       ___           ___           ___                    _____
//      /  /\         /  /\         /  /\       ___        /  /::\
//     /  /:/        /  /::\       /  /:/_     /__/\      /  /:/\:\
//    /  /:/        /  /:/\:\     /  /:/ /\    \  \:\    /  /:/  \:\
//   /  /:/  ___   /  /::\ \:\   /  /:/ /:/     \__\:\  /__/:/ \__\:|
//  /__/:/  /  /\ /__/:/\:\_\:\ /__/:/ /:/      /  /::\ \  \:\ /  /:/
//  \  \:\ /  /:/ \__\/~|::\/:/ \  \:\/:/      /  /:/\:\ \  \:\  /:/
//   \  \:\  /:/     |  |:|::/   \  \::/      /  /:/__\/  \  \:\/:/
//    \  \:\/:/      |  |:|\/     \  \:\     /__/:/        \  \::/
//     \  \::/       |__|:|        \  \:\    \__\/          \__\/
//      \__\/         \__\|         \__\/

/// @title CRFTDMarketplace
/// @author phaze (https://github.com/0xPhaze)
/// @notice Marketplace that supports purchasing limited off-chain items
contract CRFTDMarketplace is Owned(msg.sender) {
    using SafeTransferLib for ERC20;

    uint256 immutable INITIAL_CHAIN_ID;
    bytes32 immutable INITIAL_DOMAIN_SEPARATOR;
    bytes32 immutable MARKET_ORDER_TYPE_HASH;

    /* ------------- events ------------- */

    event MarketItemPurchased(
        uint256 indexed marketId,
        bytes32 indexed itemHash,
        address indexed account,
        bytes32 buyerHash,
        address paymentToken,
        uint256 price
    );

    /* ------------- structs ------------- */

    struct ERC20Permit {
        ERC20 token;
        address owner;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MarketOrderPermit {
        address buyer;
        bytes32[] itemHashes;
        address[] paymentTokens;
        bytes32 buyerHash;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MarketItem {
        uint256 marketId;
        uint256 start;
        uint256 end;
        uint256 expiry;
        uint256 maxPurchases;
        uint256 maxSupply;
        uint256 raffleNumPrizes;
        address[] raffleControllers;
        address receiver;
        bytes32 dataHash;
        address[] acceptedPaymentTokens;
        uint256[] tokenPricesStart;
        uint256[] tokenPricesEnd;
    }

    /* ------------- storage ------------- */

    /// @dev (bytes32 itemHash) => (uint256 totalSupply)
    mapping(bytes32 => uint256) public totalSupply;
    /// @dev (bytes32 itemHash) => (address user) => (uint256 numPurchases)
    mapping(bytes32 => mapping(address => uint256)) public numPurchases;
    /// @dev (bytes32 itemHash) => (uint256 tokenId) => (address user)
    mapping(bytes32 => mapping(uint256 => address)) public raffleEntries;
    /// @dev (bytes32 itemHash) => (uint256 seed)
    mapping(bytes32 => uint256) public raffleRandomSeeds;
    /// @dev (address token) => (bool approved)
    mapping(address => bool) public isAcceptedPaymentToken;
    /// @dev EIP2612 nonces
    mapping(address => uint256) public nonces;

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
        MARKET_ORDER_TYPE_HASH = keccak256(
            "MarketOrder(address buyer,bytes32[] itemHashes,address[] paymentTokens,bytes32 buyerHash,uint256 nonce,uint256 deadline)"
        );
    }

    /* ------------- EIP712 ------------- */

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("CRFTDMarketplace"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /* ------------- external ------------- */

    function purchaseMarketItems(MarketItem[] calldata items, address[] calldata paymentTokens, bytes32 buyerHash)
        public
        payable
    {
        // Make sure only approved tokens are being used.
        for (uint256 i; i < paymentTokens.length; ++i) {
            if (address(paymentTokens[i]).code.length == 0) revert InvalidPaymentToken();
        }

        _purchaseMarketItems(msg.sender, buyerHash, items, paymentTokens, new bytes32[](0));
    }

    function purchaseMarketItemsWithPermit(
        ERC20Permit[] calldata tokenPermits,
        MarketOrderPermit calldata orderPermit,
        MarketItem[] calldata items
    ) public {
        // Use ERC20 permits if provided.
        if (tokenPermits.length != 0) usePermits(tokenPermits);

        _validateOrder(orderPermit);

        _purchaseMarketItems(
            orderPermit.buyer, orderPermit.buyerHash, items, orderPermit.paymentTokens, orderPermit.itemHashes
        );
    }

    function purchaseMarketItemsWithPermitSafe(
        ERC20Permit[] calldata tokenPermits,
        MarketOrderPermit calldata orderPermit,
        MarketItem[] calldata items
    ) public {
        // Make sure only approved tokens are being used.
        for (uint256 i; i < orderPermit.paymentTokens.length; ++i) {
            if (!isAcceptedPaymentToken[orderPermit.paymentTokens[i]]) revert InvalidPaymentToken();
        }

        purchaseMarketItemsWithPermit(tokenPermits, orderPermit, items);
    }

    function usePermits(ERC20Permit[] calldata permits) public {
        for (uint256 i; i < permits.length; ++i) {
            ERC20Permit calldata permit = permits[i];

            permit.token.permit(
                permit.owner, address(this), permit.value, permit.deadline, permit.v, permit.r, permit.s
            );
        }
    }

    /* ------------- internal ------------- */

    function _purchaseMarketItems(
        address buyer,
        bytes32 buyerHash,
        MarketItem[] calldata items,
        address[] calldata paymentTokens,
        bytes32[] memory itemHashes
    ) private {
        unchecked {
            uint256 msgValue = msg.value;
            // If item hashes are provided, we need
            // to make sure to validate them.
            bool validateItemHashes = itemHashes.length != 0;

            for (uint256 i; i < items.length; ++i) {
                MarketItem calldata item = items[i];

                // Retrieve item's hash.
                bytes32 itemHash = keccak256(abi.encode(item));
                if (validateItemHashes && itemHashes[i] != itemHash) revert InvalidMarketItemHash();

                {
                    // Stack too deep in my ass.
                    // Get current total supply increased by `1`.
                    uint256 supply = ++totalSupply[itemHash];

                    // If it's a raffle, store raffle ticket ownership.
                    if (item.raffleNumPrizes != 0) raffleEntries[itemHash][supply] = buyer;

                    // Validate timestamp and supply.
                    if (block.timestamp < item.start || item.expiry < block.timestamp) revert NotActive();
                    if (++numPurchases[itemHash][buyer] > item.maxPurchases) revert MaxPurchasesReached();
                    if (supply > item.maxSupply) revert NoSupplyLeft();
                }

                // address paymentToken = paymentTokens[i];
                uint256 price;
                {
                    // Get token payment method and price.
                    (bool found, uint256 tokenIndex) = utils.indexOf(item.acceptedPaymentTokens, paymentTokens[i]);
                    if (!found) revert InvalidPaymentToken();

                    price = getItemPrice(item, tokenIndex);
                }

                // Handle token payment.
                if (paymentTokens[i] == address(0)) {
                    if (msgValue < price) revert InvalidEthAmount();

                    msgValue -= price; // Reduce `msgValue` balance.

                    payable(item.receiver).transfer(price); // Transfer ether to `receiver`.
                } else {
                    // Transfer tokens to receiver.
                    ERC20(paymentTokens[i]).safeTransferFrom(buyer, item.receiver, price);
                }

                emit MarketItemPurchased(item.marketId, itemHash, buyer, buyerHash, paymentTokens[i], price);
            }

            // Transfer any remaining value back.
            if (msg.sender == tx.origin && msgValue != 0) payable(msg.sender).transfer(msgValue);
        }
    }

    function _validateOrder(MarketOrderPermit calldata orderPermit) internal {
        // Validate order permit.
        if (orderPermit.itemHashes.length == 0) revert InvalidOrder();
        if (orderPermit.itemHashes.length != orderPermit.paymentTokens.length) revert InvalidOrder();
        if (orderPermit.deadline < block.timestamp) revert DeadlineExpired();

        bytes32 orderHash = keccak256(
            abi.encode(
                MARKET_ORDER_TYPE_HASH,
                orderPermit.buyer,
                keccak256(abi.encodePacked(orderPermit.itemHashes)),
                keccak256(abi.encodePacked(orderPermit.paymentTokens)),
                orderPermit.buyerHash,
                nonces[orderPermit.buyer]++,
                orderPermit.deadline
            )
        );

        // Recover signer.
        address recovered = ecrecover(
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), orderHash)),
            orderPermit.v,
            orderPermit.r,
            orderPermit.s
        );

        if (recovered == address(0) || recovered != orderPermit.buyer) revert InvalidSigner();
    }

    /* ------------- view (off-chain) ------------- */

    function getItemPrice(MarketItem calldata item, uint256 tokenIndex) public view returns (uint256 price) {
        price = item.tokenPricesStart[tokenIndex];

        // If the end is `!= 0` it is a dutch auction.
        if (item.end != 0) {
            // Clamp timestamp if it's outside of the range.
            uint256 timestamp =
                block.timestamp > item.end ? item.end : block.timestamp < item.start ? item.start : block.timestamp;

            // Linearly interpolate the price.
            // Safecasting is for losers.
            price = uint256(
                int256(price)
                    - (
                        (int256(item.tokenPricesStart[tokenIndex]) - int256(item.tokenPricesEnd[tokenIndex]))
                            * int256(timestamp - item.start)
                    ) / int256(item.end - item.start)
            );
        }
    }

    function getRaffleEntrants(bytes32 itemHash) external view returns (address[] memory entrants) {
        uint256 supply = totalSupply[itemHash];

        // Create address array of entrants.
        entrants = new address[](supply);

        // Loop over supply size and add to array.
        for (uint256 i; i < supply; ++i) {
            entrants[i] = raffleEntries[itemHash][i + 1];
        }
    }

    function getRaffleWinners(bytes32 itemHash, uint256 numPrizes) public view returns (address[] memory winners) {
        // Retrieve the random seed set for this raffle.
        uint256 randomSeed = raffleRandomSeeds[itemHash];
        // Make sure it is not the default `0`.
        if (randomSeed == 0) return winners;

        // Choose the winning ids.
        uint256[] memory winnerIds = choice.selectNOfM(numPrizes, totalSupply[itemHash], randomSeed);

        // Map winning ids to participating addresses.
        uint256 numWinners = winnerIds.length;
        winners = new address[](numWinners);

        for (uint256 i; i < numWinners; ++i) {
            winners[i] = raffleEntries[itemHash][winnerIds[i] + 1];
        }
    }

    /* ------------- restricted ------------- */

    function revealRaffle(MarketItem calldata item) external {
        // Compute item hash.
        bytes32 itemHash = keccak256(abi.encode(item));

        // Must be after raffle expiry time.
        if (block.timestamp < item.expiry) revert NotActive();

        // Make sure the caller is a controller.
        (bool found,) = utils.indexOf(item.raffleControllers, msg.sender);
        if (!found) revert NotAuthorized();

        // Only set the seed once.
        if (raffleRandomSeeds[itemHash] != 0) revert RandomSeedAlreadyChosen();

        // Cheap keccak randomness which can only be influenced by owner.
        raffleRandomSeeds[itemHash] = uint256(keccak256(abi.encode(blockhash(block.number - 1), itemHash)));
    }

    /* ------------- owner ------------- */

    function recoverToken(ERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverNFT(ERC721 token, uint256 id) external onlyOwner {
        token.transferFrom(address(this), msg.sender, id);
    }

    function setAcceptedPaymentToken(address token, bool accept) external onlyOwner {
        isAcceptedPaymentToken[token] = accept;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title Random Choice Library
/// @author phaze (https://github.com/0xPhaze)
/// @notice Selects `n` out of `m` given the random seed `r`.
/// @dev Caution: Uses only 16 bits of randomness for efficiency.
///      Assumes `n` << `m`: If `n` is close to `m` and `m` is big
///      the complexity will be very bad.
library choice {
    function selectNOfM(
        uint256 n,
        uint256 m,
        uint256 r
    ) internal pure returns (uint256[] memory selected) {
        if (n > m) n = m;

        selected = new uint256[](n);

        uint256 s;
        uint256 slot;

        uint256 j;
        uint256 c;

        bool invalidChoice;

        unchecked {
            for (uint256 i; i < n; ++i) {
                do {
                    slot = (s & 0xF) << 4;
                    if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, s)));
                    c = ((r >> slot) & 0xFFFF) % m;
                    invalidChoice = false;
                    for (j = 0; j < i && !invalidChoice; ++j) invalidChoice = selected[j] == c;
                    ++s;
                } while (invalidChoice);

                selected[i] = c;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {
    function getOwnedIds(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;
        uint256 idsLength;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 32)
        }

        unchecked {
            uint256 end = collectionSize + 1;
            for (uint256 id = 0; id < end; ++id) {
                if (ownerMapping[id] == user) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 32)
                        idsLength := add(idsLength, 1)
                    }
                }
            }
        }

        assembly {
            mstore(ids, idsLength)
            mstore(0x40, memPtr)
        }
    }

    function balanceOf(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256 numOwned) {
        unchecked {
            uint256 end = collectionSize + 1;
            address owner;
            for (uint256 id = 0; id < end; ++id) {
                owner = ownerMapping[id];
                assembly {
                    numOwned := add(numOwned, eq(owner, user))
                }
            }
        }
    }

    function indexOf(address[] calldata arr, address addr) internal pure returns (bool found, uint256 index) {
        unchecked {
            for (uint256 i; i < arr.length; ++i) if (arr[i] == addr) return (true, i);
        }
        return (false, 0);
    }
}