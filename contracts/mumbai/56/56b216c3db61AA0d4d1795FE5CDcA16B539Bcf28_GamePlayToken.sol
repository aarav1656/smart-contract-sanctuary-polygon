/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: GamePlayToken.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

 

 contract GamePlayToken is ERC20{
     uint private totalTokenSupply;
     address private ownerAddress;
     address private contractAddress;
     uint public publicPrice;
     uint public strategicPrice;
     mapping(address=>uint) currentBalance;

     mapping(address=>uint) public tokenBalance;
     mapping(address=>uint) public strategicSaleBalance;
     mapping(address=>uint) public publicSaleBalance;
     mapping(address=>uint) public marketingBalance;
     mapping(address=>uint) public developmentTeamBalance;
     mapping(address=>uint) public liquidityBalance;
     mapping(address=>uint) public playToEarnBalance;
     mapping(address=>uint) public foundationBalance;
     mapping(address=>uint) public steakBalance;
     mapping(address=>uint) public unlockedBalance;

     mapping(address=>uint) strategicUnlockTimeLock;
     mapping(address=>uint) marketingUnlockTimeLock;
     mapping(address=>uint) developmentUnlockTimeLock;
     bool private developmentFirstUnlock;

     address[] private strategicAdresses;
     address[] private publicAddresses;
     bool private publicFirstSell;
     bool private strategicFirstSell;
     mapping(address=>uint) public publicSaleRemainingAmount;
     mapping(address=>uint) public unlockedPublicBalance;
     mapping(address=>uint) public remainingPublicBalance;

     mapping(address=>uint) public unlockedStrategicBalance;
     mapping(address=>uint) public remainingStrategicBalance;

     modifier OnlyOwner(){
         require(msg.sender==ownerAddress,"Owner only");
         _;
     }

     constructor() ERC20("GamePlayToken","GPT"){
         //Total supply declaration 
         totalTokenSupply = 800000000*10**18;
         //Contract address and the owner address
         contractAddress = address(this);
         ownerAddress = msg.sender;
         //Assignment of balances
         tokenBalance[contractAddress] = totalTokenSupply;
         strategicSaleBalance[contractAddress] = (totalTokenSupply*14)/100;
         publicSaleBalance[contractAddress] = (totalTokenSupply*2)/100;
         marketingBalance[contractAddress] = (totalTokenSupply*6)/100;
         developmentTeamBalance[contractAddress] = (totalTokenSupply*7)/100;
         liquidityBalance[contractAddress] = (totalTokenSupply*3)/100;
         playToEarnBalance[contractAddress] = (totalTokenSupply*51)/100;
         foundationBalance[contractAddress] = (totalTokenSupply*7)/100;
         steakBalance[contractAddress] = (totalTokenSupply*10)/100;
         
         tokenBalance[contractAddress] -= strategicSaleBalance[contractAddress] + publicSaleBalance[contractAddress] + marketingBalance[contractAddress] + 
            developmentTeamBalance[contractAddress] + liquidityBalance[contractAddress] + playToEarnBalance[contractAddress] + foundationBalance[contractAddress]
            + steakBalance[contractAddress];
        strategicSaleBalance[contractAddress] = block.timestamp + 30 days;
        marketingUnlockTimeLock[0x17A98E9eF16D0E9f3B24a7d68038dDfeB1E968A2] = block.timestamp + 30 days;
        developmentUnlockTimeLock[0x5f88fDFa55727Db194865Ea41ca9f8787060cd54] = block.timestamp + 150 days;
        publicPrice = 3*10**16;
        strategicPrice = 23*10**15;
         _mint(contractAddress,totalTokenSupply);
     }

     function BuyStrategicSale() public payable{
         require(msg.value<=msg.sender.balance,"You do not have enough funds");
         uint tokenAmount = (msg.value*10**18/strategicPrice);
         payable(ownerAddress).transfer(msg.value);
         strategicSaleBalance[contractAddress] -= tokenAmount;
         strategicSaleBalance[msg.sender] += tokenAmount;
         strategicAdresses.push(msg.sender);
         unlockedBalance[msg.sender] += (tokenAmount*4)/100;
         unlockedStrategicBalance[msg.sender] += (strategicSaleBalance[msg.sender]*4)/100;
         remainingStrategicBalance[msg.sender] = strategicSaleBalance[msg.sender]-unlockedStrategicBalance[msg.sender];
     }
     function BuyPublicSale() public payable{
         require(msg.value<=msg.sender.balance,"You do not have enough funds");
         uint tokenAmount = (msg.value*10**18/publicPrice);
         payable(ownerAddress).transfer(msg.value);
         publicSaleBalance[contractAddress] -= tokenAmount;
         publicSaleBalance[msg.sender] += tokenAmount;
         publicAddresses.push(msg.sender);
         unlockedBalance[msg.sender] += (tokenAmount*5)/100;
         unlockedPublicBalance[msg.sender] += (tokenAmount*5)/100;
         remainingPublicBalance[msg.sender] = publicSaleBalance[msg.sender]-unlockedPublicBalance[msg.sender];
         publicSaleRemainingAmount[msg.sender] = remainingPublicBalance[msg.sender]/12;
     } 

     /*function IncreaseTokenAmount(uint supply) public{
         tokenBalance[contractAddress] += supply;
         _mint(contractAddress,tokenBalance[contra]);
     }*/
     function WithdrawTokens() public{
         require(unlockedBalance[msg.sender]>0,"You don't have enough funds");
         if(!publicFirstSell && publicSaleBalance[msg.sender]>0){
             publicSaleRemainingAmount[msg.sender] -= (publicSaleRemainingAmount[msg.sender]*5)/100;
             publicFirstSell = true;
             publicSaleRemainingAmount[msg.sender] = publicSaleBalance[msg.sender]/12;
         }
         if(strategicSaleBalance[msg.sender]>0 && !strategicFirstSell){
            strategicSaleBalance[msg.sender]-=(strategicSaleBalance[msg.sender]*4)/100;
            strategicFirstSell = true;
         }
         this.transfer(msg.sender,unlockedBalance[msg.sender]);
         unlockedBalance[msg.sender] = 0;
         tokenBalance[msg.sender] = publicSaleBalance[msg.sender]+strategicSaleBalance[msg.sender];
     }
     function UnlockStrategicTokens() public OnlyOwner{
         for(uint i=0; i<strategicAdresses.length; i++){
             uint unlockedAmount = (remainingStrategicBalance[strategicAdresses[i]]*4)/100;
             unlockedBalance[strategicAdresses[i]] += unlockedAmount;
             remainingStrategicBalance[strategicAdresses[i]] -= unlockedAmount;
             unlockedStrategicBalance[strategicAdresses[i]] += unlockedAmount;
         }
     }
     function UnlockPublicTokens() public{
         require(msg.sender==ownerAddress,"You cannot complete this operation");
         for(uint i=0; i<publicAddresses.length; i++){
            unlockedBalance[publicAddresses[i]] += publicSaleRemainingAmount[publicAddresses[i]];
            remainingPublicBalance[publicAddresses[i]] -= publicSaleRemainingAmount[publicAddresses[i]];
            unlockedPublicBalance[publicAddresses[i]] += publicSaleRemainingAmount[publicAddresses[i]];
            
         }
     }

     function UnlockMarketingTokens() public OnlyOwner{
         require(block.timestamp>marketingUnlockTimeLock[0x17A98E9eF16D0E9f3B24a7d68038dDfeB1E968A2],"Time has not passed yet");
         this.transfer(0x17A98E9eF16D0E9f3B24a7d68038dDfeB1E968A2,(marketingBalance[contractAddress]*1)/100);
         marketingUnlockTimeLock[0x17A98E9eF16D0E9f3B24a7d68038dDfeB1E968A2] = block.timestamp + 30 days;
         marketingBalance[0x869d6e60693952816c75B167af18839b3c99fe47] -= (marketingBalance[contractAddress]*1)/100;
     }
     
     function UnlockDevelopmentTokens() public OnlyOwner{
         if(block.timestamp > developmentUnlockTimeLock[0x5f88fDFa55727Db194865Ea41ca9f8787060cd54] && !developmentFirstUnlock){
             this.transfer(0x5f88fDFa55727Db194865Ea41ca9f8787060cd54,(developmentTeamBalance[contractAddress]*2)/100);
             developmentUnlockTimeLock[0x5f88fDFa55727Db194865Ea41ca9f8787060cd54] = block.timestamp+90 days;
             developmentFirstUnlock = true;
         }
         else if(developmentFirstUnlock && block.timestamp>developmentUnlockTimeLock[0x5f88fDFa55727Db194865Ea41ca9f8787060cd54]){
             this.transfer(0x5f88fDFa55727Db194865Ea41ca9f8787060cd54,(developmentTeamBalance[contractAddress]*2)/100);
             developmentUnlockTimeLock[0x5f88fDFa55727Db194865Ea41ca9f8787060cd54] = block.timestamp+90 days;
             developmentTeamBalance[contractAddress] -= (developmentTeamBalance[contractAddress]*2)/100;
         }
         else{
             revert("Time has not passed yet");
         }
     }

     function SetPublicPrice(uint newPrice) public OnlyOwner{
         publicPrice = newPrice*10**17;
     }
     function SetStrategicPrice(uint newPrice) public OnlyOwner{
         strategicPrice = newPrice*10**17;
     }

 }