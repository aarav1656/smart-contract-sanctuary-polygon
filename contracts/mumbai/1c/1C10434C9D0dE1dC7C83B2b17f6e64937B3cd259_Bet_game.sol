/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: contracts/Bet_game.sol

//SPDX-License-Identifier:MIT
// rock paper scissors 
// creator Amar

pragma solidity ^0.8.6;



contract Bet_game is Ownable, ReentrancyGuard {

    struct data{
        address user1;
        address user2;
        uint amount ;
    }
    uint public service_fee_percent;
    // service fee of the owner which is received when withdrawn
    uint public owner_service_fee;

    //gameID=1
    mapping (string =>data) public bet_id_rps ;
    //gameID=2
    mapping (string =>data) public bet_id_cup ;

    // data in the blockchain for winners
     event winners_rps(address winner , uint amount);

     event winners_cup(address winner , uint amount);

    constructor(uint Service_Fee) {
        service_fee_percent = Service_Fee;
    }
     // This is called when the user want to set the service fee
     
    function set_service_fee(uint Service) external onlyOwner {
        service_fee_percent = Service;
    }

    // This is the function called when the users want to create a bid to play in different games based on gameID

    function create_bet(string memory betting_id, uint value , uint game_id) external nonReentrant returns(bool){
        require(msg.sender!=address(0),"Invalid address");
        require(value>0,"It minimum value must be greater than 0");
        uint total_bet = 2*value*1000000000;  
        if(game_id==1){
            bet_id_rps[betting_id].amount=total_bet;
            return true;
        }else if(game_id==2){
             bet_id_cup[betting_id].amount=total_bet;
             return true;
        }  
        return false;
    }

    // This is called when the both the users wants to join a bet which is already created by some user

    function join_bet(string memory betting_id, uint game_id ) payable external nonReentrant returns (bool){
        require(msg.sender!=address(0),"user validation");
        if(game_id==1){
            require(msg.value>=bet_id_rps[betting_id].amount/2,"The amount is insufficient");
            if(bet_id_rps[betting_id].user1==address(0)){
            bet_id_rps[betting_id].user1=msg.sender;
             }else{
            bet_id_rps[betting_id].user2=msg.sender;
        }
        return true;
        } else if(game_id==2){
            require(msg.value>=bet_id_cup[betting_id].amount/2,"The amount is insufficient");
            if(bet_id_cup[betting_id].user1==address(0)){
            bet_id_cup[betting_id].user1=msg.sender;
             }else{
            bet_id_cup[betting_id].user2=msg.sender;
        }
        return true;
        }
        return false;
    }

    // Incase the 2nd user had not participated in the bet then the user1 can withdraw the funds back in both the games

    function cancel_bet(string memory betting_id,uint game_id) external nonReentrant returns(bool){
        if(game_id==1){
            require((bet_id_rps[betting_id].user1==msg.sender && bet_id_rps[betting_id].user2==address(0)),"You might not be user1 or second user might paid the amount");
            payable(msg.sender).transfer(bet_id_rps[betting_id].amount/2);  
            delete bet_id_rps[betting_id];
            return true;
        }else if(game_id==2){
        require((bet_id_cup[betting_id].user1==msg.sender && bet_id_cup[betting_id].user2==address(0)),"You might not be user1 or second user might paid the amount");
            payable(msg.sender).transfer(bet_id_cup[betting_id].amount/2);      
            delete bet_id_cup[betting_id];
            return true;
        }
        return false;
    }
    // Once the winner is decided this function is called for both the games
    function winner(string memory betting_id , address payable won , uint game_id) external nonReentrant returns(bool){
        require(won==msg.sender,"Not the winner");
        if(game_id==1){
            require((bet_id_rps[betting_id].user1==won||bet_id_rps[betting_id].user2==won),"Not a valid winner");
             uint service_fee = (bet_id_rps[betting_id].amount * service_fee_percent)/100;
             uint winner_price = bet_id_rps[betting_id].amount-service_fee;
             won.transfer(winner_price);
             owner_service_fee=owner_service_fee+service_fee;
             emit winners_rps(won,winner_price);
             delete bet_id_rps[betting_id];
             return true; 
        }
        else if(game_id==2){
        require((bet_id_cup[betting_id].user1==won||bet_id_cup[betting_id].user2==won),"Not a valid winner");
        uint service_amount = (bet_id_cup[betting_id].amount * service_fee_percent)/100;
        uint winning_price = bet_id_cup[betting_id].amount-service_amount;
            won.transfer(winning_price);
            owner_service_fee=owner_service_fee+service_amount;
            emit winners_cup(won,winning_price);
            delete bet_id_cup[betting_id];
            return true;
        }
        return false;
    }

// owner is transfered with the funds available for the owner in the contract
    function with_draw_service_funds() external onlyOwner{
        address Owner = owner();
        payable(Owner).transfer(owner_service_fee);
        owner_service_fee=0;
    }

// Only used to trigger when the contract has no use and want to fetch all the balance 
    function with_draw_contract_balance() external onlyOwner{
        address Owner = owner();
        payable(Owner).transfer(address(this).balance);
    }

}