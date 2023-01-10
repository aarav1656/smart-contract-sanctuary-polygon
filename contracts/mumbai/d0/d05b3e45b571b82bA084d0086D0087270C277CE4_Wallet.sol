// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    /**
    / Events
    */
    event Execution(
        address indexed destinationAddress,
        uint256 value,
        bytes txData
    );
    event ExecutionFailure(
        address indexed destinationAddress,
        uint256 value,
        bytes txData
    );
    event Deposit(address indexed sender, uint256 value);
    event OperatorChange(address indexed origin, address indexed current);
    event StaticCallsChange(address indexed origin, address indexed current);

    address public operatorContractAddress;
    address public staticCallsContractAddress;

    modifier onlyOperator() {
        require(
            msg.sender == operatorContractAddress,
            "Restricted to operators."
        );
        _;
    }

    constructor(address operatorContractAddress_, address staticCallsContractAddress_) {
        require(operatorContractAddress_ != address(0), "operator can't be null");
        require(staticCallsContractAddress_ != address(0), "staticCalls can't be null");
        operatorContractAddress = operatorContractAddress_;
        staticCallsContractAddress = staticCallsContractAddress_;
    }

    fallback() external payable {
        if (msg.data.length > 0) {
            //static call
            address loc = staticCallsContractAddress;
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), loc, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }

    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    function changeOperatorContractAddress(address operatorContractAddress_) external onlyOwner {
        require(operatorContractAddress_ != address(0), "operator can't be null");
        address preOperatorContractAddress = operatorContractAddress;
        operatorContractAddress = operatorContractAddress_;
        emit OperatorChange(preOperatorContractAddress, operatorContractAddress);
    }

    function changeStaticCallsContractAddress(address staticCallsContractAddress_) external onlyOwner {
        require(staticCallsContractAddress_ != address(0), "operator can't be null");
        address preStaticCallsContractAddress = staticCallsContractAddress;
        staticCallsContractAddress = staticCallsContractAddress_;
        emit OperatorChange(preStaticCallsContractAddress, staticCallsContractAddress);
    }

    /**
     * @dev function to call any on chain transaction
     * @dev verifies that the transaction data has been signed by the wallets controlling private key
     * @dev and that the transaction has been sent from an approved sending wallet
     * @param destination address - destination for this transaction
     * @param value uint - value of this transaction
     * @param data bytes - transaction data
     */
    function callTx(
        address destination,
        uint256 value,
        bytes memory data
    ) public payable onlyOperator returns (bool) {
        if (external_call(destination, value, data)) {
            emit Execution(destination, value, data);
        } else {
            emit ExecutionFailure(destination, value, data);
        }
        return (true);
    }

    /** External call function
     * Taken from Gnosis Mutli Sig wallet
     * https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
     */
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        bool result;
        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gas(),
                destination,
                value,
                d,
                mload(data), // Size of the input (in bytes)
                0,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
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