/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
// import "hardhat/console.sol";

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventId, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);

    event DepositsPaidOut(bytes32 eventId);

    struct Event {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => Event) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
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

        idToEvent[eventId] = Event(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        Event storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "Not enough for RSVP");

        require(block.timestamp <= myEvent.eventTimestamp, "Already happened");

        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "Event is at full capacity"
        );

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "Already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public payable {
        // look up event from our struct using the eventId
        Event storage myEvent = idToEvent[eventId];
        // require that msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "You are not the host");
        // require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }
        require(rsvpConfirm == attendee, "No RSVP to confirm");
        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee);
        }
        // require that deposits are not already claimed by the event owner
        require(!myEvent.paidOut, "Already paid out");
        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);
        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");
        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        Event memory myEvent = idToEvent[eventId];
        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "You are not the host");
        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        Event memory myEvent = idToEvent[eventId];
        // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "This has been paid out");
        // check if it's been 7 days past myEvent.eventTimestamp
        require(myEvent.eventTimestamp > 7 days, "It's too early");
        // only the event owner can withdraw
        require(
            msg.sender == myEvent.eventOwner,
            "You are not allowed to witdraw"
        );
        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;
        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;
        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");
        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}