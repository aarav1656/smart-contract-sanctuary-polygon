// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {IValidator} from "../validators/IValidator.sol";

contract RewardVaultETH is IERC721Receiver, Initializable {
    using SafeERC20 for IERC20;

    struct LPTokenInfo {
        uint256 amount0;
        uint256 amount1;
        uint256 amount;
        address owner;
    }

    /// @dev The number of NFTs in the pool
    uint128 private reserve0; // uses single storage slot, accessible via getReserves
    /// @dev The amount of ETH in the pool
    uint128 private reserve1; // uses single storage slot, accessible via getReserves

    address protocolOwner;
    address deployer;
    ICollectionPoolFactory public lpToken;
    IValidator public validator;
    IERC721 nft;
    ICurve.Params curveParams;
    address bondingCurve;
    uint96 fee;
    uint256 royaltyNumerator;
    bytes32 tokenIDFilterRoot;

    uint256 public constant MAX_REWARD_TOKENS = 5;
    uint256 public LOCK_TIME;

    /// @dev The total number of tokens minted
    uint256 private _totalSupply;
    mapping(address => uint256) internal _balances;
    /// @dev maps from tokenId to pool LPToken information
    mapping(uint256 => LPTokenInfo) public lpTokenInfo;

    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public rewardTokenValid;

    uint256 public periodFinish;
    uint256 public rewardSweepTime;
    /// @dev maps from ERC20 token to the reward amount / duration of period
    mapping(IERC20 => uint256) public rewardRates;
    uint256 public lastUpdateTime;
    /**
     * @dev maps from ERC20 token to the reward amount accumulated per unit of
     * reward token
     */
    mapping(IERC20 => uint256) public rewardPerTokenStored;
    mapping(IERC20 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(IERC20 => mapping(address => uint256)) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 amount);
    event RewardPaid(IERC20 indexed rewardToken, address indexed user, uint256 reward);
    event RewardSwept();
    event RewardVaultRecharged(IERC20[] rewardTokens, uint256[] rewards, uint256 startTime, uint256 endTime);

    //////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////
    error BadEndTime();
    error BalanceOverflow();
    error CallerNotEOA();
    error LengthLimitExceeded();
    error LengthMismatch();
    error MissingExistingTokens();
    error NFTNotERC721();
    error NotTwoSidedLP();
    error PoolMismatch();
    error RepeatedToken();
    error RewardsOngoing();
    error TokenMismatch();
    error TooEarly();
    error Unauthorized();
    error ZeroRewardRate();

    modifier updateReward(address account) {
        // skip update after rewards program starts
        // cannot include equality because
        // multiple accounts can perform actions in the same block
        // and we have to update account's rewards and userRewardPerTokenPaid values
        if (block.timestamp < lastUpdateTime) {
            _;
            return;
        }

        _applyRewardUpdate(account);
        _;
    }

    function _applyRewardUpdate(address account) internal {
        uint256 rewardTokensLength = rewardTokens.length;
        // lastUpdateTime is set to startTime in constructor
        if (block.timestamp > lastUpdateTime) {
            for (uint256 i; i < rewardTokensLength;) {
                IERC20 rewardToken = rewardTokens[i];
                rewardPerTokenStored[rewardToken] = rewardPerToken(rewardToken);
                unchecked {
                    ++i;
                }
            }
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            for (uint256 i; i < rewardTokensLength;) {
                IERC20 rewardToken = rewardTokens[i];
                rewards[rewardToken][account] = earned(account, rewardToken);
                userRewardPerTokenPaid[rewardToken][account] = rewardPerTokenStored[rewardToken];
                unchecked {
                    ++i;
                }
            }
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _protocolOwner,
        address _deployer,
        ICollectionPoolFactory _lpToken,
        IValidator _validator,
        IERC721 _nft,
        address _bondingCurve,
        ICurve.Params calldata _curveParams,
        uint96 _fee,
        uint256 _royaltyNumerator,
        bytes32 _tokenIDFilterRoot,
        IERC20[] calldata _rewardTokens,
        uint256[] calldata _rewardRates,
        uint256 _startTime,
        uint256 _periodFinish
    ) public initializer {
        protocolOwner = _protocolOwner;
        LOCK_TIME = 30 days;
        if (!_nft.supportsInterface(0x80ac58cd)) revert NFTNotERC721(); // check if it supports ERC721
        deployer = _deployer;
        lpToken = _lpToken;
        validator = _validator;
        nft = _nft;
        bondingCurve = _bondingCurve;
        curveParams = _curveParams;
        tokenIDFilterRoot = _tokenIDFilterRoot;
        fee = _fee;
        royaltyNumerator = _royaltyNumerator;
        rewardTokens = _rewardTokens;
        unchecked {
            for (uint256 i; i < rewardTokens.length; ++i) {
                // ensure reward token hasn't been added yet
                if (rewardTokenValid[_rewardTokens[i]]) revert RepeatedToken();
                rewardRates[_rewardTokens[i]] = _rewardRates[i];
                rewardTokenValid[_rewardTokens[i]] = true;
            }
        }
        lastUpdateTime = _startTime == 0 ? block.timestamp : _startTime;
        periodFinish = _periodFinish;
        rewardSweepTime = _periodFinish + LOCK_TIME;
    }

    /**
     * @notice Add ERC20 tokens to the pool and set the `newPeriodFinish` value of
     * the pool
     *
     * @dev new reward tokens are to be appended to inputRewardTokens
     *
     * @param inputRewardTokens An array of ERC20 tokens to recharge the pool with
     * @param inputRewardAmounts An array of the amounts of each ERC20 token to
     * recharge the pool with
     * @param _newPeriodFinish The value to update this pool's `periodFinish` variable to
     */
    function rechargeRewardVault(
        IERC20[] calldata inputRewardTokens,
        uint256[] calldata inputRewardAmounts,
        uint256 _newPeriodFinish
    ) public virtual updateReward(address(0)) {
        if (msg.sender != deployer && msg.sender != protocolOwner) revert Unauthorized();
        if (_newPeriodFinish <= block.timestamp) revert BadEndTime();
        if (block.timestamp <= periodFinish) revert RewardsOngoing();
        uint256 oldRewardTokensLength = rewardTokens.length;
        uint256 newRewardTokensLength = inputRewardTokens.length;
        if (oldRewardTokensLength > newRewardTokensLength) revert MissingExistingTokens();
        if (newRewardTokensLength > MAX_REWARD_TOKENS) revert LengthLimitExceeded();
        if (newRewardTokensLength != inputRewardAmounts.length) revert LengthMismatch();

        // Mark each ERC20 in the input as used by this pool, and ensure no
        // duplicates within the input
        uint256 newReward;
        for (uint256 i; i < newRewardTokensLength;) {
            IERC20 inputRewardToken = inputRewardTokens[i];
            // ensure same ordering for existing tokens
            if (i < oldRewardTokensLength) {
                if (inputRewardToken != rewardTokens[i]) revert TokenMismatch();
            } else {
                // adding new token
                if (rewardTokenValid[inputRewardToken]) revert RepeatedToken();
                rewardTokenValid[inputRewardToken] = true;
            }

            // note that reward amounts can be zero
            newReward = inputRewardAmounts[i];
            // pull tokens
            if (newReward > 0) {
                inputRewardToken.safeTransferFrom(msg.sender, address(this), newReward);

                // newReward = new reward rate
                newReward /= (_newPeriodFinish - block.timestamp);
                if (newReward == 0) revert ZeroRewardRate();
            }
            rewardRates[inputRewardToken] = newReward;

            unchecked {
                ++i;
            }
        }

        rewardTokens = inputRewardTokens;
        lastUpdateTime = block.timestamp;
        periodFinish = _newPeriodFinish;
        rewardSweepTime = _newPeriodFinish + LOCK_TIME;

        emit RewardVaultRecharged(inputRewardTokens, inputRewardAmounts, block.timestamp, _newPeriodFinish);
    }

    /**
     * @notice Sends all ERC20 token balances of this pool to the deployer.
     */
    function sweepRewards() external {
        if (block.timestamp < rewardSweepTime) revert TooEarly();
        emit RewardSwept();
        uint256 rewardTokensLength = rewardTokens.length;
        address _deployer = deployer;
        unchecked {
            for (uint256 i; i < rewardTokensLength; ++i) {
                IERC20 rewardToken = rewardTokens[i];
                rewardToken.safeTransfer(_deployer, rewardToken.balanceOf(address(this)));
            }
        }
    }

    function atomicPoolAndVault(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint256 _royaltyNumerator,
        address payable _royaltyRecipientOverride,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (uint256 currTokenId) {
        // create pool with empty NFTs first
        uint256[] memory _emptyInitialNFTIDs;
        address pool;

        (pool, currTokenId) = lpToken.createPoolETH{value: msg.value}(
            ICollectionPoolFactory.CreateETHPoolParams({
                nft: _nft,
                bondingCurve: _bondingCurve,
                assetRecipient: payable(0),
                receiver: msg.sender,
                poolType: ICollectionPool.PoolType.TRADE,
                delta: _delta,
                fee: _fee,
                spotPrice: _spotPrice,
                props: _props,
                state: _state,
                royaltyNumerator: _royaltyNumerator,
                royaltyRecipientOverride: _royaltyRecipientOverride,
                initialNFTIDs: _emptyInitialNFTIDs
            })
        );

        // transfer NFTs into pool
        for (uint256 i; i < _initialNFTIDs.length;) {
            _nft.safeTransferFrom(msg.sender, pool, _initialNFTIDs[i]);
            unchecked {
                ++i;
            }
        }

        stake(currTokenId);
    }

    function atomicExitAndUnpool(uint256 _tokenId) external {
        exit(_tokenId);
        lpToken.burn(_tokenId);
    }

    /**
     * @notice Add the balances of an LP token to the reward pool and mint
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward
     * pool
     * @return amount The number of tokens minted
     */
    function mint(uint256 tokenId) private returns (uint256 amount) {
        ICollectionPoolFactory _lpToken = lpToken;
        if (_lpToken.ownerOf(tokenId) != msg.sender) revert Unauthorized();

        ICollectionPoolFactory.LPTokenParams721 memory params = _lpToken.viewPoolParams(tokenId);
        ICollectionPool _pool = ICollectionPool(params.poolAddress);
        IERC721 _nft = nft;
        if (
            params.nftAddress != address(_nft) || params.bondingCurveAddress != bondingCurve
                || !validator.validate(_pool, curveParams, fee, royaltyNumerator, tokenIDFilterRoot)
        ) revert PoolMismatch();

        // Calculate the number of tokens to mint. Equal to
        // sqrt(NFT balance * ETH balance) if there's enough ETH for the pool to
        // buy at least 1 NFT. Else 0.
        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings
        uint256 amount0 = _nft.balanceOf(address(_pool));
        uint256 amount1 = address(_pool).balance;

        (,,,, uint256 bidPrice,,) = _pool.getSellNFTQuote(1);
        if (amount1 >= bidPrice) {
            amount = Math.sqrt(amount0 * amount1);
        }

        uint256 balance0 = _reserve0 + amount0;
        uint256 balance1 = _reserve1 + amount1;
        if (balance0 > type(uint128).max || balance1 > type(uint128).max) revert BalanceOverflow();

        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);
        lpTokenInfo[tokenId] = LPTokenInfo({amount0: amount0, amount1: amount1, amount: amount, owner: msg.sender});
    }

    /**
     * @notice Remove the balances of an LP token from the reward pool and burn
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward
     * pool
     * @return amount The number of lp tokens burned
     */
    function burn(uint256 tokenId) internal virtual returns (uint256 amount) {
        LPTokenInfo memory lpTokenIdInfo = lpTokenInfo[tokenId];
        if (lpTokenIdInfo.owner != msg.sender) revert Unauthorized();
        amount = lpTokenIdInfo.amount;

        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings

        reserve0 = uint128(_reserve0 - lpTokenIdInfo.amount0);
        reserve1 = uint128(_reserve1 - lpTokenIdInfo.amount1);

        delete lpTokenInfo[tokenId];
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @return The end of the period, or now if earlier
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculate the amount of `_rewardToken` rewards accrued per reward
     * token.
     * @param _rewardToken The ERC20 token to be rewarded
     * @return The amount of `_rewardToken` awardable per reward token
     *
     */
    function rewardPerToken(IERC20 _rewardToken) public view returns (uint256) {
        uint256 lastRewardTime = lastTimeRewardApplicable();
        // latter condition required because calculations will revert when called externally
        // even though internally this function will only be called if lastRewardTime > lastUpdateTime
        if (totalSupply() == 0 || lastRewardTime <= lastUpdateTime) {
            return rewardPerTokenStored[_rewardToken];
        }
        return rewardPerTokenStored[_rewardToken]
            + (((lastRewardTime - lastUpdateTime) * rewardRates[_rewardToken] * 1e18) / totalSupply());
    }

    /**
     * @notice Calculate the amount of `_rewardToken` earned by `account`
     * @dev
     *
     * @param account The account to calculate earnings for
     * @param _rewardToken The ERC20 token to calculate earnings of
     * @return The amount of ERC20 token earned
     */
    function earned(address account, IERC20 _rewardToken) public view virtual returns (uint256) {
        return balanceOf(account) * (rewardPerToken(_rewardToken) - userRewardPerTokenPaid[_rewardToken][account])
            / (1e18) + rewards[_rewardToken][account];
    }

    /**
     * @notice Stake an LP token into the reward pool
     * @param tokenId The tokenId of the LP token to stake
     * @return amount The amount of reward token minted as a result
     */
    function stake(uint256 tokenId) public virtual updateReward(msg.sender) returns (uint256 amount) {
        if (tx.origin != msg.sender) revert CallerNotEOA();
        amount = mint(tokenId);
        if (amount == 0) revert NotTwoSidedLP();

        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId, amount);
    }

    function withdraw(uint256 tokenId) public updateReward(msg.sender) {
        // amount will never be 0 because it is checked in stake()
        uint256 amount = burn(tokenId);
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId, amount);
    }

    function exit(uint256 tokenId) public {
        withdraw(tokenId);
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength;) {
            IERC20 rewardToken = rewardTokens[i];
            uint256 reward = earned(msg.sender, rewardToken);
            if (reward > 0) {
                rewards[rewardToken][msg.sender] = 0;
                emit RewardPaid(rewardToken, msg.sender, reward);
                rewardToken.safeTransfer(msg.sender, reward);
            }
            unchecked {
                ++i;
            }
        }
    }

    function getReserves() public view returns (uint128 _reserve0, uint128 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
     * @param spotPrice The current selling spot price of the pool, in tokens
     * @param delta The delta parameter of the pool, what it means depends on the curve
     * @param props The properties of the pool, what it means depends on the curve
     * @param state The state of the pool, what it means depends on the curve
     */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
     * @param trade The amount of fee to send to the pool, in tokens
     * @param protocol The amount of fee to send to the protocol, in tokens
     * @param royalties The amount to pay for each item in the order they
     * are purchased. Always has length `numItems`.
     */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
     * @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
     */
    struct FeeMultipliers {
        uint256 trade;
        uint256 protocol;
        uint256 royaltyNumerator;
        uint256 carry;
    }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta The delta value to be validated
     * @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
     * @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
     * @param newSpotPrice The new spot price to be set
     * @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
     * @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param props The props value to be validated
     * @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props) external view returns (bool valid);

    /**
     * @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param state The state value to be validated
     * @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state) external view returns (bool valid);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should pay to purchase an NFT from the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is buying from the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return inputValue The amount that the user should pay, in tokens
     * @return fees The amount of fees
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 inputValue,
            ICurve.Fees calldata fees
        );

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should receive when selling NFTs to the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is selling to the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return outputValue The amount that the user should receive, in tokens
     * @return fees The amount of fees
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface ICollectionPoolFactory is IERC721, IERC721Enumerable {
    enum PoolVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    struct LPTokenParams721 {
        address nftAddress;
        address bondingCurveAddress;
        address tokenAddress;
        address payable poolAddress;
        uint96 fee;
        uint128 delta;
        uint256 royaltyNumerator;
    }

    /**
     * @param merkleRoot Merkle root for NFT ID filter
     * @param encodedTokenIDs Encoded list of acceptable NFT IDs
     * @param initialProof Merkle multiproof for initial NFT IDs
     * @param initialProofFlags Merkle multiproof flags for initial NFT IDs
     * @param initialProofLeaves Sorted leaves of Merkle multiproof
     */
    struct NFTFilterParams {
        bytes32 merkleRoot;
        bytes encodedTokenIDs;
        bytes32[] initialProof;
        bool[] initialProofFlags;
        bytes32[] initialProofLeaves;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     *                       If set to address(0), assets will be sent to the pool address.
     *                       Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @return pool The new pool
     */
    struct CreateETHPoolParams {
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint256 royaltyNumerator;
        address payable royaltyRecipientOverride;
        uint256[] initialNFTIDs;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param token The ERC20 token used for pool swaps
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     *                         If set to address(0), assets will be sent to the pool address.
     *                         Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price, in ETH
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @param initialTokenBalance The initial token balance sent from the sender to the new pool
     * @return pool The new pool
     */
    struct CreateERC20PoolParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint256 royaltyNumerator;
        address payable royaltyRecipientOverride;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function carryFeeMultiplier() external view returns (uint256);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(CollectionRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool, PoolVariant variant) external view returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (address pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params) external returns (address pool, uint256 tokenId);

    function burn(uint256 tokenId) external;

    /**
     * @return poolParams the parameters of the pool matching `tokenId`.
     */
    function viewPoolParams(uint256 tokenId) external view returns (LPTokenParams721 memory poolParams);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {ITokenIDFilter} from "../filter/ITokenIDFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
     * @param ids The list of IDs of the NFTs to sell to the pool
     * @param proof Merkle multiproof proving list is allowed by pool
     * @param proofFlags Merkle multiproof flags for proof
     * @param proofLeaves Sorted leaves of Merkle multiproof
     */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
        bytes32[] proofLeaves;
    }

    function bondingCurve() external view returns (ICurve);

    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint96);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function spotPrice() external view returns (uint128);

    function royaltyNumerator() external view returns (uint256);

    /**
     * @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
     * @dev If the NFT is the pool's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
     * @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
     * @param a The token to transfer
     * @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 outputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        );
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface IValidator {
    /// @notice Validates if a pool fulfills the conditions of a bonding curve. The conditions can be different for each type of curve.
    function validate(
        ICollectionPool pool,
        ICurve.Params calldata params,
        uint96 fee,
        uint256 royaltyNumerator,
        bytes32 tokenIDFilterRoot
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW, // The updated spot price doesn't fit into 128 bits
        TOO_MANY_ITEMS // The value of numItems passes was too great
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

contract CollectionRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PoolSwapAny {
        CollectionPool pool;
        uint256 numItems;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        bytes32[] proofLeaves;
    }

    struct RobustPoolSwapAny {
        PoolSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecific {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPoolNFTsFoTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecific[] tokenToNFTTrades;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ICollectionPoolFactory public immutable factory;

    constructor(ICollectionPoolFactory _factory) {
        factory = _factory;
    }

    /**
     * ETH swaps
     */

    /**
     * @notice Swaps ETH into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps ETH into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForSpecificNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount = _swapETHForSpecificNFTs(
            trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient
        ) + minOutput;
    }

    /**
     * ERC20 swaps
     *
     * Note: All ERC20 swaps assume that a single ERC20 token is used for all the pools involved.
     * Swapping using multiple tokens in the same transaction is possible, but the slippage checks
     * & the return values will be meaningless, and may lead to undefined behavior.
     *
     * Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
     * swaps to work smoothly.
     */

    /**
     * @notice Swaps ERC20 tokens into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps ERC20 tokens into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps NFTs into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PoolSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount = _swapERC20ForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * Robust Swaps
     * These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
     * Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 poolCost;
        CurveErrorCodes.Error error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs{value: poolCost}(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) public payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     *
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPoolSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            uint256 poolOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCodes.Error error;
                (error,,,, poolOutput,,) = swapList[i].swapInfo.pool.getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
                if (error != CurveErrorCodes.Error.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            // If at least equal to our minOutput, proceed
            if (poolOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pool.swapNFTsForToken(
                    ICollectionPool.NFTs(
                        swapList[i].swapInfo.nftIds,
                        swapList[i].swapInfo.proof,
                        swapList[i].swapInfo.proofFlags,
                        swapList[i].swapInfo.proofLeaves
                    ),
                    0,
                    tokenRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Buys NFTs with ETH and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,,, poolCost,,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,,, poolOutput,,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags,
                            params.nftToTokenTrades[i].swapInfo.proofLeaves
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,,, poolCost,,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,,, poolOutput,,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags,
                            params.nftToTokenTrades[i].swapInfo.proofLeaves
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPool(msg.sender, variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPool(msg.sender, variant), "Not pool");

        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }

    /**
     * Internal functions
     */

    /**
     * @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
     * @notice Internal function used to swap ETH for any NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,,, poolCost,,) = swapList[i].pool.getBuyNFTQuote(swapList[i].numItems);

            // Require no error
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs{value: poolCost}(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap ETH for a specific set of NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,,, poolCost,,) = swapList[i].pool.getBuyNFTQuote(swapList[i].nftIds.length);

            // Require no errors
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs{value: poolCost}(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for any NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(PoolSwapAny[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for specific NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(PoolSwapSpecific[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
     * @dev Calling with multiple tokens is permitted, BUT minOutput will be
     * far from enough of a safety check because different tokens almost certainly have different unit prices.
     * @param swapList The list of pools and swap calldata
     * @param minOutput The minimum number of tokens to be receieved from the swaps
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(PoolSwapSpecific[] calldata swapList, uint256 minOutput, address payable tokenRecipient)
        internal
        virtual
        returns (uint256 outputAmount)
    {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pool.swapNFTsForToken(
                ICollectionPool.NFTs(
                    swapList[i].nftIds, swapList[i].proof, swapList[i].proofFlags, swapList[i].proofLeaves
                ),
                0,
                tokenRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {TokenIDFilter} from "../filter/TokenIDFilter.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title The base contract for an NFT/TOKEN AMM pool
/// @author Collection
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract CollectionPool is ReentrancyGuard, ERC1155Holder, TokenIDFilter, ICollectionPool {
    /**
     * @dev The RoyaltyDue struct is used to track information about royalty payments that are due on NFT swaps.
     * It contains two fields:
     * @dev amount: The amount of the royalty payment, in the token's base units.
     * This value is calculated based on the price of the NFT being swapped, and the royaltyNumerator value set in the AMM pool contract.
     * @dev recipient: The address to which the royalty payment should be sent.
     * This value is determined by the NFT being swapped, and it is specified in the ERC2981 metadata for the NFT.
     * @dev When a user swaps an NFT for tokens using the AMM pool contract, a RoyaltyDue struct is created to track the amount
     * and recipient of the royalty payment that is due on the NFT swap. This struct is then used to facilitate the payment of
     * the royalty to the appropriate recipient.
     */
    struct RoyaltyDue {
        uint256 amount;
        address recipient;
    }

    /**
     * @dev The _INTERFACE_ID_ERC2981 constant specifies the interface ID for the ERC2981 standard. This standard is used for tracking
     * royalties on non-fungible tokens (NFTs). It defines a standard interface for NFTs that includes metadata about the royalties that
     * are due on the NFT when it is swapped or transferred.
     * @dev The _INTERFACE_ID_ERC2981 constant is used in the AMM pool contract to check whether an NFT being swapped implements the ERC2981
     * standard. If it does, the contract can use the metadata provided by the ERC2981 interface to facilitate the payment of royalties on the
     * NFT swap. If the NFT does not implement the ERC2981 standard, the contract will not track or pay royalties on the NFT swap.
     * This can be overridden by the royaltyNumerator field in the AMM pool contract.
     * @dev For more information about the ERC2981 standard, see https://eips.ethereum.org/EIPS/eip-2981
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev The MAX_FEE constant specifies the maximum fee you, the user, are allowed to charge for this AMM pool.
     * It is used to limit the amount of fees that can be charged by the AMM pool contract on NFT/token swaps.
     * @dev The MAX_FEE constant is used to ensure that the AMM pool does not charge excessive fees on NFT/token swaps.
     * It also helps to protect users from paying excessive fees when using the AMM pool contract.
     * @dev usage: 90%, must <= 1 - MAX_PROTOCOL_FEE (set in CollectionPoolFactory)
     * @dev If the bid/ask is 9/10 and the fee is set to 1%, then the fee is calculated as follows:
     * @dev For a buy order, the fee would be the bid price multiplied by the fee rate, or 9 * 1% = 0.09
     * @dev For a sell order, the fee would be the ask price multiplied by the fee rate, or 10 * 1% = 0.1
     * @dev The fee is charged as a percentage of the bid/ask price, and it is used to cover the costs associated with running the AMM pool
     * contract and providing liquidity to the decentralized exchange. The fee is deducted from the final price of the token or NFT swap,
     * and it is paid to the contract owner or to a designated fee recipient. The exact fee rate and fee recipient can be configured by the
     * contract owner when the AMM pool contract is deployed.
     */
    uint256 internal constant MAX_FEE = 0.9e18;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 public spotPrice;

    // The parameter for the pool's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 public delta;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e18
    uint96 public fee;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pool.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // The trade fee accrued from trades.
    uint256 public tradeFee;

    // The properties used by the pool's bonding curve.
    bytes public props;

    // The state used by the pool's bonding curve.
    bytes public state;

    // For every NFT swapped, a fraction of the cost will be sent to the
    // ERC2981 payable address for the NFT swapped. The fraction is equal to
    // `royaltyNumerator / 1e18`
    uint256 public royaltyNumerator;

    // An address to which all royalties will be paid to if not address(0). This
    // overrides ERC2981 royalties set by the NFT creator, and allows sending
    // royalties to arbitrary addresses even if a collection does not support ERC2981.
    address payable public royaltyRecipientOverride;
    // token ID assigned to the pool instance
    uint256 public tokenId;

    // creation timestamp, to prevent trades in the same time / block as pool creation
    uint256 private creationTimestamp;

    // Events
    event SwapNFTInPool();
    event SwapNFTOutPool();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(uint256 amount);
    event TokenWithdrawal(uint256 amount);
    event NFTWithdrawal();
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);
    event PropsUpdate(bytes newProps);
    event StateUpdate(bytes newState);
    event RoyaltyNumeratorUpdate(uint256 newRoyaltyNumerator);
    event RoyaltyRecipientOverrideUpdate(address payable newOverride);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    /**
     * @dev Use this whenever modifying the value of royaltyNumerator.
     */
    modifier validRoyaltyNumerator(uint256 _royaltyNumerator) {
        require(_royaltyNumerator < 1e18, "royaltyNumerator must be < 1e18");
        _;
    }

    /**
     * Ownable functions
     */

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return IERC721(address(factory())).ownerOf(tokenId);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner(), "not authorized");
        _;
    }

    /// @dev Throws if called by accounts that were not authorized by the owner.
    modifier onlyAuthorized() {
        factory().requireAuthorizedForToken(msg.sender, tokenId);
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        IERC721(address(factory())).safeTransferFrom(msg.sender, newOwner, tokenId);
    }

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _tokenId The token id of the pool
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param _royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     */
    function initialize(
        uint256 _tokenId,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint256 _royaltyNumerator,
        address payable _royaltyRecipientOverride
    ) external payable validRoyaltyNumerator(_royaltyNumerator) {
        require(tokenId == 0, "Initialized");
        tokenId = _tokenId;
        creationTimestamp = block.timestamp;
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            require(_fee == 0, "Only Trade Pools can have nonzero fee");
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            require(_fee < MAX_FEE, "Trade fee must be less than 90%");
            require(_assetRecipient == address(0), "Trade pools can't set asset recipient");
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(_bondingCurve.validateSpotPrice(_spotPrice), "Invalid new spot price for curve");
        require(_bondingCurve.validateProps(_props), "Invalid props for curve");
        require(_bondingCurve.validateState(_state), "Invalid state for curve");
        delta = _delta;
        spotPrice = _spotPrice;
        props = _props;
        state = _state;
        royaltyNumerator = _royaltyNumerator;
        royaltyRecipientOverride = _royaltyRecipientOverride;
    }

    /**
     * External state-changing functions
     */

    /**
     * @notice Sets NFT token ID filter that is allowed in this pool
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external {
        require(msg.sender == address(factory()) || msg.sender == owner(), "not authorized");
        _setRootAndEmitAcceptedIDs(address(nft()), merkleRoot, encodedTokenIDs);
    }

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        IERC721 _nft = nft();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require((numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))), "Ask for > 0 and <= balanceOf NFTs");
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) =
            _calculateBuyInfoAndUpdatePoolParams(numNFTs, maxExpectedTokenInput, _bondingCurve, _factory);

        tradeFee += fees.trade;
        uint256[] memory tokenIds = _selectArbitraryNFTs(_nft, numNFTs);
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(_nft, tokenIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, fees.protocol, royaltiesDue);

        _sendSpecificNFTsToRecipient(_nft, nftRecipient, tokenIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
     * @notice Sends token to the pool in exchange for a specific set of NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. Also higher chance of
     * reverting if some of the specified IDs leave the pool before the swap goes through.
     * @param nftIds The list of IDs of the NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) =
            _calculateBuyInfoAndUpdatePoolParams(nftIds.length, maxExpectedTokenInput, _bondingCurve, _factory);

        tradeFee += fees.trade;
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nftIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, fees.protocol, royaltiesDue);

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        ICollectionPool.NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual nonReentrant returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.TOKEN || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(nfts.ids.length > 0, "Must ask for > 0 NFTs");
            require(acceptsTokenIDs(nfts.proof, nfts.proofFlags, nfts.proofLeaves), "NFT not allowed");
        }

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (outputAmount, fees) =
            _calculateSellInfoAndUpdatePoolParams(nfts.ids.length, minExpectedTokenOutput, _bondingCurve);

        // Accrue trade fees before sending token output. This ensures that the balance is always sufficient for trade fee withdrawal.
        tradeFee += fees.trade;

        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nfts.ids, fees.royalties);

        _sendTokenOutput(tokenRecipient, outputAmount, royaltiesDue);

        _payProtocolFeeFromPool(_factory, fees.protocol);

        _takeNFTsFromSender(nft(), nfts.ids, _factory, isRouter, routerCaller);

        emit SwapNFTInPool();
    }

    /**
     * View functions
     */

    /**
     * @notice Checks if NFTs is allowed in this pool
     * @param tokenID NFT ID
     * @param proof Merkle proof
     */
    function acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) public view returns (bool) {
        return _acceptsTokenID(tokenID, proof);
    }

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     * @param leaves The leaves of the merkle tree in sorted order
     */
    function acceptsTokenIDs(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] calldata leaves)
        public
        view
        returns (bool)
    {
        return _acceptsTokenIDs(proof, proofFlags, leaves);
    }

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 inputAmount,
            uint256 _tradeFee,
            uint256 protocolFee
        )
    {
        ICurve.Params memory newParams;
        ICurve.Fees memory fees;
        (error, newParams, inputAmount, fees) = bondingCurve().getBuyInfo(curveParams(), numNFTs, feeMultipliers());

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
     * @dev Used as read function to query the bonding curve for sell pricing info
     * @param numNFTs The number of NFTs to sell to the pool
     */
    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 outputAmount,
            uint256 _tradeFee,
            uint256 protocolFee
        )
    {
        ICurve.Params memory newParams;
        ICurve.Fees memory fees;
        (error, newParams, outputAmount, fees) = bondingCurve().getSellInfo(curveParams(), numNFTs, feeMultipliers());

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
     * @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
     * @notice Returns the pool's variant (NFT is enumerable or not, pool uses ETH or ERC20)
     */
    function poolVariant() public pure virtual returns (ICollectionPoolFactory.PoolVariant);

    function factory() public pure returns (ICollectionPoolFactory _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(0x60, calldataload(sub(calldatasize(), paramsLength)))
        }
    }

    /**
     * @notice Returns the type of bonding curve that parameterizes the pool
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 20)))
        }
    }

    /**
     * @notice Returns the NFT collection that parameterizes the pool
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 40)))
        }
    }

    /**
     * @notice Returns the pool's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(0xf8, calldataload(add(sub(calldatasize(), paramsLength), 60)))
        }
    }

    /**
     * @notice Handles royalty recipient and fallback logic. Attempts to honor
     * ERC2981 where possible, followed by the owner's set fallback. If neither
     * is a valid address, then royalties go to the asset recipient for this
     * pool.
     * @param erc2981Recipient The address to which royalties should be paid as
     * returned by the IERC2981 `royaltyInfo` method. `payable(address(0))` if
     * the nft does not implement IERC2981.
     * @return The address to which royalties should be paid
     */
    function getRoyaltyRecipient(address payable erc2981Recipient) internal view returns (address payable) {
        if (erc2981Recipient != address(0)) {
            return erc2981Recipient;
        }

        // No recipient from ERC2981 royaltyInfo method. Check if we have a fallback
        if (royaltyRecipientOverride != address(0)) {
            return royaltyRecipientOverride;
        }

        // No ERC2981 recipient or recipient fallback. Default to pool.
        return getAssetRecipient();
    }

    /**
     * @notice Returns the address that assets that receives assets when a swap is done with this pool
     * Can be set to another address by the owner, if set to address(0), defaults to the pool's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    function curveParams() public view returns (ICurve.Params memory params) {
        return ICurve.Params(spotPrice, delta, props, state);
    }

    function feeMultipliers() public view returns (ICurve.FeeMultipliers memory) {
        uint256 protocolFeeMultiplier;
        uint256 carryFeeMultiplier;

        PoolType _poolType = poolType();
        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            protocolFeeMultiplier = factory().protocolFeeMultiplier();
        } else if (_poolType == PoolType.TRADE) {
            carryFeeMultiplier = factory().carryFeeMultiplier();
        }

        return ICurve.FeeMultipliers(fee, protocolFeeMultiplier, royaltyNumerator, carryFeeMultiplier);
    }

    /**
     * Internal functions
     */

    /**
     * @notice Calculates the amount needed to be sent into the pool for a buy and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to purchase from the pool
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @return inputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ICollectionPoolFactory
    ) internal returns (uint256 inputAmount, ICurve.Fees memory fees) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, inputAmount, fees) = _bondingCurve.getBuyInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Calculates the amount needed to be sent by the pool for a sell and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to send to the the pool
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param _bondingCurve The bonding curve used to fetch pricing information from
     * @return outputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve
    ) internal returns (uint256 outputAmount, ICurve.Fees memory fees) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, outputAmount, fees) = _bondingCurve.getSellInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(outputAmount >= minExpectedTokenOutput, "Out too little tokens");

        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Pulls the token input of a trade from the trader and pays the protocol fee.
     * @param inputAmount The amount of tokens to be sent
     * @param isRouter Whether or not the caller is CollectionRouter
     * @param routerCaller If called from CollectionRouter, store the original caller
     * @param _factory The CollectionPoolFactory which stores CollectionRouter allowlist info
     * @param protocolFee The protocol fee to be paid
     * @param royaltyAmounts An array of royalties to pay
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltyAmounts
    ) internal virtual;

    /**
     * @notice Sends excess tokens back to the caller (if applicable)
     * @dev We send ETH back to the caller even when called from CollectionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller)
     * Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
     * @notice Sends protocol fee (if it exists) back to the CollectionPoolFactory from the pool
     */
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal virtual;

    /**
     * @notice Sends tokens to a recipient and pays royalties owed
     * @param tokenRecipient The address receiving the tokens
     * @param outputAmount The amount of tokens to send
     * @param royaltiesDue An array of royalties to pay
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        virtual;

    /**
     * @notice Select arbitrary NFTs from pool
     * @param _nft The address of the NFT to send
     * @param numNFTs The number of NFTs to send
     */
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs) internal virtual returns (uint256[] memory tokenIds);

    /**
     * @notice Sends specific NFTs to a recipient address
     * @dev Even though we specify the NFT address here, this internal function is only
     * used to send NFTs associated with this specific pool.
     * @param _nft The address of the NFT to send
     * @param nftRecipient The receiving address for the NFTs
     * @param nftIds The specific IDs of NFTs to send
     */
    function _sendSpecificNFTsToRecipient(IERC721 _nft, address nftRecipient, uint256[] memory nftIds)
        internal
        virtual;

    /**
     * @notice Takes NFTs from the caller and sends them into the pool's asset recipient
     * @dev This is used by the CollectionPool's swapNFTForToken function.
     * @param _nft The NFT collection to take from
     * @param nftIds The specific NFT IDs to take
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     */
    function _takeNFTsFromSender(
        IERC721 _nft,
        uint256[] calldata nftIds,
        ICollectionPoolFactory _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                CollectionRouter router = CollectionRouter(payable(msg.sender));
                (bool routerAllowed,) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs;) {
                        router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[i], poolVariant());

                        unchecked {
                            ++i;
                        }
                    }
                    require((_nft.balanceOf(_assetRecipient) - beforeBalance) == numNFTs, "NFTs not transferred");
                } else {
                    router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[0], poolVariant());
                    require(_nft.ownerOf(nftIds[0]) == _assetRecipient, "NFT not transferred");
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs;) {
                    _nft.safeTransferFrom(msg.sender, _assetRecipient, nftIds[i]);

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @dev Used internally to grab pool parameters from calldata, see CollectionPoolCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /**
     * @notice Rescues ERC1155 tokens from the pool to the owner. Only callable by the owner.
     * @param a The NFT to transfer
     * @param ids The NFT ids to transfer
     * @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external onlyAuthorized {
        a.safeBatchTransferFrom(address(this), owner(), ids, amounts, "");
    }

    /**
     * @notice Withdraws trade fee owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawTradeFee() external virtual;

    /**
     * @notice Updates the selling spot price. Only callable by the owner.
     * @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateSpotPrice(newSpotPrice), "Invalid new spot price for curve");
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
     * @notice Updates the delta parameter. Only callable by the owner.
     * @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateDelta(newDelta), "Invalid delta for curve");
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
     * @notice Updates the props parameter. Only callable by the owner.
     * @param newProps The new props parameter
     */
    function changeProps(bytes calldata newProps) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateProps(newProps), "Invalid props for curve");
        if (keccak256(props) != keccak256(newProps)) {
            props = newProps;
            emit PropsUpdate(newProps);
        }
    }

    /**
     * @notice Updates the state parameter. Only callable by the owner.
     * @param newState The new state parameter
     */
    function changeState(bytes calldata newState) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateState(newState), "Invalid state for curve");
        if (keccak256(state) != keccak256(newState)) {
            state = newState;
            emit StateUpdate(newState);
        }
    }

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint96 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType == PoolType.TRADE, "Only for Trade pools");
        require(newFee < MAX_FEE, "Trade fee must be less than 90%");
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
     * @notice Changes the address that will receive assets received from
     * trades. Only callable by the owner.
     * @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    function changeRoyaltyNumerator(uint256 newRoyaltyNumerator)
        external
        onlyOwner
        validRoyaltyNumerator(newRoyaltyNumerator)
    {
        require(
            _validRoyaltyState(newRoyaltyNumerator, royaltyRecipientOverride, nft()),
            "Invalid royaltyNumerator or royaltyRecipientOverride"
        );
        royaltyNumerator = newRoyaltyNumerator;
        emit RoyaltyNumeratorUpdate(newRoyaltyNumerator);
    }

    function changeRoyaltyRecipientOverride(address payable newOverride) external onlyOwner {
        require(
            _validRoyaltyState(royaltyNumerator, newOverride, nft()),
            "Invalid royaltyNumerator or royaltyRecipientOverride"
        );
        royaltyRecipientOverride = newOverride;
        emit RoyaltyRecipientOverrideUpdate(newOverride);
    }

    /**
     * @notice Allows the pool to make arbitrary external calls to contracts
     * whitelisted by the protocol. Only callable by authorized parties.
     * @param target The contract to call
     * @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data) external onlyAuthorized {
        ICollectionPoolFactory _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result,) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
     * @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     * @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
     * @param calls The calldata for each call to make
     * @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail) external onlyAuthorized {
        for (uint256 i; i < calls.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(owner() == msg.sender, "Ownership cannot be changed in multicall");
    }

    /**
     * @param _returnData The data returned from a multicall result
     * @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getRoyaltiesDue(IERC721 _nft, uint256[] memory nftIds, uint256[] memory royaltyAmounts)
        private
        view
        returns (RoyaltyDue[] memory royaltiesDue)
    {
        uint256 length = royaltyAmounts.length;
        royaltiesDue = new RoyaltyDue[](length);
        bool is2981 = IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981);
        if (royaltyNumerator != 0) {
            for (uint256 i = 0; i < length;) {
                // 2981 recipient, if nft is 2981 and recipient is set.
                address recipient2981;
                if (is2981) {
                    (recipient2981,) = IERC2981(address(_nft)).royaltyInfo(nftIds[i], 0);
                }

                address recipient = getRoyaltyRecipient(payable(recipient2981));
                royaltiesDue[i] = RoyaltyDue({amount: royaltyAmounts[i], recipient: recipient});

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Returns true if it's valid to set the contract variables to the
     * variables passed to this function.
     */
    function _validRoyaltyState(uint256 _royaltyNumerator, address payable _royaltyRecipientOverride, IERC721 _nft)
        internal
        view
        returns (bool)
    {
        return
        // Supports 2981 interface to tell us who gets royalties or
        (
            IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981)
            // There is an override so we always know where to send royaltiers or
            || _royaltyRecipientOverride != address(0)
            // Royalties will not be paid
            || _royaltyNumerator == 0
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
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
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
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
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
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
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// to use a custom error

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error Reentrancy();

    function __ReentrancyGuard_init() internal {
      _status = _NOT_ENTERED;
    } 

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ITokenIDFilter} from "./ITokenIDFilter.sol";

contract TokenIDFilter is ITokenIDFilter {
    event AcceptsTokenIDs(address indexed _collection, bytes32 indexed _root, bytes _data);

    // Merkle root
    bytes32 public tokenIDFilterRoot;

    uint32[999] _padding;

    function _setRootAndEmitAcceptedIDs(address collection, bytes32 root, bytes calldata data) internal {
        tokenIDFilterRoot = root;
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) internal view returns (bool) {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        // double hash to prevent second preimage attack
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenID)))));

        return MerkleProof.verifyCalldata(proof, tokenIDFilterRoot, leaf);
    }

    function _emitTokenIDs(address collection, bytes calldata data) internal {
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenIDs(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] calldata leaves)
        internal
        view
        returns (bool)
    {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        uint256 length = leaves.length;
        bytes32[] memory hashedLeaves = new bytes32[](length);

        for (uint256 i; i < length;) {
            // double hash to prevent second preimage attack
            hashedLeaves[i] = keccak256(abi.encodePacked(keccak256(abi.encodePacked((leaves[i])))));
            unchecked {
                ++i;
            }
        }

        return MerkleProof.multiProofVerify(proof, proofFlags, tokenIDFilterRoot, hashedLeaves);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}