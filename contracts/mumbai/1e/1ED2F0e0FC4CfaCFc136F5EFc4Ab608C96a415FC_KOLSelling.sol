//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
import './security/Pausable.sol';
import './token/ERC20Implementation.sol';

contract KOLSelling is Pausable {
    ERC20Implementation token;
    ERC20Implementation USDT = ERC20Implementation(0xcacE8f13C6C857c8a6a47B7aC0BA53b755237C74);
    ERC20Implementation WETH = ERC20Implementation(0x79092e8003dC358c4f4d50d1dB8D931F56c9c91B);

    mapping(address => uint256) ownerAmount;
    mapping(address => bool) whiteList;

    //Matic swap rate , divide 1e6
    uint256 swapRate = 46026;
    //WETH swap rate , divide 1e18
    uint256 swapRate_WETH = 23946216800000;
    //USDT swap rate , divide 1e6
    uint256 swapRate_USDT = 80000;

    uint256 maxRelease = 500000 * 1e6;
    uint256 restRelease = 500000 * 1e6;
    uint256 accountMaximum = 50000 * 1e6;

    uint256 startTime = 1648001467;
    uint256 endTime = 1748001467;

    event Bought(address _address, uint256 _amount);

    constructor(
        address _Acoin_address,
        address _USDT_address,
        address _WETH_address
    ) {
        token = ERC20Implementation(_Acoin_address);
        USDT = ERC20Implementation(_USDT_address);
        WETH = ERC20Implementation(_WETH_address);
    }

    modifier basicCheck(uint256 _amount) {
        require(token.balanceOf(address(this)) >= _amount, "This Contract don't have enough token");
        //but amount at least 1000
        require(whiteList[msg.sender] == true, 'Not in the whitelist');
        require(_amount >= 1000 * 1e6, 'Buying amount should more than 1000');
        require(restRelease >= _amount, 'Rest amount is not enough');
        require(ownerAmount[msg.sender] + _amount <= accountMaximum, 'One account maximum is 50000');
        require(block.timestamp >= startTime && block.timestamp <= endTime, 'Not in the period');
        _;
    }

    function addToWhitelist(address[] calldata users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
    }

    function checkWhiteList(address _user) external view returns (bool) {
        return whiteList[_user];
    }

    function setDetails(
        uint256 _swapRate,
        uint256 _swapRate_USDT,
        uint256 _swapRate_WETH,
        uint256 _max_Release,
        uint256 _accountMaximum
    ) external onlyAdmin {
        require(token.balanceOf(address(this)) >= _max_Release, 'Contract have not enough token');
        swapRate = _swapRate;
        swapRate_USDT = _swapRate_USDT;
        swapRate_WETH = _swapRate_WETH;
        maxRelease = _max_Release;
        restRelease = maxRelease;
        accountMaximum = _accountMaximum;
    }

    function getDetails()
        external
        view
        returns (
            uint256 _swapRate,
            uint256 _swapRate_USDT,
            uint256 _swapRate_WETH,
            uint256 _maxRelease,
            uint256 _restRelease,
            uint256 _accountMaximum,
            uint256 _accountRestAmount
        )
    {
        uint256 accountRestAmount = accountMaximum - ownerAmount[msg.sender];
        return (swapRate, swapRate_USDT, swapRate_WETH, maxRelease, restRelease, accountMaximum, accountRestAmount);
    }

    function setTime(uint256 _startTime, uint256 _endTime) external onlyAdmin {
        startTime = _startTime;
        endTime = _endTime;
    }

    function getTime() external view returns (uint256 _startTime, uint256 _endTime) {
        return (startTime, endTime);
    }

    function buy(uint256 _amount) external payable basicCheck(_amount) whenNotPaused {
        uint256 paymentTobuy = ((_amount * 1e12) * swapRate) / 1e6;
        require(msg.value > 0 && msg.value >= paymentTobuy, 'The payment is not enough');

        token.transfer(msg.sender, _amount);
        ownerAmount[msg.sender] += _amount;
        restRelease -= _amount;

        emit Bought(msg.sender, _amount);
    }

    function buyWithWETH(uint256 _buyamount, uint256 _payamount) external basicCheck(_buyamount) whenNotPaused {
        uint256 paymentTobuy = ((_buyamount * 1e12) * swapRate_WETH) / 1e18;
        require(_payamount >= paymentTobuy, 'The payment is not enough');
        require(WETH.balanceOf(msg.sender) >= _payamount, 'Not enough WETH');
        require(WETH.allowance(msg.sender, address(this)) >= _payamount, 'Not enough WETH allowance');

        WETH.transferFrom(msg.sender, address(this), _payamount);
        token.transfer(msg.sender, _buyamount);
        ownerAmount[msg.sender] += _buyamount;
        restRelease -= _buyamount;

        emit Bought(msg.sender, _buyamount);
    }

    function buyWithUSDT(uint256 _buyamount, uint256 _payamount) external basicCheck(_buyamount) whenNotPaused {
        uint256 paymentTobuy = (_buyamount * swapRate_USDT) / 1e6;
        require(_payamount >= paymentTobuy, 'The payment is not enough');
        require(USDT.balanceOf(msg.sender) >= _payamount, 'Not enough USDT');
        require(USDT.allowance(msg.sender, address(this)) >= _payamount, 'Not enough USDT allowance');

        USDT.transferFrom(msg.sender, address(this), _payamount);
        token.transfer(msg.sender, _buyamount);
        ownerAmount[msg.sender] += _buyamount;
        restRelease -= _buyamount;

        emit Bought(msg.sender, _buyamount);
    }

    function getMaticBalacne() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalacne() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUSDTBalacne() external view returns (uint256) {
        return USDT.balanceOf(address(this));
    }

    function getWETHBalacne() external view returns (uint256) {
        return WETH.balanceOf(address(this));
    }

    function withdrawToken(uint256 _amount) external onlyAdmin {
        token.transfer(msg.sender, _amount);
    }

    function withdrawUSDT(uint256 _amount) external onlyAdmin {
        USDT.transfer(msg.sender, _amount);
    }

    function withdrawWETH(uint256 _amount) external onlyAdmin {
        WETH.transfer(msg.sender, _amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

import "./AccessControl.sol";

contract Pausable is AccessControl {
    /// @dev Error message.
    string constant PAUSED = "paused";
    string constant NOT_PAUSED = "not paused";

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused() {
        require(paused, NOT_PAUSED);
        _;
    }

    /// @dev Called by admin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the admin.
    function unpause() external onlyAdmin whenPaused {
        paused = false;
    }
}

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "../security/Pausable.sol";

/// @title Standard ERC20 token

contract ERC20Implementation is IERC20, Pausable {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowed;

    uint256 _totalSupply;

    /// @dev Total number of tokens in existence
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets the balance of the specified address.
    /// @param _owner The address to query the balance of.
    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[_owner];
    }

    /// @dev Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(_to != address(0), INVALID_ADDRESS);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool success) {
        require(_to != address(0), INVALID_ADDRESS);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender The address which will spend the funds.
    /// @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(_spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _allowed[_owner][_spender];
    }

    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Internal function that mints an amount of the token and assigns it to an account.
    ///  This encapsulates the modification of balances such that the proper events are emitted.
    /// @param account The account that will receive the created tokens.
    /// @param amount The amount that will be created.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), INVALID_ADDRESS);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl {
    /// @dev Error message.
    string constant NO_PERMISSION = "no permission";
    string constant INVALID_ADDRESS = "invalid address";

    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable public superAdmin;

    /// @dev Administrator of this contract.
    address payable public admin;

    /// @dev This event is fired after modifying superAdmin.
    event superAdminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// @dev This event is fired after modifying admin.
    event adminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor() {
        superAdmin = payable(msg.sender);
        admin = payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(msg.sender == admin, NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit superAdminChanged(superAdmin, addr, block.timestamp);
        superAdmin = addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit adminChanged(admin, addr, block.timestamp);
        admin = addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin {
        superAdmin.transfer(amount);
    }

    fallback() external {}
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount.
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}