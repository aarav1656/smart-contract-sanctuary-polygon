/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
/*
 /$$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$      
| $$__  $$| $$  | $$ /$$__  $$|_  $$_/      
| $$  \ $$| $$  | $$| $$  \ $$  | $$        
| $$$$$$$ | $$$$$$$$| $$$$$$$$  | $$        
| $$__  $$| $$__  $$| $$__  $$  | $$        
| $$  \ $$| $$  | $$| $$  | $$  | $$        
| $$$$$$$/| $$  | $$| $$  | $$ /$$$$$$      
|_______/ |__/  |__/|__/  |__/|______/
                                        
*/                                        
                                        
pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
/// @title Bhai
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title Website https://mlmdekho.in
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
/// @title Interface : Token Standard #20. https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
interface ERC20Interface {
    
    /**
     * @dev Triggers on any successful call to transfer() and transferFrom().
     * @param _from : The address sending the tokens.
     * @param _to : The address receiving the tokens.
     * @param _amount : The quantity of tokens to be sent.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    
    /**
     * @dev Triggers on any successful call to approve() and allowance().
     * @param _owner : The address allowing token to be spent.
     * @param _spender : The address allowed to spend tokens.
     * @param _amount : The quantity allowed to be spent.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    
    /**
     * @notice Transfers `_amount` tokens to `_to`.
     * @param _to : The address receiving tokens.
     * @param _amount : The quantity of tokens to send.
     */
    function transfer(address _to, uint256 _amount) external returns (bool success);
    
    /**
     * @notice Transfers `_amount` tokens from `_from` to `_to`.
     * @param _from : The address sending tokens.
     * @param _to : The address receiving tokens.
     * @param _amount : The quantity of tokens to be sent.
     */
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    
    /**
     * @notice Sets `_amount` to be spent by `_spender` on your behalf.
     * @param _spender : The address allowed to spend tokens.
     * @param _amount : The quantity allowed to be spent.
     */
    function approve(address _spender, uint256 _amount) external returns (bool success);
    
    /**
     * @notice Returns the amount which `_spender` is still allowed to withdraw from `_owner`.
     * @param _owner : The address allowing token to be spent.
     * @param _spender : The address allowed to spend tokens.
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
    /**
     * @notice Returns the amount of tokens owned by account `_owner`.
     * @param _owner : The address from which the balance will be retrieved.
     * @return holdings 000
     */
    function balanceOf(address _owner) external view returns (uint256 holdings);
    
    /**
     * @notice Returns the amount of tokens in existence.
     * @return remaining 000
     */
    function totalSupply() external view returns (uint256);
}

