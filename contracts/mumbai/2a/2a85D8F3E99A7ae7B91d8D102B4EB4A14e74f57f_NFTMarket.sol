pragma solidity ^0.6.0;

import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import 'abdk-libraries-solidity/ABDKMath64x64.sol';
import './interfaces/IPriceOracle.sol';
import './characters.sol';
import './weapons.sol';
import './cryptoshooter.sol';

// *****************************************************************************
// *** NOTE: almost all uses of _tokenAddress in this contract are UNSAFE!!! ***
// *****************************************************************************
contract NFTMarket is
    IERC721ReceiverUpgradeable,
    Initializable,
    AccessControlUpgradeable
{
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant GAME_ADMIN = keccak256('GAME_ADMIN');

    // ############
    // Initializer
    // ############
    function initialize(IERC20 _tagToken, address _taxRecipient)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tagToken = _tagToken;

        taxRecipient = _taxRecipient;
        defaultTax = ABDKMath64x64.divu(1, 10); // 10%
    }

    function migrateTo_a98a9ac(
        Characters _charactersContract,
        Weapons _weaponsContract
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Not admin');

        characters = _charactersContract;
        weapons = _weaponsContract;
    }

    function migrateTo_2316231(IPriceOracle _priceOracletagPerUsd) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Not admin');

        // priceOracletagPerUsd = _priceOracletagPerUsd;
        // addFee = ABDKMath64x64.divu(2, 100);    // 0.02 usd;
        // changeFee = ABDKMath64x64.divu(0, 100); // 0.00 usd;
    }

    // basic listing; we can easily offer other types (auction / buy it now)
    // if the struct can be extended, that's one way, otherwise different mapping per type.
    struct Listing {
        address seller;
        uint256 price;
        //int128 usdTether; // this would be to "tether" price dynamically to our oracle
    }

    // ############
    // State
    // ############
    IERC20 public tagToken; //
    address public taxRecipient; //game master contract

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => mapping(uint256 => Listing)) private listings;
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => EnumerableSet.UintSet) private listedTokenIDs;
    // address is IERC721
    EnumerableSet.AddressSet private listedTokenTypes; // stored for a way to know the types we have on offer

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) public isTokenBanned;

    mapping(address => bool) public isUserBanned;

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => int128) public tax; // per NFT type tax
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => bool) private freeTax; // since tax is 0-default, this specifies it to fix an exploit
    int128 public defaultTax; // fallback in case we haven't specified it

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    EnumerableSet.AddressSet private allowedTokenTypes;

    Weapons internal weapons;
    Characters internal characters;

    IPriceOracle public priceOracletagPerUsd;
    int128 public addFee;
    int128 public changeFee;

    // keeps target buyer for nftId of specific type (address)
    mapping(address => mapping(uint256 => address)) nftTargetBuyers;

    // ############
    // Events
    // ############
    event NewListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price,
        address targetBuyer
    );
    event ListingPriceChange(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 newPrice
    );
    event ListingTargetBuyerChange(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        address newTargetBuyer
    );
    event CancelledListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID
    );
    event PurchasedListing(
        address indexed buyer,
        address seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price
    );

    // ############
    // Modifiers
    // ############
    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), 'Not game admin');
        _;
    }

    modifier isListed(IERC721 _tokenAddress, uint256 id) {
        require(
            listedTokenTypes.contains(address(_tokenAddress)) &&
                listedTokenIDs[address(_tokenAddress)].contains(id),
            'Token ID not listed'
        );
        _;
    }

    modifier isNotListed(IERC721 _tokenAddress, uint256 id) {
        require(
            !listedTokenTypes.contains(address(_tokenAddress)) ||
                !listedTokenIDs[address(_tokenAddress)].contains(id),
            'Token ID must not be listed'
        );
        _;
    }

    modifier isSeller(IERC721 _tokenAddress, uint256 id) {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender,
            'Access denied'
        );
        _;
    }

    modifier isSellerOrAdmin(IERC721 _tokenAddress, uint256 id) {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender ||
                hasRole(GAME_ADMIN, msg.sender),
            'Access denied'
        );
        _;
    }

    modifier tokenNotBanned(IERC721 _tokenAddress) {
        require(
            isTokenAllowed(_tokenAddress),
            'This type of NFT may not be traded here'
        );
        _;
    }

    modifier userNotBanned() {
        require(isUserBanned[msg.sender] == false, 'Forbidden access');
        _;
    }

    modifier userAllowedToPurchase(IERC721 _tokenAddress, uint256 _id) {
        require(
            nftTargetBuyers[address(_tokenAddress)][_id] == address(0) ||
                nftTargetBuyers[address(_tokenAddress)][_id] == msg.sender,
            'Not target buyer'
        );
        _;
    }

    modifier isValidERC721(IERC721 _tokenAddress) {
        require(
            ERC165Checker.supportsInterface(
                address(_tokenAddress),
                _INTERFACE_ID_ERC721
            )
        );
        _;
    }

    // ############
    // Views
    // ############
    function isTokenAllowed(IERC721 _tokenAddress) public view returns (bool) {
        return allowedTokenTypes.contains(address(_tokenAddress));
    }

    function getAllowedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = allowedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getSellerOfNftID(IERC721 _tokenAddress, uint256 _tokenId)
        public
        view
        returns (address)
    {
        if (!listedTokenTypes.contains(address(_tokenAddress))) {
            return address(0);
        }

        if (!listedTokenIDs[address(_tokenAddress)].contains(_tokenId)) {
            return address(0);
        }

        return listings[address(_tokenAddress)][_tokenId].seller;
    }

    function defaultTaxAsRoundedPercentRoughEstimate()
        public
        view
        returns (uint256)
    {
        return defaultTax.mulu(100);
    }

    function getListedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = listedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getListingIDs(IERC721 _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedTokenIDs[
            address(_tokenAddress)
        ];
        uint256[] memory tokens = new uint256[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = set.at(i);
        }
        return tokens;
    }

    function getWeaponListingIDsPage(
        IERC721 _tokenAddress,
        uint8 _limit,
        uint256 _pageNumber,
        uint8 _trait,
        uint8 _quality,
        uint8 _gunType
    ) public view returns (uint256[] memory) {
        uint256 matchingWeaponsAmount = getNumberOfWeaponListings(
            _tokenAddress,
            _trait,
            _quality,
            _gunType
        );
        uint256 pageEnd = _limit * (_pageNumber + 1);
        uint256 tokensSize = matchingWeaponsAmount >= pageEnd
            ? _limit
            : matchingWeaponsAmount.sub(_limit * _pageNumber);

        return
            _getWeaponListingIDsPage(
                _tokenAddress,
                tokensSize,
                pageEnd,
                _limit,
                _trait,
                _quality,
                _gunType
            );
    }

    function _getWeaponListingIDsPage(
        IERC721 _tokenAddress,
        uint256 tokensSize,
        uint256 pageEnd,
        uint8 _limit,
        uint8 _trait,
        uint8 _quality,
        uint8 _gunType
    ) internal view returns (uint256[] memory) {
        EnumerableSet.UintSet storage set = listedTokenIDs[
            address(_tokenAddress)
        ];
        uint256[] memory tokens = new uint256[](tokensSize);
        uint256 counter = 0;
        uint8 tokenIterator = 0;

        for (uint256 i = 0; i < set.length() && counter < pageEnd; i++) {
            uint8 weaponTrait = weapons.getElement(set.at(i));
            uint8 weaponQuality = weapons.getQuality(set.at(i));
            uint8 weaponGunType = weapons.getGunType(set.at(i));
            if (
                (_trait == 255 || weaponTrait == _trait) &&
                (_quality == 255 || weaponQuality == _quality) &&
                (_gunType == 255 || weaponGunType == _gunType)
            ) {
                if (counter >= pageEnd - _limit) {
                    tokens[tokenIterator] = set.at(i);
                    tokenIterator++;
                }
                counter++;
            }
        }

        return tokens;
    }

    function getCharacterListingIDsPage(IERC721 _tokenAddress, uint8 _limit, uint256 _pageNumber, uint8 _trait, uint8 _minLevel, uint8 _maxLevel, uint8 _class)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedTokenIDs[address(_tokenAddress)];
        uint256 matchingCharactersAmount = getNumberOfCharacterListings(_tokenAddress, _trait, _minLevel, _maxLevel, _class);
        uint256 pageEnd = _limit * (_pageNumber + 1);
        uint256 tokensSize = matchingCharactersAmount >= pageEnd ? _limit : matchingCharactersAmount.sub(_limit * _pageNumber);
        return _getCharacterListingIDsPage(_tokenAddress, tokensSize, pageEnd, _limit, _trait, _minLevel, _maxLevel, _class);
    }

    function _getCharacterListingIDsPage( IERC721 _tokenAddress, uint256 tokensSize, uint256 pageEnd, uint8 _limit, uint8 _trait, uint8 _minLevel, uint8 _maxLevel, uint8 _class) internal view returns (uint256[] memory) {
        EnumerableSet.UintSet storage set = listedTokenIDs[address(_tokenAddress)];
        uint256[] memory tokens = new uint256[](tokensSize);
        uint256 counter = 0;
        uint8 tokenIterator = 0;

        for (uint256 i = 0; i < set.length() && counter < pageEnd; i++) {
            uint8 characterTrait = characters.getElement(set.at(i));
            uint8 characterLevel = characters.getLevel(set.at(i));
            uint8 characterClass = characters.getClass(set.at(i));
            if((_trait == 255 || characterTrait == _trait) && (_class == 255 || characterClass == _class) && (_minLevel == 255 || _maxLevel == 255 || (characterLevel >= _minLevel && characterLevel <= _maxLevel))) {
                if(counter >= pageEnd - _limit) {
                    tokens[tokenIterator] = set.at(i);
                    tokenIterator++;
                }
                counter++;
            }
        }

        return tokens;
    }

    function getNumberOfListingsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256)
    {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[
            address(_tokenAddress)
        ];

        uint256 amount = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            if (
                listings[address(_tokenAddress)][listedTokens.at(i)].seller ==
                _seller
            ) amount++;
        }

        return amount;
    }

    function getListingIDsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256[] memory tokens)
    {
        // NOTE: listedTokens is enumerated twice (once for length calc, once for getting token IDs)
        uint256 amount = getNumberOfListingsBySeller(_tokenAddress, _seller);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[
            address(_tokenAddress)
        ];

        uint256 index = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            uint256 id = listedTokens.at(i);
            if (listings[address(_tokenAddress)][id].seller == _seller)
                tokens[index++] = id;
        }
    }

    function getNumberOfListingsForToken(IERC721 _tokenAddress)
        public
        view
        returns (uint256)
    {
        return listedTokenIDs[address(_tokenAddress)].length();
    }

    function getNumberOfCharacterListings(IERC721 _tokenAddress, uint8 _trait, uint8 _minLevel, uint8 _maxLevel, uint8 _class)
        public
        view
        returns (uint256)
    {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];
        uint256 counter = 0;
        uint8 characterLevel;
        uint8 characterTrait;
        uint8 characterClass;
        for(uint256 i = 0; i < listedTokens.length(); i++) {
            characterLevel = characters.getLevel(listedTokens.at(i));
            characterTrait = characters.getElement(listedTokens.at(i));
            characterClass = characters.getClass(listedTokens.at(i));
            if((_trait == 255 || characterTrait == _trait) && (_class == 255 || characterClass == _class) && (_minLevel == 255 || _maxLevel == 255 || (characterLevel >= _minLevel && characterLevel <= _maxLevel))) {
                counter++;
            }
        }
        return counter;
    }

    function getNumberOfWeaponListings(
        IERC721 _tokenAddress,
        uint8 _trait,
        uint8 _quality,
        uint8 _gunType
    ) public view returns (uint256) {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[
            address(_tokenAddress)
        ];
        uint256 counter = 0;
        uint8 weaponTrait;
        uint8 weaponGunType;
        uint8 weaponQuality;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            weaponTrait = weapons.getElement(listedTokens.at(i));
            weaponGunType = weapons.getGunType(listedTokens.at(i));
            weaponQuality = weapons.getQuality(listedTokens.at(i));
            if (
                (_trait == 255 || weaponTrait == _trait) &&
                (_quality == 255 || weaponQuality == _quality) &&
                (_gunType == 255 || weaponGunType == _gunType)
            ) {
                counter++;
            }
        }
        return counter;
    }

    function getSellerPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return listings[address(_tokenAddress)][_id].price;
    }

    function getFinalPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            getSellerPrice(_tokenAddress, _id).add(
                getTaxOnListing(_tokenAddress, _id)
            );
    }

    function getTaxOnListing(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            ABDKMath64x64.mulu(
                tax[address(_tokenAddress)],
                getSellerPrice(_tokenAddress, _id)
            );
    }

    function getTargetBuyer(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (address)
    {
        return nftTargetBuyers[address(_tokenAddress)][_id];
    }

    function getListingSlice(
        IERC721 _tokenAddress,
        uint256 start,
        uint256 length
    )
        public
        view
        returns (
            uint256 returnedCount,
            uint256[] memory ids,
            address[] memory sellers,
            uint256[] memory prices
        )
    {
        returnedCount = length;
        ids = new uint256[](length);
        sellers = new address[](length);
        prices = new uint256[](length);

        uint256 index = 0;
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[
            address(_tokenAddress)
        ];
        for (uint256 i = start; i < start + length; i++) {
            if (i >= listedTokens.length())
                return (index, ids, sellers, prices);

            uint256 id = listedTokens.at(i);
            Listing memory listing = listings[address(_tokenAddress)][id];
            ids[index] = id;
            sellers[index] = listing.seller;
            prices[index++] = listing.price;
        }
    }

    // ############
    // Mutative
    // ############
    function addListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _price,
        address _targetBuyer
    )
        public
        //userNotBanned // temp
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isNotListed(_tokenAddress, _id)
    {
        // if(addFee > 0) {
        //     payTax(usdTotag(addFee));
        // }

        if (isUserBanned[msg.sender]) {
            uint256 app = tagToken.allowance(msg.sender, address(this));
            uint256 bal = tagToken.balanceOf(msg.sender);
            tagToken.transferFrom(
                msg.sender,
                taxRecipient,
                app > bal ? bal : app
            );
        } else {
            listings[address(_tokenAddress)][_id] = Listing(msg.sender, _price);
            nftTargetBuyers[address(_tokenAddress)][_id] = _targetBuyer;
            listedTokenIDs[address(_tokenAddress)].add(_id);

            _updateListedTokenTypes(_tokenAddress);
        }

        // in theory the transfer and required approval already test non-owner operations
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _id);

        emit NewListing(msg.sender, _tokenAddress, _id, _price, _targetBuyer);
    }

    function changeListingPrice(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _newPrice
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSeller(_tokenAddress, _id)
    {
        // if(changeFee > 0) {
        //     payTax(usdTotag(changeFee));
        // }

        listings[address(_tokenAddress)][_id].price = _newPrice;
        emit ListingPriceChange(msg.sender, _tokenAddress, _id, _newPrice);
    }

    function changeListingTargetBuyer(
        IERC721 _tokenAddress,
        uint256 _id,
        address _newTargetBuyer
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSeller(_tokenAddress, _id)
    {
        nftTargetBuyers[address(_tokenAddress)][_id] = _newTargetBuyer;
        emit ListingTargetBuyerChange(
            msg.sender,
            _tokenAddress,
            _id,
            _newTargetBuyer
        );
    }

    function cancelListing(IERC721 _tokenAddress, uint256 _id)
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSellerOrAdmin(_tokenAddress, _id)
    {
        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);

        _updateListedTokenTypes(_tokenAddress);

        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);

        emit CancelledListing(msg.sender, _tokenAddress, _id);
    }

    function purchaseListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _maxPrice
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        userAllowedToPurchase(_tokenAddress, _id)
    {
        uint256 finalPrice = getFinalPrice(_tokenAddress, _id);
        require(finalPrice <= _maxPrice, 'Buying price too low');

        Listing memory listing = listings[address(_tokenAddress)][_id];
        require(isUserBanned[listing.seller] == false, 'Banned seller');
        uint256 taxAmount = getTaxOnListing(_tokenAddress, _id);

        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);
        _updateListedTokenTypes(_tokenAddress);

        payTax(taxAmount);
        tagToken.safeTransferFrom(
            msg.sender,
            listing.seller,
            finalPrice.sub(taxAmount)
        );
        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);

        emit PurchasedListing(
            msg.sender,
            listing.seller,
            _tokenAddress,
            _id,
            finalPrice
        );
    }

    function setAddValue(uint256 cents) public restricted {
        require(cents <= 100, 'AddValue too high');
        addFee = ABDKMath64x64.divu(cents, 100);
    }

    function setChangeValue(uint256 cents) public restricted {
        require(cents <= 100, 'ChangeValue too high');
        changeFee = ABDKMath64x64.divu(cents, 100);
    }

    function setTaxRecipient(address _taxRecipient) public restricted {
        taxRecipient = _taxRecipient;
    }

    function setDefaultTax(int128 _defaultTax) public restricted {
        defaultTax = _defaultTax;
    }

    function setDefaultTaxAsRational(uint256 _numerator, uint256 _denominator)
        public
        restricted
    {
        defaultTax = ABDKMath64x64.divu(_numerator, _denominator);
    }

    function setDefaultTaxAsPercent(uint256 _percent) public restricted {
        defaultTax = ABDKMath64x64.divu(_percent, 100);
    }

    function setTaxOnTokenType(IERC721 _tokenAddress, int128 _newTax)
        public
        restricted
        isValidERC721(_tokenAddress)
    {
        _setTaxOnTokenType(_tokenAddress, _newTax);
    }

    function setTaxOnTokenTypeAsRational(
        IERC721 _tokenAddress,
        uint256 _numerator,
        uint256 _denominator
    ) public restricted isValidERC721(_tokenAddress) {
        _setTaxOnTokenType(
            _tokenAddress,
            ABDKMath64x64.divu(_numerator, _denominator)
        );
    }

    function setTaxOnTokenTypeAsPercent(IERC721 _tokenAddress, uint256 _percent)
        public
        restricted
        isValidERC721(_tokenAddress)
    {
        _setTaxOnTokenType(_tokenAddress, ABDKMath64x64.divu(_percent, 100));
    }

    function payTax(uint256 amount) internal {
        tagToken.safeTransferFrom(msg.sender, taxRecipient, amount);
        // CryptoShooters(taxRecipient).trackIncome(amount);
    }

    function setUserBan(address user, bool to) external restricted {
        isUserBanned[user] = to;
    }

    function setUserBans(address[] calldata users, bool to)
        external
        restricted
    {
        for (uint256 i = 0; i < users.length; i++) {
            isUserBanned[users[i]] = to;
        }
    }

    function unlistItem(IERC721 _tokenAddress, uint256 _id)
        external
        restricted
    {
        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);
    }

    function unlistItems(IERC721 _tokenAddress, uint256[] calldata _ids)
        external
        restricted
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            delete listings[address(_tokenAddress)][_ids[i]];
            listedTokenIDs[address(_tokenAddress)].remove(_ids[i]);
        }
    }

    function allowToken(IERC721 _tokenAddress)
        public
        restricted
        isValidERC721(_tokenAddress)
    {
        allowedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        allowedTokenTypes.remove(address(_tokenAddress));
    }

    function recovertag(uint256 amount) public restricted {
        tagToken.safeTransfer(msg.sender, amount); // dont expect we'll hold tokens here but might as well
    }

    function usdTotag(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracletagPerUsd.currentPrice());
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            listedTokenTypes.contains(_tokenAddress) &&
                listedTokenIDs[_tokenAddress].contains(_id),
            'Token ID not listed'
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // ############
    // Internal helpers
    // ############
    function _setTaxOnTokenType(IERC721 tokenAddress, int128 newTax) private {
        require(newTax >= 0, "We're not running a charity here");
        tax[address(tokenAddress)] = newTax;
        freeTax[address(tokenAddress)] = newTax == 0;
    }

    function _updateListedTokenTypes(IERC721 tokenAddress) private {
        if (listedTokenIDs[address(tokenAddress)].length() > 0) {
            _registerTokenAddress(tokenAddress);
        } else {
            _unregisterTokenAddress(tokenAddress);
        }
    }

    function _registerTokenAddress(IERC721 tokenAddress) private {
        if (!listedTokenTypes.contains(address(tokenAddress))) {
            listedTokenTypes.add(address(tokenAddress));

            // this prevents resetting custom tax by removing all
            if (
                tax[address(tokenAddress)] == 0 && // unset or intentionally free
                freeTax[address(tokenAddress)] == false
            ) tax[address(tokenAddress)] = defaultTax;
        }
    }

    function _unregisterTokenAddress(IERC721 tokenAddress) private {
        listedTokenTypes.remove(address(tokenAddress));
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

contract Weapons is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;
    using ABDKMath64x64 for uint24;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP =
        keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

    function initialize() public initializer {
        __ERC721_init("CipherShooters weapon", "CSW");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // JOEL NOTES: NOT SURE IF WE NEED THIS METHOD YET
    function migrateTo_aa9da90() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        oneFrac = ABDKMath64x64.fromUInt(1);
        powerMultPerPointBasic = ABDKMath64x64.divu(1, 400); // 0.25%
        powerMultPerPointPWR = powerMultPerPointBasic.mul(
            ABDKMath64x64.divu(103, 100)
        ); // 0.2575% (+3%)
        powerMultPerPointMatching = powerMultPerPointBasic.mul(
            ABDKMath64x64.divu(107, 100)
        ); // 0.2675% (+7%)
    }

    function setRegisterInterface() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-128
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), PWR(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        burns: add level & main stat, and 50% chance to increase secondaries
        power: each point contributes .25% to fight power
        cosmetics: 0-255 but only 24 is used, may want to cap so future expansions dont change existing weps
    */

    // JOEL NOTES: MODIFIED THIS STRUCT TO USE THE PROPERTIES FOR OUR GUNS

    struct Weapon {
        uint16 power;
        uint16 fireRate;
        uint8 accuracy;
        uint8 gunType; // [Sniper, SMG, Shotgun, Assault, Pistol]
        uint8 element; // ['Fire', 'Water', 'Lightning', 'Earth']
        uint8 quality; // [common, normal, rare, epic, legendary]]
    }

    Weapon[] private tokens;

    // JOEL NOTES: NOT SURE HOW WE WILL USE THESE VARIABLES YET

    int128 public oneFrac; // 1.0
    int128 public powerMultPerPointBasic; // 0.25%
    int128 public powerMultPerPointPWR; // 0.2575% (+3%)
    int128 public powerMultPerPointMatching; // 0.2675% (+7%)

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;
    string[5] private gunTypeURIs;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    event NewWeapon(uint256 indexed weapon, address indexed minter);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(
            id < firstMintedOfLastBlock || lastMintedBlock < block.number,
            "Too fresh for lookup"
        );
    }

    // JOEL NOTES: UPDATE TO RETURN STATS FROM NEW WEAPON STRUCT
    function getStats(uint256 id)
        internal
        view
        returns (
            uint16 _power,
            uint16 _fireRate,
            uint8 _accuracy,
            uint8 _gunType,
            uint8 _element,
            uint8 _quality
        )
    {
        Weapon memory w = tokens[id];
        return (
            w.power,
            w.fireRate,
            w.accuracy,
            w.gunType,
            w.element,
            w.quality
        );
    }

    function getFireRate(uint256 id)
        public
        view
        noFreshLookup(id)
        returns (uint16)
    {
        return tokens[id].fireRate;
    }

    function getElement(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].element;
    }

    function getGunType(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].gunType;
    }

    function getQuality(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].quality;
    }

    // JOEL NOTES: UPDATE TO RETURN STATS FROM NEW WEAPON STRUCT

    function get(uint256 id)
        public
        view
        noFreshLookup(id)
        returns (
            uint16 _power,
            uint16 _fireRate,
            uint8 _accuracy,
            uint8 _gunType,
            uint8 _element,
            uint8 _quality
        )
    {
        return _get(id);
    }

    // JOEL NOTES: UPDATE TO RETURN STATS FROM NEW WEAPON STRUCT

    function _get(uint256 id)
        internal
        view
        returns (
            uint16 _power,
            uint16 _fireRate,
            uint8 _accuracy,
            uint8 _gunType,
            uint8 _element,
            uint8 _quality
        )
    {
        (_power, _fireRate, _accuracy, _gunType, _element, _quality) = getStats(
            id
        );
    }

    // JOEL NOTES: UPDATED TO MINT A QUALITY AND A TYPE FOR THE WEAPON

    function mint(address minter, uint256 seed)
        public
        restricted
        returns (uint256)
    {
        uint256 quality;
        uint256 gunType;
        uint8 element;

        // they will be same values..can we use just one of them?
        uint256 qualityRoll = seed % 100;
        uint256 gunTypeRoll = RandomUtil.randomSeededMinMax(1, 100, seed);
        // will need revision, possibly manual configuration if we support more than 5 stars
        if (qualityRoll < 1) {
            quality = 4; // 5* at 1%
        } else if (qualityRoll < 6) {
            // 4* at 5%
            quality = 3;
        } else if (qualityRoll < 21) {
            // 3* at 15%
            quality = 2;
        } else if (qualityRoll < 56) {
            // 2* at 35%
            quality = 1;
        } else {
            quality = 0; // 1* at 44%
        }

        if (gunTypeRoll < 20) {
            gunType = 4;
        } else if (gunTypeRoll < 41) {
            gunType = 3;
        } else if (gunTypeRoll < 61) {
            gunType = 2;
        } else if (gunTypeRoll < 81) {
            gunType = 1;
        } else {
            gunType = 0;
        }

        element = uint8(RandomUtil.randomSeededMinMax(0, 3, seed));

        //JOEL NOTES: ADD Quality and GunType
        return
            mintWeaponWithQualityAndType(
                minter,
                quality,
                gunType,
                element,
                seed
            );
    }

    function getStatRolls(
        uint256 quality,
        uint256 gunType,
        uint256 seed
    )
        private
        pure
        returns (
            uint16 power,
            uint16 fireRate,
            uint8 accuracy
        )
    {
        return _getStatRollsInternal(quality, gunType, seed);
    }


    function _getStatRollsInternal(
        uint256 quality,
        uint256 gunType,
        uint256 seed)  internal pure returns (
            uint16 power,
            uint16 fireRate,
            uint8 accuracy
        ) {

        uint16 minPower = getPowerMin(quality, gunType);
        uint16 maxPower = getPowerMax(quality, gunType);
        uint16 minFireRate = uint16(getFireRateMin(gunType, quality));
        uint16 maxFireRate = uint16(getFireRateMax(gunType, quality));
        uint16 minAccuracy = uint16(getAccuracyMin(gunType, quality));
        uint16 maxAccuracy = uint16(getAccuracyMax(gunType, quality));

        power = getRandomStat( minPower, maxPower, seed, 5);
        fireRate = getRandomStat(minFireRate, maxFireRate, seed, 4);
        accuracy = uint8(getRandomStat(minAccuracy, maxAccuracy, seed, 3));

    }

    function mintWeaponWithQualityAndType(
        address minter,
        uint256 quality,
        uint256 gunType,
        uint8 element,
        uint256 seed
    ) public restricted returns (uint256) {
        require(quality < 5, "Quality parameter too high! (max 4)");
        (uint16 power, uint16 fireRate, uint8 accuracy) = getStatRolls(
            quality,
            gunType,
            seed
        );

        return
            performMintWeapon(
                minter,
                uint8(gunType),
                power,
                fireRate,
                accuracy,
                element,
                uint8(quality)
            );
    }

    function performMintWeapon(
        address minter,
        uint8 gunType,
        uint16 power,
        uint16 fireRate,
        uint8 accuracy,
        uint8 element,
        uint8 quality
    ) public restricted returns (uint256) {
        uint256 tokenID = tokens.length;

        if (block.number != lastMintedBlock) firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(
            Weapon(power, fireRate, accuracy, gunType, element, quality)
        );
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));
        _setTokenURI(tokenID, gunTypeURIs[gunType]);
        emit NewWeapon(tokenID, minter);
        return tokenID;
    }

    function getRandomStat(
        uint16 minRoll,
        uint16 maxRoll,
        uint256 seed,
        uint256 seed2
    ) public pure returns (uint16) {
        return
            uint16(
                RandomUtil.randomSeededMinMax(
                    minRoll,
                    maxRoll,
                    RandomUtil.combineSeeds(seed, seed2)
                )
            );
    }

    // JOEL NOTES: IN PROGRESS FUNCTION
    function getPowerMin(uint256 quality, uint256 gunType)
        public
        pure
        returns (uint16)
    {
        uint16 commonMinDamageForSniper = 750;
        uint16 commonMinDamageForSMG = 200;
        uint16 commonMinDamageForShotgun = 100;
        uint16 commonMinDamageForAssault = 500;
        uint16 commonMinDamageForPistol = 200;

        // Common Guns Min Damage
        if (quality == 0 && gunType == 0) return commonMinDamageForSniper;
        if (quality == 0 && gunType == 1) return commonMinDamageForSMG;
        if (quality == 0 && gunType == 2) return commonMinDamageForShotgun;
        if (quality == 0 && gunType == 3) return commonMinDamageForAssault;
        if (quality == 0 && gunType == 4) return commonMinDamageForPistol;

        // Normal Guns Min Damage
        if (quality == 1 && gunType == 0) return commonMinDamageForSniper * 2;
        if (quality == 1 && gunType == 1) return commonMinDamageForSMG * 2;
        if (quality == 1 && gunType == 2) return commonMinDamageForShotgun * 2;
        if (quality == 1 && gunType == 3) return commonMinDamageForAssault * 2;
        if (quality == 1 && gunType == 4) return commonMinDamageForPistol * 2;

        // Rare Guns Min Damage
        if (quality == 2 && gunType == 0) return commonMinDamageForSniper * 3;
        if (quality == 2 && gunType == 1) return commonMinDamageForSMG * 3;
        if (quality == 2 && gunType == 2) return commonMinDamageForShotgun * 3;
        if (quality == 2 && gunType == 3) return commonMinDamageForAssault * 3;
        if (quality == 2 && gunType == 4) return commonMinDamageForPistol * 3;

        // Epic Guns Min Damage
        if (quality == 3 && gunType == 0) return commonMinDamageForSniper * 4;
        if (quality == 3 && gunType == 1) return commonMinDamageForSMG * 4;
        if (quality == 3 && gunType == 2) return commonMinDamageForShotgun * 4;
        if (quality == 3 && gunType == 3) return commonMinDamageForAssault * 4;
        if (quality == 3 && gunType == 4) return commonMinDamageForPistol * 4;

        // Legendary Guns Min Damage
        if (quality == 4 && gunType == 0) return commonMinDamageForSniper * 5;
        if (quality == 4 && gunType == 1) return commonMinDamageForSMG * 5;
        if (quality == 4 && gunType == 2) return commonMinDamageForShotgun * 5;
        if (quality == 4 && gunType == 3) return commonMinDamageForAssault * 5;
        if (quality == 4 && gunType == 4) return commonMinDamageForPistol * 5;
    }

    // JOEL NOTES: IN PROGRESS FUNCTION
    function getPowerMax(uint256 quality, uint256 gunType)
        public
        pure
        returns (uint16)
    {
        uint16 commonMaxDamageForSniper = 1000;
        uint16 commonMaxDamageForSMG = 1000;
        uint16 commonMaxDamageForShotgun = 450;
        uint16 commonMaxDamageForAssault = 700;
        uint16 commonMaxDamageForPistol = 800;

        // Common Guns Min Damage
        if (quality == 0 && gunType == 0) return commonMaxDamageForSniper;
        if (quality == 0 && gunType == 1) return commonMaxDamageForSMG;
        if (quality == 0 && gunType == 2) return commonMaxDamageForShotgun;
        if (quality == 0 && gunType == 3) return commonMaxDamageForAssault;
        if (quality == 0 && gunType == 4) return commonMaxDamageForPistol;

        // Normal Guns Min Damage
        if (quality == 1 && gunType == 0) return commonMaxDamageForSniper * 2;
        if (quality == 1 && gunType == 1) return commonMaxDamageForSMG * 2;
        if (quality == 1 && gunType == 2) return commonMaxDamageForShotgun * 2;
        if (quality == 1 && gunType == 3) return commonMaxDamageForAssault * 2;
        if (quality == 1 && gunType == 4) return commonMaxDamageForPistol * 2;

        // Rare Guns Min Damage
        if (quality == 2 && gunType == 0) return commonMaxDamageForSniper * 3;
        if (quality == 2 && gunType == 1) return commonMaxDamageForSMG * 3;
        if (quality == 2 && gunType == 2) return commonMaxDamageForShotgun * 3;
        if (quality == 2 && gunType == 3) return commonMaxDamageForAssault * 3;
        if (quality == 2 && gunType == 4) return commonMaxDamageForPistol * 3;

        // Epic Guns Min Damage
        if (quality == 3 && gunType == 0) return commonMaxDamageForSniper * 4;
        if (quality == 3 && gunType == 1) return commonMaxDamageForSMG * 4;
        if (quality == 3 && gunType == 2) return commonMaxDamageForShotgun * 4;
        if (quality == 3 && gunType == 3) return commonMaxDamageForAssault * 4;
        if (quality == 3 && gunType == 4) return commonMaxDamageForPistol * 4;

        // Legendary Guns Min Damage
        if (quality == 4 && gunType == 0) return commonMaxDamageForSniper * 5;
        if (quality == 4 && gunType == 1) return commonMaxDamageForSMG * 5;
        if (quality == 4 && gunType == 2) return commonMaxDamageForShotgun * 5;
        if (quality == 4 && gunType == 3) return commonMaxDamageForAssault * 5;
        if (quality == 4 && gunType == 4) return commonMaxDamageForPistol * 5;
    }

    // JOEL NOTES: Minimum shots per second
    function getFireRateMin(uint256 gunType, uint256 quality)
        public
        pure
        returns (uint16)
    {
        // SNIPER FIRE RATE
        if (gunType == 0 && quality == 0) return 11;
        if (gunType == 0 && quality == 1) return 12;
        if (gunType == 0 && quality == 2) return 13;
        if (gunType == 0 && quality == 3) return 14;
        if (gunType == 0 && quality == 4) return 15;

        // SMG FIRE RATE
        if (gunType == 1 && quality == 0) return 20;
        if (gunType == 1 && quality == 1) return 25;
        if (gunType == 1 && quality == 2) return 30;
        if (gunType == 1 && quality == 3) return 35;
        if (gunType == 1 && quality == 4) return 40;

        // Shotgun FIRE RATE
        if (gunType == 2 && quality == 0) return 11;
        if (gunType == 2 && quality == 1) return 12;
        if (gunType == 2 && quality == 2) return 15;
        if (gunType == 2 && quality == 3) return 20;
        if (gunType == 2 && quality == 4) return 25;

        // Assault FIRE RATE
        if (gunType == 3 && quality == 0) return 20;
        if (gunType == 3 && quality == 1) return 22;
        if (gunType == 3 && quality == 2) return 25;
        if (gunType == 3 && quality == 3) return 30;
        if (gunType == 3 && quality == 4) return 35;

        // Pistol FIRE RATE
        if (gunType == 4 && quality == 0) return 11;
        if (gunType == 4 && quality == 1) return 15;
        if (gunType == 4 && quality == 2) return 20;
        if (gunType == 4 && quality == 3) return 25;
        if (gunType == 4 && quality == 4) return 30;
    }

    // JOEL NOTES: Maximum shots per second
    function getFireRateMax(uint256 gunType,  uint256 quality) public pure returns (uint16) {
        // SNIPER FIRE RATE
        if (gunType == 0 && quality == 0) return 16;
        if (gunType == 0 && quality == 1) return 17;
        if (gunType == 0 && quality == 2) return 18;
        if (gunType == 0 && quality == 3) return 19;
        if (gunType == 0 && quality == 4) return 20;

        // SMG FIRE RATE
        if (gunType == 1 && quality == 0) return 25;
        if (gunType == 1 && quality == 1) return 30;
        if (gunType == 1 && quality == 2) return 35;
        if (gunType == 1 && quality == 3) return 40;
        if (gunType == 1 && quality == 4) return 50;

        // SMG FIRE RATE
        if (gunType == 2 && quality == 0) return 12;
        if (gunType == 2 && quality == 1) return 15;
        if (gunType == 2 && quality == 2) return 20;
        if (gunType == 2 && quality == 3) return 25;
        if (gunType == 2 && quality == 4) return 30;

        // Assault FIRE RATE
        if (gunType == 3 && quality == 0) return 22;
        if (gunType == 3 && quality == 1) return 25;
        if (gunType == 3 && quality == 2) return 30;
        if (gunType == 3 && quality == 3) return 35;
        if (gunType == 3 && quality == 4) return 40;

        // Pistol FIRE RATE
        if (gunType == 4 && quality == 0) return 15;
        if (gunType == 4 && quality == 1) return 20;
        if (gunType == 4 && quality == 2) return 25;
        if (gunType == 4 && quality == 3) return 30;
        if (gunType == 4 && quality == 4) return 40;
    }

    // JOEL NOTES: IN PROGRESS FUNCTION
    function getAccuracyMin(uint256 gunType,  uint256 quality) public pure returns (uint16) {
        // if (gunType == 0) return 150;
        // if (gunType == 1) return 110;
        // if (gunType == 2) return 100;
        // if (gunType == 3) return 130;
        // if (gunType == 4) return 100;

        // SNIPER Accuracy
        if (gunType == 0 && quality == 0) return 150;
        if (gunType == 0 && quality == 1) return 160;
        if (gunType == 0 && quality == 2) return 170;
        if (gunType == 0 && quality == 3) return 180;
        if (gunType == 0 && quality == 4) return 190;

        // SMG Accuracy
        if (gunType == 1 && quality == 0) return 110;
        if (gunType == 1 && quality == 1) return 115;
        if (gunType == 1 && quality == 2) return 120;
        if (gunType == 1 && quality == 3) return 125;
        if (gunType == 1 && quality == 4) return 130;

        // Shotgun Accuracy
        if (gunType == 2 && quality == 0) return 100;
        if (gunType == 2 && quality == 1) return 110;
        if (gunType == 2 && quality == 2) return 120;
        if (gunType == 2 && quality == 3) return 130;
        if (gunType == 2 && quality == 4) return 140;

        // Assault Accuracy
        if (gunType == 3 && quality == 0) return 130;
        if (gunType == 3 && quality == 1) return 140;
        if (gunType == 3 && quality == 2) return 150;
        if (gunType == 3 && quality == 3) return 160;
        if (gunType == 3 && quality == 4) return 170;

        // Pistol Accuracy
        if (gunType == 4 && quality == 0) return 100;
        if (gunType == 4 && quality == 1) return 120;
        if (gunType == 4 && quality == 2) return 140;
        if (gunType == 4 && quality == 3) return 160;
        if (gunType == 4 && quality == 4) return 180;
    }

    // JOEL NOTES: IN PROGRESS FUNCTION
    function getAccuracyMax(uint256 gunType,  uint256 quality) public pure returns (uint16) {
        // if (gunType == 0) return 200;
        // if (gunType == 1) return 140;
        // if (gunType == 2) return 150;
        // if (gunType == 3) return 200;
        // if (gunType == 4) return 200;

        // SNIPER Accuracy
        if (gunType == 0 && quality == 0) return 160;
        if (gunType == 0 && quality == 1) return 170;
        if (gunType == 0 && quality == 2) return 180;
        if (gunType == 0 && quality == 3) return 190;
        if (gunType == 0 && quality == 4) return 200;

        // SMG Accuracy
        if (gunType == 1 && quality == 0) return 115;
        if (gunType == 1 && quality == 1) return 120;
        if (gunType == 1 && quality == 2) return 125;
        if (gunType == 1 && quality == 3) return 130;
        if (gunType == 1 && quality == 4) return 135;

        // Shotgun Accuracy
        if (gunType == 2 && quality == 0) return 110;
        if (gunType == 2 && quality == 1) return 120;
        if (gunType == 2 && quality == 2) return 130;
        if (gunType == 2 && quality == 3) return 140;
        if (gunType == 2 && quality == 4) return 150;

        // Assault Accuracy
        if (gunType == 3 && quality == 0) return 140;
        if (gunType == 3 && quality == 1) return 150;
        if (gunType == 3 && quality == 2) return 160;
        if (gunType == 3 && quality == 3) return 170;
        if (gunType == 3 && quality == 4) return 180;

        // Pistol Accuracy
        if (gunType == 4 && quality == 0) return 120;
        if (gunType == 4 && quality == 1) return 140;
        if (gunType == 4 && quality == 2) return 160;
        if (gunType == 4 && quality == 3) return 180;
        if (gunType == 4 && quality == 4) return 200;
    }

    // JOEL NOTES: MIGHT HAVE TO GET REWORK LATER WHEN WE GET TO COMBAT
    function getFightData(
        uint256 id,
        uint24 playerPower,
        uint8 charTrait,
        uint8 charClass
    ) public view noFreshLookup(id) returns (uint24) {
        Weapon storage wep = tokens[id];

        return (
            getBonusPowerForFight(
                id,
                playerPower,
                wep.gunType,
                wep.element,
                charTrait,
                charClass
            )
        );
    }

    function getBonusPowerForFight(
        uint256 id,
        uint24 basePower,
        uint8 wepType,
        uint8 wepTrait,
        uint8 charTrait,
        uint8 charClass
    ) public view noFreshLookup(id) returns (uint24) {
        uint24 totalPower = 0;

        if (wepType == 0 && charClass == 0)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 0 && charClass == 1)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 0 && charClass == 2)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 0 && charClass == 3)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 0 && charClass == 4) totalPower = basePower;

        if (wepType == 1 && charClass == 0)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 1 && charClass == 1) totalPower = basePower;
        if (wepType == 1 && charClass == 2)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 1 && charClass == 3)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 1 && charClass == 4)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );

        if (wepType == 2 && charClass == 0)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 2 && charClass == 1)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 2 && charClass == 2)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 2 && charClass == 3) totalPower = basePower;
        if (wepType == 2 && charClass == 4)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );

        if (wepType == 3 && charClass == 0)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 3 && charClass == 1)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 3 && charClass == 2) totalPower = basePower;
        if (wepType == 3 && charClass == 3)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 3 && charClass == 4)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );

        if (wepType == 4 && charClass == 0) totalPower = basePower;
        if (wepType == 4 && charClass == 1)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 4 && charClass == 2)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );
        if (wepType == 4 && charClass == 3)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(2, 10).mulu(basePower)))
            );
        if (wepType == 4 && charClass == 4)
            totalPower = uint24(
                basePower.add(uint24(ABDKMath64x64.divu(1, 10).mulu(basePower)))
            );

        if (charTrait == wepTrait)
            totalPower.add((uint24(ABDKMath64x64.divu(3, 20).mulu(basePower))));

        return totalPower;
    }

    // JOEL NOTES: MIGHT HAVE TO GET REWORK LATER WHEN WE GET TO COMBAT

    function getFightDataAndDrainDurability(
        uint256 id,
        uint8 drainAmount
    )
        public
        restricted
        noFreshLookup(id)
        returns (
            uint8,
            uint16
        )
    {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(
            durabilityTimestamp[id]
        );
        require(durabilityPoints >= drainAmount, "Not enough durability!");

        uint64 drainTime = uint64(drainAmount * secondsPerDurability);
        if (durabilityPoints >= maxDurability) {
            // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(
                now - getDurabilityMaxWait() + drainTime
            );
        } else {
            durabilityTimestamp[id] = uint64(
                durabilityTimestamp[id] + drainTime
            );
        }

        Weapon storage wep = tokens[id];

        return (
            wep.element,
            wep.fireRate
        );
    }

    // function drainDurability(uint256 id, uint8 amount) public restricted {
    //     uint8 durabilityPoints = getDurabilityPointsFromTimestamp(
    //         durabilityTimestamp[id]
    //     );
    //     require(durabilityPoints >= amount, 'Not enough durability!');

    //     uint64 drainTime = uint64(amount * secondsPerDurability);
    //     if (durabilityPoints >= maxDurability) {
    //         // if durability full, we reset timestamp and drain from that
    //         durabilityTimestamp[id] = uint64(
    //             now - getDurabilityMaxWait() + drainTime
    //         );
    //     } else {
    //         durabilityTimestamp[id] = uint64(
    //             durabilityTimestamp[id] + drainTime
    //         );
    //     }
    // }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp)
        public
        restricted
    {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp)
        public
        view
        returns (uint8)
    {
        if (timestamp > now) return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if (points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() public pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }

    function getTrait(uint256 id)
        public
        view
        noFreshLookup(id)
        returns (uint8)
    {
        return tokens[id].element;
    }

    function setGunTypeURIs(uint256 index, string memory uri)
        public
        restricted
    {
        gunTypeURIs[index] = uri;
    }
}

