// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseLockdrop.sol";
import "../external/IPoolsController.sol";
import "../external/IPositionManager.sol";

/**
 * @title AtlendisLockdrop
 * @notice Lockdrop contract designed to rewards users that lock their Atlendis
 * positions for a given duration with a corresponding amount of tokens
 **/
contract AtlendisLockdrop is BaseLockdrop {
    using SafeERC20 for ERC20;

    ////////////
    // EVENTS //
    ////////////

    event LockdropCreated(
        address poolsContract,
        address positionsContract,
        bytes32 poolHash,
        uint256 maxMultiplier,
        uint256 minLockingPeriod,
        uint256 maxLockingPeriod,
        uint256 minPositionAmount
    );
    event RateUpdated(uint256 tokenId, address from, uint256 newRate);

    /////////////
    // STORAGE //
    /////////////

    bytes32 private immutable poolHash; // a lockdrop is specific to an Atlendis pool
    uint256 private immutable minPositionAmount; // positions must have a minimum underlying token value
    address private immutable poolsController; // address of Atlendis' pools contract

    /////////////////
    // CONSTRUCTOR //
    /////////////////

    constructor(
        address _poolsController,
        address _positionManager,
        bytes32 _poolHash,
        uint256 _maxMultiplier,
        uint256 _minLockingPeriod,
        uint256 _maxLockingPeriod,
        uint256 _minPositionAmount
    )
        BaseLockdrop(
            _positionManager,
            _maxMultiplier,
            _minLockingPeriod,
            _maxLockingPeriod
        )
    {
        require(_poolHash != "", "Wrong pool input");

        poolHash = _poolHash;
        minPositionAmount = _minPositionAmount;
        poolsController = _poolsController;

        (address underlyingToken, , , , , , , , , , ) = IPoolsController(
            poolsController
        ).getPoolParameters(poolHash);
        require(underlyingToken != address(0), "Target pool does not exist");

        emit LockdropCreated(
            _poolsController,
            _positionManager,
            _poolHash,
            _maxMultiplier,
            _minLockingPeriod,
            _maxLockingPeriod,
            _minPositionAmount
        );
    }

    /////////////////////////
    // POSITION MANAGEMENT //
    /////////////////////////

    /**
     * @notice Update the rate of the underlying Atlendis position
     **/
    function updateRate(uint256 tokenId, uint256 newRate)
        external
        isLockOwner(tokenId)
    {
        IPositionManager(nft).updateRate(uint128(tokenId), uint128(newRate));

        emit RateUpdated(tokenId, _msgSender(), newRate);
    }

    ///////////////
    // OVERRIDES //
    ///////////////

    /**
     * @notice Get back remaining rewards
     * Owner can get back remaining rewards
     * Rescueing rewards lets users claim their pending rewards
     * Users won't be able to use lock positions anymore
     **/
    function rescueRewards(address to) external override onlyOwner {
        uint256[] memory toRescue = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            toRescue[i] =
                ERC20(tokens[i]).balanceOf(address(this)) -
                pendingRewards[tokens[i]];
            ERC20(tokens[i]).safeTransfer(_msgSender(), toRescue[i]);
        }

        emit RewardsRescued(to, toRescue);
    }

    /**
     * @notice Locking logic
     * Implementation of _lock function to take into account Atlendis' specific use case
     * Verifies that the position complies with the lockdrop conditions
     * Computes the rewards and transfers the nft to the lockdrop contract
     **/
    function _lock(
        uint256 tokenId,
        uint256[] memory baseAllocations,
        uint256 lockingDuration
    ) internal override {
        (
            uint128 bondsQuantity,
            uint128 normalizedDepositedAmount
        ) = IPositionManager(nft).getPositionRepartition(uint128(tokenId));
        require(
            (bondsQuantity + normalizedDepositedAmount) > minPositionAmount,
            "Unsufficient position size"
        );
        (bytes32 _poolHash, , , , , , ) = IPositionManager(nft).position(
            uint128(tokenId)
        );
        require(_poolHash == poolHash, "Wrong pool hash");
        currentLocks[tokenId].owner = _msgSender();
        currentLocks[tokenId].endDate = block.timestamp + lockingDuration;
        uint256[] memory rewards = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 reward = _getRewardsAmount(
                baseAllocations[i],
                lockingDuration,
                tokenId,
                tokens[i]
            );
            require(
                ERC20(tokens[i]).balanceOf(address(this)) >=
                    (pendingRewards[tokens[i]] + reward),
                "Not enough rewards left to distribute"
            );
            pendingRewards[tokens[i]] += reward;
            currentLocks[tokenId].rewards[tokens[i]] = reward;
            rewards[i] = reward;
        }
        ERC721(nft).transferFrom(_msgSender(), address(this), tokenId);
        emit Locked(
            tokenId,
            bondsQuantity + normalizedDepositedAmount,
            lockingDuration,
            _msgSender(),
            baseAllocations,
            rewards
        );
    }

    /**
     * @notice Computes token rewards amount
     * Implementation to comply with Atlendis' specific use case
     **/
    function _getRewardsAmount(
        uint256 baseAmount,
        uint256 lockingDuration,
        uint256 tokenId,
        address token
    ) internal view override returns (uint256) {
        (
            uint128 bondsQuantity,
            uint128 normalizedDepositedAmount
        ) = IPositionManager(nft).getPositionRepartition(uint128(tokenId));
        uint256 positionAmount = uint256(
            bondsQuantity + normalizedDepositedAmount
        );
        uint256 multiplier = _getMultiplier(lockingDuration, tokenId);
        uint256 baseAllocation = (baseAmount * multiplier) / baseMultiplier;
        uint256 rewardsAmount = (positionAmount *
            tokenParameters[token].rate * // rate is in token per second and inherits its precision
            lockingDuration *
            multiplier) /
            baseMultiplier /
            1e18; // getPositionRepartition always returns wad precision
        return baseAllocation + rewardsAmount;
    }

    /**
     * @notice Computes token rewards multiplier
     * Implementation to comply with Atlendis' specific use case
     * the longer the lock, the bigger the reward
     **/
    function _getMultiplier(uint256 lockingDuration, uint256)
        internal
        view
        override
        returns (uint256 multiplier)
    {
        return
            baseMultiplier +
            ((maxMultiplier - baseMultiplier) *
                (lockingDuration - minLockingPeriod)) /
            (maxLockingPeriod - minLockingPeriod);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title BaseLockdrop
 * @notice Lockdrop contract designed to rewards users that lock their NFTs
 * for a given time with a corresponding amount of tokens
 **/
abstract contract BaseLockdrop is Ownable {
    using SafeERC20 for ERC20;

    ////////////
    // EVENTS //
    ////////////

    event Locked(
        uint256 tokenId,
        uint256 amount,
        uint256 lockDuration,
        address from,
        uint256[] baseAllocations,
        uint256[] rewards
    );
    event Quit(uint256 tokenId, uint256 lockEnd, address from);
    event Claimed(
        uint256 tokenId,
        uint256 lockEnd,
        address from,
        uint256[] rewards
    );
    event Withdrawn(
        uint256 tokenId,
        uint256 lockEnd,
        address from,
        uint256[] rewards
    );
    event TokenAdded(address token, uint256 rate, bytes32 root);
    event RootSet(address token, bytes32 root);
    event RewardsRescued(address to, uint256[] amounts);

    /////////////
    // STORAGE //
    /////////////

    // lock parameters
    address public immutable nft; // address of the nft to lock
    uint256 public immutable baseMultiplier = 1e18; // 1
    uint256 public immutable maxMultiplier;
    uint256 public immutable minLockingPeriod;
    uint256 public immutable maxLockingPeriod;

    // tokens
    address[] public tokens; // token rewards addresses
    struct TokenParameters {
        uint256 rate; // base tokens per nft value unit per second of locking
        bytes32 root; // merkle tree root used for base token allocations
    }
    mapping(address => TokenParameters) public tokenParameters;

    // contract state
    mapping(address => uint256) public pendingRewards; // rewards attributed to currently locked positions
    struct LockDrop {
        address owner;
        mapping(address => uint256) rewards;
        uint256 endDate;
        bool claimed;
        bool withdrawn;
    }
    mapping(uint256 => LockDrop) internal currentLocks;
    mapping(bytes32 => bool) public claimedAllocations; // base allocations can only be claimed once

    /////////////////
    // CONSTRUCTOR //
    /////////////////

    constructor(
        address _nft,
        uint256 _maxMultiplier,
        uint256 _minLockingPeriod,
        uint256 _maxLockingPeriod
    ) {
        require(
            _minLockingPeriod < _maxLockingPeriod,
            "Wrong locking periods input"
        );
        require(
            _maxMultiplier >= baseMultiplier,
            "Max multiplier must be greater or equal than base multiplier"
        );
        require(_nft != address(0), "Wrong nft address");
        nft = _nft;
        maxMultiplier = _maxMultiplier;
        minLockingPeriod = _minLockingPeriod;
        maxLockingPeriod = _maxLockingPeriod;
    }

    ///////////////
    // MODIFIERS //
    ///////////////

    /**
     * @notice Position lock ownership verification logic
     **/
    modifier isLockOwner(uint256 tokenId) {
        require(
            _msgSender() == currentLocks[tokenId].owner,
            "Caller is not the owner of the lock"
        );
        _;
    }

    /**
     * @notice Lock validity verification logic
     **/
    modifier validLock(uint256 lockingDuration) {
        require(
            (lockingDuration <= maxLockingPeriod) &&
                (lockingDuration >= minLockingPeriod),
            "Wrong locking duration"
        );
        require(tokens.length > 0, "No token is registered");
        _;
    }

    ///////////
    // VIEWS //
    ///////////

    /**
     * @notice Get lock for target tokenId
     **/
    function getLockParameters(uint256 tokenId)
        external
        view
        returns (
            address,
            uint256,
            bool
        )
    {
        return (
            currentLocks[tokenId].owner,
            currentLocks[tokenId].endDate,
            currentLocks[tokenId].claimed
        );
    }

    /**
     * @notice Get lock rewards for target tokenId and reward token address
     **/
    function getLockRewards(uint256 tokenId, address _token)
        external
        view
        returns (uint256)
    {
        return currentLocks[tokenId].rewards[_token];
    }

    /**
     * @notice Preview rewards for upcoming lock
     **/
    function previewRewards(
        uint256 baseAmount,
        uint256 tokenId,
        uint256 lockingDuration,
        address token
    ) external view returns (uint256 rewards) {
        require(
            (lockingDuration <= maxLockingPeriod) &&
                (lockingDuration >= minLockingPeriod),
            "Wrong locking duration"
        );
        require(tokens.length > 0, "No token is registered");
        require(tokenParameters[token].rate > 0, "Token not registered");
        rewards = _getRewardsAmount(
            baseAmount,
            lockingDuration,
            tokenId,
            token
        );
        require(
            ERC20(token).balanceOf(address(this)) >
                (pendingRewards[token] + rewards),
            "Not enough rewards left to distribute"
        );
    }

    ////////////
    // OWNER  //
    ////////////

    /**
     * @notice Add new token reward
     * Owner can add new types of token rewards
     * Distribution can begin after the lockdrop contract is sent tokens to distribute
     **/
    function addToken(
        address token,
        uint256 rate,
        bytes32 root
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != token, "Token already supported");
        }
        tokens.push(token);
        tokenParameters[token] = TokenParameters({rate: rate, root: root});

        emit TokenAdded(token, rate, root);
    }

    /**
     * @notice Set token base allocation merkle root
     * Owner can set base allocation merkle root for a token
     * Can only be done if root was set to 0 beforehand
     **/
    function setRoot(address token, bytes32 root) external onlyOwner {
        require(
            tokenParameters[token].root == bytes32(0),
            "Root has already been set"
        );

        tokenParameters[token].root = root;

        emit RootSet(token, root);
    }

    /**
     * @notice Get back remaining rewards
     * Owner can get back remaining rewards in some circumstances
     * This function must be overidden to specify conditions for the target use case
     **/
    function rescueRewards(address to) external virtual;

    /////////////
    // LOCKING //
    /////////////

    /**
     * @notice Lock without base allocation
     * A user locks its nft in exchange for future rewards
     * The longer the user locks its position, the bigger the rewards
     **/
    function lock(uint256 tokenId, uint256 lockingDuration)
        external
        validLock(lockingDuration)
    {
        uint256[] memory noAllocations = new uint256[](tokens.length);
        _lock(tokenId, noAllocations, lockingDuration);
    }

    /**
     * @notice Lock with base allocation
     * A merkle tree root is specified at deployment time including base token allocations
     * These allocations serve as a base amount to compute future rewards
     * Base allocations benefit from multipliers
     **/
    function lock(
        bytes32[][] calldata proofs,
        uint256[] memory baseAllocations,
        uint256 tokenId,
        uint256 lockingDuration
    ) external validLock(lockingDuration) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (baseAllocations[i] > 0) {
                bytes32 leaf = keccak256(
                    abi.encode(_msgSender(), baseAllocations[i])
                );
                require(
                    !claimedAllocations[leaf],
                    "Base allocation already claimed"
                );
                require(
                    MerkleProof.verify(
                        proofs[i],
                        tokenParameters[tokens[i]].root,
                        leaf
                    ),
                    "Proof is not valid"
                );
                claimedAllocations[leaf] = true; // claimed allocations that are quitted cannot be claimed again
            }
        }
        _lock(tokenId, baseAllocations, lockingDuration);
    }

    ///////////////
    // RELEASING //
    ///////////////

    /**
     * @notice Stops lock before maturity, renouncing to rewards
     **/
    function quit(uint256 tokenId) external virtual isLockOwner(tokenId) {
        require(
            block.timestamp < currentLocks[tokenId].endDate,
            "Quit too late"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            pendingRewards[tokens[i]] -= currentLocks[tokenId].rewards[
                tokens[i]
            ];
            currentLocks[tokenId].rewards[tokens[i]] = 0;
        }
        uint256 endDate = currentLocks[tokenId].endDate;
        delete currentLocks[tokenId];

        ERC721(nft).transferFrom(address(this), _msgSender(), tokenId);

        emit Quit(tokenId, endDate, _msgSender());
    }

    /**
     * @notice Withdraw locked nft
     * Sends back nft after the lock is successfully completed
     * A lock is considered final when both token is withdrawn and rewards are claimed
     * Logic can be modified by inheriting contracts
     **/
    function withdraw(uint256 tokenId) public virtual isLockOwner(tokenId) {
        require(
            block.timestamp >= currentLocks[tokenId].endDate,
            "Withdraw too early"
        );

        uint256[] memory rewards = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rewards[i] = currentLocks[tokenId].rewards[tokens[i]];
            if (currentLocks[tokenId].claimed)
                currentLocks[tokenId].rewards[tokens[i]] = 0;
        }
        uint256 endDate = currentLocks[tokenId].endDate;
        // lock rewards were already claimed
        if (currentLocks[tokenId].claimed) {
            delete currentLocks[tokenId];
        } else {
            currentLocks[tokenId].withdrawn = true;
        }

        ERC721(nft).transferFrom(address(this), _msgSender(), tokenId);

        emit Withdrawn(tokenId, endDate, _msgSender(), rewards);
    }

    /**
     * @notice Claim lock rewards
     * Send token rewards after a lock is successfully completed
     * A lock is considered final when both token is withdrawn and rewards are claimed
     * Logic can be modified by inheriting contracts
     **/
    function claim(uint256 tokenId) public virtual isLockOwner(tokenId) {
        require(
            block.timestamp >= currentLocks[tokenId].endDate,
            "Claim too early"
        );
        require(!currentLocks[tokenId].claimed, "Lock already claimed");

        bool toDelete = currentLocks[tokenId].withdrawn;
        uint256[] memory rewards = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            pendingRewards[tokens[i]] -= currentLocks[tokenId].rewards[
                tokens[i]
            ];
            rewards[i] = currentLocks[tokenId].rewards[tokens[i]];
            if (toDelete) currentLocks[tokenId].rewards[tokens[i]] = 0;
        }
        uint256 endDate = currentLocks[tokenId].endDate;
        // locked token was already withdrawn
        if (toDelete) {
            delete currentLocks[tokenId];
        } else {
            currentLocks[tokenId].claimed = true;
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20(tokens[i]).safeTransfer(_msgSender(), rewards[i]);
        }
        emit Claimed(tokenId, endDate, _msgSender(), rewards);
    }

    /**
     * @notice Claim lock rewards and withdraw position
     * Helper method to do both actions in the same transaction
     **/
    function claimAndWithdraw(uint256 tokenId) external {
        claim(tokenId);
        withdraw(tokenId);
    }

    //////////////////////////////
    // INTERNAL VIRTUAL METHODS //
    //////////////////////////////

    /**
     * @notice Internal lock logic
     * Computes rewards, gets target position and saves data for future position releasing
     **/
    function _lock(
        uint256 tokenId,
        uint256[] memory baseAllocations,
        uint256 lockingDuration
    ) internal virtual;

    /**
     * @notice Computes token rewards amount
     **/
    function _getRewardsAmount(
        uint256 baseAmount,
        uint256 lockingDuration,
        uint256 tokenId,
        address token
    ) internal view virtual returns (uint256 rewardsAmount);

    /**
     * @notice Computes token rewards multiplier
     * the longer the lock, the bigger the reward
     **/
    function _getMultiplier(uint256 lockingDuration, uint256 tokenId)
        internal
        view
        virtual
        returns (uint256 multiplier);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////
