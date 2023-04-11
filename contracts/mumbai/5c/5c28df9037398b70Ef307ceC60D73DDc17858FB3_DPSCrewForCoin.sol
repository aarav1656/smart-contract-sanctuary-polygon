//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import ".././interfaces/IERC721Full.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(
        FLAGSHIP_PART _trait,
        uint256 _tokenId,
        uint8 _level
    ) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface DPSI is IERC721, IERC721Metadata {}

contract DPSCrewForCoin is IERC721Receiver, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC721Full public immutable lDPS;
    IERC721Full public immutable lFlagship;
    DPSI public immutable dps;
    DPSFlagshipI public immutable flagship;
    IERC20 public immutable doubloons;
    address public docks;

    mapping(IERC721 => mapping(uint256 => Asset)) public assets;
    mapping(uint256 => bool) public pausedComponent;
    uint16 public constant DENOMINATOR = 10_000;
    uint16 public doubloonsForTreasuryPercentage;
    address public treasury;

    EpochConfig public epochConfig;

    EnumerableSet.AddressSet private _allowedReceivers;

    struct EpochConfig {
        uint128 maxEpochs;
        uint64 epochInSeconds;
    }

    struct Asset {
        uint32 targetId;
        bool borrowed;
        address borrower;
        uint32 epochs;
        address lender;
        uint64 startTime;
        uint64 endTime;
        uint256 doubloonsPerEpoch;
    }

    constructor(
        IERC721Full _lDPS,
        IERC721Full _lFlagship,
        DPSI _dps,
        DPSFlagshipI _flagship,
        IERC20 _doubloons
    ) {
        lDPS = _lDPS;
        lFlagship = _lFlagship;
        dps = _dps;
        flagship = _flagship;
        doubloons = _doubloons;

        epochConfig = EpochConfig(29, 1 days);
    }

    /**
     * @dev you must approve the token id to be transfer by the Lender contract
     */
    function lendDPS(
        uint256 _tokenId,
        uint256 _epochs,
        uint256 _doubloonsPerEpoch
    ) external nonReentrant {
        if (pausedComponent[1]) revert Paused();
        if (_epochs > epochConfig.maxEpochs) revert TooLong();
        if (dps.ownerOf(_tokenId) != msg.sender) revert NotOwner();

        if (_epochs == 0) revert AddressZero();

        assets[dps][_tokenId] = Asset({
            borrowed: false,
            borrower: address(0),
            lender: msg.sender,
            startTime: 0,
            endTime: 0,
            epochs: uint32(_epochs),
            targetId: uint32(_tokenId),
            doubloonsPerEpoch: _doubloonsPerEpoch
        });

        dps.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        emit LentDPS(msg.sender, _epochs, _doubloonsPerEpoch, _tokenId);
    }

    function cancelLendingDPS(uint256 _tokenId) external nonReentrant {
        Asset storage asset = assets[dps][_tokenId];
        if (asset.lender != msg.sender) revert NotOwner();
        if (asset.borrower != address(0)) revert AlreadyBorrowed();
        delete assets[dps][_tokenId];

        dps.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        emit CancelLendingDPS(msg.sender, _tokenId);
    }

    function borrowDPS(uint256 _tokenId) external nonReentrant {
        if (pausedComponent[2]) revert Paused();

        Asset storage asset = assets[dps][_tokenId];
        if (asset.epochs == 0) revert NotListed();
        if (asset.borrower != address(0)) revert AlreadyBorrowed();

        asset.borrowed = true;
        asset.borrower = msg.sender;
        asset.startTime = uint64(block.timestamp);
        asset.endTime = uint64(block.timestamp) + asset.epochs * epochConfig.epochInSeconds;

        // calculate percentage
        uint256 totalDoubloonsToPay = asset.doubloonsPerEpoch * asset.epochs;
        uint256 percentage = (totalDoubloonsToPay * doubloonsForTreasuryPercentage) / DENOMINATOR;

        totalDoubloonsToPay -= percentage;

        doubloons.transferFrom(msg.sender, treasury, percentage);
        doubloons.transferFrom(msg.sender, asset.lender, totalDoubloonsToPay);

        lDPS.mint(msg.sender, asset.targetId);

        emit AssetBorrowed(address(dps), msg.sender, asset.lender, totalDoubloonsToPay);
    }

    function redeemDPS(uint256 _tokenId) public nonReentrant {
        if (pausedComponent[3]) revert Paused();

        Asset storage asset = assets[dps][_tokenId];
        if (asset.borrower == address(0)) revert NotListed();
        if (asset.endTime >= block.timestamp) revert NotExpired();
        if (lDPS.ownerOf(_tokenId) == docks) revert ClaimVoyageFirst();

        lDPS.burn(_tokenId);

        address lender = asset.lender;

        delete assets[dps][_tokenId];

        dps.safeTransferFrom(address(this), lender, _tokenId, "");

        emit AssetRedeemed(address(dps), msg.sender, _tokenId);
    }

    /**
     * @dev you must approve the token id to be transfer by the Lender contract
     */
    function lendFlagship(
        uint256 _tokenId,
        uint256 _epochs,
        uint256 _doubloonsPerEpoch
    ) external nonReentrant {
        if (pausedComponent[4]) revert Paused();

        if (_epochs > epochConfig.maxEpochs) revert TooLong();

        if (flagship.ownerOf(_tokenId) != msg.sender) revert NotOwner();

        if (_epochs == 0) revert AddressZero();
        if (flagship.getPartsLevel(_tokenId)[0] < 100) revert ShipDamaged();

        assets[flagship][_tokenId] = Asset({
            borrowed: false,
            borrower: address(0),
            lender: msg.sender,
            startTime: 0,
            endTime: 0,
            epochs: uint32(_epochs),
            targetId: uint32(_tokenId),
            doubloonsPerEpoch: _doubloonsPerEpoch
        });

        flagship.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        emit LentFlagship(msg.sender, _epochs, _doubloonsPerEpoch, _tokenId);
    }

    function cancelLendingFlagship(uint256 _tokenId) external nonReentrant {
        Asset storage asset = assets[flagship][_tokenId];
        if (asset.lender != msg.sender) revert NotOwner();
        if (asset.borrower != address(0)) revert AlreadyBorrowed();

        delete assets[flagship][_tokenId];

        flagship.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        emit CancelLendingFlagship(msg.sender, _tokenId);
    }

    function borrowFlagship(uint256 _tokenId) external nonReentrant {
        if (pausedComponent[5]) revert Paused();

        Asset storage asset = assets[flagship][_tokenId];
        if (asset.epochs == 0) revert NotListed();
        if (asset.borrower != address(0)) revert AlreadyBorrowed();

        asset.borrowed = true;
        asset.borrower = msg.sender;
        asset.startTime = uint64(block.timestamp);
        asset.endTime = uint64(block.timestamp) + asset.epochs * epochConfig.epochInSeconds;

        uint256 totalDoubloonsToPay = asset.doubloonsPerEpoch * asset.epochs;
        uint256 percentage = (totalDoubloonsToPay * doubloonsForTreasuryPercentage) / DENOMINATOR;
        totalDoubloonsToPay -= percentage;

        doubloons.transferFrom(msg.sender, treasury, percentage);
        doubloons.transferFrom(msg.sender, asset.lender, totalDoubloonsToPay);

        lFlagship.mint(msg.sender, asset.targetId);

        emit AssetBorrowed(address(lFlagship), msg.sender, asset.lender, totalDoubloonsToPay);
    }

    function redeemFlagship(uint256 _tokenId) public nonReentrant {
        if (pausedComponent[6]) revert Paused();

        Asset storage asset = assets[flagship][_tokenId];
        if (asset.borrower == address(0)) revert NotListed();
        if (asset.endTime >= block.timestamp) revert NotExpired();
        if (lFlagship.ownerOf(_tokenId) == docks) revert ClaimVoyageFirst();

        lFlagship.burn(_tokenId);

        address lender = asset.lender;

        delete assets[flagship][_tokenId];

        flagship.safeTransferFrom(address(this), lender, _tokenId, "");

        emit AssetRedeemed(address(flagship), msg.sender, _tokenId);
    }

    function expireAsset(IERC721 _collection, uint256 _tokenId) public onlyOwner {
        Asset memory asset = assets[_collection][_tokenId];
        assets[_collection][_tokenId].endTime = 0;
        emit ForceAssetExpire(asset.lender, asset.borrower, _collection, _tokenId);
    }

    function expireAssets(IERC721 _collection, uint256[] calldata _tokenIds) external {
        uint256 i;
        for (; i < _tokenIds.length; ++i) {
            expireAsset(_collection, _tokenIds[i]);
        }
    }

    function beforeTransferHookDPS(
        address _from,
        address _to,
        uint256 _tokenId
    ) external view {
        if (msg.sender != address(lDPS)) revert Unauthorized();
        if (_from == address(0)) return;

        Asset memory asset = assets[dps][_tokenId];

        if (!_allowedReceivers.contains(_to) && _to != asset.borrower && _to != address(0)) revert Unauthorized();

        if (asset.epochs == 0) revert InvalidAction();

        // we let a token to be transferred only to the borrower or burned in case it expired
        if (asset.endTime < block.timestamp && (_to != asset.borrower && _to != address(0))) revert Expired();
    }

    function afterTransferHookDPS(
        address,
        address _to,
        uint256 _tokenId
    ) external {
        if (msg.sender != address(lDPS)) revert Unauthorized();

        Asset memory asset = assets[dps][_tokenId];

        // we burn the token once it's expired
        if (asset.endTime < block.timestamp && _to == asset.borrower) {
            redeemDPS(_tokenId);
        }
    }

    function beforeTransferHookFlagship(
        address _from,
        address _to,
        uint256 _tokenId
    ) external view {
        if (msg.sender != address(lFlagship)) revert Unauthorized();
        if (_from == address(0)) return;

        Asset memory asset = assets[flagship][_tokenId];

        if (!_allowedReceivers.contains(_to) && _to != asset.borrower && _to != address(0)) revert Unauthorized();

        if (asset.epochs == 0) revert InvalidAction();

        // we let a token to be transferred only to the borrower in case it expired
        if (asset.endTime < block.timestamp && (_to != asset.borrower && _to != address(0))) revert Expired();
    }

    function afterTransferHookFlagship(
        address,
        address _to,
        uint256 _tokenId
    ) external {
        if (msg.sender != address(lFlagship)) revert Unauthorized();

        Asset memory asset = assets[flagship][_tokenId];

        // we burn the token once it's expired
        if (asset.endTime < block.timestamp && _to == asset.borrower) {
            redeemFlagship(_tokenId);
        }
    }

    function upgradeFlagshipPartHook(
        uint256 _tokenId,
        FLAGSHIP_PART _part,
        uint8 _level
    ) external {
        if (msg.sender != address(lFlagship)) revert Unauthorized();
        flagship.upgradePart(_part, _tokenId, _level);
    }

    function getFlagshipUri(uint256 _tokenId) external view returns (string memory) {
        return flagship.tokenURI(_tokenId);
    }

    function getDPSUri(uint256 _tokenId) external view returns (string memory) {
        return dps.tokenURI(_tokenId);
    }

    function isDPSInMarket(uint256 _tokenId) external view returns (Asset memory) {
        return assets[dps][_tokenId];
    }

    function isFlagshipInMarket(uint256 _tokenId) external view returns (Asset memory) {
        return assets[flagship][_tokenId];
    }

    function getParts(uint256 _tokenId) external view returns (uint8[7] memory parts) {
        parts = flagship.getPartsLevel(_tokenId);
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator != address(this)) revert Unauthorized();
        return this.onERC721Received.selector;
    }

    function setEpochConfig(EpochConfig memory _newEpochConfig) external onlyOwner {
        emit EpochConfigChanged(epochConfig, _newEpochConfig);
        epochConfig = _newEpochConfig;
    }

    /**
     * @notice used to recover tokens using call. This will be used so we can save some contract sizes
     * @param _token the token address
     * @param _data encoded with abi.encodeWithSignature(signatureString, arg); of transferFrom, transfer methods
     */
    function recoverToken(address _token, bytes calldata _data) external onlyOwner {
        (bool success, ) = _token.call{value: 0}(_data);
        if (!success) revert NotEnoughTokens();
        emit TokenRecovered(_token, _data);
    }

    function modifyAllowedReceivers(address _receiver, bool _add) external onlyOwner {
        if (_add) {
            _allowedReceivers.add(_receiver);
        } else {
            _allowedReceivers.remove(_receiver);
        }

        emit AllowedReceiverModified(_receiver, _add);
    }

    function pauseComponent(uint256 _target, bool _paused) external onlyOwner {
        pausedComponent[_target] = _paused;
        emit ComponentPaused(_target, _paused);
    }

    function allowedReceivers() external view returns (address[] memory) {
        return _allowedReceivers.values();
    }

    function setDoubloonsForTreasuryPercentage(uint16 _newDoubloonsForTreasuryPercentage) external onlyOwner {
        if (_newDoubloonsForTreasuryPercentage > 1_000) {
            revert InvalidDoubloonsForTreasuryPercentage();
        }
        doubloonsForTreasuryPercentage = _newDoubloonsForTreasuryPercentage;
        emit SetDoubloonsForTreasuryPercentage(_newDoubloonsForTreasuryPercentage);
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) {
            revert AddressZero();
        }
        treasury = _newTreasury;
        emit SetTreasury(_newTreasury);
    }

    function setDocks(address _docks) external onlyOwner {
        if (_docks == address(0)) {
            revert AddressZero();
        }
        docks = _docks;
        emit SetDocks(_docks);
    }

    event LentDPS(address indexed _lender, uint256 _duration, uint256 _doubloonsPerEpoch, uint256 _tokenId);
    event LentFlagship(address indexed _lender, uint256 _duration, uint256 _doubloonsPerEpoch, uint256 _tokenId);
    event TokenRecovered(address indexed _token, bytes _data);
    event EpochConfigChanged(EpochConfig _oldEpochConfig, EpochConfig _newEpochConfig);
    event AssetBorrowed(address indexed _target, address indexed _borrower, address indexed _lender, uint256 _price);
    event AssetRedeemed(address indexed _target, address indexed _lender, uint256 _tokenId);
    event AllowedReceiverModified(address indexed _receiver, bool _add);
    event SetDoubloonsForTreasuryPercentage(uint256 _newDoubloonsForTreasuryPercentage);
    event SetTreasury(address _newTreasury);
    event SetDocks(address _newDocks);
    event CancelLendingDPS(address owner, uint256 tokenId);
    event CancelLendingFlagship(address owner, uint256 tokenId);
    event ComponentPaused(uint256 _target, bool _paused);
    event ForceAssetExpire(
        address indexed _lender,
        address indexed _borrower,
        IERC721 indexed _collection,
        uint256 _tokenId
    );
}

error NotOwner();
error AddressZero();
error Unauthorized();
error NotEnoughTokens();
error NotListed();
error AlreadyBorrowed();
error InvalidAction();
error NotExpired();
error Expired();
error ShipDamaged();
error TooLong();
error InvalidDoubloonsForTreasuryPercentage();
error ClaimVoyageFirst();
error Paused();

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Full is IERC721 {
    function mint(address _owner, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
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