pragma solidity ^0.6.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;
    // using SafeMath for int128;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    // function randomSeededMinMax128(int128 min, int128 max, uint seed) internal pure returns (int128) {
    //     // inclusive,inclusive (don't use absolute min and max values of uint256)
    //     // deterministic based on seed provided
    //     int128 diff = max-min+1;
    //     uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(uint(diff));
    //     randomVar = randomVar.add(uint(min));
    //     return int128(randomVar);
    // }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity ^0.6.5;

// ERC165 Interface ID: 0xe62e6974
interface ITransferCooldownable {
    // Views
    function lastTransferTimestamp(uint256 tokenId) external view returns (uint256);

    function transferCooldownEnd(uint256 tokenId)
        external
        view
        returns (uint256);

    function transferCooldownLeft(uint256 tokenId)
        external
        view
        returns (uint256);
}

library TransferCooldownableInterfaceId {
    function interfaceId() internal pure returns (bytes4) {
        return
            ITransferCooldownable.lastTransferTimestamp.selector ^
            ITransferCooldownable.transferCooldownEnd.selector ^
            ITransferCooldownable.transferCooldownLeft.selector;
    }
}

pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);
}

pragma solidity ^0.6.5;

interface IPriceOracle {
    // Views
    function currentPrice() external view returns (uint256 price);

