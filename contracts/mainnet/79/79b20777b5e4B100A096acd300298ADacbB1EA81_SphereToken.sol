// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/IBalanceOfSphere.sol";
import "./interfaces/IDEXPair.sol";
import "./interfaces/ISphereToken.sol";
import "./interfaces/ISphereSettings.sol";
// import "./SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SphereToken is ERC20Upgradeable, OwnableUpgradeable, ISphereToken {
  // using SafeERC20 for IERC20;

  // *** CONSTANTS ***

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant ZERO = 0x0000000000000000000000000000000000000000;
  uint256 private constant DECIMALS = 18;
  uint256 private constant FEE_DENOMINATOR = 1000;
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5 * 10**9 * 10**DECIMALS;
  uint256 private constant MAX_INVEST_REMOVABLE_DELAY = 7200;
  uint256 private constant MAX_PARTY_LIST_DIVISOR_RATE = 75;
  uint256 private constant MAX_REBASE_FREQUENCY = 1800;
  uint256 private constant MAX_SUPPLY = type(uint128).max;
  uint256 private constant MAX_UINT256 = type(uint256).max;
  uint256 private constant MIN_BUY_AMOUNT_RATE = 500000 * 10**18;
  uint256 private constant MIN_INVEST_REMOVABLE_PER_PERIOD = 1500000 * 10**18;
  uint256 private constant MIN_SELL_AMOUNT_RATE = 500000 * 10**18;
  uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
  uint256 private constant MAX_BRACKET_TAX = 20;
  uint256 private constant MAX_PARTY_ARRAY = 491;
  uint256 private constant MAX_TAX_BRACKET_FEE_RATE = 50;

  // *** VARIABLES ***

  ISphereSettings public settings;
  bool public initialDistributionFinished; // = false;
  bool private inSwap;
  uint256 private _totalSupply;
  uint256 public gonsPerFragment;

  // **************

  address[] public makerPairs;
  address[] public partyArray;
  address[] public sphereGamesContracts;
  address[] public subContracts;
  address[] public lpContracts;

  bool public feesOnNormalTransfers; // = true;

  bool public autoRebase; // = true;

  bool public isLiquidityEnabled; // = true;
  bool public isMoveBalance; // = false;
  bool public isSellHourlyLimit; // = true;
  bool public isTaxBracket; // = false;
  bool public isWall; // = false;
  bool public partyTime; // = true;
  bool public swapEnabled; // = true;
  bool public goDeflationary; // = false;

  mapping(address => InvestorInfo) public investorInfoMap;
  mapping(address => bool) public isBuyFeeExempt;
  mapping(address => bool) public isSellFeeExempt;
  mapping(address => bool) public isTotalFeeExempt;
  mapping(address => bool) public canRebase;
  mapping(address => bool) public canSetRewardYield;
  mapping(address => bool) public _disallowedToMove;
  mapping(address => bool) public automatedMarketMakerPairs;
  mapping(address => bool) public partyArrayCheck;
  mapping(address => bool) public sphereGamesCheck;
  mapping(address => bool) public subContractCheck;
  mapping(address => bool) public lpContractCheck;
  mapping(address => uint256) public partyArrayFee;
  mapping(address => mapping(address => uint256)) private _allowedFragments;
  mapping(address => uint256) private _gonBalances;

  uint256 public rewardYieldDenominator; // = 10000000000000000;

  uint256 public investRemovalDelay; // = 3600;
  uint256 public partyListDivisor; // = 50;
  uint256 public rebaseFrequency; // = 1800;
  uint256 public rewardYield; // = 3943560072416;

  uint256 public markerPairCount; //;
  uint256 public index; //;
  uint256 public maxBuyTransactionAmount; // = 500000 * 10 ** 18;
  uint256 public maxSellTransactionAmount; // = 500000 * 10 ** 18;
  uint256 public nextRebase; // = 1647385200;
  uint256 public rebaseEpoch; // = 0;
  uint256 public taxBracketMultiplier; // = 50;
  uint256 public wallDivisor; // = 2;

  address public liquidityReceiver; // = 0x1a2Ce410A034424B784D4b228f167A061B94CFf4;
  address public treasuryReceiver; // = 0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;
  address public riskFreeValueReceiver; // = 0x826b8d2d523E7af40888754E3De64348C00B99f4;
  address public galaxyBondReceiver; // = 0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;

  address public sphereSwapper;

  uint256 public maxInvestRemovablePerPeriod; // = 1500000 * 10 ** 18;

  // New vars for 2.1

  bool public isGameDepositLimited; // = false
  uint256 public gameDepositDelay; // = 7 days
  uint256 public gameDepositMaxShare;
  address public sphereGamePool;

  address private constant ONE = 0x0000000000000000000000000000000000000001;

  // **************

  mapping(address => bool) public hackerDeadLock;
  address public multisig;
  mapping(address => bool) public isTransferFeeExempt;
  address private constant TWO = 0x0000000000000000000000000000000000000002;
  uint256 previousTreasuryBalance;

  // constructor() ERC20Detailed('Sphere Finance', 'SPHERE', uint8(DECIMALS)) {}

  // *** RESTRICTIONS ***

  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  modifier validRecipient(address to) {
    require(to != address(0x0), "recipient is not valid");
    _;
  }

  function init() public initializer {
    __Ownable_init();
    __ERC20_init("Sphere Finance", "SPHERE");

    feesOnNormalTransfers = true;
    autoRebase = true;
    isLiquidityEnabled = true;
    isMoveBalance = false;
    isSellHourlyLimit = true;
    isTaxBracket = false;
    isWall = false;
    partyTime = true;
    swapEnabled = true;
    goDeflationary = false;
    rewardYieldDenominator = 10000000000000000;
    investRemovalDelay = 3600;
    partyListDivisor = 50;
    rebaseFrequency = 1800;
    rewardYield = 3943560072416;
    maxBuyTransactionAmount = 500000 * 10**18;
    maxSellTransactionAmount = 500000 * 10**18;
    nextRebase = 1647385200;
    rebaseEpoch = 0;
    taxBracketMultiplier = 50;
    wallDivisor = 2;
    liquidityReceiver = 0x1a2Ce410A034424B784D4b228f167A061B94CFf4;
    treasuryReceiver = 0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;
    riskFreeValueReceiver = 0x826b8d2d523E7af40888754E3De64348C00B99f4;
    galaxyBondReceiver = 0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;
    maxInvestRemovablePerPeriod = 1500000 * 10**18;

    _allowedFragments[address(this)][address(this)] = type(uint256).max;

    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonBalances[msg.sender] = TOTAL_GONS;
    gonsPerFragment = TOTAL_GONS / (_totalSupply);

    isTotalFeeExempt[treasuryReceiver] = true;
    isTotalFeeExempt[sphereSwapper] = true;
    isTotalFeeExempt[address(this)] = true;
    isTotalFeeExempt[msg.sender] = true;
    index = 1e18 * gonsPerFragment;
    initialDistributionFinished = true;

    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  //***********************************************************
  //******************** ERC20 ********************************
  //***********************************************************

  /**
   * @notice  gets every token in circulation no matter where
   * @dev     Simsala
   * @return  uint256  total supply of assets
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @notice  how much a user is allowed to transfer from own address to another one
   * @dev     Simsala
   * @param   owner_  Address of the account to be checked on
   * @param   spender  Contract allowed to spend funds on behalf of user
   * @return  uint256  amount allowed to be spent
   */
  function allowance(address owner_, address spender) public view override returns (uint256) {
    return _allowedFragments[owner_][spender];
  }

  /**
   * @notice  returns the balance of the user
   * @dev     Simsala
   * @param   who  Address to be checked
   * @return  uint256  balance of user
   */
  function balanceOf(address who) public view override returns (uint256) {
    if (gonsPerFragment == 0) {
      return 0;
    }
    return _gonBalances[who] / (gonsPerFragment);
  }

  //transfer from one valid to another
  /**
   * @notice  Transfer function to send from one address to another
   * @dev     Simsala
   * @param   to  Receiver of funds
   * @param   value  Amount to be sent
   * @return  bool  If transfer was successful
   */
  function transfer(address to, uint256 value) public override validRecipient(to) returns (bool) {
    _transferFrom(msg.sender, to, value);
    return true;
  }

  /**
   * @notice  Basic transfer from one wallet to the other
   * @dev     Simsala
   * @param   from  From which address to send funds to
   * @param   to  Which address to receive assets
   * @param   amount  Amount of assets
   * @return  bool  If successful
   */
  function _basicTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    uint256 gonAmount = amount * (gonsPerFragment);
    _gonBalances[from] = _gonBalances[from] - (gonAmount);
    _gonBalances[to] = _gonBalances[to] + (gonAmount);

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @notice  Transfer function that accounts for taxes and other checks like
   *          sell per hour, party array check
   * @dev     Simsala
   * @param   sender  From which address to send funds to
   * @param   recipient  Which address to receive assets
   * @param   amount  Amount of assets
   * @return  bool  If successful
   */
  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    bool excludedAccount = isTotalFeeExempt[sender] || isTotalFeeExempt[recipient];

    require(initialDistributionFinished || excludedAccount, "Trade off");

    if (automatedMarketMakerPairs[recipient] && !excludedAccount) {
      require(amount <= maxSellTransactionAmount, "Too much sell");
    }

    if (hackerDeadLock[sender]) {
      recipient = address(DEAD);
      emit HackerDeadLock(sender, amount);
    }

    if (automatedMarketMakerPairs[recipient] && !excludedAccount && partyArrayCheck[sender] && partyTime) {
      require(amount <= (maxSellTransactionAmount / (partyListDivisor)), "party div");
    }

    if (automatedMarketMakerPairs[sender] && !excludedAccount) {
      require(amount <= maxBuyTransactionAmount, "too much buy");
    }

    if (automatedMarketMakerPairs[recipient] && !excludedAccount && isSellHourlyLimit) {
      InvestorInfo storage investor = investorInfoMap[sender];
      //Make sure they can't withdraw too often.
      Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
      uint256 authorizedWithdraw = (maxInvestRemovablePerPeriod - (getLastPeriodWithdrawals(sender)));
      require(amount <= authorizedWithdraw, "max withdraw");
      withdrawHistory.push(Withdrawal({timestamp: block.timestamp, withdrawAmount: amount}));
    }

    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }

    uint256 gonAmount = amount * (gonsPerFragment);

    uint256 gonAmountReceived = _shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, gonAmount) : gonAmount;

    _gonBalances[sender] = _gonBalances[sender] - gonAmount;
    _gonBalances[recipient] = _gonBalances[recipient] + (gonAmountReceived);

    emit Transfer(sender, recipient, gonAmountReceived / (gonsPerFragment));

    return true;
  }

  /**
   * @notice  Internal function to override the transfer function
   * @dev     Simsala
   * @param   from Which address sends the funds
   * @param   to  Which address to receive funds
   * @param   value  amount of funds to be transferred
   * @return  bool  If successful
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public override validRecipient(to) returns (bool) {
    if (_allowedFragments[from][msg.sender] != type(uint256).max) {
      _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - (value);
    }

    _transferFrom(from, to, value);
    return true;
  }

  /**
   * @notice  Decreases allownace of assets
   * @dev     Simsala
   * @param   spender  Address of which account should be decreased
   * @param   subtractedValue  how much to be subtracted
   * @return  bool  If successful
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedFragments[msg.sender][spender] = 0;
    } else {
      _allowedFragments[msg.sender][spender] = oldValue - (subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /**
   * @notice  Decreases allownace of assets
   * @dev     Simsala
   * @param   spender  Address of which account should be increased
   * @param   addedValue  how much to be added
   * @return  bool  If successful
   */
  function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
    _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + (addedValue);
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /**
   * @notice  Approval of funds to be used by another contract
   * @dev     Simsala
   * @param   spender  Address that is getting approved to use assets
   * @param   value  Amount to be approved
   * @return  bool  If successful
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    _allowedFragments[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @notice  Checks if address is taxable (gets alled in transferFrom)
   * @dev     Simsala
   * @param   from  Address which does the the transaction
   * @param   to  Address that is on the receiving end of transaction
   * @return  bool  .
   */
  function _shouldTakeFee(address from, address to) internal view returns (bool) {
    if (isTotalFeeExempt[from] || isTotalFeeExempt[to]) {
      return false;
    } else if (feesOnNormalTransfers) {
      return true;
    } else {
      return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
    }
  }

  /**
   * @notice  this function iterates through all other contracts that are being part of the Sphere ecosystem
   * @dev     Gets balance of all contracts that SPHERE is inside
   * @param   sender  Address to be checked
   * @return  userTotal
   */
  function getBalanceContracts(address sender) public view returns (uint256 userTotal) {
    for (uint256 i = 0; i < subContracts.length; i++) {
      userTotal += (IBalanceOfSphere(subContracts[i]).balanceOfSphere(sender));
    }
    for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
      userTotal += (IERC20(sphereGamesContracts[i]).balanceOf(sender));
    }
  }

  /**
   * @notice  Calculate circulating supply (removing all addresses that are not accounted for circulating)
   * @dev     Takes all gons and removes circulating supply
   * @return  uint256  Returns the circulating supply
   */
  function getCirculatingSupply() external view returns (uint256) {
    return
      (TOTAL_GONS -
        _gonBalances[DEAD] -
        _gonBalances[ZERO] -
        _gonBalances[ONE] -
        _gonBalances[treasuryReceiver] -
        _gonBalances[TWO] -
        previousTreasuryBalance) / gonsPerFragment;
  }

  /**
   * @notice  Gets the current bracket of user
   * @dev     Simsala
   * @param   _address  Address to get bracket of
   * @return  _bracket  Returns bracket tier
   */
  function getCurrentTaxBracket(address _address) public view returns (uint256 _bracket) {
    //gets the total balance of the user
    uint256 userTotal = getUserTotalOnDifferentContractsSphere(_address);

    //calculate the percentage
    uint256 totalCap = (userTotal * (100)) / (getTokensInLPCirculation());

    //calculate what is smaller, and use that
    _bracket = totalCap < MAX_BRACKET_TAX ? totalCap : MAX_BRACKET_TAX;

    //multiply the bracket with the multiplier
    _bracket *= taxBracketMultiplier;
  }

  /**
   * @notice  Calculate how much SPHERE is in LPs
   * @dev     Simsala
   * @return  lpTotal  Amount of tokens in LPs
   */
  function getTokensInLPCirculation() public view returns (uint256 lpTotal) {
    for (uint256 i = 0; i < lpContracts.length; i++) {
      lpTotal += balanceOf(lpContracts[i]);
    }
  }

  /**
   * @notice  Calculates the balance of user in different contracts
   * @dev     Simsala
   * @param   sender  Adderss to be checked
   * @return  userTotal Amount of total returned
   */
  function getUserTotalOnDifferentContractsSphere(address sender) public view returns (uint256 userTotal) {
    userTotal = balanceOf(sender) + getBalanceContracts(sender);
  }

  /** @dev Returns the total amount withdrawn by the _address during the last hour **/

  /**
   * @notice  Gets array to calculate how much has been sold within period
   * @dev     Simsala
   * @param   _address  Address of withdrawer
   * @return  totalWithdrawLastHour  How much has been withdrawn in the last period
   */
  function getLastPeriodWithdrawals(address _address) public view returns (uint256 totalWithdrawLastHour) {
    InvestorInfo storage investor = investorInfoMap[_address];

    Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
    for (uint256 i = 0; i < withdrawHistory.length; i++) {
      Withdrawal memory withdraw = withdrawHistory[i];
      if (withdraw.timestamp >= (block.timestamp - (investRemovalDelay))) {
        totalWithdrawLastHour = totalWithdrawLastHour + (withdrawHistory[i].withdrawAmount);
      }
    }
  }

  /**
   * @notice  Calculates the fee amount to be taken for the contract
   * @dev     Simsala
   * @param   sender  Address that sends
   * @param   recipient  Address that receives
   * @param   gonAmount  Gon amount to be transferred
   * @return  uint256  amount of gon left over after fees
   */
  function takeFee(
    address sender,
    address recipient,
    uint256 gonAmount
  ) internal returns (uint256) {
    uint256 _realFee;

    // Buy order
    if (automatedMarketMakerPairs[sender]) {
      ISphereSettings.BuyFees memory buyFees = settings.currentBuyFees();
      _realFee = isBuyFeeExempt[sender] ? 0 : buyFees.totalFees;

      // Sell order
    } else if (automatedMarketMakerPairs[recipient]) {
      ISphereSettings.SellFees memory sellFees = settings.currentSellFees();
      _realFee = isSellFeeExempt[sender] ? 0 : sellFees.totalFees;

      if (partyArrayCheck[sender] && partyTime && !isSellFeeExempt[sender]) {
        if (_realFee < partyArrayFee[sender]) _realFee = partyArrayFee[sender];
      }

      // Transfer order
    } else {
      ISphereSettings.TransferFees memory fees = settings.currentTransferFees();
      _realFee = isTransferFeeExempt[sender] ? 0 : fees.totalFees;
    }

    // Tax bracket on sell & transfer
    if (!automatedMarketMakerPairs[sender]) {
      //calculate Tax
      if (isTaxBracket) {
        _realFee += getCurrentTaxBracket(sender);
      }
    }

    uint256 feeGonAmount = (gonAmount * (_realFee)) / (FEE_DENOMINATOR);
    uint256 feeAmount = feeGonAmount / gonsPerFragment;

    // NOTE: take a share of all buy / sell fees for sphere game prize pool
    uint256 feeSphereGamePoolGonAmount = 0;
    uint256 feeSphereGamePoolAmount = 0;

    if (sphereGamePool != address(0)) {
      ISphereSettings.GameFees memory gameFees = settings.currentGameFees();
      feeSphereGamePoolGonAmount = (feeGonAmount * gameFees.depositLimit) / FEE_DENOMINATOR;
      feeSphereGamePoolAmount = feeSphereGamePoolGonAmount / gonsPerFragment;

      _gonBalances[sphereGamePool] += feeSphereGamePoolGonAmount;
      emit Transfer(sender, sphereGamePool, feeSphereGamePoolAmount);

      feeGonAmount -= feeSphereGamePoolGonAmount;
      feeAmount = feeGonAmount / gonsPerFragment;
    }

    if (sphereSwapper != address(0x0)) {
      _gonBalances[sphereSwapper] += feeGonAmount;
      emit Transfer(sender, sphereSwapper, feeAmount);
    } else {
      _gonBalances[address(this)] = _gonBalances[address(this)] + (feeGonAmount);
      emit Transfer(sender, address(this), feeAmount);
    }

    return gonAmount - (feeGonAmount + feeSphereGamePoolGonAmount);
  }

  /**
   * @notice  Settings Contract (for fees, etc)
   * @dev     belbix
   * @param   _settings  new contract address to read settins from
   */
  function setSphereSettings(address _settings) external onlyOwner {
    require(_settings != address(0x0), "Zero settings");
    settings = ISphereSettings(_settings);
  }

  /**
   * @notice  Function to allow one-time full transfer of assets to another wallet
   *          If flagged, goes to dead wallet
   * @dev     ekinox
   * @param   _to  Address to receive 100% of assets
   * @return  bool  if successful
   */
  function moveBalance(address _to) external validRecipient(_to) returns (bool) {
    require(isMoveBalance, "can not move");
    require(initialDistributionFinished, "Trade off");
    // Allow to move balance only once
    require(!_disallowedToMove[msg.sender], "not allowed");
    require(balanceOf(msg.sender) > 0, "No tokens");
    uint256 balanceOfAllSubContracts = 0;

    balanceOfAllSubContracts = getBalanceContracts(msg.sender);
    require(balanceOfAllSubContracts == 0, "other balances");

    if (hackerDeadLock[msg.sender]) {
      _to = address(DEAD);
    }

    // Once an address received funds moved from another address it should
    // not be able to move its balance again
    _disallowedToMove[msg.sender] = true;
    uint256 gonAmount = _gonBalances[msg.sender];

    // reduce balance early
    _gonBalances[msg.sender] = _gonBalances[msg.sender] - (gonAmount);

    // Move the balance to the to address
    _gonBalances[_to] = _gonBalances[_to] + (gonAmount);

    emit Transfer(msg.sender, _to, (gonAmount / (gonsPerFragment)));
    emit MoveBalance(msg.sender, _to);
    return true;
  }

  /**
   * @notice  add new subcontracts to the protocol so they can be calculated
   * @dev     Simsala
   * @param   _subContract  Address of sub contract
   * @param   _value  State of address
   */
  function addSubContracts(address _subContract, bool _value) external onlyOwner {
    require(subContractCheck[_subContract] != _value, "Value already set");

    subContractCheck[_subContract] = _value;

    if (_value) {
      subContracts.push(_subContract);
    } else {
      for (uint256 i = 0; i < subContracts.length; i++) {
        if (subContracts[i] == _subContract) {
          subContracts[i] = subContracts[subContracts.length - 1];
          subContracts.pop();
          break;
        }
      }
    }

    emit SetSubContracts(_subContract, _value);
  }

  //add new lpContracts to the protocol so they can be calculated
  /**
   * @notice  Add LP addresses to account for in dynamic tax
   * @dev     Simsala
   * @param   _lpContract  Address to add/remove from list
   * @param   _value  if true, gets accounted for in computation
   */
  function addLPAddressesForDynamicTax(address _lpContract, bool _value) external onlyOwner {
    require(lpContractCheck[_lpContract] != _value, "Value already set");

    lpContractCheck[_lpContract] = _value;

    if (_value) {
      lpContracts.push(_lpContract);
    } else {
      for (uint256 i = 0; i < lpContracts.length; i++) {
        if (lpContracts[i] == _lpContract) {
          lpContracts[i] = lpContracts[lpContracts.length - 1];
          lpContracts.pop();
          break;
        }
      }
    }

    emit SetLPContracts(_lpContract, _value);
  }

  /**
   * @notice  Add S.P.H.E.R.E. Games Contracts
   * @dev     Simsala
   * @param   _sphereGamesAddy  Address to be added
   * @param   _value  Boolean to set state
   */
  function addSphereGamesAddies(address _sphereGamesAddy, bool _value) external onlyOwner {
    require(sphereGamesCheck[_sphereGamesAddy] != _value, "Value already set");

    sphereGamesCheck[_sphereGamesAddy] = _value;

    if (_value) {
      sphereGamesContracts.push(_sphereGamesAddy);
    } else {
      for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
        if (sphereGamesContracts[i] == _sphereGamesAddy) {
          sphereGamesContracts[i] = sphereGamesContracts[sphereGamesContracts.length - 1];
          sphereGamesContracts.pop();
          break;
        }
      }
    }

    emit SetSphereGamesAddresses(_sphereGamesAddy, _value);
  }

  /**
   * @notice  Special function to add certain wallets to special fee bracket
   * @dev     Simsala
   * @param   _partyAddy  Address to be set that is malicious
   * @param   _value  If true, wallet gets special fee structure
   * @param   feeAmount  Amount of fee structure
   */
  function addPartyAddies(
    address _partyAddy,
    bool _value,
    uint256 feeAmount
  ) external onlyOwner {
    partyArrayCheck[_partyAddy] = _value;
    require(feeAmount < MAX_PARTY_ARRAY, "max party fees");
    partyArrayFee[_partyAddy] = feeAmount;

    if (_value) {
      partyArray.push(_partyAddy);
    } else {
      for (uint256 i = 0; i < partyArray.length; i++) {
        if (partyArray[i] == _partyAddy) {
          partyArray[i] = partyArray[partyArray.length - 1];
          partyArray.pop();
          break;
        }
      }
    }

    emit SetPartyAddresses(_partyAddy, _value);
  }

  /**
   * @notice  Add LP tokens to set fees accordingly
   * @dev     Simsala
   * @param   _pair  Address of LP
   * @param   _value  if true, sets fees, if false, adjusts back
   */
  function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
    require(automatedMarketMakerPairs[_pair] != _value, "already set");

    automatedMarketMakerPairs[_pair] = _value;

    if (_value) {
      makerPairs.push(_pair);
      markerPairCount++;
    } else {
      for (uint256 i = 0; i < makerPairs.length; i++) {
        if (makerPairs[i] == _pair) {
          makerPairs[i] = makerPairs[makerPairs.length - 1];
          makerPairs.pop();
          markerPairCount--;
          break;
        }
      }
    }

    emit SetAutomatedMarketMakerPair(_pair, _value);
  }

  /**
   * @notice  Enable the move balance feature, allows tax-free transfer of 100% of assets
   * @dev     Simsala
   * @param   _value  boolean to allow or not
   */
  function setMoveBalance(bool _value) external onlyOwner {
    isMoveBalance = _value;

    emit SetMoveBalance(_value);
  }

  /**
   * @notice  Enable tax exemption for certain transfer types
   * @dev     Simsala
   * @param   _addr  Address to be exempt
   * @param   _value  either whitelist/blacklist
   * @param   _type  which type to exempt
   */
  function setFeeTypeExempt(
    address _addr,
    bool _value,
    uint256 _type
  ) external onlyOwner {
    if (_type == 1) {
      require(isTotalFeeExempt[_addr] != _value, "Not changed");
      isTotalFeeExempt[_addr] = _value;
      emit SetTotalFeeExempt(_addr, _value);
    }
    if (_type == 2) {
      require(isBuyFeeExempt[_addr] != _value, "Not changed");
      isBuyFeeExempt[_addr] = _value;
      emit SetBuyFeeExempt(_addr, _value);
    }
    if (_type == 3) {
      require(isSellFeeExempt[_addr] != _value, "Not changed");
      isSellFeeExempt[_addr] = _value;
      emit SetSellFeeExempt(_addr, _value);
    }
    if (_type == 4) {
      require(isTransferFeeExempt[_addr] != _value, "Not changed");
      isTransferFeeExempt[_addr] = _value;
      emit SetTransferFeeExempt(_addr, _value);
    }
  }

  /**
   * @notice  Multiplier for how to set the tax bracket
   * @dev     Simsala
   * @param   _taxBracketFeeMultiplier  amount to be multiplied with
   * @param   _isTaxBracketEnabled  value to set the tax bracket
   */
  function setTaxBracketFeeMultiplier(uint256 _taxBracketFeeMultiplier, bool _isTaxBracketEnabled) external onlyOwner {
    require(_taxBracketFeeMultiplier <= MAX_TAX_BRACKET_FEE_RATE, "max bracket fee exceeded");
    taxBracketMultiplier = _taxBracketFeeMultiplier;
    isTaxBracket = _isTaxBracketEnabled;
    emit SetTaxBracketFeeMultiplier(_taxBracketFeeMultiplier, _isTaxBracketEnabled, block.timestamp);
  }

  /**
   * @notice  Recovers Native asset to owner
   * @dev     Simsala
   * @param   _receiver  address that receives native assets
   */
  function clearStuckBalance(address _receiver) external onlyOwner {
    uint256 balance = address(this).balance;
    payable(_receiver).transfer(balance);
    emit ClearStuckBalance(balance, _receiver, block.timestamp);
  }

  /**
   * @notice  returns assets of balance to owner (in case of wrongly sent funds)
   * @dev     Simsala
   * @param   tokenAddress  address of ERC-20 to be refunded
   */
  function rescueToken(address tokenAddress) external onlyOwner {
    uint256 tokens = IERC20(tokenAddress).balanceOf(address(this));
    emit RescueToken(tokenAddress, msg.sender, tokens, block.timestamp);
    IERC20(tokenAddress).transfer(msg.sender, tokens);
  }

  /**
   * @notice  enable fees on normal transfer
   * @dev     Simsala
   * @param   _enabled  bool to set fees on transfers or not
   */
  function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
    feesOnNormalTransfers = _enabled;
  }

  /**
   * @notice  Amount to set for max buys & sells per period
   * @dev     Simsala
   * @param   _maxSellTxn  amount of max sells
   * @param   _maxBuyTxn  amount of max buys
   */
  function setMaxTransactionAmount(uint256 _maxSellTxn, uint256 _maxBuyTxn) external onlyOwner {
    require(_maxSellTxn > MIN_SELL_AMOUNT_RATE, "Below minimum sell amount");
    require(_maxBuyTxn > MIN_BUY_AMOUNT_RATE, "Below minimum buy amount");
    maxSellTransactionAmount = _maxSellTxn;
    maxBuyTransactionAmount = _maxBuyTxn;
    emit SetMaxTransactionAmount(_maxSellTxn, _maxBuyTxn, block.timestamp);
  }

  /**
   * @notice  Add an address from the wallet that scams so tokens go to dead wallet
   * @dev     ekinox
   * @param   _hackerAddress  Address of the scammer to be added
   * @param   value  if true, user gets to deadlock
   */
  function setHackerToDeadLock(address _hackerAddress, bool value) external onlyMultisig {
    if (value) {
      require(hackerDeadLock[_hackerAddress] != true, "Dead lock already set");
    } else {
      require(hackerDeadLock[_hackerAddress], "Dead lock not set");
    }

    hackerDeadLock[_hackerAddress] = value;
    emit SetHackerToDeadLock(_hackerAddress, value);
  }

  /**
   * @notice  Add multisig address
   * @dev     ekinox
   * @param   _multisig  multisig address
   */
  function setMultiSig(address _multisig) external onlyOwnerOnceThenMultisig {
    require(_multisig != address(0), "Zero address detected");
    multisig = _multisig;
  }

  /**
   * @notice  Overwrite the balance of multisig and eradicate balances (unmint)
   * @dev     Simsala
   */
  function setMultiSigTokensToZero() external onlyOwner {
    _totalSupply -= (_gonBalances[treasuryReceiver] / gonsPerFragment);
    previousTreasuryBalance += _gonBalances[treasuryReceiver];
    _gonBalances[treasuryReceiver] = 0;
  }

  /**
   * @notice  Modifier to allow function to only be called by owner once and then only by the multisig
   * @dev     ekinox
   */
  modifier onlyOwnerOnceThenMultisig() {
    if (multisig == address(0)) {
      require(msg.sender == owner(), "Owner restricted first time");
    } else {
      require(msg.sender == multisig, "Not authorized");
    }

    _;
  }

  /**
   * @notice  Allow only multisig to execute function
   * @dev     ekinox
   */
  modifier onlyMultisig() {
    require(msg.sender == multisig, "Not authorized");
    _;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBalanceOfSphere {
  function balanceOfSphere(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDEXPair {
  function sync() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISphereToken {
  // *** STRUCTS ***

  struct Withdrawal {
    uint256 timestamp;
    uint256 withdrawAmount;
  }

  struct GameDeposit {
    uint256 timestamp;
    uint256 depositAmount;
  }

  struct InvestorInfo {
    uint256 totalInvestableExchanged;
    Withdrawal[] withdrawHistory;
    GameDeposit[] gameDepositHistory;
  }

  // *** EVENTS ***

  event SetPartyTime(bool indexed state, uint256 indexed time);

  event SetTaxBracketFeeMultiplier(uint256 indexed state, bool indexed _isTaxBracketEnabled, uint256 indexed time);

  event ClearStuckBalance(uint256 indexed amount, address indexed receiver, uint256 indexed time);

  event RescueToken(address indexed tokenAddress, address indexed sender, uint256 indexed tokens, uint256 time);

  event SetAutoRebase(bool indexed value, uint256 indexed time);

  event SetGoDeflationary(bool indexed value, uint256 indexed time);

  event SetRebaseFrequency(uint256 indexed frequency, uint256 indexed time);

  event SetRewardYield(uint256 indexed rewardYield, uint256 indexed frequency, uint256 indexed time, address setter);

  event SetNextRebase(uint256 indexed value, uint256 indexed time);

  event SetMaxTransactionAmount(uint256 indexed sell, uint256 indexed buy, uint256 indexed time);

  event SetWallDivisor(uint256 indexed _wallDivisor, bool indexed _isWall);

  event SetSwapBackSettings(bool indexed enabled, uint256 indexed num, uint256 indexed denum);

  event LogRebase(uint256 indexed epoch, uint256 totalSupply);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  event SetInitialDistribution(bool indexed value);
  event SetInvestRemovalDelay(uint256 indexed value);
  event SetMaxInvestRemovablePerPeriod(uint256 indexed value);
  event SetMoveBalance(bool indexed value);
  event SetIsLiquidityEnabled(bool indexed value);
  event SetPartyListDivisor(uint256 indexed value);
  event SetHourlyLimit(bool indexed value);
  event SetContractToChange(address indexed value);
  event SetTotalFeeExempt(address indexed addy, bool indexed value);
  event SetBuyFeeExempt(address indexed addy, bool indexed value);
  event SetSellFeeExempt(address indexed addy, bool indexed value);
  event SetTransferFeeExempt(address indexed addy, bool indexed value);
  event SetRebaseWhitelist(address indexed addy, bool indexed value, uint256 indexed _type);
  event SetSubContracts(address indexed pair, bool indexed value);
  event SetLPContracts(address indexed pair, bool indexed value);
  event SetPartyAddresses(address indexed pair, bool indexed value);
  event SetSphereGamesAddresses(address indexed pair, bool indexed value);
  event GenericErrorEvent(string reason);
  event SetRouter(address indexed _address);
  event MoveBalance(address from, address to);

  event SetGameDepositLimit(bool indexed value);
  event SetGameDepositDelay(uint256 indexed value);
  event SetGameDepositWalletShare(uint256 indexed value);

  /* ======== POLICY FUNCTIONS ======== */

  enum TaxParameter {
    NULL,
    TOTAL,
    BUY,
    SELL,
    TRANSFER
  }

  event SetHackerToDeadLock(address indexed hackerAddress, bool indexed value);
  event HackerDeadLock(address indexed hackerAddress, uint256 indexed value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISphereSettings {
  struct BuyFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct SellFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct TransferFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct Fees {
    uint burnFee;
    uint galaxyBondFee;
    uint realFeePartyArray;
    bool isTaxBracketEnabledInMoveFee;
  }

  struct GameFees {
    uint stakeFee;
    uint depositLimit;
  }

  function currentBuyFees() external view returns (BuyFees memory);
  function currentSellFees() external view returns (SellFees memory);
  function currentTransferFees() external view returns (TransferFees memory);
  function currentGameFees() external view returns (GameFees memory);
  function currentFees() external view returns (Fees memory);
  function allCurrentFees() external view returns (
    BuyFees memory,
    SellFees memory,
    GameFees memory,
    Fees memory
  );

  event SetBuyFees(BuyFees fees);
  event SetSellFees(SellFees fees);
  event SetTransferFees(TransferFees fees);
  event SetGameFees(GameFees fees);
  event SetFees(Fees fees);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}