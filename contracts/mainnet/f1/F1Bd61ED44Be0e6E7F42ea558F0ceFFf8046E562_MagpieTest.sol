// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibBytes4.sol";
import "./lib/LibBytes32.sol";
import "./lib/LibBytes32Array.sol";
import "./lib/LibSwap.sol";
import "./interfaces/IMagpieTest.sol";

contract MagpieTest is ReentrancyGuard, Ownable, Multicall, IMagpieTest {
    using LibSwap for IMagpieRouter.SwapArgs;
    using LibAsset for address;
    using LibBytes for bytes;
    using LibBytes4 for bytes4;
    using LibBytes32 for bytes32;
    using LibBytes32Array for bytes32[];

    address public immutable weth;
    mapping(uint16 => Amm) private amms;

    constructor(address _weth) {
        weth = _weth;
    }

    receive() external payable {}

    function addAmm(uint16 ammId, Amm calldata amm) external override onlyOwner {
        amms[ammId] = amm;

        emit AmmAdded(ammId, amm, msg.sender);
    }

    function removeAmm(uint16 ammId) external override onlyOwner {
        delete amms[ammId];

        emit AmmRemoved(ammId, msg.sender);
    }

    function swap(bytes[] calldata hops, bytes calldata params) external payable nonReentrant override returns (uint256 amountOut) {
        Swap memory s = Swap({
            assetsLength: params.toUint8(0),
            i: 0,
            fromIsNative: false,
            toIsNative: false,
            hopsLength: hops.length,
            amountIn: params.toUint256(2),
            accAmountIn: 0,
            lastAmountOut: 0,
            fromAssetAddress: params.toAddress(98),
            toAssetAddress: params.toAddress(118)
        });
        if (s.fromAssetAddress.isNative()) {
            s.fromIsNative = true;
            s.fromAssetAddress = weth;
        }
        if (s.toAssetAddress.isNative()) {
            s.toIsNative = true;
            s.toAssetAddress = weth;
        }
        Hop memory h = Hop({
            j: 0,
            ammId: 0,
            amountInIndex: 0,
            toAssetIndex: 0,
            amountIn: 0,
            fromAssetAddress: s.fromAssetAddress,
            toAssetAddress: address(0)
        });
        uint256[] memory startingBalances = new uint256[](s.assetsLength+4);

        if (s.assetsLength > 200) {
            revert InvalidAssets();
        }

        if (s.fromIsNative) {
            if (msg.value < s.amountIn) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: s.amountIn}();
        } else {
            s.fromAssetAddress.transferFrom(msg.sender, address(this), s.amountIn);
        }

        for (s.i; s.i < s.hopsLength; s.i++) {
            h.ammId = hops[s.i].toUint16(0);
            h.amountInIndex = hops[s.i].toUint16(2);
            h.toAssetIndex = hops[s.i].toUint16(4);
            h.amountIn = (h.fromAssetAddress == s.fromAssetAddress ? params.toUint256(h.amountInIndex) : s.lastAmountOut);
            h.toAssetAddress = params.toAddress(h.toAssetIndex);

            if (h.fromAssetAddress == s.fromAssetAddress) {
                s.accAmountIn += h.amountIn;
            }

            if (startingBalances[h.toAssetIndex] == 0) {
                startingBalances[h.toAssetIndex] = h.toAssetAddress.getBalance();
            }

            h.fromAssetAddress.approve(amms[h.ammId].ammAddress, h.amountIn);

            if (amms[h.ammId].protocolId == 0) {
                revert InvalidAmm();
            }

            (bool success,) = address(amms[h.ammId].ammAddress).call{value:0}(amms[h.ammId].selector.getPayload(hops[s.i], params));

            if (!success) {
                revert SwapFailed();
            }

            uint256 newBalance = h.toAssetAddress.getBalance();
            s.lastAmountOut = newBalance > startingBalances[h.toAssetIndex] ? (newBalance - startingBalances[h.toAssetIndex]) : 0;
            startingBalances[h.toAssetIndex] = newBalance;

            if (h.toAssetAddress == s.toAssetAddress) {
                amountOut += s.lastAmountOut;
                h.fromAssetAddress = s.fromAssetAddress;
            } else {
                h.fromAssetAddress = h.toAssetAddress;
            }
        }

        if (s.hopsLength == 0) {
            s.accAmountIn = s.amountIn;
            amountOut = s.amountIn;
        }

        if (s.toIsNative) {
            IWETH(weth).withdraw(amountOut);
        }

        if (s.amountIn != s.accAmountIn) {
            revert InvalidAmountIn();
        }

        if (amountOut < params.toUint256(34) || amountOut == 0) {
            revert InsufficientOutputAmount();
        }

        s.toAssetAddress.transfer(payable(params.toAddress(66)), amountOut);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibAsset {
    using LibAsset for address;

    error TransferFromFailed();
    error TransferFailed();
    error ApprovalFailed();

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool isSuccessful = IERC20(self).transferFrom(from, to, amount);
        if (!isSuccessful) {
            revert TransferFromFailed();
        }
    }

    function increaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
        SafeERC20.safeIncreaseAllowance(IERC20(self), spender, amount);
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        bool isSuccessful;
        if (self.isNative()) {
            (isSuccessful,) = recipient.call{value: amount}("");
        } else {
            isSuccessful = IERC20(self).transfer(recipient, amount);
        }

        if (!isSuccessful) {
            revert TransferFailed();
        }
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        bool isSuccessful = IERC20(self).approve(spender, amount);
        if (!isSuccessful) {
            revert ApprovalFailed();
        }
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20(self).allowance(owner, spender);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieBridge.sol";

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        require(self.length >= start + 32, "LibBytes: toAddress outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 0x20), start))
        }

        return tempAddress;
    }

    function toBool(bytes memory self, uint256 start) internal pure returns (bool) {
        return self.toUint8(start) == 1 ? true : false;
    }

    function toUint8(bytes memory self, uint256 start) internal pure returns (uint8) {
        require(self.length >= start + 1, "LibBytes: toUint8 outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x1), start))
        }

        return tempUint;
    }

    function toUint16(bytes memory self, uint256 start) internal pure returns (uint16) {
        require(self.length >= start + 2, "LibBytes: toUint16 outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x2), start))
        }

        return tempUint;
    }

    function toUint24(bytes memory self, uint256 start) internal pure returns (uint24) {
        require(self.length >= start + 3, "LibBytes: toUint24 outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x3), start))
        }

        return tempUint;
    }

    function toUint64(bytes memory self, uint256 start) internal pure returns (uint64) {
        require(self.length >= start + 8, "LibBytes: toUint64 outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x8), start))
        }

        return tempUint;
    }

    function toUint256(bytes memory self, uint256 start) internal pure returns (uint256) {
        require(self.length >= start + 32, "LibBytes: toUint256 outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x20), start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory self, uint256 start) internal pure returns (bytes32) {
        require(self.length >= start + 32, "LibBytes: toBytes32 outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(self, 0x20), start))
        }

        return tempBytes32;
    }

    function slice(
        bytes memory self,
        uint256 start,
        uint256 length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(length, 31)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toBridgeType(bytes memory self, uint256 start) internal pure returns (IMagpieBridge.BridgeType) {
        return self.toUint8(start) == 0 ? IMagpieBridge.BridgeType.Wormhole : IMagpieBridge.BridgeType.Stargate;
    }

    function parse(bytes memory self) internal pure returns (IMagpieBridge.ValidationOutPayload memory payload) {
        uint256 i = 0;

        payload.fromAssetAddress = self.toAddress(i);
        i += 32;

        payload.toAssetAddress = self.toAddress(i);
        i += 32;

        payload.to = self.toAddress(i);
        i += 32;

        payload.recipientCoreAddress = self.toAddress(i);
        i += 32;

        payload.senderAddress = self.toBytes32(i);
        i += 32;

        payload.amountOutMin = self.toUint256(i);
        i += 32;

        payload.swapOutGasFee = self.toUint256(i);
        i += 32;

        payload.amountIn = self.toUint256(i);
        i += 32;

        payload.tokenSequence = self.toUint64(i);
        i += 8;

        payload.senderIntermediaryDecimals = self.toUint8(i);
        i += 1;

        payload.senderNetworkId = self.toUint8(i);
        i += 1;

        payload.recipientNetworkId = self.toUint8(i);
        i += 1;

        payload.bridgeType = self.toBridgeType(i);
        i += 1;

        require(self.length == i, "LibBytes: payload is invalid");
    }

    function parseSgPayload(bytes memory self)
        internal
        pure
        returns (
            uint8 networkId,
            bytes32 senderAddress,
            uint64 coreSequence
        )
    {
        uint256 i = 0;
        networkId = self.toUint8(i);
        i += 1;
        senderAddress = self.toBytes32(i);
        i += 32;
        coreSequence = self.toUint64(i);
        i += 8;
        require(self.length == i, "LibBytes: payload is invalid");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibBytes4 {
    using LibBytes4 for bytes4;

    function getPayload(bytes4 selector, bytes memory hop, bytes memory params) internal pure returns (bytes memory) {
        uint256 hopLength = hop.length;
        bytes memory payload;

        assembly {
            payload := mload(0x40)
            let paramValues := add(params, 32)
            let position := add(payload, 32)
            let hopDefinition := add(hop, 38)
            let endOfHopDefinitions := add(hopDefinition, hopLength)

            mstore(position, selector)
            position := add(position, 4)

            for
            {}            
            lt(hopDefinition, endOfHopDefinitions)
            {
                hopDefinition := add(hopDefinition, 3)
            }
            {
                mstore(
                    position, 
                    /* Param value */
                    mload(add(
                        paramValues, 
                        /* Param index: 2 bytes shifted to right */ shr(240, mload(add(hopDefinition, 1 /* size of paramEnd */)))
                    ))
                )
                position := add(position, /* Size of param bytes to get: 1 byte shifted to right */ shr(248, mload(hopDefinition)))
            }

            mstore(payload, sub(sub(position, payload), 32))
            mstore(0x40, and(add(position, 63), not(31)))
        }

        return payload;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibBytes32 {
    using LibBytes32 for bytes32;

    function toAddress(bytes32 self) internal pure returns (address) {
        return address(uint160(uint256(self)));
    }

    function toUint8(bytes32 self) internal pure returns (uint8) {
        return uint8(self.toUint256());
    }

    function toUint8(bytes32 self, uint256 start) internal pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := shr(mul(sub(31, start), 8), self)
        }

        return tempUint;
    }

    function toUint256(bytes32 self) internal pure returns (uint256) {
        return uint256(self);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibBytes32Array {
    using LibBytes32Array for bytes32[];

    error InvalidBytes32Length();
    error HighFinalSegment();
    error LowFinalSegment();

    function concat(bytes32[] memory self, uint8 finalSegmentEnd) internal pure returns (bytes memory) {
        if (self.length == 0) {
            revert InvalidBytes32Length();
        }
        
        if (finalSegmentEnd > 32) {
            revert HighFinalSegment();
        }

        if (finalSegmentEnd == 0) {
            revert LowFinalSegment();
        }

        uint256 selfLength = self.length * 32;
        bytes memory tempBytes;
        
        assembly {
            tempBytes := mload(0x40)
            let selfPosition := add(self, 32)
            let endPosition := add(selfPosition, selfLength)
            let tempPosition := add(tempBytes, 32)

            for
                {}
                lt(selfPosition, endPosition)
                {
                    selfPosition := add(selfPosition, 32)
                }
            {
                mstore(tempPosition, mload(selfPosition))
                tempPosition := add(tempPosition, 32)
            }

            mstore(tempBytes, add(sub(selfLength, 32), finalSegmentEnd))
            mstore(0x40, tempPosition)
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IMagpieCore.sol";
import "../interfaces/IMagpieRouter.sol";
import "../interfaces/IWETH.sol";
import "./LibAssetUpgradeable.sol";

library LibSwap {
    using LibAssetUpgradeable for address;
    using LibSwap for IMagpieRouter.SwapArgs;

    function getFromAssetAddress(IMagpieRouter.SwapArgs memory self) internal pure returns (address) {
        return self.assets[self.routes[0].hops[0].path[0]];
    }

    function getToAssetAddress(IMagpieRouter.SwapArgs memory self) internal pure returns (address) {
        IMagpieRouter.Hop memory hop = self.routes[0].hops[self.routes[0].hops.length - 1];
        return self.assets[hop.path[hop.path.length - 1]];
    }

    function getAmountIn(IMagpieRouter.SwapArgs memory self) internal pure returns (uint256) {
        uint256 amountIn = 0;

        for (uint256 i = 0; i < self.routes.length; i++) {
            amountIn += self.routes[i].amountIn;
        }

        return amountIn;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieTest {
    error InvalidAmm();
    error InvalidAssets();
    error AssetNotReceived();
    error SwapFailed();
    error InvalidAmountIn();
    error InsufficientOutputAmount();

    struct Amm {
        uint8 protocolId;
        address ammAddress;
        bytes4 selector;
    }

    struct Swap {
        uint8 assetsLength;
        uint8 i;
        bool fromIsNative;
        bool toIsNative;
        uint256 hopsLength;
        uint256 amountIn;
        uint256 accAmountIn;
        uint256 lastAmountOut;
        address fromAssetAddress;
        address toAssetAddress;
    }

    struct Hop {
        uint8 j;
        uint16 ammId;
        uint16 amountInIndex;
        uint16 toAssetIndex;
        uint256 amountIn;
        address fromAssetAddress;
        address toAssetAddress;
    }

    function addAmm(uint16 ammId, Amm calldata amm) external;

    function removeAmm(uint16 ammId) external;

    // ammId, amountInIndex, toAssetIndex
    // amountIn, fromAsset, toAsset, to, amountOutMin, assetsLength
    function swap(bytes[] calldata hops, bytes calldata params) external payable returns (uint256 amountOut);

    event AmmAdded(uint16 ammId, Amm amm, address caller);

    event AmmRemoved(uint16 ammId, address caller);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieBridge {
    enum BridgeType {
        Wormhole,
        Stargate
    }

    struct BridgeConfig {
        address stargateRouterAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct BridgeArgs {
        bytes encodedVmBridge;
        bytes encodedVmCore;
        bytes senderStargateBridgeAddress;
        uint256 nonce;
        uint16 senderStargateChainId;
    }

    struct ValidationInPayload {
        bytes32 fromAssetAddress;
        bytes32 toAssetAddress;
        bytes32 to;
        bytes32 recipientCoreAddress;
        uint256 amountOutMin;
        uint256 layerZeroRecipientChainId;
        uint256 sourcePoolId;
        uint256 destPoolId;
        uint256 swapOutGasFee;
        uint16 recipientBridgeChainId;
        uint8 recipientNetworkId;
    }

    struct ValidationOutPayload {
        address fromAssetAddress;
        address toAssetAddress;
        address to;
        address recipientCoreAddress;
        bytes32 senderAddress;
        uint256 amountOutMin;
        uint256 swapOutGasFee;
        uint256 amountIn;
        uint64 tokenSequence;
        uint8 senderIntermediaryDecimals;
        uint8 senderNetworkId;
        uint8 recipientNetworkId;
        BridgeType bridgeType;
    }

    function updateConfig(BridgeConfig calldata _bridgeConfig) external;

    function bridgeIn(
        BridgeType bridgeType,
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress,
        address refundAddress
    )
        external
        payable
        returns (
            uint256 depositAmount,
            uint64 coreSequence,
            uint64 tokenSequence
        );

    function getPayload(bytes memory encodedVm)
        external
        view
        returns (ValidationOutPayload memory payload, uint64 sequence);

    function bridgeOut(
        ValidationOutPayload memory payload,
        BridgeArgs memory bridgeArgs,
        uint64 tokenSequence,
        address assetAddress
    ) external returns (uint256 amount);

    function updateMagpieCore(address _magpieCoreAddress) external;

    function adjustAssetDecimals(
        address assetAddress,
        uint8 fromDecimals,
        uint256 amountIn
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./IMagpieRouter.sol";
import "./IMagpieBridge.sol";

interface IMagpieCore {
    struct Config {
        address weth;
        address pauserAddress;
        address magpieRouterAddress;
        address magpieBridgeAddress;
        address stargateAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct SwapInArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieBridge.ValidationInPayload payload;
        IMagpieBridge.BridgeType bridgeType;
    }

    struct SwapOutArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieBridge.BridgeArgs bridgeArgs;
    }

    struct WrapSwapConfig {
        bool transferFromSender;
        bool prepareFromAsset;
        bool prepareToAsset;
        bool unwrapToAsset;
        bool swap;
    }

    function updateConfig(Config calldata config) external;

    function swap(IMagpieRouter.SwapArgs calldata args) external payable returns (uint256[] memory amountOuts);

    function swapIn(SwapInArgs calldata swapArgs)
        external
        payable
        returns (
            uint256[] memory amountOuts,
            uint256 depositAmount,
            uint64,
            uint64
        );

    function swapOut(SwapOutArgs calldata args) external returns (uint256[] memory amountOuts);

    function sgReceive(
        uint16 senderChainId,
        bytes memory magpieBridgeAddress,
        uint256 nonce,
        address assetAddress,
        uint256 amount,
        bytes memory payload
    ) external;

    event ConfigUpdated(Config config, address caller);

    event Swapped(IMagpieRouter.SwapArgs swapArgs, uint256[] amountOuts, address caller);

    event SwappedIn(
        SwapInArgs args,
        uint256[] amountOuts,
        uint256 depositAmount,
        uint8 receipientNetworkId,
        uint64 coreSequence,
        uint64 tokenSequence,
        bytes32 senderAddress,
        address caller
    );

    event SwappedOut(
        SwapOutArgs args,
        uint256[] amountOuts,
        uint8 senderNetworkId,
        uint64 coreSequence,
        bytes32 senderAddress,
        address caller
    );

    event GasFeeWithdraw(address indexed tokenAddress, address indexed owner, uint256 indexed amount);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieRouter {
    struct Amm {
        address id;
        uint16 index;
        uint8 protocolIndex;
    }

    struct Hop {
        uint16 ammIndex;
        uint8[] path;
        bytes poolData;
    }

    struct Route {
        uint256 amountIn;
        Hop[] hops;
    }

    struct SwapArgs {
        Route[] routes;
        address[] assets;
        address payable to;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function updateAmms(Amm[] calldata amms) external;

    function swap(SwapArgs memory swapArgs) external returns (uint256[] memory amountOuts);

    function updateMagpieCore(address _magpieCoreAddress) external;
    
    function updateMagpieSimulator(address _magpieSimulatorAddress) external;

    function withdraw(address weth, uint256 amount) external;

    event AmmsUpdated(Amm[] amms, address caller);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library LibAssetUpgradeable {
    using LibAssetUpgradeable for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20Upgradeable(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(self), from, to, amount);
    }

    function increaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
        SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(self), spender, amount);
    }

    function decreaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(!self.isNative(), "LibAsset: Allowance can't be decreased for native asset");
        SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(self), spender, amount);
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        self.isNative()
            ? AddressUpgradeable.sendValue(recipient, amount)
            : SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(self), recipient, amount);
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(self), spender, amount);
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20Upgradeable(self).allowance(owner, spender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
interface IERC20PermitUpgradeable {
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