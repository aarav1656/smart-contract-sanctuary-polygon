// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function _owners(address admin) external view returns (bool);

    function approve(address spender, uint256 tokenId) external;

    function admin(address admin) external view returns (bool);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function ownerOf(uint256 id) external view returns (address);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function checkout(uint256 _tokenId) external;

    function royaltyAddress() external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract MarketPlace is Initializable, BaseRelayRecipient {
    event InstantBuy(
        address indexed from,
        address indexed to,
        uint256 price,
        uint256 indexed id
    );

    event Withdraw(address indexed receiver, uint256 val);
    event WithdrawBid(address indexed bidder, uint256 amount);
    event Bid(
        address indexed bidder,
        uint256 indexed id,
        uint256 bidAmount,
        uint32 endAt
    );
    event AssetClaimed(address indexed receiver, uint256 indexed id);
    event SetPrice(address indexed owner, uint256 indexed id, uint256 price);

    event Start(
        address indexed owner,
        uint256 indexed id,
        uint256 startPrice,
        uint32 endAt,
        uint64 startTime
    );
    event End(
        address indexed highestBidder,
        uint256 highestBid,
        uint256 indexed id
    );

    event ListItem(
        address indexed owner,
        uint256 indexed id,
        uint256 price,
        uint64 startTime
    );

    struct Auc {
        // uint256 nftId;
        address creator;
        // bool started;
        // bool ended;
        uint32 endAt;
        address highestBidder;
        // uint256 highestBid;
        uint256 startingBid;
        mapping(address => uint256) pendingReturns;
    }
    IERC721 private nftCollection;
    IERC20 public usdcToken;
    address public nftAddress;
    address public admin;
    uint256 public flatFee;
    uint256 public minBid;

    mapping(uint256 => Auc) public Auctions;

    mapping(address => uint256) public toPay;
    mapping(uint256 => uint256) public instantPrice;

    function initialize(
        address nftAddressCol,
        address _owner,
        address erc20,
        uint256 _flatFee,
        address newForward
    ) public initializer {
        nftCollection = IERC721(nftAddressCol);
        nftAddress = nftAddressCol;
        admin = _owner;
        usdcToken = IERC20(erc20);
        flatFee = _flatFee;
        BaseRelayRecipient._setTrustedForwarder(newForward);
        minBid = 1 * 10**6;
    }

    function setERC20(address _token) external {
        require(msg.sender == admin, "not admin");
        usdcToken = IERC20(_token);
    }

    function setFlatFee(uint256 _fee) external {
        require(msg.sender == admin, "not admin");
        flatFee = _fee;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        admin = _admin;
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function changeForward(address newForward) external {
        require(_msgSender() == admin, "NOT ALLOWED");
        BaseRelayRecipient._setTrustedForwarder(newForward);
    }

    function setPrice(uint256 _id, uint256 _price) external {
        address owner = nftCollection.ownerOf(_id);

        require(
            _msgSender() == owner || _msgSender() == nftAddress,
            "not owner"
        );

        if (
            _msgSender() == owner &&
            nftCollection.getApproved(_id) != address(this) &&
            !nftCollection.isApprovedForAll(owner, address(this))
        ) {
            nftCollection.approve(address(this), _id);
        }
        if (_msgSender() != nftAddress) {
            if (
                !nftCollection._owners(_msgSender()) &&
                !nftCollection.admin(_msgSender())
            ) {
                require(
                    usdcToken.transferFrom(_msgSender(), admin, flatFee),
                    "not enough tokens to list"
                );
            }
        }
        instantPrice[_id] = _price;
        emit SetPrice(_msgSender(), _id, _price);
    }

    function listItem(
        uint256 id,
        uint256 price,
        uint64 startTime
    ) external {
        address owner = nftCollection.ownerOf(id);
        require(_msgSender() == owner, "not owner");
        require(instantPrice[id] == 0, "item already listed");
        if (
            nftCollection.getApproved(id) != address(this) &&
            !nftCollection.isApprovedForAll(owner, address(this))
        ) {
            nftCollection.approve(address(this), id);
        }

        instantPrice[id] = price;
        emit ListItem(_msgSender(), id, price, startTime);
    }

    function instantBuy(uint256 _id) external {
        require(instantPrice[_id] > 0, "Not on sale");
        require(
            usdcToken.allowance(_msgSender(), address(this)) >=
                instantPrice[_id],
            "Not enough usdc"
        );
        require(
            nftCollection.getApproved(_id) == address(this) ||
                nftCollection.isApprovedForAll(
                    nftCollection.ownerOf(_id),
                    address(this)
                ),
            "not approved"
        );
        uint256 price = instantPrice[_id];
        instantPrice[_id] = 0;

        address owner = nftCollection.ownerOf(_id);
        require(
            usdcToken.transferFrom(_msgSender(), address(this), price),
            "transaction failed"
        );
        nftCollection.transferFrom(owner, _msgSender(), _id);

        (address royalty, uint256 royaltyFees) = nftCollection.royaltyInfo(
            _id,
            price
        );
        unchecked {
            toPay[royalty] += royaltyFees;
        }
        require(
            usdcToken.transfer(owner, price - royaltyFees),
            "transaction failed"
        );
        emit InstantBuy(owner, _msgSender(), price, _id);
    }

    function withdraw() external {
        require(toPay[_msgSender()] > 0, "we owe no money");
        uint256 val = toPay[_msgSender()];
        toPay[_msgSender()] = 0;
        // (bool success, ) = payable(_msgSender()).call{value: val}("");
        // require(success, "transaction failed");
        require(usdcToken.transfer(_msgSender(), val), "transaction failed");
        emit Withdraw(_msgSender(), val);
    }

    function startAuction(
        uint256 _id,
        uint256 _starting,
        uint32 duration,
        uint64 startTime
    ) external {
        address owner = nftCollection.ownerOf(_id);
        require(_msgSender() == owner, "Not owner");
        if (
            !nftCollection._owners(_msgSender()) &&
            !nftCollection.admin(_msgSender())
        ) {
            require(
                usdcToken.transferFrom(_msgSender(), admin, flatFee),
                "Not enough tokens to start auction"
            );
        }

        nftCollection.transferFrom(owner, address(this), _id);
        if (instantPrice[_id] > 0) {
            instantPrice[_id] = 0;
        }
        Auc storage auc = Auctions[_id];
        unchecked {
            auc.creator = owner;
            auc.endAt = uint32(block.timestamp + duration);
            // auc.nftId = _id;
            auc.startingBid = _starting;
            // auc.ended = false;
            // auc.started = true;
            auc.highestBidder = owner;
        }

        emit Start(owner, _id, _starting, auc.endAt, startTime);
    }

    // function started(uint256 _id) internal view returns (bool) {
    //     Auc storage auc = Auctions[_id];
    //     if (auc.endAt >= block.timestamp) {
    //         return true;
    //     }
    //     return false;
    // }

    function endAuction(uint256 _id) external {
        Auc storage auc = Auctions[_id];

        // require(auc.started, "Not started");
        // require(auc.ended == false, "End already");
        require(auc.endAt <= block.timestamp, "Time left");
        // auc.ended = true;
        address bidder = auc.highestBidder;
        auc.highestBidder = address(0);
        if (bidder != address(0)) {
            (address royalty, uint256 royaltyFees) = nftCollection.royaltyInfo(
                _id,
                auc.pendingReturns[bidder]
            );
            uint256 val = auc.pendingReturns[bidder] - royaltyFees;
            auc.pendingReturns[bidder] = 0;
            unchecked {
                if (auc.creator == royalty) {
                    toPay[royalty] += (val + royaltyFees);
                } else {
                    require(
                        usdcToken.transfer(auc.creator, val),
                        "transaction failed"
                    );
                    toPay[royalty] += royaltyFees;
                }
            }
            nftCollection.transferFrom(address(this), bidder, _id);
            emit AssetClaimed(bidder, _id);
            emit End(bidder, val + royaltyFees, _id);
        }
    }

    function bid(uint256 _id, uint256 bidAmount) external {
        Auc storage auc = Auctions[_id];
        require(auc.endAt > block.timestamp, "Ended");
        // require(auc.started == true, "Not started");
        require(
            (auc.pendingReturns[_msgSender()] + bidAmount) >
                auc.pendingReturns[auc.highestBidder] &&
                (auc.pendingReturns[_msgSender()] + bidAmount) >=
                auc.startingBid &&
                bidAmount >= minBid,
            "Only higher than current bid"
        );
        require(
            usdcToken.transferFrom(_msgSender(), address(this), bidAmount),
            "transaction failed"
        );
        unchecked {
            auc.pendingReturns[_msgSender()] += bidAmount;
        }
        // auc.highestBid = auc.pendingReturns[_msgSender()];
        auc.highestBidder = _msgSender();
        emit Bid(_msgSender(), _id, bidAmount, auc.endAt);
    }

    function withdrawBid(uint256 _id) external {
        Auc storage auc = Auctions[_id];

        address winner = auc.highestBidder;
        require(_msgSender() != winner, "Winner cannot withdraw");

        uint256 bal = auc.pendingReturns[_msgSender()];
        require(bal > 0, "Not a bidder");
        auc.pendingReturns[_msgSender()] = 0;
        // (bool success, ) = payable(_msgSender()).call{value: bal}("");
        // require(success, "transaction failed");
        require(usdcToken.transfer(_msgSender(), bal), "transaction failed");
        emit WithdrawBid(_msgSender(), bal);
    }

    function cancelListing(uint256 _id) external {
        Auc storage auc = Auctions[_id];
        require(
            usdcToken.transferFrom(_msgSender(), admin, flatFee),
            "not enough tokens to cancel Listing"
        );
        if (instantPrice[_id] > 0) {
            address owner = nftCollection.ownerOf(_id);
            require(_msgSender() == owner, "Not owner");
            instantPrice[_id] = 0;
            emit SetPrice(_msgSender(), _id, 0);
        } else {
            require(_msgSender() == auc.creator, "Not allowed");
            require(auc.endAt > block.timestamp, "Not ended");
            // auc.ended = true;
            // auc.highestBid = 0;
            auc.endAt = uint32(block.timestamp - 1);
            auc.highestBidder = address(0);

            nftCollection.transferFrom(address(this), auc.creator, _id);
            emit End(auc.creator, 0, _id);
        }
    }

    function getHighestBid(uint256 _tokenId) external view returns (uint256) {
        Auc storage auc = Auctions[_tokenId];
        if (auc.pendingReturns[auc.highestBidder] == 0) {
            return auc.startingBid;
        } else {
            return auc.pendingReturns[auc.highestBidder];
        }
    }

    function isActive(uint256 _tokenId) external view returns (bool) {
        Auc storage auc = Auctions[_tokenId];
        if ((auc.endAt < block.timestamp) && (auc.endAt > 0)) {
            return true;
        } else {
            return false;
        }
    }

    function checkoutMarket(uint256 _tokenId) external {
        require(_msgSender() == nftCollection.ownerOf(_tokenId), "Not owner");
        require(
            usdcToken.transferFrom(_msgSender(), admin, flatFee),
            "not enough tokens to checkout"
        );
        if (instantPrice[_tokenId] > 0) {
            instantPrice[_tokenId] = 0;
            emit SetPrice(_msgSender(), _tokenId, 0);
        }
        nftCollection.checkout(_tokenId);
    }

    function approveUsdc(
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        usdcToken.permit(_msgSender(), address(this), value, deadline, v, r, s);
    }

    function withdrawRoyalty() external {
        require(nftCollection._owners(_msgSender()) == true, "Not owner");
        address r = nftCollection.royaltyAddress();

        uint256 val = toPay[r];
        toPay[r] = 0;
        require(usdcToken.transfer(r, val), "transaction failed");
        emit Withdraw(r, val);
    }
}