// PASTED FROM https://github.com/Atlendis/priv-contracts/ //
/////////////////////////////////////////////////////////////

/**
 * @title IPoolsController
 * @notice Management of the pools
 **/
interface IPoolsController {
    // EVENTS

    /**
     * @notice Emitted after a pool was creted
     **/
    event PoolCreated(PoolCreationParams params);

    /**
     * @notice Emitted after a borrower address was allowed to borrow from a pool
     * @param borrowerAddress The address to allow
     * @param poolHash The identifier of the pool
     **/
    event BorrowerAllowed(address borrowerAddress, bytes32 poolHash);

    /**
     * @notice Emitted after a borrower address was disallowed to borrow from a pool
     * @param borrowerAddress The address to disallow
     * @param poolHash The identifier of the pool
     **/
    event BorrowerDisallowed(address borrowerAddress, bytes32 poolHash);

    /**
     * @notice Emitted when a pool is active, i.e. after the borrower deposits enough tokens
     * in its pool liquidity rewards reserve as agreed before the pool creation
     * @param poolHash The identifier of the pool
     **/
    event PoolActivated(bytes32 poolHash);

    /**
     * @notice Emitted after pool is closed
     * @param poolHash The identifier of the pool
     * @param collectedLiquidityRewards The amount of liquidity rewards to have been collected at closing time
     **/
    event PoolClosed(bytes32 poolHash, uint128 collectedLiquidityRewards);

