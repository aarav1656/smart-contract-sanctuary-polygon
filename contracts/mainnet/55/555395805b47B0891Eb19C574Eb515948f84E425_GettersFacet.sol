//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IVotingEscrow.sol";
import "../../interfaces/IMultiFeeDistribution.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Modifiers, VeEthaInfo, Rewards, MATIC, IERC20, WMATIC} from "./AppStorage.sol";

contract GettersFacet is Modifiers {
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    function getTokenFeed(address token) external view returns (address) {
        return s.priceFeeds[token];
    }

    function getPrice(address token) external view returns (int256) {
        address feed = s.priceFeeds[token];

        if (feed != address(0)) {
            (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
            return price;
        } else return 0;
    }

    function getPriceQuickswap(address token, uint amount) external view returns (uint256) {
        address[] memory path;
        path[0] = token;
        path[1] = USDC;
        uint received = IUniswapV2Router(ROUTER).getAmountsOut(amount, path)[1];

        path[1] = WMATIC;
        path[2] = USDC;
        uint received2 = IUniswapV2Router(ROUTER).getAmountsOut(amount, path)[2];

        uint bestPrice = received > received2 ? received : received2;

        return formatDecimals(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, bestPrice);
    }

    function getAToken(address token) external view returns (address) {
        return s.aTokens[token];
    }

    function getCrToken(address token) external view returns (address) {
        return s.crTokens[token];
    }

    function getCurvePool(address token) external view returns (address) {
        return s.curvePools[token];
    }

    function getBalances(address[] calldata tokens, address user) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == MATIC) balances[i] = user.balance;
            else balances[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return balances;
    }

    function getGovernanceInfo(address veETHA, address user)
        external
        view
        returns (VeEthaInfo memory info, Rewards[] memory rewards)
    {
        info.feeRecipient = IVotingEscrow(veETHA).penaltyCollector();
        info.minLockedAmount = IVotingEscrow(veETHA).minLockedAmount();
        info.penaltyRate = IVotingEscrow(veETHA).earlyWithdrawPenaltyRate();
        info.totalEthaLocked = IVotingEscrow(veETHA).supply();
        info.totalVeEthaSupply = IVotingEscrow(veETHA).totalSupply();
        info.userVeEthaBalance = IVotingEscrow(veETHA).balanceOf(user);
        (info.userEthaLocked, info.userLockEnds) = IVotingEscrow(veETHA).locked(user);

        info.multiFeeAddress = IVotingEscrow(veETHA).multiFeeDistribution();
        IMultiFeeDistribution multiFee = IMultiFeeDistribution(info.multiFeeAddress);
        info.multiFeeTotalStaked = multiFee.totalStaked();
        info.multiFeeUserStake = multiFee.balances(user);

        address[] memory rewardTokens = multiFee.getRewardTokens(); // only works with new multi fee

        IMultiFeeDistribution.RewardData[] memory userClaimable = multiFee.claimableRewards(user);
        rewards = new Rewards[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IMultiFeeDistribution.Reward memory rewardData = multiFee.rewardData(rewardTokens[i]);
            rewards[i].tokenAddress = rewardTokens[i];
            rewards[i].rewardRate = rewardData.rewardRate;
            rewards[i].periodFinish = rewardData.periodFinish;
            rewards[i].balance = rewardData.balance;
            rewards[i].claimable = userClaimable[i].amount;
        }
    }
}

// SPDX-License-Identifier: MIT

// Standard Curvefi voting escrow interface
// We want to use a standard iface to allow compatibility
pragma solidity ^0.8.0;

interface IVotingEscrow {
    // Following are used in Fee distribution contracts e.g.
    /*
        https://etherscan.io/address/0x74c6cade3ef61d64dcc9b97490d9fbb231e4bdcc#code
    */
    // struct Point {
    //     int128 bias;
    //     int128 slope;
    //     uint256 ts;
    //     uint256 blk;
    // }

    // function user_point_epoch(address addr) external view returns (uint256);

    // function epoch() external view returns (uint256);

    // function user_point_history(address addr, uint256 loc) external view returns (Point);

    // function checkpoint() external;

    /*
    https://etherscan.io/address/0x2e57627ACf6c1812F99e274d0ac61B786c19E74f#readContract
    */
    // Gauge proxy requires the following. inherit from ERC20
    // balanceOf
    // totalSupply

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function emergencyWithdraw() external;

