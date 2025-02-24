// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract Rental is Initializable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private rewardId;

    struct LandLords {
        address owner;
        uint256[] landId;
        uint256 lordId;
        uint256[] LandCatorgy;
        uint256 LordCatorgy;
        uint256 lastClaimTime;
        uint256 currentPoolId;
        uint256 totalLandWeight;
        bool status;
    }

    struct Pool {
        uint256 poolTimeSlot;
        uint256 poolRoyalty;
        uint256[] poolTotalWeight;
        uint256 poolMonth;
        uint256 poolStartTime;
        uint256 poolEndTime;
    }

    address private landContract;
    address private lordContract;
    address public owner;

    uint256[] private landWeight;
    uint256[] private lordWeight;
    uint256 public totalLandWeights;
    uint256 public availablePoolId;

    bool public paused;

    mapping(address => bool) public isBlacklisted;
    mapping(uint256 => LandLords) landLordsInfo;
    mapping(uint256 => Pool) poolInfo;
    mapping(address => uint256[]) rewardIdInfo;
    mapping(uint256 => uint256) index;
    mapping(uint256 => mapping(uint256 => uint256)) userClaimPerPool;

    modifier isBlacklist(address _user) {
        require(!isBlacklisted[_user], "Eth amount not enough");
        _;
    }

    modifier isContractApprove() {
        require(
            IERC721Upgradeable(landContract).isApprovedForAll(
                msg.sender,
                address(this)
            ) &&
                IERC721Upgradeable(lordContract).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "Nft not approved to contract"
        );
        _;
    }

    modifier isCatorgyValid(
        uint256[] memory _landCatorgy,
        uint256 _lordCatory
    ) {
        require(catorgyValid(_landCatorgy, _lordCatory), "not valid catory");
        _;
    }

    modifier isNonzero(
        uint256 _landId,
        uint256 _lordId,
        uint256 _landCatorgy,
        uint256 _lordCatory
    ) {
        require(
            _landId != 0 &&
                _lordId != 0 &&
                _landCatorgy != 0 &&
                _lordCatory != 0,
            "not null"
        );
        _;
    }

    modifier isLandValid(uint256 length, uint256 _lordCatory) {
        require(lordWeight[_lordCatory - 1] >= length, "length mismatch");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isOwnerOfId(uint256 _rewardId) {
        require(
            msg.sender == landLordsInfo[_rewardId].owner,
            "not rewardId owner"
        );
        _;
    }

    modifier isRewardIdExist(uint256 _rewardId) {
        require(
            rewardId.current() >= _rewardId && isRewardId(_rewardId),
            "rewardId not exist"
        );
        _;
    }

    modifier isMerkelProofValid(
        uint256 _landId,
        uint256 _lordId,
        uint256 _landCatorgy,
        uint256 _lordCatory
    ) {
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "contract paused");
        _;
    }

    event Blacklisted(address account, bool value);
    event DepositeLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId,
        uint256[] landCatorgy,
        uint256 lordCatory
    );
    event Pausable(bool state);
    event UpdateOwner(address oldOwner, address newOwner);
    event UpdateLandContract(address newContract, address oldContract);
    event UpdateLordContract(address newContract, address oldContract);
    event WithdrawLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId
    );

    function initialize(
        address _owner,
        address _landContract,
        address _lordContract,
        uint256[] calldata _landWeight,
        uint256[] calldata _lordWeight
    ) external initializer {
        owner = _owner;
        landContract = _landContract;
        lordContract = _lordContract;
        landWeight.push(_landWeight[0]);
        landWeight.push(_landWeight[1]);
        landWeight.push(_landWeight[2]);
        lordWeight.push(_lordWeight[0]);
        lordWeight.push(_lordWeight[1]);
        lordWeight.push(_lordWeight[2]);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
        nonReentrant
    {
        isBlacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    function setLandContract(address _landContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = landContract;
        landContract = _landContract;

        emit UpdateLandContract(_landContract, oldContract);
    }

    function setLordContract(address _lordContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = lordContract;
        lordContract = _lordContract;

        emit UpdateLandContract(_lordContract, oldContract);
    }

    function setOwner(address _owner) external nonReentrant onlyOwner {
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function pause(bool _state) external nonReentrant onlyOwner {
        paused = _state;
        emit Pausable(_state);
    }

    function setLandWeight(
        uint256 _basicLandWeight,
        uint256 _platniumLandWeight,
        uint256 _primeLandWeight
    ) external nonReentrant onlyOwner {
        landWeight.push(_basicLandWeight);
        landWeight.push(_platniumLandWeight);
        landWeight.push(_primeLandWeight);
    }

    function setPool(
        uint256 _poolTimeSlot,
        uint256 _poolRoyalty,
        uint256[] calldata _poolTotalWeight,
        uint256 _poolMonth
    ) external payable onlyOwner {
        require(msg.value >= (_poolRoyalty * _poolMonth), "value not send");
        availablePoolId += 1;

        uint256 poolStartTime = availablePoolId == 1
            ? block.timestamp
            : poolInfo[availablePoolId - 1].poolEndTime;

        uint256 poolEndTime = poolStartTime + _poolTimeSlot * _poolMonth;

        poolInfo[availablePoolId] = Pool(
            _poolTimeSlot,
            _poolRoyalty,
            _poolTotalWeight,
            _poolMonth,
            poolStartTime,
            poolEndTime
        );
    }

    function emergencyWithdraw() external nonReentrant onlyOwner {
        _transferETH(address(this).balance);
    }

    function depositLandLords(
        uint256[] calldata _landId,
        uint256 _lordId,
        uint256[] calldata _landCatorgy,
        uint256 _lordCatory
    )
        external
        nonReentrant
        isNonzero(_landId.length, _lordId, _landCatorgy.length, _lordCatory)
        isCatorgyValid(_landCatorgy, _lordCatory)
        isContractApprove
        isLandValid(_landId.length, _lordCatory)
    {
        uint256 currentPoolIds = currentPoolId();
        require(currentPoolIds > 0, "deposite not allowed");

        _deposite(_landId, _lordId, _landCatorgy, _lordCatory, currentPoolIds);
    }

    function withdrawLandLords(uint256 _rewardId)
        external
        nonReentrant
        whenNotPaused
        isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
    {
        require(_rewardId != 0, "not zero");

        for (uint256 i = 0; i < landLordsInfo[_rewardId].landId.length; i++) {
            _transfer(
                landContract,
                msg.sender,
                address(this),
                landLordsInfo[_rewardId].landId[i]
            );
        }
        _transfer(
            lordContract,
            address(this),
            msg.sender,
            landLordsInfo[_rewardId].lordId
        );

        totalLandWeights =
            totalLandWeights -
            landLordsInfo[_rewardId].totalLandWeight;

        landLordsInfo[_rewardId].status = false;

        uint256 poolId = currentPoolId();
        uint256 currentMonth = _currentMonth(poolId);
        poolInfo[poolId].poolTotalWeight[currentMonth - 1] = totalLandWeights;

        _withdraw(_rewardId);

        emit WithdrawLandLord(
            msg.sender,
            _rewardId,
            landLordsInfo[_rewardId].landId,
            landLordsInfo[_rewardId].lordId
        );
    }

    function claimRewards(uint256 _rewardId)
        external
        isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
        returns (uint256 rewards)
    {
        rewards = _calculateRewards(_rewardId);
        _transferETH(rewards);
    }

    function getPoolInfo(uint256 _poolId) external view returns (Pool memory) {
        return poolInfo[_poolId];
    }

    function getLandLordsInfo(uint256 _rewardId)
        external
        view
        returns (LandLords memory)
    {
        return landLordsInfo[_rewardId];
    }

    function getCurrentRewrdId() external view returns (uint256) {
        return rewardId.current();
    }

    function getUserClaim(uint256 _rewardId, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        return userClaimPerPool[_rewardId][_poolId];
    }

    function currrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function _calculateRewards(uint256 _rewardId) internal returns (uint256) {
        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        bool loop;

        while (!loop) {
            if (_currentPoolId == landLordsInfo[_rewardId].currentPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        landLordsInfo[_rewardId].lastClaimTime,
                        userClaimPerPool[_rewardId][_currentPoolId]
                    );
                claimAmount += reward;

                userClaimPerPool[_rewardId][_currentPoolId] = claims;
                landLordsInfo[_rewardId].lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    landLordsInfo[_rewardId].lastClaimTime
                );
                claimAmount += reward;

                userClaimPerPool[_rewardId][poolId] = poolInfo[poolId]
                    .poolMonth;
                landLordsInfo[_rewardId].currentPoolId += 1;
                landLordsInfo[_rewardId].lastClaimTime = time;
            }
        }

        return claimAmount;
    }

    function getcalculateRewards(uint256 _rewardId)
        external
        view
        isRewardIdExist(_rewardId)
        returns (uint256, uint256)
    {
        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        uint256 userclaim = userClaimPerPool[_rewardId][_currentPoolId];
        uint256 lastClaimTime = landLordsInfo[_rewardId].lastClaimTime;
        uint256 userPoolId = landLordsInfo[_rewardId].currentPoolId;
        bool loop;

        while (!loop) {
            if (_currentPoolId == userPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        lastClaimTime,
                        userclaim
                    );
                claimAmount += reward;

                userclaim = claims;
                lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    lastClaimTime
                );
                claimAmount += reward;
                userPoolId += 1;
                lastClaimTime = time;
            }
        }

        return (claimAmount, lastClaimTime);
    }

    function getUserRewardId(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return rewardIdInfo[_user];
    }

    function isRewardId(uint256 _rewardId) internal view returns (bool) {
        for (uint256 i = 0; i < rewardIdInfo[msg.sender].length; i++) {
            if (rewardIdInfo[msg.sender][i] == _rewardId) {
                return true;
            }
        }
        return false;
    }

    function _rewardForCurrentPool(
        uint256 _poolId,
        uint256 rewardIds,
        uint256 _lastClaimTime,
        uint256 _userClaim
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _rewardId = rewardIds;
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 currentMonth = _currentMonth(_poolId);
        uint256 poolId = _poolId;
        uint256 claiming;
        uint256 weights;
        uint256 userClaim = _userClaim == currentMonth
            ? _userClaim - 1
            : _userClaim;

        if (currentMonth != 0) {
            for (uint256 i = userClaim; i < currentMonth; i++) {
                (uint256 claimableTime, uint256 monthTime) = claminingTime(
                    i,
                    currentMonth,
                    lastClaimTime,
                    poolId
                );

                claiming = claimableTime;

                uint256 weight = _poolWeight(poolId, i + 1);
                weights = weight;

                uint256 rewards = ((poolInfo[poolId].poolRoyalty *
                    claimableTime) / (weight * poolInfo[poolId].poolTimeSlot)) *
                    landLordsInfo[_rewardId].totalLandWeight;

                totalRewards += rewards;

                lastClaimTime = monthTime;
            }
        }
        return (totalRewards, lastClaimTime, currentMonth);
    }

    function claminingTime(
        uint256 preMonth,
        uint256 currentMonth,
        uint256 lastClaimTime,
        uint256 poolId
    ) internal view returns (uint256 claimableTime, uint256 lastClaim) {
        if (currentMonth == (preMonth + 1)) {
            claimableTime = block.timestamp - lastClaimTime;
            lastClaim = block.timestamp;
        } else {
            uint256 lasttime = poolInfo[poolId].poolStartTime +
                (poolInfo[poolId].poolTimeSlot * (preMonth + 1));
            claimableTime = lasttime - lastClaimTime;
            lastClaim = lasttime;
        }
    }

    function _rewardsForPreviousPool(
        uint256 _poolId,
        uint256 _rewardId,
        uint256 _lastClaimTime
    ) internal view returns (uint256, uint256) {
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 poolId = _poolId;

        for (
            uint256 i = userClaimPerPool[_rewardId][poolId];
            i < poolInfo[poolId].poolMonth;
            i++
        ) {
            uint256 monthTime = poolInfo[poolId].poolStartTime +
                (poolInfo[poolId].poolTimeSlot * (i + 1));

            uint256 claimableTime = monthTime - lastClaimTime;

            uint256 weight = _poolWeight(poolId, i + 1);

            uint256 rewards = ((poolInfo[poolId].poolRoyalty * claimableTime) /
                (weight * poolInfo[poolId].poolTimeSlot)) *
                landLordsInfo[_rewardId].totalLandWeight;

            totalRewards += rewards;

            lastClaimTime = monthTime;
        }

        return (totalRewards, lastClaimTime);
    }

    function _currentMonth(uint256 _poolId) public view returns (uint256) {
        require(currentPoolId() == _poolId, "pass correct pool id");
        uint256 poolTime = poolInfo[_poolId].poolTimeSlot;
        uint256 poolMonth = poolInfo[_poolId].poolMonth;

        uint256 leftTime = block.timestamp - poolInfo[_poolId].poolStartTime;
        require(leftTime < (poolTime * poolMonth), "Wrong pool id");

        uint256 currentMonth = leftTime / poolTime;

        return currentMonth == 4 ? 4 : currentMonth + 1;
    }

    function currentPoolId() public view returns (uint256) {
        if (availablePoolId > 0) {
            return _calcuatePoolId();
        } else {
            return 0;
        }
    }

    function _calcuatePoolId() internal view returns (uint256 poolId) {
        for (uint256 i = 0; i < availablePoolId; i++) {
            if (
                poolInfo[i + 1].poolEndTime > block.timestamp &&
                poolInfo[i + 1].poolStartTime < block.timestamp
            ) {
                return i + 1;
            } else {
                if (i + 1 == availablePoolId) {
                    return availablePoolId;
                }
            }
        }
    }

    function _deposite(
        uint256[] calldata _landId,
        uint256 _lordId,
        uint256[] calldata _landCatorgy,
        uint256 _lordCatory,
        uint256 _currentPoolId
    ) internal {
        rewardId.increment();

        uint256 totalLandWeight;

        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            totalLandWeight += landWeight[_landCatorgy[i] - 1];
        }

        landLordsInfo[rewardId.current()] = LandLords(
            msg.sender,
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory,
            block.timestamp,
            _currentPoolId,
            totalLandWeight,
            true
        );

        totalLandWeights += totalLandWeight;

        index[rewardId.current()] = rewardIdInfo[msg.sender].length;
        rewardIdInfo[msg.sender].push(rewardId.current());

        _monthTotalWeight(rewardId.current(), _currentPoolId, totalLandWeights);

        for (uint256 i = 0; i < _landId.length; i++) {
            _transfer(landContract, msg.sender, address(this), _landId[i]);
        }
        _transfer(lordContract, msg.sender, address(this), _lordId);

        emit DepositeLandLord(
            msg.sender,
            rewardId.current(),
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory
        );
    }

    function _monthTotalWeight(
        uint256 _rewardId,
        uint256 _poolId,
        uint256 _totalLandWeight
    ) internal {
        uint256 currentMonth = _currentMonth(_poolId);
        poolInfo[_poolId].poolTotalWeight[currentMonth - 1] = _totalLandWeight;

        userClaimPerPool[_rewardId][_poolId] = currentMonth - 1;
    }

    function _poolWeight(uint256 _poolId, uint256 _month)
        public
        view
        returns (uint256)
    {
        uint256 weight;
        uint256 poolId = _poolId;
        uint256 month = _month;
        for (uint256 i = 0; i < availablePoolId; i++) {
            weight = _poolMonthWeight(poolId, month);
            if (weight == 0) {
                poolId -= 1;
                month = poolInfo[poolId].poolMonth;
            } else {
                return weight;
            }
        }

        return totalLandWeights;
    }

    function _poolMonthWeight(uint256 _poolId, uint256 _month)
        internal
        view
        returns (uint256)
    {
        uint256 month = _month;
        if (_poolId == 0) {
            return totalLandWeights;
        } else {
            for (uint256 i = 0; i < _month; i++) {
                if (poolInfo[_poolId].poolTotalWeight[month - 1] > 0) {
                    return poolInfo[_poolId].poolTotalWeight[month - 1];
                } else {
                    month -= 1;
                }
            }
        }

        return 0;
    }

    function catorgyValid(uint256[] memory _landCatorgy, uint256 _lordCatory)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            if (_landCatorgy[i] > 4 && _lordCatory < 4) {
                return false;
            }
        }

        return true;
    }

    function _transfer(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable(_contract).safeTransferFrom(_from, _to, _tokenId);
    }

    function _transferETH(uint256 _amount) internal {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "refund failed");
    }

    function _withdraw(uint256 _rewardId) internal {
        uint256 lastrewardId = rewardIdInfo[msg.sender][
            (rewardIdInfo[msg.sender].length - 1)
        ];
        index[lastrewardId] = index[_rewardId];
        rewardIdInfo[msg.sender][(index[_rewardId])] = lastrewardId;
        rewardIdInfo[msg.sender].pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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