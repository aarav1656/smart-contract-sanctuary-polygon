// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.eip.712.permit")`
bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = 0x24034dbc71162a0a127c76a8ce123f10641be888cbac564cd2e6e6f5e2c19b81;

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly {
        diamondStorage.slot := slot
    }
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
///      when using with a proxy, due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    bytes32 immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 immutable _NAME_HASH;
    bytes32 immutable _VERSION_HASH;

    constructor(string memory name, string memory version) {
        _EIP_712_DOMAIN_TYPEHASH =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return keccak256(abi.encode(_EIP_712_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
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
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner) revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade(logic);
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade(address logic) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.erc721")`
bytes32 constant DIAMOND_STORAGE_ERC721 = 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;

function s() pure returns (ERC721DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// ------------- errors

error NonexistentToken();
error NonERC721Receiver();
error MintExistingToken();
error MintToZeroAddress();
error BalanceOfZeroAddress();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();

/// @title ERC721 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721UDS is Initializable, EIP712PermitUDS("ERC721Permit", "1") {
    ERC721DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed operator, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- init ------------- */

    function __ERC721_init(string memory name_, string memory symbol_) internal virtual initializer {
        s().name = name_;
        s().symbol = symbol_;
    }

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = s().ownerOf[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return s().balanceOf[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return s().isApprovedForAll[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 id) public virtual {
        address owner = s().ownerOf[id];

        if (msg.sender != owner && !s().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = operator;

        emit Approval(owner, operator, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != s().ownerOf[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner =
            (msg.sender == from || s().isApprovedForAll[from][msg.sender] || s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            s().balanceOf[from]--;
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        delete s().getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    != ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    != ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(address owner, address operator, uint256 deadline, uint8 v, bytes32 r, bytes32 s_) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (s().ownerOf[id] != address(0)) revert MintExistingToken();

        unchecked {
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = s().ownerOf[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            s().balanceOf[owner]--;
        }

        delete s().ownerOf[id];
        delete s().getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0
                && ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    != ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0
                && ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    != ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0"; // Otherwise it'd output an empty string for 0.

        assembly {
            let k := 78 // Start with the max length a uint256 string could be.

            // We'll store our string at the first chunk of free memory.
            str := mload(0x40)

            // The length of our string will start off at the max of 78.
            mstore(str, k)

            // Update the free memory pointer to prevent overriding our string.
            // Add 128 to the str pointer instead of 78 because we want to maintain
            // the Solidity convention of keeping the free memory pointer word aligned.
            mstore(0x40, add(str, 128))

            // We'll populate the string from right to left.
            // prettier-ignore
            for {} n {} {
                // The ASCII digit offset for '0' is 48.
                let char := add(48, mod(n, 10))

                // Write the current character into str.
                mstore(add(str, k), char)

                k := sub(k, 1)
                n := div(n, 10)
            }

            // Shift the pointer to the start of the string.
            str := add(str, k)

            // Set the length of the string to the correct value.
            mstore(str, sub(78, k))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {
    function getOwnedIds(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;
        uint256 idsLength;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 32)
        }

        unchecked {
            uint256 end = collectionSize + 1;
            for (uint256 id = 0; id < end; ++id) {
                if (ownerMapping[id] == user) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 32)
                        idsLength := add(idsLength, 1)
                    }
                }
            }
        }

        assembly {
            mstore(ids, idsLength)
            mstore(0x40, memPtr)
        }
    }

    function balanceOf(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256 numOwned) {
        unchecked {
            uint256 end = collectionSize + 1;
            address owner;
            for (uint256 id = 0; id < end; ++id) {
                owner = ownerMapping[id];
                assembly {
                    numOwned := add(numOwned, eq(owner, user))
                }
            }
        }
    }

    function indexOf(address[] calldata arr, address addr) internal pure returns (bool found, uint256 index) {
        unchecked {
            for (uint256 i; i < arr.length; ++i) if (arr[i] == addr) return (true, i);
        }
        return (false, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {ERC721UDS, s as erc721ds} from "UDS/tokens/ERC721UDS.sol";

import "solmate/utils/LibString.sol";
import "src/lib/utils.sol";

contract MockERC721 is UUPSUpgrade, ERC721UDS {
    string baseURI;

    uint256 public totalSupply;

    function init(string memory _name, string memory _symbol, string memory uri) external initializer {
        __ERC721_init(_name, _symbol);

        baseURI = uri;

        for (uint256 i; i < 20; i++) {
            mint(msg.sender);
        }
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string.concat(baseURI, LibString.toString(id), ".json");
    }

    function mint(address to) public virtual {
        _mint(to, ++totalSupply);
    }

    function getOwnedIds(address user) external view returns (uint256[] memory ids) {
        return utils.getOwnedIds(erc721ds().ownerOf, user, 500);
    }

    function _authorizeUpgrade(address) internal virtual override {}
}