    /**
     * @notice Emitted when a pool defaults on its loan repayment
     * @param poolHash The identifier of the pool
     * @param distributedLiquidityRewards The remaining liquidity rewards distributed to
     * bond holders
     **/
    event Default(bytes32 poolHash, uint128 distributedLiquidityRewards);

    /**
     * @notice Emitted after governance sets the maximum borrowable amount for a pool
     **/
    event SetMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash);

    /**
     * @notice Emitted after governance sets the liquidity rewards distribution rate for a pool
     **/
    event SetLiquidityRewardsDistributionRate(
        uint128 distributionRate,
        bytes32 poolHash
    );

    /**
     * @notice Emitted after governance sets the establishment fee for a pool
     **/
    event SetEstablishmentFeeRate(uint128 establishmentRate, bytes32 poolHash);

    /**
     * @notice Emitted after governance sets the repayment fee for a pool
     **/
    event SetRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash);

    /**
     * @notice Set the pool early repay option
     **/
    event SetEarlyRepay(bool earlyRepay, bytes32 poolHash);

    /**
     * @notice Emitted after governance claims the fees associated with a pool
     * @param poolHash The identifier of the pool
     * @param normalizedAmount The amount of tokens claimed
     * @param to The address receiving the fees
     **/
    event ClaimProtocolFees(
        bytes32 poolHash,
        uint128 normalizedAmount,
        address to
    );

    // VIEW METHODS

    /**
     * @notice Returns the parameters of a pool
     * @param poolHash The identifier of the pool
     * @return underlyingToken Address of the underlying token of the pool
     * @return minRate Minimum rate of deposits accepted in the pool
     * @return maxRate Maximum rate of deposits accepted in the pool
     * @return rateSpacing Difference between two rates in the pool
     * @return maxBorrowableAmount Maximum amount of tokens that can be borrowed from the pool
     * @return loanDuration Duration of a loan in the pool
     * @return liquidityRewardsDistributionRate Rate at which liquidity rewards are distributed to lenders
     * @return cooldownPeriod Period after a loan during which a borrower cannot take another loan
     * @return repaymentPeriod Period after a loan end during which a borrower can repay without penalty
     * @return lateRepayFeePerBondRate Penalty a borrower has to pay when it repays late
     * @return liquidityRewardsActivationThreshold Minimum amount of liqudity rewards a borrower has to
     * deposit to active the pool
     **/
    function getPoolParameters(bytes32 poolHash)
        external
        view
        returns (
            address underlyingToken,
            uint128 minRate,
            uint128 maxRate,
            uint128 rateSpacing,
            uint128 maxBorrowableAmount,
            uint128 loanDuration,
            uint128 liquidityRewardsDistributionRate,
            uint128 cooldownPeriod,
            uint128 repaymentPeriod,
            uint128 lateRepayFeePerBondRate,
            uint128 liquidityRewardsActivationThreshold
        );

    /**
     * @notice Returns the fee rates of a pool
     * @return establishmentFeeRate Amount of fees paid to the protocol at borrow time
     * @return repaymentFeeRate Amount of fees paid to the protocol at repay time
     **/
    function getPoolFeeRates(bytes32 poolHash)
        external
        view
        returns (uint128 establishmentFeeRate, uint128 repaymentFeeRate);

    /**
     * @notice Returns the state of a pool
     * @param poolHash The identifier of the pool
     * @return active Signals if a pool is active and ready to accept deposits
     * @return defaulted Signals if a pool was defaulted
     * @return closed Signals if a pool was closed
     * @return currentMaturity End timestamp of current loan
     * @return bondsIssuedQuantity Amount of bonds issued, to be repaid at maturity
     * @return normalizedBorrowedAmount Actual amount of tokens that were borrowed
     * @return normalizedAvailableDeposits Actual amount of tokens available to be borrowed
     * @return lowerInterestRate Minimum rate at which a deposit was made
     * @return nextLoanMinStart Cool down period, minimum timestamp after which a new loan can be taken
     * @return remainingAdjustedLiquidityRewardsReserve Remaining liquidity rewards to be distributed to lenders
     * @return yieldProviderLiquidityRatio Last recorded yield provider liquidity ratio
     * @return currentBondsIssuanceIndex Current borrow period identifier of the pool
     **/
    function getPoolState(bytes32 poolHash)
        external
        view
        returns (
            bool active,
            bool defaulted,
            bool closed,
            uint128 currentMaturity,
            uint128 bondsIssuedQuantity,
            uint128 normalizedBorrowedAmount,
            uint128 normalizedAvailableDeposits,
            uint128 lowerInterestRate,
            uint128 nextLoanMinStart,
            uint128 remainingAdjustedLiquidityRewardsReserve,
            uint128 yieldProviderLiquidityRatio,
            uint128 currentBondsIssuanceIndex
        );

    /**
     * @notice Signals whether the early repay feature is activated or not
     * @return earlyRepay Flag that signifies whether the early repay feature is activated or not
     **/
    function isEarlyRepay(bytes32 poolHash)
        external
        view
        returns (bool earlyRepay);

    /**
     * @notice Returns the state of a pool
     * @return defaultTimestamp The timestamp at which the pool was defaulted
     **/
    function getDefaultTimestamp(bytes32 poolHash)
        external
        view
        returns (uint128 defaultTimestamp);

    // GOVERNANCE METHODS

    /**
     * @notice Parameters used for a pool creation
     * @param poolHash The identifier of the pool
     * @param underlyingToken Address of the pool underlying token
     * @param yieldProvider Yield provider of the pool
     * @param minRate Minimum bidding rate for the pool
     * @param maxRate Maximum bidding rate for the pool
     * @param rateSpacing Difference between two tick rates in the pool
     * @param maxBorrowableAmount Maximum amount of tokens a borrower can get from a pool
     * @param loanDuration Duration of a loan i.e. maturity of the issued bonds
     * @param distributionRate Rate at which the liquidity rewards are distributed to unmatched positions
     * @param cooldownPeriod Period of time after a repay during which the borrow cannot take a loan
     * @param repaymentPeriod Period after the end of a loan during which the borrower can repay without penalty
     * @param lateRepayFeePerBondRate Additional fees applied when a borrower repays its loan after the repayment period ends
     * @param establishmentFeeRate Fees paid to Atlendis at borrow time
     * @param repaymentFeeRate Fees paid to Atlendis at repay time
     * @param liquidityRewardsActivationThreshold Amount of tokens the borrower has to lock into the liquidity
     * @param earlyRepay Is early repay activated
     * rewards reserve to activate the pool
     **/
    struct PoolCreationParams {
        bytes32 poolHash;
        address underlyingToken;
        address yieldProvider;
        uint128 minRate;
        uint128 maxRate;
        uint128 rateSpacing;
        uint128 maxBorrowableAmount;
        uint128 loanDuration;
        uint128 distributionRate;
        uint128 cooldownPeriod;
        uint128 repaymentPeriod;
        uint128 lateRepayFeePerBondRate;
        uint128 establishmentFeeRate;
        uint128 repaymentFeeRate;
        uint128 liquidityRewardsActivationThreshold;
        bool earlyRepay;
    }

    /**
     * @notice Creates a new pool
     * @param params A struct defining the pool creation parameters
     **/
    function createNewPool(PoolCreationParams calldata params) external;

    /**
     * @notice Allow an address to interact with a borrower pool
     * @param borrowerAddress The address to allow
     * @param poolHash The identifier of the pool
     **/
    function allow(address borrowerAddress, bytes32 poolHash) external;

    /**
     * @notice Remove pool interaction rights from an address
     * @param borrowerAddress The address to disallow
     * @param poolHash The identifier of the borrower pool
     **/
    function disallow(address borrowerAddress, bytes32 poolHash) external;

    /**
     * @notice Flags the pool as closed
     * @param poolHash The identifier of the pool to be closed
     * @param to An address to which the remaining liquidity rewards will be sent
     **/
    function closePool(bytes32 poolHash, address to) external;

    /**
     * @notice Flags the pool as defaulted
     * @param poolHash The identifier of the pool to default
     **/
    function setDefault(bytes32 poolHash) external;

    /**
     * @notice Set the maximum amount of tokens that can be borrowed in the target pool
     **/
    function setMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash)
        external;

    /**
     * @notice Set the pool liquidity rewards distribution rate
     **/
    function setLiquidityRewardsDistributionRate(
        uint128 distributionRate,
        bytes32 poolHash
    ) external;

    /**
     * @notice Set the pool establishment protocol fee rate
     **/
    function setEstablishmentFeeRate(
        uint128 establishmentFeeRate,
        bytes32 poolHash
    ) external;

    /**
     * @notice Set the pool repayment protocol fee rate
     **/
    function setRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash)
        external;

    /**
     * @notice Set the pool early repay option
     **/
    function setEarlyRepay(bool earlyRepay, bytes32 poolHash) external;

    /**
     * @notice Withdraws protocol fees to a target address
     * @param poolHash The identifier of the pool
     * @param normalizedAmount The amount of tokens claimed
     * @param to The address receiving the fees
     **/
    function claimProtocolFees(
        bytes32 poolHash,
        uint128 normalizedAmount,
        address to
    ) external;

    /**
     * @notice Stops all actions on all pools
     **/
    function freezePool() external;

    /**
     * @notice Cancel a freeze, makes actions available again on all pools
     **/
    function unfreezePool() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////