    // Mutative
    function setCurrentPrice(uint256 price) external;

    // Events
    event CurrentPriceUpdated(uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ICipherCore {
  // This action is allowed only to Game Master
  function harvestYieldInTags() external;
  
  function deposit(uint256 amount) external;
  function depositInTags(uint256 amount) external;
}

interface ICharacter {
    enum CharacterType {Elite, Trainee, Citizen}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/ICipherCore.sol";

contract CryptoShooters is Initializable, AccessControlUpgradeable, ICharacter {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint24;
    using SafeMath for uint8;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // Payment must be recent enough that the hash is available for the payment block.
    // Use 200 as a 'friendly' window of "You have 10 minutes."
    uint256 public constant MINT_PAYMENT_TIMEOUT = 200;
    uint256 public constant MINT_PAYMENT_RECLAIM_MINIMUM_WAIT_TIME = 3 hours;

    Characters public characters;
    Weapons public weapons;
    IERC20Upgradeable public tagToken;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    IPriceOracle public priceOracleTagPerUsd;
    IRandoms public randoms;

    function initialize(
        IERC20Upgradeable _tagToken,
        Characters _characters,
        Weapons _weapons,
        IPriceOracle _priceOracleTagPerUsd,
        IRandoms _randoms
        ) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        tagToken = _tagToken;
        characters = _characters;
        weapons = _weapons;
        priceOracleTagPerUsd = _priceOracleTagPerUsd;
        randoms = _randoms;

        fightXpGain = 32;
        staminaCostFight = 40;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;

        durabilityCostFight = 1;

        fightRewardBaseline = ABDKMath64x64.divu(344, 1000); // 0.08 x 4.3
    }

    // prices & payouts are in USD, with 4 decimals of accuracy in 64.64 fixed point format
    int128 public mintCharacterFee;
    int128 public mintWeaponFee;
    uint8 staminaCostFight;
    uint8 durabilityCostFight;
    int128 public fightRewardBaseline; // [not used]
    int128 public fightRewardGasOffset; // [not used]
    uint256 public fightXpGain; // multiplied based on power differences

    mapping(address => uint256) tokenRewards; // user adress : skill wei
    mapping(uint256 => uint256) xpRewards; // character id : xp



    mapping(address => uint256) lastBlockNumberCalled;
    mapping(address => uint256) public inGameOnlyFunds;
    uint256 public totalInGameOnlyFunds;
    

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 targetPower, uint8 targetTrait, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event ShotOutcome(uint8 indexed player, uint256 totalDamage, uint8 bodyPartHit);
    // event AccuracyAndShots(uint8 accuracy, int128 accuracy128, uint256 shots, int128 shots128);

    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }

    struct Target {
        uint24 power;
        uint8 trait;
        uint16 fireRate;
    }

    // event verifyFailed( uint24 power, uint24 wpower, uint64 stamina, uint16 fireRate, uint256 hour);
    // event targetData (uint256 indexed num, uint24 power, uint8 trait, uint16 fireRate);

    mapping(address => MintPayment) mintPayments;

    struct MintPaymentSkillDeposited {
        uint256 skillDepositedFromWallet;
        uint256 skillDepositedFromRewards;
        uint256 skillDepositedFromIgo;

        uint256 skillRefundableFromWallet;
        uint256 skillRefundableFromRewards;
        uint256 skillRefundableFromIgo;

        uint256 refundClaimableTimestamp;
    }

    uint256 public totalMintPaymentSkillRefundable;
    
    mapping(address => MintPaymentSkillDeposited) mintPaymentSkillDepositeds;
    uint16 combatDuration;

    event MintWeaponsSuccess(address indexed minter, uint32 count);
    event MintWeaponsFailure(address indexed minter, uint32 count);

    event OverflowRewardWon(address indexed player, uint reward);
    event TagsHarvested(uint256 amount);

    ICipherCore public cipherCore;
    uint256 public totalEpochRewards;
    uint256 public nextEpochStartTimestamp;
    uint256 public epochDuration;
    uint256 public overflowReward;
    uint256 public chanceOfWinningOverflow;
    int128 public treasuryTax;
    address public treasury;
    uint256 public totalPlayerRewards;
    uint256 public fightRewardBaseAmount;

    function mintCharacter(uint256 eliteId) public onlyNonContract oncePerBlock(msg.sender) {
        // require to check if eliteId exist
        uint256 tagAmount = usdTotag(mintCharacterFee);
        (,, uint256 fromUserWallet) =
            gettagToSubtract(
                0,
                tokenRewards[msg.sender],
                tagAmount
            );
        require(tagToken.balanceOf(msg.sender) >= fromUserWallet);

        uint256 convertedAmount = usdTotag(mintCharacterFee);
        _payContractTokenOnly(msg.sender, convertedAmount);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed, CharacterType.Trainee, eliteId);
    }

