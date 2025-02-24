/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/DrawToInfinitySiteManager.sol



pragma solidity >= 0.7.0 < 0.9.0;


contract DrawToInfinitySiteManager is Ownable {

    string private key;

    mapping (address => mapping (uint256 => bool)) public ordersHistory;

    address [] public ownersAddress = [
        0xE403c690E34c7cc4fb43C7d1054A1c6B25B1ecA6,
        0xbAD44655dd777Ef5F084AA60bC5b5430dE0f3A42,
        0xA7C09b871F3afecb62927169fD01F11c7e30424B
    ];
    

    function getPayment(string memory _key, uint256 _price, uint256 _id) public payable {
        require(keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked(key)));
        require (msg.value >= _price);

        ordersHistory[msg.sender] [_id] = true;
    }


    function getDonation() public payable {}


    function sendReward (uint256 _maticAmount, address _receiver) public onlyOwner {
        payable(_receiver).transfer(_maticAmount * 10 ** 18);
    }


    function getOwners() public view returns(address [] memory){
        return ownersAddress;
    }


    function setAddresses (address [] memory _addresses) public onlyOwner {
        require(_addresses.length > 0);
        ownersAddress = _addresses;
    }


    function setKey (string memory _key) public onlyOwner {
        key = _key;
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 x = 0; x < ownersAddress.length; x++){
            payable(ownersAddress[x]).transfer(balance / ownersAddress.length);
        }
    }
}