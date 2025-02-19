/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

// SPDX-License-Identifier: GPLv3
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/FOMOBeta.sol



pragma solidity ^0.8.6;


contract FOMORushBeta is Ownable {

    address public creatorWallet;
    address public nftContract;
    address public lastDeposit;
    uint256 public minDeposit = 1 ether;
    uint256 public currentCountDown;
    uint256 public depositsPerCycle = 0;
    uint256 public newCycleGracePeriod = 1800;
    uint256 public timerIncrement = 20;
    uint256 public fee = 20;
    uint256 public winnerPercentage = 700;
    uint256 public nftHolderPercentage = 80;
    uint256 public percentageDivider = 1000;

    constructor(address creatorAddr, address NFTAddr, uint256 startTime) {
        creatorWallet = creatorAddr;
        nftContract = NFTAddr;
        currentCountDown = startTime;
    }

    function fomo() public payable {

        require(msg.value >= minDeposit, "Transaction is below minimum deposit.");

        // Transfer 5% creator fee
        uint256 creatorFee = msg.value * fee / percentageDivider;
        (bool creatorEarning, ) = payable(creatorWallet).call{value: creatorFee}("");
        require(creatorEarning, "Creator payout error");

        // FOMO ended...
        if (currentCountDown <= block.timestamp) {
            
            // No new player
            if (depositsPerCycle == 1) {
                // Refund player from previous round
                (bool refundPrevious, ) = payable(lastDeposit).call{value: minDeposit}("");
                require(refundPrevious, "Refund payout error");
            } else if (depositsPerCycle > 1) {
                // Transfer Reward
                uint256 totalReward = getBalance() - msg.value;
                uint256 winnerReward = totalReward * winnerPercentage / percentageDivider;
                uint256 nftReward = totalReward * nftHolderPercentage / percentageDivider;
                (bool winnerPayout, ) = payable(lastDeposit).call{value: winnerReward}("");
                require(winnerPayout, "Winner reward payout error.");
                (bool nftPayout, ) = payable(nftContract).call{value: nftReward}("");
                require(nftPayout, "NFT holder reward payout error.");
            }
            // Start new game cycle
            currentCountDown = block.timestamp + newCycleGracePeriod;
            // Reset player count
            depositsPerCycle = 0;

        // FOMO is still going on...
        } else {
            // Increase count down timer
            currentCountDown += timerIncrement;
        }

        lastDeposit = msg.sender;
        depositsPerCycle++;

    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getCurrentCountDown() public view returns(uint256){
        return currentCountDown;
    }

    function getCurrentWinner() public view returns(address){
        return lastDeposit;
    }

    function setNFTContract(address newNFTContract) external onlyOwner {
        nftContract = newNFTContract;
    }

    function setMinDeposit(uint256 newAmount) external onlyOwner {
        minDeposit = newAmount;
    }

    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    function setWinnerPercentage(uint256 newPercentage) external onlyOwner {
        winnerPercentage = newPercentage;
    }

    function setHolderPercentage(uint256 newPercentage) external onlyOwner {
        nftHolderPercentage = newPercentage;
    }

    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        newCycleGracePeriod = newGracePeriod;
    }

    function setTimerIncrement(uint256 newIncrement) external onlyOwner {
        timerIncrement = newIncrement;
    }

}