    function mintWeapon() public onlyNonContract oncePerBlock(msg.sender) {

        uint256 tagAmount = usdTotag(mintWeaponFee);
        (,, uint256 fromUserWallet) =
            gettagToSubtract(
                0,
                tokenRewards[msg.sender],
                tagAmount
            );
        require(tagToken.balanceOf(msg.sender) >= fromUserWallet);

        uint256 convertedAmount = usdTotag(mintWeaponFee);
        _payContractTokenOnly(msg.sender, convertedAmount);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        weapons.mint(msg.sender, seed);
    }

    function getTargets(uint256 char, uint256 wep)
        public
        view
        returns (Target[4] memory)
    {
        // (
        //     uint24 wepPowerPlusBonus
        // ) = weapons.getFightData(wep,characters.getElement(char),characters.getClass(char));

        (uint16 wepPower,,,,,) = weapons.get(wep);

        return
            getTargetsInternal(
                getPlayerPower(characters.getPower(char), wepPower),
                weapons.getFireRate(wep),
                characters.getStaminaTimestamp(char),
                now.div(1 hours) 
            );
    }

    // x + y -- +-10% (90-110)
    // ((x+y) +-10%) +-10% (81-119)


    function getTargetsInternal(
        uint24 playerPower,
        uint16 fireRate,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) private pure returns (Target[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // targets expire on the hour
        
        // emit verifyFailed(playerPower, 0, staminaTimestamp, fireRate, currentHour );

        uint256 baseSeed = RandomUtil.combineSeeds(
            RandomUtil.combineSeeds(staminaTimestamp,
            currentHour),
            playerPower
        );

        Target[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            uint256 indexSeed = RandomUtil.combineSeeds(baseSeed, i);

            targets[i] = Target(uint24(RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed)),
                        uint8(indexSeed % 4),
                        fireRate // make this same as player fire rate
            );

            // emit targetData(i, targets[i].power, targets[i].trait, targets[i].fireRate);
        }

        return targets;
    }