// PASTED FROM https://github.com/Atlendis/priv-contracts/ //
/////////////////////////////////////////////////////////////

/**
 * @title IPositionManager
 * @notice Contains methods that can be called by lenders to create and manage their position
 **/
interface IPositionManager {
    /**
     * @notice Emitted when #deposit is called and is a success
     * @param lender The address of the lender depositing token on the protocol
     * @param tokenId The tokenId of the position
     * @param amount The amount of deposited token
     * @param rate The position bidding rate
     * @param poolHash The identifier of the pool
     * @param bondsIssuanceIndex The borrow period assigned to the position
     **/
    event Deposit(
        address indexed lender,
        uint128 tokenId,
        uint128 amount,
        uint128 rate,
        bytes32 poolHash,
        uint128 bondsIssuanceIndex
    );

    /**
     * @notice Emitted when #updateRate is called and is a success
     * @param lender The address of the lender updating their position
     * @param tokenId The tokenId of the position
     * @param amount The amount of deposited token plus their accrued interests
     * @param rate The new rate required by lender to lend their deposited token
     * @param poolHash The identifier of the pool
     **/
    event UpdateRate(
        address indexed lender,
        uint128 tokenId,
        uint128 amount,
        uint128 rate,
        bytes32 poolHash
    );

    /**
     * @notice Emitted when #withdraw is called and is a success
     * @param lender The address of the withdrawing lender
     * @param tokenId The tokenId of the position
     * @param amount The amount of tokens withdrawn
     * @param rate The position bidding rate
     * @param poolHash The identifier of the pool
     **/
    event Withdraw(
        address indexed lender,
        uint128 tokenId,
        uint128 amount,
        uint128 remainingBonds,
        uint128 rate,
        bytes32 poolHash
    );

