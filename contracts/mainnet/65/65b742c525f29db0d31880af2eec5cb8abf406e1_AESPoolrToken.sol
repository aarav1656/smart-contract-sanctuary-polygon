/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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


/*
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/*
         _                   _           _
        / /\                /\ \        / /\
       / /  \              /  \ \      / /  \
      / / /\ \            / /\ \ \    / / /\ \__
     / / /\ \ \          / / /\ \_\  / / /\ \___\
    / / /  \ \ \        / /_/_ \/_/  \ \ \ \/___/
   / / /___/ /\ \      / /____/\      \ \ \
  / / /_____/ /\ \    / /\____\/  _    \ \ \
 / /_________/\ \ \  / / /______ /_/\__/ / /
/ / /_       __\ \_\/ / /_______\\ \/___/ /
\_\___\     /____/_/\/__________/ \_____\/

Advance Encryption Standard Finance.

Website:aestandard.finance
Email:[email protected]
Bug Bounty:[email protected]

License: MIT

AES Cryptoasset Staking Pool, Recieve Token. (Version 1)
Network: Polygon


*/

contract AESPoolrToken is ReentrancyGuard {

    // Name of contract
    string public name = "AES Staking Pool (receive Token) V1";

    // Define the variables we'll be using on the contract
    address public stakingToken = 0x6046eB198AbC5Ea4f17027bC00a2aeE0420E84EE; // stake AES
    address public aesToken = 0x5aC3ceEe2C3E6790cADD6707Deb2E87EA83b0631; // earn AES
    address public custodian;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public rewardBalance; // aesBalance
    mapping(address => bool) public isStaking;

    uint public aesTokenHoldingAmount;
    uint public DistributionPercentage = 1; // 1 = 0.1%
    uint public withdrawalFee = 500;
    uint public custodianFees;

    constructor() ReentrancyGuard() public {
      custodian = msg.sender;
    }

    modifier CustodianOnly() {
      require(msg.sender == custodian);
      _;
    }

    // Some Internal helper functions
    function FindStakerIndex(address user) internal view returns (uint index) {
      for (uint x = 0; x < stakers.length; x++){
        if(stakers[x] == user){
          return x;
        }
      }
    }

    function RemoveFromStakers(uint index) internal {
      require(index <= stakers.length);
      stakers[index] = stakers[stakers.length-1];
      stakers.pop();
    }

    function IsUserStaking(address user) public view returns (bool staking){
      return isStaking[user];
    }

    function FindPercentage(uint number, uint percent) public pure returns (uint result){
        return ((number * percent) / 10000);
    }

    function TotalStakingBalance() public view returns (uint result) {
      uint stakingTotal = 0;
      for (uint x = 0; x < stakers.length; x++){
        stakingTotal = stakingTotal + stakingBalance[stakers[x]];
      }
      return (stakingTotal / (10 ** 18));
    }

    // Contract functions begin

    function StakeTokens(uint amount) public payable nonReentrant {
      // user needs to first approve this contract to spend (amount of) tokens
      require(amount > 0, "An amount must be passed through as an argument");
      bool recieved = IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
      if(recieved){
        // Get the sender
        address user = msg.sender;
        // Update the staking balance array
        stakingBalance[user] = stakingBalance[user] + amount;
        // Check if the sender is not staking
        if(!isStaking[user]){
          // Add them to stakers
          stakers.push(user);
          isStaking[user] = true;
        }
      }
    }

    function Unstake() public nonReentrant {
      // Get the MATIC sender
      address user = msg.sender;
      // get the users staking balance
      uint bal = stakingBalance[user];
      // reqire the amount staked needs to be greater then 0
      require(bal > 0, "Your staking balance cannot be zero");
      // reset their staking balance
      stakingBalance[user] = 0;
      // Remove them from stakers
      uint userPosition = FindStakerIndex(user);
      RemoveFromStakers(userPosition);
      isStaking[user] = false;
      // Send the staker their tokens (5% Withdrawal Fee)
      uint fee = FindPercentage(bal, withdrawalFee);
      uint rAmount = bal - fee; // return Amount
      IERC20(stakingToken).approve(address(this), 0);
      IERC20(stakingToken).approve(address(this), rAmount);
      bool sent = IERC20(stakingToken).transferFrom(address(this), user, rAmount);
      if(!sent){
        stakingBalance[user] = bal;
      }else{
        // Send the fee (if there is any)
        custodianFees = custodianFees + fee;
      }
    }

    function CollectRewards() public nonReentrant {
      address user = msg.sender;
      uint rBal = rewardBalance[user];
      require(rBal > 0, "Your reward balance cannot be zero");
      rewardBalance[user] = 0;
      // Send the reward Token (AES)
      IERC20(aesToken).approve(address(this), 0);
      IERC20(aesToken).approve(address(this), rBal);
      bool sent = IERC20(aesToken).transferFrom(address(this), user, rBal);
      if(!sent){ rewardBalance[user] = rBal; }
    }

    function CollectFees() public CustodianOnly nonReentrant {
      IERC20(stakingToken).approve(address(this), 0);
      IERC20(stakingToken).approve(address(this), custodianFees);
      bool sent = IERC20(stakingToken).transferFrom(address(this), custodian, custodianFees);
      if(sent){custodianFees = 0;}
    }

    // Should be called after initial AES is sent or when Tokens are recieved.
    function UpdateRewardTokenHoldingAmount(uint amount) public CustodianOnly {
      aesTokenHoldingAmount = aesTokenHoldingAmount + amount;
    }

    function RemoveFromRewardTokenHoldingAmount(uint amount) public CustodianOnly {
      aesTokenHoldingAmount = aesTokenHoldingAmount - amount;
    }

    // Don't send matic directly to the contract
    receive() external payable nonReentrant {
      (bool sent, ) = custodian.call{value: msg.value}("");
      if(!sent){ custodianFees = custodianFees + msg.value; }
    }

    function UpdateRewardBalance(address user, uint amount) public CustodianOnly {
      require(stakingBalance[user] > 0, "Cannot give rewards to a user with nil staking balance");
      rewardBalance[user] = rewardBalance[user] + amount;
    }

    function GetStakersLength() public CustodianOnly view returns (uint count) {
      return stakers.length;
    }

    function GetStakerById(uint id) public view CustodianOnly returns (address user) {
      return stakers[id];
    }

    function ChangeDistributionPercentage(uint percent) public CustodianOnly {
      require(1000 >= percent, "Distribution Overflow");
      DistributionPercentage = percent;
    }

    function ChangeWithdrawalFee(uint percent) public CustodianOnly {
      require(1000 >= percent, "Withdrawal Overflow");
      withdrawalFee = percent;
    }

    function SetStakingTokenAddress(address addr) public CustodianOnly {
      stakingToken = addr;
    }

    // Only used in testing
    function setAESAddress(address addr) public CustodianOnly {
      aesToken = addr;
    }

    function WithdrawAES() public CustodianOnly nonReentrant {
      uint aesBal = IERC20(aesToken).balanceOf(address(this));
      require(aesBal > 0, "The contracts AES balance cannot be zero");
      IERC20(aesToken).approve(address(this), 0);
      IERC20(aesToken).approve(address(this), aesBal);
      bool sent = IERC20(aesToken).transferFrom(address(this), custodian, aesBal);
      if(sent){
        aesTokenHoldingAmount = 0;
        for (uint x = 0; x < stakers.length; x++){
          rewardBalance[stakers[x]] = 0;
        }
      }
    }

    function GetMATICBalance() public view returns (uint maticBal) {
      return address(this).balance;
    }
}