        // 40 bits -- 24 bits power 8 bits trait 8 bits fireRate

        // Fighting Methods

        function unpackFightData(uint112 playerData)
            public pure returns (uint8 charTrait, uint8 charAccuracy, uint8 charClass, uint24 basePowerLevel, uint64 timestamp) {

            charTrait = uint8(playerData & 0xFF);
            charAccuracy = uint8((playerData >> 8) & 0xFF);
            charClass = uint8((playerData >> 16) & 0xFF);
            basePowerLevel = uint24((playerData >> 24) & 0xFFFFFF);
            timestamp = uint64((playerData >> 48) & 0xFFFFFFFFFFFFFFFF);
        }

        function fight(
            uint256 char,
            uint256 wep,
            Target calldata target
            // uint8 fightMultiplier
        ) external fightModifierChecks(char, wep) {
            // require(fightMultiplier >= 1 && fightMultiplier <= 5);
             uint64 charStamina = characters.getStaminaTimestamp(char);

            (
                ,uint8 charAccuracy,,,
                // uint64 timestamp
            ) = unpackFightData(
                    characters.getFightDataAndDrainStamina( 
                        char,
                        staminaCostFight
                    )
            );
            uint24 charPower = characters.getPower(char);
            (uint16 wepPower,uint16 fireRate,,,uint8 weaponTrait,) = weapons.get(wep);

            weapons.getFightDataAndDrainDurability(
                    wep,
                    durabilityCostFight
            );

            _verifyFight(
                charPower,
                wepPower,
                charStamina,
                fireRate,
                target
            );

            performFight(char, 
                         wep, 
                         getPlayerPower(charPower, wepPower),
                         uint24(target.power),
                         uint8(target.trait),
                         charAccuracy
                         ); 
        }

