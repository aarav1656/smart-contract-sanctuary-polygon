// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.access.control")`
bytes32 constant DIAMOND_STORAGE_ACCESS_CONTROL = 0xd229c8df724bc36c62cde04d6d208a43a60480edccfde27ef78f260014374ebd;

function s() pure returns (AccessControlDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ACCESS_CONTROL;
    assembly {
        diamondStorage.slot := slot
    }
}

struct AccessControlDS {
    mapping(bytes32 => RoleData) roles;
}

struct RoleData {
    bytes32 adminRole;
    mapping(address => bool) members;
}

// ------------- errors

error NotAuthorized();
error RenounceForCallerOnly();

/// @title AccessControl (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
/// @dev Requires `__AccessControl_init` to be called in proxy
abstract contract AccessControlUDS is Initializable {
    AccessControlDS private __storageLayout; // storage layout for upgrade compatibility checks

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /* ------------- init ------------- */

    function __AccessControl_init() internal initializer {
        s().roles[DEFAULT_ADMIN_ROLE].members[msg.sender] = true;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x7965db0b; // ERC165 Interface ID for AccessControl
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return s().roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return s().roles[role].adminRole;
    }

    /* ------------- public ------------- */

    function grantRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _revokeRole(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);

        if (!hasRole(previousAdminRole, msg.sender)) revert NotAuthorized();

        _setRoleAdmin(role, adminRole);
    }

    function renounceRole(bytes32 role) public virtual {
        s().roles[role].members[msg.sender] = false;

        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    /* ------------- internal ------------- */

    function _grantRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        s().roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    }

    /* ------------- modifier ------------- */

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert NotAuthorized();
        _;
    }
}

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

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.ownable")`
bytes32 constant DIAMOND_STORAGE_OWNABLE = 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
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

/// @dev diamond storage slot `keccak256("diamond.storage.erc20")`
bytes32 constant DIAMOND_STORAGE_ERC20 = 0x0e539be85842d1c3b5b43263a827c1e07ab5a9c9536bf840ece723e480d80db7;

function s() pure returns (ERC20DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is Initializable, EIP712PermitUDS("ERC20Permit", "1") {
    ERC20DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed operator, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(string memory _name, string memory _symbol, uint8 _decimals) internal virtual initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address owner, address operator) public view virtual returns (uint256) {
        return s().allowance[owner][operator];
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 amount) public virtual returns (bool) {
        s().allowance[msg.sender][operator] = amount;

        emit Approval(msg.sender, operator, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[msg.sender] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][msg.sender];

        if (allowed != type(uint256).max) s().allowance[from][msg.sender] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(address owner, address operator, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s_)
        public
        virtual
    {
        _usePermit(owner, operator, value, deadline, v, r, s_);

        s().allowance[owner][operator] = value;

        emit Approval(owner, operator, value);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS, s as erc20ds} from "../ERC20UDS.sol";

/// @title ERC20Burnable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @notice Allows for burning ERC20 tokens
abstract contract ERC20BurnableUDS is ERC20UDS {
    /* ------------- public ------------- */

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public virtual {
        if (msg.sender != from) {
            uint256 allowed = erc20ds().allowance[from][msg.sender];

            if (allowed != type(uint256).max) erc20ds().allowance[from][msg.sender] = allowed - amount;
        }

        _burn(from, amount);
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
pragma solidity ^0.8.0;

import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {ERC20BurnableUDS} from "UDS/tokens/extensions/ERC20BurnableUDS.sol";
import {AccessControlUDS} from "UDS/auth/AccessControlUDS.sol";

/// @title Gang Token
/// @author phaze (https://github.com/0xPhaze)
contract GangToken is UUPSUpgrade, OwnableUDS, ERC20BurnableUDS, AccessControlUDS {
    uint8 public constant override decimals = 18;

    bytes32 constant AUTHORITY = keccak256("AUTHORITY");

    function init(string calldata name_, string calldata symbol_) external initializer {
        __Ownable_init();
        __AccessControl_init();
        __ERC20_init(name_, symbol_, 18);
    }

    /* ------------- external ------------- */

    function mint(address user, uint256 amount) external onlyRole(AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address from, uint256 amount) public override {
        if (msg.sender == from || hasRole(AUTHORITY, msg.sender)) _burn(from, amount);
        else super.burnFrom(from, amount);
    }

    /* ------------- owner ------------- */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function airdrop(address[] calldata tos, uint256 amount) external onlyOwner {
        unchecked {
            for (uint256 i; i < tos.length; ++i) {
                _mint(tos[i], amount);
            }
        }
    }

    function airdrop(address[] calldata tos, uint256[] memory amounts) external onlyOwner {
        unchecked {
            for (uint256 i; i < tos.length; ++i) {
                _mint(tos[i], amounts[i]);
            }
        }
    }
}