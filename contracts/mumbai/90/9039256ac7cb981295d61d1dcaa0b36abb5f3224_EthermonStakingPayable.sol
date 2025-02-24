/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

contract EthermonStakingPayable {
    event Payment(uint256 _received, address _owner);
    event Called(address _owner);

    function callFunc() public {
        emit Called(msg.sender);
    }

    function() public payable {
        emit Payment(msg.value, msg.sender);
    }
}