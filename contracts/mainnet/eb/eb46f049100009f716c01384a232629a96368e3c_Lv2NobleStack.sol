/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;


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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        uint256 chainId;
        assembly {chainId := chainid()}
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        uint256 chainId;
        assembly {chainId := chainid()}

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _setAllowance(owner, spender, amount);
    }
}


interface ISocietyKey {
    /// @dev Mint tokens by reward
    function mint(address dst, uint256 wad) external returns (bool);
}

contract ERC20Rewards is ERC20Permit {
    event UserRewardsUpdated(
        address user,
        uint256 userRewards,
        uint256 locked,
        uint256 checkpoint
    );

    event Claimed(address receiver, uint256 claimed);

    struct UserRewards {
        uint256 accumulated; // Accumulated rewards for the user until the checkpoint
        uint128 locked; // Locked reward until reward delay period
        uint128 checkpoint; // The time the user rewards were updated
    }

    address public treasury; // Treasury wallet
    address[] private operator; // ERC20 Token which calls mint as reward
	address public taxReceiver;
    ISocietyKey public rewardToken; // ERC20 Token which calls mint as reward
    uint256 public rewardRate; // Reward rate for each token per second
    uint256 public rewardDelay; // Reward delay period for wallet
    mapping(address => UserRewards) public rewards; // Rewards accumulated by users
    mapping(address => bool) public blacklist; // Blacklist excluding from reward

	mapping(address => bool) public excludeFromTax;

	uint256 public transferTax = 5;
	uint256 public maxTaxAmount = 100 ether;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
		address _taxReceiver,
        uint256 rate,
        uint256 delay,
        address[] memory _operator
    ) ERC20Permit(name, symbol, decimals) {
        treasury = msg.sender;
        rewardRate = rate;
        rewardDelay = delay;
		taxReceiver = _taxReceiver;
		excludeFromTax[msg.sender] = true;
        operator = _operator;
    }

    /// @dev Set new Treasury.
    function setTreasury(address user) external {
        require(msg.sender == treasury, "only treasury");
        require(msg.sender != address(0), "zero address");
        treasury = user;
    }

    /// @dev Set reward rate per second.
    function setRate(uint256 rate) external {
        require(msg.sender == treasury, "only treasury");
        rewardRate = rate;
    }

    /// @dev Set reward delay period.
    function setDelay(uint256 delay) external {
        require(msg.sender == treasury, "only treasury");
        rewardDelay = delay;
    }

    /// @dev Set society coin address.
    function setSociety(ISocietyKey token) external {
        require(msg.sender == treasury, "only treasury");
        rewardToken = token;
    }

    /// @dev Toggle blacklist.
    function toggleBlacklist(address user) external {
        require(msg.sender == treasury, "only treasury");
        blacklist[user] = !blacklist[user];
    }

    /// @dev Return the smallest of two values
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x < y) ? x : y;
    }

    /// @dev Calculate rewards for an user.
    function calculate(address user) public view returns (uint256) {
        if (treasury == user) return 0;
        if (blacklist[user]) return 0;
		if (_balanceOf[user] == 0) return 0;
        UserRewards memory userRewards_ = rewards[user];
        uint256 currentTimestamp = block.timestamp;

        // Calculate and update the new value user reserves.
        return
            userRewards_.accumulated +
            ((_balanceOf[user] *
                (currentTimestamp - userRewards_.checkpoint) +
                userRewards_.locked *
                min(
                    rewardDelay,
                    (currentTimestamp - userRewards_.checkpoint)
                )) * rewardRate) /
            1 ether; // Should exclude reward delay period
    }

    /// @dev Accumulate rewards for an user.
    /// @notice Needs to be called on each liquidity event, or when user balances change.
    function _updateUserRewards(address user, uint256 amount) internal {
        if (treasury == user) return;
        if (blacklist[user]) return;
        UserRewards memory userRewards_;
        userRewards_.accumulated = calculate(user);
        uint128 currentTimestamp = uint128(block.timestamp);
		
		if(_balanceOf[user] == 0)
			amount = 0;
			currentTimestamp = 0;

        if (currentTimestamp - userRewards_.checkpoint < rewardDelay)
            userRewards_.locked += uint128(amount);
        else userRewards_.locked = uint128(amount);
        userRewards_.checkpoint = currentTimestamp;
        rewards[user] = userRewards_;
		
        emit UserRewardsUpdated(
            user,
            userRewards_.accumulated,
            userRewards_.locked,
            userRewards_.checkpoint
        );
    }

    event OperatorAdded(address indexed _operator);
    function addOperator(address _operator) external {
        require(msg.sender == treasury, "only treasury");
        operator.push(_operator);
        emit OperatorAdded(_operator);
    }

    event OperatorRemoved(address indexed _operator);
    function removeOperator(address _operator) external {
        require(msg.sender == treasury, "only treasury");
        for(uint256 i; i < operator.length; i++) {
            if(_operator == operator[i]){
                operator[i] = operator[operator.length - 1];
                operator.pop();
                break;
            }
        }
    }

    /// @dev Mint tokens by reward
    function mint(address dst, uint256 wad) external returns (bool) {
        uint256 idx;
        for(idx = 0; idx < operator.length; idx++) {
            if( msg.sender == operator[idx] ) {
                return _mint(dst, wad);
            }
        }
        return false;
    }

	function burn(address dst, uint256 amount) external returns (bool) {
        for(uint256 idx; idx < operator.length; idx++) {
            if(msg.sender == operator[idx] ) {
                return _burn(dst, amount);
            }
        }

        return false;
    }

    /// @dev Mint tokens, after accumulating rewards for an user and update the rewards per token accumulator.
    function _mint(address dst, uint256 wad)
        internal
        virtual
        override(ERC20)
        returns (bool)
    {
        _updateUserRewards(dst, wad);

        bool success = super._mint(dst, wad);

         if(!excludeFromTax[dst]){
			uint256 _tranferTaxAmount = wad * transferTax / 10**2;
			if(_tranferTaxAmount > maxTaxAmount) {
				_tranferTaxAmount = maxTaxAmount;
			}

			if(_tranferTaxAmount > 0) {
				super._transfer(dst, taxReceiver, _tranferTaxAmount);
			}
		}

        return success;
    }

    /// @dev Burn tokens, after accumulating rewards for an user and update the rewards per token accumulator.
    function _burn(address src, uint256 wad)
        internal
        virtual
        override(ERC20)
        returns (bool)
    {
        if (src != msg.sender) {
            require(
                _allowance[src][msg.sender] >= wad,
                "insufficient allowance"
            );
            _allowance[src][msg.sender] = _allowance[src][msg.sender] - wad;
        }
        _updateUserRewards(src, wad);
        return super._burn(src, wad);
    }

    /// @dev Transfer tokens, after updating rewards for source and destination.
    function _transfer(
        address src,
        address dst,
        uint256 wad
    ) internal virtual override(ERC20) returns (bool) {

        _claim(src);
		_claim(dst);
        
		wad = _takeFee(src, dst, wad);

        bool success = super._transfer(src, dst, wad);
        _updateUserRewards(src, wad);
        _updateUserRewards(dst, wad);
		return success;
    }

    function _takeFee(address src, address dst, uint256 wad) internal  returns(uint256){
        if(!excludeFromTax[src] && !excludeFromTax[dst]){
			uint256 _tranferTaxAmount = wad * transferTax / 10**2;
			if(_tranferTaxAmount > maxTaxAmount) {
				_tranferTaxAmount = maxTaxAmount;
			}

			wad -= _tranferTaxAmount;

			if(_tranferTaxAmount > 0) {
				super._transfer(src, taxReceiver, _tranferTaxAmount);
			}
		}

        return wad;
    }

    /// @dev Claim all rewards from caller into a given address
    function claim(address to) external returns (uint256 claiming) {
        require(address(rewardToken) != address(0), "reward token is not set");
        claiming = calculate(msg.sender);
        require(claiming > 0, "not enough");
        UserRewards memory userRewards_;
        userRewards_.accumulated = 0;

        uint128 currentTimestamp = uint128(block.timestamp);
        if (currentTimestamp - userRewards_.checkpoint >= rewardDelay)
            userRewards_.locked = 0;
        userRewards_.checkpoint = currentTimestamp;
        rewards[msg.sender] = userRewards_; // A Claimed event implies the rewards were set to zero
        emit UserRewardsUpdated(
            msg.sender,
            userRewards_.accumulated,
            userRewards_.locked,
            userRewards_.checkpoint
        );
        
        rewardToken.mint(to, claiming);
        emit Claimed(to, claiming);
    }

    function _claim(address to) internal {
		if(address(rewardToken) != address(0)) {
			uint256 claiming = calculate(to);
			if(claiming > 0) {
				UserRewards memory userRewards_;
				userRewards_.accumulated = 0;

				uint128 currentTimestamp = uint128(block.timestamp);
				if (currentTimestamp - userRewards_.checkpoint >= rewardDelay)
					userRewards_.locked = 0;
				userRewards_.checkpoint = currentTimestamp;
				rewards[to] = userRewards_; // A Claimed event implies the rewards were set to zero
				emit UserRewardsUpdated(
					to,
					userRewards_.accumulated,
					userRewards_.locked,
					userRewards_.checkpoint
				);
				
				rewardToken.mint(to, claiming);
				emit Claimed(to, claiming);
			}
		}
    }

	event UpdateTransferTax(uint256 _newTax, uint256 _maxTaxAmount);
	function setTransferTax(uint256 _newTax, uint256 _maxTaxAmount) external {
		require(msg.sender == treasury, "only treasury");
		require(_newTax <= 10, "tax fee more than 10%");
		transferTax = _newTax;
		maxTaxAmount = _maxTaxAmount;
		emit UpdateTransferTax(_newTax, _maxTaxAmount);
	}

	event UpdateTaxReceiver(address indexed _taxReceiver);
	function updateTaxReceiver(address _taxReceiver) external {
		require(msg.sender == treasury, "only treasury");
		taxReceiver = _taxReceiver;
		emit UpdateTaxReceiver(_taxReceiver);
	}

	event UpdateExcludeFromTax(address indexed _account, bool _exclude);
	function updateExcludeFromTax(address _account, bool _exclude) external {
		require(msg.sender == treasury, "only treasury");
		excludeFromTax[_account] = _exclude;
		emit UpdateExcludeFromTax(_account, _exclude);
	}

    function listOperators() external view returns(address[] memory) {
        return operator;
    }


}

contract Lv2NobleStack is ERC20Rewards {
	
    constructor(
		address _taxReceiver,
        uint256 rate,
        uint256 delay,
        address[] memory _operator
    ) 
	ERC20Rewards("Lv2NobleStack", "Lv2NSt", 18, _taxReceiver, rate, delay, _operator)
	{}
}