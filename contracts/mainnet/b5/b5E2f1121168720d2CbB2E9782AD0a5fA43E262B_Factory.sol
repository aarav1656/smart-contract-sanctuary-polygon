/**
 *Submitted for verification at polygonscan.com on 2023-01-29
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/utils/Strings
// License: MIT
library Utils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// @openzepplin/contracts/token/ERC20/IERC20
// License: MIT
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
* @title Squid Contract Factory.
* @author DSDK Technologies.
* @notice You can use this factory to create and interface with squids.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Factory {

    address payable private owner;

    uint public creationFee;
    uint32 public transactionFee;
    uint64 private idCounter;

    address private manager;
    mapping(uint64 => Squid) private squids;
    mapping(address => uint64) private squidIDs;
    mapping(address => uint64[]) private asocSquids;
    mapping(address => uint64[]) private createdSquids;

    /**
    * @notice Executed when contract is deployed. Defines the owner.
    * of the contract, as the message sender. It also sets the initial
    * fee values.
    */
    constructor() {
        owner = payable(msg.sender);
        manager = msg.sender;
        creationFee = 10000000000000000; // Wei
        transactionFee = 1000000; // Fraction of 100000000
        idCounter = 69;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Error: 1000");
        _;
    }

    receive() external payable {}

    /**
    * @notice Use this contract to create a new Squid smart contract.
    * @param _name Name of the contract.
    */
    function create(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint64[] memory _shares,
        bool _automatic
    ) external payable {

        uint64 id = ++idCounter;

        require(!exists(id), 'Error: 1001');
        require(msg.value >= creationFee, 'Error: 1002');
        require(bytes(_name).length <= 20, 'Error: 1003');
        require(bytes(_description).length <= 50, '1003');
        require(_payees.length == _shares.length, 'Error: 1004');

        if(_automatic) { require(_payees.length <= 8, "Error: 1013"); }

        uint64 total_shares;
        for(uint16 i = 0; i < _shares.length; i++) {
            total_shares += _shares[i];
        }

        require(total_shares <= 1000000000000, 'Error: 1005');

        squids[id] = new Squid(
            _name,
            _description,
            _payees,
            _shares,
            total_shares,
            transactionFee,
            msg.sender,
            address(this)
        );

        for(uint16 i = 0; i < _payees.length; i++) {
            asocSquids[_payees[i]].push(id);
        }

        createdSquids[msg.sender].push(id);

    }

    /**
    * @notice Retrieve all data (except shareholders) about a specific Squid.
    * @param _id UUID used to identify which squid to access.
    * @return result An array of strings which contains the collated data.
    */
    function getShareData(uint64 _id, address _account) public view returns (string[] memory) {
        string[] memory result;
        if(!exists(_id)) { return result; }
        return squids[_id].getData(_account);
    }

    /**
    * @notice Allows the retrieval of all UUIDs associated with an address
    * where the address is a payee of a squid.
    * @param _account Address of account to retrieve UUIDs for.
    * @return UUIDs An array of UUIDs.
    */
    function getIds(address _account) public view returns (uint64[] memory) {
        return asocSquids[_account];
    }

    /**
    * @notice Allows the retrieval of all UUIDs associated with an address
    * where the address is a creator of a Squid.
    * @param _account Address of account to retrieve UUIDs for.
    * @return UUIDs An array of UUIDs.
    */
    function getCreatedIds(address _account) public view returns (uint64[] memory) {
        return createdSquids[_account];
    }

    /**
    * @notice Retrieves all shareholders and their number of assigned shares.
    * @param _id UUID of a Squid.
    * @return sharholders An array containing each address and associated shares
    * founnd within a Squid. 
    */
    function getShareholders(uint64 _id) public view returns (string[] memory) {
        return squids[_id].getShareholders();
    }

    /**
    * @notice The owner of the contract factory can set a new owner
    * transferring permissions.
    */
    function changeOwner(address _account) onlyOwner public {
        owner = payable(_account);
    }

    /**
    * @notice The owner of the contract factory can set a new owner
    * transferring permissions.
    */
    function changeManager(address _account) onlyOwner public {
        manager = _account;
    }

    /**
    * @notice Allows only the contract owner to change the creation fee
    * as long as the new fee is not less than 0.
    * @param _fee The new fee value which will be used henceforth.
    */
    function changeCreationFee(uint _fee) onlyOwner public {
        require(_fee >= 0, 'Error: 1006');
        creationFee = _fee;
    }

    /**
    * @notice Allows only the contract owner to change the transaction fee
    * as long as the new fee is not less than 0. When a fee is changed it will
    * only apply to new squids being created.
    * @param _fee The new fee value which will be used henceforth.
    */
    function changeTransactionFee(uint32 _fee) onlyOwner public {
        require(_fee >= 0, 'Error: 1006');
        transactionFee = _fee;
    }

    /**
    * @notice The owner of the contract can release accumulated fees to their wallet.
    */
    function releaseFunds(IERC20 _token, bool _matic) onlyOwner public {
        if(!_matic) {
            _token.transfer(owner, _token.balanceOf(address(this)));
        } else {
            owner.transfer(address(this).balance);
        }
    }

    /**
    * @notice Owner and assigned manager can enter an array of ids to initiate global
    * payouts. If an ID does not exist it will be skipped.
    * @param _ids Array of UUIDS
    */
    function flush(uint64[] memory _ids, IERC20 _token, bool _matic) public {
        require(msg.sender == owner || msg.sender == manager, "Error: 1000");
        for(uint i = 0; i < _ids.length; i++) {
            if(!exists(_ids[i])) { continue; }
            if(!_matic) {
                squids[_ids[i]].payoutAllTokenized(_token);
            } else {
                squids[_ids[i]].payoutAll();
            }
        }
    }

    /**
    * @notice Allows a payee to withdraw available funds from a squid.
    * @param _id UUID of a squid.
    */
    function payout(uint64 _id) external {
        squids[_id].payout(msg.sender);
    }

    /**
    * @notice Allows the creator of a squid to release the funds to all payees.
    * @param _id UUID of a squid.
    * @param _token Address of smart contract for Token
    & @param _matic False if using token
    */
    function payoutAll(uint64 _id, IERC20 _token, bool _matic) external {
        require(squids[_id].getCreator() == msg.sender, 'Error: 1011');
        if(!_matic) {
            squids[_id].payoutAllTokenized(_token);
        } else {
            squids[_id].payoutAll();
        }
    }


    /**
    * @notice Checks whether a unique universal identifier already exists.
    * @param _id UUID to be checked.
    * @return bool true if UUID exists, false if not.
    */
    function exists(uint64 _id) private view returns (bool) {
        if(address(squids[_id]) != address(0)) {
            return true;
        }
        return false;
    }
}

