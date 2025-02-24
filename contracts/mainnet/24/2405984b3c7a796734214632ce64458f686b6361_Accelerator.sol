// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IVentureCapital.sol';
import '../interfaces/IStakeMinter.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IRandom.sol';
import '../interfaces/IAcceleratorNFT.sol';
import '../abstracts/Manageable.sol';
import '../interfaces/IAxionNFTUtility.sol';

/** Launch
    Roles Needed -
    Staking Contract: External Staker Role
    Token Contract: Burner (AKA Minter)
 */

contract Accelerator is Initializable, Manageable {
    using SafeERC20 for IERC20;

    event AcceleratorToken(
        address indexed from,
        address indexed tokenIn,
        uint256 indexed currentDay,
        address token,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    event AcceleratorEth(
        address indexed from,
        address indexed token,
        uint256 indexed currentDay,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    event SetAllowedToken(address account, address token, bool allowed);
    event SetPaused(address account, bool paused);
    event SetColliding(address account, bool colliding);
    event SetRecipient(address account, address recipient);
    event SetToken(address account, address newToken);
    event SetSplitAmounts(address account, uint8[3] splitAmounts);
    event SetMinStakeDays(address account, uint256 value);
    event SetMaxBoughtPerDay(address account, uint256 value);
    event SetBaseBonus(address account, uint256 value);
    event SetBonusStartPercent(address account, uint256 value);
    event SetBonusStartDays(address account, uint256 value);
    /** Additional Roles */
    bytes32 public constant GIVE_AWAY_ROLE = keccak256('GIVE_AWAY_ROLE');

    /** Public */
    address public staking; // Staking Address
    address public axion; // Axion Address
    address public ventureCapital; // Axion Address
    address public token; // Token to buy other then aixon
    address payable public uniswap; // Uniswap Adress
    address payable public recipient; // Recipient Address
    uint256 public minStakeDays; // Minimum length of stake from contract
    uint256 public start; // Start of Contract in seconds
    uint256 public secondsInDay; // 86400
    uint256 public maxBoughtPerDay; // Amount bought before bonus is removed
    mapping(uint256 => uint256) public bought; // Total bought for the day
    uint16 bonusStartDays; // # of days to stake before bonus starts
    uint8 bonusStartPercent; // Start percent of bonus 5 - 20, 10 - 25 etc.
    uint8 baseBonus; // (Deprecated for Utility NFT's) Base bonus unrequired by baseStartDays
    uint8[3] public splitAmounts; // 0 axion, 1 btc, 2 recipient
    mapping(address => bool) public allowedTokens; // Tokens allowed to be used for stakeWithToken
    //** Private */
    bool private _paused; // Contract paused

    /** Upgradeable Variables */
    address public stakeManager; // Axion Address
    address public WETH;

    //** Accelerator NFT vars */
    bool colliding;
    IAcceleratorNFT acceleratorNFT;
    IRandom randomGenerator;
    IAxionNFTUtility nftFactory;

    address otcPool;

    uint256 public mintedAmount;
    uint256 public maxMint;
    // -------------------- Modifiers ------------------------

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), 'AUTOSTAKER: paused');
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    // -------------------- Functions ------------------------

    /** @dev stake with token
        Description: Sell a token buy axion and then stake it for # of days
        @param _amountOut {uint256}
        @param _amountTokenOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStakeEth(
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    )
        external
        payable
        notContract
        whenNotPaused
        returns (uint256 axionBought, uint256 tokenBought)
    {
        require(false, 'Function is not turned on');
        require(
            false,
            'AUTOSTAKER: Buy and stake eth is currently turned off until further notice.'
        );
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        uint256 currentDay = getCurrentDay();
        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(msg.value);

        //** Swap tokens */
        axionBought = swapEthForTokens(axion, stakeManager, _axionAmount, _amountOut, _deadline);
        tokenBought = swapEthForTokens(
            token,
            ventureCapital,
            _tokenAmount,
            _amountTokenOut,
            _deadline
        );

        // Call sendAndBurn
        uint256 payout = sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer any eithereum in contract to recipient address */
        safeTransferETH(recipient, _recipientAmount);

        //** Emit Event  */
        emit AcceleratorEth(
            msg.sender,
            token,
            currentDay,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return {uint256}
     */
    function swapEthForTokens(
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        if (_tokenOutAddress == WETH) {
            /** Path through WETH */
            address[] memory pathEth = new address[](2);
            pathEth[0] = IUniswapV2Router02(uniswap).WETH();
            pathEth[1] = _tokenOutAddress;

            /** Swap for tokens */
            return
                IUniswapV2Router02(uniswap).swapExactETHForTokens{value: _amountIn}(
                    _amountOutMin,
                    pathEth,
                    _to,
                    _deadline
                )[1];
        }

        /** Path through WETH */
        address[] memory path = new address[](3);
        path[0] = IUniswapV2Router02(uniswap).WETH();
        path[1] = WETH;
        path[2] = _tokenOutAddress;

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactETHForTokens{value: _amountIn}(
                _amountOutMin,
                path,
                _to,
                _deadline
            )[2];
    }

    /** @dev stake with ethereum
        Description: Sell a token buy axion and then stake it for # of days
        @param _token {address}
        @param _amount {uint256}
        @param _amountOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStake(
        address _token,
        uint256 _amount,
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    ) external notContract whenNotPaused returns (uint256 axionBought, uint256 tokenBought) {
        require(mintedAmount < maxMint, "Accelerator has minted it's maximum limit");
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        require(
            allowedTokens[_token],
            'AUTOSTAKER: This token is not allowed to be used on this contract'
        );
        uint256 currentDay = getCurrentDay();

        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(_amount);

        /** Transfer tokens to contract */
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        //** Swap tokens */
        axionBought = swapTokensForTokens(
            _token,
            axion,
            stakeManager,
            _axionAmount,
            _amountOut,
            _deadline
        );

        if (_token != token) {
            tokenBought = swapTokensForTokens(
                _token,
                token,
                ventureCapital,
                _tokenAmount,
                _amountTokenOut,
                _deadline
            );
        } else {
            tokenBought = _tokenAmount;
            IERC20(token).safeTransfer(ventureCapital, tokenBought);
        }

        // Call sendAndBurn
        uint256 payout = sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer tokens to Manager */
        IERC20(_token).safeTransfer(recipient, _recipientAmount);

        //* Emit Event */
        emit AcceleratorToken(
            msg.sender,
            _token,
            currentDay,
            token,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev stake with ethereum
        Description: Use the wBTC interest earned to Buy and Stake into the Accelerator
        @param _token {address}
        @param _amount {uint256}
        @param _amountOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStakeWithDivs(
        address _token,
        uint256 _amount,
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    ) external notContract whenNotPaused returns (uint256 axionBought, uint256 tokenBought) {
        require(mintedAmount < maxMint, "Accelerator has minted it's maximum limit");
        require(_token != axion, 'AUTOSTAKER: Can not use axion to buy and stake with divs');
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');

        //uint256 wBtcDivsBalance = IVentureCapital(ventureCapital).getTokenInterestEarned(msg.sender, _token); //get wBTC divs balance
        require(
            _amount <= IVentureCapital(ventureCapital).getTokenInterestEarned(msg.sender, _token),
            'AUTOSTAKER: amount is higher than wBTC divs balance'
        ); //ensure the user is not trying to bid with more than the amount of wBTC divs he has

        uint256 currentDay = getCurrentDay();

        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(_amount);

        /** Withdraw wBTC divs tokens to contract */

        IVentureCapital(ventureCapital).withdrawDivTokensToAccelerator(
            msg.sender,
            _token,
            payable(address(this))
        );

        //** Swap tokens */
        axionBought = swapTokensForTokens(
            _token,
            axion,
            stakeManager,
            _axionAmount,
            _amountOut,
            _deadline
        );

        if (_token != token) {
            tokenBought = swapTokensForTokens(
                _token,
                token,
                ventureCapital,
                _tokenAmount,
                _amountTokenOut,
                _deadline
            );
        } else {
            tokenBought = _tokenAmount;
            IERC20(token).safeTransfer(ventureCapital, tokenBought);
        }

        // Call sendAndBurn
        uint256 payout = sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer tokens to Manager */
        IERC20(_token).safeTransfer(recipient, _recipientAmount);

        //* Emit Event */
        emit AcceleratorToken(
            msg.sender,
            _token,
            currentDay,
            token,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenInAddress {address}
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return amounts {uint256[]} [TokenIn, ETH, AXN]
     */
    function swapTokensForTokens(
        address _tokenInAddress,
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        /** Path through WETH */
        if (_tokenInAddress == WETH || _tokenOutAddress == WETH) {
            address[] memory pathEth = new address[](2);
            pathEth[0] = _tokenInAddress;
            pathEth[1] = _tokenOutAddress;

            /** Check allowance */
            if (IERC20(_tokenInAddress).allowance(address(this), uniswap) < 2**128) {
                IERC20(_tokenInAddress).approve(uniswap, 2**255);
            }

            /** Swap for tokens */
            return
                IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                    _amountIn,
                    _amountOutMin,
                    pathEth,
                    _to,
                    _deadline
                )[1];
        }

        address[] memory path = new address[](3);
        path[0] = _tokenInAddress;
        path[1] = WETH;
        path[2] = _tokenOutAddress;

        /** Check allowance */
        if (IERC20(_tokenInAddress).allowance(address(this), uniswap) < 2**128) {
            IERC20(_tokenInAddress).approve(uniswap, 2**255);
        }

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                _to,
                _deadline
            )[2];
    }

    /** @dev sendAndBurn
        Description: Burns axion, transfers btc to staking, and creates the stake
        @param _axionBought {uint256}
        @param _days {uint256}
        @param _currentDay {uint256}

        @return payout uint256 
     */
    function sendAndBurn(
        uint256 _axionBought,
        uint256 _tokenBought,
        uint256 _days,
        uint256 _currentDay
    ) internal returns (uint256) {
        IVentureCapital(ventureCapital).updateTokenPricePerShare(token, _tokenBought);

        //** Add additional axion if stake length is greater then 1year */
        uint256 payout = (100 * _axionBought) / splitAmounts[0];

        // Generate the NFT.
        if (colliding) {
            (uint256 amount, uint256 rarity) =
                randomGenerator.getRandomMultiplier(payout, msg.sender);
            acceleratorNFT.mint(msg.sender, amount, rarity);
        }

        if (nftFactory.balanceOf(msg.sender, 3) > 0 && nftFactory.balanceOf(msg.sender, 8) > 0) {
            // Phoenix Gold + diamond
            payout = payout + (payout * 9) / 100;
        } else if (
            nftFactory.balanceOf(msg.sender, 3) > 0 && nftFactory.balanceOf(msg.sender, 7) > 0
        ) {
            // Phoenix Silver + diamond
            payout = payout + (payout * 8) / 100;
        } else if (
            nftFactory.balanceOf(msg.sender, 3) > 0 && nftFactory.balanceOf(msg.sender, 6) > 0
        ) {
            // Phoenix bronze + diamond
            payout = payout + (payout * 7) / 100;
        } else if (nftFactory.balanceOf(msg.sender, 3) > 0) {
            // diamond
            payout = payout + (payout * 5) / 100;
        } else if (nftFactory.balanceOf(msg.sender, 8) > 0) {
            // Phoenix Gold
            payout = payout + (payout * 4) / 100;
        } else if (nftFactory.balanceOf(msg.sender, 7) > 0) {
            // Phoenix Silver
            payout = payout + (payout * 3) / 100;
        } else if (nftFactory.balanceOf(msg.sender, 6) > 0) {
            // Phoenix Bronze
            payout = payout + (payout * 2) / 100;
        }

        if (_days >= bonusStartDays && bought[_currentDay] < maxBoughtPerDay) {
            // Get amount for sale left
            uint256 payoutWithBonus = maxBoughtPerDay - bought[_currentDay];
            // Add to payout
            bought[_currentDay] += payout;
            if (payout > payoutWithBonus) {
                uint256 payoutWithoutBonus = payout - payoutWithBonus;

                payout =
                    (payoutWithBonus +
                        (payoutWithBonus * ((_days / bonusStartDays) + bonusStartPercent)) /
                        100) +
                    payoutWithoutBonus;
            } else {
                payout = payout + (payout * ((_days / bonusStartDays) + bonusStartPercent)) / 100; // multiply by percent divide by 100
            }
        } else {
            //** If not returned above add to bought and return payout. */
            bought[_currentDay] += payout;
        }

        //** Stake the burned tokens */
        mintedAmount += payout;
        IStakeMinter(staking).externalStake(payout, _days, msg.sender);
        //** Return amounts for the frontend */
        return payout;
    }

    /** Utility Functions */
    /** @dev currentDay
        Description: Get the current day since start of contract
     */
    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp - start) / secondsInDay;
    }

    /** @dev splitAmounts */
    function getSplitAmounts() public view returns (uint8[3] memory) {
        uint8[3] memory _splitAmounts;
        for (uint256 i = 0; i < splitAmounts.length; i++) {
            _splitAmounts[i] = splitAmounts[i];
        }
        return _splitAmounts;
    }

    /** @dev dividedAmounts
        Description: Uses Split amounts to return amountIN should be each
        @param _amountIn {uint256}
     */
    function dividedAmounts(uint256 _amountIn)
        internal
        view
        returns (
            uint256 _axionAmount,
            uint256 _tokenAmount,
            uint256 _recipientAmount
        )
    {
        _axionAmount = (_amountIn * splitAmounts[0]) / 100;
        _tokenAmount = (_amountIn * splitAmounts[1]) / 100;
        _recipientAmount = (_amountIn * splitAmounts[2]) / 100;
    }

    // -------------------- Setter Functions ------------------------
    /** @dev setAllowedToken
        Description: Allow tokens can be swapped for axion.
        @param _token {address}
        @param _allowed {bool}
     */
    function setAllowedToken(address _token, bool _allowed) external onlyManager {
        allowedTokens[_token] = _allowed;

        emit SetAllowedToken(msg.sender, _token, _allowed);
    }

    /** @dev setAllowedTokens
        Description: Allow tokens can be swapped for axion.
        @param _tokens {address}
        @param _allowed {bool}
     */
    function setAllowedTokens(address[] calldata _tokens, bool[] calldata _allowed)
        external
        onlyManager
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = _allowed[i];
            emit SetAllowedToken(msg.sender, _tokens[i], _allowed[i]);
        }
    }

    /** @dev setPaused
        @param _p {bool}
     */
    function setPaused(bool _p) external onlyManager {
        _paused = _p;

        emit SetPaused(msg.sender, _p);
    }

    /** @dev setColliding
        @param _colliding {bool}
     */
    function setColliding(bool _colliding) external onlyManager {
        colliding = _colliding;

        emit SetColliding(msg.sender, _colliding);
    }

    /** @dev setFee
        @param _days {uint256}
     */
    function setMinStakeDays(uint256 _days) external onlyManager {
        minStakeDays = _days;

        emit SetMinStakeDays(msg.sender, _days);
    }

    /** @dev splitAmounts
        @param _splitAmounts {uint256[]}
     */
    function setSplitAmounts(uint8[3] calldata _splitAmounts) external onlyManager {
        uint8 total = _splitAmounts[0] + _splitAmounts[1] + _splitAmounts[2];
        require(total == 100, 'ACCELERATOR: Split Amounts must == 100');

        splitAmounts = _splitAmounts;

        emit SetSplitAmounts(msg.sender, _splitAmounts);
    }

    /** @dev maxBoughtPerDay
        @param _amount uint256 
    */
    function setMaxBoughtPerDay(uint256 _amount) external onlyManager {
        maxBoughtPerDay = _amount;

        emit SetMaxBoughtPerDay(msg.sender, _amount);
    }

    /** @dev setBaseBonus
        @param _amount uint256 
    */
    function setBaseBonus(uint8 _amount) external onlyManager {
        baseBonus = _amount;

        emit SetBaseBonus(msg.sender, _amount);
    }

    /** @dev setBonusStart%
        @param _amount uint8 
    */
    function setBonusStartPercent(uint8 _amount) external onlyManager {
        bonusStartPercent = _amount;

        emit SetBonusStartPercent(msg.sender, _amount);
    }

    /** @dev setBonusStartDays
        @param _amount uint8 
    */
    function setBonusStartDays(uint16 _amount) external onlyManager {
        bonusStartDays = _amount;

        emit SetBonusStartDays(msg.sender, _amount);
    }

    /** @dev setRecipient
        @param _recipient uint8 
    */
    function setRecipient(address payable _recipient) external onlyManager {
        recipient = _recipient;

        emit SetRecipient(msg.sender, _recipient);
    }

    /** @dev setToken
        @param _token {address} 
    */
    function setToken(address _token) external onlyManager {
        token = _token;
        IVentureCapital(ventureCapital).addDivToken(_token);

        emit SetToken(msg.sender, _token);
    }

    /** @dev setVC
        @param _ventureCapital {address} 
    */
    function setVentureCapital(address _ventureCapital) external onlyManager {
        ventureCapital = _ventureCapital;
    }

    /** @dev setStaking
        @param _staking {address} 
    */
    function setStaking(address _staking) external onlyManager {
        staking = _staking;
    }

    /** @dev setStakeManager
        @param _stakeManager {address} 
    */
    function setStakeManager(address _stakeManager) external onlyManager {
        stakeManager = _stakeManager;
    }

    /** @dev setUniswap
        @param _uni {address} 
    */
    function setUniswap(address _uni) external onlyManager {
        uniswap = payable(_uni);
    }

    /** @dev setAcceleratorNFT
        @param _nft {address} 
    */
    function setAcceleratorNFT(address _nft) external onlyManager {
        acceleratorNFT = IAcceleratorNFT(_nft);
    }

    /** @dev setRandomGenerator
        @param _random {address} 
    */
    function setRandomGenerator(address _random) external onlyManager {
        randomGenerator = IRandom(_random);
    }

    /** @dev setNFTFactory
        @param _nftFactory {address} 
    */
    function setNFTFactory(address _nftFactory) external onlyManager {
        nftFactory = IAxionNFTUtility(_nftFactory);
    }

    /** @notice Set WETH */
    function setWETH(address _weth) external onlyManager {
        WETH = _weth;
    }

    /** @notice Set WETH */
    function setOTCPool(address _pool) external onlyManager {
        otcPool = _pool;
    }

    function setMaxMint(uint256 value) external onlyManager {
        maxMint = value;
    }

    // -------------------- Getter Functions ------------------------
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /** Utility Function */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** note: Recover tokens accidentally put into contract. */
    function safeRecover(
        address recoverFor,
        address tokenToRecover,
        uint256 amount
    ) external onlyManager {
        IERC20(tokenToRecover).safeTransfer(recoverFor, amount);
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

pragma solidity >=0.8.0;

interface IVentureCapital {
    function addTotalSharesOfAndRebalance(address staker, uint256 shares) external;

    function subTotalSharesOfAndRebalance(address staker, uint256 shares) external;

    function withdrawDivTokensFromToExternal(address from, address payable to) external;

    function withdrawDivTokensToAccelerator(
        address from,
        address tokenAddress,
        address payable acceleratorAddress
    ) external;

    function transferSharesAndRebalance(
        address from,
        address to,
        uint256 shares
    ) external;

    function transferSharesAndRebalance(
        address from,
        address to,
        uint256 oldShares,
        uint256 newShares
    ) external;

    function updateTokenPricePerShare(address tokenAddress, uint256 amountBought) external payable;

    function updateTokenPricePerShareAxn(uint256 amountBought) external;

    function addDivToken(address tokenAddress) external;

    function getTokenInterestEarned(address accountAddress, address tokenAddress)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStakeMinter {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

interface IToken is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IRandom {
    function getRandom(uint256 difficulty, address account) external returns (bool);

    function getBaseDifficult() external returns (uint256);

    function getRandomMultiplier(uint256 multipliedBy, address account)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAcceleratorNFT {
    function mint(
        address to,
        uint256 particles,
        uint256 rarity
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

abstract contract Manageable is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), 'Caller is not a manager');
        _;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAxionNFTUtility {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function mintExternal(
        uint256 utilityIdx,
        uint256 amount,
        address to
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}