/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

contract donationExample {

    address payable owner;

    constructor() {
         owner = payable(msg.sender);
     }

     event Donate (
        address from,
        uint256 amount
     );

    function newDonation() public payable{
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(
            msg.sender,
            msg.value / 1000000000000000000
        );
    } 

}