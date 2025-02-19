/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// hevm: flattened sources of src/deployers/BorrowerDeployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

////// src/factories/interfaces.sol
/* pragma solidity >=0.7.6; */

interface NAVFeedFactoryLike {
    function newFeed() external returns (address);
}

interface TitleFabLike {
    function newTitle(string calldata, string calldata) external returns (address);
}

interface PileFactoryLike {
    function newPile() external returns (address);
}

interface ShelfFactoryLike {
    function newShelf(address, address, address, address) external returns (address);
}

interface ReserveFactoryLike_1 {
    function newReserve(address) external returns (address);
}

interface AssessorFactoryLike_2 {
    function newAssessor() external returns (address);
}

interface TrancheFactoryLike_1 {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFactoryLike_2 {
    function newCoordinator(uint) external returns (address);
}

interface OperatorFactoryLike_1 {
    function newOperator(address) external returns (address);
}

interface MemberlistFactoryLike_1 {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFactoryLike_1 {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface PoolAdminFactoryLike {
    function newPoolAdmin() external returns (address);
}

interface ClerkFactoryLike {
    function newClerk(address, address) external returns (address);
}

interface castenManagerFactoryLike {
    function newcastenManager(address, address, address,  address, address, address, address, address) external returns (address);
}


////// src/fixed_point.sol
/* pragma solidity >=0.7.6; */

abstract contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

////// src/deployers/BorrowerDeployer.sol
/* pragma solidity >=0.7.6; */

/* import { ShelfFactoryLike, PileFactoryLike, TitleFabLike } from "./../factories/interfaces.sol"; */
/* import { FixedPoint } from "./../fixed_point.sol"; */

interface DependLike_1 {
    function depend(bytes32, address) external;
}

interface AuthLike_1 {
    function rely(address) external;
    function deny(address) external;
}

interface NAVFeedLike_2 {
    function init() external;
}

interface FeedFabLike {
    function newFeed() external returns(address);
}

interface FileLike_1 {
    function file(bytes32 name, uint value) external;
}

contract BorrowerDeployer is FixedPoint {
    address      public immutable root;

    TitleFabLike     public immutable titlefab;
    ShelfFactoryLike     public immutable shelffab;
    PileFactoryLike      public immutable pilefab;
    FeedFabLike      public immutable feedFab;

    address public title;
    address public shelf;
    address public pile;
    address public immutable currency;
    address public feed;

    string  public titleName;
    string  public titleSymbol;
    Fixed27 public discountRate;

    address constant ZERO = address(0);
    bool public wired;

    constructor (
      address root_,
      address titlefab_,
      address shelffab_,
      address pilefab_,
      address feedFab_,
      address currency_,
      string memory titleName_,
      string memory titleSymbol_,
      uint discountRate_
    ) {
        root = root_;

        titlefab = TitleFabLike(titlefab_);
        shelffab = ShelfFactoryLike(shelffab_);

        pilefab = PileFactoryLike(pilefab_);
        feedFab = FeedFabLike(feedFab_);

        currency = currency_;

        titleName = titleName_;
        titleSymbol = titleSymbol_;
        discountRate = Fixed27(discountRate_);
    }

    function deployPile() public {
        require(pile == ZERO);
        pile = pilefab.newPile();
        AuthLike_1(pile).rely(root);
    }

    function deployTitle() public {
        require(title == ZERO);
        title = titlefab.newTitle(titleName, titleSymbol);
        AuthLike_1(title).rely(root);
    }

    function deployShelf() public {
        require(shelf == ZERO && title != ZERO && pile != ZERO && feed != ZERO);
        shelf = shelffab.newShelf(currency, address(title), address(pile), address(feed));
        AuthLike_1(shelf).rely(root);
    }

    function deployFeed() public {
        require(feed == ZERO);
        feed = feedFab.newFeed();
        AuthLike_1(feed).rely(root);
    }

    function deploy(bool initNAVFeed) public {
        // ensures all required deploy methods were called
        require(shelf != ZERO);
        require(!wired, "borrower contracts already wired"); // make sure borrower contracts only wired once
        wired = true;

        // shelf allowed to call
        AuthLike_1(pile).rely(shelf);

        DependLike_1(feed).depend("shelf", address(shelf));
        DependLike_1(feed).depend("pile", address(pile));

        // allow nftFeed to update rate groups
        AuthLike_1(pile).rely(feed);

        DependLike_1(shelf).depend("subscriber", address(feed));

        AuthLike_1(feed).rely(shelf);
        AuthLike_1(title).rely(shelf);
        
        FileLike_1(feed).file("discountRate", discountRate.value);

        if (initNAVFeed) {
            NAVFeedLike_2(feed).init();
        }
    }


    function deploy() public {
        deploy(false);
    }
}