/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

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

// File: contracts/raffle.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract raffle is Ownable {

    uint256 private price;
    uint256 private period;
    uint8 private ratio;
    uint8 private startRatio;
    uint8 private endRatio;

    mapping(uint256 => bool) private state;
    mapping(uint256 => uint256) private pot;
    mapping(uint256 => uint256) private startIncentive;
    mapping(uint256 => address) private starter;
    mapping(uint256 => uint256) private endIncentive;
    mapping(uint256 => address) private finisher;
    mapping(address => uint256) private rewards;
    mapping(uint256 => uint256) private totalEntries;
    mapping(uint256 => uint256) private startDate;
    mapping(uint256 => uint256) private endDate;
    mapping(uint256 => address) private winner;
    mapping(uint256 => mapping(uint256 => address)) private entries;
    mapping(uint256 => mapping(address => uint256)) private participant;

    uint256 private id = 0;
    uint256 private entry = 0;
    uint256 private claimRemaining = 0;
    bool private maintenance = false;

    event Start(uint256 indexed id, address indexed starter, uint256 startIncentive);
    event Participation(uint256 indexed id, address indexed participant, uint256 entry, uint256 entries);
    event End(uint256 indexed id, address indexed winner, uint256 entry, uint256 prize, address indexed finisher, uint256 endIncentive);

    constructor(uint256 _price, uint8 _ratio, uint8 _startRatio, uint8 _endRatio, uint256 _period) {
        price = _price;
        ratio = _ratio;
        startRatio = _startRatio;
        endRatio = _endRatio;
        period = _period;
    }

    //Main

    function start() external payable notActive {
        require(!maintenance, "Raffle system in maintenance");

        pot[id] = msg.value;
        state[id] = true;
        startDate[id] = block.timestamp;
        starter[id] = msg.sender;
        rewards[msg.sender] += startIncentive[id];
        claimRemaining += startIncentive[id];

        emit Start(id, msg.sender, startIncentive[id]);
    }

    function participate() external payable active {
        require(msg.value >= price, "Incorrect payment");

        participant[id][msg.sender]++;
        entries[id][entry] = msg.sender;
        totalEntries[id]++;
        pot[id] += (msg.value * ratio) / 100;
        endIncentive[id] += (msg.value * endRatio) / 100;
        startIncentive[id + 1] += (msg.value * startRatio) / 100;

        emit Participation(id, msg.sender, entry, participant[id][msg.sender]);

        entry++;
    }

    function end() external active {
        require(block.timestamp - startDate[id] > period, "Raffle period not finished");

        uint256 _number = randNumber(totalEntries[id]);
        address _winner = entries[id][_number];
        winner[id] = _winner;
        rewards[_winner] += pot[id];
        rewards[msg.sender] += endIncentive[id];
        claimRemaining += pot[id] + endIncentive[id];
        state[id] = false;
        endDate[id] = block.timestamp;
        finisher[id] = msg.sender;

        emit End(id, _winner, _number, pot[id], msg.sender, endIncentive[id]);

        entry = 0;
        id++;
    }

    function claimReward() external {
        require(rewards[msg.sender] > 0, "Nothing to claim");
        require(address(this).balance >= rewards[msg.sender], "Not enough balance");

        payable(msg.sender).transfer(rewards[msg.sender]);
        claimRemaining -= rewards[msg.sender];
        rewards[msg.sender] = 0;
    }

    function withdraw() external onlyOwner notActive {
        require(address(this).balance - claimRemaining > 0, "Nothing to withdraw");

        payable(msg.sender).transfer(address(this).balance - claimRemaining);
    }

    //Utils

    function randNumber(uint256 _maxNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % _maxNumber;
    }

    //SETTERS - Management

    function setPrice(uint256 _amount) external onlyOwner notActive {
        price = _amount;
    }

    function setPeriod(uint256 _seconds) external onlyOwner notActive {
        period = _seconds;
    }

    function setMaintenance(bool _stat) external onlyOwner {
        maintenance = _stat;
    }

    function setRatio(uint8 _ratio) external onlyOwner notActive {
        require(_ratio >= 0 && _ratio <= 100, "Ratio out of range (0 to 100)");
        require(_ratio + startRatio + endRatio <= 100, "Exceeded ratio");

        ratio = _ratio;
    }

    function setStartRatio(uint8 _ratio) external onlyOwner notActive {
        require(_ratio >= 0 && _ratio <= 100, "Ratio out of range (0 to 100)");
        require(ratio + _ratio + endRatio <= 100, "Exceeded ratio");

        startRatio = _ratio;
    }

    function setEndRatio(uint8 _ratio) external onlyOwner notActive {
        require(_ratio >= 0 && _ratio <= 100, "Ratio out of range (0 to 100)");
        require(ratio + startRatio + _ratio <= 100, "Exceeded ratio");

        endRatio = _ratio;
    }

    //GETTERS - Config

    function rId() public view returns (uint256) {
    return id;
    }

    function rPot() public view returns (uint256) {
        return pot[id];
    }

    function rPrice() public view returns (uint256) {
        return price;
    }

    function rPeriod() public view returns (uint256) {
        return period;
    }

    function rEntries() public view returns (uint256) {
        return totalEntries[id];
    }

    function rStartDate() public view returns (uint256) {
        return startDate[id];
    }

    function rExpectedEndDate() active public view returns (uint256) {
        return startDate[id] + period;
    }

    function rEndIncentive() public view returns (uint256) {
        return endIncentive[id];
    }

    function rStarter() public view returns (address) {
        return starter[id];
    }

    //GETTERS - General

    function getPot(uint256 _id) public view returns (uint256) {
    return pot[_id];
    }

    function getTotalEntries(uint256 _id) public view returns (uint256) {
        return totalEntries[_id];
    }

    function getWinner(uint256 _id) public view returns (address) {
        return winner[_id];
    }

    function getStartDate(uint256 _id) public view returns (uint256) {
        return startDate[_id];
    }

    function getEndtDate(uint256 _id) public view returns (uint256) {
        return endDate[_id];
    }

    function getStartIncentive(uint256 _id) public view returns (uint256) {
        return startIncentive[_id];
    }

    function getEndIncentive(uint256 _id) public view returns (uint256) {
        return endIncentive[_id];
    }

    function getStarter(uint256 _id) public view returns (address) {
        return starter[_id];
    }

    function getFinisher(uint256 _id) public view returns (address) {
        return finisher[_id];
    }

    //GETTERS - State

    function checkMaintenance() public view returns (bool) {
        return maintenance;
    }

    function checkState() public view returns (bool) {
        return state[id];
    }

    function chechEnd() public view returns (bool) {
        return state[id] && block.timestamp - startDate[id] > period;
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //GETTERS - User

    function myEntries() public view returns (uint256) {
        return participant[id][msg.sender];
    }

    function myEntriesByRaffle(uint256 _id) public view returns (uint256) {
        return participant[_id][msg.sender];
    }

    function myPendingReward() public view returns (uint256) {
        return rewards[msg.sender];
    }

    //Modifiers

    modifier notActive {
      require(!state[id], "Raffle in process");
      _;
    }

    modifier active {
      require(state[id], "No raffle in process");
      _;
    }

}