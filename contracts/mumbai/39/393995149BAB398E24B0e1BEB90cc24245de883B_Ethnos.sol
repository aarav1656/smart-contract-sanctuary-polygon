// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Ethnos {
    address public owner;
    address public service;
    
    mapping (address => bool) admins;
    mapping (address => bool) approved;

    event OwnershipTransferred(address _newOwner, address _previousOwner);
    event AdminUpdate(address _user, bool _isAdmin, address _approver);
    event UserApproved(address _user, address _approver);

    constructor (address _service) {
        owner = msg.sender;
        service = _service;
    }

    function checkApproved(address _user) public view returns (bool) { return approved[_user]; }
    function checkAdmin(address _user) public view returns (bool) { return admins[_user]; }

    function setAdmin(address _user, bool _isAdmin) public {
        _requireOwner();
        admins[_user] = _isAdmin;
        emit AdminUpdate(_user, _isAdmin, msg.sender);
    }

    function transferOwnership(address _newOwner) public {
        _requireOwner();
        address _oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(owner, _oldOwner);
    }

    function setApproved(address _user) public {
        _requireAdmin();
        approved[_user] = true;
        emit UserApproved(_user, msg.sender);
    }

    function _requireOwner() private view {
        require(msg.sender == owner, 'Must be contract owner');
    }

    function _requireAdmin() private view {
        require(admins[msg.sender] || msg.sender == service, 'Must be contract admin or service');
    }
}