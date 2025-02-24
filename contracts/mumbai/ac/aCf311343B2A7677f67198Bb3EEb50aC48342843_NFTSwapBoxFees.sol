// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/INFTSwap.sol";
import "./interface/INFTSwapFeeDiscount.sol";

contract NFTSwapBoxFees is INFTSwap,AccessControl {
    using SafeMath for uint256;
    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint256 public defaultNFTSwapFee = 0.0001 ether;
    uint256 public defaultTokenSwapPercentage;
    uint256 public defaultGasTokenSwapPercentage;

    mapping(address => uint256) public NFTSwapFee;
    mapping(address => uint256) public ERC20SwapFee;
    mapping(address => RoyaltyFee) public NFTRoyaltyFee;

    address public nftSwapFeeDiscount;

    /// @dev Add `root` to the admin role as a member.
    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
    }

    function setDefaultNFTSwapFee(uint256 fee) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 0, "fee must be greate than 0");
        defaultNFTSwapFee = fee;
    }

    function setDefaultTokenSwapPercentage(uint256 fee) public  {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultTokenSwapPercentage = fee;
    }

    function setDefaultGasTokenSwapPercentage(uint256 fee) public {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultGasTokenSwapPercentage = fee;
    }

    function setNFTSwapFee(address nftAddress, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTSwapFee[nftAddress] = fee;
    }

    function setNFTRoyaltyFee(address nftAddress, uint256 fee, address receiver) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTRoyaltyFee[nftAddress].feeAmount = uint96(fee);
        NFTRoyaltyFee[nftAddress].reciever = receiver;
    }

    function setERC20Fee(address erc20Address, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 100 && fee <= 10000, "fee must be greate than 0");
        ERC20SwapFee[erc20Address] = fee;
    }

    function setNFTSwapDiscountAddress(address addr) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        nftSwapFeeDiscount = addr;
    }

    function getNFTSwapFee(address nftAddress) public view returns(uint256) {
        return NFTSwapFee[nftAddress];
    }

    function getRoyaltyFee(address nftAddress) public view returns(RoyaltyFee memory) {
        return NFTRoyaltyFee[nftAddress];
    }

    function getERC20Fee(address erc20Address) public view returns(uint256) {
        return ERC20SwapFee[erc20Address];
    }

    // function _getNFTLength(
    //     ERC721Details[] memory _erc721Details,
    //     ERC1155Details[] memory _erc1155Details
    // ) internal view returns(uint256) {

    //     uint256 royaltyLength;
    //     for(uint256 i ; i < _erc721Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     for(uint256 i ; i < _erc1155Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     return royaltyLength;
    // }

    function _checkerc20Fees(
        ERC20Details[] memory _erc20Details,
        address boxOwner
    ) external view returns(ERC20Fee[] memory) {
        uint256 erc20fee;
        ERC20Fee [] memory fees = new ERC20Fee[](_erc20Details.length);
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc20Details.length ; ++i) {
            erc20fee = 0;
            if(ERC20SwapFee[_erc20Details[i].tokenAddr] > 0)
                erc20fee = _erc20Details[i].amounts * ERC20SwapFee[_erc20Details[i].tokenAddr];
            else
                erc20fee = _erc20Details[i].amounts * defaultTokenSwapPercentage;
            erc20fee -= erc20fee * userDiscount / 10000;
            fees[i].tokenAddr = _erc20Details[i].tokenAddr;
            fees[i].feeAmount = uint96(erc20fee / 10000);
        }
        return fees;
    }
    
    function _checknftgasfee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenAmount,
        address boxOwner
    ) external view returns(uint256){
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);
        uint256 erc721Fee;
        uint256 erc1155Fee;
        uint256 gasFee;
        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += defaultNFTSwapFee;

            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];    

            if(nftDiscount > userDiscount) {
                erc721Fee -= erc721Fee * nftDiscount / 10000;
            }
            else {  
                erc721Fee -= erc721Fee * userDiscount / 10000;
            }
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount2 != 0)
               erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount2;
            
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount2 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount2;

            if(nftDiscount > userDiscount) {
                erc1155Fee -= erc1155Fee * nftDiscount / 10000;
            }
            else {  
                erc1155Fee -= erc1155Fee * userDiscount / 10000;
            }
        }

        if(_gasTokenAmount > 0)
            gasFee = _gasTokenAmount *  defaultGasTokenSwapPercentage / 10000;
        gasFee -= gasFee * userDiscount / 10000;

        return erc721Fee + erc1155Fee + gasFee;
    }

    function _checkRoyaltyFee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        address boxOwner
    ) external view returns(RoyaltyFee[] memory) {
        RoyaltyFee[] memory royalty = new RoyaltyFee[](_erc721Details.length + _erc1155Details.length);
       
        uint256 nftIndex;
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id1 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id2 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id3 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;

            if(nftDiscount > userDiscount) {
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else {  
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc721Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount1 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount1;   
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount2 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount2;   

            if(nftDiscount > userDiscount){
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else{
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc1155Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        return royalty;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwap {

    event SwapBoxState(
        uint32 boxID,
        uint8 state,
        string chainName
    );

    event SwapBoxOffer(
        uint32 listBoxID,
        uint32 OfferBoxID,
        string chainName
    );

    event Swaped (
        uint256 historyID,
        uint256 listID,
        address listBoxOwner,
        uint256 offerID,
        address offerBoxOwner,
        string chainName
    );

    event SwapBoxWithDrawOffer(
        uint32 listSwapBoxID,
        uint32 offerSwapBoxID,
        string chainName
    );

    struct ERC20Details {
        address tokenAddr;
        uint96 amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint32 id3;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint16 amount1;
        uint16 amount2;
    }

    struct ERC20Fee {
        address tokenAddr;
        uint96 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint96 feeAmount;
    }


    struct SwapBox {
        address owner;
        uint32 id;
        uint32 state;
        uint32 whiteListOffer;
    }
    
    struct SwapBoxConfig {
        uint8 usingERC721WhiteList;
        uint8 usingERC1155WhiteList;
        uint8 NFTTokenCount;
        uint8 ERC20TokenCount;
    }

    struct UserTotalSwapFees {
        address owner;
        uint256 nftFees;
        ERC20Fee[] totalERC20Fees;
    }

    struct SwapHistory {
        uint256 id;
        uint256 listId;
        address listOwner;
        uint256 offerId;
        address offerOwner;
        uint256 swapedTime;
    }

    struct Discount {
        address user;
        address nft;
    }

    struct PrePaidFee {
        uint256 nft_gas_SwapFee;
        ERC20Fee[] erc20Fees;
        RoyaltyFee[] royaltyFees;
    }

    enum State {    
        Waiting_for_offers,
        Offered
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwapFeeDiscount {
    function getUserDiscount(address) external view returns(uint256);
    function getNFTDiscount(address) external view returns(uint256);

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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