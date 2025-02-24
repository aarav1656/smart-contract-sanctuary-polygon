//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract TestDapps {

    string public message;
    uint256 public dappsCount;
    // dappId => count
    mapping(bytes32 => uint256) public subscriberCount;

    event NewAppRegistered(
        bytes32 appID, 
        address appAdmin, 
        string appName,
        uint256 dappCount
    );

    event AppAdmin(
        bytes32 appID,
        address appAdmin,
        address admin,
        uint8 role
    );

    event AppSubscribed(bytes32 appID, address subscriber, uint256 count);

    event AppUnSubscribed(bytes32 appID, address subscriber, uint256 count);

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta,
        bool isEncrypted
    );

    constructor(string memory _message) {
        // console.log("Deploying a Greeter with message:", _message);
        message = _message;
    }

    function registerApp(
        address _appAdmin, 
        string memory _appName
    ) public {
        bytes32 appID = keccak256(abi.encode(block.number, _appName, dappsCount));
        emit NewAppRegistered(appID, _appAdmin, _appName, dappsCount++);
    }

    function addDappAdmin(
        bytes32 _appID,
        address _appAdmin,
        address _admin,
        uint8 _role
    ) public {
        emit AppAdmin(_appID, _appAdmin, _admin, _role);
    }

    function toggleSubscribe(
        bytes32 _appID, 
        address _subscriber,
        bool _isSubscribe
    ) public {
        if(_isSubscribe) {
            subscriberCount[_appID] += 1;
            emit AppSubscribed(_appID, _subscriber, subscriberCount[_appID]);
        }
        else {
            subscriberCount[_appID] -= 1;
            emit AppUnSubscribed(_appID, _subscriber, subscriberCount[_appID]);
        }
    }

    function sendNotification(
        bytes32 _appId,
        address _walletAddress,
        string memory _message,
        string memory _buttonName,
        string memory _cta,
        bool _isEncrypted
    ) public {
        emit NewNotification(_appId, _walletAddress, _message, _buttonName, _cta, _isEncrypted);
    }
}