// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OrgRegistry.sol";

import "./IDRegistry.sol";

contract KYCGov is Ownable {

    OrgRegistry OrgR;

    IDRegistry IDR;

    constructor ( ) Ownable(){}

    function SetOrgRegistry( address _orgR ) external onlyOwner{
        OrgR = OrgRegistry(_orgR);
    }

    function SetIDRegistry( address _orgR ) external onlyOwner{
        IDR = IDRegistry(_orgR);
    }

    function setOrg( address _org ) external onlyOwner {
        OrgR.setOrg(_org);
    }

    function unsetOrg( address _org ) external onlyOwner {
        OrgR.unsetOrg(_org);
    }

    function SetType( uint8 _type, string memory _data ) external onlyOwner {
        IDR.SetType(_type , _data);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Registered Banks / Org
contract OrgRegistry {

    address private kycGov;

    mapping ( address => bool ) private Orgs;

    modifier isGov( ){
        require( msg.sender == kycGov," Error not KYC Gov");
        _;
    }

    constructor ( address _kycGov ) {
        kycGov = _kycGov;
    }

    function setOrg( address _orgAddr) external isGov{
        Orgs[_orgAddr] = true;
    }

    function unsetOrg( address _orgAddr) external isGov{
        Orgs[_orgAddr] = false;
    }

    function fetchOrg( address _orgAddr) external view returns ( bool ){
        return Orgs[_orgAddr];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IDRegistry {

    address private kycGov;

    address private kycCore;

    mapping ( bytes32 => mapping ( uint8 => userStruct ) ) private userData; // Hash of ID no -> id type( Aaddhar / passort / pancard etc ) ->

    // (HASH - TDType) - USERStruct
    struct userStruct {
        address _verifier;
        uint256 _time;
        bool status;
    }

    mapping( bytes32 => mapping ( address => bool )) private hasAccess;

    mapping ( uint8 => string ) private idTypeData;

    modifier isGov( ){
        require( msg.sender == kycGov," Error not KYC Gov");
        _;
    }

    modifier isCore( ){
        require( msg.sender == kycCore ," Error not KYC Core");
        _;
    }

    constructor ( address _kycGov , address _kycCore ) {
        kycGov = _kycGov;
        kycCore = _kycCore;
    }

    function SetType( uint8 _type, string memory _data ) external isGov {
        idTypeData[_type] = _data;
    }

    function SetKYC( bytes32 _hash , uint8 _id , address _veri ) external isCore {
        userData[_hash][_id] = userStruct( _veri , block.timestamp , true);
    }

    function SetAccess( bytes32 _hash , address _veri ) external isCore {
        hasAccess[_hash][_veri] = true;
    }

    function fetchUserData( bytes32 _hash , uint8 _type ) external view returns ( userStruct memory ){
        return userData[_hash][_type];
    }

    function fetchHasaccess( bytes32 _hash , address _addr ) external view returns ( bool ){
        return hasAccess[_hash][_addr];
    }

    function fetchType( uint8 _type ) external view returns ( string memory ){
        return idTypeData[_type];
    }

}

// SPDX-License-Identifier: MIT
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