/**
* @title Squid Smart Contract.
* @author DSDK Technologies.
* @notice A Squid is a collection of crypto addresses each with an assigned number of shares.
* Once a Squid has been created it can no longer be modified and all share values are fixed.
* If a payee wants to withdraw any monies from the Squid they can only withdraw the amount
* they are entitled to which is determined by the amount of shares they have been allocated.
* The creator of the Squid has the ability to flush the contract and all payees will be
* transferred their share of any monies remaining.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Squid {

    address factory;
    address creator;
    string name;
    string description;
    bool automatic;
    uint64 total_shares = 0;
    uint total_revenue = 0;
    uint32 fee;
    address[] payees;
    mapping(address => uint) shareholders;
    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;
    mapping(uint => string[]) transactions;

    /**
    * @notice Executed when a new Squid is created.
    * @param _name Name of the Squid (max 20 characters).
    * @param _description Description of the Squid (max 50 characters).
    * @param _payees This is an array of addresses of all the payees to be stored
    * within the Squid contract.
    * @param _shares This is an array of values which stores the number of shares
    * for each shareholder.
    * @param _total_shares This is the total number of shares allocated.
    * @param _fee This is a fixed value which determines the fee paid when monies
    * are withdrawn from the wallet.
    * @param _creator This is the address of the wallet which called for a new
    * contract to be created and alloted the shares for all payees.
    */
    constructor(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint64[] memory _shares,
        uint64 _total_shares,
        uint32 _fee,
        address _creator,
        address _factory
    ) {
        name = _name;
        description = _description;
        total_shares = _total_shares;
        payees = _payees;
        fee = _fee;
        creator = _creator;
        factory = _factory;

        for(uint16 i = 0; i < _payees.length; i++) {
            shareholders[_payees[i]] = _shares[i];
        }
    }

    /**
    * @notice Executed when a payment is made to the contract address when data is empty.
    */
    receive() external payable {
        uint transaction_fee = ( msg.value / 100000000 ) * fee;
        total_revenue = total_revenue + msg.value - transaction_fee;
        payable(factory).transfer(transaction_fee);
    }

    /**
    * @notice Executed when a payment is made to the contract address when data is not empty.
    */
    fallback() external payable {
        uint transaction_fee = ( msg.value / 100000000 ) * fee;
        total_revenue = total_revenue + msg.value - transaction_fee;
        payable(factory).transfer(transaction_fee);
    }

    function getData(address _account) public view returns (string[] memory) {
        string[] memory shareData = new string[](10);
        shareData[0] = Utils.toHexString(address(this)); // Address
        shareData[1] = name; // Name
        shareData[2] = description; // Description
        shareData[3] = Utils.toString(shareholders[_account]); // Personal shares
        shareData[4] = Utils.toString(total_shares); // Total shares
        shareData[5] = Utils.toString(getUserBalance(_account)); // Personal Balance
        shareData[6] = Utils.toString(address(this).balance); // Total Balance
        shareData[7] = Utils.toString(last_withdrawl[_account]); // Last withdrawl blockstamp
        shareData[8] = Utils.toHexString(creator); // Creator
        if(automatic) { shareData[9] = "automatic"; } else { shareData[9] = "manual"; } // Type of contract
        return shareData;
    }

    /**
    * @notice Returns creator of the Squid.
    */
    function getCreator() public view returns (address) {
        return creator;
    }

    /**
    * @notice Calculates available balance within the Squid.
    * @return balance Remaning balance.
    */
    function getUserBalance(address _payee) private view returns (uint256) {
        return ( shareholders[_payee] * total_revenue ) / total_shares - total_released[_payee];
    }

    /**
    * @notice Checks is a payee is a shareholder within a Squid.
    * @param _payee Address to be checked.
    * @return bool true if payee is a shareholder, false if not.
    */
    function isPayee(address _payee) private view returns (bool) {
        for(uint i = 0; i < payees.length; i++) {
            if(_payee == payees[i]) { return true; }
        }
        return false;
    }

    /**
    * @notice Retrieves all shareholders and their number of allocated shares
    * within the Squid
    * @return _shareholders An array containing each address and associated shares
    * found within a Squid.
    */
    function getShareholders() public view returns (string[] memory) {
        string[] memory _shareholders = new string[](payees.length * 2);

        uint j = 0;
        for(uint i = 0; i < payees.length; i++) {
            address _payee = payees[i];
            _shareholders[j] = Utils.toHexString(_payee);
            _shareholders[j + 1] = Utils.toString(shareholders[_payee]);
            j = j + 2;
        }

        return _shareholders;
    }

    /**
    * @notice Transfers payee their available balance. Can only be executed
    * by a payee.
    */
    function payout(address _account) external {

        require(msg.sender == factory, 'Error: 1012');
        require(isPayee(_account), 'Error: 1007');
        require(shareholders[_account] > 0, 'Error: 1008');
        require(address(this).balance > 0, 'Error: 1009');

        uint bal = getUserBalance(_account);

        require(bal > 0, 'Error: 1010');

        // Track data
        total_released[_account] += bal;
        last_withdrawl[_account] = block.timestamp;

        // Pay
        (bool success, bytes memory data) = payable(_account).call{value: bal}("");
        require(success, "Failed to send ether");
    }

    /**
    * @notice Transfers all payees their available balance. Can only be executed
    * by the creator of the squid.
    */
    function payoutAll() external {

        require(msg.sender == factory, 'Error: 1012');
        require(address(this).balance > 0, 'Error: 1009');

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];

            if(shareholders[payee] < 0) { continue; }

            uint bal = getUserBalance(payee);
            if(bal > 0) {
                // Track Data
                total_released[payee] += bal;
                last_withdrawl[payee] = block.timestamp;

                // Pay
                (bool success, bytes memory data) = payable(payee).call{value: bal}("");
                require(success, "Failed to send ether");
            }
        }
    }

    /**
    * @notice Transfers all payees their tokens from defined token address. Can only be executed
    * by the creator of the squid.
    */
    function payoutAllTokenized(IERC20 tokenAddress) external {

        require(msg.sender == factory, 'Error: 1012');

        uint TotalBalance = tokenAddress.balanceOf(address(this));

        uint transaction_fee = ( TotalBalance / 100000000 ) * fee;
        
        TotalBalance = TotalBalance - transaction_fee;

        tokenAddress.transfer(factory, transaction_fee);

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];

            if(shareholders[payee] < 0) { continue; }

            uint bal = ( shareholders[payee] / total_shares ) * TotalBalance;
            
            if(bal > 0) {
                // Pay
                tokenAddress.transfer(payee, bal);
            }
        }

    }
}