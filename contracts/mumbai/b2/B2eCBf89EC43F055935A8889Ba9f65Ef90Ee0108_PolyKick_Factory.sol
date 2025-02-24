/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.17;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/PolyKick_ILO.sol


pragma solidity ^0.8.17;



contract PolyKick_ILO{
using SafeMath for uint256;

    error InvalidAmount(uint256 min, uint256 max);
    address public factory;
    address public constant burn = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    IERC20 public token;
    uint8 public tokenDecimals;
    uint256 public tokenAmount;
    IERC20 public currency;
    uint256 public price;
    uint256 public target;
    uint256 public duration;
    uint256 maxAmount;
    uint256 minAmount;
    uint256 public salesCount;

    struct buyerVault{
        uint256 tokenAmount;
        uint256 currencyPaid;
    }
    
    mapping(address => bool) public isWhitelisted;
    mapping(address => buyerVault) public buyer;
    mapping(address => bool) public isBuyer;

    address public seller;
    address public polyKick;

    uint256 public sellerVault;
    uint256 public soldAmounts;
    uint256 public notSold;
    uint256 private polyKickPercentage;
    
    bool success;
    
    event approveILO(bool);
    event tokenSale(uint256 CurrencyAmount, uint256 TokenAmount);
    event tokenWithdraw(address Buyer, uint256 Amount);
    event CurrencyReturned(address Buyer, uint256 Amount);
/*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    constructor(
           address _seller,
           address _polyKick,
           IERC20 _token,
           uint8 _tokenDecimals,
           uint256 _tokenAmount,
           IERC20 _currency, 
           uint256 _price,
           uint256 _target, 
           uint256 _duration,
           uint256 _polyKickPercentage
           ){
        factory = msg.sender;
        seller = _seller;
        polyKick = _polyKick;
        token = _token;
        tokenDecimals = _tokenDecimals;
        tokenAmount = _tokenAmount;
        currency = _currency;
        price = _price;
        target = _target;
        duration = _duration;
        polyKickPercentage = _polyKickPercentage;
        minAmount = tokenAmount.mul(1).div(1000);
        maxAmount = tokenAmount.mul(1).div(100);
        _status = _NOT_ENTERED;
        notSold = _tokenAmount;
    }

    function addToWhiteListBulk(address[] memory _allowed) external{
        require(msg.sender == seller || msg.sender == polyKick,"not authorized");
        for(uint i=0; i<_allowed.length; i++){
            isWhitelisted[_allowed[i]] = true;
        }
    }
    function addToWhiteList(address _allowed) external{
        require(msg.sender == seller || msg.sender == polyKick,"not authorized");
        isWhitelisted[_allowed] = true;
    }
    function removeWhiteList(address _usr) external{
        require(msg.sender == seller || msg.sender == polyKick,"not authorized");
        isWhitelisted[_usr] = false;
    }
    function buyTokens(uint256 _amountToPay) external nonReentrant{
        require(isWhitelisted[msg.sender] == true, "You need to be White Listed for this ILO");
        require(block.timestamp < duration,"ILO Ended!");
        uint256 amount = _amountToPay.div(price); //pricePerToken;
        uint256 finalAmount = amount * 10 ** tokenDecimals;
        if(finalAmount < minAmount && finalAmount > maxAmount){
            revert InvalidAmount(minAmount, maxAmount);
        }
        emit tokenSale(_amountToPay, finalAmount);
        //The transfer requires approval from currency smart contract
        currency.transferFrom(msg.sender, address(this), _amountToPay);
        sellerVault += _amountToPay;
        buyer[msg.sender].tokenAmount = finalAmount;
        buyer[msg.sender].currencyPaid = _amountToPay;
        soldAmounts += finalAmount;
        notSold -= finalAmount;
        isBuyer[msg.sender] = true;
        salesCount++;
    }

    function iloApproval() external returns(bool){
        require(block.timestamp > duration, "ILO has not ended yet!");
        if(soldAmounts >= target){
            success = true;
            token.transfer(burn, notSold);
        }
        else{
            success = false;
            sellerVault = 0;
        }
        emit approveILO(success);
        return(success);
    }
    function changeMinMax(uint256 _min, uint256 _minM, uint256 _max, uint256 _maxM) external{
        require(msg.sender == seller, "Not authorized!");
        minAmount = tokenAmount.mul(_min).div(_minM);
        maxAmount = tokenAmount.mul(_max).div(_maxM);
    }
    function withdrawTokens() external nonReentrant{
        require(block.timestamp > duration, "ILO has not ended yet!");
        require(isBuyer[msg.sender] == true,"Not an Buyer");
        require(success == true, "ILO Failed");
        uint256 buyerAmount = buyer[msg.sender].tokenAmount;
        emit tokenWithdraw(msg.sender, buyerAmount);
        token.transfer(msg.sender, buyerAmount);
        soldAmounts -= buyerAmount;
        buyer[msg.sender].tokenAmount = 0;
        isBuyer[msg.sender] = false;
    }

    function returnFunds() external nonReentrant{
        require(block.timestamp > duration, "ILO has not ended yet!");
        require(isBuyer[msg.sender] == true,"Not an Buyer");
        require(success == false, "ILO Succeed try withdrawTokens");
        uint256 buyerAmount = buyer[msg.sender].currencyPaid;
        emit CurrencyReturned(msg.sender, buyerAmount);
        currency.transfer(msg.sender, buyerAmount);
        buyer[msg.sender].currencyPaid = 0;
        isBuyer[msg.sender] = false;
    }

    function sellerWithdraw() external nonReentrant{
        require(msg.sender == seller,"Not official seller");
        require(block.timestamp > duration, "ILO has not ended yet!");
        uint256 polyKickAmount = sellerVault.mul(polyKickPercentage).div(100);
        uint256 sellerAmount = sellerVault - polyKickAmount;
        if(success == true){
            currency.transfer(polyKick, polyKickAmount);
            currency.transfer(seller, sellerAmount);
        }
        else{
            token.transfer(seller, token.balanceOf(address(this)));
        }
    }


/*
   @dev: people who send Matic by mistake to the contract can withdraw them
*/
    mapping(address => uint) public balanceReceived;

    function receiveMoney() public payable {
        assert(balanceReceived[msg.sender] + msg.value >= balanceReceived[msg.sender]);
        balanceReceived[msg.sender] += msg.value;
    }

    function withdrawWrongTrasaction(address payable _to, uint256 _amount) public {
        require(_amount <= balanceReceived[msg.sender], "not enough funds.");
        assert(balanceReceived[msg.sender] >= balanceReceived[msg.sender] - _amount);
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    } 

    receive() external payable {
        receiveMoney();
    }
}


               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2022
               **********************************************************/
    



