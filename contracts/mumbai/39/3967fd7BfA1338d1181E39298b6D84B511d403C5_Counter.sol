/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/interfaces/interfaces.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMessageBridge {
  function send(
    address user,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory signature
  ) external payable;

  function execute(
    address from,
    address to,
    uint256 value,
    uint256 nonce,
    uint256 bond,
    bytes memory data,
    bytes memory signature
  ) external;
}

// File solmate/src/auth/[email protected]

pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event OwnerUpdated(address indexed user, address indexed newOwner);

  /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

  address public owner;

  modifier onlyOwner() virtual {
    require(msg.sender == owner, "UNAUTHORIZED");

    _;
  }

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _owner) {
    owner = _owner;

    emit OwnerUpdated(address(0), _owner);
  }

  /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

  function setOwner(address newOwner) public virtual onlyOwner {
    owner = newOwner;

    emit OwnerUpdated(msg.sender, newOwner);
  }
}

// File contracts/Counter.sol

pragma solidity >=0.8.15;

// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Counter is Owned {
  /// @notice bridge to send
  address public immutable bridge;

  /// @notice counter
  uint256 public count;

  /// @notice event emitted when counter is called
  event CounterLatest(uint256 counter);

  /// @notice constructor sets the bridge on current chain
  constructor(address _bridge) Owned(_bridge) {
    bridge = _bridge;
  }

  /// @notice Increment the counter
  function increment() public onlyOwner {
    count += 1;
    emit CounterLatest(count);
  }

  /// @notice Send message to another chain
  /// @param to address of the contract to be called
  /// @param value value to be sent to the contract
  /// @param data data to be sent to the contract
  /// @param signature signature of the transaction
  function send(
    address to,
    uint256 value,
    bytes memory data,
    bytes memory signature
  ) public payable {
    IMessageBridge(bridge).send(
      msg.sender, // user requesting this cross-chain txn
      to,
      value,
      data,
      signature
    );
  }
}