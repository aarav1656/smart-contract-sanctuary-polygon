//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./DarkMatter.sol";
import "./GenerationManager.sol";
import "./StableCoinAcceptor.sol";
import "./Exchange.sol";
import "./StackOsNFTBasic.sol";
import "./Subscription.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

contract Vault is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    event Deposit(address indexed depositor);
    event Withdraw(address indexed depositor);

    // this data is stored when NFT is deposited in vault
    struct DepositInfo {
        address depositor; // who deposited NFT and received withdrawn fee and bonus
        uint256 totalFee; // total subscription fee withdrawn
        uint256 totalBonus; // total subscription bonus withdrawn

        // these two are always small numbers, so put them in one slot
        uint128 tax; // tax percent when subscription fee withdrawn
        uint128 date; // block.timestamp when deposit with claim were made
    }

    IERC20 internal immutable stackToken;
    GenerationManager internal immutable generations;
    Subscription internal immutable sub0;
    Subscription internal immutable subscription;
    uint256 public immutable LOCK_DURATION;

    bool public isDepositsOpened = true;

    mapping(address => uint256) public allocations;
    mapping(address => mapping(uint256 => uint256[])) private ownerToTokens;
    mapping(uint256 => mapping(uint256 => DepositInfo)) public depositInfo;

    constructor(
        IERC20 _stackToken,
        GenerationManager _generations,
        Subscription _sub0,
        Subscription _subscription,
        uint256 _LOCK_DURATION
    ) {
        stackToken = _stackToken;
        generations = _generations;
        sub0 = _sub0;
        subscription = _subscription;
        LOCK_DURATION = _LOCK_DURATION;
    }

    /// @notice returns tokens in generation `generationId` that are in vault and deposited by wallet `owner`.
    function getDepositedTokensOf(address owner, uint256 generationId)
        public
        view
        returns (uint256[] memory)
    {
        return ownerToTokens[owner][generationId];
    }

    function deposit(uint256 generationId, uint256 tokenId) public {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(isDepositsOpened, "Deposits are closed now");
        require(
            depositInfo[generationId][tokenId].depositor == address(0),
            "Cannot redeposit same token"
        );

        StackOsNFTBasic stackNft = StackOsNFTBasic(
            address(generations.get(generationId))
        );
        stackNft.transferFrom(msg.sender, address(this), tokenId);

        Subscription _subscription = getSubscriptionContract(generationId);
        // withdraw subscription fee to this contract
        (, uint256 tax, ) = _subscription.deposits(generationId, tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        uint256 balanceBeforeWithdraw = stackToken.balanceOf(address(this));
        _subscription.withdraw(generationId, tokenIds);
        uint256 balanceAfterWithdraw = stackToken.balanceOf(address(this));

        // save total fee + bonus that this user ever deposited
        (uint256 unlocked, uint256 locked, ) = _subscription.pendingBonus(
            generationId,
            tokenId
        );
        allocations[msg.sender] +=
            (balanceAfterWithdraw - balanceBeforeWithdraw) +
            unlocked +
            locked;

        // claim bonus to this contract
        uint256 balanceBeforeBonus = stackToken.balanceOf(address(this));
        _subscription.claimBonus(generationId, tokenIds);
        uint256 balanceAfterBonus = stackToken.balanceOf(address(this));

        // transfer withdrawn fee and bonus to owner
        if (balanceAfterBonus > 0)
            stackToken.transfer(owner(), balanceAfterBonus);

        // save claim info
        depositInfo[generationId][tokenId] = DepositInfo({
            depositor: msg.sender,
            totalFee: balanceAfterWithdraw - balanceBeforeWithdraw,
            totalBonus: balanceAfterBonus - balanceBeforeBonus,
            tax: uint128(tax),
            date: uint128(block.timestamp)
        });
        ownerToTokens[msg.sender][generationId].push(tokenId);

        emit Deposit(msg.sender);
    }

    function withdraw(uint256 generationId, uint256 tokenId) public {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(
            block.timestamp >
                depositInfo[generationId][tokenId].date + LOCK_DURATION,
            "locked"
        );
        require(
            msg.sender == depositInfo[generationId][tokenId].depositor,
            "Not owner"
        );

        StackOsNFTBasic stackNft = StackOsNFTBasic(
            address(generations.get(generationId))
        );

        Subscription _subscription = getSubscriptionContract(generationId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        // claim bonus to this contract
        try _subscription.claimBonus(generationId, tokenIds) {} catch {}
        uint256 stackTokensBalance = stackToken.balanceOf(address(this));

        // transfer withdraw fee and bonus to owner
        if (stackTokensBalance > 0)
            stackToken.transfer(owner(), stackTokensBalance);
        stackNft.transferFrom(address(this), msg.sender, tokenId);
        emit Withdraw(msg.sender);
    }

    function ownerClaim(uint256 generationId, uint256 tokenId)
        public
        onlyOwner
    {
        require(generationId < generations.count(), "Generation doesn't exist");

        Subscription _subscription = getSubscriptionContract(generationId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        _subscription.withdraw(generationId, tokenIds);
        _subscription.claimBonus(generationId, tokenIds);
        uint256 stackTokensBalance = stackToken.balanceOf(address(this));

        // transfer withdrawn fee and bonus to owner
        if (stackTokensBalance > 0)
            stackToken.transfer(msg.sender, stackTokensBalance);
    }

    /// @dev returns correct subscription contract for gen0 and gen1
    function getSubscriptionContract(uint256 generationId)
        private
        view
        returns (Subscription)
    {
        return generationId == 0 ? sub0 : subscription;
    }

    function closeDeposits() external onlyOwner {
        isDepositsOpened = false;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IStackOsNFT.sol";
import "./GenerationManager.sol";
import "./Whitelist.sol";

contract DarkMatter is Whitelist, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;

    event Activate();
    event Deposit(
        address indexed _wallet, 
        uint256 generationId,
        uint256[] tokenIds
    );

    Counters.Counter private _tokenIdCounter;
    
    GenerationManager private immutable generations;
    
    // number of StackNFTs that must be deposited in order to be able to mint a DarkMatter.
    uint256 immutable mintPrice; 
    bool isActive; 

    // total amount of NFT deposited from any generation
    mapping(address => uint256) private deposits; 
    // owner => current incomplete DarkMatter id
    mapping(address => uint256) private lastUserDarkMatter; 
    // owner => DarkMatter ids
    mapping(address => uint256[]) private toBeMinted; 

    // need this to distinguish from default 0
    struct ValidId {
        uint256 id;
        bool written;
    }
    // generation => StackNFT id => DarkMatter id
    mapping(uint256 => mapping(uint256 => ValidId)) private stackToDarkMatter; 

    // DarkMatter id => generation => StackNFT ids 
    mapping(uint256 => mapping(uint256 => uint256[])) private darkMatterToStack; 


    constructor(GenerationManager _generations, uint256 _mintPrice)
        ERC721("DarkMatter", "DM")
    {
        generations = _generations;
        mintPrice = _mintPrice;
    }

    function activate() external onlyOwner {
        isActive = true;
        emit Activate();
    }

    /**
     * @notice Get stack token ids used to mint this DarkMatterNFT.
     * @param _darkMatterId DarkMatter token id.
     * @return Stack token ids owned by DarkMatterNFT.
     */
    function ID(uint256 _darkMatterId)
        external 
        view
        returns (uint256[][] memory)
    {
        uint256[][] memory stackTokenIds = new uint256[][](generations.count());
        for(uint256 i; i < stackTokenIds.length; i ++) {
            stackTokenIds[i] = darkMatterToStack[_darkMatterId][i];
        }
        return stackTokenIds;
    }

    /**
     * @notice Get whether wallet owns StackNFT or DarkMatter that owns this StackNFT
     * @param _wallet Address of wallet.
     * @param generationId StackNFT generation id.
     * @param tokenId StackNFT token id.
     * @return Whether `_wallet` owns either StackNFT or DarkMatterNFT that owns this StackNFT.
     */
    function isOwnStackOrDarkMatter(
        address _wallet,
        uint256 generationId,
        uint256 tokenId
    ) external view returns (bool) {
        if (
            stackToDarkMatter[generationId][tokenId].written &&
            _exists(stackToDarkMatter[generationId][tokenId].id) &&
            ownerOfStack(generationId, tokenId) == _wallet
        ) {
            return true;
        }
        return generations.get(generationId).ownerOf(tokenId) == _wallet;
    }

    /**
     * @notice Returns owner of either StackNFT or DarkMatter that owns StackNFT. 
     * @param _stackOsNFT StackNFT address.
     * @param tokenId StackNFT token id.
     * @return Address that owns StackNFT or DarkMatter that owns this StackNFT. 
     */
    function ownerOfStackOrDarkMatter(IStackOsNFT _stackOsNFT, uint256 tokenId)
        external
        view
        returns (address)
    {
        uint256 generationId = generations.getIDByAddress(address(_stackOsNFT));
        if (
            stackToDarkMatter[generationId][tokenId].written &&
            _exists(stackToDarkMatter[generationId][tokenId].id)
        ) {
            return ownerOfStack(generationId, tokenId);
        }
        return _stackOsNFT.ownerOf(tokenId);
    }

    /**
     * @notice Get owner of the DarkMatterNFT that owns StackNFT.
     * @param generationId StackNFT generation id.
     * @param tokenId StackNFT token id.
     * @return Owner of the DarkMatterNFT that owns StackNFT.
     */
    function ownerOfStack(uint256 generationId, uint256 tokenId)
        public
        view
        returns (address)
    {
        require(stackToDarkMatter[generationId][tokenId].written);
        return ownerOf(stackToDarkMatter[generationId][tokenId].id);
    }

    /**
     *  @notice Deposit enough StackNFTs in order to be able to mint DarkMatter.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds Token ids.
     *  @dev StackNFT generation must be added in manager prior to deposit.
     */
    function deposit(uint256 generationId, uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        require(isActive, "Inactive");
        require(generationId < generations.count(), "Generation doesn't exist");
        IStackOsNFT stackNFT = generations.get(generationId);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            stackNFT.transferFrom(msg.sender, address(this), tokenId);

            if (deposits[msg.sender] == 0) {
                lastUserDarkMatter[msg.sender] = _tokenIdCounter.current();
                _tokenIdCounter.increment();
            }
            deposits[msg.sender] += 1;
            if (deposits[msg.sender] == mintPrice) {
                deposits[msg.sender] -= mintPrice;
                darkMatterToStack[lastUserDarkMatter[msg.sender]][generationId].push(tokenId);
                toBeMinted[msg.sender].push(lastUserDarkMatter[msg.sender]);
            } else {
                darkMatterToStack[lastUserDarkMatter[msg.sender]][generationId].push(tokenId);
            }
            stackToDarkMatter[generationId][tokenId].written = true;
            stackToDarkMatter[generationId][tokenId].id = lastUserDarkMatter[
                msg.sender
            ];
        }

        emit Deposit(msg.sender, generationId, tokenIds);
    }

    /**
     *  @notice Mints a DarkMatterNFT for the caller.
     *  @dev Caller must have deposited `mintPrice` number of StackNFT of any generation.
     */
    function mint() external nonReentrant {
        require(toBeMinted[msg.sender].length > 0, "Not enough deposited");
        while (toBeMinted[msg.sender].length > 0) {
            _mint(
                msg.sender,
                toBeMinted[msg.sender][toBeMinted[msg.sender].length - 1]
            );
            toBeMinted[msg.sender].pop();
        }
    }

    /*
     *  @title Override to make use of whitelist.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721)
        onlyWhitelisted
    {
        super._transfer(from, to, tokenId);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IStackOsNFT.sol";
import "./StackOsNFTBasic.sol";

contract GenerationManager is Ownable, ReentrancyGuard {
    using Strings for uint256;

    event NextGenerationDeploy(
        address StackNFT, 
        address deployer, 
        uint256 deployTimestamp
    );
    event AdjustAddressSettings(
        address _stableAcceptor,
        address _exchange,
        address _dao
    );
    event SetupDeploy(
        Deployment settings
    );

    struct Deployment {
        string name;
        string symbol;
        address stackToken;
        address darkMatter;
        address subscription;
        address sub0;
        uint256 mintPrice;
        uint256 subsFee;
        uint256 daoFee;
        uint256 maxSupplyGrowthPercent;
        uint256 transferDiscount;
        uint256 rewardDiscount;
        address royaltyAddress;
        address market;
        string baseURI;
    }

    address private stableAcceptor;
    address private exchange;
    address private dao;

    uint256 private GEN2_MAX_SUPPLY = 1000;

    Deployment private deployment;
    IStackOsNFT[] private generations;
    mapping(address => uint256) private ids;

    constructor() {}

    function getDeployment() 
        external 
        view 
        returns 
        (Deployment memory) 
    {
        return deployment;
    }

    function adjustAddressSettings(
        address _stableAcceptor,
        address _exchange,
        address _dao
    )
        public
        onlyOwner
    {
        stableAcceptor = _stableAcceptor;
        exchange = _exchange;
        dao = _dao;
        emit AdjustAddressSettings(
            _stableAcceptor,
            _exchange,
            _dao
        );
    }

    /**
     * @notice Function for convinience when testing.
     * @param maxSupply Max supply to use in generation 2 deployment.
     * @dev Could only be invoked by the contract owner.
     */
    function SET_GEN2_MAX_SUPPLY(
        uint256 maxSupply
    ) public onlyOwner {
        GEN2_MAX_SUPPLY = maxSupply;
    }

    /**
     * @notice Save settings for manual or auto deployment.
     * @param settings Structure of parameters to use for next generation deployment.
     * @dev Could only be invoked by the contract owner.
     */
    function setupDeploy(
        Deployment calldata settings
    ) public onlyOwner {
        deployment = settings;
        emit SetupDeploy(settings);
    }

    /**
     * @notice Called by StackNFTBasic once it reaches max supply.
     * @dev Could only be invoked by the last StackOsNFTBasic generation.
     * @dev Generation id is appended to the name. 
     * @return Address of new StackNFT contract generation.
     */
    function autoDeployNextGeneration() 
        public 
        nonReentrant
        returns 
        (IStackOsNFTBasic) 
    {
        // Can only be called from StackNFT contracts
        // Cannot deploy next generation if it's already exists
        require(getIDByAddress(msg.sender) == generations.length - 1);

        StackOsNFTBasic stack = StackOsNFTBasic(
            address(
                new StackOsNFTBasic()
            )
        );
        stack.setName(
            string(abi.encodePacked(
                deployment.name,
                " ",
                uint256(count()).toString()
            ))
        );
        stack.setSymbol(deployment.symbol);
        stack.initialize(
            deployment.stackToken,
            deployment.darkMatter,
            deployment.subscription,
            deployment.sub0,
            deployment.royaltyAddress,
            stableAcceptor,
            exchange,
            deployment.mintPrice,
                // if kicking 2nd generation, use constant, otherwise apply growth % 
                count() == 1 ? GEN2_MAX_SUPPLY : 
                get(getIDByAddress(msg.sender)).getMaxSupply() * 
                (deployment.maxSupplyGrowthPercent + 10000) / 10000,

            deployment.transferDiscount
        );
        add(address(stack));
        stack.setFees(deployment.subsFee, deployment.daoFee);
        stack.setRewardDiscount(deployment.rewardDiscount);
        stack.adjustAddressSettings(dao);
        stack.whitelist(address(deployment.darkMatter));
        stack.whitelist(address(deployment.market));
        stack.setBaseURI(deployment.baseURI);
        stack.transferOwnership(Ownable(msg.sender).owner());
        emit NextGenerationDeploy(address(stack), msg.sender, block.timestamp);
        return IStackOsNFTBasic(address(stack));
    }

    /**
     * @notice Add next generation of StackNFT to manager. 
     * @notice To be called automatically, or when adding 1st generation.
     * @notice Royalty address has to be set with setupDeploy.
     * @param _stackOS IStackOsNFT address.
     * @dev Royalty address has to be set with setupDeploy.
     * @dev Could only be invoked by the contract owner to add 1st generation
     *      or by StackNFT contract on auto deployment.
     * @dev Address should be unique.
     */
    function add(address _stackOS) public {
        require(owner() == _msgSender() || isAdded(_msgSender()));
        require(address(_stackOS) != address(0)); // forbid 0 address
        require(isAdded(address(_stackOS)) == false); // forbid duplicates
        ids[address(_stackOS)] = generations.length;
        Royalty(payable(deployment.royaltyAddress))
            .onGenerationAdded(generations.length, _stackOS);
        generations.push(IStackOsNFT(_stackOS));
    }

    /**
     * @notice Deploy new StackOsNFTBasic manually.
     * @notice Deployment structure must be filled before deploy.
     * @notice `adjustAddressSettings` must be called in GenerationManager before deploy. 
     * @param _maxSupply Exact max supply for new NFT contract.
     */
    function deployNextGenerationManually(
        uint256 _maxSupply
    ) 
        public 
        onlyOwner 
        nonReentrant
        returns 
        (IStackOsNFTBasic) 
    {
        StackOsNFTBasic stack = StackOsNFTBasic(
            address(
                new StackOsNFTBasic()
            )
        );
        stack.setName(
            string(abi.encodePacked(
                deployment.name,
                " ",
                uint256(count()).toString()
            ))
        );
        stack.setSymbol(deployment.symbol);
        stack.initialize(
            deployment.stackToken,
            deployment.darkMatter,
            deployment.subscription,
            deployment.sub0,
            deployment.royaltyAddress,
            stableAcceptor,
            exchange,
            deployment.mintPrice,
            _maxSupply,
            deployment.transferDiscount
        );
        add(address(stack));
        stack.setFees(deployment.subsFee, deployment.daoFee);
        stack.setRewardDiscount(deployment.rewardDiscount);
        stack.adjustAddressSettings(dao);
        stack.whitelist(address(deployment.darkMatter));
        stack.whitelist(address(deployment.market));
        stack.setBaseURI(deployment.baseURI);
        stack.transferOwnership(msg.sender);
        emit NextGenerationDeploy(address(stack), msg.sender, block.timestamp);
        return IStackOsNFTBasic(address(stack));
    }

    /**
     * @notice Get total number of generations added.
     */
    function count() public view returns (uint256) {
        return generations.length;
    }

    /**
     * @notice Get address of StackNFT contract by generation id.
     * @param generationId Generation id to lookup.
     * @dev Must be valid generation id to avoid out-of-bounds error.
     * @return Address of StackNFT contract.
     */
    function get(uint256 generationId) public view returns (IStackOsNFT) {
        return generations[generationId];
    }

    /**
     * @notice Get generation id by StackNFT contract address.
     * @param _nftAddress Stack NFT contract address
     * @return Generation id.
     */
    function getIDByAddress(address _nftAddress) public view returns (uint256) {
        uint256 generationID = ids[_nftAddress];
        if (generationID == 0) {
            require(address(get(0)) == _nftAddress);
        }
        return generationID;
    }

    /**
     * @notice Returns whether StackNFT contract is added to this manager.
     * @param _nftAddress Stack NFT contract address.
     * @return Whether StackNFT contract is added to manager.
     */
    function isAdded(address _nftAddress) public view returns (bool) {
        uint256 generationID = ids[_nftAddress];
        return generations.length > generationID && address(get(generationID)) == _nftAddress;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableCoinAcceptor {

    IERC20[] public stablecoins;

    constructor(
        IERC20[] memory _stables
    ) {
        require(_stables.length > 0, "Empty data");
        for(uint256 i; i < _stables.length; i++) {
            require(
                address(_stables[i]) != address(0), 
                "Should not be zero-address"
            );
        }
        stablecoins = _stables;
    }

    /**
     * @notice Returns whether provided stablecoin is supported.
     * @param _address Address to lookup.
     */
    function supportsCoin(IERC20 _address) public view returns (bool) {
        uint256 len = stablecoins.length;
        for(uint256 i; i < len; i++) {
            if(_address == stablecoins[i]) {
                return true;
            }
        }
        return false;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Exchange is Ownable {
    using SafeERC20 for IERC20;

    event SetRouter(address newRouter);

    IUniswapV2Router02 public router;

    constructor (address _router) {
        router = IUniswapV2Router02(_router);
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0));
        router = IUniswapV2Router02(_router);
        emit SetRouter(_router);
    }

    /**
     *  @notice Swap exact ETH for tokens.
     *  @param token Address of token to receive.
     *  @return amountReceived Amount of token received.
     */
    function swapExactETHForTokens(
        IERC20 token
    ) public payable returns (uint256 amountReceived) {
        uint256 deadline = block.timestamp + 1200;
        address[] memory path = new address[](2);
        path[0] = address(router.WETH());
        path[1] = address(token);
        uint256[] memory amountOutMin = router.getAmountsOut(msg.value, path);
        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin[1],
            path,
            address(msg.sender),
            deadline
        );
        return amounts[1];
    }

    /**
     *  @notice Swap exact tokens for ETH.
     *  @param token Address of token to swap.
     *  @param amount Amount of token to swap.
     *  @param to Receiver of eth.
     *  @return amountReceived Amount of eth received.
     */
    function swapExactTokensForETH(
        IERC20 token,
        uint256 amount,
        address to
    ) public payable returns (uint256 amountReceived) {
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.approve(address(router), amount);
        uint256 deadline = block.timestamp + 1200;
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(router.WETH());
        uint256[] memory amountOutMin = router.getAmountsOut(amount, path);
        uint256[] memory amounts = router.swapExactTokensForETH(
            amount,
            amountOutMin[1],
            path,
            to,
            deadline
        );
        return amounts[1];
    }

    /**
     *  @notice Swap exact tokens for tokens using path tokenA > WETH > tokenB.
     *  @param amountA Amount of tokenA to spend.
     *  @param tokenA Address of tokenA to spend.
     *  @param tokenB Address of tokenB to receive.
     *  @return amountReceivedTokenB Amount of tokenB received.
     */
    function swapExactTokensForTokens(
        uint256 amountA, 
        IERC20 tokenA, 
        IERC20 tokenB
    ) public returns (uint256 amountReceivedTokenB) {

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenA.approve(address(router), amountA);

        uint256 deadline = block.timestamp + 1200;
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(router.WETH());
        path[2] = address(tokenB);
        uint256[] memory amountOutMin = router.getAmountsOut(amountA, path);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountA,
            amountOutMin[2],
            path,
            address(msg.sender),
            deadline
        );
        return amounts[2];
    }

    /**
     *  @notice Given an output amount of an asset, 
     *          returns a required input amount of the other asset,
     *          using path tokenIn > WETH > tokenOut.
     *  @param amountOut Amount wish to receive.
     *  @param tokenOut Token wish to receive.
     *  @param tokenIn Token wish to spend.
     *  @return amountIn Amount of tokenIn.
     */
    function getAmountIn(
        uint256 amountOut, 
        IERC20 tokenOut, 
        IERC20 tokenIn
    ) public view returns (uint256 amountIn) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(router.WETH());
        path[2] = address(tokenOut);
        uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
        return amountsIn[0];
    }

    /**
     *  @notice Given an input amount of an asset, 
     *          returns the maximum output amount of the other asset,
     *          using path tokenIn > WETH > tokenOut.
     *  @param amountIn Amount wish to spend.
     *  @param tokenIn Token wish to spend.
     *  @param tokenOut Token wish to receive.
     *  @return amountOut Amount of tokenIn.
     */
    function getAmountOut(
        uint256 amountIn, 
        IERC20 tokenIn, 
        IERC20 tokenOut
    ) public view returns (uint256 amountOut) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(router.WETH());
        path[2] = address(tokenOut);
        uint256[] memory amountsIn = router.getAmountsOut(amountIn, path);
        return amountsIn[2];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IStackOsNFT.sol";
import "./interfaces/IDecimals.sol";
import "./Subscription.sol";
import "./StableCoinAcceptor.sol";
import "./Exchange.sol";
import "./Whitelist.sol";
import "./Royalty.sol";


contract StackOsNFTBasic is
    Whitelist,
    ERC721Enumerable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    event SetPrice(uint256 _price);
    event SetBaseURI(string uri);
    event SetName(string name);
    event SetSymbol(string symbol);
    event AdjustAddressSettings(
        address dao 
    );
    event SetRewardDiscount(uint256 _rewardDiscount);
    event SetFees(uint256 subs, uint256 dao);
    event AdminWithdraw(address admin, uint256 withdrawAmount);

    string private _name;
    string private _symbol;

    uint256 public constant PRICE_PRECISION = 1e18;

    Counters.Counter private _tokenIdCounter;
    IERC20 private stackToken;
    DarkMatter private darkMatter;
    Subscription private subscription;
    Subscription private sub0;
    Royalty private royaltyAddress;
    StableCoinAcceptor private stableAcceptor;
    GenerationManager private immutable generations;
    Exchange private exchange;
    address private daoAddress;

    uint256 public rewardDiscount;
    uint256 private maxSupply;
    uint256 public mintPrice;
    uint256 public transferDiscount;
    uint256 private subsFee;
    uint256 private daoFee;
    // this is max amount of mints to unlock
    uint256 public constant maxMintRate = 50;
    // time required to unlock 1 mint
    uint256 public constant mintUnlockTime = 12 seconds;

    mapping(address => uint256) private totalMinted;
    mapping(address => uint256) private lastMintAt;

    string private baseURI;

    bool private initialized;

    /*
     * @title Must be deployed only by GenerationManager
     */
    constructor() ERC721("", "") {
        
        require(Address.isContract(msg.sender));
        generations = GenerationManager(msg.sender);
    }

    function initialize(
        address _stackToken,
        address _darkMatter,
        address _subscription,
        address _sub0,
        address _royaltyAddress,
        address _stableAcceptor,
        address _exchange,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _transferDiscount
    ) external onlyOwner {
        require(initialized == false);
        initialized = true;
        
        stackToken = IERC20(_stackToken);
        darkMatter = DarkMatter(_darkMatter);
        subscription = Subscription(_subscription);
        sub0 = Subscription(_sub0);
        royaltyAddress = Royalty(payable(_royaltyAddress));
        stableAcceptor = StableCoinAcceptor(_stableAcceptor);
        exchange = Exchange(_exchange);

        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        transferDiscount = _transferDiscount;
    }

    /**
     *  @notice `_price` should have 18 decimals
     */
    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
        emit SetPrice(_price);
    }

    // Set baseURI that is used for new tokens
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetBaseURI(_uri);
    }

    /*
     * @title Set token name.
     * @dev Could only be invoked by the contract owner.
     */
    function setName(string memory name_) external onlyOwner {
        _name = name_;
        emit SetName(name_);
    }

    /*
     * @title Set token symbol.
     * @dev Could only be invoked by the contract owner.
     */
    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
        emit SetSymbol(symbol_);
    }

    /**
     * @dev Override so that it returns what we set with setName.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Override so that it returns what we set with setSybmol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /*
     * @title Adjust address settings
     * @param Dao address
     * @param Royalty distribution address
     * @dev Could only be invoked by the contract owner.
     */

    function adjustAddressSettings(
        address _dao 
    )
        external
        onlyOwner
    {
        daoAddress = _dao;
        emit AdjustAddressSettings(_dao);
    }

    /*
     * @title Set discont applied on mint from subscription or royalty rewards
     * @param percent
     * @dev Could only be invoked by the contract owner.
     */

    function setRewardDiscount(uint256 _rewardDiscount) external onlyOwner {
        require(_rewardDiscount <= 10000);
        rewardDiscount = _rewardDiscount;
        emit SetRewardDiscount(_rewardDiscount);
    }

    /*
     * @title Set amounts taken from mint
     * @param % that is sended to Subscription contract 
     * @param % that is sended to dao
     * @dev Could only be invoked by the contract owner.
     */

    function setFees(uint256 _subs, uint256 _dao)
        external
        onlyOwner
    {
        require(_subs + _dao <= 10000);
        subsFee = _subs;
        daoFee = _dao;
        emit SetFees(_subs, _dao);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /*
     * @title Get max supply
     */
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }
    
    /*
     * @title Called by 1st generation as part of `transferTickets`
     * @param Wallet to mint tokens to
     * @param Amount of STACK token received
     * @dev Could only be invoked by the StackNFT contract.
     * @dev It receives stack token and use it to mint NFTs at a discount
     */
    function transferFromLastGen(address _ticketOwner, uint256 _amount) external {

        // check that caller is generation 1 contract 
        require(address(generations.get(0)) == msg.sender);

        stackToken.transferFrom(msg.sender, address(this), _amount);

        IERC20 stablecoin = stableAcceptor.stablecoins(0);
        // how much usd we can receive for _amount of stack tokens
        uint256 amountUsd = exchange.getAmountOut(
            _amount,
            stackToken,
            stablecoin
        );

        // we need to use usd decimal places instead of uniform
        uint256 price = adjustDecimals(
            mintPrice, 
            stablecoin
        );
        // apply discount to the price
        uint256 mintPriceDiscounted = price
            .mul(10000 - transferDiscount)
            .div(10000);

        // get total amount of tickets we can mint for discounted price 
        uint256 ticketAmount = amountUsd.div(mintPriceDiscounted);

        // limit amount of tickets to mint rate
        ticketAmount = ticketAmount > maxMintRate ? maxMintRate : ticketAmount;
        // limit amount of tickets to max supply
        ticketAmount = clampToMaxSupply(ticketAmount);

        // get amount of usd we will spend for minting
        uint256 usdToSpend = mintPriceDiscounted.mul(ticketAmount);
        // convert usdToSpend to amount of stack tokens
        uint256 stackToSpend = exchange.getAmountOut(
            usdToSpend,
            stablecoin,
            stackToken
        );

        // transfer left over amount to user (total amount minus amount to spend for minting)
        stackToken.transfer(
            _ticketOwner,
            _amount - stackToSpend 
        );

        // send fees, not guaranteed that fees will take 100% of stackToSpend
        stackToSpend = sendFees(stackToSpend);

        // admin gets the payment after fees
        stackToken.transfer(owner(), stackToSpend);

        for (uint256 i; i < ticketAmount; i++) {
            _mint(_ticketOwner);
        }
    }

    /*
     * @title User mint a token amount for stack tokens.
     * @param Number of tokens to mint.
     * @dev Sales should be started before mint.
     */

    function mint(uint256 _nftAmount) external {

        require(tx.origin == msg.sender, "Only EOW");

        _nftAmount = clampToMaxSupply(_nftAmount);

        IERC20 stablecoin = stableAcceptor.stablecoins(0);
        uint256 amountOut = adjustDecimals(
            mintPrice, 
            stablecoin
        );
        amountOut = amountOut.mul(_nftAmount);

        uint256 stackAmount = exchange.getAmountIn(
            amountOut,
            stablecoin,
            stackToken
        );

        stackToken.transferFrom(msg.sender, address(this), stackAmount);

        stackAmount = sendFees(stackAmount);

        // admin gets the payment after fees
        stackToken.transfer(owner(), stackAmount);

        for (uint256 i; i < _nftAmount; i++) {
            _mint(msg.sender);
        }
    }

    /*
     * @title User mint a token amount for stablecoin.
     * @param Number of tokens to mint.
     * @param Supported stablecoin.
     * @dev Sales should be started before mint.
     */

    function mintForUsd(uint256 _nftAmount, IERC20 _stablecoin) external {
        require(tx.origin == msg.sender, "Only EOW");
        require(stableAcceptor.supportsCoin(_stablecoin));

        _nftAmount = clampToMaxSupply(_nftAmount);

        uint256 usdToSpend = adjustDecimals(
            mintPrice, 
            _stablecoin
        );
        usdToSpend = usdToSpend.mul(_nftAmount);

        _stablecoin.transferFrom(msg.sender, address(this), usdToSpend);
        _stablecoin.approve(address(exchange), usdToSpend);
        uint256 stackAmount = exchange.swapExactTokensForTokens(
            usdToSpend,
            _stablecoin,
            stackToken
        );

        stackAmount = sendFees(stackAmount);

        // admin gets the payment after fees
        stackToken.transfer(owner(), stackAmount);

        for (uint256 i; i < _nftAmount; i++) {
            _mint(msg.sender);
        }
    }

    /*
     * @title Called when user want to mint and pay with bonuses from subscriptions.
     * @param Amount to mint
     * @param Stack token amount to spend
     * @param Address to receive minted tokens
     * @dev Can only be called by Subscription contract.
     * @dev Sales should be started before mint.
     */

    function mintFromSubscriptionRewards(
        uint256 _nftAmount,
        uint256 _stackAmount,
        address _to
    ) external {
        require(
            msg.sender == address(subscription) ||
            msg.sender == address(sub0)
        );

        _stackAmount = sendFees(_stackAmount);

        // admin gets the payment after fees
        stackToken.transfer(owner(), _stackAmount);

        for (uint256 i; i < _nftAmount; i++) {
            // frontrun protection is in Subscription contract
            _mint(_to);
        }

    }

    /*
     * @title Called when user want to mint and pay with bonuses from royalties.
     * @param Amount to mint
     * @param Address to mint to
     * @dev Can only be called by Royalty contract.
     * @dev Sales should be started before mint.
     */

    function mintFromRoyaltyRewards(
        uint256 _mintNum, 
        address _to
    ) 
        external
        returns (uint256 amountSpend)
    {
        require(msg.sender == address(royaltyAddress));

        _mintNum = clampToMaxSupply(_mintNum);
        
        IERC20 stablecoin = stableAcceptor.stablecoins(0);
        uint256 price = adjustDecimals(
            mintPrice, 
            stablecoin
        );

        uint256 discountPrice = price
            .mul(10000 - rewardDiscount)
            .div(10000);

        uint256 amountUsd = discountPrice.mul(_mintNum);
        uint256 stackAmount = exchange.getAmountIn(
            amountUsd,
            stablecoin,
            stackToken
        );
        
        amountSpend = stackAmount;
        stackToken.transferFrom(msg.sender, address(this), stackAmount);

        stackAmount = sendFees(stackAmount);

        // admin gets the payment after fees
        stackToken.transfer(owner(), stackAmount);

        for (uint256 i; i < _mintNum; i++) {
            _mint(_to);
        }
    }

    /*
     * @returns left over amount after fees subtracted
     * @dev Take fees out of `_amount`
     */

    function sendFees(uint256 _amount) internal returns (uint256 amountAfterFees) {

        uint256 subsPart = _amount * subsFee / 10000;
        uint256 daoPart = _amount * daoFee / 10000;
        amountAfterFees = _amount - subsPart - daoPart;

        uint256 subsPartHalf = subsPart / 2;
        uint256 subsPartHalfTwo = subsPart - subsPartHalf;

        stackToken.approve(address(sub0), subsPartHalf);
        stackToken.approve(address(subscription), subsPartHalfTwo);
        // if subs contract don't take it, send to dao 
        if(sub0.onReceiveStack(subsPartHalf) == false) {
            daoPart += (subsPartHalf);
        }
        if(subscription.onReceiveStack(subsPartHalfTwo) == false) {
            daoPart += (subsPartHalfTwo);
        }
        stackToken.transfer(address(daoAddress), daoPart);
    }

    function _mint(address _address) internal {
        require(totalSupply() < maxSupply);

        uint256 timeSinceLastMint = block.timestamp - lastMintAt[_address];
        uint256 unlocked = timeSinceLastMint / mintUnlockTime;
        if (unlocked > totalMinted[_address])
            unlocked = totalMinted[_address];

        totalMinted[_address] -= unlocked;

        lastMintAt[_address] = block.timestamp;

        require(
            totalMinted[_address] < maxMintRate
        );

        totalMinted[_address] += 1;

        uint256 _current = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_address, _current);

        if(
            totalSupply() == maxSupply && 
            generations.getIDByAddress(address(this)) == generations.count() - 1
        ) {
            generations.autoDeployNextGeneration();
        }
    }
 
    // frontrun protection helper function
    function clampToMaxSupply(uint256 value) 
        public
        view
        returns (uint256 clamped)
    {
        // frontrun protection
        if (value > maxSupply - totalSupply())
            value = maxSupply - totalSupply();
        return value;
    }

    // Adjusts amount's decimals to token's decimals
    function adjustDecimals(uint256 amount, IERC20 token) 
        private 
        view 
        returns (uint256) 
    {
        return amount   
            .mul(10 ** IDecimals(address(token)).decimals())
            .div(PRICE_PRECISION); 
    }

    // notice the onlyWhitelisted modifier
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        override(ERC721) 
        onlyWhitelisted 
    {
        super._transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721)
    {
        super._burn(tokenId);
    }

    /**
     * @dev Returns URI in a form of "baseURI + generationId/tokenId".
     * @dev BaseURI should have slash at the end.
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override(ERC721)
        returns (string memory) 
    {
        // URI query for nonexistent token
        require(_exists(tokenId));

        string memory baseURI_ = _baseURI();
        string memory generationId = 
            generations.getIDByAddress(address(this)).toString();

        return bytes(baseURI_).length > 0 ?
            string(abi.encodePacked(baseURI_, generationId, "/", tokenId.toString())) :
            "";
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DarkMatter.sol";
import "./GenerationManager.sol";
import "./StableCoinAcceptor.sol";
import "./Exchange.sol";
import "./StackOsNFTBasic.sol";
import "./interfaces/IDecimals.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Subscription is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event SetOnlyFirstGeneration();
    event SetDripPeriod(uint256 _seconds);
    event SetPrice(uint256 price);
    event SetMaxPrice(uint256 maxPrice);
    event SetBonusPercent(uint256 _percent);
    event SetTaxReductionAmount(uint256 _amount);
    event SetForgivenessPeriod(uint256 _seconds);
    event NewPeriodStarted(uint256 newPeriodId);

    event Subscribe(
        address indexed subscriberWallet,
        uint256 nextPayDate,
        uint256 generationId,
        uint256 tokenId,
        uint256 stablePayed,
        uint256 stackReceived,
        uint256 userBonus,
        IERC20 _stablecoin,
        bool _payWithStack,
        uint256 periodId
    );

    event WithdrawRewards(
        address indexed subscriberWallet,
        uint256 amountWithdrawn,
        uint256 generationId, 
        uint256[] tokenIds
    );

    event PurchaseNewNft(
        address indexed subscriberWallet,
        uint256 generationId,
        uint256 tokenId,
        uint256 purchaseGenerationId,
        uint256 amountToMint
    );

    event Withdraw(
        address indexed subscriberWallet,
        uint256 generationId,
        uint256 tokenId,
        uint256 amountWithdrawn
    );

    event ClaimBonus(
        address indexed subscriberWallet,
        uint256 generationId,
        uint256 tokenId,
        uint256 amountWithdrawn
    );

    IERC20 internal immutable stackToken;
    GenerationManager internal immutable generations;
    DarkMatter internal immutable darkMatter;
    StableCoinAcceptor internal immutable stableAcceptor;
    Exchange internal immutable exchange;
    address internal immutable taxAddress;

    uint256 internal constant HUNDRED_PERCENT = 10000;
    uint256 public constant PRICE_PRECISION = 1e18; // how much decimals `price` has
    uint256 public constant MONTH = 30 days;

    uint256 public totalDeposited;
    uint256 public totalRewards;

    uint256 public dripPeriod;
    uint256 public forgivenessPeriod;
    uint256 public price; // price in USD
    uint256 public maxPrice;
    uint256 public bonusPercent;
    uint256 public taxReductionAmount;
    uint256 public currentPeriodId;
    uint256 public adminWithdrawable;
    bool public isOnlyFirstGeneration;

    enum withdrawStatus {
        withdraw,
        purchase
    }

    struct Period {
        uint256 balance; // total fees collected from mint
        uint256 withdrawn; // total fees withdrawn as rewards
        uint256 subsNum; // total subscribed tokens during this period
        uint256 endAt;   // when period ended, then subs can claim reward
        mapping(uint256 => mapping(uint256 => PeriodTokenData)) tokenData; // tokens related data, see struct 
    }

    struct PeriodTokenData {
        bool isSub;         // whether token is subscribed during period
        uint256 withdrawn;  // this is probably unchanged once written, and is equal to token's share in period
    }

    struct Bonus {
        uint256 total;
        uint256 lastTxDate;
        uint256 releasePeriod;
        uint256 lockedAmount;
    }

    struct Deposit {
        uint256 balance; // amount without bonus
        Bonus[] bonuses; // subscription bonuses
        uint256 tax; // tax percent on withdraw
        uint256 nextPayDate; // you can subscribe after this date, but before deadline to reduce tax
    }

    mapping(uint256 => Period) public periods;
    mapping(uint256 => mapping(uint256 => Deposit)) public deposits; // generationId => tokenId => Deposit
    mapping(uint256 => mapping(uint256 => uint256)) public bonusDripped; // generationId => tokenId => total bonuses unlocked

    modifier restrictGeneration(uint256 generationId) {
        requireCorrectGeneration(generationId);
        _;
    }

    constructor(
        IERC20 _stackToken,
        GenerationManager _generations,
        DarkMatter _darkMatter,
        StableCoinAcceptor _stableAcceptor,
        Exchange _exchange,
        address _taxAddress,
        uint256 _forgivenessPeriod,
        uint256 _price,
        uint256 _bonusPercent,
        uint256 _taxReductionAmount
    ) {
        stackToken = _stackToken;
        generations = _generations;
        darkMatter = _darkMatter;
        stableAcceptor = _stableAcceptor;
        exchange = _exchange;
        taxAddress = _taxAddress;
        forgivenessPeriod = _forgivenessPeriod;
        price = _price;
        bonusPercent = _bonusPercent;
        taxReductionAmount = _taxReductionAmount;
    }    
    
    /**
     * @notice If set, then only 1st generation allowed to use contract, 
     *         otherwise only generation 2 and onward can.
     * @dev Could only be invoked by the contract owner.
     */
    function setOnlyFirstGeneration() external onlyOwner {
        isOnlyFirstGeneration = true;
        emit SetOnlyFirstGeneration();
    }

    /**
     * @notice Set bonus drip period.
     * @param _seconds Amount of seconds required to fully release bonus.
     * @dev Could only be invoked by the contract owner.
     */
    function setDripPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Cant be zero");
        dripPeriod = _seconds;
        emit SetDripPeriod(_seconds);
    }

    /**
     * @notice Set subscription price.
     * @param _price New price in USD. Must have `PRICE_PRECISION` decimals.
     * @dev Could only be invoked by the contract owner.
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Cant be zero");
        price = _price;
        emit SetPrice(_price);
    }

    /**
     * @notice Set max subscription price, usde only if contract locked to 1st generation.
     * @param _maxPrice Max price in USD. Must have `PRICE_PRECISION` decimals.
     * @dev Could only be invoked by the contract owner.
     * @dev Max price unused in 2nd generation and onward.
     */
    function setMaxPrice(uint256 _maxPrice) external onlyOwner {
        require(_maxPrice > 0, "Cant be zero");
        maxPrice = _maxPrice;
        emit SetMaxPrice(_maxPrice);
    }

    /**
     * @notice Set bonus added for each subscription.
     * @param _percent Bonus percent.
     * @dev Could only be invoked by the contract owner.
     */
    function setBonusPercent(uint256 _percent) external onlyOwner {
        require(_percent <= HUNDRED_PERCENT, "invalid basis points");
        bonusPercent = _percent;
        emit SetBonusPercent(_percent);
    }

    /**
     * @notice Set tax reduction amount.
     * @param _amount Amount to subtract from tax on each subscribed month in a row.
     * @dev Could only be invoked by the contract owner.
     */
    function setTaxReductionAmount(uint256 _amount) external onlyOwner {
        require(_amount <= HUNDRED_PERCENT, "invalid basis points");
        taxReductionAmount = _amount;
        emit SetTaxReductionAmount(_amount);
    }

    /**
     * @notice Set forgiveness period for resubscribe to keep TAX reducing.
     * @param _seconds Amount of seconds.
     * @dev Could only be invoked by the contract owner.
     */
    function setForgivenessPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Cant be zero");
        forgivenessPeriod = _seconds;
        emit SetForgivenessPeriod(_seconds);
    }  
    
    /**
     * @dev Reverts if generationId doesn't match contract's desired generation.
     * @dev This is used in modifier.
     */
    function requireCorrectGeneration(uint256 generationId) internal view {
        if(isOnlyFirstGeneration)
            require(generationId == 0, "Generation should be 0");
        else
            require(generationId > 0, "Generation shouldn't be 0");
    }

    /**
     * @notice View periods.tokenData struct
     */
    function viewPeriodTokenData(
        uint256 periodId, 
        uint256 tokenId, 
        uint256 generationId
    ) external view returns (PeriodTokenData memory) {
        return periods[periodId].tokenData[tokenId][generationId];
    }

    /**
     *  @notice Pay subscription.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds StackNFT token ids.
     *  @param _payAmount Amount to pay for one token. Unused if `isOnlyFirstGeneration == false`.
     *  @param _stablecoin Address of supported stablecoin to pay with. Unused if `_payWithStack == true`.
     *  @param _payWithStack Whether to pay with STACK token.
     *  @dev Caller must approve us to spend `price` amount of `_stablecoin`.
     *  @dev If paying with stack, caller must approve stack amount worth of `price` in usd.
     */
    function subscribe(
        uint256 generationId,
        uint256[] calldata tokenIds,
        uint256 _payAmount,
        IERC20 _stablecoin,
        bool _payWithStack
    ) 
        public 
        nonReentrant 
        restrictGeneration(generationId)
    {
        require(tx.origin == msg.sender, "Only EOW");
        require(
            // don't validate stables when paying with stack
            _payWithStack || stableAcceptor.supportsCoin(_stablecoin), 
            "Unsupported stablecoin"
        );

        uint256 _price = price;
        if(isOnlyFirstGeneration) {
            _price = _payAmount;
            require(
                _payAmount >= price && _payAmount <= maxPrice, 
                "Wrong pay amount"
            );
        }

        updatePeriod();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(periods[currentPeriodId].tokenData[generationId][tokenId].isSub == false) {
                periods[currentPeriodId].subsNum += 1;
                periods[currentPeriodId].tokenData[generationId][tokenId].isSub = true;
            }

            _subscribe(generationId, tokenId, _price, _stablecoin, _payWithStack);
        }
    }

    function _subscribe(
        uint256 generationId,
        uint256 tokenId,
        uint256 _price,
        IERC20 _stablecoin,
        bool _payWithStack
    ) internal {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(
            generations.get(generationId).exists(tokenId), 
            "Token doesn't exists"
        );

        Deposit storage deposit = deposits[generationId][tokenId];
        require(deposit.nextPayDate < block.timestamp, "Cant pay in advance");

        // Paid after deadline?
        if (deposit.nextPayDate + forgivenessPeriod < block.timestamp) {
            deposit.tax = HUNDRED_PERCENT;
        }

        deposit.tax = subOrZero(deposit.tax, taxReductionAmount);
        deposit.nextPayDate = block.timestamp + MONTH;

        uint256 amount;
        if(_payWithStack) {
            _stablecoin = stableAcceptor.stablecoins(0);
            // price has 18 decimals, convert to stablecoin decimals
            _price = _price * 
                10 ** IDecimals(address(_stablecoin)).decimals() /
                PRICE_PRECISION;
            // get stack amount we need to sell to get `price` amount of usd
            amount = exchange.getAmountIn(
                _price, 
                _stablecoin, 
                stackToken
            );
            stackToken.transferFrom(msg.sender, address(this), amount);
        } else {
            // price has 18 decimals, convert to stablecoin decimals
            _price = _price * 
                10 ** IDecimals(address(_stablecoin)).decimals() /
                PRICE_PRECISION;
            _stablecoin.safeTransferFrom(msg.sender, address(this), _price);
            _stablecoin.approve(address(exchange), _price);
            amount = exchange.swapExactTokensForTokens(
                _price,
                _stablecoin,
                stackToken
            );
        }

        totalDeposited += amount;
        deposit.balance += amount;

        // bonuses logic
        updateBonuses(generationId, tokenId);
        uint256 bonusAmount = amount * bonusPercent / HUNDRED_PERCENT;
        deposit.bonuses.push(Bonus({
            total: bonusAmount,
            lastTxDate: block.timestamp,
            releasePeriod: dripPeriod,
            lockedAmount: bonusAmount
        }));
        emit Subscribe(
            msg.sender,
            deposit.nextPayDate,
            generationId,
            tokenId,
            _price,
            amount,
            bonusAmount,
            _stablecoin,
            _payWithStack,
            currentPeriodId
        );
    }

    /**
     *  @notice Start next period if its time.
     *  @dev Called automatically from other functions, but can be called manually.
     */
    function updatePeriod() public {
        if (periods[currentPeriodId].endAt < block.timestamp) {
            currentPeriodId += 1;
            periods[currentPeriodId].endAt = block.timestamp + MONTH;
            if(currentPeriodId > 3) {
                // subtract 4 because need to ignore current cycle + 3 cycles before it
                uint256 removeIndex = currentPeriodId - 4;
                uint256 leftOver = periods[removeIndex].balance - periods[removeIndex].withdrawn;
                adminWithdrawable += leftOver;
                totalRewards -= leftOver;
                periods[removeIndex].balance = 0;
                periods[removeIndex].withdrawn = 0;
            }
            emit NewPeriodStarted(currentPeriodId);
        }
    }

    /**
     *  @notice Handle fee sent from minting.
     *  @param _amount Amount of stack trying to receive.
     *  @return _isTransferred Whether fee received or not.
     *  @dev Called automatically from stack NFT contract, but can be called manually.
     *  @dev Will receive tokens if previous period has active subs.
     */
    function onReceiveStack(uint256 _amount) 
        external 
        returns 
        (bool _isTransferred) 
    {
        updatePeriod();

        if(periods[currentPeriodId - 1].subsNum == 0) {
            return false;
        } else {
            totalRewards += _amount;
            periods[currentPeriodId - 1].balance += _amount;
            stackToken.transferFrom(msg.sender, address(this), _amount);
        }
        return true;
    }

    /**
     *  @notice Withdraw active subs reward which comes from minting fees.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds StackNFT token ids.
     *  @dev Caller must own tokens.
     *  @dev Tokens should have subscription during periods.
     */
    function claimReward(
        uint256 generationId, 
        uint256[] calldata tokenIds
    )
        external
        nonReentrant
        restrictGeneration(generationId)
    {
        updatePeriod();
        require(currentPeriodId > 0, "Still first period");


        uint256 toWithdraw;
        uint256 periodId = subOrZero(currentPeriodId, 3);
        for (; periodId < currentPeriodId; periodId++) {
            Period storage period = periods[periodId];
            if (period.subsNum == 0) continue;
            
            uint256 share = period.balance / period.subsNum;

            for (uint256 i; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                require(
                    darkMatter.isOwnStackOrDarkMatter(
                        msg.sender,
                        generationId,
                        tokenId
                    ),
                    "Not owner"
                );
                if (!period.tokenData[generationId][tokenId].isSub) continue;
                uint256 amountWithdraw = (share - period.tokenData[generationId][tokenId].withdrawn);
                toWithdraw += amountWithdraw;
                period.tokenData[generationId][tokenId].withdrawn = share; 
                period.withdrawn += amountWithdraw;
            }

        }

        totalRewards -= toWithdraw;
        stackToken.transfer(msg.sender, toWithdraw);

        emit WithdrawRewards(
            msg.sender,
            toWithdraw,
            generationId, 
            tokenIds
        );
    }

    /**
     *  @dev Calculate dripped amount and remove fully released bonuses from array.
     */
    function updateBonuses(
        uint256 generationId,
        uint256 tokenId
    ) private {
        Deposit storage deposit = deposits[generationId][tokenId];
        // number of fully unlocked bonuses
        uint256 unlockedNum; 
        // current number of token's bonuses
        uint256 bonusesLength = deposit.bonuses.length;
        // total dripped of each bonus
        uint256 drippedAmount;

        for (uint256 i; i < bonusesLength; i++) {
            // this should saves gas, but probably not
            // in case where 0 fully unlocked bonuses
            Bonus memory bonus = deposit.bonuses[i];

            uint256 withdrawAmount = 
                (bonus.total / bonus.releasePeriod) * 
                (block.timestamp - bonus.lastTxDate);

            if (withdrawAmount > bonus.lockedAmount)
                withdrawAmount = bonus.lockedAmount;
            
            drippedAmount += withdrawAmount;
            bonus.lockedAmount -= withdrawAmount;
            bonus.lastTxDate = block.timestamp;

            // We need to remove all drained bonuses from the array.
            // If our array looks like this [+--+-] where - is drained bonuses,
            // then we move all - to be after all +, so we get [++---]
            // Then we can pop all - from the end of array.
            if(bonus.lockedAmount == 0) 
                unlockedNum += 1;
            else if(unlockedNum > 0)
                deposit.bonuses[i - unlockedNum] = bonus;
            else
                deposit.bonuses[i] = bonus;
        }
        bonusDripped[generationId][tokenId] += drippedAmount;

        for (uint256 i = unlockedNum; i > 0; i--) {
            deposit.bonuses.pop();
        }
    }

    /**
     *  @notice Withdraw deposit, accounting for tax.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds StackNFT token ids.
     *  @dev Caller must own `tokenIds`
     *  @dev Tax resets to maximum after withdraw.
     */
    function withdraw(
        uint256 generationId, 
        uint256[] calldata tokenIds
    )
        external
        nonReentrant
        restrictGeneration(generationId)
    {
        updatePeriod();
        for (uint256 i; i < tokenIds.length; i++) {
            _withdraw(
                generationId,
                tokenIds[i],
                withdrawStatus.withdraw,
                0,
                0
            );
        }
    }

   /**
    * @notice Purchase StackNFTs using money in deposit.
    * @param withdrawGenerationId StackNFT generation id to withdraw fee for.
    * @param withdrawTokenIds StackNFT token ids to withdraw fee for.
    * @param purchaseGenerationId Generation id to mint.
    * @param amountToMint Amount to mint.
    * @dev Tokens must be owned by the caller.
    * @dev Purchase Generation should be greater than 0.
    * @dev Function withdraw token subscription fee, then on received stack tokens
    *      it mints `amountToMint`, it will do this for every token in `tokenIds`.
    *      So if `withdrawTokenIds` has 2 subscribed tokens, and `amountToMint == 2`
    *      Then you'll receive 2 + 2 = 4 new tokens.
    */
    function purchaseNewNft(
        uint256 withdrawGenerationId,
        uint256[] calldata withdrawTokenIds,
        uint256 purchaseGenerationId,
        uint256 amountToMint
    ) 
        external 
        nonReentrant
        restrictGeneration(withdrawGenerationId)
    {
        require(tx.origin == msg.sender, "Only EOW");
        require(purchaseGenerationId > 0, "Cant purchase generation 0");
        updatePeriod();

        for (uint256 i; i < withdrawTokenIds.length; i++) {
            _withdraw(
                withdrawGenerationId,
                withdrawTokenIds[i],
                withdrawStatus.purchase,
                purchaseGenerationId,
                amountToMint
            );
        }
    }

    function _withdraw(
        uint256 generationId,
        uint256 tokenId,
        withdrawStatus allocationStatus,
        uint256 purchaseGenerationId,
        uint256 amountToMint
    ) internal {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(
            darkMatter.isOwnStackOrDarkMatter(
                msg.sender,
                generationId,
                tokenId
            ),
            "Not owner"
        );
        Deposit storage deposit = deposits[generationId][tokenId];

        uint256 amountWithdraw = deposit.balance;
        require(amountWithdraw > 0, "Already withdrawn");

        if (allocationStatus == withdrawStatus.purchase) {

            require(deposit.tax == 0, "Can only purchase when 0 tax");

            StackOsNFTBasic stack = StackOsNFTBasic(
                address(generations.get(purchaseGenerationId))
            );

            // some of the following should be on stack contract side, but code size limit...
            amountToMint = stack.clampToMaxSupply(amountToMint);

            // adjust decimals
            uint256 mintPrice = stack.mintPrice() * 
                (10 ** IDecimals(address(stableAcceptor.stablecoins(0))).decimals()) / 
                stack.PRICE_PRECISION();

            // convert usd to stack
            uint256 stackToSpend = exchange.getAmountIn(
                // get total amount usd needed to mint requested amount 
                (mintPrice * (10000 - stack.rewardDiscount()) / 10000) * amountToMint,
                stableAcceptor.stablecoins(0),
                stackToken
            );

            require(amountWithdraw > stackToSpend, "Not enough earnings");

            stackToken.transfer(
                address(stack), 
                stackToSpend 
            );

            stack.mintFromSubscriptionRewards(
                amountToMint, 
                stackToSpend, 
                msg.sender
            );

            // Add left over amount back to user's balance
            deposit.balance = amountWithdraw - stackToSpend;
            // decrease totals only by amount that we spend
            totalDeposited -= stackToSpend;

            emit PurchaseNewNft(
                msg.sender,
                generationId,
                tokenId,
                purchaseGenerationId,
                amountToMint
            );
        } else {

            // if not subscribed - max taxes
            if (deposit.nextPayDate + forgivenessPeriod < block.timestamp) {
                deposit.tax = HUNDRED_PERCENT - taxReductionAmount;
            }

            // decrease totals before we transfer tax
            totalDeposited -= amountWithdraw;

            // early withdraw tax
            if (deposit.tax > 0) {
                uint256 tax = amountWithdraw * deposit.tax / HUNDRED_PERCENT;
                amountWithdraw -= tax;
                stackToken.transfer(taxAddress, tax);
            }

            stackToken.transfer(msg.sender, amountWithdraw);
            deposit.tax = HUNDRED_PERCENT;
            deposit.balance = 0;

            emit Withdraw(
                msg.sender,
                generationId,
                tokenId,
                amountWithdraw
            );
        }
    }

    /**
     *  @notice Withdraw dripped bonuses.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds StackNFT token ids.
     *  @dev Caller must own `tokenIds`.
     */
    function claimBonus(
        uint256 generationId,
        uint256[] calldata tokenIds
    ) external {

        uint256 totalWithdraw;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(generationId < generations.count(), "Generation doesn't exist");
            require(
                darkMatter.isOwnStackOrDarkMatter(
                    msg.sender,
                    generationId,
                    tokenId
                ),
                "Not owner"
            );

            updateBonuses(generationId, tokenId);
            uint256 unlockedBonus = bonusDripped[generationId][tokenId];
            totalWithdraw += unlockedBonus;
            bonusDripped[generationId][tokenId] = 0;

            emit ClaimBonus(
                msg.sender,
                generationId,
                tokenId,
                unlockedBonus
            );
        }

        uint256 contractBalance = stackToken.balanceOf(address(this));
        require(
            // make sure bonus won't withdraw balances of deposits or rewards
            totalWithdraw <= 
                contractBalance - totalRewards - totalDeposited,
            "Bonus balance is too low"
        );
        stackToken.transfer(msg.sender, totalWithdraw);
    }

   /**
     * @notice Get pending bonus amount, locked amount, and longest timeLeft.
     * @param _generationId StackNFT generation id.
     * @param _tokenId StackNFT token id.
     * @return unlocked Withdrawable amount of bonuses
     * @return locked Locked amount of bonuses
     * @return timeLeft Per-bonus array containing time left to fully release locked amount
     */
    function pendingBonus(uint256 _generationId, uint256 _tokenId)
        external
        view
        returns (
            uint256 unlocked, 
            uint256 locked,
            uint256 timeLeft 
        )
    {
        Deposit memory deposit = deposits[_generationId][_tokenId];

        uint256 bonusesLength = deposit.bonuses.length;

        for (uint256 i; i < bonusesLength; i++) {
            Bonus memory bonus = deposit.bonuses[i];

            uint256 amount = 
                (bonus.total / bonus.releasePeriod) * 
                (block.timestamp - bonus.lastTxDate);

            if (amount > bonus.lockedAmount)
                amount = bonus.lockedAmount;

            unlocked += amount;
            bonus.lockedAmount -= amount;
            locked += bonus.lockedAmount;

            // find max timeleft
            uint256 _timeLeft = 
                bonus.releasePeriod * bonus.lockedAmount / bonus.total;

            if(_timeLeft > timeLeft) timeLeft = _timeLeft;
        }
        
        unlocked += bonusDripped[_generationId][_tokenId];
    }

   /**
     * @notice First elemement shows total claimable amount.
     * @notice Next elements shows claimable amount per next months.
     * @param _generationId StackNFT generation id.
     * @param _tokenId StackNFT token id.
     * @param months Amount of MONTHs to get drip rate for.
     */
    function monthlyDripRateBonus(
        uint256 _generationId, 
        uint256 _tokenId,
        uint256 months
    )
        external
        view
        returns (
            uint256[] memory dripRates
        )
    {
        Deposit memory deposit = deposits[_generationId][_tokenId];

        uint256 bonusesLength = deposit.bonuses.length;
        uint256[] memory monthlyDrip = new uint256[](months);

        uint256 month = MONTH;
        uint256 blockTimestamp = block.timestamp;

        // +1 because we want skip first element
        // as it shows us unlocked amount
        for (uint256 m; m < months+1; m++) {

            uint256 unlocked; 

            for (uint256 i; i < bonusesLength; i++) {
                Bonus memory bonus = deposit.bonuses[i];

                if(bonus.lockedAmount == 0) continue;

                uint256 amount = 
                    (bonus.total / bonus.releasePeriod) * 
                    (blockTimestamp - bonus.lastTxDate);

                if(m == 0)
                    bonus.lastTxDate = blockTimestamp;
                else
                    bonus.lastTxDate += month;

                if (amount > bonus.lockedAmount)
                    amount = bonus.lockedAmount;

                unlocked += amount;
                bonus.lockedAmount -= amount;
            }
            blockTimestamp += month;
            if(m > 0)
                monthlyDrip[m-1] = unlocked;
            unlocked = 0;
        }
        dripRates = monthlyDrip;
    }

    /**
     *  @notice Get active subs pending reward.
     *  @param generationId StackNFT generation id.
     *  @param tokenIds StackNFT token id.
     *  @dev Unsubscribed tokens in period are ignored.
     */
    function pendingReward(
        uint256 generationId, 
        uint256[] calldata tokenIds
    )
        external
        view
        returns(uint256 withdrawableAmount)
    {
        uint256 _currentPeriodId = currentPeriodId;
        if (periods[_currentPeriodId].endAt < block.timestamp) {
            _currentPeriodId += 1;
        }
        require(_currentPeriodId > 0, "Still first period");

        uint256 toWithdraw;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            uint256 periodId = subOrZero(_currentPeriodId, 3);
            for (; periodId < _currentPeriodId; periodId++) {
                Period storage period = periods[periodId];
                if(period.subsNum == 0) continue;
                if(!period.tokenData[generationId][tokenId].isSub) continue;
                        
                uint256 share = period.balance / period.subsNum;
                toWithdraw += (share - period.tokenData[generationId][tokenId].withdrawn);
            }
        }
        return toWithdraw;
    }

    function adminWithdraw()
        external
        onlyOwner
    {
        require(adminWithdrawable > 0, "Nothing to withdraw");
        stackToken.transfer(msg.sender, adminWithdrawable);
        adminWithdrawable = 0;
    }

    /**
     *  @dev Subtract function, on underflow returns zero.
     */
    function subOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStackOsNFT is IERC721 {

    function whitelist(address _addr) external;

    function getMaxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function exists(uint256 _tokenId) external returns (bool);

    function setBaseURI(string calldata _uri) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {

    mapping(address => bool) public _whitelist;
 
    modifier onlyWhitelisted () {
        require(_whitelist[_msgSender()], "Not whitelisted for transfers");
        _;
    }

    /**
     *  @notice Whitelist address to transfer tokens.
     *  @param _addres Address to whitelist.
     *  @dev Caller must be owner of the contract.
     */
    function whitelist(address _addres) public onlyOwner {
        _whitelist[_addres] = true;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDecimals {
    function decimals() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GenerationManager.sol";
import "./DarkMatter.sol";
import "./interfaces/IStackOsNFT.sol";
import "./interfaces/IStackOsNFTBasic.sol";
import "./Exchange.sol";

contract Royalty is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    event SetFeeAddress(address payable _feeAddress);
    event SetWETH(IERC20 WETH);
    event SetFeePercent(uint256 _percent);
    event SetMinEthPerCycle(uint256 amount);
    event NewCycle(uint256 newCycleId);
    event SetCycleDuration(uint256 _seconds);

    Counters.Counter public counter; // counting cycles

    uint256 private constant HUNDRED_PERCENT = 10000;
    GenerationManager private immutable generations;
    DarkMatter private immutable darkMatter;
    Exchange private immutable exchange;
    IERC20 private WETH; // for Matic network
    address payable private feeAddress;
    IERC20 private stackToken;
    uint256 private feePercent;

    uint256 public minEthPerCycle;
    uint256 public cycleDuration = 30 days;

    uint256 public adminWithdrawable;

    struct GenData {
        // total received by each generation in cycle
        uint256 balance;
        // whether reward for this token in this cycle for this generation is claimed
        mapping(uint256 => mapping(uint256 => bool)) isClaimed; 
    }

    struct Cycle {
        // cycle started timestamp
        uint256 startTimestamp; 
        // this is used in admin withdrawable
        // and for cycle ending condition
        uint256 totalBalance; 
        // per generation balance
        mapping(uint256 => GenData) genData; 
    }

    mapping(uint256 => Cycle) public cycles; 
    // generationId => total maxSupply of generations below plus this one
    mapping(uint256 => uint256) public maxSupplys; 

    constructor(
        GenerationManager _generations,
        DarkMatter _darkMatter,
        Exchange _exchange,
        address payable _feeAddress,
        IERC20 _stackToken,
        uint256 _minEthPerCycle
    ) {
        generations = _generations;
        darkMatter = _darkMatter;
        exchange = _exchange;
        feeAddress = _feeAddress;
        stackToken = _stackToken;
        minEthPerCycle = _minEthPerCycle;

        cycles[counter.current()].startTimestamp = block.timestamp;
    }

    /** 
     * @notice Deposit royalty so that NFT holders can claim it later.
     * @notice Deposits to the latest generation at this time,
     *         so that any generation below can claim that.
     */
    receive() external payable {

        uint256 generationId = generations.count() - 1;

        // take fee from deposits
        uint256 feePart = msg.value * feePercent / HUNDRED_PERCENT;
        uint256 valuePart = msg.value - feePart;

        updateCycle();

        cycles[counter.current()].totalBalance += valuePart;
        cycles[counter.current()].genData[generationId].balance += valuePart;

        (bool success, ) = feeAddress.call{value: feePart}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Deposit royalty so that NFT holders can claim it later.
     * @param generationId Which generation balance receives royalty.
     */
    function onReceive(uint256 generationId) external payable nonReentrant {
        require(generationId < generations.count(), "Wrong generationId");

        // take fee from deposits
        uint256 feePart = msg.value * feePercent / HUNDRED_PERCENT;
        uint256 valuePart = msg.value - feePart;

        updateCycle();

        cycles[counter.current()].totalBalance += valuePart;
        cycles[counter.current()].genData[generationId].balance += valuePart;

        (bool success, ) = feeAddress.call{value: feePart}("");
        require(success, "Transfer failed.");
    }

    function updateCycle() private {
        // is current cycle lasts enough?
        if (
            cycles[counter.current()].startTimestamp + cycleDuration <
            block.timestamp
        ) {
            // is current cycle got enough ether?
            if (cycles[counter.current()].totalBalance >= minEthPerCycle) {
                // start new cycle
                counter.increment();
                cycles[counter.current()].startTimestamp = block.timestamp;

                if(counter.current() > 3) {
                    // subtract 4 because need to ignore current cycle + 3 cycles before it
                    uint256 removeIndex = counter.current() - 4;
                    adminWithdrawable += cycles[removeIndex].totalBalance;
                    cycles[removeIndex].totalBalance = 0;
                }

                emit NewCycle(counter.current());
            }
        }
    }

    function genDataBalance(
        uint256 cycleId,
        uint256 generationFeeBalanceId
    ) 
        external 
        view
        returns (uint256) 
    {
        return cycles[cycleId].genData[generationFeeBalanceId].balance;
    }

    function isClaimed(
        uint256 cycleId,
        uint256 generationFeeBalanceId,
        uint256 generationId,
        uint256 tokenId
    ) 
        external 
        view
        returns (bool) 
    {
        return cycles[cycleId]
                .genData[generationFeeBalanceId]
                    .isClaimed[generationId][tokenId];
    }

    /**
     * @dev Save total max supply of all preveious generations + added one. 
     */
    function onGenerationAdded(
        uint256 generationId, 
        address stack
    ) external {
        require(address(msg.sender) == address(generations));
        if(generationId == 0) {
            maxSupplys[generationId] = IStackOsNFT(stack).getMaxSupply();
        } else {
            maxSupplys[generationId] =
                maxSupplys[generationId - 1] + IStackOsNFT(stack).getMaxSupply();
        }
    }

    /**
     * @notice Set cycle duration.
     * @dev Could only be invoked by the contract owner.
     */
    function setCycleDuration(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Must be not zero");
        cycleDuration = _seconds;
        emit SetCycleDuration(_seconds);
    }   

    /**
     * @notice Set fee address.
     * @notice Fee transferred when contract receives new royalties.
     * @param _feeAddress Fee address.
     * @dev Could only be invoked by the contract owner.
     */
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "Must be not zero-address");
        feeAddress = _feeAddress;
        emit SetFeeAddress(_feeAddress);
    }    

    /**
     * @notice Set WETH address.
     * @notice Used to claim royalty in weth instead of matic.
     * @param _WETH WETH address.
     * @dev Could only be invoked by the contract owner.
     */
    function setWETH(IERC20 _WETH) external onlyOwner {
        require(address(_WETH) != address(0), "Must be not zero-address");
        WETH = _WETH;
        emit SetWETH(_WETH);
    }

    /**
     * @notice Set minimum eth needed to end cycle.
     * @param amount Amount of eth.
     * @dev Could only be invoked by the contract owner.
     */
    function setMinEthPerCycle(uint256 amount) external onlyOwner {
        require(amount > 0);
        minEthPerCycle = amount;
        emit SetMinEthPerCycle(amount);
    }

    /**
     * @notice Set fee percent taken everytime royalties recieved.
     * @param _percent Fee basis points.
     * @dev Could only be invoked by the contract owner.
     */
    function setFeePercent(uint256 _percent) external onlyOwner {
        require(feePercent <= HUNDRED_PERCENT, "invalid fee basis points");
        feePercent = _percent;
        emit SetFeePercent(_percent);
    }

    /**
     * @notice Claim royalty for tokens.
     * @param _generationId Generation id of tokens that will claim royalty.
     * @param _tokenIds Token ids who will claim royalty.
     * @param _genIds Ids of generation balances to claim royalties.
     * @dev Tokens must be owned by the caller.
     * @dev When generation tranded on market, fee is transferred to
     *      dedicated balance of this generation in royalty contract (_genIds).
     *      Then tokens that have lower generation id can claim part of this.
     *      So token of generation 1 can claim from genId 1,2,3.
     *      But token of generation 5 can't claim from genId 1.
     */
    function claim(
        uint256 _generationId, 
        uint256[] calldata _tokenIds,
        uint256[] calldata _genIds
    )
        external
        nonReentrant
    {
        _claim(_generationId, _tokenIds, 0, false, _genIds);
    }

    /**
     * @notice Same as `claim` but caller receives WETH.
     * @dev WETH address must be set in the contract.
     */
    function claimWETH(
        uint256 _generationId, 
        uint256[] calldata _tokenIds,
        uint256[] calldata _genIds
    )
        external
        nonReentrant
    {
        require(address(WETH) != address(0), "Wrong WETH address");
        _claim(_generationId, _tokenIds, 0, true, _genIds);
    }

    /**
     * @notice Purchase StackNFTs for royalties.
     * @notice Caller will receive the left over amount of royalties as STACK tokens.
     * @param _generationId Generation id to claim royalty and purchase, should be greater than 0.
     * @param _tokenIds Token ids that claim royalty.
     * @param _mintNum Amount to mint.
     * @param _genIds Ids of generation balances to claim royalties.
     * @dev Tokens must be owned by the caller.
     * @dev `_generationId` should be greater than 0.
     * @dev See `claim` function description for info on `_genIds`.
     */
    function purchaseNewNft(
        uint256 _generationId,
        uint256[] calldata _tokenIds,
        uint256 _mintNum,
        uint256[] calldata _genIds
    ) 
        external 
        nonReentrant 
    {
        require(tx.origin == msg.sender, "Only EOW");
        require(_generationId > 0, "Must be not first generation");
        require(_mintNum > 0, "Mint num is 0");
        _claim(_generationId, _tokenIds, _mintNum, false, _genIds);
    }

    function _claim(
        uint256 generationId,
        uint256[] calldata tokenIds,
        uint256 _mintNum,
        bool _claimWETH,
        uint256[] calldata _genIds
    ) internal {
        require(_genIds.length > 0, "No gen ids");
        require(address(this).balance > 0, "No royalty");
        IStackOsNFTBasic stack = 
            IStackOsNFTBasic(address(generations.get(generationId)));

        updateCycle();


        require(counter.current() > 0, "Still first cycle");

        uint256 reward;

        // iterate over tokens from args
        for (uint256 i; i < tokenIds.length; i++) {
            
            require(
                darkMatter.isOwnStackOrDarkMatter(
                    msg.sender,
                    generationId,
                    tokenIds[i]
                ),
                "Not owner"
            );

            reward += calcReward(generationId, tokenIds[i], _genIds);
        }

        require(reward > 0, "Nothing to claim");

        if (_mintNum == 0) {
            if(_claimWETH) {
                uint256 wethReceived = exchange.swapExactETHForTokens{value: reward}(WETH);
                WETH.safeTransfer(msg.sender, wethReceived);
            } else {
                (bool success, ) = payable(msg.sender).call{value: reward}(
                    ""
                );
                require(success, "Transfer failed");
            }
        } else {
            uint256 stackReceived = 
                exchange.swapExactETHForTokens{value: reward}(stackToken);
            stackToken.approve(address(stack), stackReceived);


            uint256 spendAmount = stack.mintFromRoyaltyRewards(
                _mintNum,
                msg.sender
            );
            stackToken.transfer(msg.sender, stackReceived - spendAmount);
        }

    }

    function calcReward(
        uint256 generationId,
        uint256 tokenId,
        uint256[] calldata _genIds
    )
        private 
        returns (uint256 reward) 
    {
        for (uint256 o = 1; o <= 3; o++) {
            uint256 cycleId = counter.current() - o;

            uint256 removeFromCycle;
            for (uint256 j; j < _genIds.length; j++) {
                require(_genIds[j] >= generationId, "Bad gen id");
                require(_genIds[j] < generations.count(), "genId not exists");
                GenData storage genData = cycles[cycleId].genData[_genIds[j]];

                if (
                    genData.balance > 0 &&
                    genData.isClaimed[generationId][tokenId] == false
                ) {
                    uint256 claimAmount = genData.balance / maxSupplys[_genIds[j]];
                    reward += claimAmount;
                    removeFromCycle += claimAmount;

                    genData.isClaimed[generationId][tokenId] = true;
                }
            }

            cycles[cycleId].totalBalance -= removeFromCycle;
            if(cycleId == 0) break;
        }
    }

    /**
     * @notice Get pending royalty for NFT.
     * @param generationId StackOS generation id.
     * @param tokenIds Token ids.
     * @return withdrawableRoyalty Total withdrawable royalty from all cycles and all balances.
     */
    function pendingRoyalty(
        uint256 generationId,
        uint256[] calldata tokenIds
    ) external view returns (uint256 withdrawableRoyalty) {
        require(generationId < generations.count(), "Wrong generation id");

        uint256 _counterCurrent = counter.current();
        if (
            cycles[_counterCurrent].startTimestamp + cycleDuration <
            block.timestamp
        ) {
            if (cycles[_counterCurrent].totalBalance >= minEthPerCycle) {
                _counterCurrent ++;
            }
        }

        require(_counterCurrent > 0, "Still first cycle");
        uint256 reward;

        // iterate over tokens from args
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            for (uint256 o = 1; o <= 3; o++) {
                uint256 cycleId = _counterCurrent - o;
                // j is pool id, should be greater or equal than token generation
                for (uint256 j = generationId; j < generations.count(); j++) {

                    GenData storage genData = cycles[cycleId].genData[j];
                    if (
                        genData.balance > 0 &&
                        // verify reward is unclaimed
                        genData.isClaimed[generationId][tokenId] == false
                    ) {
                        reward += genData.balance / maxSupplys[j];
                    }
                }

                if(cycleId == 0) break;
            }
        }

        withdrawableRoyalty = reward;
    }

    function adminWithdraw()
        external
        onlyOwner
    {
        require(adminWithdrawable > 0, "Nothing to withdraw");
        uint256 amount = adminWithdrawable;
        adminWithdrawable = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}(
            ""
        );
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IStackOsNFT.sol";

interface IStackOsNFTBasic is IStackOsNFT {

    function setName(
        string memory name_
    ) external;

    function setSymbol(
        string memory symbol_
    ) external;

    function mintFromSubscriptionRewards(
        uint256 _nftAmount,
        uint256 _stackAmount,
        address _to
    ) external;

    function mintFromRoyaltyRewards(
        uint256 _mintNum,
        address _to
    ) external returns (uint256);

    function mintPrice()
        external
        view
        returns (uint256);

    function PRICE_PRECISION()
        external
        view
        returns (uint256);

    function rewardDiscount()
        external
        view
        returns (uint256);

    function transferFromLastGen(address _ticketOwner, uint256 _amount)
        external;
}