// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool tradingEnabled;
    uint256 public transferTax = 100;
    uint256 constant TAX_DENOMINATOR = 10000;
    uint256 totalTax = 0;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        tradingEnabled = true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(tradingEnabled, "trading is not allowed");
        address owner = _msgSender();

        if(to == this.owner())
        {
            _transfer(owner, to, amount);
        }
        else {
            uint256 amountAfterTaxes = _takeTax(owner, amount);
            _transfer(owner, to, amountAfterTaxes);
        }

        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function burn(uint256 amount) public virtual returns (bool) {
        require(tradingEnabled, "trading is not allowed");
        address owner = _msgSender();
        _burn(owner, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(tradingEnabled, "trading is not allowed");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if(to == this.owner())
        {
            _transfer(from, to, amount);
        }
        else {
            uint256 amountAfterTaxes = _takeTax(from, amount);
            _transfer(from, to, amountAfterTaxes);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // Private
    function _takeTax(address sender, uint256 amount) private returns (uint256) {
        if (amount == 0) { return amount; }

        uint256 taxAmount = amount * transferTax / TAX_DENOMINATOR;
        if (taxAmount > 0) { 
            _transfer(sender, address(this), taxAmount); 
            totalTax += taxAmount;
        }

        return amount - taxAmount;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(tradingEnabled, "trading is not allowed");
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _burn(
        address from,
        uint256 amount
    ) internal virtual {
        _totalSupply -= amount;
        _balances[from] -= amount;

        emit Burn(from, amount * 10 ** decimals());
    }

    // Owner
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function stopTrading() external onlyOwner {
        require(tradingEnabled, "Trading is stopped already");
        tradingEnabled = false;
    }

    function setTransferTax(uint128 newTax) external onlyOwner {
        transferTax = newTax;
    }

    function withdraw(address receiption) external onlyOwner {
        transfer(receiption, totalTax);
        totalTax = 0;
    }
}

contract VowToken is ERC20 {
    constructor() ERC20("V-DOLLAR", "VD") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}