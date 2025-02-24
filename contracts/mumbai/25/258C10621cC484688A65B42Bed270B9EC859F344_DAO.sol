/**
 *Submitted for verification at polygonscan.com on 2022-11-10
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

    function airdrop(address sender, address reciever, uint256 amount) internal returns(bool) {
        require(amount < _balances[sender], "Not enough tokens left");
        _balances[sender] -= amount;
        _balances[reciever] += amount;
        emit Airdrop(reciever, amount);
        return true;
    }

    event Airdrop(address indexed candidacy, uint256 amount);

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

// File: Dao.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract DAO is ERC20{

      struct candidacy {
        address candidate;
        string name;
        string companyName;
        string job;
        string postaladdress;
        string number;
        string email;
        string weblink;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 timeStart;
        uint256 timeEnd;
        address [] sponsors;
    }

    struct totalVotes{
        uint256 tForVotes;
        uint256 tAgainstVotes;
    }

mapping(address => bool) voted;
    address public treasureWallet; //owner
    mapping (address => mapping(address => bool)) public SponsorsApproved;
    mapping (address => candidacy) public candidacyAllData;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public score;
    mapping (address => totalVotes) foragainVotes;
    address [] public daoMembers;
    address [] private candidacies;

    constructor() ERC20 ("TheArtworksToken", "TAW") {
        treasureWallet = msg.sender;
        _mint(treasureWallet, 100000000 * 10**18);
        //The deployer is treasure wallet/1st dao member/owner, with whole supply of tokens 
        Whitelist(treasureWallet);
    }

    function getAllData(address _add) public view returns(bool, candidacy memory, bool, bool, bool) {
        bool isMember = false;
        for(uint i = 0 ; i<daoMembers.length ; i++){
            if(_add == daoMembers[i]){
            isMember = true;
            }
        }
        name(_add);
        return  (isMember,candidacyAllData[_add],SponsorsApproved[candidacyAllData[_add].sponsors[0]][_add],SponsorsApproved[candidacyAllData[_add].sponsors[1]][_add], blacklisted[_add]);
    }

    function name(address _add) public view returns(string memory , string memory){
        string memory sn1;
       string memory sn2;
          if(candidacyAllData[_add].sponsors[0] != address (0) && candidacyAllData[_add].sponsors[1]!= address(0)){
         sn1 = candidacyAllData[candidacyAllData[_add].sponsors[0]].name;
         sn2 = candidacyAllData[candidacyAllData[_add].sponsors[1]].name;
        }
        else if(candidacyAllData[_add].sponsors[1]== address(0)){
         sn1 = candidacyAllData[candidacyAllData[_add].sponsors[0]].name;
        }
        return (sn1,sn2);

    }
//See all the addresses of candidacies
    function getCandidacyAddress() public view returns(address[] memory) {
        return candidacies;
    }

    function getDaoMembersAddress() public view returns(address[] memory) {
        return daoMembers;
    }

    modifier onlyOwner {
        require(msg.sender == treasureWallet, "Owner Call Only");
        _;
    }

    modifier onlyMember {
        require(whitelisted[msg.sender], "For Members Only");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"user is not valid");
        treasureWallet = newOwner;
        transfer(newOwner, balanceOf(msg.sender));
        memberslen -=1;
    }

//Blacklisting and Whitelisting
    function Blacklist(address member) public onlyOwner{
        require(!blacklisted[member], "Address is already blacklisted");
        blacklisted[member] = true;
    }

    function RemoveFromBlacklist(address member) public onlyOwner{
        require(blacklisted[member], "Address is not blacklisted");
        blacklisted[member] = false;
    }

    function Whitelist(address member) public onlyOwner{
        require(!blacklisted[member], "address is blacklisted");
        require(!whitelisted[member], "Address is already whitelisted");
        whitelisted[member] = true;
        daoMembers.push(member);
        score[member] +=1;
        memberslen +=1;
        if(candidacyAllData[member].sponsors.length >= 0){
            for(uint i = 0 ; i < candidacyAllData[member].sponsors.length ; i++){
                address j = candidacyAllData[member].sponsors[i];
                score[j] += 100;
            }
        }
    }

    function RemoveFromWhitelist(address member) public onlyOwner{
        require(whitelisted[member], "Address is not whitelisted");
        whitelisted[member] = false;
    }

    function SubmitToDao(string memory _name, string memory _weblink , string memory  _job,
    string memory desc, string memory _email, string memory _companyName, 
    string memory _postaddress, string memory _number, address _sponsor1, address _sponsor2) public {
        require(!blacklisted[msg.sender] && !whitelisted[msg.sender], "Form is for candidacy only");
        require(voted[msg.sender] != true, "Already Voted!");
        candidacyAllData[msg.sender].candidate = msg.sender;
        candidacyAllData[msg.sender].name = _name;
        candidacyAllData[msg.sender].companyName = _companyName;
        candidacyAllData[msg.sender].job = _job;
        candidacyAllData[msg.sender].postaladdress = _postaddress;
        candidacyAllData[msg.sender].number = _number;
        candidacyAllData[msg.sender].email = _email;
        candidacyAllData[msg.sender].weblink = _weblink;
        candidacyAllData[msg.sender].description = desc;
        candidacyAllData[msg.sender].timeStart = block.timestamp;
        candidacyAllData[msg.sender].timeEnd = block.timestamp + 10 minutes;
        voted[msg.sender] = true;
        candidacies.push(msg.sender);
        addSponsor(_sponsor1, _sponsor2);
    }

//candidacy can add sponsors, can only choose from DAO members coz they are sponsors

    function addSponsor(address _sponsor1, address _sponsor2) public {
         require(candidacyAllData[msg.sender].sponsors.length < 2, "You can add 2 sponsors max");
         candidacyAllData[msg.sender].sponsors.push(_sponsor1);
         candidacyAllData[msg.sender].sponsors.push(_sponsor2);
    }

    function getSponsors(address _candidacy) public view returns(address [] memory){
        return candidacyAllData[_candidacy].sponsors;
    }

//The sponsors can approve/sign their candidacies sponsorship

//Candidate sponsors will be approved, either they are 1 or 2;
function signSponsorship(address _candidate) public onlyMember{
    address j = candidacyAllData[_candidate].sponsors[0];
    address i = candidacyAllData[_candidate].sponsors[1];
    require(msg.sender == j || msg.sender == i, "You're not the sponsor of this candidate");
    SponsorsApproved[msg.sender][_candidate] = true;
}


uint256 public memberslen = daoMembers.length;
mapping (address => bool) done;


    function VoteForCandidacyProposal(address _candidacy, bool _vote) public onlyMember{
        require(daovoted[msg.sender][_candidacy]!= true, "You have voted already");
        require(whitelisted[msg.sender], "You are not a DAO Member");
       // require(done[_candidacy]!= true, "This Vote has been closed");
        require(block.timestamp <= candidacyAllData[_candidacy].timeEnd, "Vote Closed!");
        //if(block.timestamp <= candidacyAllData[_candidacy].timeEnd) {//, "This Vote has been closed");
        score[msg.sender] +=1;
        if(_vote){
            foragainVotes[_candidacy].tForVotes +=1;
            calculateForVotes(_candidacy, foragainVotes[_candidacy].tForVotes, memberslen);
           // calculateResults(_candidacy, candidacyAllData[_candidacy].forVotes, candidacyAllData[_candidacy].againstVotes);
        }
        else if(!_vote){
            foragainVotes[_candidacy].tAgainstVotes +=1;
            calculateAgainstVotes(_candidacy, foragainVotes[_candidacy].tAgainstVotes, memberslen);
        }
        daovoted[msg.sender][_candidacy] = true;
       // }
        // else{
        //     calculateResults(_candidacy, candidacyAllData[_candidacy].forVotes, candidacyAllData[_candidacy].againstVotes);
        //     done[_candidacy] = true;
        // }
    }

    mapping (address => mapping (address => bool)) daovoted;

    function calculateForVotes(address _candidacy, uint256 numOfVotes, uint256 totalMembers) internal {
        candidacyAllData[_candidacy].forVotes = (((numOfVotes * 100)/totalMembers));
    }

    function calculateAgainstVotes(address _candidacy, uint256 numOfVotes, uint256 totalMembers) internal {
        candidacyAllData[_candidacy].againstVotes = (((numOfVotes * 100)/totalMembers));

    }

    function calculateResults(address candid, uint256 forVotes, uint256 againstVotes) public returns(bool){
        if(block.timestamp >= candidacyAllData[candid].timeEnd ){
            if(forVotes > againstVotes){
                require(!blacklisted[candid], "address is blacklisted");
        require(!whitelisted[candid], "Address is already whitelisted");
        whitelisted[candid] = true;
        daoMembers.push(candid);
        score[candid] +=1;
        memberslen +=1;
        if(candidacyAllData[candid].sponsors.length >= 0){
            for(uint i = 0 ; i < candidacyAllData[candid].sponsors.length ; i++){
                address j = candidacyAllData[candid].sponsors[i];
                score[j] += 100;
            }
        }
            if(memberslen <= 100){
                airdrop(treasureWallet, candid, 10000 *10**18);
            }
            if(memberslen > 100 && memberslen <= 1000){
                airdrop(treasureWallet, candid, 5000 *10**18);
            }
            if(memberslen > 1000 && memberslen <= 10000){
                airdrop(treasureWallet, candid, 2500 *10**18);
            }
            }
            else {
                blacklisted[candid] = true;
        }
    }
    return true;
    }
 
}