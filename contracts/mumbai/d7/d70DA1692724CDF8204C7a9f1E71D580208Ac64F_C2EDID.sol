//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract C2EDID {
    uint256 autoID;

    struct DID {
        uint256 id;
        string username;
        address controller;
        string didDoc;
    }

    modifier onlyController() {
        require(
            dids[msg.sender].controller == msg.sender,
            "sender is not the controller of the DID"
        );
        _;
    }

    mapping(address => DID) public dids; // address to DID
    mapping(uint256 => address[]) controllers; // did id to addresses
    mapping(string => uint256) usernames; //username to did id

    event DIDCreated(
        address sender,
        uint256 didID,
        string doc,
        string username
    );

    event DIDUpdated(
        address sender,
        uint256 didID,
        string doc,
        address[] addedAddresses
    );

    event DIDDeleted(address sender, uint256 didID);

    function createDID(string memory _doc, string memory _username) external {
        require(dids[msg.sender].id == 0, "address already had did");
        uint256 _didID = ++autoID;
        DID memory _did = DID(_didID, _username, msg.sender, _doc);
        dids[msg.sender] = _did;
        controllers[_didID].push(msg.sender);
        usernames[_username] = _didID;

        emit DIDCreated(msg.sender, _didID, _doc, _username);
    }

    function updateDIDDoc(
        string memory _doc,
        address[] memory _addresses
    ) external onlyController {
        DID storage _did = dids[msg.sender];
        address[] storage _controllers = controllers[_did.id];
        _did.didDoc = _doc;
        for (uint i = 0; i < _addresses.length; i++) {
            if (!_isArrayContain(_controllers, _addresses[i])) {
                _controllers.push(_addresses[i]);
            }
            dids[_addresses[i]] = _did;
        }
        emit DIDUpdated(msg.sender, _did.id, _doc, _addresses);
    }

    function deleteDIDDoc() external onlyController {
        DID memory _did = dids[msg.sender];
        address[] memory _controllers = controllers[_did.id];

        for (uint i = 0; i < _controllers.length; i++) {
            delete dids[_controllers[i]];
        }

        delete usernames[_did.username];
        delete controllers[_did.id];
        emit DIDDeleted(msg.sender, _did.id);
    }

    function getDIDDoc(address _address) external view returns (string memory) {
        return dids[_address].didDoc;
    }

    function getUsername(
        address _address
    ) external view returns (string memory) {
        return dids[_address].username;
    }

    function isUniqueUsername(
        string memory _username
    ) external view returns (bool) {
        if (usernames[_username] == 0) return true;
        return false;
    }

    function _isArrayContain(
        address[] memory _arr,
        address _item
    ) private pure returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _item) {
                return true;
            }
        }
        return false;
    }
}