    // Extra required views
    function balanceOf(address) external view returns (uint256);

    function supply() external view returns (uint256);

    function minLockedAmount() external view returns (uint256);

    function earlyWithdrawPenaltyRate() external view returns (uint256);

    function MINDAYS() external view returns (uint256);

    function MAXDAYS() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function locked(address) external view returns (uint256, uint256);

    function delegates(address account) external view returns (address);

    function lockedToken() external view returns (address);

    function penaltyCollector() external view returns (address);

    function multiFeeDistribution() external view returns (address);

    function delegate(address delegatee) external;

    function locked__of(address _addr) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function voting_power_unlock_time(uint256 _value, uint256 _unlockTime) external view returns (uint256);

    function voting_power_locked_days(uint256 _value, uint256 _days) external pure returns (uint256);

    // function transferOwnership(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        // tracks already-added balances to handle accrued interest in aToken rewards
        // for the stakingToken this value is unused and will always be 0
        uint256 balance;
    }

    struct RewardData {
        address token;
        uint256 amount;
    }

    function stake(uint256 amount, address user) external;

    function withdraw(uint256 amount, address user) external;

    function getReward(address[] memory _rewardTokens, address user) external;

    function exit(address user) external;

    function getRewardTokens() external view returns (address[] memory);

    function rewardData(address) external view returns (Reward memory);

    function claimableRewards(address) external view returns (RewardData[] memory);

    function totalStaked() external view returns (uint);

    function balances(address) external view returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {LibDiamond} from "../../libs/LibDiamond.sol";
import {LibMeta} from "../../libs/LibMeta.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

address constant MATIC = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

// AAVE
address constant AAVE_DATA_PROVIDER = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
address constant AAVE_INCENTIVES = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;

// QUICK
address constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
address constant DQUICK = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;

struct LpData {
    uint256 lpPrice;
    uint256 totalSupply;
    uint256 totalMarketUSD;
    uint112 reserves0;
    uint112 reserves1;
    address token0;
    address token1;
    string symbol0;
    string symbol1;
}

struct VeEthaInfo {
    address feeRecipient;
    uint256 minLockedAmount;
    uint256 penaltyRate;
    uint256 totalEthaLocked;
    uint256 totalVeEthaSupply;
    address multiFeeAddress;
    uint256 multiFeeTotalStaked;
    uint256 userVeEthaBalance;
    uint256 userEthaLocked;
    uint256 userLockEnds;
    uint256 multiFeeUserStake;
}

struct Rewards {
    address tokenAddress;
    uint256 rewardRate;
    uint periodFinish;
    uint balance;
    uint claimable;
}

struct SynthData {
    address stakingToken;
    address stakingContract;
    address rewardsToken;
    uint256 totalStaked;
    uint256 rewardsRate;
    uint256 periodFinish;
    uint256 rewardBalance;
}

struct ChefData {
    address stakingToken;
    address stakingContract;
    address rewardsToken;
    uint256 totalStaked;
    uint256 rewardsRate;
    uint256 periodFinish;
    uint256 rewardBalance;
}

struct VaultInfo {
    address depositToken;
    address rewardsToken;
    address strategy;
    address distribution;
    address feeRecipient;
    address strategist;
    uint256 totalDeposits;
    uint256 performanceFee;
    uint256 withdrawalFee;
    uint256 lastDistribution;
}

struct QiVaultInfo {
    address stakingContract;
    address qiToken;
    address lpToken;
    address qiVault;
    uint poolId;
    uint debt;
    uint availableBorrow;
    uint collateral;
    uint safeLow;
    uint safeHigh;
    uint safeTarget;
}

struct LendingBalance {
    uint256 aave;
    uint256 cream;
}

struct AppStorage {
    mapping(address => address) aTokens;
    mapping(address => address) debtTokens;
    mapping(address => address) crTokens;
    mapping(address => address) priceFeeds;
    mapping(address => address) curvePools;
    address[] creamMarkets;
    address ethaRegistry;
    address feeManager;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function formatDecimals(address token, uint256 amount) internal view returns (uint256) {
        uint256 decimals = IERC20Metadata(token).decimals();

        if (decimals == 18) return amount;
        else return (amount * 1 ether) / (10**decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
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