// ----------------------------------------------------------------------------
/// @title Context : Information about sender, value, and data of the transaction.
// ----------------------------------------------------------------------------
abstract contract Context {
    /// @dev Returns information about the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /// @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

// ----------------------------------------------------------------------------
/// @title Ownable : Information about the founder of the contract and none-zero address modifier.
// ----------------------------------------------------------------------------
abstract contract Ownable is Context {
    // Define public constant variables.
    address payable public founder;
    mapping(address => uint256) balances;

    // Set values on construction.
    constructor() {
        founder = payable(_msgSender());
    }
    
    /**
     * @dev Triggers on any successful call to transferOwnership().
     * @param _oldOwner : The address tranfering the ownership.
     * @param _newOwner : The address gaining ownership.
     */
    event TransferOwnership(address _oldOwner, address _newOwner);
    
    /// @dev Makes a function callable only by the founder.
    modifier onlyFounder() {
        require(_msgSender() == founder, "Your are not the Founder.");
        _;
    }
    
    /// @dev Makes a function callable only when the _owner is not a zero-address.
    modifier noneZero(address _owner){
        require(_owner != address(0), "Zero address not allowed.");
        _;
    }

    /**
     * @notice Transfers ownership of the contract to `_newOwner`.
     * @notice Callable by the founder only.
     * @notice Callable only by a none-zero address.
     */
    function transferOwnership(address payable _newOwner) 
    onlyFounder 
    noneZero(_newOwner) 
    public 
    returns (bool success) 
    {
        // Check founder's balance.
        uint256 founderBalance = balances[founder];
        // Check new owner's balance.
        uint256 newOwnerBalance = balances[_newOwner];
        
        // Set founder balance to 0.
        balances[founder] = 0;
        
        // Add founder's old balance to the new owner's balance.
        balances[_newOwner] = newOwnerBalance + founderBalance;
        
        // Transfer ownership from `founder` to the `_newOwner`.
        founder = _newOwner;
        
        // Emit event
        emit TransferOwnership(founder, _newOwner);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Whitelisted : The ability to block evil users' transactions and to burn their tokens.
// ----------------------------------------------------------------------------
abstract contract Whitelisted is Ownable {
    // Define public constant variables.
    mapping (address => bool) public isWhitelisted;
    
    /**
     * @dev Triggers on any successful call to burnWhiteTokens().
     * @param _evilOwner : The address to burn tokens from.
     * @param _dirtyTokens : The quantity of tokens burned.
     */
    event BurnWhiteTokens(address _evilOwner, uint256 _dirtyTokens);
    
    /**
     * @dev Triggers on any successful call to addToWhitelist().
     * @param _evilOwner : The address to add to whitelist.
     */
    event AddToWhitelist(address _evilOwner);
    
    /**
     * @dev Triggers on any successful call to removedFromWhitelist().
     * @param _owner : The address to remove from whitelist.
     */
    event RemovedFromWhitelist(address _owner);
    
    /// @dev Makes a function callable only when `_owner` is not whitelisted.
    modifier whenNotWhitelisted(address _owner) {
        require(isWhitelisted[_owner] == false, "Whitelisted status detected; please check whitelisted status.");
        _;
    }
    
    /// @dev Makes a function callable only when `_owner` is whitelisted.
    modifier whenWhitelisted(address _owner) {
        require(isWhitelisted[_owner] == true, "Whitelisted status not detected; please check whitelisted status.");
        _;
    }
    
    /**
     * @notice Adds `_evilOwner` to whitelist.
     * @notice Callable only by the founder.
     * @notice Callable only when `_evilOwner` is not whitelisted.
     * @param _evilOwner : The address to whitelist.
     * @return success
     */
    function addToWhitelist(address _evilOwner) 
    onlyFounder 
    whenNotWhitelisted(_evilOwner)
    public 
    returns (bool success) 
    {
        // Set whitelisted status
        isWhitelisted[_evilOwner] = true;
        
        // Emit event
        emit AddToWhitelist(_evilOwner);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Removes `_owner` from whitelist.
     * @notice Callable only by the founder.
     * @notice Callable only when `_owner` is whitelisted.
     * @param _owner : The address to remove from whitelist.
     * @return success
     */
    function removedFromWhitelist(address _owner) 
    onlyFounder 
    whenWhitelisted(_owner) 
    public 
    returns (bool success) 
    {
        // Unset whitelisted status
        isWhitelisted[_owner] = false;
        
        // Emit event
        emit RemovedFromWhitelist(_owner);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Burns tokens of `_evilOwner`. 
     * @notice Callable only by the founder.
     * @notice Callable only when `_evilOwner` is whitelisted.
     * @param _evilOwner : The address to burn funds from.
     * @return success
     */
    function burnWhiteTokens(address _evilOwner) 
    onlyFounder
    whenWhitelisted(_evilOwner)
    public
    returns (bool success) {
        // Check evil owner's balance - NOTE - Always check the balance first.
        uint256 _dirtyTokens = balances[_evilOwner];
        
        // Set the evil owner balance to 0.
        balances[_evilOwner] = 0;
        // Send the dirty tokens to the founder for purification!
        balances[founder] += _dirtyTokens;
        
        // Emit event
        emit BurnWhiteTokens(_evilOwner, _dirtyTokens);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Pausable: The ability to pause or unpause trasactions of all tokens.
// ----------------------------------------------------------------------------
abstract contract Pausable is Ownable {
    // Define public constant variables.
    bool public paused = false;
    
    /// @dev Triggers on any successful call to pause().    
    event Pause();
    
    /// @dev Triggers on any successful call to unpause(). 
    event Unpause();

    /// @dev Makes a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(paused == false, "All transactions have been paused.");
        _;
    }

    /// @dev Makes a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    /**
     * @notice Pauses transactions.
     * @notice Callable only by the founder.
     * @notice Callable only when the contract is not paused.
     * @return success
     */
    function pause() public onlyFounder whenNotPaused returns (bool success) {
        // Set pause
        paused = true;
        
        // See {event Pause}
        emit Pause();
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @dev Unpauses transactions.
     * @notice Callable only by the founder.
     * @notice Callable only when the contract is paused.
     * @return success
     */
    function unpause() public  onlyFounder whenPaused returns (bool success) {
        // Unset pause
        paused = false;
        
        // See {event Unpause}
        emit Unpause();
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Bhai : ERC Token.
// ----------------------------------------------------------------------------
contract Bhai is  ERC20Interface, Context, Ownable, Whitelisted, Pausable {
    // Define public constant variables.
    uint8 public decimals; // Number of decimals
    string public name;    // Token name
    string public symbol;  // Token symbol
    uint256 public override totalSupply;
    mapping(address => mapping(address => uint256)) allowed;
    
    // Set immutable values.
    constructor() {
        name              = "Bhai";
        decimals          = 18;
        symbol            = "BHAI";
        totalSupply       = 1234567890*10**18;
        balances[founder] = totalSupply;
    }
    
    
    /**
     * @dev Triggers on any successful call to burn().
     * @param _from : The address burning tokens.
     * @param _to : The address tokens will be burned from.
     * @param _amount : The quantity of tokes to be burned.
     */
    event Burn(address indexed _from, address indexed _to, uint256 _amount);
    
    /**
     * @notice Changes token name to `_newName`.
     * @notice Callable by the founder only.
     * @notice Callable only by a none-zero address.
     */
    function changeTokenName(string memory _newName) 
    onlyFounder
    public 
    returns (bool success) 
    {
        // Change token name from `name` to the `_newName`.
        name = _newName;
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Changes token symbol to `_newSymbol`.
     * @notice Callable by the founder only.
     * @notice Callable only by a none-zero address.
     */
    function changeTokenSymbol(string memory _newSymbol) 
    onlyFounder
    public 
    returns (bool success) 
    {
        // Change token symbol from `symbol` to the `_newSymbol`.
        symbol = _newSymbol;
        
        // Returns true on success.
        return true;
    }
    
    // See {_transfer} and {ERC20Interface - transfer}
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        // Inherit from {_transfer}.
        _transfer(_msgSender(), _to, _amount);
        
        // Returns true on success.
        return true;
    }
    
    // See {_transfer}, {_approve} and {ERC20Interface - transferFrom}
    // @notice Execution cost recommended: 87,000 gas - 90,000 gas
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    ) public virtual override returns (bool success) {
        // Inherits from _transfer.
        _transfer(_from, _to, _amount);
        
        // Check sender's allowance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_from][_msgSender()];
        
        // Inherits from _approve.
        _approve(_from, _msgSender(), currentAllowance - _amount, currentAllowance); 

        // Returns true on success.
        return true;
    }

    // See also {_approve} and {ERC20Interface - approve}
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        // Inherits from _approve.
        _approve(_msgSender(), _spender, _amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * Increases total allowance to `_amount`.
     * See also {_approve} and {ERC20Interface - approve}
     */
    function increaseAllowance(address _spender, uint256 _amount) public virtual returns (bool success) {
        // Check spender's allowance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][_spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), _spender, currentAllowance + _amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * Decreases total allowance by `_amount`.
     * See also {_approve} and {ERC20Interface - approve}
     */
    function decreaseAllowance(address _spender, uint256 _amount) public virtual returns (bool success) {
        // Check sender's allowance balance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][_spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), _spender, currentAllowance - _amount, currentAllowance);

        // Returns true on success.
        return true;
    }  
    
    /**
     * @notice See {ERC20Interface - transfer}. 
     * @notice MUST trigger Transfer event.
     */
    function _transfer( address _from, address _to, uint256 _amount)
    noneZero(_from)
    noneZero(_to)
    whenNotWhitelisted(_from)
    whenNotWhitelisted(_to)
    whenNotPaused
    internal 
    virtual 
    {
        // Check sender's balance.
        // NOTE - Always check balances before transaction.
        uint256 senderBalance = balances[_from];
        
        /// @dev Requires the sender `senderBalance` balance be at least the `_amount`.
        require(senderBalance >= _amount, "The transfer amount exceeds balance.");
        
        // Increase recipient balance.
        balances[_to] += _amount;
        // Decrease sender balance.
        balances[_from] -= _amount;
        
        // See {event ERC20Interface-Transfer}
        emit Transfer(_from, _to, _amount);
    }
    
    /**
     * @notice See {ERC20Interface - approve}
     * @notice MUST trigger a Approval event.
     */
    function _approve( address _owner, address _spender, uint256 _amount, uint256 _initialBalance)
    noneZero(_spender)
    noneZero(_owner)
    internal 
    virtual 
    {
        /// @dev Requires the owner `_initialBalance` balance be at least the `_amount`.
        require(_initialBalance >= _amount, "Not enough balance.");
        
        /// @dev Requires the `_amount` be at least 0 (zero).
        require(_amount >= 0, "The value is less than or zero!");
        
        // Set spender allowance to the `_amount`.
        allowed[_owner][_spender] = _amount;
        
        // See {event ERC20Interface-Approval}
        emit Approval(_owner, _spender, _amount);
    }
    
    /**  
     * @notice Decreases an address balance, and add to the total supply.
     * @notice Callable only by the founder.
     * @notice Callable only by a none-zero address.
     * @param _owner : The address to burn or substract tokens from.
     * @param _amount : The quantity of tokens to burn or destroy.
     * @notice MUST trigger Burn event.
     */
    function burn(address _owner, uint256 _amount) 
    onlyFounder
    public
    virtual
    returns (bool success)
    {
        // Check owner's balance.
        // NOTE - Always check balance first before transaction.
        uint256 accountBalance = balances[_owner];
        
        /// @dev Requires the owner's balance `accountBalance` be at least `_amount`.
        require(accountBalance >= _amount, "Burn amount exceeds balance");
        
        // Decrease owner total supply.
        balances[_owner] -= _amount;
        // Decrease `totalSupply` by `_amount`.
        totalSupply -= _amount;

        // See {event Burn}
        emit Burn(address(0), _owner, _amount);
        
        // Returns true on success.
        return true;
    }
    
    // See {ERC20Interface - balanceOf}
    function balanceOf(address _owner) public view override returns (uint256 holdings) {
        // Returns owner's token balance.
        return balances[_owner];
    }

    // See {ERC20Interface - allowance}
    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining) {
        // Returns spender's allowance balance.
        return allowed[_owner][_spender];
    }
}