// File: contracts/PolyKick_Factory.sol


pragma solidity ^0.8.17;




contract PolyKick_Factory{

    PolyKick_ILO private pkILO;

    uint256 constant months = 30 days;
    uint256 constant MAX_UINT = 2**256 - 1;
    uint256 public projectsAllowed;
    uint256 public projectsCount;
    address public owner;
    uint256 private pID;

    event projectAdded(uint256 ProjectID, string ProjectName, IERC20 ProjectToken, address ProjectOwner);
    event ILOCreated(address pkILO);
    event ChangeOwner(address NewOwner);

    struct allowedProjects{
        uint256 projectID;
        string projectName;
        address projectOwner;
        IERC20 projectToken;
        uint8 tokenDecimals;
        address ILO;
        uint256 rounds;
        uint256 totalAmounts;
        uint256 polyKickPercentage;
        bool projectStatus;
    }

    struct Currencies{
        string name;
        uint8 decimals;
    }
    mapping(IERC20 => Currencies) public allowedCurrencies;
    mapping(IERC20 => bool) public isCurrency;
    mapping(IERC20 => bool) public isProject;
    mapping(uint256 => allowedProjects) public projectsByID;
    mapping(IERC20 => uint256) private pT;

/* @dev: Check if contract owner */
    modifier onlyOwner (){
        require(msg.sender == owner, "Not Owner!");
        _;
    }

    constructor(){
        owner = msg.sender;
        pID = 0;
    }
/*
    @dev: Change the contract owner
*/
    function transferOwnership(address _newOwner)external onlyOwner{
        require(_newOwner != address(0x0),"Zero Address");
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }
    function addCurrency(string memory _name, IERC20 _currency, uint8 _decimal) external onlyOwner{
        //can also fix incase of wrong data
        allowedCurrencies[_currency].name = _name;
        allowedCurrencies[_currency].decimals = _decimal;
        isCurrency[_currency] = true; 
    }
    function addProject(string memory _name, IERC20 _token, uint8 _tokenDecimals, address _projectOwner, uint256 _polyKickPercentage) external onlyOwner returns(uint256) {
        require(isProject[_token] != true, "Project already exist!");
        pID++;
        projectsByID[pID].projectID = pID;
        projectsByID[pID].projectName = _name;
        projectsByID[pID].projectOwner = _projectOwner;
        projectsByID[pID].projectToken = _token;
        projectsByID[pID].tokenDecimals = _tokenDecimals;
        projectsByID[pID].projectStatus = true;
        isProject[_token] = true;
        pT[_token] = pID;
        projectsByID[pID].polyKickPercentage = _polyKickPercentage;
        projectsAllowed++;
        emit projectAdded(pID, _name, _token, _projectOwner);
        return(pID);
    }
    function projectNewRound(IERC20 _token) external onlyOwner{
        projectsByID[pT[_token]].projectStatus = true;
    }
    function startILO(
        IERC20 _token, 
        uint256 _tokenAmount, 
        IERC20 _currency, 
        uint256 _price, 
        uint8 _priceDecimals, 
        uint256 _target,
        uint256 _months
        ) external{
        require(isProject[_token] == true, "Project is not allowed!");
        require(projectsByID[pT[_token]].projectStatus == true, "ILO was initiated");
        require(_token.balanceOf(msg.sender) >= _tokenAmount,"Not enough tokens");
        require(isCurrency[_currency] ==true, "Currency token is not allowed!");
        require(_priceDecimals <= allowedCurrencies[_currency].decimals, "Decimals error!");
        projectsByID[pT[_token]].projectStatus = false;
        uint256 _pkP = projectsByID[pT[_token]].polyKickPercentage;
        address _polyKick = owner;
        _months = _months * months;
        uint8 priceDecimals = allowedCurrencies[_currency].decimals - _priceDecimals;
        uint256 price = _price*10**priceDecimals;
        uint8 _tokenDecimals = projectsByID[pT[_token]].tokenDecimals;
        uint256 _duration = _months + block.timestamp;

        pkILO = new PolyKick_ILO(
            msg.sender, 
            _polyKick, 
            _token,
            _tokenDecimals, 
            _tokenAmount,
            _currency, 
            price,
            _target, 
            _duration,
            _pkP
            );
        emit ILOCreated(address(pkILO));
        _token.transferFrom(msg.sender, address(pkILO), _tokenAmount);
        projectsCount++;
        registerILO(_token, _tokenAmount);
    }
    function registerILO(IERC20 _token, uint256 _tokenAmount) internal{
        projectsByID[pT[_token]].rounds++;
        projectsByID[pT[_token]].totalAmounts += _tokenAmount;
        projectsByID[pT[_token]].ILO = address(pkILO);
    }
}

               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2022
               **********************************************************/