    /**
     * @notice Set the position descriptor address
     * @param positionDescriptor The address of the new position descriptor
     **/
    event SetPositionDescriptor(address positionDescriptor);

    /**
     * @notice Emitted when #withdraw is called and is a success
     * @param tokenId The tokenId of the position
     * @return poolHash The identifier of the pool
     * @return adjustedBalance Adjusted balance of the position original deposit
     * @return rate Position bidding rate
     * @return underlyingToken Address of the tokens the position contains
     * @return remainingBonds Quantity of bonds remaining in the position after a partial withdraw
     * @return bondsMaturity Maturity of the position's remaining bonds
     * @return bondsIssuanceIndex Borrow period the deposit was made in
     **/
    function position(uint128 tokenId)
        external
        view
        returns (
            bytes32 poolHash,
            uint128 adjustedBalance,
            uint128 rate,
            address underlyingToken,
            uint128 remainingBonds,
            uint128 bondsMaturity,
            uint128 bondsIssuanceIndex
        );

    /**
     * @notice Returns the balance on yield provider and the quantity of bond held
     * @param tokenId The tokenId of the position
     * @return bondsQuantity Quantity of bond held, represents funds borrowed
     * @return normalizedDepositedAmount Amount of deposit placed on yield provider
     **/
    function getPositionRepartition(uint128 tokenId)
        external
        view
        returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount);

    /**
     * @notice Deposits tokens into the yield provider and places a bid at the indicated rate within the
     * respective borrower's order book. A new position is created within the positions map that keeps
     * track of this position's composition. An ERC721 NFT is minted for the user as a representation
     * of the position.
     * @param to The address for which the position is created
     * @param amount The amount of tokens to be deposited
     * @param rate The rate at which to bid for a bonds
     * @param poolHash The identifier of the pool
     * @param underlyingToken The contract address of the token to be deposited
     **/
    function deposit(
        address to,
        uint128 amount,
        uint128 rate,
        bytes32 poolHash,
        address underlyingToken
    ) external returns (uint128 tokenId);

    /**
     * @notice Allows a user to update the rate at which to bid for bonds. A rate is only
     * upgradable as long as the full amount of deposits are currently allocated with the
     * yield provider i.e the position does not hold any bonds.
     * @param tokenId The tokenId of the position
     * @param newRate The new rate at which to bid for bonds
     **/
    function updateRate(uint128 tokenId, uint128 newRate) external;

    /**
     * @notice Withdraws the amount of tokens that are deposited with the yield provider.
     * The bonds portion of the position is not affected.
     * @param tokenId The tokenId of the position
     **/
    function withdraw(uint128 tokenId) external;

    /**
     * @notice Set the address of the position descriptor.
     * Only accessible to governance.
     * @param positionDescriptor The address of the position descriptor
     **/
    function setPositionDescriptor(address positionDescriptor) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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