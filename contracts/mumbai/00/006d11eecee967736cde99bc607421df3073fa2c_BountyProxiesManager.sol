//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// import "./interfaces/IMIMOProxy.sol";
// import "./interfaces/IBountyProxyFactory.sol";
// import "./interfaces/IMIMOProxyRegistry.sol";
// import "../core/interfaces/IAddressProvider.sol";
// import "../core/interfaces/IAccessController.sol";
// import { CustomErrors } from "../libraries/CustomErrors.sol";
import "./SaloonWallet.sol";
import "./BountyProxyFactory.sol";
import "./IBountyProxyFactory.sol";
import "./BountyPool.sol";

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";

//// THOUGHTS:
// Planning to separate this into contracts:
// 1. Registry contract that holds varaibles
// 2. Manager Contract that hold state changing functions and inherits Registry

contract BountyProxiesManager is OwnableUpgradeable, UUPSUpgradeable {
    /// PUBLIC STORAGE ///

    event DeployNewBounty(
        address indexed sender,
        address indexed _projectWallet,
        BountyPool newProxyAddress
    );

    // should this be a constant?
    BountyProxyFactory public factory;
    UpgradeableBeacon public beacon;
    address public bountyImplementation;
    SaloonWallet public saloonWallet;

    struct Bounties {
        string projectName;
        address projectWallet;
        BountyPool proxyAddress;
        address token;
        bool dead;
    }

    Bounties[] public bountiesList;
    // Project name => project auth address => proxy address
    mapping(string => Bounties) public bountyDetails;
    // Token address => approved or not
    mapping(address => bool) public tokenWhitelist;

    function notDead(bool _isDead) internal pure returns (bool) {
        // if notDead is false return bounty is live(true)
        return _isDead == false ? true : false;
    }

    // factory address might not be known at the time of deployment
    /// @param _factory The base contract of the factory
    // constructor(
    //     BountyProxyFactory factory_,
    //     UpgradeableBeacon _beacon,
    //     address _bountyImplementation
    // ) {
    //     factory = factory_;
    //     beacon = _beacon;
    //     bountyImplementation = _bountyImplementation;
    // }
    function initialize(
        BountyProxyFactory _factory,
        UpgradeableBeacon _beacon,
        address _bountyImplementation
    ) public initializer {
        factory = _factory;
        beacon = _beacon;
        bountyImplementation = _bountyImplementation;
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    //////// UPDATE SALOON WALLET FOR HUNTER PAYOUTS ////// done
    function updateSaloonWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "Address cant be zero");
        saloonWallet = SaloonWallet(_newWallet);
    }

    //////// WITHDRAW FROM SALOON WALLET ////// done
    function withdrawSaloon(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        require(_to != address(0), "Address Zero");
        saloonWallet.withdrawSaloonFunds(_token, _to, _amount);
        return true;
    }

    ///// DEPLOY NEW BOUNTY ////// done
    function deployNewBounty(
        bytes memory _data,
        string memory _projectName,
        address _token,
        address _projectWallet
    ) external onlyOwner returns (BountyPool, bool) {
        // revert if project name already has bounty
        require(
            bountyDetails[_projectName].proxyAddress == BountyPool(address(0)),
            "Project already has bounty"
        );

        require(tokenWhitelist[_token] == true, "Token not approved");

        Bounties memory newBounty;
        newBounty.projectName = _projectName;
        newBounty.projectWallet = _projectWallet;
        newBounty.token = _token;

        // call factory to deploy bounty
        BountyPool newProxyAddress = factory.deployBounty(
            address(beacon),
            _data
        );
        newProxyAddress.initializeImplementation(address(this));

        newBounty.proxyAddress = newProxyAddress;

        // Push new bounty to storage array
        bountiesList.push(newBounty);

        // Create new mapping so we can look up bounty details by their name
        bountyDetails[_projectName] = newBounty;

        //  NOT NEEDED  update proxyWhitelist in implementation
        // bountyImplementation.updateProxyWhitelist(newProxyAddress, true);
        emit DeployNewBounty(msg.sender, _projectWallet, newProxyAddress);

        return (newProxyAddress, true);
    }

    ///// KILL BOUNTY ////
    function killBounty(string memory _projectName)
        external
        onlyOwner
        returns (bool)
    {
        // attempt to withdraw all money?
        // call (currently non-existent) pause function?
        // look up address by name
        bountyDetails[_projectName].dead = true;

        return true;
    }

    ///// PUBLIC PAY PREMIUM FOR ONE BOUNTY // done
    // todo cache variables for gas efficiency
    function billPremiumForOnePool(string memory _projectName)
        external
        returns (bool)
    {
        // check if active
        require(
            notDead(bountyDetails[_projectName].dead) == true,
            "Bounty is Dead"
        );
        // bill
        bountyDetails[_projectName].proxyAddress.billFortnightlyPremium(
            bountyDetails[_projectName].token,
            bountyDetails[_projectName].projectWallet
        );
        return true;
    }

    ///// PUBLIC PAY PREMIUM FOR ALL BOUNTIES // done
    function billPremiumForAll() external returns (bool) {
        // cache bounty bounties listt
        Bounties[] memory bountiesArray = bountiesList;
        uint256 length = bountiesArray.length;
        // iterate through all bounty proxies
        for (uint256 i; i < length; ++i) {
            // collect the premium fees from bounty
            if (notDead(bountiesArray[i].dead) == true) {
                continue; // killed bounties are supposed to be skipped.
            }
            bountiesArray[i].proxyAddress.billFortnightlyPremium(
                bountiesArray[i].token,
                bountiesArray[i].projectWallet
            );
        }
        return true;
    }

    /// ADMIN WITHDRAWAL FROM POOL  TO PAY BOUNTY /// done
    function payBounty(
        string memory _projectName,
        address _hunter,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        require(
            notDead(bountyDetails[_projectName].dead) == true,
            "Bounty is Dead"
        );
        bountyDetails[_projectName].proxyAddress.payBounty(
            bountyDetails[_projectName].token,
            address(saloonWallet),
            _hunter,
            _amount
        );
        // update saloonWallet variables
        saloonWallet.bountyPaid(
            bountyDetails[_projectName].token,
            _hunter,
            _amount
        );
        return true;
    }

    /// ADMIN CLAIM PREMIUM FEES for ALL BOUNTIES/// done
    function withdrawSaloonPremiumFees() external onlyOwner returns (bool) {
        // cache bounty bounties listt
        Bounties[] memory bountiesArray = bountiesList;
        uint256 length = bountiesArray.length;
        // iterate through all bounty proxies
        for (uint256 i; i < length; ++i) {
            if (notDead(bountiesArray[i].dead) == true) {
                continue; // killed bounties are supposed to be skipped.
            }
            // collect the premium fees from bounty
            uint256 totalCollected = bountiesArray[i]
                .proxyAddress
                .collectSaloonPremiumFees(
                    bountiesArray[i].token,
                    address(saloonWallet)
                );

            saloonWallet.premiumFeesCollected(
                bountiesArray[i].token,
                totalCollected
            );
        }
        return true;
    }

    /// ADMIN update BountyPool IMPLEMENTATION ADDRESS of UPGRADEABLEBEACON /// done
    function updateBountyPoolImplementation(address _newImplementation)
        external
        onlyOwner
        returns (bool)
    {
        require(_newImplementation != address(0), "Address zero");
        beacon.upgradeTo(_newImplementation);

        return true;
    }

    ///????????????? ADMIN CHANGE ASSIGNED TOKEN TO BOUNTY /// ????????

    /// ADMIN UPDATE APPROVED TOKENS /// done
    function updateTokenWhitelist(address _token, bool whitelisted)
        external
        onlyOwner
        returns (bool)
    {
        tokenWhitelist[_token] = whitelisted;
    }

    //////// PROJECTS FUNCTION TO CHANGE APY and CAP by NAME///// done
    // time locked
    // fails if msg.sender != project owner
    function setBountyCapAndAPY(
        string memory _projectName,
        uint256 _poolCap,
        uint256 _desiredAPY
    ) external returns (bool) {
        // look for project address
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // require msg.sender == projectWallet
        require(msg.sender == bounty.projectWallet, "Not project owner");

        // set cap
        bounty.proxyAddress.setPoolCap(_poolCap);
        // set APY
        bounty.proxyAddress.setDesiredAPY(
            bounty.token,
            bounty.projectWallet,
            _desiredAPY
        );

        return true;
    }

    /////// PROJECTS FUNCTION TO DEPOSIT INTO POOL by NAME/////// done
    function projectDeposit(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if msg.sender is allowed
        require(msg.sender == bounty.projectWallet, "Not project owner");
        // do deposit
        bounty.proxyAddress.bountyDeposit(
            bounty.token,
            bounty.projectWallet,
            _amount
        );

        return true;
    }

    /////// PROJECT FUNCTION TO SCHEDULE WITHDRAW FROM POOL  by PROJECT NAME///// done
    function scheduleProjectDepositWithdrawal(
        string memory _projectName,
        uint256 _amount
    ) external returns (bool) {
        // cache bounty
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if caller is project
        require(msg.sender == bounty.projectWallet, "Not project owner");

        // schedule withdrawal
        bounty.proxyAddress.scheduleprojectDepositWithdrawal(_amount);

        return true;
    }

    /////// PROJECT FUNCTION TO WITHDRAW FROM POOL  by PROJECT NAME///// done
    function projectDepositWithdrawal(
        string memory _projectName,
        uint256 _amount
    ) external returns (bool) {
        // cache bounty
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        // check if caller is project
        require(msg.sender == bounty.projectWallet, "Not project owner");

        // schedule withdrawal
        bounty.proxyAddress.projectDepositWithdrawal(
            bounty.token,
            bounty.projectWallet,
            _amount
        );

        return true;
    }

    ////// STAKER FUNCTION TO STAKE INTO POOL by PROJECT NAME////// done
    function stake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");
        bounty.proxyAddress.stake(bounty.token, msg.sender, _amount);

        return true;
    }

    ////// STAKER FUNCTION TO SCHEDULE UNSTAKE FROM POOL /////// done
    function scheduleUnstake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        //todo should all these function check return value like this?
        if (bounty.proxyAddress.askForUnstake(msg.sender, _amount)) {
            return true;
        }
    }

    ////// STAKER FUNCTION TO UNSTAKE FROM POOL /////// done
    function unstake(string memory _projectName, uint256 _amount)
        external
        returns (bool)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        if (bounty.proxyAddress.unstake(bounty.token, msg.sender, _amount)) {
            return true;
        }
    }

    ///// STAKER FUNCTION TO CLAIM PREMIUM by PROJECT NAME////// done
    function claimPremium(string memory _projectName)
        external
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];

        // check if active
        require(notDead(bounty.dead) == true, "Bounty is Dead");

        (uint256 premiumClaimed, ) = bounty.proxyAddress.claimPremium(
            bounty.token,
            msg.sender,
            bounty.projectWallet
        );

        return premiumClaimed;
    }

    // ??????????/  STAKER FUNCTION TO STAKE INTO GLOBAL POOL??????????? //////

    ///////////////////////// VIEW FUNCTIONS //////////////////////

    // Function to view all bounties name string // done
    function viewAllBountiesByName() external view returns (Bounties[] memory) {
        return bountiesList;
    }

    //?????? Function to view TVL , average APY and remaining  amount to reach total CAP of all pools together //
    function viewBountyInfo(string memory _projectName)
        external
        view
        returns (
            uint256 payout,
            uint256 apy,
            uint256 staked,
            uint256 poolCap
        )
    {
        payout = viewHackerPayout(_projectName);
        staked = viewstakersDeposit(_projectName);
        apy = viewDesiredAPY(_projectName);
        poolCap = viewPoolCap(_projectName);
    }

    function viewBountyBalance(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewBountyBalance();
    }

    function viewPoolCap(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewPoolCap();
    }

    // Function to view Total Balance of Pool By Project Name // done
    function viewHackerPayout(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewHackerPayout();
    }

    // Function to view Project Deposit to Pool by Project Name // done
    function viewProjectDeposit(string memory _projectName)
        external
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewProjecDeposit();
    }

    // Function to view Total Staker Balance of Pool By Project Name // done
    function viewstakersDeposit(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewStakersDeposit();
    }

    function viewDesiredAPY(string memory _projectName)
        public
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        return bounty.proxyAddress.viewDesiredAPY();
    }

    // Function to view individual Staker Balance in Pool by Project Name // done
    function viewUserStakingBalance(string memory _projectName)
        external
        view
        returns (uint256)
    {
        Bounties memory bounty = bountyDetails[_projectName];
        (uint256 stakingBalance, ) = bounty.proxyAddress.viewUserStakingBalance(
            msg.sender
        );
        return stakingBalance;
    }

    // Function to find bounty proxy and wallet address by Name // done
    function getBountyAddressByName(string memory _projectName)
        external
        view
        returns (address)
    {
        return address(bountyDetails[_projectName].proxyAddress);
    }

    function viewBountyOwner(string memory _projectName)
        external
        view
        returns (address)
    {
        return address(bountyDetails[_projectName].projectWallet);
    }

    //  SALOON WALLET VIEW FUNCTIONS
    function viewSaloonBalance() external view returns (uint256) {
        return saloonWallet.viewSaloonBalance();
    }

    function viewTotalEarnedSaloon() external view returns (uint256) {
        return saloonWallet.viewTotalEarnedSaloon();
    }

    function viewTotalHackerPayouts() external view returns (uint256) {
        return saloonWallet.viewTotalHackerPayouts();
    }

    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return saloonWallet.viewHunterTotalTokenPayouts(_token, _hunter);
    }

    function viewTotalSaloonCommission() external view returns (uint256) {
        return saloonWallet.viewTotalSaloonCommission();
    }

    function viewTotalPremiums() external view returns (uint256) {
        return saloonWallet.viewTotalPremiums();
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SaloonWallet {
    using SafeERC20 for IERC20;

    uint256 public constant BOUNTY_COMMISSION = 12 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;

    address public immutable manager;

    // premium fees to collect
    uint256 public premiumFees;
    uint256 public saloonTotalBalance;
    uint256 public cummulativeCommission;
    uint256 public cummulativeHackerPayouts;

    // hunter balance per token
    // hunter address => token address => amount
    mapping(address => mapping(address => uint256)) public hunterTokenBalance;

    // saloon balance per token
    // token address => amount
    mapping(address => uint256) public saloonTokenBalance;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    // bountyPaid
    function bountyPaid(
        address _token,
        address _hunter,
        uint256 _amount
    ) external onlyManager {
        // calculate commision
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // update variables and mappings
        hunterTokenBalance[_hunter][_token] += hunterPayout;
        cummulativeHackerPayouts += hunterPayout;
        saloonTokenBalance[_token] += saloonCommission;
        saloonTotalBalance += saloonCommission;
        cummulativeCommission += saloonCommission;
    }

    function premiumFeesCollected(address _token, uint256 _amount)
        external
        onlyManager
    {
        saloonTokenBalance[_token] += _amount;
        premiumFees += _amount;
        saloonTotalBalance += _amount;
    }

    //
    // WITHDRAW FUNDS TO ANY ADDRESS saloon admin
    function withdrawSaloonFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyManager returns (bool) {
        require(_amount <= saloonTokenBalance[_token], "not enough balance");
        // decrease saloon funds
        saloonTokenBalance[_token] -= _amount;
        saloonTotalBalance -= _amount;

        IERC20(_token).safeTransfer(_to, _amount);

        return true;
    }

    ///////////////////////   VIEW FUNCTIONS  ////////////////////////

    // VIEW SALOON CURRENT TOTAL BALANCE
    function viewSaloonBalance() external view returns (uint256) {
        return saloonTotalBalance;
    }

    // VIEW COMMISSIONS PLUS PREMIUM
    function viewTotalEarnedSaloon() external view returns (uint256) {
        uint256 premiums = viewTotalPremiums();
        uint256 commissions = viewTotalSaloonCommission();

        return premiums + commissions;
    }

    // VIEW TOTAL PAYOUTS MADE - commission - fees
    function viewTotalHackerPayouts() external view returns (uint256) {
        return cummulativeHackerPayouts;
    }

    // view hacker payouts by hunter
    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return hunterTokenBalance[_hunter][_token];
    }

    // VIEW TOTAL COMMISSION
    function viewTotalSaloonCommission() public view returns (uint256) {
        return cummulativeCommission;
    }

    // VIEW TOTAL IN PREMIUMS
    function viewTotalPremiums() public view returns (uint256) {
        return premiumFees;
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./BountyProxy.sol";
import "./IBountyProxyFactory.sol";
import "./BountyPool.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BountyProxyFactory is Ownable, Initializable {
    using Clones for address;
    /// PUBLIC STORAGE ///

    address public bountyProxyBase;

    address public manager;

    uint256 public constant VERSION = 1;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping to track all deployed proxies.
    mapping(address => bool) internal _proxies;

    function initiliaze(address payable _bountyProxyBase, address _manager)
        external
        initializer
        onlyOwner
    {
        bountyProxyBase = _bountyProxyBase;
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    function deployBounty(address _beacon, bytes memory _data)
        public
        onlyManager
        returns (BountyPool proxy)
    {
        proxy = BountyPool(bountyProxyBase.clone());

        BountyProxy newBounty = BountyProxy(payable(address(proxy)));
        newBounty.initialize(_beacon, _data, msg.sender);
        // proxy.initializeImplementation(msg.sender);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./BountyProxy.sol";
import "./BountyPool.sol";

/// @title IBountyProxyFactory
/// @notice Deploys new proxies with CREATE2.
interface IBountyProxyFactory {
    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Mapping to track all deployed proxies.
    /// @param proxy The address of the proxy to make the check for.
    function isProxy(address proxy) external view returns (bool result);

    /// @notice The release version of PRBProxy.
    /// @dev This is stored in the factory rather than the proxy to save gas for end users.
    function VERSION() external view returns (uint256);

    // /// @notice Deploys a new proxy for a given owner and returns the address of the newly created proxy
    // /// @param _projectWallet The owner of the proxy.
    // /// @return proxy The address of the newly deployed proxy contract.
    function deployBounty(
        address _beacon,
        address _projectWallet,
        bytes memory _data
    ) external returns (BountyPool proxy);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "./SaloonWallet.sol";

//  OBS: Better suggestions for calculating the APY paid on a fortnightly basis are welcomed.

contract BountyPool is Ownable, Initializable {
    using SafeERC20 for IERC20;
    //#################### State Variables *****************\\

    //todo possibly make this a constant
    address public manager;

    bool public APYdropped;

    uint256 public constant VERSION = 1;
    uint256 public constant BOUNTY_COMMISSION = 12 * 1e18;
    uint256 public constant PREMIUM_COMMISSION = 2 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;
    uint256 public constant YEAR = 365 days;

    uint256 public projectDeposit;
    uint256 public stakersDeposit;
    uint256 public bountyBalance = projectDeposit + stakersDeposit;

    uint256 public saloonBountyCommission;
    // bountyBalance - % commission

    uint256 public saloonPremiumFees;
    uint256 public premiumBalance;
    uint256 public desiredAPY;
    uint256 public poolCap;
    uint256 public lastTimePaid;
    uint256 public requiredPremiumBalancePerPeriod;
    uint256 public poolPeriod = 2 weeks;
    // amount => timelock
    mapping(uint256 => uint256) public projectWithdrawalTimeLock;
    // staker => last time premium was claimed
    mapping(address => uint256) public lastClaimed;
    // staker address => stakerInfo array
    mapping(address => StakerInfo[]) public staker;

    address[] public stakerList;
    // staker address => amount => timelock time
    mapping(address => mapping(uint256 => uint256)) public stakerTimelock;

    struct StakerInfo {
        uint256 stakerBalance;
        uint256 balanceTimeStamp;
    }

    struct APYperiods {
        uint256 timeStamp;
        uint256 periodAPY;
    }

    APYperiods[] public APYrecords;

    //#################### State Variables End *****************\\

    function initializeImplementation(address _manager) public initializer {
        manager = _manager;
    }

    //#################### Modifiers *****************\\

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    //todo  maybe make this check at the manager level ????
    modifier onlyManagerOrSelf() {
        require(
            msg.sender == manager || msg.sender == address(this),
            "Only manager allowed"
        );
        _;
    }

    //#################### Modifiers END *****************\\

    //#################### Functions *******************\\

    // ADMIN PAY BOUNTY public
    // this implementation uses investors funds first before project deposit,
    // future implementation might use a more hybrid and sophisticated splitting of costs.
    // todo cache variables to make it more gas effecient
    function payBounty(
        address _token,
        address _saloonWallet,
        address _hunter,
        uint256 _amount
    ) public onlyManager returns (bool) {
        // check if stakersDeposit is enough
        if (stakersDeposit >= _amount) {
            // decrease stakerDeposit
            stakersDeposit -= _amount;
            // cache length
            uint256 length = stakerList.length;
            // if staker deposit == 0
            if (stakersDeposit == 0) {
                for (uint256 i; i < length; ++i) {
                    // update stakerInfo struct
                    StakerInfo memory newInfo;
                    newInfo.balanceTimeStamp = block.timestamp;
                    newInfo.stakerBalance = 0;

                    address stakerAddress = stakerList[i]; //todo cache stakerList before
                    staker[stakerAddress].push(newInfo);

                    // deduct saloon commission and transfer
                    calculateCommissioAndTransferPayout(
                        _token,
                        _hunter,
                        _saloonWallet,
                        _amount
                    );

                    // todo Emit event with timestamp and amount
                    return true;
                }

                // clean stakerList array
                delete stakerList;
            }
            // calculate percentage of stakersDeposit
            uint256 percentage = _amount / stakersDeposit;
            // loop through all stakers and deduct percentage from their balances
            for (uint256 i; i < length; ++i) {
                address stakerAddress = stakerList[i]; //todo cache stakerList before
                uint256 arraySize = staker[stakerAddress].length - 1;
                uint256 oldStakerBalance = staker[stakerAddress][arraySize]
                    .stakerBalance;

                // update stakerInfo struct
                StakerInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakerBalance =
                    oldStakerBalance -
                    ((oldStakerBalance * percentage) / DENOMINATOR);

                staker[stakerAddress].push(newInfo);
            }

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            // todo Emit event with timestamp and amount

            return true;
        } else {
            // reset baalnce of all stakers
            uint256 length = stakerList.length;
            for (uint256 i; i < length; ++i) {
                // update stakerInfo struct
                StakerInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakerBalance = 0;

                address stakerAddress = stakerList[i]; //todo cache stakerList before
                staker[stakerAddress].push(newInfo);
            }
            // clean stakerList array
            delete stakerList;
            // if stakersDeposit not enough use projectDeposit to pay the rest
            uint256 remainingCost = _amount - stakersDeposit;
            // descrease project deposit by the remaining amount
            projectDeposit -= remainingCost;

            // set stakers deposit to 0
            stakersDeposit = 0;

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            // todo Emit event with timestamp and amount
            return true;
        }
    }

    function calculateCommissioAndTransferPayout(
        address _token,
        address _hunter,
        address _saloonWallet,
        uint256 _amount
    ) internal returns (bool) {
        // deduct saloon commission
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // transfer to hunter
        IERC20(_token).safeTransfer(_hunter, hunterPayout); //todo maybe transfer to payout address
        // transfer commission to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonCommission);

        return true;
    }

    // ADMIN HARVEST FEES public
    function collectSaloonPremiumFees(address _token, address _saloonWallet)
        external
        onlyManager
        returns (uint256)
    {
        // send current fees to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonPremiumFees);
        uint256 totalCollected = saloonPremiumFees;
        // reset claimable fees
        saloonPremiumFees = 0;

        return totalCollected;

        // todo emit event
    }

    // PROJECT DEPOSIT
    // project must approve this address first.
    function bountyDeposit(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // transfer from project account
        IERC20(_token).safeTransferFrom(_projectWallet, address(this), _amount);

        // update deposit variable
        projectDeposit += _amount;

        return true;
    }

    // PROJECT SET CAP
    function setPoolCap(uint256 _amount) external onlyManager {
        // todo two weeks time lock?
        poolCap = _amount;
    }

    // PROJECT SET APY
    // project must approve this address first.
    // project will have to pay upfront cost of full period on the first time.
    // this will serve two purposes:
    // 1. sign of good faith and working payment system
    // 2. if theres is ever a problem with payment the initial premium deposit can be used as a buffer so users can still be paid while issue is fixed.
    function setDesiredAPY(
        address _token,
        address _projectWallet,
        uint256 _desiredAPY
    ) external onlyManager returns (bool) {
        // set timelock on this???
        // make sure APY has right amount of decimals (1e18)

        // ensure there is enough premium balance to pay stakers new APY for a month
        uint256 currentPremiumBalance = premiumBalance;
        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap * _desiredAPY) /
            DENOMINATOR) / YEAR) * poolPeriod;
        // this might lead to leftover premium if project decreases APY, we will see what to do about that later
        if (currentPremiumBalance < newRequiredPremiumBalancePerPeriod) {
            // calculate difference to be paid
            uint256 difference = newRequiredPremiumBalancePerPeriod -
                currentPremiumBalance;
            // transfer to this address
            IERC20(_token).safeTransferFrom(
                _projectWallet,
                address(this),
                difference
            );
            // increase premium
            premiumBalance += difference;
        }

        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;

        // register new APYperiod
        APYperiods memory newAPYperiod;
        newAPYperiod.timeStamp = block.timestamp;
        newAPYperiod.periodAPY = _desiredAPY;
        APYrecords.push(newAPYperiod);

        // set APY
        desiredAPY = _desiredAPY;

        // disable instant withdrawals
        APYdropped = false;

        return true;
    }

    // PROJECT PAY weekly/monthly PREMIUM to this address
    // this address needs to be approved first
    function billFortnightlyPremium(address _token, address _projectWallet)
        public
        onlyManagerOrSelf
        returns (bool)
    {
        uint256 currentPremiumBalance = premiumBalance;
        uint256 minimumRequiredBalance = requiredPremiumBalancePerPeriod;
        uint256 stakersDeposits = stakersDeposit;
        // check if current premium balance is less than required
        if (currentPremiumBalance < minimumRequiredBalance) {
            uint256 lastPaid = lastTimePaid;
            uint256 paymentPeriod = poolPeriod;

            // check when function was called last time and pay premium according to how much time has passed since then.
            uint256 sinceLastPaid = block.timestamp - lastPaid;

            if (sinceLastPaid > paymentPeriod) {
                // multiple by `sinceLastPaid` instead of two weeks
                uint256 fortnightlyPremiumOwed = ((
                    ((stakersDeposits * desiredAPY) / DENOMINATOR)
                ) / YEAR) * sinceLastPaid;

                if (
                    !IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        fortnightlyPremiumOwed
                    )
                ) {
                    // if transfer fails APY is reset and premium is paid with new APY
                    // register new APYperiod

                    APYperiods memory newAPYperiod;
                    newAPYperiod.timeStamp = block.timestamp;
                    newAPYperiod.periodAPY = viewcurrentAPY();
                    APYrecords.push(newAPYperiod);
                    // set new APY
                    desiredAPY = viewcurrentAPY();

                    uint256 newFortnightlyPremiumOwed = (((stakersDeposits *
                        desiredAPY) / DENOMINATOR) / YEAR) * sinceLastPaid;
                    {
                        // Calculate saloon fee
                        uint256 saloonFee = (newFortnightlyPremiumOwed *
                            PREMIUM_COMMISSION) / DENOMINATOR;

                        // update saloon claimable fee
                        saloonPremiumFees += saloonFee;

                        // update premiumBalance
                        premiumBalance += newFortnightlyPremiumOwed;

                        lastTimePaid = block.timestamp;

                        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap *
                                desiredAPY) / DENOMINATOR) / YEAR) *
                                paymentPeriod;

                        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;
                    }
                    // try transferring again...
                    IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        newFortnightlyPremiumOwed
                    );
                    // enable instant withdrawals
                    APYdropped = true;

                    return true;
                } else {
                    // Calculate saloon fee
                    uint256 saloonFee = (fortnightlyPremiumOwed *
                        PREMIUM_COMMISSION) / DENOMINATOR;

                    // update saloon claimable fee
                    saloonPremiumFees += saloonFee;

                    // update premiumBalance
                    premiumBalance += fortnightlyPremiumOwed;

                    lastTimePaid = block.timestamp;

                    // disable instant withdrawals
                    APYdropped = false;

                    return true;
                }
            } else {
                uint256 fortnightlyPremiumOwed = (((stakersDeposit *
                    desiredAPY) / DENOMINATOR) / YEAR) * paymentPeriod;

                if (
                    !IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        fortnightlyPremiumOwed
                    )
                ) {
                    // if transfer fails APY is reset and premium is paid with new APY
                    // register new APYperiod
                    APYperiods memory newAPYperiod;
                    newAPYperiod.timeStamp = block.timestamp;
                    newAPYperiod.periodAPY = viewcurrentAPY();
                    APYrecords.push(newAPYperiod);
                    // set new APY
                    desiredAPY = viewcurrentAPY();

                    uint256 newFortnightlyPremiumOwed = (((stakersDeposit *
                        desiredAPY) / DENOMINATOR) / YEAR) * paymentPeriod;
                    {
                        // Calculate saloon fee
                        uint256 saloonFee = (newFortnightlyPremiumOwed *
                            PREMIUM_COMMISSION) / DENOMINATOR;

                        // update saloon claimable fee
                        saloonPremiumFees += saloonFee;

                        // update premiumBalance
                        premiumBalance += newFortnightlyPremiumOwed;

                        lastTimePaid = block.timestamp;

                        uint256 newRequiredPremiumBalancePerPeriod = (((poolCap *
                                desiredAPY) / DENOMINATOR) / YEAR) *
                                paymentPeriod;

                        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;
                    }
                    // try transferring again...
                    IERC20(_token).safeTransferFrom(
                        _projectWallet,
                        address(this),
                        newFortnightlyPremiumOwed
                    );
                    // enable instant withdrawals
                    APYdropped = true;

                    return true;
                } else {
                    // Calculate saloon fee
                    uint256 saloonFee = (fortnightlyPremiumOwed *
                        PREMIUM_COMMISSION) / DENOMINATOR;

                    // update saloon claimable fee
                    saloonPremiumFees += saloonFee;

                    // update premiumBalance
                    premiumBalance += fortnightlyPremiumOwed;

                    lastTimePaid = block.timestamp;

                    // disable instant withdrawals
                    APYdropped = false;

                    return true;
                }
            }
        }
        return false;
    }

    // PROJECT EXCESS PREMIUM BALANCE WITHDRAWAL -- NOT SURE IF SHOULD IMPLEMENT THIS
    // timelock on this?

    function scheduleprojectDepositWithdrawal(uint256 _amount) external {
        projectWithdrawalTimeLock[_amount] = block.timestamp + poolPeriod;

        //todo emit event -> necessary to predict payout payment in the following week
        //todo OR have variable that gets updated with new values? - forgot what we discussed about this
    }

    // PROJECT DEPOSIT WITHDRAWAL
    function projectDepositWithdrawal(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external returns (bool) {
        // timelock on this.
        require(
            projectWithdrawalTimeLock[_amount] < block.timestamp &&
                projectWithdrawalTimeLock[_amount] != 0,
            "Timelock not finished or started"
        );

        projectDeposit -= _amount;
        IERC20(_token).safeTransfer(_projectWallet, _amount);
        // todo emit event
        return true;
    }

    // STAKING
    // staker needs to approve this address first
    function stake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // dont allow staking if stakerDeposit >= poolCap
        require(
            stakersDeposit + _amount <= poolCap,
            "Staking Pool already full"
        );
        uint256 arraySize = staker[_staker].length - 1;

        // Push to stakerList array if previous balance = 0
        if (staker[_staker][arraySize].stakerBalance == 0) {
            stakerList.push(_staker);
        }

        // update stakerInfo struct
        StakerInfo memory newInfo;
        newInfo.balanceTimeStamp = block.timestamp;
        newInfo.stakerBalance =
            staker[_staker][arraySize].stakerBalance +
            _amount;

        // save info to storage
        staker[_staker].push(newInfo);

        // increase global stakersDeposit
        stakersDeposit += _amount;

        // transferFrom to this address
        IERC20(_token).safeTransferFrom(_staker, address(this), _amount);

        return true;
    }

    function askForUnstake(address _staker, uint256 _amount)
        external
        onlyManager
        returns (bool)
    {
        uint256 arraySize = staker[_staker].length - 1;
        require(
            staker[_staker][arraySize].stakerBalance >= _amount,
            "Insuficcient balance"
        );

        stakerTimelock[_staker][_amount] = block.timestamp + poolPeriod;
        return true;
        //todo emit event -> necessary to predict payout payment in the following week
        //todo OR have variable that gets updated with new values? - forgot what we discussed about this
    }

    // UNSTAKING
    // allow instant withdraw if stakerDeposit >= poolCap or APY = 0%
    // otherwise have to wait for timelock period
    function unstake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // allow for immediate withdrawal if APY drops from desired APY
        // going to need to create an extra variable for storing this when apy changes for worse
        if (desiredAPY != 0 || APYdropped == true) {
            require(
                stakerTimelock[_staker][_amount] < block.timestamp &&
                    stakerTimelock[_staker][_amount] != 0,
                "Timelock not finished or started"
            );
            uint256 arraySize = staker[_staker].length - 1;

            // decrease staker balance
            // update stakerInfo struct
            StakerInfo memory newInfo;
            newInfo.balanceTimeStamp = block.timestamp;
            newInfo.stakerBalance =
                staker[_staker][arraySize].stakerBalance -
                _amount;

            address[] memory stakersList = stakerList;
            if (newInfo.stakerBalance == 0) {
                // loop through stakerlist
                uint256 length = stakersList.length; // can you do length on memory arrays?
                for (uint256 i; i < length; ) {
                    // find staker
                    if (stakersList[i] == _staker) {
                        // exchange it with last address in array
                        address lastAddress = stakersList[length - 1];
                        stakerList[length - 1] = _staker;
                        stakerList[i] = lastAddress;
                        // pop it
                        stakerList.pop();
                        break;
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
            // save info to storage
            staker[_staker].push(newInfo);

            // decrease global stakersDeposit
            stakersDeposit -= _amount;

            // transfer it out
            IERC20(_token).safeTransfer(_staker, _amount);

            return true;
        }
    }

    // claim premium
    function claimPremium(
        address _token,
        address _staker,
        address _projectWallet
    ) external onlyManager returns (uint256, bool) {
        // how many chunks of time (currently = 2 weeks) since lastclaimed?
        uint256 lastTimeClaimed = lastClaimed[_staker];
        uint256 sinceLastClaimed = block.timestamp - lastTimeClaimed;
        uint256 paymentPeriod = poolPeriod;
        StakerInfo[] memory stakerInfo = staker[_staker];
        uint256 stakerLength = stakerInfo.length;
        // if last time premium was called > 1 period

        if (sinceLastClaimed > paymentPeriod) {
            uint256 totalPremiumToClaim = calculatePremiumToClaim(
                lastTimeClaimed,
                stakerInfo,
                stakerLength
            );
            // Calculate saloon fee
            uint256 saloonFee = (totalPremiumToClaim * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            totalPremiumToClaim -= saloonFee;
            uint256 owedPremium = totalPremiumToClaim;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billFortnightlyPremium(_token, _projectWallet);
                // if function above changes APY than accounting is going to get messed up,
                // because the APY used for for new transfer will be different than APY used to calculate totalPremiumToClaim
                // if function above fails then it fails...
            }

            // update premiumBalance
            premiumBalance -= totalPremiumToClaim;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        } else {
            // calculate currently owed for the week
            uint256 owedPremium = (((stakerInfo[stakerLength - 1]
                .stakerBalance * desiredAPY) / DENOMINATOR) / YEAR) *
                poolPeriod;
            // pay current period owed

            // Calculate saloon fee
            uint256 saloonFee = (owedPremium * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            owedPremium -= saloonFee;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billFortnightlyPremium(_token, _projectWallet);
                // if function above changes APY than accounting is going to get messed up,
                // because the APY used for for new transfer will be different than APY used to calculate totalPremiumToClaim
                // if function above fails then it fails...
            }

            // update premium
            premiumBalance -= owedPremium;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        }
    }

    function calculatePremiumToClaim(
        uint256 _lastTimeClaimed,
        StakerInfo[] memory _stakerInfo,
        uint256 _stakerLength
    ) internal view returns (uint256) {
        uint256 length = APYrecords.length;
        // loop through APY periods (reversely) until last missed period is found
        uint256 lastMissed;
        uint256 totalPremiumToClaim;
        for (uint256 i = length - 1; i == 0; --i) {
            if (APYrecords[i].timeStamp < _lastTimeClaimed) {
                lastMissed = i + 1;
            }
        }
        // loop through all missed periods
        for (uint256 i = lastMissed; i < length; ++i) {
            uint256 periodStart = APYrecords[i].timeStamp;
            // period end end is equal NOW for last APY that has been set
            uint256 periodEnd = APYrecords[i + 1].timeStamp != 0
                ? APYrecords[i + 1].timeStamp
                : block.timestamp;
            uint256 periodLength = periodEnd - periodStart;
            // loop through stakers balance fluctiation during this period

            uint256 periodTotalBalance;
            for (uint256 j; j < _stakerLength; ++j) {
                // check staker balance at that moment
                if (
                    _stakerInfo[j].balanceTimeStamp > periodStart &&
                    _stakerInfo[j].balanceTimeStamp < periodEnd
                ) {
                    // add it to that period total
                    periodTotalBalance += _stakerInfo[j].stakerBalance;
                }
            }

            //calcualte owed APY for that period: (APY * amount / Seconds in a year) * number of seconds in X period
            totalPremiumToClaim +=
                (((periodTotalBalance * desiredAPY) / DENOMINATOR) / YEAR) *
                periodLength;
        }

        return totalPremiumToClaim;
    }

    ///// VIEW FUNCTIONS /////

    // View currentAPY
    function viewcurrentAPY() public view returns (uint256) {
        uint256 apy = premiumBalance / poolCap;
        return apy;
    }

    // View total balance
    function viewHackerPayout() external view returns (uint256) {
        uint256 saloonCommission = Math.mulDiv(
            bountyBalance,
            BOUNTY_COMMISSION,
            DENOMINATOR
        );
        return bountyBalance - saloonCommission;
    }

    function viewBountyBalance() external view returns (uint256) {
        return bountyBalance;
    }

    // View stakersDeposit balance
    function viewStakersDeposit() external view returns (uint256) {
        return stakersDeposit;
    }

    // View deposit balance
    function viewProjecDeposit() external view returns (uint256) {
        return projectDeposit;
    }

    // view premium balance
    function viewPremiumBalance() external view returns (uint256) {
        return premiumBalance;
    }

    // view required premium balance
    function viewRequirePremiumBalance() external view returns (uint256) {
        return requiredPremiumBalancePerPeriod;
    }

    // View APY
    function viewDesiredAPY() external view returns (uint256) {
        return desiredAPY;
    }

    // View Cap
    function viewPoolCap() external view returns (uint256) {
        return poolCap;
    }

    // View user staking balance
    function viewUserStakingBalance(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        uint256 length = staker[_staker].length;
        return (
            staker[_staker][length - 1].stakerBalance,
            staker[_staker][length - 1].balanceTimeStamp
        );
    }

    //todo view user current claimable premium ???

    //todo view version???

    ///// VIEW FUNCTIONS END /////
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/InitializableUp.sol";

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
abstract contract OwnableUpgradeable is InitializableUp, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        return true;
    }

    // THIS FUNCTION HAS BEEN EDITED TO RETURN A VALUE
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        return true;
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts/contracts/proxy/Proxy.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BountyProxy is Proxy, ERC1967Upgrade, Initializable {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    function initialize(
        address _beaconAddress,
        bytes memory _data,
        address _manager
    ) external payable initializer {
        // require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _upgradeBeaconToAndCall(_beaconAddress, _data, false);
        _changeAdmin(_manager);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual override {
        // access control
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual override {
        // access control
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _fallback();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/InitializableUp.sol";

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
abstract contract ContextUpgradeable is InitializableUp {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract InitializableUp {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}