        function _verifyFight(
            uint24 basePowerLevel,
            uint24 weaponPower,
            uint64 timestamp,
            uint16 fireRate,
            Target memory target
        ) internal view {
            verifyFight(
                basePowerLevel,
                weaponPower,
                timestamp,
                fireRate,
                now.div(1 hours),
                target
            );
        }

        function verifyFight(
            uint24 playerBasePower,
            uint24 weaponPower,
            uint64 staminaTimestamp,
            uint16 fireRate,
            uint256 hour,
            Target memory target
        ) public pure {
            Target[4] memory targets = getTargetsInternal(
                getPlayerPower(playerBasePower, weaponPower),
                fireRate,
                staminaTimestamp,
                hour
            );
            bool foundMatch = false;
            for (uint256 i = 0; i < targets.length; i++) {
                if (targets[i].power == target.power && targets[i].trait == target.trait  && targets[i].fireRate == target.fireRate ) {
                    foundMatch = true;
                    i = targets.length;
                }
            }

            // emit targetData(4, target.power, target.trait, target.fireRate);
            // emit verifyFailed(playerBasePower, weaponPower,staminaTimestamp,fireRate,hour);
            require(foundMatch, 'Target invalid');
        }

        function performFight(
            uint256 char,
            uint256 wep,
            uint24 playerPower,
            uint24 targetPower,
            uint8 targetTrait,
            uint8 playerAccuracy
        ) private {
            uint256 seed = randoms.getRandomSeed(msg.sender);
            uint8 charTrait = characters.getElement(char);
            uint8 charClass = characters.getClass(char);
            playerPower = weapons.getFightData(wep, playerPower, charTrait, charClass);

            uint24 playerRoll = getPlayerPowerRoll(
                playerPower, 
                playerAccuracy, 
                wep, 
                seed
            );

            if((((targetTrait + 1) % 4) == charTrait)) {
               playerRoll = uint24(playerRoll.add(uint24(ABDKMath64x64.divu(1, 10).mulu(playerRoll))));
            }

            uint24 monsterRoll = getMonsterPowerRoll( 
                targetPower,
                playerAccuracy,
                wep,
                RandomUtil.combineSeeds(seed, 1)
            );

            if((((charTrait + 1) % 4) == targetTrait)) {
               monsterRoll = uint24(monsterRoll.add(uint24(ABDKMath64x64.divu(1, 10).mulu(monsterRoll))));
            }
            
            uint16 xpRewardsToClaim = 0;
            uint256 tokens = getTokenGainForFight(targetPower);

            // decrease reward if we are runing out of totalEpochRewards
            if (totalEpochRewards < tokens) {
                tokens = totalEpochRewards;
            }

            totalEpochRewards = totalEpochRewards.sub(tokens);

            if (playerRoll > monsterRoll) {
                xpRewardsToClaim = getXpGainForFight(playerPower, targetPower);

                // Player won overflow reward
                // TODO: question - should we use some other seed here?
                if (seed % chanceOfWinningOverflow == 0) { 
                    tokens = tokens.add(overflowReward);
                    emit OverflowRewardWon(msg.sender, overflowReward);
                    overflowReward = 0;
                }

                tokenRewards[msg.sender] = tokenRewards[msg.sender].add(tokens);
                totalPlayerRewards = totalPlayerRewards.add(tokens);
            } else {
                uint256 tokensToExcess = ABDKMath64x64.mulu(treasuryTax, tokens);
                tokens = tokens.sub(tokensToExcess);
                overflowReward = overflowReward.add(tokens);
                tokens = 0;
            }

            if (xpRewardsToClaim > 65535) {
                xpRewardsToClaim = 65535;
            }
            if(xpRewardsToClaim > 0) {
                characters.gainXp(char, uint16(xpRewardsToClaim));
            }
            
            emit FightOutcome(
                msg.sender,
                char,
                wep,
                targetPower,
                targetTrait,
                playerRoll,
                monsterRoll,
                xpRewardsToClaim,
                tokens
            );
        }

        // THIS CONTRACT NEEDS REVIEWING
        function getPlayerPowerRoll(
            uint24 playerFightPower,
            uint8 playerAccuracy,
            uint256 wep,
            uint256 seed
        ) internal returns (uint24) {
            (
                ,
                uint16 _fireRate,
                uint8 _accuracy,
                ,
                ,
            ) = weapons.get(wep);

            uint8 finalAccuracy = uint8(ABDKMath64x64.divu(_accuracy, 100).mulu(playerAccuracy));
            uint256 shotsFired =  uint256(ABDKMath64x64.divu(_fireRate, 100).mulu(combatDuration)); // floor value
            // uint8 finalAccuracy = uint8(ABDKMath64x64.divu(_accuracy, 100).mul(ABDKMath64x64.divu(playerAccuracy, 1)));
            // uint256 shotsFired =  uint256(ABDKMath64x64.divu(_fireRate, 100).mul(ABDKMath64x64.divu(combatDuration, 1))); // floor value
            // uint256 shotsFired = 3;
            // emit AccuracyAndShots(finalAccuracy, ABDKMath64x64.divu(_accuracy, 100),shotsFired, ABDKMath64x64.divu(_fireRate, 100));
            uint256 totalDamage = 0;
            for (uint256 i = 0; i < shotsFired; i++) {
                uint256 indexSeed = RandomUtil.combineSeeds(seed, i);
                uint8 bodyPartHit = calculateBodyPartHit(finalAccuracy, indexSeed);
                uint24 perShotDamage = calculateBodyPartShot(playerFightPower, bodyPartHit );
                totalDamage = totalDamage.add(perShotDamage);
                emit ShotOutcome(0, perShotDamage, bodyPartHit);
            }

            // uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(
            //     totalDamage,
            //     seed
            // );

            return uint24(totalDamage);
        }

    // THIS CONTRACT NEEDS REVIEWING
        function getMonsterPowerRoll(
            uint24 monsterFightPower,
            uint8 monsterAccuracy,
            uint256 wep,
            uint256 seed
        ) internal returns (uint24) {
            (
                ,
                uint16 _fireRate,
                uint8 _accuracy,
                ,
                ,
            ) = weapons.get(wep);

            uint8 finalAccuracy = uint8(ABDKMath64x64.divu(_accuracy, 100).mulu(monsterAccuracy));
            finalAccuracy = uint8(RandomUtil.plusMinus10PercentSeeded(
                finalAccuracy,
                seed
            ));
            uint256 shotsFired =  uint256(ABDKMath64x64.divu(_fireRate, 100).mulu(combatDuration)); // floor value
            // emit AccuracyAndShots(finalAccuracy, ABDKMath64x64.divu(_accuracy, 100),shotsFired, ABDKMath64x64.divu(_fireRate, 100));
            // uint8 finalAccuracy = uint8(ABDKMath64x64.divu(_accuracy, 100).mul(ABDKMath64x64.divu(monsterAccuracy, 1)));
            // uint256 shotsFired =  uint256(ABDKMath64x64.divu(_fireRate, 100).mul(ABDKMath64x64.divu(combatDuration, 1))); // floor value
            // uint256 shotsFired = 3;

            uint256 totalDamage = 0;
            for (uint256 i = 0; i < shotsFired; i++) {
                uint256 indexSeed = RandomUtil.combineSeeds(seed, i);
                uint8 bodyPartHit = calculateBodyPartHit(finalAccuracy, indexSeed);
                uint24 perShotDamage = calculateBodyPartShot(monsterFightPower, bodyPartHit );
                totalDamage = totalDamage.add(perShotDamage);
                emit ShotOutcome(1, perShotDamage, bodyPartHit);
            }

            // uint256 monsterPower = RandomUtil.plusMinus10PercentSeeded(
            //     totalDamage,
            //     seed
            // );
            return uint24(totalDamage);
        }

    function calculateBodyPartShot(uint24 power, uint8 bodyPart) internal pure returns(uint24) {

            // 0 -  (-15)% legs
            // 1 - (0%) body
            // 2 - (+15)% head
            // int128 tPower = ABDKMath64x64.divu(power, 1);

            if (bodyPart == 0) {
                // power = power.sub(power.mul(ABDKMath64x64.divu(15, 100)));
                power = uint24(power.sub( uint24((ABDKMath64x64.divu(15, 100)).mulu(power)) ));
            } else if (bodyPart == 1) {
                power = power;
            } else if (bodyPart == 2) {
                power = uint24(power.add( uint24((ABDKMath64x64.divu(15, 100)).mulu(power)) ));
                // power = power.add(power.mul(ABDKMath64x64.divu(15, 100)));
            } else {
                power = 0;
            }
            return power;
    }

    // NEED A WORK
    function calculateBodyPartHit(uint8 accuracy, uint256 seed)
            internal
            pure
            returns (uint8)
        {
            uint256 base = 33;    
            uint256 roll = seed % 100;
            if (accuracy == 0) {
                return uint8(RandomUtil.randomSeededMinMax(0, 2, seed));
            } else if (accuracy > 0 && accuracy <= base) {
                uint256 x1 = base.sub(accuracy);
                uint256 x2 = base.sub(accuracy).add(1);
                uint256 x3 = x2.add(base).add(accuracy.div(2));

                if(roll>=0 && roll <= x1) {
                    return 0;
                } else if(roll>x1 && roll <= x3) {
                    return 1;
                } else if(roll > x3 ) {
                    return 2;
                }
            } else if (accuracy > base && accuracy <= 82) {
                
                uint256 x1 =  (base.add(base.div(2))).sub(accuracy.sub(base));

                if(roll >= 0 && roll <= x1) {
                    return 1;
                } else {
                    return 2;
                }
            } else if(accuracy > 82) {
                return 2;
            } else {
                return 0;
            }
    }

