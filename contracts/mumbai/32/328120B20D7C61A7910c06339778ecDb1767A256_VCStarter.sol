// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../marketplace/VCMarketplaceFixedPrice.sol";
import "../marketplace/VCMarketplaceAuction.sol";

import "./VCCampaign.sol";
import "./VCProject.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCStarter.sol";

// import "../governance/VCGovernance.sol";
// import "../interfaces/IGovernance.sol";

error SttrTransferToEscrowFailed();
error SttrSenderNotMarketplace();
error SttrNotWhitelistedLab();
error SttrUserWithdrawalFailed();
error SttrMintPoCNftNotAllowed();
error SttrUnexpectedGovernanceAddress();

/**
 * @title Allow users to deposit or consult a pool’s status under eventual fundraising campaigns.
 * @notice Users can donate under different dynamics referred to as Funding models
 */

contract VCStarter is AccessControl {
    // TODO: add many more events for subgraphs!
    event SuccessfulUserWithdrawal(address indexed user);
    event SuccessfulPoCMint(address indexed user);
    event ProjectCreated(address indexed lab, uint256 indexed projectId);

    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @notice The list of whitelisted Laboratories
    mapping(address => bool) public isWhitelistedLab;

    /// @notice The VC Marketplace Auction contract address
    address public marketplaceAuction;

    /// @notice The VC Marketplace Fixed Price contract address
    address public marketplaceFixedPrice;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The address of the admin
    address public admin;

    /// @notice A Campaign contract template cloned for each campaign
    address public campaignTemplate;

    /// @notice A project contract template cloned for each project
    address public projectTemplate;

    /// @notice The maximum amount of time a Salvage Poll can last
    uint256 public maxPollDuration;

    /// @notice The Salvage Poll quorum
    uint256 public quorumPoll;

    /// @notice Protocol currency
    IERC20 public currency;

    /// @notice Proof of Collaboration NFT
    IPoCNft public pocNft;

    /// @notice An array of all deployed projects.
    VCProject[] private _projects;

    /**
     * @notice Constructor of the contract.
     *
     * @param _pool The VC Pool address.
     * @param _admin The address of the admin.
     * @param _campaignTemplate The escrow contract template.
     * @param _projectTemplate The project contract template.
     */
    constructor(
        address _pool,
        address _admin,
        address _campaignTemplate,
        address _projectTemplate
    ) {
        if (_admin == address(this) || _admin == address(0)) {
            revert SttrUnexpectedGovernanceAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        pool = _pool;
        admin = _admin;
        campaignTemplate = _campaignTemplate;
        projectTemplate = _projectTemplate;
    }

    /**
     * @dev Given a project identifier, checks if caller is the owner, i.e.
     * the laboratory that launched the project.
     *
     * @param _projectId The project identifier.
     */
    modifier onlyLab(uint256 _projectId) {
        require(msg.sender == _projects[_projectId].lab(), "STARTER: Sender must be the project's lab");
        _;
    }

    /**
     * @dev Checks if the project identifier is valid.
     */
    modifier validProject(uint256 _projectId) {
        require(_projectId < _projects.length, "STARTER: Invalid project id");
        _;
    }

    /**
     * @dev Checks if caller is the VC Marketplace smart contract.
     */
    modifier onlyMarketplace() {
        if (msg.sender != marketplaceAuction || msg.sender != marketplaceFixedPrice) {
            revert SttrSenderNotMarketplace();
        }
        _;
    }

    /**
     * @dev Checks if caller is a whitelisted Laboratory.
     */
    modifier onlyWhitelistedLab() {
        if (!isWhitelistedLab[msg.sender]) {
            revert SttrNotWhitelistedLab();
        }
        _;
    }

    function whitelistLabs(address[] memory _labs) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _labs.length; i++) {
            isWhitelistedLab[_labs[i]] = true;
        }
    }

    function blacklistLabs(address[] memory _labs) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _labs.length; i++) {
            isWhitelistedLab[_labs[i]] = false;
        }
    }

    // FIXME: if projects can be closed, this function should check the project
    // status before being added to the marketplace
    /**
     * @notice Allows owner to set marketplace address.
     *
     * @dev Migrates all active projects to the new marketplace.
     *
     * @param _newMarketplaceAuction New Marketplace Auction address.
     */
    function setMarketplaceAuction(address _newMarketplaceAuction) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketplaceAuction = _newMarketplaceAuction;
        for (uint256 i = 0; i < _projects.length; i++) {
            VCMarketplaceAuction(_newMarketplaceAuction).addProject(i);
        }
    }

    // FIXME: if projects can be closed, this function should check the project
    // status before being added to the marketplace
    /**
     * @notice Allows owner to set marketplace address.
     *
     * @dev Migrates all active projects to the new marketplace.
     *
     * @param _newMarketplaceFixedPrice New Marketplace Fixed Price address.
     */
    function setMarketplaceFixedPrice(address _newMarketplaceFixedPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketplaceFixedPrice = _newMarketplaceFixedPrice;
        for (uint256 i = 0; i < _projects.length; i++) {
            VCMarketplaceFixedPrice(_newMarketplaceFixedPrice).addProject(i);
        }
    }

    /**
     * @notice Allows owner to set the currency contract.
     *
     * @dev update currency on marketplace
     *
     * @param _currency new currency contract address
     */
    function setCurrency(IERC20 _currency) public onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = _currency;
    }

    function setPoCNft(address _pocNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pocNft = IPoCNft(_pocNft);
    }

    function setQuorumPoll(uint256 _quorumPoll) external onlyRole(DEFAULT_ADMIN_ROLE) {
        quorumPoll = _quorumPoll;
    }

    function setMaxPollDuration(uint256 _maxPollDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPollDuration = _maxPollDuration;
    }

    /**
     * @notice A whitelisted Laboratory initializes a project.
     *
     * @dev Creates a project clone.
     */
    function createProject() external onlyWhitelistedLab {
        address project = Clones.clone(projectTemplate);
        VCProject(project).init(address(this), admin, msg.sender);

        if (marketplaceFixedPrice != address(0)) {
            VCMarketplaceFixedPrice(marketplaceFixedPrice).addProject(_projects.length);
        }

        if (marketplaceAuction != address(0)) {
            VCMarketplaceAuction(marketplaceAuction).addProject(_projects.length);
        }

        _projects.push(VCProject(project));

        emit ProjectCreated(msg.sender, _projects.length - 1);
    }

    // IDEA: can a project be closed?
    // TODO: discuss with Sthorm team!
    // function closeProject() {}

    // TODO: the following should be discussed with Sthorm
    // IDEA: this should be createPendingCampaign and launch the campaign once approved by Governance.
    // IDEA: in Governance we approve a campaign if Core Team + Scientific Board accepts.
    /**
     * @notice A whitelisted Laboratory initializes a funding campaign.
     *
     * @dev Creates an escrow clone and attaches it to the project campaign.
     *
     * @param _projectId The project identifier to link the campaign to
     * @param _target The amount of USD required for the campaign
     * @param _stretchInBips Maximum percentage of target that a campaign can
     * raise past its original target goal.
     * @param _duration Maximum duration in seconds for the campaign to be active.
     */
    function createCampaign(
        uint256 _projectId,
        uint256 _target,
        uint256 _stretchInBips,
        uint256 _duration
    ) external validProject(_projectId) onlyLab(_projectId) returns (uint256) {
        VCProject project = _projects[_projectId];
        address campaign = Clones.clone(campaignTemplate);
        VCCampaign(campaign).init(project.lab(), pool, address(project));
        uint256 campaignId = project.createCampaign(
            campaign,
            _target,
            _stretchInBips,
            _duration,
            maxPollDuration,
            quorumPoll
        );
        // emit event
        return campaignId;
    }

    /**
     * @notice Allow sender to donate currency to a specific campaign.
     *
     * @dev Requires the campaign to have an ACTIVE status.
     * @dev Forwards `_amount` from sender to escrow contract.
     *
     * @param _projectId Index of project on projects array
     * @param _campaignId The campaign identifier.
     * @param _amount Amount of currency donated to the campaign.
     */
    function fundCampaign(
        uint256 _projectId,
        uint256 _campaignId,
        uint256 _amount
    ) external validProject(_projectId) {
        VCProject project = _projects[_projectId];
        if (currency.transferFrom(msg.sender, project.getCampaignData(_campaignId).campaign, _amount)) {
            revert SttrTransferToEscrowFailed();
        }
        project.fundCampaign(_campaignId, msg.sender, _amount);
    }

    // TODO: check if donation should go to either pool or project.
    // TODO: Test on Marketplace.js testing script
    /**
     * @notice Receive donations from marketplace purchases.
     *
     * @dev Transfer `_amount` from marketplace to either the escrow
     * contract or VC pool.
     *
     * @param _projectId The project identifier.
     * @param _amount Amount of currency marketplace forwards to the
     * project
     */
    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external onlyMarketplace {
        VCProject project = _projects[_projectId];
        currency.transferFrom(msg.sender, address(project), _amount);
        project.increaseMarketplaceFunding(_amount);
    }

    // FIXME: why do we make it onlyOwner? Maybe the Lab should be able to call this method as well.
    /**
     * @notice Allows owner to close a campaign.
     *
     * @dev Campaign cannot be already closed.
     * @dev Campaign cannot be running a Salvage Poll.
     * @dev Campaign status cannot be ACTIVE, i.e. must be either FAILED,
     * DEFEATED or SUCCEEDED.
     * @dev If campaign FAILED or has been DEFEATED, donations are returned
     * back to backers and marketplace contributions are sent to the VC Pool.
     * @dev If campaign SUCCEEDED, the pertinent splitting is done between
     * VC Pool and Lab.
     *
     * @param _projectId The project identifier.
     * @param _campaignId The campaign identifier.
     */
    function closeCampaign(
        uint256 _projectId,
        uint256 _campaignId,
        bool _ifFailDefeated,
        uint256 _duration
    ) external validProject(_projectId) onlyLab(_projectId) {
        VCProject project = _projects[_projectId];
        project.closeCampaign(_campaignId, _ifFailDefeated, _duration);
    }

    function withdrawOnCampaignDefeated(uint256 _projectId, uint256 _campaignId) external validProject(_projectId) {
        VCProject project = _projects[_projectId];
        if (!project.withdrawOnCampaignDefeated(_campaignId, msg.sender)) {
            revert SttrUserWithdrawalFailed();
        }
        emit SuccessfulUserWithdrawal(msg.sender);
    }

    function mintPoCNft(uint256 _projectId, uint256 _campaignId) external validProject(_projectId) {
        VCProject project = _projects[_projectId];
        (bool result, uint256 userAmount) = project.checkMintAllowed(_campaignId, msg.sender);
        if (!result) {
            revert SttrMintPoCNftNotAllowed();
        }
        pocNft.mint(msg.sender, userAmount);
        emit SuccessfulPoCMint(msg.sender);
    }

    // NOTE: this function does not apply anymore
    /**
     * @notice Allow lab to start a Salvage Poll if campaign has failed.
     *
     * @dev Requires campaign to be declared as FAILED on `_updateCampaignStatus`
     * @dev Creates an array of votes with UNSET vote type to track valid
     * voters.
     * @dev Possible results for poll are EXTEND, SETTLE or REJECT.
     *
     * @param _projectId the Project identifier.
     * @param _campaignId The FAILED campaign identifier.
     * @param _duration The extended funding time period.
     */
    function startSalvagePoll(
        uint256 _projectId,
        uint256 _campaignId,
        uint256 _duration
    ) external validProject(_projectId) onlyLab(_campaignId) {
        VCProject project = _projects[_projectId];
        project.startSalvagePoll(_campaignId, _duration);
    }

    // TODO: Add test cases for this function
    /**
     * @notice Allow backer to vote on a campaign salvage poll
     *
     * @dev Requires sender to be a valid voter, i.e. a campaign backer.
     * @dev Only campaigns with >70% of target can be voted for settlement.
     * @dev the vote power is based on the amount of CURE tokens the voter owns.
     *
     * @param _projectId The project identifier.
     * @param _campaignId The campaign identifier with an active salvage poll.
     */
    function voteSalvagePoll(
        uint256 _projectId,
        uint256 _campaignId,
        SalvagePollVoteType _voteType
    ) external validProject(_projectId) {
        uint256 votePower = VCGovernance(admin).votePower(msg.sender);
        VCProject project = _projects[_projectId];
        project.voteSalvagePoll(_campaignId, msg.sender, votePower, _voteType);
    }

    // TODO: Add test cases for this function
    /**
     * @notice Allows Lab to conclude the salvage poll if has all votes.
     *
     * @dev Requires sender to be the project lab.
     * @dev Requires salvage poll to be active.
     *
     * @param _projectId The project identifier.
     * @param _campaignId The campaign identifier with an active salvage poll.
     */
    // NOTE: why onlyLab? if the poll has expired everyone should be able to call this function
    function closeSalvagePoll(uint256 _projectId, uint256 _campaignId)
        external
        validProject(_projectId)
        onlyLab(_projectId)
    {
        VCProject project = _projects[_projectId];
        project.closeSalvagePoll(_campaignId, quorumPoll);
    }

    /**
     * @notice returns campaign data from id
     * @param _projectId Project id
     * @param _campaignId Campaign id
     */
    function getCampaignData(uint256 _projectId, uint256 _campaignId)
        external
        view
        validProject(_projectId)
        returns (CampaignData memory)
    {
        return _projects[_projectId].getCampaignData(_campaignId);
    }

    /**
     * @notice Retrieves the current raised amount for a funding campaign.
     *
     * @param _projectId The project.
     * @param _campaignId The campaign.
     */
    function getCampaignTotalFunding(uint256 _projectId, uint256 _campaignId) public view returns (uint256) {
        return _projects[_projectId].getCampaignTotalFunding(_campaignId);
    }

    /**
     * @notice Retrieves the current raised amount for a given project.
     *
     * @param _projectId The project identifier.
     */
    function getProjectTotalFunding(uint256 _projectId) public view returns (uint256) {
        return _projects[_projectId].getProjectTotalFunding();
    }

    /**
     * @notice Returns the salvage poll for a given campaign at a given project.
     *
     * @param _projectId The project identifier.
     * @param _campaignId The campaign identifier.
     */
    function getSalvagePoll(uint256 _projectId, uint256 _campaignId) external view returns (SalvagePoll memory poll) {
        poll = _projects[_projectId].getSalvagePoll(_campaignId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VCMarketplaceBase.sol";
import "../interfaces/IArtistNft.sol";
import "../interfaces/IVCStarter.sol";

contract VCMarketplaceFixedPrice is VCMarketplaceBase {
    error MktPurchaseFailed();
    error MktNotEnoughTokens();

    struct FixedPriceListing {
        bool minted;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 marketFee;
    }

    event ListedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        uint256 marketFee
    );
    event UpdatedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        uint256 marketFee
    );
    event UnlistedFixedPrice(address indexed token, uint256 indexed tokenId, address indexed seller, uint256 amount);
    event Purchased(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 listPrice,
        uint256 marketFee
    );

    // FIXME: remove first key, not anymore needed
    mapping(address => mapping(uint256 => mapping(address => FixedPriceListing))) public fixedPriceListings;

    constructor(
        address _artistNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artistNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to list a specific amount of an ERC1155
     * token with a given fixed price to the Marketplace.
     *
     * @param _tokenId the token identifier
     * @param _listPrice the listing price
     * @param _amount the amount of tokens to list
     * @param _poolFeeBps the fee transferred to the VC Pool on purchases
     * @param _projectIds Array of projects identifiers to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        uint256 marketFee = _toFee(_listPrice, marketplaceFeeBps);
        _setFees(address(artistNft), _tokenId, msg.sender, _poolFeeBps, _projectIds, _projectFeesBps);
        if (!listed(address(artistNft), _tokenId, msg.sender)) {
            _newList(_tokenId, _amount, _listPrice, marketFee);
            emit ListedFixedPrice(address(artistNft), _tokenId, msg.sender, _amount, _listPrice, marketFee);
        } else {
            _updateList(_tokenId, _amount, _listPrice, marketFee);
            emit UpdatedFixedPrice(address(artistNft), _tokenId, msg.sender, _amount, _listPrice, marketFee);
        }
    }

    function _newList(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 marketFee
    ) internal {
        bool minted = artistNft.exists(_tokenId);
        if (!minted) {
            artistNft.requireCanRequestMint(msg.sender, _tokenId, _amount);
        } else {
            artistNft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }
        fixedPriceListings[address(artistNft)][_tokenId][msg.sender] = FixedPriceListing(
            minted,
            msg.sender,
            _amount,
            _listPrice,
            marketFee
        );
    }

    function _updateList(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 marketFee
    ) internal {
        FixedPriceListing memory listing = fixedPriceListings[address(artistNft)][_tokenId][msg.sender];
        listing.price = _listPrice;
        listing.marketFee = marketFee;
        listing.amount += _amount;
        if (!listing.minted) {
            artistNft.requireCanRequestMint(msg.sender, _tokenId, listing.amount);
        } else {
            artistNft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }
        fixedPriceListings[address(artistNft)][_tokenId][msg.sender] = listing;
    }

    function listed(
        address _token,
        uint256 _tokenId,
        address seller
    ) public view returns (bool) {
        return fixedPriceListings[_token][_tokenId][seller].seller != address(0);
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to remove a specific amount of a token listing
     * from the Marketplace and sends back the asset to the seller.
     *
     * @param _tokenId the token identifier
     */
    function unlistFixedPrice(uint256 _tokenId, uint256 _amount) public {
        FixedPriceListing memory listing = fixedPriceListings[address(artistNft)][_tokenId][msg.sender];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        _updateFixedPriceListing(_tokenId, msg.sender, _amount);

        if (listing.minted) {
            artistNft.safeTransferFrom(address(this), listing.seller, _tokenId, _amount, "");
        }

        emit UnlistedFixedPrice(address(artistNft), _tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows a buyer, i.e. msg.sender, to purchase a token with fixed price in the Marketplace.
     * Tokens must be purchased for the price set by the seller plus the market fee.
     *
     * @param _tokenId the token identifier
     *
     */
    function purchase(uint256 _tokenId, address _seller) public whenNotPaused {
        FixedPriceListing memory listing = fixedPriceListings[address(artistNft)][_tokenId][_seller];

        if (listing.seller == address(0)) {
            revert MktTokenNotListed();
        }

        _updateFixedPriceListing(_tokenId, _seller, 1);

        (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _chargeFee(
            address(artistNft),
            _tokenId,
            _seller,
            currency,
            listing.price,
            listing.marketFee
        );
        resultingAmount -= _chargeRoyalty(_tokenId, listing.price);
        if (!currency.transferFrom(msg.sender, listing.seller, resultingAmount)) {
            revert MktPurchaseFailed();
        }
        if (!listing.minted) {
            artistNft.mint(_tokenId, listing.amount);
            fixedPriceListings[address(artistNft)][_tokenId][_seller].minted = true;
        }
        artistNft.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");

        pocNft.mint(msg.sender, listing.marketFee);
        pocNft.mint(listing.seller, starterFee + poolFee);

        emit Purchased(msg.sender, address(artistNft), _tokenId, listing.seller, listing.price, listing.marketFee);
    }

    function _updateFixedPriceListing(
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) internal {
        FixedPriceListing memory listing = fixedPriceListings[address(artistNft)][_tokenId][_seller];

        if (listing.amount == _amount) {
            delete fixedPriceListings[address(artistNft)][_tokenId][_seller];
        } else if (listing.amount > _amount) {
            fixedPriceListings[address(artistNft)][_tokenId][_seller].amount -= _amount;
        } else {
            revert MktNotEnoughTokens();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VCMarketplaceBase.sol";
import "../interfaces/IArtistNft.sol";
import "../interfaces/IVCStarter.sol";

contract VCMarketplaceAuction is VCMarketplaceBase {
    error MktAlreadyListed();
    error MktExistingBid();
    error MktBidderNotAllowed();
    error MktBidTooLate();
    error MktBidTooLow();
    error MktSettleFailed();
    error MktSettleTooEarly();

    struct AuctionListing {
        bool minted;
        address seller;
        uint256 initialPrice;
        uint256 maturity;
        address highestBidder;
        uint256 highestBid;
        uint256 marketFee;
    }

    event ListedAuction(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 initialPrice,
        uint256 marketFee,
        uint256 maturity
    );
    event UnlistedAuction(address indexed seller, address indexed token, uint256 indexed tokenId);
    event Settled(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 tokenId,
        uint256 endPrice
    );
    event Bid(address indexed bidder, address indexed token, uint256 indexed tokenId, uint256 amount);

    mapping(address => mapping(uint256 => AuctionListing)) public auctionListings;

    constructor(
        address _artistNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artistNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to list only ERC1155 NFTs
     * with a given initial price to the Marketplace.
     *
     * @param _tokenId the token identifier
     * @param _initialPrice minimum price set by the seller
     * @param _biddingDuration duration of the auction in seconds
     * @param _projectIds Array of projects identifiers to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listAuction(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _biddingDuration,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        // creator or collector cannot re-list
        if (auctionListings[address(artistNft)][_tokenId].seller != address(0)) {
            revert MktAlreadyListed();
        }

        bool minted = artistNft.exists(_tokenId);

        _checkSupply(minted, _tokenId);

        uint256 marketFee = _toFee(_initialPrice, marketplaceFeeBps);

        _setFees(address(artistNft), _tokenId, msg.sender, _poolFeeBps, _projectIds, _projectFeesBps);

        uint256 maturity = block.timestamp + _biddingDuration;

        _newList(minted, _tokenId, _initialPrice, maturity, marketFee);

        emit ListedAuction(address(artistNft), _tokenId, msg.sender, _initialPrice, marketFee, maturity);
    }

    function _checkSupply(bool _minted, uint256 _tokenId) internal {
        uint256 totalSupply = _minted ? artistNft.totalSupply(_tokenId) : artistNft.lazyTotalSupply(_tokenId);
        require(totalSupply == 1, "Can auction NFTs only");
    }

    function _newList(
        bool minted,
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _maturity,
        uint256 marketFee
    ) internal {
        if (!minted) {
            artistNft.requireCanRequestMint(msg.sender, _tokenId, 1);
        } else {
            artistNft.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        }

        auctionListings[address(artistNft)][_tokenId] = AuctionListing(
            minted,
            msg.sender,
            _initialPrice,
            _maturity,
            address(0),
            0,
            marketFee
        );
    }

    /**
     * @dev Cancels the token auction from the Marketplace and sends back the
     * asset to the seller.
     *
     * Requirements:
     *
     * - The token must not have a bid placed, if there is a bid the transaction will fail
     *
     * @param _tokenId the token identifier
     */
    function unlistAuction(uint256 _tokenId) public {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        if (listing.highestBid != 0) {
            revert MktExistingBid();
        }

        delete auctionListings[address(artistNft)][_tokenId];

        if (listing.minted) {
            artistNft.safeTransferFrom(address(this), listing.seller, _tokenId, 1, "");
        }

        emit UnlistedAuction(msg.sender, address(artistNft), _tokenId);
    }

    /**
     * @dev Places a bid for a token listed in the Marketplace. If the bid is valid,
     * previous bid amount and its market fee gets returned back to previous bidder,
     * while current bid amount and market fee is charged to current bidder.
     *
     * @param _tokenId the token identifier
     * @param _amount the bid amount
     */
    function bid(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        _checkBeforeBid(listing, _amount);

        if (listing.highestBid != 0) {
            currency.transfer(listing.highestBidder, listing.highestBid + listing.marketFee);
        }

        uint256 marketFee = _toFee(_amount, marketplaceFeeBps);

        currency.transferFrom(msg.sender, address(this), _amount + marketFee);

        listing.highestBidder = msg.sender;
        listing.highestBid = _amount;
        listing.marketFee = marketFee;
        auctionListings[address(artistNft)][_tokenId] = listing;

        emit Bid(msg.sender, address(artistNft), _tokenId, _amount);
    }

    /**
     * @dev Allows anyone to settle the auction. If there are no bids, the seller
     * receives back the NFT
     *
     * @param _tokenId the token identifier
     */
    function settle(uint256 _tokenId) public whenNotPaused {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        _checkBeforeSettle(listing);

        delete auctionListings[address(artistNft)][_tokenId];

        if (listing.highestBid != 0) {
            (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _transferFee(
                address(artistNft),
                _tokenId,
                listing.seller,
                currency,
                listing.highestBid,
                listing.marketFee
            );
            resultingAmount -= _transferRoyalty(_tokenId, listing.highestBid);
            if (!currency.transfer(listing.seller, resultingAmount)) {
                revert MktSettleFailed();
            }
            if (!listing.minted) {
                artistNft.mint(_tokenId, 1);
            }
            artistNft.safeTransferFrom(address(this), listing.highestBidder, _tokenId, 1, "");
            pocNft.mint(listing.highestBidder, listing.marketFee);
            pocNft.mint(listing.seller, starterFee + poolFee);
        } else {
            if (listing.minted) {
                artistNft.safeTransferFrom(address(this), listing.seller, _tokenId, 1, "");
            }
        }

        emit Settled(listing.highestBidder, listing.seller, address(artistNft), _tokenId, listing.highestBid);
    }

    function _checkBeforeBid(AuctionListing memory listing, uint256 _amount) internal view {
        if (listing.seller == address(0)) {
            revert MktTokenNotListed();
        }
        if (listing.seller == msg.sender) {
            revert MktBidderNotAllowed();
        }
        if (block.timestamp > listing.maturity) {
            revert MktBidTooLate();
        }
        if (_amount < listing.highestBid || _amount < listing.initialPrice) {
            revert MktBidTooLow();
        }
    }

    function _checkBeforeSettle(AuctionListing memory listing) internal view {
        if (listing.seller == address(0)) {
            revert MktTokenNotListed();
        }
        if (!(block.timestamp > listing.maturity)) {
            revert MktSettleTooEarly();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCStarter.sol";

contract VCCampaign is Initializable, AccessControl {
    IVCStarter public starter;
    bool public campaignSucceeded;
    IERC20 public currency;
    bool public campaignDefeated;
    address public lab;
    uint96 public totalFunders;
    address public pool;
    mapping(address => uint256) public fundings;
    uint256 public totalFunding;

    error CampaignUnexpectedAdminAddress();
    error CampaignMintNotAllowed();
    error CampaignInvalidUser();
    error CampaignWithdrawNotAllowed();
    error CampaignAlreadySucceeded();
    error CampaignUserAlreadyWithdrew();
    error CampaignOnlyStarterAllowed();

    event UserWithdrawal(address indexed user, uint256 amount, uint256 time);
    event CampaignSucceeded(uint256 time);
    event CampaignFailed(uint256 time);

    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor() {}

    function init(
        address _lab,
        address _pool,
        address _project
    ) public initializer {
        if (_project == address(this) || _project == address(0)) {
            revert CampaignUnexpectedAdminAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _project);
        starter = IVCStarter(msg.sender);
        currency = IERC20(starter.currency());
        lab = _lab;
        pool = _pool;
    }

    function onCampaignSucceeded(uint256 _extraGain) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (campaignSucceeded) {
            revert CampaignAlreadySucceeded();
        }
        campaignSucceeded = true;
        (uint256 poolAmount, uint256 labAmount) = _splitFunding(totalFunding, _extraGain);

        totalFunding = 0;
        currency.transfer(lab, labAmount);
        currency.transfer(pool, poolAmount);
        // this could be moved to project
        emit CampaignSucceeded(block.timestamp);
    }

    function onCampaignDefeated() external onlyRole(DEFAULT_ADMIN_ROLE) {
        campaignDefeated = true;
        // this could be moved to project
        emit CampaignFailed(block.timestamp);
    }

    function checkMintAllowed(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool, uint256) {
        if (!campaignSucceeded || !(fundings[_user] > 0)) {
            return (false, 0);
        }
        uint256 userAmount = fundings[_user];
        fundings[_user] = 0;
        return (true, userAmount);
    }

    function withdrawOnCampaignDefeated(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (!campaignDefeated) {
            revert CampaignWithdrawNotAllowed();
        }
        if (!(fundings[_user] > 0)) {
            revert CampaignInvalidUser();
        }
        uint256 userAmount = fundings[_user];
        totalFunding -= userAmount;
        fundings[_user] = 0;
        if (!currency.transfer(_user, userAmount)) {
            return false;
        }
        emit UserWithdrawal(_user, userAmount, block.timestamp);
        return true;
    }

    function fund(address _funder, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (fundings[_funder] == 0) {
            totalFunders++;
        }
        fundings[_funder] += _amount;
        totalFunding += _amount;

        // bool existingDonor = false;
        // for (uint256 i = 0; i < _donations.length; i++) {
        //     if (_donations[i].donor == _donor) {
        //         _donations[i].amount += _amount;
        //         existingDonor = true;
        //         break;
        //     }
        // }
        // if (!existingDonor) {
        //     _donations.push(Donation({amount: _amount, donor: _donor}));
        // }
        // totalDonations += _amount;
        // emit event
    }

    function getFundings(address _user) public view returns (uint256) {
        return fundings[_user];
    }

    // function getDonations() external view returns (Donation[] memory) {
    //     return _donations;
    // }

    function _splitFunding(uint256 _funding, uint256 _extraFunding)
        private
        pure
        returns (uint256 poolAmount, uint256 labAmount)
    {
        uint256 target = _funding - _extraFunding;

        poolAmount = _fromBips(target, 2000);
        poolAmount += _fromBips(_extraFunding, 500);

        labAmount = _fromBips(target, 8000);
        labAmount += _fromBips(_extraFunding, 9500);
    }

    function _fromBips(uint256 _totalAmount, uint256 _bips) internal pure returns (uint256) {
        return (_totalAmount * _bips) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../governance/VCGovernance.sol";
import "../interfaces/IVCStarter.sol";
import "./VCCampaign.sol";

// import "../starter/VCStarter.sol";

enum CampaignStatus {
    ACTIVE,
    FAILED,
    DEFEATED,
    SUCCEEDED
}

struct CampaignData {
    uint256 id;
    bool closed;
    address campaign;
    uint256 target;
    uint256 maturity;
    uint256 maxTarget;
    CampaignStatus status;
    SalvagePoll salvagePoll;
}

enum SalvagePollStatus {
    INACTIVE,
    ACTIVE,
    REJECTED,
    EXTENDED,
    SETTLED
}

struct SalvagePoll {
    // bool launched;         // if already launched
    uint256 campaignDuration; // extended Campaign duration
    uint256 duration; // poll duration
    uint256 maturity; // pool maturity
    uint256 quorum;
    uint256 votersCount;
    uint256 settleCount;
    uint256 extendCount;
    uint256 rejectCount;
    SalvagePollStatus status;
}

enum SalvagePollVoteType {
    UNSET,
    REJECT,
    EXTEND,
    SETTLE
}

// struct SalvagePollVote {
//     uint256 votePower;
//     SalvagePollVoteType voteType;
// }

error ProjectCampaignAlreadyClosed();
error ProjectCampaignAlreadyFinished();
error ProjectCampaignAlreadyFailed();
error ProjectCampaignAlreadyDefeated();

// FIXME: should be renamed to Project at the beginning instead of SalvagePoll
error SalvagePollTransferToVCPoolFailed(); // not used
error SalvagePollCampaignHasOpenedSalvagePoll();
error SalvagePollCampaignStillActive();
error SalvagePollTransferLabFailed(); // not used
error SalvagePollNotActive();
error SalvagePollTransferVCPoolFailed(); // not used
error SalvagePollTransferFromMarketFailed(); // not used
error SalvagePollInvalidVoter();
error SalvagePollCanNotBeClosed();
error SalvagePollSalvagePollCreated();
error SalvagePollHasExpired();

contract VCProject is Initializable {
    address public lab;
    address public starter;
    address public admin;
    uint256 public marketplaceFunding;

    /// @notice Maps Campaign identifiers and accounts to their SalvagePollsVoteType struct
    mapping(uint256 => mapping(address => SalvagePollVoteType)) private _votes;

    /// @notice An array of all project Campaigns
    CampaignData[] private _campaigns;

    modifier onlyStarter() {
        require(msg.sender == starter, "PROJECT: Function can only be called by starter");
        _;
    }

    // NOT USED
    // modifier allowedVoter(uint256 _campaignId, address _voter) {
    //     address[] memory voters = _campaigns[_campaignId].salvagePoll.voters;
    //     bool isAllowed = false;
    //     bool hasVoted = false;
    //     for (uint256 i = 0; i < voters.length; i++) {
    //         if (voters[i] == _voter) {
    //             isAllowed = true;
    //             hasVoted = _votes[_campaignId][_voter].voteType == SalvagePollVoteType.UNSET;
    //             break;
    //         }
    //     }
    //     require(isAllowed, "STARTER: Sender has not backed this campaign");
    //     require(!hasVoted, "STARTER: Sender has already voted");
    //     _;
    // }

    modifier validVote(uint256 _campaignId, SalvagePollVoteType _voteType) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        uint256 totalFunding = VCCampaign(campaignData.campaign).totalFunding();
        require(
            _voteType != SalvagePollVoteType.SETTLE || totalFunding > (campaignData.target * 70) / 100,
            "STARTER: Cannot settle if campaign has not raised >70% of target"
        );
        _;
    }

    constructor() {}

    function init(
        address _starter,
        address _admin,
        address _lab
    ) public initializer {
        starter = _starter;
        admin = _admin;
        lab = _lab;
    }

    // FIXME: how do we claim this funds?
    function increaseMarketplaceFunding(uint256 _amount) external onlyStarter {
        marketplaceFunding += _amount;
    }

    /**
     * @notice Refer to VCStarter `createCampaign` documentation.
     */
    function createCampaign(
        address _campaign,
        uint256 _target,
        uint256 _stretchInBips,
        uint256 _duration,
        uint256 _maxPollDuration,
        uint256 _pollQuorum
    ) external onlyStarter returns (uint256) {
        CampaignData memory campaignData = CampaignData({
            id: _campaigns.length,
            closed: false,
            campaign: _campaign,
            target: _target,
            maturity: block.timestamp + _duration,
            maxTarget: _target + (_target * _stretchInBips) / 10000,
            status: CampaignStatus.ACTIVE,
            salvagePoll: SalvagePoll(0, _maxPollDuration, 0, _pollQuorum, 0, 0, 0, 0, SalvagePollStatus.INACTIVE)
        });

        _campaigns.push(campaignData);

        return campaignData.id;
    }

    /**
     * @notice Computes the Campaign status based on its donated amount and
     * maturity.
     *
     * @dev ACTIVE iff maxTarget has not been reached within duration.
     * @dev SUCCEEDED iff maxTarget has been reached within duration
     * or target has been reached after maturity.
     * @dev FAILED iff target has not been reached after duration.
     * @dev A DEFEATED campaign remains DEFEATED.
     *
     * @param _campaign Campaign to update status
     */
    function _updateCampaignStatus(CampaignData memory _campaign) internal {
        if (_campaign.closed || _campaign.status == CampaignStatus.DEFEATED) {
            return;
        }

        uint256 campaignTotalFunding = VCCampaign(_campaign.campaign).totalFunding();

        if (campaignTotalFunding < _campaign.target) {
            if (block.timestamp < _campaign.maturity) {
                _campaign.status = CampaignStatus.ACTIVE;
            } else {
                _campaign.status = CampaignStatus.FAILED;
            }
        } else if (campaignTotalFunding < _campaign.maxTarget) {
            if (block.timestamp < _campaign.maturity) {
                _campaign.status = CampaignStatus.ACTIVE;
            } else {
                _campaign.status = CampaignStatus.SUCCEEDED;
            }
        } else {
            _campaign.status = CampaignStatus.SUCCEEDED;
        }

        _campaigns[_campaign.id] = _campaign;
    }

    /**
     * @notice Refer to VCStarter `fundCampaign` documentation.
     */
    function fundCampaign(
        uint256 _campaignId,
        address _donor,
        uint256 _amount
    ) external {
        CampaignData memory campaignData = _campaigns[_campaignId];

        // FIXME: here we are updating in memory and then checking in before fund something
        // that has not been updated!
        _updateCampaignStatus(campaignData);

        _checkBeforeFund(campaignData);

        VCCampaign(campaignData.campaign).fund(_donor, _amount);
    }

    // FIXME: this function should not be named closeCampaign, as it can not close a Campaign and
    // start a salvage poll instead!
    // FIXME: Once a salvage poll fails again, here we can start a new Salvage poll, we should avoid that
    /**
     * @notice Refer to VCStarter `closeCampaign` documentation.
     */
    function closeCampaign(
        uint256 _campaignId,
        bool _ifFailDefeated,
        uint256 _duration // the extended funding time period
    ) external onlyStarter {
        CampaignData memory campaignData = _checkBeforeCloseCampaign(_campaignId);
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaignData.status == CampaignStatus.FAILED) {
            if (_ifFailDefeated) {
                campaignData.status = CampaignStatus.DEFEATED;
                campaign.onCampaignDefeated();
                campaignData.closed = true;
            } else {
                // NOTE: Users will be locked here, they are not able to mintNFT nor withdraw, salvage poll is available, but what happens if there is no
                // salvage poll? i propose that the salvage poll is created here automatically, the lab has the decision since the can specify `failIfDefeated`
                // for that i will make public `startSalvagePoll` but this is just to avoid compiling errors i think there is no need, it should be internal
                // and if required called automatically by this function (and delete it from Starter)
                if (campaignData.salvagePoll.status == SalvagePollStatus.ACTIVE) {
                    revert SalvagePollSalvagePollCreated();
                }

                // if (campaignData.salvagePoll.launched) {
                //     revert SalvagePollSalvagePollCreated();
                // }

                startSalvagePoll(_campaignId, _duration);
            }
        } else {
            uint256 campaignTotalFunding = campaign.totalFunding();
            campaign.onCampaignSucceeded(
                campaignTotalFunding > campaignData.target ? campaignTotalFunding - campaignData.target : 0
            );
            campaignData.closed = true;
        }
        _campaigns[_campaignId] = campaignData;
    }

    function withdrawOnCampaignDefeated(uint256 _campaignId, address _user) public onlyStarter returns (bool) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.status != CampaignStatus.DEFEATED) {
            revert();
        }
        VCCampaign campaign = VCCampaign(campaignData.campaign);
        if (!campaign.withdrawOnCampaignDefeated(_user)) {
            return false;
        }
        return true;
    }

    /**
     * @notice Refer to VCStarter `startSalvagePoll` documentation.
     */
    function startSalvagePoll(uint256 _campaignId, uint256 _duration) public {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        _updateCampaignStatus(campaignData);

        require(
            campaignData.status == CampaignStatus.FAILED,
            "STARTER: Only failed campaigns can start a salvage poll"
        );

        // Funding[] memory fundings = Escrow(campaign.campaign).getFundings();
        // for (uint256 i = 0; i < fundings.length; i++) {
        //     campaign.salvagePoll.voters.push(fundings[i].funder);
        // }

        campaignData.salvagePoll.status = SalvagePollStatus.ACTIVE;
        campaignData.salvagePoll.campaignDuration = _duration;
        campaignData.salvagePoll.maturity = block.timestamp + campaignData.salvagePoll.duration;
        _campaigns[_campaignId] = campaignData;
    }

    /**
     * @notice Refer to VCStarter `voteSalvagePoll` documentation.
     */
    function voteSalvagePoll(
        uint256 _campaignId,
        address _voter,
        uint256 _votePower,
        SalvagePollVoteType _voteType
    ) external validVote(_campaignId, _voteType) onlyStarter {
        CampaignData memory campaignData = _campaigns[_campaignId];

        _checkBeforeVoteSalvagePoll(campaignData, _campaignId, _voter);

        campaignData.salvagePoll.votersCount++;

        // _votes[_campaignId][_voter].votePower = _votePower;
        _votes[_campaignId][_voter] = _voteType;
        if (_voteType == SalvagePollVoteType.SETTLE) {
            campaignData.salvagePoll.settleCount += _votePower;
        } else if (_voteType == SalvagePollVoteType.EXTEND) {
            campaignData.salvagePoll.extendCount += _votePower;
        } else {
            campaignData.salvagePoll.rejectCount += _votePower;
        }

        _campaigns[_campaignId] = campaignData;
    }

    // TODO: Add test cases for this function
    /**
     * @notice Refer to VCStarter `closeSalvagePoll` documentation.
     */
    function closeSalvagePoll(uint256 _campaignId, uint256 _quorum) external onlyStarter {
        CampaignData memory campaignData = _campaigns[_campaignId];

        _checkBeforeCloseSalvagePoll(campaignData, _quorum);

        (SalvagePollStatus pollStatus, CampaignStatus campaignStatus) = _getStatusFromSalvagePoll(
            campaignData.salvagePoll
        );

        campaignData.salvagePoll.status = pollStatus;
        campaignData.status = campaignStatus;

        VCCampaign campaign = VCCampaign(campaignData.campaign);
        if (pollStatus == SalvagePollStatus.EXTENDED) {
            campaignData.maturity = block.timestamp + campaignData.salvagePoll.campaignDuration;
        } else if (pollStatus == SalvagePollStatus.REJECTED) {
            // if the Poll status is REJECTED we allow the users to withdraw their USDC
            campaign.onCampaignDefeated();
            campaignData.closed = true;
        } else {
            campaign.onCampaignSucceeded(0);
            campaignData.closed = true;
        }
        _campaigns[_campaignId] = campaignData;
    }

    function _checkBeforeFund(CampaignData memory campaignData) private pure {
        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }
        if (campaignData.status == CampaignStatus.SUCCEEDED) {
            revert ProjectCampaignAlreadyFinished();
        }
        if (campaignData.status == CampaignStatus.DEFEATED) {
            revert ProjectCampaignAlreadyDefeated();
        }
        if (campaignData.status == CampaignStatus.FAILED) {
            revert ProjectCampaignAlreadyFailed();
        }
    }

    function _checkBeforeCloseCampaign(uint256 _campaignId) private returns (CampaignData memory) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }
        if (campaignData.salvagePoll.status == SalvagePollStatus.ACTIVE) {
            revert SalvagePollCampaignHasOpenedSalvagePoll();
        }
        _updateCampaignStatus(campaignData);
        // get again the SCampaing since it should have changed inside _updateCampaignStatus()
        campaignData = _campaigns[_campaignId];

        if (campaignData.status == CampaignStatus.ACTIVE) {
            revert SalvagePollCampaignStillActive();
        }
        return campaignData;
    }

    function checkMintAllowed(uint256 _campaignId, address _user) public onlyStarter returns (bool, uint256) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        VCCampaign campaign = VCCampaign(campaignData.campaign);
        (bool result, uint256 userAmount) = campaign.checkMintAllowed(_user);
        if (!result) {
            return (false, userAmount);
        }
        return (true, userAmount);
    }

    function _checkBeforeVoteSalvagePoll(
        CampaignData memory campaignData,
        uint256 _campaignId,
        address _voter
    ) private view {
        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        if (campaignData.salvagePoll.status != SalvagePollStatus.ACTIVE) {
            revert SalvagePollNotActive();
        }

        if (block.timestamp > campaignData.salvagePoll.maturity) {
            revert SalvagePollHasExpired();
        }

        if (!_validateVoter(_campaignId, _voter)) {
            revert SalvagePollInvalidVoter();
        }
    }

    function _checkBeforeCloseSalvagePoll(CampaignData memory campaignData, uint256 _quorum) private view {
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        if (campaignData.salvagePoll.status != SalvagePollStatus.ACTIVE) {
            revert SalvagePollNotActive();
        }

        if (
            campaignData.salvagePoll.votersCount <= (campaign.totalFunders() * _quorum) / 100 ||
            block.timestamp <= campaignData.salvagePoll.maturity
        ) {
            revert SalvagePollCanNotBeClosed();
        }
    }

    /**
     * @notice Retrieves campaign data.
     *
     * @param _campaignId The campaign identifier.
     */
    function getCampaignData(uint256 _campaignId) external view returns (CampaignData memory) {
        return _campaigns[_campaignId];
    }

    /**
     * @notice Retrieves the current raised amount for a funding campaign.
     *
     * @param _campaignId The campaign identifier.
     */
    function getCampaignTotalFunding(uint256 _campaignId) public view returns (uint256) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        return VCCampaign(campaignData.campaign).totalFunding();
    }

    /**
     * @notice Retrieves the current raised amount for the project itself.
     */
    function getProjectTotalFunding() external view returns (uint256) {
        uint256 projectTotalFunding = 0;
        for (uint256 i = 0; i < _campaigns.length; i++) {
            CampaignData memory campaignData = _campaigns[i];
            projectTotalFunding += VCCampaign(campaignData.campaign).totalFunding();
        }
        projectTotalFunding += marketplaceFunding;
        return projectTotalFunding;
    }

    /**
     * @notice Retrieves salvage poll data.
     *
     * @param _campaignId The campaign identifier.
     */
    function getSalvagePoll(uint256 _campaignId) external view returns (SalvagePoll memory) {
        return _campaigns[_campaignId].salvagePoll;
    }

    /**
     * @dev Calculate and returns the campaign and poll status based on the votes
     * @param _salvagePoll Salvage poll to calculate votes
     * @return A pair of objects SalvagePollStatus and CampaignStatus
     */
    function _getStatusFromSalvagePoll(SalvagePoll memory _salvagePoll)
        internal
        pure
        returns (SalvagePollStatus, CampaignStatus)
    {
        return
            _salvagePoll.settleCount > _salvagePoll.extendCount && _salvagePoll.settleCount > _salvagePoll.rejectCount
                ? (SalvagePollStatus.SETTLED, CampaignStatus.SUCCEEDED)
                : _salvagePoll.extendCount > _salvagePoll.rejectCount
                ? (SalvagePollStatus.EXTENDED, CampaignStatus.ACTIVE)
                : (SalvagePollStatus.REJECTED, CampaignStatus.DEFEATED);
    }

    function _validateVoter(uint256 _campaignId, address _voter) internal view returns (bool) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaign.getFundings(_voter) == 0 || (_votes[_campaignId][_voter] != SalvagePollVoteType.UNSET)) {
            return false;
        }
        return true;

        // address[] memory voters = _campaigns[_campaignId].salvagePoll.voters;
        // bool isAllowed = false;
        // bool hasVoted = false;
        // for (uint256 i = 0; i < voters.length; i++) {
        //     if (voters[i] == _voter) {
        //         isAllowed = true;
        //         hasVoted = _votes[_campaignId][_voter].voteType != SalvagePollVoteType.UNSET;
        //         break;
        //     }
        // }
        // require(isAllowed, "STARTER: Sender has not backed this campaign");
        // require(!hasVoted, "STARTER: Sender has already voted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external returns (uint256 _currentTokenId);

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    function currency() external returns (IERC20);

    function setPoCNft(address _poCNFT) external;

    function setMarketplaceAuction(address _newMarketplace) external;

    function setMarketplaceFixedPrice(address _newMarketplace) external;

    function whitelistLabs(address[] memory _labs) external;

    function setCurrency(IERC20 _currency) external;

    function setQuorumPoll(uint256 _quorumPoll) external;

    function setMaxPollDuration(uint256 _maxPollDuration) external;

    function maxPollDuration() external view returns (uint256);

    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./FeeBeneficiary.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IArtistNft.sol";

abstract contract VCMarketplaceBase is FeeBeneficiary, Pausable {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktNotWhitelistedToken();
    error MktRoyaltyChargeFailed();
    error MktRoyaltyTransferFailed();

    /// @notice The Marketplace currency.
    IERC20 public currency;

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Artist Non-Fungible Token
    IArtistNft public artistNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artistNft) {
        artistNft = IArtistNft(_artistNft);
    }

    /**
     * @dev pause or unpause the Marketplace
     */
    function pause(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     */
    function setPoCNft(address _pocNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pocNft = IPoCNft(_pocNft);
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = _currency;
    }

    // IDEA: we left this function just in case, there is no real use for the moment.
    /**
     * @dev Allows the withdrawal of any `ERC20` token from the Marketplace to
     * any account. Can only be called by the owner.
     *
     * Requirements:
     *
     * - Contract balance has to be equal or greater than _amount
     *
     * @param _token: ERC20 token address to withdraw
     * @param _to: Address that will receive the transfer
     * @param _amount: Amount to withdraw
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(_token).balanceOf(address(this)) > _amount);
        IERC20(_token).transfer(_to, _amount);
    }

    function _fundProject(uint256 _projectId, uint256 _amount) internal override {
        IVCStarter(starter).fundProjectFromMarketplace(_projectId, _amount);
    }

    /**
     * @dev Computes the royalty amount and transfers it from sender to the
     * asset creator, i.e. the royalty beneficiary.
     *
     * @param _tokenId: NFT token ID
     * @param _amount: A pertinent amount used to compute the royalty.
     *
     * NOTE: Charges fee to msg.sender, i.e. buyer.
     */
    function _chargeRoyalty(uint256 _tokenId, uint256 _amount) internal returns (uint256) {
        (address receiver, uint256 royaltyAmount) = IERC2981(address(artistNft)).royaltyInfo(_tokenId, _amount);
        if (royaltyAmount > 0) {
            if (!currency.transferFrom(msg.sender, receiver, royaltyAmount)) {
                revert MktRoyaltyChargeFailed();
            }
        }
        return royaltyAmount;
    }

    /**
     * @dev Computes the royalty amount and transfers it from the Marketplace
     * to the asset creator, i.e. the royalty beneficiary.
     *
     * @param _tokenId: NFT token ID
     * @param _amount: A pertinent amount used to compute the royalty.
     *
     * NOTE: Transfer royalty from contract (Market) itself.
     */
    function _transferRoyalty(uint256 _tokenId, uint256 _amount) internal returns (uint256) {
        (address receiver, uint256 royaltyAmount) = IERC2981(address(artistNft)).royaltyInfo(_tokenId, _amount);
        if (royaltyAmount > 0) {
            if (!currency.transfer(receiver, royaltyAmount)) {
                revert MktRoyaltyTransferFailed();
            }
        }
        return royaltyAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IArtistNft is IERC1155 {
    function mint(uint256 _tokenId, uint256 _amount) external;

    function exists(uint256 _tokenId) external returns (bool);

    function totalSupply(uint256 _tokenId) external returns (uint256);

    function lazyTotalSupply(uint256 _tokenId) external returns (uint256);

    function requireCanRequestMint(
        address _by,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function grantRole(address _newCreator) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function addCreator(address _creator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    uint256[] projectIds;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktAddProjectFailed();
error MktRemoveProjectFailed();
error MktTotalFeeTooLow();
error MktVCPoolTransferFailed();
error MktVCStarterTransferFailed();
error MktUnexpectedAddress();
error MktInactiveProject();

contract FeeBeneficiary is AccessControl {
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minTotalFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    event ProjectAdded(uint256 indexed projectId, uint256 time);
    event ProjectRemoved(uint256 indexed projectId, uint256 time);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(address => mapping(uint256 => mapping(address => TokenFeesData))) _tokenFeesData;

    /**
     * @dev Maps a project id to its beneficiary status.
     */
    mapping(uint256 => bool) internal _isActiveProject;

    /**
     * @dev Constructor
     */
    constructor(
        address _pool,
        address _starter,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _checkAddress(_pool);
        _checkAddress(_starter);

        _setMinTotalFeeBps(_minTotalFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);

        _grantRole(POOL_ROLE, _pool);
        _grantRole(STARTER_ROLE, _starter);

        pool = _pool;
        starter = _starter;
    }

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMinTotalFeeBps(_minTotalFeeBps);
    }

    function _setMinTotalFeeBps(uint256 _minTotalFeeBps) private {
        minTotalFeeBps = _minTotalFeeBps;
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Adds a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function addProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (_isActiveProject[_projectId]) {
            revert MktAddProjectFailed();
        }
        _isActiveProject[_projectId] = true;
        emit ProjectAdded(_projectId, block.timestamp);
    }

    /**
     * @dev Removes a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier to remove.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function removeProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (!_isActiveProject[_projectId]) {
            revert MktRemoveProjectFailed();
        }
        _isActiveProject[_projectId] = false;
        emit ProjectRemoved(_projectId, block.timestamp);
    }

    /**
     * @dev Returns True if the project is active or False if is not.
     *
     * @param _projectId the project identifier.
     */
    function isActiveProject(uint256 _projectId) public view returns (bool) {
        return _isActiveProject[_projectId];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _token NFT token address
     * @param _tokenId NFT token ID
     * @param _seller The seller address
     * @param _projectIds Array of Project identifiers to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        address _token,
        uint256 _tokenId,
        address _seller,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) internal {
        if (_projectIds.length != _projectFeesBps.length || _projectIds.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            if (!_isActiveProject[_projectIds[i]]) {
                revert MktInactiveProject();
            }
            starterFeeBps += _projectFeesBps[i];
        }

        if (_poolFeeBps + starterFeeBps < minTotalFeeBps) {
            revert MktTotalFeeTooLow();
        }

        _tokenFeesData[_token][_tokenId][_seller] = TokenFeesData(
            _poolFeeBps,
            starterFeeBps,
            _projectIds,
            _projectFeesBps
        );
    }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _token: Non-fungible token address
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(
        address _token,
        uint256 _tokenId,
        address _seller
    ) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_token][_tokenId][_seller];
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart
     * contracts when the token is sold.
     *
     * @param _token Non-fungible token address
     * @param _tokenId Non-fungible token identifier
     * @param _currency the Marketplace currency
     * @param _listPrice Token fixed price
     *
     * NOTE: Charges fee to msg.sender, i.e. buyer.
     */
    function _chargeFee(
        address _token,
        uint256 _tokenId,
        address _seller,
        IERC20 _currency,
        uint256 _listPrice,
        uint256 _marketFee
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TokenFeesData memory feesData = _tokenFeesData[_token][_tokenId][_seller];
        (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _splitListPrice(feesData, _listPrice);
        if (!_currency.transferFrom(msg.sender, pool, _marketFee + poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (starterFee > 0) {
            if (!_currency.transferFrom(msg.sender, address(this), starterFee)) {
                revert MktVCStarterTransferFailed();
            }
            _currency.approve(starter, starterFee);
            _fundProjects(feesData, _listPrice);
        }

        return (starterFee, poolFee, resultingAmount);
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart
     * contracts.
     *
     * @param _token Non-fungible token address
     * @param _tokenId Non-fungible token identifier
     * @param _currency the Marketplace currency
     * @param _listPrice Token auction price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        address _token,
        uint256 _tokenId,
        address _seller,
        IERC20 _currency,
        uint256 _listPrice,
        uint256 _marketFee
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TokenFeesData memory feesData = _tokenFeesData[_token][_tokenId][_seller];
        (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _splitListPrice(feesData, _listPrice);
        if (!_currency.transfer(pool, _marketFee + poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (starterFee > 0) {
            _currency.approve(starter, starterFee);
            _fundProjects(feesData, _listPrice);
        }

        return (starterFee, poolFee, resultingAmount);
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        private
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(TokenFeesData memory _feesData, uint256 _listPrice) internal {
        for (uint256 i = 0; i < _feesData.projectFeesBps.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                _fundProject(_feesData.projectIds[i], amount);
            }
        }
    }

    /**
     * @dev
     */
    function _fundProject(uint256 _projectId, uint256 _amount) internal virtual {}

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IMarketplaceFixedPrice.sol";
import "../interfaces/IMarketplaceAuction.sol";
import "../interfaces/IArtistNft.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();

    event ProtocolComponentsSet(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketplaceFixedPrice,
        address marketplaceAuction,
        address artistNft,
        address pocNft
    );

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    IMarketplaceFixedPrice public marketplaceFixedPrice;
    IMarketplaceAuction public marketplaceAuction;
    IArtistNft public artistNft;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function protocolComponents(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _marketplaceFixedPrice,
        address _marketplaceAuction,
        address _artistNft,
        address _pocNft
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        marketplaceFixedPrice = IMarketplaceFixedPrice(_marketplaceFixedPrice);
        marketplaceAuction = IMarketplaceAuction(_marketplaceAuction);
        artistNft = IArtistNft(_artistNft);
        pocNft = IPoCNft(_pocNft);

        _setPoCNft(_pocNft);
        _setMinterRoleArtistNft(_marketplaceFixedPrice);
        _setMinterRoleArtistNft(_marketplaceAuction);
        _setCurrency(_currency);

        emit ProtocolComponentsSet(
            _vcPool,
            _vcStarter,
            _currency,
            _marketplaceFixedPrice,
            _marketplaceAuction,
            _artistNft,
            _pocNft
        );
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceFixedPriceWithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceFixedPrice.withdrawTo(_token, _to, _amount);
    }

    function marketplaceAuctionWithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceAuction.withdrawTo(_token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketplaceFixedPrice.setPoCNft(_pocNft);
        marketplaceAuction.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    function whitelistTokens(address[] memory _tokens) external {
        _onlyAdmin();
        marketplaceFixedPrice.whitelistTokens(_tokens);
        marketplaceAuction.whitelistTokens(_tokens);
    }

    function blacklistTokens(address[] memory _tokens) external {
        _onlyAdmin();
        marketplaceFixedPrice.blacklistTokens(_tokens);
        marketplaceAuction.blacklistTokens(_tokens);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        marketplaceAuction.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMinTotalFeeBps(_minTotalFeeBps);
        marketplaceAuction.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFee(uint256 _marketplaceFee) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMarketplaceFee(_marketplaceFee);
        marketplaceAuction.setMarketplaceFee(_marketplaceFee);
    }

    /////////////////////////////////////////
    // ARTIST NFT SETUP THROUGH GOVERNANCE //
    /////////////////////////////////////////

    function setMinterRoleArtistNft(address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtistNft(_minter);
    }

    function _setMinterRoleArtistNft(address _marketplace) private {
        artistNft.grantMinterRole(_marketplace);
    }

    function setRoyaltyInfoArtistNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artistNft.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artistNft.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artistNft.setMaxBatchSize(_maxBatchSize);
    }

    function grantCreatorRoleArtistNft(address _newCreator) external {
        _onlyAdmin();
        artistNft.addCreator(_newCreator);
    }

    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    function setMarketplaceFixedPriceStarter(address _newMarketplaceFixedPrice) external {
        _onlyAdmin();
        starter.setMarketplaceFixedPrice(_newMarketplaceFixedPrice);
    }

    function setMarketplaceAuctionStarter(address _newMarketplaceAuction) external {
        _onlyAdmin();
        starter.setMarketplaceAuction(_newMarketplaceAuction);
    }

    // NECESITAMOS UN BLACKLIST O UN REMOVE WHITELIST??
    function whitelistLabsStarter(address[] memory _labs) external {
        _onlyAdmin();
        starter.whitelistLabs(_labs);
    }

    function setQuorumPollStarter(uint256 _quorumPoll) external {
        _onlyAdmin();
        if (_quorumPoll > 100) {
            revert GovInvalidQuorumPoll();
        }
        starter.setQuorumPoll(_quorumPoll);
    }

    function setMaxPollDurationStarter(uint256 _maxPollDuration) external {
        // should we check something here??
        _onlyAdmin();
        starter.setMaxPollDuration(_maxPollDuration);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _setCurrency(_currency);
    }

    function _setCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.setCurrency(_currency);
        pool.setCurrency(_currency);
        marketplaceAuction.setCurrency(_currency);
        marketplaceFixedPrice.setCurrency(_currency);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtistNft.sol";

interface IMarketplaceAuction {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtistNft.sol";

interface IMarketplaceFixedPrice {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}