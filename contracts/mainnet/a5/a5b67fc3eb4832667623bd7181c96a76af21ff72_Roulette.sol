/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Roulette.sol

pragma solidity ^0.8.7;










interface DAIPermit {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

enum BetType {
    Number,
    Color,
    Even,
    Column,
    Dozen,
    Half
}

enum Color {
    Green,
    Red,
    Black
}
/**
 * @title Sakura casino roulette
 */
contract Roulette is VRFConsumerBaseV2, ERC20, Ownable {
    struct Bet {
        BetType betType;
        uint8 value;
        uint256 amount;
    }
    
    mapping (uint256 => uint256[3][]) _rollRequestsBets;
    mapping (uint256 => bool) _rollRequestsCompleted;
    mapping (uint256 => address) _rollRequestsSender;
    mapping (uint256 => uint8) _rollRequestsResults;
    mapping (uint256 => uint256) _rollRequestsTime;
    mapping (address => uint256) _chipsAccount;

    uint256 BASE_SHARES = uint256(10) ** 18;
    uint256 public current_liquidity = 0; //当前流动性  下注的真金白银
    uint256 public locked_liquidity = 0;
    uint256 public collected_fees = 0;
    address public bet_token;
    uint256 public max_bet;
    uint256 public bet_fee;
    uint256 public redeem_min_time = 2 hours;

    // Minimum required liquidity for betting 1 token
    // uint256 public minLiquidityMultiplier = 36 * 10;
    uint256 public minLiquidityMultiplier = 100;
    
    // Constant value to represent an invalid result
    uint8 public constant INVALID_RESULT = 99;

    mapping (uint8 => Color) COLORS;
    uint8[18] private RED_NUMBERS = [
        1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36
    ];

    event BetRequest(uint256 requestId, address sender);
    event BetResult(uint256 requestId, uint256 randomResult, uint256 payout);

    // Chainlink VRF Data
    bytes32 public keyHash;
    event RequestedRandomness(uint256 requestId);

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // Your subscription ID.
    uint64 public s_subscriptionId;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 5 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;


    //uint256[]  s_randomWords;

    /**
     * Contract's constructor
     * @param _bet_token address of the token used for bets and liquidity
     * @param _vrfCoordinator address of Chainlink's VRFCoordinator contract
     * @param _link address of the LINK token
     * @param _keyHash public key of Chainlink's VRF
     */
    constructor(
        address _bet_token,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    )  ERC20("ROULETTE_TOKEN", "CHIPS") VRFConsumerBaseV2(_vrfCoordinator) public {
        keyHash = _keyHash;
        bet_token = _bet_token;
        max_bet = 10**20;
        bet_fee = 0;

       
        
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        
        LINKTOKEN = LinkTokenInterface(_link);
    
        //Create a new subscription when you deploy the contract.
        createNewSubscription();

        // Set up colors
        COLORS[0] = Color.Green;
        for (uint8 i = 1; i < 37; i++) {
            COLORS[i] = Color.Black;
        }
        for (uint8 i = 0; i < RED_NUMBERS.length; i++) {
            COLORS[RED_NUMBERS[i]] = Color.Red;
        }
    }
  
    /**
     * cash In the account: ONLY FOR ERC20 TOKENS WITHOUT PERMIT FUNCTION
     * @param amount amount of account to be added
     */
    function cashIn(uint256 amount) public {
        require(amount > 0, "You didn't send any balance");

        IERC20(bet_token).transferFrom(msg.sender, address(this), amount);
        _chipsAccount[msg.sender] +=  amount;
    }



    /**
     * cash out
     * @param amount amount of account to be withdraw
     */


    function cashOut(uint256 amount) external {
        require(amount > 0, "cash out amount need > 0");
        require(_chipsAccount[msg.sender] >= amount, "Your chips account do not have enough money");

        _chipsAccount[msg.sender] -= amount;
        IERC20(bet_token).transfer(msg.sender, amount); 
    }


     /**
     * Add liquidity to the pool: ONLY FOR ERC20 TOKENS WITHOUT PERMIT FUNCTION
     * @param amount amount of liquidity to be added
     */
   
    function addLiquidity(uint256 amount) public {
        require(amount > 0, "You didn't send any balance");

        // Collect ERC-20 tokens
        IERC20(bet_token).transferFrom(msg.sender, address(this), amount);

        uint256 added_liquidity = amount;

        
        uint256 current_shares = totalSupply();

    
        if (current_shares <= 0) {
            
            current_liquidity += added_liquidity;
            
            _mint(msg.sender, BASE_SHARES * added_liquidity);
            return;
        }

        
        uint256 new_shares = (added_liquidity * current_shares) / (current_liquidity + locked_liquidity);
        
        
        current_liquidity += added_liquidity;

        
        _mint(msg.sender, new_shares);
    }



    /**
     * Remove liquidity from the pool
     */


    function removeLiquidity() external {
        require(balanceOf(msg.sender) > 0, "Your don't have liquidity");
        require(locked_liquidity <=0 , "Liquidity been locked");

        uint256 sender_shares = balanceOf(msg.sender); 
        uint256 sender_liquidity = (sender_shares * current_liquidity) / totalSupply(); 
        current_liquidity -= sender_liquidity;  
        _burn(msg.sender, sender_shares);   
        IERC20(bet_token).transfer(msg.sender, sender_liquidity); 
    }

    function setZeroLockedLiquidity() external onlyOwner {
        current_liquidity += locked_liquidity;
        locked_liquidity = 0;
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setRedeemMinTime(uint256 _redeem_min_time) external onlyOwner {
        redeem_min_time = _redeem_min_time;
    }
    
    /**
     * Roll bets
     * @param bets list of bets to be playedon
     */
    function rollBets(Bet[] memory bets) public {
        uint256 amount = 0;

        for (uint index = 0; index < bets.length; index++) {
            require(bets[index].value < 37);
            amount += bets[index].amount;
        }

        require(amount <= getMaxBet(), "Your bet exceeds the max allowed");
        require(amount + bet_fee <= _chipsAccount[msg.sender], "Your chips account do not have enough money");


        current_liquidity -= amount * 35;
        locked_liquidity += amount * 36;
        collected_fees += bet_fee;
        _chipsAccount[msg.sender] -= amount + bet_fee ;

        
        uint256 requestId = getRandomNumber();
        emit BetRequest(requestId, msg.sender);
        
        _rollRequestsSender[requestId] = msg.sender;
        _rollRequestsCompleted[requestId] = false;
        _rollRequestsTime[requestId] = block.timestamp;
        for (uint i; i < bets.length; i++) {
            _rollRequestsBets[requestId].push([uint256(bets[i].betType), uint256(bets[i].value), uint256(bets[i].amount)]);
        }
    }

    /**
     * Creates a randomness request for Chainlink VRF
     * @return requestId id of the created randomness request
     */
    function getRandomNumber() private returns (uint256 requestId) {
        //require(LINKTOKEN.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        //uint256 seed = uint256(keccak256(abi.encode(userProvidedSeed, blockhash(block.number)))); // Hash user seed and blockhash
        //bytes32 _requestId = requestRandomness(keyHash, fee, seed);
        uint256 _requestId = COORDINATOR.requestRandomWords(
                                    keyHash,
                                    s_subscriptionId,
                                    requestConfirmations,
                                    callbackGasLimit,
                                    numWords
                                    );
        emit RequestedRandomness(_requestId);
        return _requestId;
    }


     
  

    /**
     * Randomness fulfillment to be called by the VRF Coordinator once a request is resolved
     * This function makes the expected payout to the user
     * @param requestId id of the resolved request
     * @param randomWords generated random number
     */
     function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
    
        require(_rollRequestsCompleted[requestId] == false);

        

        //s_randomWords = randomWords;

        assert(randomWords.length >0);
        uint8 result = uint8(randomWords[0] % 37);
        uint256[3][] memory bets = _rollRequestsBets[requestId];
        uint256 rollLockedAmount = getRollRequestAmount(requestId) * 36;

        current_liquidity += rollLockedAmount;
        locked_liquidity -= rollLockedAmount;

        uint256 amount = 0;
        for (uint index = 0; index < bets.length; index++) {
            BetType betType = BetType(bets[index][0]);
            uint8 betValue = uint8(bets[index][1]);
            uint256 betAmount = bets[index][2];

            if (betType == BetType.Number && result == betValue) {
                amount += betAmount * 36;
                continue;
            }
            if (result == 0) {
                continue;
            }
            if (betType == BetType.Color && uint8(COLORS[result]) == betValue) {
                amount += betAmount * 2;
                continue;
            }
            if (betType == BetType.Even && result % 2 == betValue) {
                amount += betAmount * 2;
                continue;
            }
            if (betType == BetType.Column && result % 3 == betValue) {
                amount += betAmount * 3;
                continue;
            }
            if (betType == BetType.Dozen && betValue * 12 < result && result <= (betValue + 1) * 12) {
                amount += betAmount * 3;
                continue;
            }
            if (betType == BetType.Half && (betValue != 0 ? (result > 19) : (result <= 19))) {
                amount += betAmount * 2;
                continue;
            }
        }

        _rollRequestsResults[requestId] = result;
        _rollRequestsCompleted[requestId] = true;
        if (amount > 0) {
            _chipsAccount[_rollRequestsSender[requestId]] += amount ;
            current_liquidity -= amount;
        }

        emit BetResult(requestId, result, amount);
    }

    /**
     * Pays back the roll amount to the user if more than two hours passed and the random request has not been resolved yet
     * @param requestId id of random request
     */
    function redeem(uint256 requestId) external onlyOwner{
        require(_rollRequestsCompleted[requestId] == false, 'requestId already completed');
        require(block.timestamp - _rollRequestsTime[requestId] > redeem_min_time, 'Redeem time not passed');

        _rollRequestsCompleted[requestId] = true;
        _rollRequestsResults[requestId] = INVALID_RESULT;

        uint256 amount = getRollRequestAmount(requestId);

        current_liquidity += amount * 35;
        locked_liquidity -= amount * 36;
        _chipsAccount[_rollRequestsSender[requestId]] += amount ;
       
        emit BetResult(requestId, _rollRequestsResults[requestId], amount);
    }

    /**
     * Returns the roll amount of a request
     * @param requestId id of random request
     * @return amount of the roll of the request
     */
    function getRollRequestAmount(uint256 requestId) internal view returns(uint256) {
        uint256[3][] memory bets = _rollRequestsBets[requestId];
        uint256 amount = 0;

        for (uint index = 0; index < bets.length; index++) {
            uint256 betAmount = bets[index][2];
            amount += betAmount;
        }

        return amount;
    }


    /**
     * Returns a request state
     * @param requestId id of random request
     * @return indicates if request is completed
     */
    function isRequestCompleted(uint256 requestId) public view returns(bool) {
        return _rollRequestsCompleted[requestId];
    }

    /**
     * Returns the address of a request
     * @param requestId id of random request
     * @return address of the request sender
     */
    function requesterOf(uint256 requestId) public view returns(address) {
        return _rollRequestsSender[requestId];
    }

    /**
     * Returns the result of a request
     * @param requestId id of random request
     * @return numeric result of the request in range [0, 38], 99 means invalid result from a redeem
     */
    function resultOf(uint256 requestId) public view returns(uint8) {
        return _rollRequestsResults[requestId];
    }

    /**
     * Returns all the bet details in a request
     * @param requestId id of random request
     * @return a list of (betType, value, amount) tuplets from the request
     */
    function betsOf(uint256 requestId) public view returns(uint256[3][] memory) {
        return _rollRequestsBets[requestId];
    }

    /**
     * Returns the current pooled liquidity
     * @return the current liquidity
     */
    function getCurrentLiquidity() public view returns(uint256) {
        return current_liquidity;
    }

    /**
     * Returns the current bet fee
     * @return the bet fee
     */
    function getBetFee() public view returns(uint256) {
        return bet_fee;
    }

    /**
     * Returns the current maximum fee
     * @return the maximum bet
     */
    function getMaxBet() public view returns(uint256) {
        uint256 maxBetForLiquidity = current_liquidity / minLiquidityMultiplier;
        if (max_bet > maxBetForLiquidity) {
            return maxBetForLiquidity;
        }
        return max_bet;
    }

    /**
     * Returns the collected fees so far
     * @return the collected fees
     */
    function getCollectedFees() public view returns(uint256) {
        return collected_fees;
    }

    /**
     * Returns the collected fees so far
     * @param account  query account address
     * @return the chips amount
     */
    function getChipsAmount(address account) public view returns(uint256) {
        return _chipsAccount[account];
       
    }

     /**
     * Returns the collected fees so far
     * @return the chips amount
     */
    function getChipsAmount() public view returns(uint256) {
        return _chipsAccount[msg.sender];
       
    }

    
    /**
     * Sets the bet fee
     * @param _bet_fee the new bet fee
     */
    function setBetFee(uint256 _bet_fee) external onlyOwner {
        bet_fee = _bet_fee;
    }

    /**
     * Sets the maximum bet
     * @param _max_bet the new maximum bet
     */
    function setMaxBet(uint256 _max_bet) external onlyOwner {
        max_bet = _max_bet;
    }

    /**
     * Sets minimum liquidity needed for betting 1 token
     * @param _minLiquidityMultiplier the new minimum liquidity multiplier
     */
    function setMinLiquidityMultiplier(uint256 _minLiquidityMultiplier) external onlyOwner {
        minLiquidityMultiplier = _minLiquidityMultiplier;
    }

    /**
     * Withdraws the collected fees
     */
    function withdrawFees() external onlyOwner {
        uint256 _collected_fees = collected_fees;
        collected_fees = 0;
        IERC20(bet_token).transfer(owner(), _collected_fees);
    }

   
    function setCallbackGasLimit(uint32 _GasLimit) external onlyOwner {
        callbackGasLimit = _GasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    /*
    function setNumWords(uint32 _numWords) external onlyOwner {
        numWords = _numWords;
    }
    */
    
    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    /*
    function getLastRandomNum() private returns(uint256)  {
        uint256 _lastnum = s_randomWords[s_randomWords.length-1];
        s_randomWords.pop();
        return _lastnum;
    }
    */

    
}