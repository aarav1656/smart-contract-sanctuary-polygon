// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {RandomStorage} from "./RandomStorage.sol";
import {RandomModifiers} from "./RandomModifiers.sol";

contract RandomFacet is RandomModifiers {
    
    function random(uint256 _raffleId, uint256 count) external view returns(uint256 rand) {
        // solhint-disable-next-line not-rely-on-time
        rand = uint256( keccak256(abi.encode(block.timestamp, s.raffles[_raffleId].participants, count)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RandomStorage {
    
    bool active;
   
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IRandomFacet} from "./IRandomFacet.sol";
import {Base} from "../../base/Base.sol";

abstract contract RandomModifiers is IRandomFacet, Base {

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {RandomStorage} from "./RandomStorage.sol";

interface IRandomFacet {

    function random(uint256 _raffleId, uint256 count) external view returns(uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IBase} from "../interfaces/IBase.sol";

/// @title Base Contract for Facets
/// @author Kfish n Chips
/// @notice Check that caller is a EoA
/// @dev revert with CallerNotEoA
/// @custom:security-contact [email protected]
abstract contract Base is IBase {
    AppStorage internal s;

    /// @notice Check that caller is a EoA
    /// @dev revert with CallerNotEoA
    modifier onlyEoA() {
        if(tx.origin != msg.sender) revert CallerNotEoA();      // solhint-disable-line avoid-tx-origin
        _;
    }

    /// @notice Check that a project with projectId_  is active
    /// @dev revert with ProjectNotActive
    modifier projectIsActive(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        if (!s.projects[projectId_].active) revert ProjectNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier projectExist(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        _;
    }

    /// @notice Check that category is Active Exist
    /// @dev 
    ///     revert with QueryNonExistentCategory
    ///     revert with CategoryNotActive
    modifier categoryIsActive(uint256 categoryId_) {
        if (!(categoryId_ > 0 && categoryId_ <= s.categoryCount)) revert QueryNonExistentCategory();
        if (!s.categories[categoryId_].active) revert CategoryNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier categoryExist(uint256 categoryId_) {
        if (categoryId_ < 1 ||  categoryId_ > s.categoryCount) revert QueryNonExistentCategory();
        _;
    }
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {RaffleStorage} from "../facets/Raffle/RaffleStorage.sol";
import {ProjectStorage} from "../facets/Project/ProjectStorage.sol";
import {AllowlistStorage} from "../facets/Allowlist/AllowlistStorage.sol";
import {CategoryStorage} from "../facets/Category/CategoryStorage.sol";
import {UserInventoryStorage} from "../facets/UserInventory/UserInventoryStorage.sol";


import {UserStorage} from "./LibUserStorage.sol";


/* AppStorage Pattern
 *
 * @dev A nicer and more convenient way to access application specific state variables that are shared among facets.
 * 
 * Keep State Variables Safe
 *   DOES
 *      1 To add new state variables to an AppStorage struct, add them to the end of the struct. This makes sense 
 *          because it is not possible for existing facets to overwrite state variables at new storage locations.
 *      2 New state variables can be added to the ends of structs that are stored in mappings.
 *      3 A trick to use inner structs and still enable them to be extended is to put them in mappings. A struct 
 *          stored in a mapping can be extended in upgrades.
 *   DONT
 *      1 If you are using AppStorage then do not declare and use state variables outside the AppStorage struct. 
 *          Except Diamond Storage can be used.
 *      2 Do not add new state variables to the beginning or middle of structs. Doing this makes the new state 
 *          variable overwrite existing state variable data and all state variables after the new state variable 
 *          reference the wrong storage location.
 *      3 Do not put structs directly in structs unless you don’t plan on ever adding more state variables to the 
 *          inner structs. You won't be able to add new state variables to inner structs in upgrades.
 *      4 Do not add new state variables to structs that are used in arrays.
 *      5 Do not allow any facet to be able to call `selfdestruct`. This is easy. Simply don’t allow the `selfdestruct` 
 *          command to exist in any facet source code and don’t allow that command to be called via a delegatecall. Because 
 *          `selfdestruct` could delete a facet that is used by a diamond, or `selfdestruct` could be used to delete a 
 *          diamond proxy contract.
 */ 
 
struct AppStorage {
    uint256 allowlistsCount;
    uint256 rafflesCount;
    uint256 usersCount;
    uint256 projectsCount;
    uint256 categoryCount;
    uint256 activeCategoryCount;
    address createUserSigner;
    IERC20 tokenContract;
    address collector;
    // wallet => User
    mapping(address => UserStorage) users;
    // project id => Project
    mapping(uint256 => ProjectStorage) projects;
    // listing id => Allowlist
    mapping(uint256 => AllowlistStorage) allowlists; 
    // raffle id => Raffle
    mapping(uint256 => RaffleStorage) raffles;
    // raffle id => address => bool)
    mapping(uint256 => mapping (address => bool)) rafflesWinners;
    // address => User Inventory
    mapping(address => UserInventoryStorage) userInventory;
    // category id => Category
    mapping(uint256 => CategoryStorage) categories;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IBase {
    error EndTimeBeforeStartTime();
    error CallerNotEoA();
    error InvalidSignature();
    error QueryNonExistentCategory();
    error CategoryNotActive();
    error UserWalletNotMatch();
    error MaxPerWalletReached();
    
    /**
        STOCK
    */
    error TotalStockLessThanSoldStock();
    error NotEnoughStock();
    error NoStockLeft();
    error CreateWithZeroStock();
    error PurchasedGreaterStock();
    /**
        USERS
    */
    error UserAlreadyExists();
    error CreateUserSignerZero();
    error AlreadyIsCreateUserSigner();
    error QueryNonExistentUser();
    error UserIsFrozen();
    
    
    /**
        PROJECTS
    */
    error QueryNonExistentProject();
    error ProjectNotActive();
    error MaxPerWalletZero();
    error ProjectAlreadyInState();
    /**
        RBAC
    */
    error CallerNotAuthorized();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title  Raffle AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RaffleStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 maxWinners;
    uint256 winnersCount;
    uint256 projectId;
    string  raffleMetadataUrl;
    bool active;
    bool raffled;
    address[] participants;
    address[] winners;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct ProjectStorage {
    uint256 id;
    uint256 maxPerWallet;
    bool active;
    uint256 categoryId;
    string metadataUrl;
    uint256 allowlistsCount;
    uint256 raffleCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct AllowlistStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 projectId;
    string  allowlistMetadataUrl;
    bool active;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Category AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct CategoryStorage {
    uint256 id;
    string name;
    bool active;
    string metadataUrl;
    uint256 projectsCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct UserInventoryStorage {
    uint256[] allowlistsIds;
    uint256[] raffleIds;
    uint256[] raffleWonIds;
    // project id => count of allowlist + raffle won
    mapping(uint256 => uint256) projectBalance;
    // allowlist id => count of allowlist 
    mapping(uint256 => uint256) allowlistsBalance;
    // raffke id => count of raffle 
    mapping(uint256 => uint256) raffleBalance;
    // raffke id => count of raffle won
    mapping(uint256 => uint256) raffleWonBalance;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Data Storage for User
/// wallet: address of the user
/// discordID: ID of the user on Discord
/// frozen: enable/disable user

struct UserStorage {
    address wallet;
    string discordId;
    uint256 purchaseCount;
    bool frozen;
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