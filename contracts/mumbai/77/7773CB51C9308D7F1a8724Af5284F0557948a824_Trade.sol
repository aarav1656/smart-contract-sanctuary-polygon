// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interface/ITransferProxy.sol";

contract Trade is AccessControl {
    enum BuyingAssetType {
        ERC1155,
        ERC721,
        LazyERC1155,
        LazyERC721
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    event ExecuteBid(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    // buyer platformFee
    uint8 private buyerFeePermille;
    //seller platformFee
    uint8 private sellerFeePermille;

    uint8 private buyerFeePermilleForWETH;

    uint8 private sellerFeePermilleForWETH;

    ITransferProxy public transferProxy;
    //contract owner
    address public owner;

    address public signer;

    mapping(uint256 => bool) private usedNonce;
    mapping (uint256 => Asset1155) private users;

    struct Asset1155 {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 supply;
        bool initialize;
    }

    IERC20 public weth;

    IERC20 public mfgToken;

    uint256 public mintingFee = 1000 * 10 ** 18;


    /** Fee Struct
        @param platformFee  uint256 (buyerFee + sellerFee) value which is transferred to current contract owner.
        @param assetFee  uint256  assetvalue which is transferred to current seller of the NFT.
        @param royaltyFee  uint256 value, transferred to Minter of the NFT.
        @param price  uint256 value, the combination of buyerFee and assetValue.
        @param tokenCreator address value, it's store the creator of NFT.
     */
    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    /** Order Params
        @param seller address of user,who's selling the NFT.
        @param buyer address of user, who's buying the NFT.
        @param erc20Address address of the token, which is used as payment token(WETH/WBNB/WMATIC...)
        @param nftAddress address of NFT contract where the NFT token is created/Minted.
        @param nftType an enum value, if the type is ERC721/ERC1155 the enum value is 0/1.
        @param uintprice the Price Each NFT it's not including the buyerFee.
        @param amout the price of NFT(assetFee + buyerFee).
        @param tokenId
        @param qty number of quantity to be transfer.
     */
    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        bool skipRoyalty;
        uint256 amount;
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        uint96 royaltyFee;
        uint256 qty;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        uint8 _buyerFeeForWETH,
        uint8 _sellerFeeForWETH,
        ITransferProxy _transferProxy,
        IERC20 _weth,
        IERC20 _mfgToken
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        buyerFeePermilleForWETH = _buyerFeeForWETH;
        sellerFeePermilleForWETH = _sellerFeeForWETH;
        transferProxy = _transferProxy;
        weth = _weth;
        mfgToken = _mfgToken;
        owner = msg.sender;
        signer = msg.sender;
        _setupRole("ADMIN_ROLE", msg.sender);
    }

    /**
        returns the buyerservice Fee in multiply of 1000.
     */

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    /**
        returns the sellerservice Fee in multiply of 1000.
     */

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function buyerServiceFeeForWETH() external view virtual returns (uint8) {
        return buyerFeePermilleForWETH;
    }

    function sellerServiceFeeForWETH() external view virtual returns (uint8) {
        return sellerFeePermilleForWETH;
    }

    /**
        @param _buyerFee  value for buyerservice in multiply of 1000.
    */

    function setBuyerServiceFee(uint8 _buyerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    /**
        @param _sellerFee  value for buyerservice in multiply of 1000.
    */

    function setSellerServiceFee(uint8 _sellerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    /**
        @param _buyerFee  value for buyerserviceForWeth in multiply of 1000.
    */

    function setBuyerServiceFeeForWETH(uint8 _buyerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns(bool)
    {
        buyerFeePermilleForWETH = _buyerFee;
        emit BuyerFee(buyerFeePermilleForWETH);
        return true;
    }

    /**
        @param _sellerFee  value for sellerserviceForWeth in multiply of 1000.
    */

    function setSellerServiceFeeForWETH(uint8 _sellerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns(bool)
    {
        sellerFeePermilleForWETH = _sellerFee;
        emit SellerFee(sellerFeePermilleForWETH);
        return true;
    }

    /**
        transfers the contract ownership to newowner address.
        @param newOwner address of newOwner
     */

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function buyAsset(Order calldata order, uint256 supply, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        if(order.nftType == BuyingAssetType.ERC721 ||  order.nftType == BuyingAssetType.LazyERC721) {
            usedNonce[sign.nonce] = true;
        }
        else if(order.nftType == BuyingAssetType.ERC1155 || order.nftType == BuyingAssetType.LazyERC1155) {
              if(users[sign.nonce].initialize){
                require(users[sign.nonce].nftAddress == order.nftAddress && users[sign.nonce].seller == order.seller && users[sign.nonce].tokenId == order.tokenId, "Nonce: Invalid Data");
                require(users[sign.nonce].supply >= order.qty, "Invalid Quantity");
                users[sign.nonce].supply -= order.qty;
                if(users[sign.nonce].supply == 0) {
                    usedNonce[sign.nonce] = true;
                }
            }
            else if(!users[sign.nonce].initialize) {
                require(supply >= order.qty, "Invalid Quantity");
                users[sign.nonce] = Asset1155(order.seller, order.nftAddress, order.tokenId, supply - order.qty, true);
            }
        }
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            supply,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function executeBid(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

        /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function mintAndBuyAsset(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.tokenId,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function mintAndExecuteBid(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    function mint(address nftAddress, BuyingAssetType nftType, string memory tokenURI, uint96 fee, uint256 supply, Sign memory sign)
        external
        returns(bool)
    {
        verifyOwnerSign(
            msg.sender,
            tokenURI,
            nftAddress,
            sign
        );
        if(mintingFee != 0) {
            transferProxy.erc20safeTransferFrom(IERC20(mfgToken), msg.sender, owner, mintingFee);
        }
        if(nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721mint(ILazyMint(nftAddress), msg.sender, tokenURI, fee);
        }
        if(nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155mint(ILazyMint(nftAddress), msg.sender, tokenURI, fee, supply);
        }
        return true;
    }


    /**
        returns the signer of given signature.
     */
    function getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    function verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            seller == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function verifyOwnerSign(
        address seller,
        string memory tokenURI,
        address assetAddress,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                this,
                assetAddress,
                seller,
                tokenURI,
                sign.nonce
            )
        );
        require(
            signer == getSigner(hash, sign),
            "owner sign verification failed"
        );
    }

    function verifyBuyerSign(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            buyer == getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    /**
        it retuns platformFee, assetFee, royaltyFee, price and tokencreator.
     */

    function getFees(
        Order calldata order
    ) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint _buyerFeePermille = weth == IERC20(order.erc20Address) ? buyerFeePermilleForWETH : buyerFeePermille;
        uint _sellerFeePermille = weth == IERC20(order.erc20Address) ? sellerFeePermilleForWETH : sellerFeePermille;
        uint256 price = (order.amount * 1000) / (1000 + _buyerFeePermille);
        uint256 buyerFee = order.amount - price;
        uint256 sellerFee = (price * _sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        if(!order.skipRoyalty && ((order.nftType == BuyingAssetType.ERC721) || (order.nftType == BuyingAssetType.ERC1155))) {
            (tokenCreator, royaltyFee) = IERC2981(order.nftAddress)
                    .royaltyInfo(order.tokenId, price);
        }
        if(!order.skipRoyalty && ((order.nftType == BuyingAssetType.LazyERC721) || (order.nftType == BuyingAssetType.LazyERC1155))) {
            (tokenCreator, royaltyFee) = (order.seller, order.royaltyFee);
        }
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    /**
        transfers the NFTs and tokens...
        @param order ordervalues(seller, buyer,...).
        @param fee Feevalues(platformFee, assetFee,...).
    */

    function tradeAsset(
        Order calldata order,
        Fee memory fee,
        address buyer,
        address seller
    ) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(
                IERC721(order.nftAddress),
                seller,
                buyer,
                order.tokenId
            );
        }
        if (order.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(order.nftAddress),
                seller,
                buyer,
                order.tokenId,
                order.qty,
                ""
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC721) {
            transferProxy.mintAndSafe721Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee
            );
        }
        if (order.nftType == BuyingAssetType.LazyERC1155) {
            transferProxy.mintAndSafe1155Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.supply,
                order.qty
            );
        }

        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                owner,
                fee.platformFee
            );
        }
        if (fee.royaltyFee > 0 && (!order.skipRoyalty)) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                fee.tokenCreator,
                fee.royaltyFee
            );
        }
        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

import "./ILazyMint.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

interface ITransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;
    
    function mintAndSafe1155Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        uint256 qty
    ) external ;

    function mintAndSafe721Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external ;

    function erc721mint(
        ILazyMint token, 
        address creator, 
        string memory tokenURI, 
        uint96 fee
    ) external;

    function erc1155mint(
        ILazyMint token, 
        address creator, 
        string memory tokenURI, 
        uint96 fee,
        uint256 supply 
    ) external;

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface ILazyMint {

    function mint(
        address creator,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external returns (uint256 _tokenId);

    function mint(
        address creator,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply
    ) external returns (uint256 _tokenId);

    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external returns(uint256 _tokenId);
    
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        uint256 qty
    ) external returns(uint256 _tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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