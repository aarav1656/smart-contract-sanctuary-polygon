/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


pragma solidity ^0.8.4;

contract Web3RSVP {

    IERC20 token;
    address private owner;

        constructor()     {
        token = IERC20(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
        owner = msg.sender;
    }

    mapping(address => bool) whitelistedAddresses;

    modifier onlyOwner() {
      require(msg.sender == owner, "Ownable: caller is not the owner");
      _;
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted in order to create events.");
      _;
    }

    function addUserToWhitelist(address _addressToWhitelist) public onlyOwner {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function removeUserFromWhitelist(address _addressToRemove) public onlyOwner {
        whitelistedAddresses[_addressToRemove] = false;
    }

    function checkIfUserIsWhitelisted(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }


    /**Address to entity**/
    mapping(address => string) addressToEntity;

    function addAddressToEntity(address _addressToAdd, string memory _entity) public onlyOwner {
        addressToEntity[_addressToAdd] = _entity;
    }

    function removeAddressToEntity(address _addressToRemove) public onlyOwner {
        addressToEntity[_addressToRemove] = "";
    }

    function checkEntityAddress(address _entityAddress) public view returns(string memory) {
        string memory entity = addressToEntity[_entityAddress];
        return entity;
    }

    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        address depositAddress,
        uint256 creatorFee,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventID, address attendeeAddress, string _discordId);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        address depositAddress;
        uint256 creatorFee;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        address depositAddress,
        uint256 creatorFee,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external isWhitelisted(msg.sender) {
        // generate an eventID based on other things passed in to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            depositAddress,
            creatorFee,
            false
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            depositAddress,
            creatorFee,
            eventDataCID
        );
    }

    /*mapping(address => uint256) protocolFee;
    address METSOADDRESS = "0xED835CB39712805913ffE3E6542Ac5e90FF981c5";

    function updateMetsoReceiver(address protocolFeeReceiver) external{
        address METSOADDRESS = protocolFeeReceiver;
    }

    function checkMetsoReceiver() external {
        address METSOADDRESS = protocolFee[METSOADDRESS];
        return address METSOADDRESS;
    } */

    mapping(address => uint256) protocolFee;

    function updateProtocolFee(address _protocolAddress, uint256 _fee) public onlyOwner {
        protocolFee[_protocolAddress] = _fee;
    }

    function createNewRSVP(bytes32 eventId, string calldata _discordId) external {

        address protocolAddress = 0xED835CB39712805913ffE3E6542Ac5e90FF981c5;
        
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId]; 

        // require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "This event is in the past");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event is full"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        if (myEvent.deposit > 0) {
            uint256 metsoShare = (myEvent.deposit * protocolFee[protocolAddress] / 100000000000000000000);
            uint256 creatorShare = (myEvent.deposit * myEvent.creatorFee / 100000000000000000000);
            uint256 eventShare = myEvent.deposit - (creatorShare + metsoShare);

            token.transferFrom(msg.sender, protocolAddress, metsoShare);
            token.transferFrom(msg.sender, myEvent.depositAddress, creatorShare);
            token.transferFrom(msg.sender, myEvent.depositAddress, eventShare);
        }

        myEvent.confirmedRSVPs.push(msg.sender);
    
        emit NewRSVP(eventId, msg.sender, _discordId);
    }
}