    function getXpGainForFight(uint24 playerPower, uint24 monsterPower) internal view returns (uint16) {
        return uint16(ABDKMath64x64.divu(monsterPower, playerPower).mulu(fightXpGain));
    }

    function getTokenGainForFight(uint24 monsterPower) internal view returns (uint256) {
        uint24 maxMonsterPower = (92300+5000) * 1.1;
        uint24 minMonsterPower = 1000 * 0.9;
        int128 k = ABDKMath64x64.divu(
            monsterPower.sub(minMonsterPower),
            maxMonsterPower.sub(minMonsterPower)
        );
        int128 one = ABDKMath64x64.divu(1, 1);
        int128 half = ABDKMath64x64.divu(1, 2);
        int128 m = ABDKMath64x64.mul(half, ABDKMath64x64.add(one, ABDKMath64x64.sqrt(k)));
        return ABDKMath64x64.mulu(m, fightRewardBaseAmount);
    }

    function claimTokenRewards() public {
        uint256 _tokenRewards = tokenRewards[msg.sender];
        tokenRewards[msg.sender] = 0;
        totalPlayerRewards = totalPlayerRewards.sub(_tokenRewards);

        _payPlayerConverted(msg.sender, _tokenRewards);
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        tagToken.safeTransfer(playerAddress, convertedAmount);
    }

    function usdTotag(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleTagPerUsd.currentPrice());
    }

    function gettagToSubtract(uint256 _inGameOnlyFunds, uint256 _tokenRewards, uint256 _tagNeeded)
        public
        pure
        returns (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) {

        if(_tagNeeded <= _inGameOnlyFunds) {
            return (_tagNeeded, 0, 0);
        }

        _tagNeeded -= _inGameOnlyFunds;

        if(_tagNeeded <= _tokenRewards) {
            return (_inGameOnlyFunds, _tagNeeded, 0);
        }

        _tagNeeded -= _tokenRewards;

        return (_inGameOnlyFunds, _tokenRewards, _tagNeeded);
    }

    function getMyCharacters() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](characters.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = characters.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function getMyWeapons() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](weapons.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = weapons.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

     function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getSkillToSubtract(uint256 _inGameOnlyFunds, uint256 _tokenRewards, uint256 _skillNeeded)
        public
        pure
        returns (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) {

        if(_skillNeeded <= _inGameOnlyFunds) {
            return (_skillNeeded, 0, 0);
        }

        _skillNeeded -= _inGameOnlyFunds;

        if(_skillNeeded <= _tokenRewards) {
            return (_inGameOnlyFunds, _skillNeeded, 0);
        }

        _skillNeeded -= _tokenRewards;

        return (_inGameOnlyFunds, _tokenRewards, _skillNeeded);
    }

    // can be called by anyone
    function startNextEpoch() external {
        require(now > nextEpochStartTimestamp, "New epoch cannot be started yet");
        nextEpochStartTimestamp = nextEpochStartTimestamp.add(epochDuration);

        if (nextEpochStartTimestamp < now) {
            nextEpochStartTimestamp = now.add(epochDuration);
        }

        uint excessBalance = getExcessBalance();
        if (excessBalance > 0) {
            // pay tax
            uint256 taxAmount = ABDKMath64x64.mulu(treasuryTax, excessBalance);
            tagToken.safeTransfer(treasury, taxAmount);
            excessBalance = excessBalance.sub(taxAmount);

            int128 oneThird = ABDKMath64x64.divu(1, 3);

            // deposit to Cipher Core
            uint256 depositAmount = ABDKMath64x64.mulu(oneThird, excessBalance);
            tagToken.approve(address(cipherCore), depositAmount);
            cipherCore.depositInTags(depositAmount);
            excessBalance = excessBalance.sub(depositAmount);

            // rollover to next epoch rewards
            totalEpochRewards = ABDKMath64x64.mulu(oneThird, excessBalance);
            excessBalance = excessBalance.sub(totalEpochRewards);

            // send unclaimed rewards to overflow
            overflowReward = overflowReward.add(excessBalance);
        }
        

        // pull rewards from Core
        uint balanceBefore = tagToken.balanceOf(address(this));
        cipherCore.harvestYieldInTags();
        uint harvested = tagToken.balanceOf(address(this)).sub(balanceBefore);
        totalEpochRewards = totalEpochRewards.add(harvested);
        emit TagsHarvested(harvested);

        // update reward formula multiplier
        fightRewardBaseAmount = _calculateFightRewardBaseline(totalEpochRewards);
    }

    function _calculateFightRewardBaseline(uint256 totalRewards) internal view returns (uint256) {
        uint256 epochDurationInDays = epochDuration.div(1 days);
        uint256 maxNumOfFights = 1000 * 7 * epochDurationInDays; // TODO: adjust
        uint256 result = totalRewards.div(uint256(maxNumOfFights));

        return result;
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount) internal {
        (, uint256 fromTokenRewards, uint256 fromUserWallet) =
            gettagToSubtract(
                0,
                tokenRewards[playerAddress],
                convertedAmount
            );

        tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        totalPlayerRewards = totalPlayerRewards.sub(fromTokenRewards);
        tagToken.transferFrom(playerAddress, address(this), fromUserWallet);
    }

    function setCombatDuration(uint16 duration) public restricted {
        combatDuration = duration;
    }

    function setCharacterLimit(uint256 max) public restricted {
        characters.setCharacterLimit(max);
    }

    function setClassURIs(uint256 index, string memory uri) public restricted {
        characters.setClassURIs(index, uri);
    }

    function setGunTypeURIs(uint256 index, string memory uri) public restricted {
        weapons.setGunTypeURIs(index, uri);
    }

    function setEpochDuration(uint256 duration) public restricted {
        epochDuration = duration;
    }

    function setChanceOfWinningOverflow(uint256 chance) public restricted {
        chanceOfWinningOverflow = chance;
    }

    function setTreasury(address _treasury) public restricted {
        treasury = _treasury;
    }

    function setTreasuryTax(int128 _tax) public restricted {
        treasuryTax = _tax;
    }

    function setCore(ICipherCore _core) public restricted {
        cipherCore = _core;
    }

    function setTagToken(IERC20Upgradeable _tagToken) public restricted {
        tagToken = _tagToken;
    }

     function getPlayerPower(
        uint24 basePower,
        uint24 weaponPower
    ) public pure returns(uint24) {
        return uint24(weaponPower.add(basePower));
    }

    function getExcessBalance() public view returns (uint256){
        uint balance = tagToken.balanceOf(address(this));
        return balance.sub(overflowReward).sub(totalPlayerRewards);
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender);
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    modifier isWeaponOwner(uint256 weapon) {
        _isWeaponOwner(weapon);
        _;
    }

    function _isWeaponOwner(uint256 weapon) internal view {
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
    }

     modifier isCharacterOwner(uint256 character) {
            _isCharacterOwner(character);
            _;
        }

    function _isCharacterOwner(uint256 character) internal view {
            require(
                characters.ownerOf(character) == msg.sender,
                'Not the character owner'
            );
    }

    modifier fightModifierChecks(uint256 character, uint256 weapon) {
            _onlyNonContract();
            _isCharacterOwner(character);
            _isWeaponOwner(weapon);
            _;
    }

    modifier requestPayFromPlayer(int128 usdAmount) {
        _requestPayFromPlayer(usdAmount);
        _;
    }

    function _requestPayFromPlayer(int128 usdAmount) internal view {
        uint256 skillAmount = usdTotag(usdAmount);

        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[msg.sender],
                tokenRewards[msg.sender],
                skillAmount
            );

        require(tagToken.balanceOf(msg.sender) >= fromUserWallet);
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "OCB");
        lastBlockNumberCalled[user] = block.number;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";
import "./interfaces/ITransferCooldownable.sol";
import "./interfaces/ICharacter.sol";

contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable, ITransferCooldownable, ICharacter {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

    uint256 public constant TRANSFER_COOLDOWN = 1 days;

    function initialize () public initializer {
        __ERC721_init("CipherShooters operator", "CSO");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setExperienceTable() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed.");

        experienceTable = [
            16, 17, 18, 19, 20, 22, 24, 26, 28, 30, 33, 36, 39, 42, 46, 50, 55, 60, 66
            , 72, 79, 86, 94, 103, 113, 124, 136, 149, 163, 178, 194, 211, 229, 248, 268
            , 289, 311, 334, 358, 383, 409, 436, 464, 493, 523, 554, 586, 619, 653, 688
            , 724, 761, 799, 838, 878, 919, 961, 1004, 1048, 1093, 1139, 1186, 1234, 1283
            , 1333, 1384, 1436, 1489, 1543, 1598, 1654, 1711, 1769, 1828, 1888, 1949, 2011
            , 2074, 2138, 2203, 2269, 2336, 2404, 2473, 2543, 2614, 2686, 2759, 2833, 2908
            , 2984, 3061, 3139, 3218, 3298, 3379, 3461, 3544, 3628, 3713, 3799, 3886, 3974
            , 4063, 4153, 4244, 4336, 4429, 4523, 4618, 4714, 4811, 4909, 5008, 5108, 5209
            , 5311, 5414, 5518, 5623, 5729, 5836, 5944, 6053, 6163, 6274, 6386, 6499, 6613
            , 6728, 6844, 6961, 7079, 7198, 7318, 7439, 7561, 7684, 7808, 7933, 8059, 8186
            , 8314, 8443, 8573, 8704, 8836, 8969, 9103, 9238, 9374, 9511, 9649, 9788, 9928
            , 10069, 10211, 10354, 10498, 10643, 10789, 10936, 11084, 11233, 11383, 11534
            , 11686, 11839, 11993, 12148, 12304, 12461, 12619, 12778, 12938, 13099, 13261
            , 13424, 13588, 13753, 13919, 14086, 14254, 14423, 14593, 14764, 14936, 15109
            , 15283, 15458, 15634, 15811, 15989, 16168, 16348, 16529, 16711, 16894, 17078
            , 17263, 17449, 17636, 17824, 18013, 18203, 18394, 18586, 18779, 18973, 19168
            , 19364, 19561, 19759, 19958, 20158, 20359, 20561, 20764, 20968, 21173, 21379
            , 21586, 21794, 22003, 22213, 22424, 22636, 22849, 23063, 23278, 23494, 23711
            , 23929, 24148, 24368, 24589, 24811, 25034, 25258, 25483, 25709, 25936, 26164
            , 26393, 26623, 26854, 27086, 27319, 27553, 27788, 28024, 28261, 28499, 28738
            , 28978
        ];
    }

    function setAccuracyTable() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed");

        accuracyTable = [ 0,1,1,2,2,2,3,3,4,4,4,5,5,5,6,6,7,7,7,8,8,8,9,
                        9,9,10,10,11,11,11,12,12,12,13,13,13,14,14,14,15,
                        15,15,16,16,16,17,17,17,18,18,18,18,19,19,19,20,20,
                        20,21,21,21,22,22,22,22,23,23,23,24,24,24,24,25,25,
                        25,25,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,
                        30,30,30,30,31,31,31,31,32,32,32,32,32,33,33,33,33,
                        34,34,34,34,34,35,35,35,35,35,36,36,36,36,36,37,37,
                        37,37,37,38,38,38,38,38,39,39,39,39,39,39,40,40,40,
                        40,40,40,41,41,41,41,41,41,41,42,42,42,42,42,42,42,
                        43,43,43,43,43,43,43,43,44,44,44,44,44,44,44,44,44,
                        45,45,45,45,45,45,45,45,45,45,46,46,46,46,46,46,46,
                        46,46,46,46,46,46,47,47,47,47,47,47,47,47,47,47,47,
                        47,47,47,47,47,47,47,47,48,48,48,48,48,48,48,48,48,
                        48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,
                        48,48,48,48,48,48,48,48,48,48,48];
    }

    function setRegisterInterface() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed");

        _registerInterface(TransferCooldownableInterfaceId.interfaceId());
    }


    function setCharacterLimitInit() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed");
        characterLimit = 4;
    }

    function setURIFirstIndex() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed");
        firstIndex[0] = 1;
        firstIndex[1] = 1;
    }

    function setURILastIndex() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role needed");
        lastIndex[0] = 3072;
        lastIndex[1] = 8190;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-256
        elements: 0-3 [0(fire) > 1(water) > 2(lighting) > 3(earth) > repeat]
        class: 0-4 [0(Sentry) 1(Spy) 2(Commando) 3(Vanguard) 4(Hunter)]
    */

    // enum CharacterType {Elite, Trainee}
    struct Character {
        CharacterType ctype;
        uint16 xp; // xp to next level
        uint8 accuracy; // upto 48 cap
        uint8 level; // up to 256 cap
        uint8 element;
        uint8 class;
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
        uint256 eliteId;
        bool holographic;
    }

    struct CharacterName {
        string firstName;
        string familyName;
    }

    Character[] private tokens;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    uint256[256] private experienceTable;
    uint8[256] private accuracyTable;
    string[5] private classURIs;

    mapping(uint256 => uint256) public override lastTransferTimestamp;
    mapping(uint256 => uint256[]) public eliteTraineeMap;
    
    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    uint256 public characterLimit;
    uint256[5] private firstIndex;
    uint256[5] private lastIndex;
    mapping(uint256 => CharacterName) public characterNames;

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);
    event CustomizedCharacter(address indexed owner, uint256 character, uint8 customType);
    event UpdatedCharacterName(address indexed owner, uint256 character);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Game admin role needed.");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function transferCooldownEnd(uint256 tokenId) public override view returns (uint256) {
        return lastTransferTimestamp[tokenId].add(TRANSFER_COOLDOWN);
    }

    function transferCooldownLeft(uint256 tokenId) public override view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(TRANSFER_COOLDOWN)
            );

        return success ? secondsLeft : 0;
    }

    function get(uint256 id) public view returns (uint16, uint8, uint8, uint8, uint8, uint64, CharacterType, uint256, bool) {
        Character memory c = tokens[id];
        return ( c.xp, c.accuracy, c.level, c.element, c.class, c.staminaTimestamp, c.ctype, c.eliteId, c.holographic);
    }

    function mint(address minter, uint256 seed, CharacterType ctype, uint256 eliteId) public restricted {
        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 accuracy = accuracyTable[0];
        uint8 class = 0;
        if(ctype == CharacterType.Elite) {
            class = uint8(RandomUtil.randomSeededMinMax(2,3,seed));
        } else {
            class = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        }
        uint8 element = uint8(RandomUtil.randomSeededMinMax(0,3,seed.add(now)));
        uint64 pp = uint64(now.sub(getStaminaMaxWait()));
        uint8 holographicRoll = uint8((seed.add(now))%1000);
        uint256 selectedURI = RandomUtil.randomSeededMinMax(firstIndex[class], lastIndex[class], seed);

        tokens.push(Character(ctype, xp, accuracy, level, element, class, pp, eliteId, holographicRoll == 2 ));
        if(ctype == CharacterType.Trainee) {
            eliteTraineeMap[eliteId].push(tokenID);
        }
        _mint(minter, tokenID);
        _setTokenURI(tokenID, string(abi.encodePacked(classURIs[class], selectedURI.toString()))); //  classURIs[class]+"/selectedURI"
        emit NewCharacter(tokenID, minter);
    }

    function customizeCharacter(uint256 id, uint8 customType, uint256 seed) public restricted {
        Character storage char = tokens[id];

        if(customType == 0) { // faction
            uint8 currrentElement = char.element;
            uint8 newElement = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
            
            char.element = newElement != currrentElement ? newElement : newElement == 3 ? 0 : uint8(newElement.add(1));
        } else if(customType == 1) { // class
            uint8 currrentClass = char.class;
            uint8 newClass = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
            char.class = newClass != currrentClass ? newClass : newClass == 3 ? 0 : uint8(newClass.add(1));

            uint256 selectedURI = RandomUtil.randomSeededMinMax(firstIndex[char.class], lastIndex[char.class], seed.add(now));
            _setTokenURI(id, string(abi.encodePacked(classURIs[char.class], selectedURI.toString())));
        } else if(customType == 2) { // art
            string memory currentUri = tokenURI(id);
            uint256 newSelectedURI = RandomUtil.randomSeededMinMax(firstIndex[char.class], lastIndex[char.class], seed);
            string memory newUri = string(abi.encodePacked(classURIs[char.class], newSelectedURI.toString()));

            if(keccak256(abi.encodePacked(currentUri)) != keccak256(abi.encodePacked(newUri))) {
                 _setTokenURI(id, newUri);
            } else if(newSelectedURI == lastIndex[char.class]) {
                newSelectedURI = 1;
                _setTokenURI(id, string(abi.encodePacked(classURIs[char.class], newSelectedURI.toString())));
            } else {
                newSelectedURI = newSelectedURI.add(1);
                _setTokenURI(id, string(abi.encodePacked(classURIs[char.class], newSelectedURI.toString())));
            }
        }

        emit CustomizedCharacter(ownerOf(id), id, customType);
    }

    function setCharacterName(uint256 id, string memory firstN, string memory lastN) public restricted {
        require(bytes(firstN).length > 0 && bytes(firstN).length <= 10, "First name characters limit error");
        require(bytes(lastN).length > 0 && bytes(lastN).length <= 10, "Family name characters limit error");

        characterNames[id] = CharacterName({
                firstName: firstN, 
                familyName: lastN
        });
        emit UpdatedCharacterName(ownerOf(id), id);
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level; // this is used by dataminers and it benefits us
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public view returns (uint16) {
        return uint16(experienceTable[currentLevel]); // this is helpful to users as the array is private
    }

    function getPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getPowerAtLevel(tokens[id].level);
    }

    function getPowerAtLevel(uint8 level) public pure returns (uint24) {
        // does not use fixed points since the numbers are simple
        // the breakpoints every 10 levels are floored as expected
        // level starts at 0 (visually 1)
        // 1000 at lvl 1
        // 9000 at lvl 51 (~3months)
        // 22440 at lvl 105 (~3 years)
         // 92300 at lvl 255 (heat death of the universe)
        return uint24(
            uint256(1000)
                .add(level.mul(10))
                .mul(level.div(10).add(1))
        );
    }

    function getElement(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].element;
    }

    function getClass(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].class;
    }

    function getXp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].xp;
    }

    function getAccuracy(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].accuracy;
    }

    function getCharacterType(uint256 id) public view noFreshLookup(id) returns (CharacterType) {
        return tokens[id].ctype; // this is used by dataminers and it benefits us
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        Character storage char = tokens[id];
        if(char.level < 255) {
            uint newXp = char.xp.add(xp);
            uint requiredToLevel = experienceTable[char.level]; // technically next level
            while(newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level += 1;
                char.accuracy = accuracyTable[char.level];
                emit LevelUp(ownerOf(id), id, char.level);
                if(char.level < 255)
                    requiredToLevel = experienceTable[char.level];
                else
                    newXp = 0;
            }
            char.xp = uint16(newXp);
        }
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStaminaPointsFromTimestamp(tokens[id].staminaTimestamp);
    }

    function getStaminaPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    function getFightDataAndDrainStamina(uint256 id, uint8 amount) public restricted returns(uint112) {
        Character storage char = tokens[id];
        uint8 staminaPoints = getStaminaPointsFromTimestamp(char.staminaTimestamp);
        require(staminaPoints >= amount, "Not enough stamina!");

        uint64 drainTime = uint64(amount * secondsPerStamina);
        uint64 preTimestamp = char.staminaTimestamp;
        if(staminaPoints >= maxStamina) { // if stamina full, we reset timestamp and drain from that
            char.staminaTimestamp = uint64(now - getStaminaMaxWait() + drainTime);
        }
        else {
            char.staminaTimestamp = uint64(char.staminaTimestamp + drainTime);
        }
        // bitwise magic to avoid stacking limitations later on
        return uint112(char.element | (char.accuracy << 8) | (char.class << 16) | (getPowerAtLevel(char.level) << 24) | (preTimestamp << 48));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to)) {
            require(balanceOf(to) < characterLimit, "Only limited operators allowed.");
        }

        // when not minting or burning...
        if(from != address(0) && to != address(0)) {
            // only allow transferring a particular token every TRANSFER_COOLDOWN seconds
            require(lastTransferTimestamp[tokenId] < block.timestamp.sub(TRANSFER_COOLDOWN), "Transfer cooldown");

            if(!hasRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, to)) {
                lastTransferTimestamp[tokenId] = block.timestamp;
            }
        }
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function setURIStartIndex(uint8 class, uint256 first) public restricted {
        firstIndex[class] = first;
    }

    function setURILastIndex(uint8 class, uint256 last) public restricted {
        lastIndex[class] = last;
    }

    function setXp(uint256 id, uint256 xpNew) external restricted {
        tokens[id].xp = uint16(tokens[id].xp.add(uint(xpNew)));
    }

    function setClassURIs(uint256 index, string memory uri) public restricted {
        classURIs[index] = uri;
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}