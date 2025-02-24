// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import "./MinimalProxyFactory.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AelinDeal} from "./AelinDeal.sol";
import {AelinPool} from "./AelinPool.sol";
import {AelinFeeEscrow} from "./AelinFeeEscrow.sol";
import {IAelinUpFrontDeal} from "./interfaces/IAelinUpFrontDeal.sol";
import "./libraries/AelinNftGating.sol";
import "./libraries/AelinAllowList.sol";
import "./libraries/MerkleTree.sol";

contract AelinUpFrontDeal is AelinERC20, MinimalProxyFactory, IAelinUpFrontDeal {
    using SafeERC20 for IERC20;

    uint256 constant BASE = 100 * 10**18;
    uint256 constant MAX_SPONSOR_FEE = 15 * 10**18;
    uint256 constant AELIN_FEE = 2 * 10**18;

    UpFrontDealData public dealData;
    UpFrontDealConfig public dealConfig;

    address public aelinTreasuryAddress;
    address public aelinEscrowLogicAddress;
    AelinFeeEscrow public aelinFeeEscrow;
    address public dealFactory;

    MerkleTree.TrackClaimed private trackClaimed;
    AelinAllowList.AllowList public allowList;
    AelinNftGating.NftGatingData public nftGating;
    mapping(address => uint256) public purchaseTokensPerUser;
    mapping(address => uint256) public poolSharesPerUser;
    mapping(address => uint256) public amountVested;

    uint256 public totalPurchasingAccepted;
    uint256 public totalPoolShares;
    uint256 public totalUnderlyingClaimed;

    bool private underlyingDepositComplete;
    bool private sponsorClaimed;
    bool private holderClaimed;
    bool private feeEscrowClaimed;

    bool private calledInitialize;
    address public futureHolder;

    uint256 public dealStart;
    uint256 public purchaseExpiry;
    uint256 public vestingCliffExpiry;
    uint256 public vestingExpiry;

    /**
     * @dev initializes the contract configuration, called from the factory contract when creating a new Up Front Deal
     */
    function initialize(
        UpFrontDealData calldata _dealData,
        UpFrontDealConfig calldata _dealConfig,
        AelinNftGating.NftCollectionRules[] calldata _nftCollectionRules,
        AelinAllowList.InitData calldata _allowListInit,
        address _aelinTreasuryAddress,
        address _aelinEscrowLogicAddress
    ) external initOnce {
        // pool initialization checks
        require(_dealData.purchaseToken != _dealData.underlyingDealToken, "purchase & underlying the same");
        require(_dealData.purchaseToken != address(0), "cant pass null purchase address");
        require(_dealData.underlyingDealToken != address(0), "cant pass null underlying address");
        require(_dealData.holder != address(0), "cant pass null holder address");

        require(_dealConfig.purchaseDuration >= 30 minutes && _dealConfig.purchaseDuration <= 30 days, "not within limit");
        require(_dealData.sponsorFee <= MAX_SPONSOR_FEE, "exceeds max sponsor fee");

        uint8 purchaseTokenDecimals = IERC20Decimals(_dealData.purchaseToken).decimals();

        require(1825 days >= _dealConfig.vestingCliffPeriod, "max 5 year cliff");
        require(1825 days >= _dealConfig.vestingPeriod, "max 5 year vesting");

        require(_dealConfig.underlyingDealTokenTotal > 0, "must have nonzero deal tokens");
        require(_dealConfig.purchaseTokenPerDealToken > 0, "invalid deal price");

        uint8 underlyingTokenDecimals = IERC20Decimals(_dealData.underlyingDealToken).decimals();
        require(purchaseTokenDecimals <= underlyingTokenDecimals, "purchase token not compatible");
        if (_dealConfig.purchaseRaiseMinimum > 0) {
            uint256 _totalIntendedRaise = (_dealConfig.purchaseTokenPerDealToken * _dealConfig.underlyingDealTokenTotal) /
                10**underlyingTokenDecimals;
            require(_totalIntendedRaise > 0, "intended raise too small");
            require(_dealConfig.purchaseRaiseMinimum <= _totalIntendedRaise, "raise min > deal total");
        }

        // store pool and deal details as state variables
        dealData = _dealData;
        dealConfig = _dealConfig;

        dealStart = block.timestamp;

        dealFactory = msg.sender;

        // the deal token has the same amount of decimals as the underlying deal token,
        // eventually making them 1:1 redeemable
        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aeUpFrontDeal-", _dealData.name)),
            string(abi.encodePacked("aeUD-", _dealData.symbol)),
            underlyingTokenDecimals
        );

        aelinEscrowLogicAddress = _aelinEscrowLogicAddress;
        aelinTreasuryAddress = _aelinTreasuryAddress;

        // Allow list logic
        // check if there's allowlist and amounts,
        // if yes, store it to `allowList` and emit a single event with the addresses and amounts
        AelinAllowList.initialize(_allowListInit, allowList);

        // NftCollection logic
        // check if the deal is nft gated
        // if yes, store it in `nftCollectionDetails` and `nftId` and emit respective events for 721 and 1155
        AelinNftGating.initialize(_nftCollectionRules, nftGating);

        require(!(allowList.hasAllowList && nftGating.hasNftList), "cant have allow list & nft");
        require(!(allowList.hasAllowList && dealData.merkleRoot != 0), "cant have allow list & merkle");
        require(!(nftGating.hasNftList && dealData.merkleRoot != 0), "cant have nft & merkle");
        require(!(bytes(dealData.ipfsHash).length == 0 && dealData.merkleRoot != 0), "merkle needs ipfs hash");
    }

    function _startPurchasingPeriod(
        uint256 _purchaseDuration,
        uint256 _vestingCliffPeriod,
        uint256 _vestingPeriod
    ) internal {
        underlyingDepositComplete = true;
        purchaseExpiry = block.timestamp + _purchaseDuration;
        vestingCliffExpiry = purchaseExpiry + _vestingCliffPeriod;
        vestingExpiry = vestingCliffExpiry + _vestingPeriod;
        emit DealFullyFunded(address(this), block.timestamp, purchaseExpiry, vestingCliffExpiry, vestingExpiry);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only init once");
        calledInitialize = true;
        _;
    }

    /**
     * @dev method for holder to deposit underlying deal tokens
     * all underlying deal tokens must be deposited for the purchasing period to start
     * if tokens were deposited directly, this method must still be called to start the purchasing period
     * @param _depositUnderlyingAmount how many underlying tokens the holder will transfer to the contract
     */
    function depositUnderlyingTokens(uint256 _depositUnderlyingAmount) public onlyHolder {
        address _underlyingDealToken = dealData.underlyingDealToken;

        require(IERC20(_underlyingDealToken).balanceOf(msg.sender) >= _depositUnderlyingAmount, "not enough balance");
        require(!underlyingDepositComplete, "already deposited the total");

        uint256 balanceBeforeTransfer = IERC20(_underlyingDealToken).balanceOf(address(this));
        IERC20(_underlyingDealToken).safeTransferFrom(msg.sender, address(this), _depositUnderlyingAmount);
        uint256 balanceAfterTransfer = IERC20(_underlyingDealToken).balanceOf(address(this));
        uint256 underlyingDealTokenAmount = balanceAfterTransfer - balanceBeforeTransfer;

        if (balanceAfterTransfer >= dealConfig.underlyingDealTokenTotal) {
            _startPurchasingPeriod(dealConfig.purchaseDuration, dealConfig.vestingCliffPeriod, dealConfig.vestingPeriod);
        }

        emit DepositDealToken(_underlyingDealToken, msg.sender, underlyingDealTokenAmount);
    }

    /**
     * @dev allows holder to withdraw any excess underlying deal tokens deposited to the contract
     */
    function withdrawExcess() external onlyHolder {
        address _underlyingDealToken = dealData.underlyingDealToken;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
        uint256 currentBalance = IERC20(_underlyingDealToken).balanceOf(address(this));
        require(currentBalance > _underlyingDealTokenTotal, "no excess to withdraw");

        uint256 excessAmount = currentBalance - _underlyingDealTokenTotal;
        IERC20(_underlyingDealToken).safeTransfer(msg.sender, excessAmount);

        emit WithdrewExcess(address(this), excessAmount);
    }

    /**
     * @dev accept deal by depositing purchasing tokens which is converted to a mapping which stores the amount of
     * underlying purchased. pool shares have the same decimals as the underlying deal token
     * @param _nftPurchaseList NFTs to use for accepting the deal if deal is NFT gated
     * @param _merkleData Merkle Proof data to prove investors allocation
     * @param _purchaseTokenAmount how many purchase tokens will be used to purchase deal token shares
     */
    function acceptDeal(
        AelinNftGating.NftPurchaseList[] calldata _nftPurchaseList,
        MerkleTree.UpFrontMerkleData calldata _merkleData,
        uint256 _purchaseTokenAmount
    ) external lock {
        require(underlyingDepositComplete, "deal token not deposited");
        require(block.timestamp < purchaseExpiry, "not in purchase window");

        address _purchaseToken = dealData.purchaseToken;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
        uint256 _purchaseTokenPerDealToken = dealConfig.purchaseTokenPerDealToken;
        require(IERC20(_purchaseToken).balanceOf(msg.sender) >= _purchaseTokenAmount, "not enough purchaseToken");

        if (nftGating.hasNftList || _nftPurchaseList.length > 0) {
            AelinNftGating.purchaseDealTokensWithNft(_nftPurchaseList, nftGating, _purchaseTokenAmount);
        } else if (allowList.hasAllowList) {
            require(_purchaseTokenAmount <= allowList.amountPerAddress[msg.sender], "more than allocation");
            allowList.amountPerAddress[msg.sender] -= _purchaseTokenAmount;
        } else if (dealData.merkleRoot != 0) {
            MerkleTree.purchaseMerkleAmount(_merkleData, trackClaimed, _purchaseTokenAmount, dealData.merkleRoot);
        }

        uint256 balanceBeforeTransfer = IERC20(_purchaseToken).balanceOf(address(this));
        IERC20(_purchaseToken).safeTransferFrom(msg.sender, address(this), _purchaseTokenAmount);
        uint256 balanceAfterTransfer = IERC20(_purchaseToken).balanceOf(address(this));
        uint256 purchaseTokenAmount = balanceAfterTransfer - balanceBeforeTransfer;

        totalPurchasingAccepted += purchaseTokenAmount;
        purchaseTokensPerUser[msg.sender] += purchaseTokenAmount;

        uint8 underlyingTokenDecimals = IERC20Decimals(dealData.underlyingDealToken).decimals();
        uint256 poolSharesAmount;

        // this takes into account the decimal conversion between purchasing token and underlying deal token
        // pool shares having the same amount of decimals as underlying deal tokens
        poolSharesAmount = (purchaseTokenAmount * 10**underlyingTokenDecimals) / _purchaseTokenPerDealToken;
        require(poolSharesAmount > 0, "purchase amount too small");

        // pool shares directly correspond to the amount of deal tokens that can be minted
        // pool shares held = deal tokens minted as long as no deallocation takes place
        totalPoolShares += poolSharesAmount;
        poolSharesPerUser[msg.sender] += poolSharesAmount;

        if (!dealConfig.allowDeallocation) {
            require(totalPoolShares <= _underlyingDealTokenTotal, "purchased amount > total");
        }

        emit AcceptDeal(
            msg.sender,
            purchaseTokenAmount,
            purchaseTokensPerUser[msg.sender],
            poolSharesAmount,
            poolSharesPerUser[msg.sender]
        );
    }

    /**
     * @dev purchaser calls to claim their deal tokens or refund if the minimum raise does not pass
     */
    function purchaserClaim() public lock purchasingOver {
        require(poolSharesPerUser[msg.sender] > 0, "no pool shares to claim with");

        address _purchaseToken = dealData.purchaseToken;
        uint256 _purchaseRaiseMinimum = dealConfig.purchaseRaiseMinimum;

        if (_purchaseRaiseMinimum == 0 || totalPurchasingAccepted > _purchaseRaiseMinimum) {
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
            // Claim Deal Tokens
            bool deallocate = totalPoolShares > _underlyingDealTokenTotal;

            if (deallocate) {
                // adjust for deallocation and mint deal tokens
                uint256 adjustedDealTokensForUser = (((poolSharesPerUser[msg.sender] * _underlyingDealTokenTotal) /
                    totalPoolShares) * (BASE - AELIN_FEE - dealData.sponsorFee)) / BASE;
                poolSharesPerUser[msg.sender] = 0;

                // refund any purchase tokens that got deallocated
                uint256 purchasingRefund = purchaseTokensPerUser[msg.sender] -
                    ((purchaseTokensPerUser[msg.sender] * _underlyingDealTokenTotal) / totalPoolShares);
                purchaseTokensPerUser[msg.sender] = 0;

                uint256 precisionAdjustedRefund = purchasingRefund > IERC20(_purchaseToken).balanceOf(address(this))
                    ? IERC20(_purchaseToken).balanceOf(address(this))
                    : purchasingRefund;

                // mint deal tokens and transfer purchase token refund
                _mint(msg.sender, adjustedDealTokensForUser);
                IERC20(_purchaseToken).safeTransfer(msg.sender, precisionAdjustedRefund);

                emit ClaimDealTokens(msg.sender, adjustedDealTokensForUser, precisionAdjustedRefund);
            } else {
                // mint deal tokens when there is no deallocation
                uint256 adjustedDealTokensForUser = ((BASE - AELIN_FEE - dealData.sponsorFee) *
                    poolSharesPerUser[msg.sender]) / BASE;
                poolSharesPerUser[msg.sender] = 0;
                purchaseTokensPerUser[msg.sender] = 0;
                _mint(msg.sender, adjustedDealTokensForUser);
                emit ClaimDealTokens(msg.sender, adjustedDealTokensForUser, 0);
            }
        } else {
            // Claim Refund
            uint256 currentBalance = purchaseTokensPerUser[msg.sender];
            purchaseTokensPerUser[msg.sender] = 0;
            poolSharesPerUser[msg.sender] = 0;
            IERC20(_purchaseToken).safeTransfer(msg.sender, currentBalance);
            emit ClaimDealTokens(msg.sender, 0, currentBalance);
        }
    }

    /**
     * @dev sponsor calls once the purchasing period is over if the minimum raise has passed to claim
     * their share of deal tokens
     * NOTE also calls the claim for the protocol fee
     */
    function sponsorClaim() public lock purchasingOver passMinimumRaise onlySponsor {
        require(!sponsorClaimed, "sponsor already claimed");
        sponsorClaimed = true;

        address _sponsor = dealData.sponsor;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

        uint256 totalSold = totalPoolShares > _underlyingDealTokenTotal ? _underlyingDealTokenTotal : totalPoolShares;
        uint256 _sponsorFeeAmt = (totalSold * dealData.sponsorFee) / BASE;
        _mint(_sponsor, _sponsorFeeAmt);
        emit SponsorClaim(_sponsor, _sponsorFeeAmt);

        if (!feeEscrowClaimed) {
            feeEscrowClaim();
        }
    }

    /**
     * @dev holder calls once purchasing period is over to claim their raise or
     * underlying deal tokens if the minimum raise has not passed
     * NOTE also calls the claim for the protocol fee
     */
    function holderClaim() public lock purchasingOver onlyHolder {
        require(!holderClaimed, "holder already claimed");
        holderClaimed = true;

        address _holder = dealData.holder;
        address _underlyingDealToken = dealData.underlyingDealToken;
        address _purchaseToken = dealData.purchaseToken;
        uint256 _purchaseRaiseMinimum = dealConfig.purchaseRaiseMinimum;

        if (_purchaseRaiseMinimum == 0 || totalPurchasingAccepted > _purchaseRaiseMinimum) {
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

            bool deallocate = totalPoolShares > _underlyingDealTokenTotal;
            if (deallocate) {
                uint256 _underlyingTokenDecimals = IERC20Decimals(_underlyingDealToken).decimals();
                uint256 _totalIntendedRaise = (dealConfig.purchaseTokenPerDealToken * _underlyingDealTokenTotal) /
                    10**_underlyingTokenDecimals;

                uint256 precisionAdjustedRaise = _totalIntendedRaise > IERC20(_purchaseToken).balanceOf(address(this))
                    ? IERC20(_purchaseToken).balanceOf(address(this))
                    : _totalIntendedRaise;

                IERC20(_purchaseToken).safeTransfer(_holder, precisionAdjustedRaise);
                emit HolderClaim(_holder, _purchaseToken, precisionAdjustedRaise, _underlyingDealToken, 0, block.timestamp);
            } else {
                // holder receives raise
                uint256 _currentBalance = IERC20(_purchaseToken).balanceOf(address(this));
                IERC20(_purchaseToken).safeTransfer(_holder, _currentBalance);
                // holder receives any leftover underlying deal tokens
                uint256 _underlyingRefund = _underlyingDealTokenTotal - totalPoolShares;
                IERC20(_underlyingDealToken).safeTransfer(_holder, _underlyingRefund);
                emit HolderClaim(
                    _holder,
                    _purchaseToken,
                    _currentBalance,
                    _underlyingDealToken,
                    _underlyingRefund,
                    block.timestamp
                );
            }
            if (!feeEscrowClaimed) {
                feeEscrowClaim();
            }
        } else {
            uint256 _currentBalance = IERC20(_underlyingDealToken).balanceOf(address(this));
            IERC20(_underlyingDealToken).safeTransfer(_holder, _currentBalance);
            emit HolderClaim(_holder, _purchaseToken, 0, _underlyingDealToken, _currentBalance, block.timestamp);
        }
    }

    /**
     * @dev transfers protocol fee of underlying deal tokens to the treasury escrow contract
     */
    function feeEscrowClaim() public purchasingOver {
        if (!feeEscrowClaimed) {
            feeEscrowClaimed = true;
            address _underlyingDealToken = dealData.underlyingDealToken;
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

            address aelinEscrowStorageProxy = _cloneAsMinimalProxy(aelinEscrowLogicAddress, "Could not create new escrow");
            aelinFeeEscrow = AelinFeeEscrow(aelinEscrowStorageProxy);
            aelinFeeEscrow.initialize(aelinTreasuryAddress, _underlyingDealToken);

            uint256 totalSold;
            if (totalPoolShares > _underlyingDealTokenTotal) {
                totalSold = _underlyingDealTokenTotal;
            } else {
                totalSold = totalPoolShares;
            }
            uint256 aelinFeeAmt = (totalSold * AELIN_FEE) / BASE;
            IERC20(_underlyingDealToken).safeTransfer(address(aelinFeeEscrow), aelinFeeAmt);

            emit FeeEscrowClaim(aelinEscrowStorageProxy, _underlyingDealToken, aelinFeeAmt);
        }
    }

    /**
     * @dev purchaser calls after the purchasing period to claim underlying deal tokens
     * amount based on the vesting schedule
     */
    function claimUnderlying() external lock purchasingOver passMinimumRaise {
        uint256 underlyingDealTokensClaimed = claimableUnderlyingTokens(msg.sender);
        require(underlyingDealTokensClaimed > 0, "no underlying ready to claim");
        address _underlyingDealToken = dealData.underlyingDealToken;
        amountVested[msg.sender] += underlyingDealTokensClaimed;
        _burn(msg.sender, underlyingDealTokensClaimed);
        totalUnderlyingClaimed += underlyingDealTokensClaimed;
        IERC20(_underlyingDealToken).safeTransfer(msg.sender, underlyingDealTokensClaimed);
        emit ClaimedUnderlyingDealToken(msg.sender, _underlyingDealToken, underlyingDealTokensClaimed);
    }

    /**
     * @dev a view showing the amount of the underlying deal token a purchaser can claim
     * @param _purchaser address to check the quantity of claimable underlying tokens
     */
    function claimableUnderlyingTokens(address _purchaser) public view purchasingOver returns (uint256) {
        uint256 _vestingPeriod = dealConfig.vestingPeriod;
        uint256 precisionAdjustedUnderlyingClaimable;

        uint256 maxTime = block.timestamp > vestingExpiry ? vestingExpiry : block.timestamp;
        if (
            balanceOf(_purchaser) > 0 &&
            (maxTime > vestingCliffExpiry || (maxTime == vestingCliffExpiry && _vestingPeriod == 0))
        ) {
            uint256 timeElapsed = maxTime - vestingCliffExpiry;

            uint256 underlyingClaimable = _vestingPeriod == 0
                ? balanceOf(_purchaser)
                : ((balanceOf(_purchaser) + amountVested[_purchaser]) * timeElapsed) /
                    _vestingPeriod -
                    amountVested[_purchaser];
            // This could potentially be the case where the last user claims a slightly smaller amount if there is some precision loss
            // although it will generally never happen as solidity rounds down so there should always be a little bit left
            address _underlyingDealToken = dealData.underlyingDealToken;
            precisionAdjustedUnderlyingClaimable = underlyingClaimable >
                IERC20(_underlyingDealToken).balanceOf(address(this))
                ? IERC20(_underlyingDealToken).balanceOf(address(this))
                : underlyingClaimable;
        }

        return (precisionAdjustedUnderlyingClaimable);
    }

    /**
     * @dev the holder may change their address
     * @param _holder address to swap the holder role
     */
    function setHolder(address _holder) external onlyHolder {
        futureHolder = _holder;
    }

    /**
     * @dev futurHolder can call to accept the role of holder
     */
    function acceptHolder() external {
        require(msg.sender == futureHolder, "only future holder can access");
        dealData.holder = futureHolder;
        emit SetHolder(futureHolder);
    }

    /**
     * @dev a function that any Ethereum address can call to vouch for a pool's legitimacy
     */
    function vouch() external {
        emit Vouch(msg.sender);
    }

    /**
     * @dev a function that any Ethereum address can call to disavow for a pool's legitimacy
     */
    function disavow() external {
        emit Disavow(msg.sender);
    }

    /**
     * @dev returns allow list information
     * @param _userAddress address to use in returning the amountPerAddress
     * @return address[] returns array of addresses included in the allow list
     * @return uint256[] returns array of allow list amounts for the address matching the index of allowListAddresses
     * @return uint256 allow list amount for _userAddress input
     * @return bool true if this deal has an allow list
     */
    function getAllowList(address _userAddress)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256,
            bool
        )
    {
        return (
            allowList.allowListAddresses,
            allowList.allowListAmounts,
            allowList.amountPerAddress[_userAddress],
            allowList.hasAllowList
        );
    }

    /**
     * @dev returns NFT collection details for the input collection address
     * @param _collection NFT collection address to get the collection details for
     * @return uint256 purchase amount, if 0 then unlimited purchase
     * @return address collection address used for configuration
     * @return bool if true then purchase amount is per token, if false then purchase amount is per user
     * @return uint256[] for ERC1155, included token IDs for this collection
     * @return uint256[] for ERC1155, min number of tokens required for participating
     */
    function getNftCollectionDetails(address _collection)
        public
        view
        returns (
            uint256,
            address,
            bool,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            nftGating.nftCollectionDetails[_collection].purchaseAmount,
            nftGating.nftCollectionDetails[_collection].collectionAddress,
            nftGating.nftCollectionDetails[_collection].purchaseAmountPerToken,
            nftGating.nftCollectionDetails[_collection].tokenIds,
            nftGating.nftCollectionDetails[_collection].minTokensEligible
        );
    }

    /**
     * @dev returns various details about the NFT gating storage
     * @param _collection NFT collection address to check
     * @param _wallet user address to check
     * @param _nftId if _collection is ERC721 or CryptoPunks check if this ID has been used, if ERC1155 check if this ID is included
     * @return bool true if the _wallet has already been used to claim this _collection
     * @return bool if _collection is ERC721 or CryptoPunks true if this ID has been used, if ERC1155 true if this ID is included
     * @return bool returns hasNftList, true if this deal has a valid NFT gating list
     */
    function getNftGatingDetails(
        address _collection,
        address _wallet,
        uint256 _nftId
    )
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            nftGating.nftWalletUsedForPurchase[_collection][_wallet],
            nftGating.nftId[_collection][_nftId],
            nftGating.hasNftList
        );
    }

    /**
     * @dev getPurchaseTokensPerUser
     * @param _address address to check
     */
    function getPurchaseTokensPerUser(address _address) public view returns (uint256) {
        return (purchaseTokensPerUser[_address]);
    }

    /**
     * @dev getPoolSharesPerUser
     * @param _address address to check
     */
    function getPoolSharesPerUser(address _address) public view returns (uint256) {
        return (poolSharesPerUser[_address]);
    }

    /**
     * @dev getAmountVested
     * @param _address address to check
     */
    function getAmountVested(address _address) public view returns (uint256) {
        return (amountVested[_address]);
    }

    /**
     * @dev hasPurchasedMerkle
     * @param _index index of leaf node/ address to check
     */
    function hasPurchasedMerkle(uint256 _index) public view returns (bool) {
        return MerkleTree.hasPurchasedMerkle(trackClaimed, _index);
    }

    modifier onlyHolder() {
        require(msg.sender == dealData.holder, "must be holder");
        _;
    }

    modifier onlySponsor() {
        require(msg.sender == dealData.sponsor, "must be sponsor");
        _;
    }

    modifier purchasingOver() {
        require(underlyingDepositComplete, "underlying deposit incomplete");
        require(block.timestamp > purchaseExpiry, "purchase period not over");
        _;
    }

    modifier passMinimumRaise() {
        require(
            dealConfig.purchaseRaiseMinimum == 0 || totalPurchasingAccepted > dealConfig.purchaseRaiseMinimum,
            "does not pass min raise"
        );
        _;
    }

    modifier blockTransfer() {
        require(false, "cant transfer deal tokens");
        _;
    }

    function transfer(address _dst, uint256 _amount) public virtual override blockTransfer returns (bool) {
        return super.transfer(_dst, _amount);
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) public virtual override blockTransfer returns (bool) {
        return super.transferFrom(_src, _dst, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/**
 * @dev a standard ERC20 contract that is extended with a few methods
 * described in detail below
 */
contract AelinERC20 is ERC20 {
    bool setInfo;
    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name and symbol in the initializer which requires these custom variables
     */
    string private _custom_name;
    string private _custom_symbol;
    uint8 private _custom_decimals;
    bool private locked;
    uint8 constant DEAL_TOKEN_DECIMALS = 18;

    constructor() ERC20("", "") {}

    modifier initInfoOnce() {
        require(!setInfo, "can only initialize once");
        _;
    }

    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name, symbol, and decimals in the initializer which requires this
     * custom logic for name(), symbol(), decimals(), and _setNameSymbolAndDecimals()
     */
    function name() public view virtual override returns (string memory) {
        return _custom_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _custom_symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _custom_decimals;
    }

    function _setNameSymbolAndDecimals(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initInfoOnce returns (bool) {
        _custom_name = _name;
        _custom_symbol = _symbol;
        _custom_decimals = _decimals;
        setInfo = true;
        emit AelinToken(_name, _symbol, _decimals);
        return true;
    }

    /**
     * @dev Add this to prevent reentrancy attacks on purchasePoolTokens and depositUnderlying
     * source: https://quantstamp.com/blog/how-the-dforce-hacker-used-reentrancy-to-steal-25-million
     * uniswap implementation: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L31-L36
     */
    modifier lock() {
        require(!locked, "AelinV1: LOCKED");
        locked = true;
        _;
        locked = false;
    }

    event AelinToken(string name, string symbol, uint8 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.7;

// https://docs.synthetix.io/contracts/source/contracts/minimalproxyfactory
// https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
contract MinimalProxyFactory {
    function _cloneAsMinimalProxy(address _base, string memory _revertMsg) internal returns (address clone) {
        bytes memory createData = _generateMinimalProxyCreateData(_base);

        assembly {
            clone := create(
                0, // no value
                add(createData, 0x20), // data
                55 // data is always 55 bytes (10 constructor + 45 code)
            )
        }

        // If CREATE fails for some reason, address(0) is returned
        require(clone != address(0), _revertMsg);
    }

    function _generateMinimalProxyCreateData(address _base) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                //---- constructor -----
                bytes10(0x3d602d80600a3d3981f3),
                //---- proxy code -----
                bytes10(0x363d3d373d3d3d363d73),
                _base,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import "./interfaces/IAelinDeal.sol";
import "./MinimalProxyFactory.sol";
import "./AelinFeeEscrow.sol";

contract AelinDeal is AelinERC20, MinimalProxyFactory, IAelinDeal {
    using SafeERC20 for IERC20;
    uint256 public maxTotalSupply;

    address public underlyingDealToken;
    uint256 public underlyingDealTokenTotal;
    uint256 public totalUnderlyingClaimed;
    address public holder;
    address public futureHolder;
    address public aelinTreasuryAddress;

    uint256 public underlyingPerDealExchangeRate;

    address public aelinPool;
    uint256 public vestingCliffExpiry;
    uint256 public vestingCliffPeriod;
    uint256 public vestingPeriod;
    uint256 public vestingExpiry;
    uint256 public holderFundingExpiry;

    bool private calledInitialize;
    address public aelinEscrowAddress;
    AelinFeeEscrow public aelinFeeEscrow;

    bool public depositComplete;
    mapping(address => uint256) public amountVested;

    Timeline public openRedemption;
    Timeline public proRataRedemption;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new deal created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the initialize method replaces the constructor setup and can only be called once
     * NOTE the deal tokens wrapping the underlying are always 18 decimals
     */
    function initialize(
        string calldata _poolName,
        string calldata _poolSymbol,
        DealData calldata _dealData,
        address _aelinTreasuryAddress,
        address _aelinEscrowAddress
    ) external initOnce {
        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aeDeal-", _poolName)),
            string(abi.encodePacked("aeD-", _poolSymbol)),
            DEAL_TOKEN_DECIMALS
        );

        holder = _dealData.holder;
        underlyingDealToken = _dealData.underlyingDealToken;
        underlyingDealTokenTotal = _dealData.underlyingDealTokenTotal;
        maxTotalSupply = _dealData.maxDealTotalSupply;

        aelinPool = msg.sender;
        vestingCliffPeriod = _dealData.vestingCliffPeriod;
        vestingPeriod = _dealData.vestingPeriod;
        proRataRedemption.period = _dealData.proRataRedemptionPeriod;
        openRedemption.period = _dealData.openRedemptionPeriod;
        holderFundingExpiry = _dealData.holderFundingDuration;
        aelinTreasuryAddress = _aelinTreasuryAddress;
        aelinEscrowAddress = _aelinEscrowAddress;

        depositComplete = false;

        /**
         * calculates the amount of underlying deal tokens you get per wrapped deal token accepted
         */
        underlyingPerDealExchangeRate = (_dealData.underlyingDealTokenTotal * 1e18) / maxTotalSupply;
        emit SetHolder(_dealData.holder);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier finalizeDeposit() {
        require(block.timestamp < holderFundingExpiry, "deposit past deadline");
        require(!depositComplete, "deposit already complete");
        _;
    }

    /**
     * @dev the holder may change their address
     */
    function setHolder(address _holder) external onlyHolder {
        require(_holder != address(0));
        futureHolder = _holder;
    }

    function acceptHolder() external {
        require(msg.sender == futureHolder, "only future holder can access");
        holder = futureHolder;
        emit SetHolder(futureHolder);
    }

    /**
     * @dev the holder finalizes the deal for the pool created by the
     * sponsor by depositing funds using this method.
     *
     * NOTE if the deposit was completed with a transfer instead of this method
     * the deposit still needs to be finalized by calling this method with
     * _underlyingDealTokenAmount set to 0
     */
    function depositUnderlying(uint256 _underlyingDealTokenAmount) external finalizeDeposit lock returns (bool) {
        if (_underlyingDealTokenAmount > 0) {
            uint256 currentBalance = IERC20(underlyingDealToken).balanceOf(address(this));
            IERC20(underlyingDealToken).safeTransferFrom(msg.sender, address(this), _underlyingDealTokenAmount);
            uint256 balanceAfterTransfer = IERC20(underlyingDealToken).balanceOf(address(this));
            uint256 underlyingDealTokenAmount = balanceAfterTransfer - currentBalance;

            emit DepositDealToken(underlyingDealToken, msg.sender, underlyingDealTokenAmount);
        }

        if (IERC20(underlyingDealToken).balanceOf(address(this)) >= underlyingDealTokenTotal) {
            depositComplete = true;
            proRataRedemption.start = block.timestamp;
            proRataRedemption.expiry = block.timestamp + proRataRedemption.period;
            vestingCliffExpiry = block.timestamp + proRataRedemption.period + openRedemption.period + vestingCliffPeriod;
            vestingExpiry = vestingCliffExpiry + vestingPeriod;

            if (openRedemption.period > 0) {
                openRedemption.start = proRataRedemption.expiry;
                openRedemption.expiry = proRataRedemption.expiry + openRedemption.period;
            }

            address aelinEscrowStorageProxy = _cloneAsMinimalProxy(aelinEscrowAddress, "Could not create new escrow");
            aelinFeeEscrow = AelinFeeEscrow(aelinEscrowStorageProxy);
            aelinFeeEscrow.initialize(aelinTreasuryAddress, underlyingDealToken);

            emit DealFullyFunded(
                aelinPool,
                proRataRedemption.start,
                proRataRedemption.expiry,
                openRedemption.start,
                openRedemption.expiry
            );
            return true;
        }
        return false;
    }

    /**
     * @dev the holder can withdraw any amount accidentally deposited over
     * the amount needed to fulfill the deal or all amount if deposit was not completed
     */
    function withdraw() external onlyHolder {
        uint256 withdrawAmount;
        if (!depositComplete && block.timestamp >= holderFundingExpiry) {
            withdrawAmount = IERC20(underlyingDealToken).balanceOf(address(this));
        } else {
            withdrawAmount =
                IERC20(underlyingDealToken).balanceOf(address(this)) -
                (underlyingDealTokenTotal - totalUnderlyingClaimed);
        }
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(underlyingDealToken, holder, withdrawAmount);
    }

    /**
     * @dev after the redemption period has ended the holder can withdraw
     * the excess funds remaining from purchasers who did not accept the deal
     *
     * Requirements:
     * - both the pro rata and open redemption windows are no longer active
     */
    function withdrawExpiry() external onlyHolder {
        require(proRataRedemption.expiry > 0, "redemption period not started");
        require(
            openRedemption.expiry > 0
                ? block.timestamp >= openRedemption.expiry
                : block.timestamp >= proRataRedemption.expiry,
            "redeem window still active"
        );
        uint256 withdrawAmount = IERC20(underlyingDealToken).balanceOf(address(this)) -
            ((underlyingPerDealExchangeRate * totalSupply()) / 1e18);
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(underlyingDealToken, holder, withdrawAmount);
    }

    modifier onlyHolder() {
        require(msg.sender == holder, "only holder can access");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == aelinPool, "only AelinPool can access");
        _;
    }

    /**
     * @dev a view showing the number of claimable deal tokens and the
     * amount of the underlying deal token a purchser gets in return
     */
    function claimableTokens(address purchaser)
        public
        view
        returns (uint256 underlyingClaimable, uint256 dealTokensClaimable)
    {
        underlyingClaimable = 0;
        dealTokensClaimable = 0;

        uint256 maxTime = block.timestamp > vestingExpiry ? vestingExpiry : block.timestamp;
        if (
            balanceOf(purchaser) > 0 &&
            (maxTime > vestingCliffExpiry || (maxTime == vestingCliffExpiry && vestingPeriod == 0))
        ) {
            uint256 timeElapsed = maxTime - vestingCliffExpiry;

            dealTokensClaimable = vestingPeriod == 0
                ? balanceOf(purchaser)
                : ((balanceOf(purchaser) + amountVested[purchaser]) * timeElapsed) / vestingPeriod - amountVested[purchaser];
            underlyingClaimable = (underlyingPerDealExchangeRate * dealTokensClaimable) / 1e18;
        }
    }

    /**
     * @dev allows a user to claim their underlying deal tokens or a partial amount
     * of their underlying tokens once they have vested according to the schedule
     * created by the sponsor
     */
    function claim() external returns (uint256) {
        return _claim(msg.sender);
    }

    function _claim(address recipient) internal returns (uint256) {
        (uint256 underlyingDealTokensClaimed, uint256 dealTokensClaimed) = claimableTokens(recipient);
        if (dealTokensClaimed > 0) {
            amountVested[recipient] += dealTokensClaimed;
            totalUnderlyingClaimed += underlyingDealTokensClaimed;
            _burn(recipient, dealTokensClaimed);
            IERC20(underlyingDealToken).safeTransfer(recipient, underlyingDealTokensClaimed);
            emit ClaimedUnderlyingDealToken(underlyingDealToken, recipient, underlyingDealTokensClaimed);
        }
        return dealTokensClaimed;
    }

    /**
     * @dev allows the purchaser to mint deal tokens. this method is also used
     * to send deal tokens to the sponsor. It may only be called from the pool
     * contract that created this deal
     */
    function mint(address dst, uint256 dealTokenAmount) external onlyPool {
        require(depositComplete, "deposit not complete");
        _mint(dst, dealTokenAmount);
    }

    /**
     * @dev allows the protocol to handle protocol fees coming in deal tokens.
     * It may only be called from the pool contract that created this deal
     */
    function protocolMint(uint256 dealTokenAmount) external onlyPool {
        require(depositComplete, "deposit not complete");
        uint256 underlyingProtocolFees = (underlyingPerDealExchangeRate * dealTokenAmount) / 1e18;
        IERC20(underlyingDealToken).safeTransfer(address(aelinFeeEscrow), underlyingProtocolFees);
    }

    modifier blockTransfer() {
        require(msg.sender == aelinTreasuryAddress, "cannot transfer deal tokens");
        _;
    }

    /**
     * @dev a function only the treasury can use so they can send both the all
     * unvested deal tokens as well as all the vested underlying deal tokens in a
     * single transaction for distribution to $AELIN stakers.
     */
    function treasuryTransfer(address recipient) external returns (bool) {
        require(msg.sender == aelinTreasuryAddress, "only Rewards address can access");
        (uint256 underlyingClaimable, uint256 claimableDealTokens) = claimableTokens(msg.sender);
        transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
        IERC20(underlyingDealToken).safeTransferFrom(msg.sender, recipient, underlyingClaimable);
        return true;
    }

    /**
     * @dev below are helpers for transferring deal tokens. NOTE the token holder transferring
     * the deal tokens must pay the gas to claim their vested tokens first, which will burn their vested deal
     * tokens. They must also pay for the receivers claim and burn any of their vested tokens in order to ensure
     * the claim calculation is always accurate for all parties in the system
     */
    function transferMax(address recipient) external blockTransfer returns (bool) {
        (, uint256 claimableDealTokens) = claimableTokens(msg.sender);
        return transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
    }

    function transferFromMax(address sender, address recipient) external blockTransfer returns (bool) {
        (, uint256 claimableDealTokens) = claimableTokens(sender);
        return transferFrom(sender, recipient, balanceOf(sender) - claimableDealTokens);
    }

    function transfer(address recipient, uint256 amount) public virtual override blockTransfer returns (bool) {
        _claim(msg.sender);
        _claim(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override blockTransfer returns (bool) {
        _claim(sender);
        _claim(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    event SetHolder(address indexed holder);
    event DealFullyFunded(
        address indexed poolAddress,
        uint256 proRataRedemptionStart,
        uint256 proRataRedemptionExpiry,
        uint256 openRedemptionStart,
        uint256 openRedemptionExpiry
    );
    event DepositDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event WithdrawUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event ClaimedUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed recipient,
        uint256 underlyingDealTokensClaimed
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinDeal.sol";
import "./interfaces/IAelinPool.sol";
import "./interfaces/ICryptoPunks.sol";
import "./libraries/NftCheck.sol";

contract AelinPool is AelinERC20, MinimalProxyFactory, IAelinPool {
    using SafeERC20 for IERC20;
    address constant CRYPTO_PUNKS = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    uint256 constant BASE = 100 * 10**18;
    uint256 constant MAX_SPONSOR_FEE = 15 * 10**18;
    uint256 constant AELIN_FEE = 2 * 10**18;
    uint8 constant MAX_DEALS = 5;

    uint8 public numberOfDeals;
    uint8 public purchaseTokenDecimals;
    address public purchaseToken;
    uint256 public purchaseTokenCap;
    uint256 public proRataConversion;

    uint256 public sponsorFee;
    address public sponsor;
    address public futureSponsor;
    address public poolFactory;

    uint256 public purchaseExpiry;
    uint256 public poolExpiry;
    uint256 public holderFundingExpiry;
    uint256 public totalAmountAccepted;
    uint256 public totalAmountWithdrawn;
    uint256 public purchaseTokenTotalForDeal;

    bool private calledInitialize;

    address public aelinTreasuryAddress;
    address public aelinDealLogicAddress;
    address public aelinEscrowLogicAddress;
    AelinDeal public aelinDeal;
    address public holder;

    mapping(address => uint256) public amountAccepted;
    mapping(address => uint256) public amountWithdrawn;
    mapping(address => bool) public openPeriodEligible;
    mapping(address => uint256) public allowList;
    // collectionAddress -> NftCollectionRules struct
    mapping(address => NftCollectionRules) public nftCollectionDetails;
    // collectionAddress -> walletAddress -> bool
    mapping(address => mapping(address => bool)) public nftWalletUsedForPurchase;
    // collectionAddress -> tokenId -> bool
    /**
     * @dev For 721, it is used for blacklisting the tokenId of a collection
     * and for 1155, it is used for identifying the eligible tokenIds for
     * participating in the pool
     */
    mapping(address => mapping(uint256 => bool)) public nftId;
    bool public hasNftList;
    bool public hasAllowList;

    string private storedName;
    string private storedSymbol;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new pool created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the initialize method replaces the constructor setup and can only be called once
     *
     * Requirements:
     * - max 1 year duration
     * - purchase expiry can be set from 30 minutes to 30 days
     * - max sponsor fee is 15000 representing 15%
     */
    function initialize(
        PoolData calldata _poolData,
        address _sponsor,
        address _aelinDealLogicAddress,
        address _aelinTreasuryAddress,
        address _aelinEscrowLogicAddress
    ) external initOnce {
        require(
            30 minutes <= _poolData.purchaseDuration && 30 days >= _poolData.purchaseDuration,
            "outside purchase expiry window"
        );
        require(365 days >= _poolData.duration, "max 1 year duration");
        require(_poolData.sponsorFee <= MAX_SPONSOR_FEE, "exceeds max sponsor fee");
        purchaseTokenDecimals = IERC20Decimals(_poolData.purchaseToken).decimals();
        require(purchaseTokenDecimals <= DEAL_TOKEN_DECIMALS, "too many token decimals");
        storedName = _poolData.name;
        storedSymbol = _poolData.symbol;
        poolFactory = msg.sender;

        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aePool-", _poolData.name)),
            string(abi.encodePacked("aeP-", _poolData.symbol)),
            purchaseTokenDecimals
        );

        purchaseTokenCap = _poolData.purchaseTokenCap;
        purchaseToken = _poolData.purchaseToken;
        purchaseExpiry = block.timestamp + _poolData.purchaseDuration;
        poolExpiry = purchaseExpiry + _poolData.duration;
        sponsorFee = _poolData.sponsorFee;
        sponsor = _sponsor;
        aelinEscrowLogicAddress = _aelinEscrowLogicAddress;
        aelinDealLogicAddress = _aelinDealLogicAddress;
        aelinTreasuryAddress = _aelinTreasuryAddress;

        address[] memory allowListAddresses = _poolData.allowListAddresses;
        uint256[] memory allowListAmounts = _poolData.allowListAmounts;

        if (allowListAddresses.length > 0 || allowListAmounts.length > 0) {
            require(
                allowListAddresses.length == allowListAmounts.length,
                "allowListAddresses and allowListAmounts arrays should have the same length"
            );
            for (uint256 i; i < allowListAddresses.length; ++i) {
                allowList[allowListAddresses[i]] = allowListAmounts[i];
                emit AllowlistAddress(allowListAddresses[i], allowListAmounts[i]);
            }
            hasAllowList = true;
        }

        NftCollectionRules[] memory nftCollectionRules = _poolData.nftCollectionRules;

        if (nftCollectionRules.length > 0) {
            // if the first address supports punks or 721, the entire pool only supports 721 or punks
            if (
                nftCollectionRules[0].collectionAddress == CRYPTO_PUNKS ||
                NftCheck.supports721(nftCollectionRules[0].collectionAddress)
            ) {
                for (uint256 i; i < nftCollectionRules.length; ++i) {
                    require(
                        nftCollectionRules[i].collectionAddress == CRYPTO_PUNKS ||
                            NftCheck.supports721(nftCollectionRules[i].collectionAddress),
                        "can only contain 721"
                    );
                    nftCollectionDetails[nftCollectionRules[i].collectionAddress] = nftCollectionRules[i];
                    emit PoolWith721(
                        nftCollectionRules[i].collectionAddress,
                        nftCollectionRules[i].purchaseAmount,
                        nftCollectionRules[i].purchaseAmountPerToken
                    );
                }
                hasNftList = true;
            }
            // if the first address supports 1155, the entire pool only supports 1155
            else if (NftCheck.supports1155(nftCollectionRules[0].collectionAddress)) {
                for (uint256 i; i < nftCollectionRules.length; ++i) {
                    require(NftCheck.supports1155(nftCollectionRules[i].collectionAddress), "can only contain 1155");
                    nftCollectionDetails[nftCollectionRules[i].collectionAddress] = nftCollectionRules[i];

                    for (uint256 j; j < nftCollectionRules[i].tokenIds.length; ++j) {
                        nftId[nftCollectionRules[i].collectionAddress][nftCollectionRules[i].tokenIds[j]] = true;
                    }
                    emit PoolWith1155(
                        nftCollectionRules[i].collectionAddress,
                        nftCollectionRules[i].purchaseAmount,
                        nftCollectionRules[i].purchaseAmountPerToken,
                        nftCollectionRules[i].tokenIds,
                        nftCollectionRules[i].minTokensEligible
                    );
                }
                hasNftList = true;
            } else {
                revert("collection is not compatible");
            }
        }

        emit SetSponsor(_sponsor);
    }

    modifier dealReady() {
        if (holderFundingExpiry > 0) {
            require(!aelinDeal.depositComplete() && block.timestamp >= holderFundingExpiry, "cant create new deal");
        }
        _;
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier onlySponsor() {
        require(msg.sender == sponsor, "only sponsor can access");
        _;
    }

    modifier dealFunded() {
        require(holderFundingExpiry > 0 && aelinDeal.depositComplete(), "deal not yet funded");
        _;
    }

    /**
     * @dev the sponsor may change addresses
     */
    function setSponsor(address _sponsor) external onlySponsor {
        require(_sponsor != address(0));
        futureSponsor = _sponsor;
    }

    function acceptSponsor() external {
        require(msg.sender == futureSponsor, "only future sponsor can access");
        sponsor = futureSponsor;
        emit SetSponsor(futureSponsor);
    }

    /**
     * @dev only the sponsor can create a deal. The deal must be funded by the holder
     * of the underlying deal token before a purchaser may accept the deal. If the
     * holder does not fund the deal before the expiry period is over then the sponsor
     * can create a new deal for the pool of capital by calling this method again.
     *
     * Requirements:
     * - The purchase expiry period must be over
     * - the holder funding expiry period must be from 30 minutes to 30 days
     * - the pro rata redemption period must be from 30 minutes to 30 days
     * - the purchase token total for the deal that may be accepted must be <= the funds in the pool
     * - if the pro rata conversion ratio (purchase token total for the deal:funds in pool)
     *   is 1:1 then the open redemption period must be 0,
     *   otherwise the open period is from 30 minutes to 30 days
     */
    function createDeal(
        address _underlyingDealToken,
        uint256 _purchaseTokenTotalForDeal,
        uint256 _underlyingDealTokenTotal,
        uint256 _vestingPeriod,
        uint256 _vestingCliffPeriod,
        uint256 _proRataRedemptionPeriod,
        uint256 _openRedemptionPeriod,
        address _holder,
        uint256 _holderFundingDuration
    ) external onlySponsor dealReady returns (address) {
        require(numberOfDeals < MAX_DEALS, "too many deals");
        require(_holder != address(0), "cant pass null holder address");
        require(_underlyingDealToken != address(0), "cant pass null token address");
        require(block.timestamp >= purchaseExpiry, "pool still in purchase mode");
        require(
            30 minutes <= _proRataRedemptionPeriod && 30 days >= _proRataRedemptionPeriod,
            "30 mins - 30 days for prorata"
        );
        require(1825 days >= _vestingCliffPeriod, "max 5 year cliff");
        require(1825 days >= _vestingPeriod, "max 5 year vesting");
        require(30 minutes <= _holderFundingDuration && 30 days >= _holderFundingDuration, "30 mins - 30 days for holder");
        require(_purchaseTokenTotalForDeal <= totalSupply(), "not enough funds available");
        proRataConversion = (_purchaseTokenTotalForDeal * 1e18) / totalSupply();
        if (proRataConversion == 1e18) {
            require(0 minutes == _openRedemptionPeriod, "deal is 1:1, set open to 0");
        } else {
            require(30 minutes <= _openRedemptionPeriod && 30 days >= _openRedemptionPeriod, "30 mins - 30 days for open");
        }

        numberOfDeals += 1;
        poolExpiry = block.timestamp;
        holder = _holder;
        holderFundingExpiry = block.timestamp + _holderFundingDuration;
        purchaseTokenTotalForDeal = _purchaseTokenTotalForDeal;
        uint256 maxDealTotalSupply = _convertPoolToDeal(_purchaseTokenTotalForDeal, purchaseTokenDecimals);

        address aelinDealStorageProxy = _cloneAsMinimalProxy(aelinDealLogicAddress, "Could not create new deal");
        aelinDeal = AelinDeal(aelinDealStorageProxy);
        IAelinDeal.DealData memory dealData = IAelinDeal.DealData(
            _underlyingDealToken,
            _underlyingDealTokenTotal,
            _vestingPeriod,
            _vestingCliffPeriod,
            _proRataRedemptionPeriod,
            _openRedemptionPeriod,
            _holder,
            maxDealTotalSupply,
            holderFundingExpiry
        );

        aelinDeal.initialize(storedName, storedSymbol, dealData, aelinTreasuryAddress, aelinEscrowLogicAddress);

        emit CreateDeal(
            string(abi.encodePacked("aeDeal-", storedName)),
            string(abi.encodePacked("aeD-", storedSymbol)),
            sponsor,
            aelinDealStorageProxy
        );

        emit DealDetail(
            aelinDealStorageProxy,
            _underlyingDealToken,
            _purchaseTokenTotalForDeal,
            _underlyingDealTokenTotal,
            _vestingPeriod,
            _vestingCliffPeriod,
            _proRataRedemptionPeriod,
            _openRedemptionPeriod,
            _holder,
            _holderFundingDuration
        );

        return aelinDealStorageProxy;
    }

    /**
     * @dev the 2 methods allow a purchaser to exchange accept all or a
     * portion of their pool tokens for deal tokens
     *
     * Requirements:
     * - the redemption period is either in the pro rata or open windows
     * - the purchaser cannot accept more than their share for a period
     * - if participating in the open period, a purchaser must have maxxed their
     *   contribution in the pro rata phase
     */
    function acceptMaxDealTokens() external {
        _acceptDealTokens(msg.sender, 0, true);
    }

    function acceptDealTokens(uint256 _poolTokenAmount) external {
        _acceptDealTokens(msg.sender, _poolTokenAmount, false);
    }

    /**
     * @dev the if statement says if you have no balance or if the deal is not funded
     * or if the pro rata period is not active, then you have 0 available for this period
     */
    function maxProRataAmount(address _purchaser) public view returns (uint256) {
        (, uint256 proRataRedemptionStart, uint256 proRataRedemptionExpiry) = aelinDeal.proRataRedemption();

        if (
            (balanceOf(_purchaser) == 0 && amountAccepted[_purchaser] == 0 && amountWithdrawn[_purchaser] == 0) ||
            holderFundingExpiry == 0 ||
            proRataRedemptionStart == 0 ||
            block.timestamp >= proRataRedemptionExpiry
        ) {
            return 0;
        }
        return
            (proRataConversion * (balanceOf(_purchaser) + amountAccepted[_purchaser] + amountWithdrawn[_purchaser])) /
            1e18 -
            amountAccepted[_purchaser];
    }

    function _maxOpenAvail(address _purchaser) internal view returns (uint256) {
        return
            balanceOf(_purchaser) + totalAmountAccepted <= purchaseTokenTotalForDeal
                ? balanceOf(_purchaser)
                : purchaseTokenTotalForDeal - totalAmountAccepted;
    }

    function _acceptDealTokens(
        address _recipient,
        uint256 _poolTokenAmount,
        bool _useMax
    ) internal dealFunded lock {
        (, uint256 proRataRedemptionStart, uint256 proRataRedemptionExpiry) = aelinDeal.proRataRedemption();
        (, uint256 openRedemptionStart, uint256 openRedemptionExpiry) = aelinDeal.openRedemption();

        if (block.timestamp >= proRataRedemptionStart && block.timestamp < proRataRedemptionExpiry) {
            _acceptDealTokensProRata(_recipient, _poolTokenAmount, _useMax);
        } else if (openRedemptionStart > 0 && block.timestamp < openRedemptionExpiry) {
            _acceptDealTokensOpen(_recipient, _poolTokenAmount, _useMax);
        } else {
            revert("outside of redeem window");
        }
    }

    function _acceptDealTokensProRata(
        address _recipient,
        uint256 _poolTokenAmount,
        bool _useMax
    ) internal {
        uint256 maxProRata = maxProRataAmount(_recipient);
        uint256 maxAccept = maxProRata > balanceOf(_recipient) ? balanceOf(_recipient) : maxProRata;
        if (!_useMax) {
            require(
                _poolTokenAmount <= maxProRata && balanceOf(_recipient) >= _poolTokenAmount,
                "accepting more than share"
            );
        }
        uint256 acceptAmount = _useMax ? maxAccept : _poolTokenAmount;
        amountAccepted[_recipient] += acceptAmount;
        totalAmountAccepted += acceptAmount;
        _mintDealTokens(_recipient, acceptAmount);
        if (proRataConversion != 1e18 && maxProRataAmount(_recipient) == 0) {
            openPeriodEligible[_recipient] = true;
        }
    }

    function _acceptDealTokensOpen(
        address _recipient,
        uint256 _poolTokenAmount,
        bool _useMax
    ) internal {
        require(openPeriodEligible[_recipient], "ineligible: didn't max pro rata");
        uint256 maxOpen = _maxOpenAvail(_recipient);
        require(maxOpen > 0, "nothing left to accept");
        uint256 acceptAmount = _useMax ? maxOpen : _poolTokenAmount;
        if (!_useMax) {
            require(acceptAmount <= maxOpen, "accepting more than share");
        }
        totalAmountAccepted += acceptAmount;
        amountAccepted[_recipient] += acceptAmount;
        _mintDealTokens(_recipient, acceptAmount);
    }

    /**
     * @dev the holder will receive less purchase tokens than the amount
     * transferred if the purchase token burns or takes a fee during transfer
     */
    function _mintDealTokens(address _recipient, uint256 _poolTokenAmount) internal {
        _burn(_recipient, _poolTokenAmount);
        uint256 poolTokenDealFormatted = _convertPoolToDeal(_poolTokenAmount, purchaseTokenDecimals);
        uint256 aelinFeeAmt = (poolTokenDealFormatted * AELIN_FEE) / BASE;
        uint256 sponsorFeeAmt = (poolTokenDealFormatted * sponsorFee) / BASE;

        aelinDeal.mint(sponsor, sponsorFeeAmt);
        aelinDeal.protocolMint(aelinFeeAmt);
        aelinDeal.mint(_recipient, poolTokenDealFormatted - (sponsorFeeAmt + aelinFeeAmt));
        IERC20(purchaseToken).safeTransfer(holder, _poolTokenAmount);
        emit AcceptDeal(_recipient, address(aelinDeal), _poolTokenAmount, sponsorFeeAmt, aelinFeeAmt);
    }

    /**
     * @dev allows anyone to become a purchaser by sending purchase tokens
     * in exchange for pool tokens
     *
     * Requirements:
     * - the deal is in the purchase expiry window
     * - the cap has not been exceeded
     */
    function purchasePoolTokens(uint256 _purchaseTokenAmount) external lock {
        require(block.timestamp < purchaseExpiry, "not in purchase window");
        require(!hasNftList, "has NFT list");
        if (hasAllowList) {
            require(_purchaseTokenAmount <= allowList[msg.sender], "more than allocation");
            allowList[msg.sender] -= _purchaseTokenAmount;
        }
        uint256 currentBalance = IERC20(purchaseToken).balanceOf(address(this));
        IERC20(purchaseToken).safeTransferFrom(msg.sender, address(this), _purchaseTokenAmount);
        uint256 balanceAfterTransfer = IERC20(purchaseToken).balanceOf(address(this));
        uint256 purchaseTokenAmount = balanceAfterTransfer - currentBalance;
        if (purchaseTokenCap > 0) {
            uint256 totalPoolAfter = totalSupply() + purchaseTokenAmount;
            require(totalPoolAfter <= purchaseTokenCap, "cap has been exceeded");
            if (totalPoolAfter == purchaseTokenCap) {
                purchaseExpiry = block.timestamp;
            }
        }

        _mint(msg.sender, purchaseTokenAmount);
        emit PurchasePoolToken(msg.sender, purchaseTokenAmount);
    }

    /**
     * @dev allows anyone to become a purchaser with a qualified erc721
     * nft in the pool depending on the scenarios
     *
     * Scenarios:
     * 1. each wallet holding a qualified NFT to deposit an unlimited amount of purchase tokens
     * 2. certain amount of purchase tokens per wallet regardless of the number of qualified NFTs held
     * 3. certain amount of Investment tokens per qualified NFT held
     */

    function purchasePoolTokensWithNft(NftPurchaseList[] calldata _nftPurchaseList, uint256 _purchaseTokenAmount)
        external
        lock
    {
        require(hasNftList, "pool does not have an NFT list");
        require(block.timestamp < purchaseExpiry, "not in purchase window");

        uint256 maxPurchaseTokenAmount;

        for (uint256 i; i < _nftPurchaseList.length; ++i) {
            NftPurchaseList memory nftPurchaseList = _nftPurchaseList[i];
            address collectionAddress = nftPurchaseList.collectionAddress;
            uint256[] memory tokenIds = nftPurchaseList.tokenIds;

            NftCollectionRules memory nftCollectionRules = nftCollectionDetails[collectionAddress];
            require(nftCollectionRules.collectionAddress == collectionAddress, "collection not in the pool");

            if (nftCollectionRules.purchaseAmountPerToken) {
                maxPurchaseTokenAmount += nftCollectionRules.purchaseAmount * tokenIds.length;
            }

            if (!nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                require(!nftWalletUsedForPurchase[collectionAddress][msg.sender], "wallet already used for nft set");
                nftWalletUsedForPurchase[collectionAddress][msg.sender] = true;
                maxPurchaseTokenAmount += nftCollectionRules.purchaseAmount;
            }

            if (nftCollectionRules.purchaseAmount == 0) {
                maxPurchaseTokenAmount = _purchaseTokenAmount;
            }

            if (NftCheck.supports721(collectionAddress)) {
                _blackListCheck721(collectionAddress, tokenIds);
            }
            if (NftCheck.supports1155(collectionAddress)) {
                _eligibilityCheck1155(collectionAddress, tokenIds, nftCollectionRules);
            }
            if (collectionAddress == CRYPTO_PUNKS) {
                _blackListCheckPunks(collectionAddress, tokenIds);
            }
        }

        require(_purchaseTokenAmount <= maxPurchaseTokenAmount, "purchase amount should be less the max allocation");

        uint256 amountBefore = IERC20(purchaseToken).balanceOf(address(this));
        IERC20(purchaseToken).safeTransferFrom(msg.sender, address(this), _purchaseTokenAmount);
        uint256 amountAfter = IERC20(purchaseToken).balanceOf(address(this));
        uint256 purchaseTokenAmount = amountAfter - amountBefore;

        if (purchaseTokenCap > 0) {
            uint256 totalPoolAfter = totalSupply() + purchaseTokenAmount;
            require(totalPoolAfter <= purchaseTokenCap, "cap has been exceeded");
            if (totalPoolAfter == purchaseTokenCap) {
                purchaseExpiry = block.timestamp;
            }
        }

        _mint(msg.sender, purchaseTokenAmount);
        emit PurchasePoolToken(msg.sender, purchaseTokenAmount);
    }

    function _blackListCheck721(address _collectionAddress, uint256[] memory _tokenIds) internal {
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(IERC721(_collectionAddress).ownerOf(_tokenIds[i]) == msg.sender, "has to be the token owner");
            require(!nftId[_collectionAddress][_tokenIds[i]], "tokenId already used");
            nftId[_collectionAddress][_tokenIds[i]] = true;
            emit BlacklistNFT(_collectionAddress, _tokenIds[i]);
        }
    }

    function _eligibilityCheck1155(
        address _collectionAddress,
        uint256[] memory _tokenIds,
        NftCollectionRules memory _nftCollectionRules
    ) internal view {
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(nftId[_collectionAddress][_tokenIds[i]], "tokenId not in the pool");
            require(
                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[i]) >= _nftCollectionRules.minTokensEligible[i],
                "erc1155 balance too low"
            );
        }
    }

    function _blackListCheckPunks(address _punksAddress, uint256[] memory _tokenIds) internal {
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(ICryptoPunks(_punksAddress).punkIndexToAddress(_tokenIds[i]) == msg.sender, "not the owner");
            require(!nftId[_punksAddress][_tokenIds[i]], "tokenId already used");
            nftId[_punksAddress][_tokenIds[i]] = true;
            emit BlacklistNFT(_punksAddress, _tokenIds[i]);
        }
    }

    /**
     * @dev the withdraw and partial withdraw methods allow a purchaser to take their
     * purchase tokens back in exchange for pool tokens if they do not accept a deal
     *
     * Requirements:
     * - the pool has expired either due to the creation of a deal or the end of the duration
     */
    function withdrawMaxFromPool() external {
        _withdraw(balanceOf(msg.sender));
    }

    function withdrawFromPool(uint256 _purchaseTokenAmount) external {
        _withdraw(_purchaseTokenAmount);
    }

    /**
     * @dev purchasers can withdraw at the end of the pool expiry period if
     * no deal was presented or they can withdraw after the holder funding period
     * if they do not like a deal
     */
    function _withdraw(uint256 _purchaseTokenAmount) internal {
        require(_purchaseTokenAmount <= balanceOf(msg.sender), "input larger than balance");
        require(block.timestamp >= poolExpiry, "not yet withdraw period");
        if (holderFundingExpiry > 0) {
            require(block.timestamp > holderFundingExpiry || aelinDeal.depositComplete(), "cant withdraw in funding period");
        }
        amountWithdrawn[msg.sender] += _purchaseTokenAmount;
        totalAmountWithdrawn += _purchaseTokenAmount;
        _burn(msg.sender, _purchaseTokenAmount);
        IERC20(purchaseToken).safeTransfer(msg.sender, _purchaseTokenAmount);
        emit WithdrawFromPool(msg.sender, _purchaseTokenAmount);
    }

    /**
     * @dev view to see how much of the deal a purchaser can accept.
     */
    function maxDealAccept(address _purchaser) external view returns (uint256) {
        /**
         * The if statement is checking to see if the holder has not funded the deal
         * or if the period is outside of a redemption window so nothing is available.
         * It then checks if you are in the pro rata period and open period eligibility
         */

        (, uint256 proRataRedemptionStart, uint256 proRataRedemptionExpiry) = aelinDeal.proRataRedemption();
        (, uint256 openRedemptionStart, uint256 openRedemptionExpiry) = aelinDeal.openRedemption();

        if (
            holderFundingExpiry == 0 ||
            proRataRedemptionStart == 0 ||
            (block.timestamp >= proRataRedemptionExpiry && openRedemptionStart == 0) ||
            (block.timestamp >= openRedemptionExpiry && openRedemptionStart != 0)
        ) {
            return 0;
        } else if (block.timestamp < proRataRedemptionExpiry) {
            uint256 maxProRata = maxProRataAmount(_purchaser);
            return maxProRata > balanceOf(_purchaser) ? balanceOf(_purchaser) : maxProRata;
        } else if (!openPeriodEligible[_purchaser]) {
            return 0;
        } else {
            return _maxOpenAvail(_purchaser);
        }
    }

    modifier transferWindow() {
        (, uint256 proRataRedemptionStart, uint256 proRataRedemptionExpiry) = aelinDeal.proRataRedemption();
        (, uint256 openRedemptionStart, uint256 openRedemptionExpiry) = aelinDeal.openRedemption();

        require(
            proRataRedemptionStart == 0 ||
                (block.timestamp >= proRataRedemptionExpiry && openRedemptionStart == 0) ||
                (block.timestamp >= openRedemptionExpiry && openRedemptionStart != 0),
            "no transfers in redeem window"
        );
        _;
    }

    function transfer(address _dst, uint256 _amount) public virtual override transferWindow returns (bool) {
        return super.transfer(_dst, _amount);
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) public virtual override transferWindow returns (bool) {
        return super.transferFrom(_src, _dst, _amount);
    }

    /**
     * @dev convert pool with varying decimals to deal tokens of 18 decimals
     * NOTE that a purchase token must not be greater than 18 decimals
     */
    function _convertPoolToDeal(uint256 _poolTokenAmount, uint256 _poolTokenDecimals) internal pure returns (uint256) {
        return _poolTokenAmount * 10**(18 - _poolTokenDecimals);
    }

    /**
     * @dev a function that any Ethereum address can call to vouch for a pool's legitimacy
     */
    function vouch() external {
        emit Vouch(msg.sender);
    }

    /**
     * @dev a function that any Ethereum address can call to disavow for a pool's legitimacy
     */
    function disavow() external {
        emit Disavow(msg.sender);
    }

    event SetSponsor(address indexed sponsor);
    event PurchasePoolToken(address indexed purchaser, uint256 purchaseTokenAmount);
    event WithdrawFromPool(address indexed purchaser, uint256 purchaseTokenAmount);
    event AcceptDeal(
        address indexed purchaser,
        address indexed dealAddress,
        uint256 poolTokenAmount,
        uint256 sponsorFee,
        uint256 aelinFee
    );
    event CreateDeal(string name, string symbol, address indexed sponsor, address indexed dealContract);
    event DealDetail(
        address indexed dealContract,
        address indexed underlyingDealToken,
        uint256 purchaseTokenTotalForDeal,
        uint256 underlyingDealTokenTotal,
        uint256 vestingPeriod,
        uint256 vestingCliff,
        uint256 proRataRedemptionPeriod,
        uint256 openRedemptionPeriod,
        address indexed holder,
        uint256 holderFundingDuration
    );
    event AllowlistAddress(address indexed purchaser, uint256 allowlistAmount);
    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);
    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );
    event Vouch(address indexed voucher);
    event Disavow(address indexed voucher);
    event BlacklistNFT(address indexed collection, uint256 nftID);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AelinFeeEscrow {
    using SafeERC20 for IERC20;
    uint256 public vestingExpiry;
    address public treasury;
    address public futureTreasury;
    address public escrowedToken;

    bool private calledInitialize;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new escrow created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the treasury may change their address
     */
    function setTreasury(address _treasury) external onlyTreasury {
        require(_treasury != address(0));
        futureTreasury = _treasury;
    }

    function acceptTreasury() external {
        require(msg.sender == futureTreasury, "only future treasury can access");
        treasury = futureTreasury;
        emit SetTreasury(futureTreasury);
    }

    function initialize(address _treasury, address _escrowedToken) external initOnce {
        treasury = _treasury;
        vestingExpiry = block.timestamp + 180 days;
        escrowedToken = _escrowedToken;
        emit InitializeEscrow(msg.sender, _treasury, vestingExpiry, escrowedToken);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury can access");
        _;
    }

    function delayEscrow() external onlyTreasury {
        require(vestingExpiry < block.timestamp + 90 days, "can only extend by 90 days");
        vestingExpiry = block.timestamp + 90 days;
        emit DelayEscrow(vestingExpiry);
    }

    /**
     * @dev transfer all the escrow tokens to the treasury
     */
    function withdrawToken() external onlyTreasury {
        require(block.timestamp > vestingExpiry, "cannot access funds yet");
        uint256 balance = IERC20(escrowedToken).balanceOf(address(this));
        IERC20(escrowedToken).safeTransfer(treasury, balance);
    }

    event SetTreasury(address indexed treasury);
    event InitializeEscrow(
        address indexed dealAddress,
        address indexed treasury,
        uint256 vestingExpiry,
        address indexed escrowedToken
    );
    event DelayEscrow(uint256 vestingExpiry);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IAelinPool} from "./IAelinPool.sol";

interface IAelinUpFrontDeal {
    struct UpFrontDealData {
        string name;
        string symbol;
        address purchaseToken;
        address underlyingDealToken;
        address holder;
        address sponsor;
        uint256 sponsorFee;
        bytes32 merkleRoot;
        string ipfsHash;
    }

    struct UpFrontDealConfig {
        uint256 underlyingDealTokenTotal;
        uint256 purchaseTokenPerDealToken;
        uint256 purchaseRaiseMinimum;
        uint256 purchaseDuration;
        uint256 vestingPeriod;
        uint256 vestingCliffPeriod;
        bool allowDeallocation;
    }

    event CreateUpFrontDeal(
        address indexed dealAddress,
        string name,
        string symbol,
        address purchaseToken,
        address underlyingDealToken,
        address indexed holder,
        address indexed sponsor,
        uint256 sponsorFee,
        bytes32 merkleRoot,
        string ipfsHash
    );

    event CreateUpFrontDealConfig(
        address indexed dealAddress,
        uint256 underlyingDealTokenTotal,
        uint256 purchaseTokenPerDealToken,
        uint256 purchaseRaiseMinimum,
        uint256 purchaseDuration,
        uint256 vestingPeriod,
        uint256 vestingCliffPeriod,
        bool allowDeallocation
    );

    event DepositDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );

    event DealFullyFunded(
        address upFrontDealAddress,
        uint256 timestamp,
        uint256 purchaseExpiryTimestamp,
        uint256 vestingCliffExpiryTimestamp,
        uint256 vestingExpiryTimestamp
    );

    event WithdrewExcess(address UpFrontDealAddress, uint256 amountWithdrawn);

    event AcceptDeal(
        address indexed user,
        uint256 amountPurchased,
        uint256 totalPurchased,
        uint256 amountDealTokens,
        uint256 totalDealTokens
    );

    event ClaimDealTokens(address indexed user, uint256 amountMinted, uint256 amountPurchasingReturned);

    event SponsorClaim(address indexed sponsor, uint256 amountMinted);

    event HolderClaim(
        address indexed holder,
        address purchaseToken,
        uint256 amountClaimed,
        address underlyingToken,
        uint256 underlyingRefund,
        uint256 timestamp
    );

    event FeeEscrowClaim(address indexed aelinFeeEscrow, address indexed underlyingTokenAddress, uint256 amount);

    event ClaimedUnderlyingDealToken(address indexed user, address underlyingToken, uint256 amountClaimed);

    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);

    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );

    event SetHolder(address indexed holder);

    event Vouch(address indexed voucher);

    event Disavow(address indexed voucher);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NftCheck.sol";
import "../interfaces/ICryptoPunks.sol";

library AelinNftGating {
    address constant CRYPTO_PUNKS = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    // collectionAddress should be unique, otherwise will override
    struct NftCollectionRules {
        // if 0, then unlimited purchase
        uint256 purchaseAmount;
        address collectionAddress;
        // if true, then `purchaseAmount` is per token
        // else `purchaseAmount` is per account regardless of the NFTs held
        bool purchaseAmountPerToken;
        // both variables below are only applicable for 1155
        uint256[] tokenIds;
        // min number of tokens required for participating
        uint256[] minTokensEligible;
    }

    struct NftGatingData {
        mapping(address => NftCollectionRules) nftCollectionDetails;
        mapping(address => mapping(address => bool)) nftWalletUsedForPurchase;
        mapping(address => mapping(uint256 => bool)) nftId;
        bool hasNftList;
    }

    struct NftPurchaseList {
        address collectionAddress;
        uint256[] tokenIds;
    }

    /**
     * @dev check if deal is nft gated, sets hasNftList
     * if yes, move collection rule array input to mapping in the data storage
     * @param _nftCollectionRules array of all nft collection rule data
     * @param _data contract storage data passed by reference
     */
    function initialize(NftCollectionRules[] calldata _nftCollectionRules, NftGatingData storage _data) external {
        if (_nftCollectionRules.length > 0) {
            // if the first address supports punks or 721, the entire pool only supports 721 or punks
            if (
                _nftCollectionRules[0].collectionAddress == CRYPTO_PUNKS ||
                NftCheck.supports721(_nftCollectionRules[0].collectionAddress)
            ) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(
                        _nftCollectionRules[i].collectionAddress == CRYPTO_PUNKS ||
                            NftCheck.supports721(_nftCollectionRules[i].collectionAddress),
                        "can only contain 721"
                    );
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];
                    emit PoolWith721(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken
                    );
                }
                _data.hasNftList = true;
            }
            // if the first address supports 1155, the entire pool only supports 1155
            else if (NftCheck.supports1155(_nftCollectionRules[0].collectionAddress)) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(NftCheck.supports1155(_nftCollectionRules[i].collectionAddress), "can only contain 1155");
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];

                    for (uint256 j; j < _nftCollectionRules[i].tokenIds.length; ++j) {
                        _data.nftId[_nftCollectionRules[i].collectionAddress][_nftCollectionRules[i].tokenIds[j]] = true;
                    }
                    emit PoolWith1155(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken,
                        _nftCollectionRules[i].tokenIds,
                        _nftCollectionRules[i].minTokensEligible
                    );
                }
                _data.hasNftList = true;
            } else {
                require(false, "collection is not compatible");
            }
        } else {
            _data.hasNftList = false;
        }
    }

    /**
     * @dev allows anyone to become a purchaser with a qualified erc721
     * nft in the pool depending on the scenarios
     *
     * Scenarios:
     * 1. each wallet holding a qualified NFT to deposit an unlimited amount of purchase tokens
     * 2. certain amount of purchase tokens per wallet regardless of the number of qualified NFTs held
     * 3. certain amount of Investment tokens per qualified NFT held
     * @param _nftPurchaseList nft collection address and token ids to use for purchase
     * @param _data contract storage data for nft gating passed by reference
     * @param _purchaseTokenAmount amount to purchase with, must not exceed max allowable from collection rules
     * @return uint256 max purchase token amount allowable
     */
    function purchaseDealTokensWithNft(
        NftPurchaseList[] calldata _nftPurchaseList,
        NftGatingData storage _data,
        uint256 _purchaseTokenAmount
    ) external returns (uint256) {
        require(_data.hasNftList, "pool does not have an NFT list");
        require(_nftPurchaseList.length > 0, "must provide purchase list");

        uint256 maxPurchaseTokenAmount;

        for (uint256 i; i < _nftPurchaseList.length; ++i) {
            NftPurchaseList memory nftPurchaseList = _nftPurchaseList[i];
            address _collectionAddress = nftPurchaseList.collectionAddress;
            uint256[] memory _tokenIds = nftPurchaseList.tokenIds;

            NftCollectionRules memory nftCollectionRules = _data.nftCollectionDetails[_collectionAddress];
            require(nftCollectionRules.collectionAddress == _collectionAddress, "collection not in the pool");

            if (nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                if (NftCheck.supports1155(_collectionAddress)) {
                    for (uint256 j; j < _tokenIds.length; ++j) {
                        unchecked {
                            uint256 collectionAllowance = nftCollectionRules.purchaseAmount *
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]);
                            // if there is an overflow of the pervious calculation, allow the max purchase token amount
                            if (
                                collectionAllowance / nftCollectionRules.purchaseAmount !=
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j])
                            ) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            } else {
                                maxPurchaseTokenAmount += collectionAllowance;
                                if (maxPurchaseTokenAmount < collectionAllowance) {
                                    maxPurchaseTokenAmount = type(uint256).max;
                                }
                            }
                        }
                    }
                } else {
                    unchecked {
                        uint256 collectionAllowance = nftCollectionRules.purchaseAmount * _tokenIds.length;
                        // if there is an overflow of the pervious calculation, allow the max purchase token amount
                        if (collectionAllowance / nftCollectionRules.purchaseAmount != _tokenIds.length) {
                            maxPurchaseTokenAmount = type(uint256).max;
                        } else {
                            maxPurchaseTokenAmount += collectionAllowance;
                            if (maxPurchaseTokenAmount < collectionAllowance) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            }
                        }
                    }
                }
            }

            if (!nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                require(!_data.nftWalletUsedForPurchase[_collectionAddress][msg.sender], "wallet already used for nft set");
                _data.nftWalletUsedForPurchase[_collectionAddress][msg.sender] = true;
                unchecked {
                    maxPurchaseTokenAmount += nftCollectionRules.purchaseAmount;
                    // if addition causes overflow the max allowance is max value of uint256
                    if (maxPurchaseTokenAmount < nftCollectionRules.purchaseAmount) {
                        maxPurchaseTokenAmount = type(uint256).max;
                    }
                }
            }

            if (nftCollectionRules.purchaseAmount == 0) {
                maxPurchaseTokenAmount = type(uint256).max;
            }

            if (NftCheck.supports721(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(IERC721(_collectionAddress).ownerOf(_tokenIds[j]) == msg.sender, "has to be the token owner");
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
            if (NftCheck.supports1155(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId not in the pool");
                    require(
                        IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]) >=
                            nftCollectionRules.minTokensEligible[j],
                        "erc1155 balance too low"
                    );
                }
            }
            if (_collectionAddress == CRYPTO_PUNKS) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(
                        ICryptoPunks(_collectionAddress).punkIndexToAddress(_tokenIds[j]) == msg.sender,
                        "not the owner"
                    );
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
        }

        require(_purchaseTokenAmount <= maxPurchaseTokenAmount, "purchase amount greater than max allocation");

        return (maxPurchaseTokenAmount);
    }

    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);

    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );
    event BlacklistNFT(address indexed collection, uint256 nftID);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library AelinAllowList {
    struct InitData {
        address[] allowListAddresses;
        uint256[] allowListAmounts;
    }

    struct AllowList {
        address[] allowListAddresses;
        uint256[] allowListAmounts;
        mapping(address => uint256) amountPerAddress;
        bool hasAllowList;
    }

    function initialize(InitData calldata _init, AllowList storage _self) external {
        if (_init.allowListAddresses.length > 0 || _init.allowListAmounts.length > 0) {
            require(
                _init.allowListAddresses.length == _init.allowListAmounts.length,
                "allowListAddresses and allowListAmounts arrays should have the same length"
            );
            _self.allowListAddresses = _init.allowListAddresses;
            _self.allowListAmounts = _init.allowListAmounts;
            for (uint256 i; i < _init.allowListAddresses.length; ++i) {
                _self.amountPerAddress[_init.allowListAddresses[i]] = _init.allowListAmounts[i];
            }
            _self.hasAllowList = true;
            emit AllowlistAddress(_init.allowListAddresses, _init.allowListAmounts);
        }
    }

    event AllowlistAddress(address[] indexed allowListAddresses, uint256[] allowlistAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library MerkleTree {
    struct UpFrontMerkleData {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    struct TrackClaimed {
        mapping(uint256 => uint256) claimedBitMap;
    }

    /**
     * @dev a function that checks if the index leaf node is valid and if the user has purchased.
     * will set the index node to purchased if approved
     */
    function purchaseMerkleAmount(
        UpFrontMerkleData calldata merkleData,
        TrackClaimed storage self,
        uint256 _purchaseTokenAmount,
        bytes32 merkleRoot
    ) external {
        require(!hasPurchasedMerkle(self, merkleData.index), "Already purchased tokens");
        require(msg.sender == merkleData.account, "cant purchase others tokens");
        require(merkleData.amount >= _purchaseTokenAmount, "purchasing more than allowance");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(merkleData.index, merkleData.account, merkleData.amount));
        require(MerkleProof.verify(merkleData.merkleProof, merkleRoot, node), "MerkleTree.sol: Invalid proof.");

        // Mark it claimed and send the token.
        _setPurchased(self, merkleData.index);
    }

    /**
     * @dev sets the claimedBitMap to true for that index
     */
    function _setPurchased(TrackClaimed storage self, uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        self.claimedBitMap[claimedWordIndex] = self.claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
     * @dev returns if address has purchased merkle
     * @return bool index of the leaf node has purchased or not
     */
    function hasPurchasedMerkle(TrackClaimed storage self, uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = self.claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAelinDeal {
    struct DealData {
        address underlyingDealToken;
        uint256 underlyingDealTokenTotal;
        uint256 vestingPeriod;
        uint256 vestingCliffPeriod;
        uint256 proRataRedemptionPeriod;
        uint256 openRedemptionPeriod;
        address holder;
        uint256 maxDealTotalSupply;
        uint256 holderFundingDuration;
    }

    struct Timeline {
        uint256 period;
        uint256 start;
        uint256 expiry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAelinPool {
    struct PoolData {
        string name;
        string symbol;
        uint256 purchaseTokenCap;
        address purchaseToken;
        uint256 duration;
        uint256 sponsorFee;
        uint256 purchaseDuration;
        address[] allowListAddresses;
        uint256[] allowListAmounts;
        NftCollectionRules[] nftCollectionRules;
    }

    // collectionAddress should be unique, otherwise will override
    struct NftCollectionRules {
        // if 0, then unlimited purchase
        uint256 purchaseAmount;
        address collectionAddress;
        // if true, then `purchaseAmount` is per token
        // else `purchaseAmount` is per account regardless of the NFTs held
        bool purchaseAmountPerToken;
        // both variables below are only applicable for 1155
        uint256[] tokenIds;
        // min number of tokens required for participating
        uint256[] minTokensEligible;
    }

    struct NftPurchaseList {
        address collectionAddress;
        uint256[] tokenIds;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface ICryptoPunks {
    function balanceOf(address) external view returns (uint256);

    function punkIndexToAddress(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library NftCheck {
    bytes4 public constant IERC165_ID = type(IERC165).interfaceId;
    bytes4 public constant IERC1155_ID = type(IERC1155).interfaceId;
    bytes4 public constant IERC721_ID = type(IERC721).interfaceId;

    function supports721(address collectionAddress) internal view returns (bool) {
        return _supportsInterface(collectionAddress, IERC721_ID);
    }

    function supports1155(address collectionAddress) internal view returns (bool) {
        return _supportsInterface(collectionAddress, IERC1155_ID);
    }

    function _supportsInterface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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