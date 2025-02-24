// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IHandshakeLevels.sol";
import 'base64-sol/base64.sol';

/// @custom:security-contact [email protected]
contract DexGoNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;

    // shoes:
    uint8 public constant SHOES0 = 0;
    uint8 public constant SHOES1 = 1;
    uint8 public constant SHOES2 = 2;
    uint8 public constant SHOES3 = 3;
    uint8 public constant SHOES4 = 4;
    uint8 public constant SHOES5 = 5;
    uint8 public constant SHOES6 = 6;
    uint8 public constant SHOES7 = 7;
    uint8 public constant SHOES8 = 8;
    uint8 public constant SHOES9 = 9;
    uint8 public constant MAGIC_BOX = 10;

    uint8 public constant PATH = 100;
    uint8 public constant MOVIE = 200;

    address public accountTeam1 = address(0xC98834f2De2Eb9c97FFbdF2E4952535D2D4bC1A1);
    address public accountTeam2 = address(0x1cea85b1148bEAD4D40316BC4D5270f70425B79C);

    address public gameServer;
    function setGameServer(address _gameServer) public onlyOwner {
        gameServer = _gameServer;
    }
    function getGameServer() public view returns (address) {
        return gameServer;
    }

    address public handshakeLevels;
    function setHandshakeLevels(address _handshakeLevels) public onlyOwner {
        handshakeLevels = _handshakeLevels;
    }
    function getHandshakeLevels() public view returns (address) {
        return handshakeLevels;
    }
    string public ipfsRoot = "https://openbisea.mypinata.cloud/ipfs/QmVww6AoULsNxeMfQeyXfk6EN7syspR285MbiqqMdU1Vob/";
    function setIpfsRoot(string memory _ipfsRoot) public onlyOwner {
        ipfsRoot = _ipfsRoot;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;



    mapping(address => uint256) latestPurchaseTime;
    function getLatestPurchaseTime(address wallet) public view returns (uint256) {
        return latestPurchaseTime[wallet];
    }
    function setLatestPurchaseTime(address wallet, uint8 timestamp) public onlyOwner {
        latestPurchaseTime[wallet] = timestamp;
    }

    mapping(uint8 => string) nameForType;
    function setNameForType(string memory _nameForType, uint8 typeNft) public onlyOwner {
        nameForType[typeNft] = _nameForType;
    }
    mapping(uint8 => string) descriptionForType;
    function setDescriptionForType(string memory _descriptionForType, uint8 typeNft) public onlyOwner {
        descriptionForType[typeNft] = _descriptionForType;
    }
    mapping(uint8 => string) imageForTypeMaxKm;
    function setImageForTypeMaxKm(string memory _imageForType, uint8 typeNft) public onlyOwner {
        imageForTypeMaxKm[typeNft] = _imageForType;
    }
    mapping(uint8 => string) imageForType75PercentKm;
    function setImageForType75PercentKm(string memory _imageForType, uint8 typeNft) public onlyOwner {
        imageForType75PercentKm[typeNft] = _imageForType;
    }
    mapping(uint8 => string) imageForType50PercentKm;
    function setImageForType50PercentKm(string memory _imageForType, uint8 typeNft) public onlyOwner {
        imageForType50PercentKm[typeNft] = _imageForType;
    }
    mapping(uint8 => string) imageForType25PercentKm;
    function setImageForType25PercentKm(string memory _imageForType, uint8 typeNft) public onlyOwner {
        imageForType25PercentKm[typeNft] = _imageForType;
    }

    mapping(uint8 => uint256) counterForType;
    function getCounterForType(uint8 typeNft) public view returns (uint256) {
        return counterForType[typeNft];
    }

    mapping(uint8 => uint256) limitForType;
    function setLimitForType(uint256 limit, uint8 typeNft) public onlyOwner {
        limitForType[typeNft] = limit;
    }
    function getLimitForType(uint8 typeNft) public view returns (uint256) {
        return limitForType[typeNft];
    }

    mapping(uint8 => uint256) priceForType;
    function setPriceForType(uint256 price, uint8 typeNft) public onlyOwner {
        priceForType[typeNft] = price;
    }
    function getPriceForType(uint8 typeNft) public view returns (uint256) {
        return priceForType[typeNft];
    }
    mapping(uint8 => uint256) priceInitialForType;
    function setPriceInitialForType(uint256 price, uint8 typeNft) public onlyOwner {
        priceInitialForType[typeNft] = price;
    }
    function getPriceInitialForType(uint8 typeNft) public view returns (uint256) {
        return priceInitialForType[typeNft];
    }

    mapping(uint256 => uint8) typeForId;
    function getTypeForId(uint256 tokenId) public view returns (uint8) {
        return typeForId[tokenId];
    }

    mapping(uint => string) inAppPurchaseInfo;
    function setInAppPurchaseData(string memory _inAppPurchaseInfo, uint tokenId) public onlyOwner {
        inAppPurchaseInfo[tokenId] = _inAppPurchaseInfo;
    }
    function getInAppPurchaseData(uint tokenId) public view returns(string memory) {
        return inAppPurchaseInfo[tokenId];
    }
    mapping(uint => bool) inAppPurchaseBlackListTokenId;
    function setInAppPurchaseBlackListTokenId( uint tokenId, bool isBlackListed) public onlyOwner {
        inAppPurchaseBlackListTokenId[tokenId] = isBlackListed;
    }
    function getInAppPurchaseBlackListTokenId(uint tokenId) public view returns(bool) {
        return inAppPurchaseBlackListTokenId[tokenId];
    }
    mapping(address => bool) inAppPurchaseBlackListWallet;
    function setInAppPurchaseBlackListWallet(address wallet, bool isBlackListed) public onlyOwner {
        inAppPurchaseBlackListWallet[wallet] = isBlackListed;
    }
    function getInAppPurchaseBlackListWallet(address wallet) public view returns(bool) {
        return inAppPurchaseBlackListWallet[wallet];
    }

    uint8[] public players;

    AggregatorV3Interface internal priceFeed;

    function getLatestPrice() public view returns (uint256, uint8) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function setupType(
        uint8 _type,
        uint256 _price,
        uint256 _limit,
        string memory _name,
        string memory _description,
        string memory _image
    ) private {
        priceForType[_type] = _price;
        priceInitialForType[_type] = _price;
        limitForType[_type] = _limit;
        nameForType[_type] = _name;
        descriptionForType[_type] = _description;
        imageForTypeMaxKm[_type] = _image;
        imageForType75PercentKm[_type] = _image;
        imageForType50PercentKm[_type] = _image;
        imageForType25PercentKm[_type] = _image;
    }

    constructor(uint256 networkId, address _gameServer) ERC721("dexGoNFT", "DEXGO") {
        gameServer = _gameServer;
        players = [SHOES0, SHOES1, SHOES2, SHOES3, SHOES4, SHOES5, SHOES6, SHOES7, SHOES8, SHOES9];
        uint startPrice = 0.01 ether;
        if (networkId == 137) startPrice = 10 ether;

        setupType(SHOES0, startPrice, 0, "Downtrodden nerds",
            "Downtrodden Nerds are those favorite sneakers with which you went through fire, water and copper pipes. Joint memories do not allow you to replace them with a new couple. A budget model for the start, with which you will definitely overcome 10 km per day. Shoes are easy to repair and go with them on a new trip. Walk confidently, take care of your health and know that coins are already jingling on your account.\nDexGo is a move to earn project that has made a splash in the NFT games market. Now the usual routine of maintaining an active lifestyle is turning into a full-fledged process of moneymaking and interactive interaction with space in augmented reality technology. Unlike standard games of this type, DexGo opens familiar city locations from new, completely unexpected sides.",
            "Shoes1.gif");
        setupType(SHOES1, startPrice + 1 * startPrice / 10, 0, "Inconspicuous walkers",
            "Fans of classic sneakers will definitely fall in love with this pair. Sleek silhouette, practical materials and running comfort are the formula for the success of the inconspicuous walkers. This pair is an ideal partner in daily steps, mastering new routes and effectively replenishing the crypto piggy bank. You can easily overcome 11 km non-stop with it. After a hike, sneakers can be restored for further walks.\nDiscover new facets of augmented reality NFT games with the DexGo project. Let your daily activity turn into an exciting quest with valuable rewards. DexGo is a care for the physical form and an opportunity to discover new facets of the familiar reality.",
            "Shoes2.gif");
        setupType(SHOES2, startPrice + 2 * startPrice / 10, 0, "High runners",
            "Faster, higher, stronger - this is the only way you will complete routes in futuristic high runners. This model is a real find for lovers of tourism. Fast lacing, a tread that prevents trips, slips and falls, and an innovative foam platform to cover long distances of 12 km without repair - that's what makes these stylish beauties so popular.\nLet your love of long walking bear fruit. DexGo is a project with which hiking becomes brighter and turns into money. Walk, earn cryptocurrency and master new routes within the framework of the project for the benefit of the body and soul.",
            "Shoes3.gif");
        setupType(SHOES3, startPrice + 3 * startPrice / 10, 0, "Pink walkers",
            "Pink Walkers - NFT-candy, with which it has become even easier to lose weight and keep fit. Universal handsome men will add zest to your moneymaker arsenal. Walking 13 km? It's easy if you have these caramels on! After overcoming the 13-kilometer distance, the shoes must be restored. And then - you can conquer new horizons of your favorite city.\nDexGo is a game that wins the hearts of fans of interactive NFT projects in the move to earn style by leaps and bounds. It is chosen for its interactivity and the ability to film your trip, addictive gameplay and fair cash payments, the size of which depends only on you. This is the only project that takes care of your activity and leisure. Support for daily steps, exciting adventures on the routes - DexGo has something to surprise you.",
            "Shoes4.gif");
        setupType(SHOES4, startPrice + 4 * startPrice / 10, 0, "White boosters",
            "White Boosters are sneakers that will definitely take you back to the future. Futuristic high-ankle sneakers protect against injuries during the route, help to collect the maximum of bonuses and rewards, and cover up to 14 kilometers without recovery. Stylish, spectacular, profitable - this is the motto of the owners of this snow-white couple.\nDexGo is a new era in the blockchain space. Thanks to the project, you will be able to charge yourself with a cocktail of vivacity, explore interesting routes and replenish your pocket with crypto!",
            "Shoes5.gif");
        setupType(SHOES5, startPrice + 5 * startPrice / 10, 0, "Rushing forward",
            "Elegant Jordans in an expensive and spectacular gray-crimson shade - that's the key to success! Rushing Forward are the shoes of real champions, who are not ready for half measures in matters of money making. Shoes will easily help to overcome 15 km without restoration and repair. Be sure that in these sneakers you are not afraid of extra pounds and poor health.\nDiscover new unexplored locations on the DexGo travel maps and go on a journey of the future with us. The NFT game will change your idea of earning money, investing and a profitable hobby. You just need to take a step, and after him another ...",
            "Shoes6.gif");
        setupType(SHOES6, startPrice + 6 * startPrice / 10, 0, "Elegant Winners",
            "From premium leather and stylish lacing to a lightweight sole and perforated surface, everything is perfect. Elegant winners are a couple created for success, discovery and long 16 km walks in the fresh air. To be restored after passing its distance. Walk confidently, meet other users on the route and discover familiar locations from a new, unknown side.\nDexGo is a fresh take on the beloved move to lose weight and earn money game. The project not only provides walking with 100% liquidity, but also opens up promising locations for an exciting game. Open the portal from the NFT universe to reality in a beautiful, spectacular and profitable way!",
            "Shoes7.gif");
        setupType(SHOES7, startPrice + 7 * startPrice / 10, 0, "Robots",
            "Robots are a design of the future. Every step in them is like soaring on the clouds. The bold and slightly aggressive visual of robots literally screams to its future owner - We will conquer this world!. Toe protection, comfortable tread, no fuss with lacing - this pair is made for true winners. Robot rovers are not afraid of ultra-long distances and can easily cover 17 km with you. After undergoing repairs, they are ready to conquer new peaks of the routes.\nTurn, walking into cryptocurrency gold with DexGo. Earn blockchain assets quickly, confidently and for the benefit of your well-being! The game allows you to fatten up your wallet by burning your calories while exploring city routes at the same time.",
            "Shoes8.gif");
        setupType(SHOES8, startPrice + 8 * startPrice / 10, 0, "Hidden pioneers",
            "Hidden Pioneers is the very case when space potential is hidden behind a laconic pair of sneakers. Handsome men with a bold and memorable design are just waiting for their opportunity to walk with you without repairing an 18-kilometer marathon along interesting routes developed.\nAllow yourself the luxury of wellness walks around the city and start making money doing what you love with DexGo. Turn your steps into real money and enjoy the activity with the sound of coins.",
            "Shoes9.gif");
        setupType(SHOES9, startPrice + 9 * startPrice / 10, 0, "Top Talkers",
            "TikTok fans will squeal with delight when they try on these sneakers - because finally you can earn money yourself from the audience and videos. Signature leather tone and lacing, reliable Velcro that fixes the pair on the ankles, will help you overcome the 19-kilometer distance in one go without stopping for repairs. Top Talkers will inspire you to record an exciting video of the route, for which the owner receives a decent cash. At the same time, shoes will not leave a single hope for long distances to doubt their strength and reliability. Top Talkers are a unique DexGo product that reveals the routes of popularity.\nThe profitable DexGo project contains all the delights of the project's capabilities within walking distance: interesting routes of your favorite city, video filming of a walk, interactive and, of course, a decent reward for active participation. Turn your movement into real money and a stellar adventure!",
            "Shoes10.gif");
        setupType(MAGIC_BOX, startPrice + 3 * startPrice / 10, 0, "Magic Box",
            "The most unpredictable character. The Magic Box is the ultimate opportunity to own a pair of DexGo shoes for just $11. What kind of sneakers will be in your chest - is decided randomly after opening it. It is quite possible that it is you who will be lucky enough to become the owner of ultra-hardy Top Talkers at a price half that of the market price. Trust fate and catch luck by the tail.\nDexGo is a project about movement, willpower training and unexplored routes of light earnings. The game was created for pumping a healthy lifestyle for a decent income. Take care of your body, recharge your emotions and discover new city locations.",
            "MagicBox.gif");

        if (networkId == 1) priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH mainnet
        if (networkId == 4) priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);// ETH rinkeby
        if (networkId == 42) priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);// ETH kovan
        if (networkId == 56) priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);// BCS mainnet
        if (networkId == 97) priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);// BCS testnet
        if (networkId == 80001) priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);// Matic testnet
        if (networkId == 137) priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);// Matic mainnet
    }


//    function pause() public onlyOwner {
//        _pause();
//    }
//
//    function unpause() public onlyOwner {
//        _unpause();
//    }

    uint public increaseValue = 500;
    function setIncreaseValue(uint _increaseValue) public onlyOwner {
        increaseValue = _increaseValue;
    }

    function _increasePrice(uint8 typeNft) private {
        uint256 currentPrice = priceForType[typeNft];
        priceForType[typeNft] = currentPrice.add(currentPrice.div(increaseValue));
    }

    mapping(uint => bool) public approvedPathOrMovie;
    function setApprovedPathOrMovie(uint tokenId, bool isApproved) public {
        require(msg.sender == gameServer || msg.sender == owner() || msg.sender == accountTeam1 || msg.sender == accountTeam2,'DexGoNFT: only server account can change it');
        approvedPathOrMovie[tokenId] = isApproved;
    }
    function getApprovedPathOrMovie(uint tokenId) public view returns (bool) {
        return approvedPathOrMovie[tokenId];
    }

    function mint(address to, string memory uri, uint8 typeNft) public {
        require(typeNft == PATH || typeNft == MOVIE, "DexGoNFT: counter reach end of limit");
        _safeMintType(to, uri, typeNft, true);
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _safeMintType(address to, string memory uri, uint8 typeNft, bool needURI) private {
        uint256 counter = counterForType[typeNft];
        counterForType[typeNft] = counter + 1;
        if (limitForType[typeNft] > 0) require(counter + 1 < limitForType[typeNft], "DexGoNFT: counter reach end of limit");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        if (needURI) _setTokenURI(tokenId, uri);
        typeForId[tokenId] = typeNft;
        _increasePrice(typeNft);
        kmLeavesForId[tokenId] = priceInitialForType[typeNft];

    }

    function safeMintType(address to, string memory uri, uint8 typeNft) public onlyOwner {
        _safeMintType(to, uri, typeNft, true);
    }

    function safeMintTypeBatch(address[] memory to, uint8[] memory typesNft) public onlyOwner {
        for(uint256 x=0;x<typesNft.length;x++) {
            _safeMintType(to[x], "", typesNft[x], false);
        }
    }

    function valueInMainCoin(uint8 typeNft) public view returns (uint256) {
        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = getLatestPrice();
        uint256 valueToCompare = priceForType[typeNft].mul(10 ** decimals).div(priceMainToUSDreturned);
        return valueToCompare;
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % players.length;
    }

    bool public isIGO = true;
    function setIsIGO(bool _isIGO) public onlyOwner {
        isIGO = _isIGO;
    }

    event Purchase(address indexed from, uint256 value, uint8 typeNft, uint8 finalTypeNft, address referrer, uint valueForOwner);

    function _distributeMoney(address sender, uint value) private returns (uint){
        address[] memory friends;
        uint friendsCount;
        uint valueForOwner = value;
        (friends, friendsCount) = IHandshakeLevels(handshakeLevels).getHandshakes(sender);
        // invitation bonus
        uint valueForFriend;
        if (friends[0] != address(0)) {
            valueForFriend = value * IHandshakeLevels(handshakeLevels).getPercentPerInvitationBonusWei() / 1 ether;
            Address.sendValue(payable(friends[0]), valueForFriend);
            valueForOwner = valueForOwner.sub(valueForFriend);
        }

        for(uint8 x=1;x<friendsCount;x++) {
            if (friends[x] != address (0) && block.timestamp - latestPurchaseTime[friends[x]] < 60 * 60 * 24 * 30) { // must make at least one purchase per months to receive reward
                valueForFriend = value * IHandshakeLevels(handshakeLevels).getPercentPerLevelWei(x) / 1 ether;
                Address.sendValue(payable(friends[x]), valueForFriend);
                valueForOwner = valueForOwner.sub(valueForFriend);
            }
        }
        uint toFirstAndSecondTeam = valueForOwner / 3;
        Address.sendValue(payable(accountTeam1), toFirstAndSecondTeam);
        valueForOwner = valueForOwner.sub(toFirstAndSecondTeam);
        Address.sendValue(payable(accountTeam2), toFirstAndSecondTeam);
        valueForOwner = valueForOwner.sub(toFirstAndSecondTeam);
        Address.sendValue(payable(owner()), valueForOwner);
        return valueForOwner;
    }

    uint public valueDecrease = 10000000;
    function setValueDecrease(uint _valueDecrease) public onlyOwner {
        valueDecrease = _valueDecrease;
    }
    function purchase(uint8 typeNft, address referrer, string memory _inAppPurchaseInfo) payable public {
        require(msg.value > valueInMainCoin(typeNft).sub(valueDecrease), "DexGoNFT: wrong value to send");
        require(handshakeLevels != address (0), "DexGoNFT: wrong HandshakeLevels");
        require(typeNft <= 10, "DexGoNFT: wrong type");

        uint8 finalTypeNft = typeNft;

        if (typeNft == MAGIC_BOX) {
            finalTypeNft = uint8(random());
        }

        if (IHandshakeLevels(handshakeLevels).getFullList(msg.sender) == 0 && isIGO) IHandshakeLevels(handshakeLevels).setHandshake(msg.sender, referrer);

        uint valueForOwner = _distributeMoney(msg.sender, msg.value);

        latestPurchaseTime[msg.sender] = block.timestamp;
        inAppPurchaseInfo[_tokenIdCounter.current()] = _inAppPurchaseInfo;
        _safeMintType(msg.sender, "", finalTypeNft, false);

        emit Purchase(msg.sender, msg.value, typeNft, finalTypeNft, referrer, valueForOwner);
    }

    function purchaseBatchValue(uint8[] memory typesNft) public view returns (uint256) {
        uint256[] memory _priceForType = new uint256[](10);
        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = getLatestPrice();

        uint256 totalValueToPay;
        for(uint256 x=0;x<typesNft.length;x++) {
            if (_priceForType[typesNft[x]] == 0) _priceForType[x] = priceForType[typesNft[x]];
            require(typesNft[x] <= 10, "DexGoNFT: wrong type");
            uint256 valueToCompare = _priceForType[typesNft[x]].mul(10 ** decimals).div(priceMainToUSDreturned);
            totalValueToPay = totalValueToPay + valueToCompare;
            uint256 currentPrice = _priceForType[typesNft[x]];
            _priceForType[typesNft[x]] = currentPrice.add(currentPrice.div(increaseValue));
        }
        return totalValueToPay;
    }
    function purchaseBatch(uint8[] memory typesNft, address referrer, string[] memory _inAppPurchaseInfo) payable public {
        require(msg.value >= purchaseBatchValue(typesNft).sub(valueDecrease), "DexGoNFT: wrong value to send");

        if (IHandshakeLevels(handshakeLevels).getFullList(msg.sender) == 0 && isIGO) IHandshakeLevels(handshakeLevels).setHandshake(msg.sender, referrer);

        uint valueForOwner = _distributeMoney(msg.sender, msg.value);
        for(uint256 y=0;y<typesNft.length;y++) {
            uint8 finalTypeNft = typesNft[y];
            if (typesNft[y] == MAGIC_BOX) {
                finalTypeNft = uint8(random());
            }
            inAppPurchaseInfo[_tokenIdCounter.current()] = _inAppPurchaseInfo[y];
            _safeMintType(msg.sender, "", finalTypeNft, false);
            emit Purchase(msg.sender, msg.value,  typesNft[y], finalTypeNft, referrer, valueForOwner);
        }
        latestPurchaseTime[msg.sender] = block.timestamp;
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        require(!inAppPurchaseBlackListWallet[from] && !inAppPurchaseBlackListTokenId[tokenId], "DexGoNFT: wallet or tokenId blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURIForType(uint8 typeNft, string memory nameReplaced, uint256 tokenId)
    public
    view
    returns (string memory)
    {
        string memory image = imageForTypeMaxKm[typeNft];
        if (kmLeavesForId[tokenId] * 100 / priceInitialForType[typeNft] < 25) image = imageForType25PercentKm[typeNft];
        if (kmLeavesForId[tokenId] * 100 / priceInitialForType[typeNft] < 50) image = imageForType50PercentKm[typeNft];
        if (kmLeavesForId[tokenId] * 100 / priceInitialForType[typeNft] < 75) image = imageForType75PercentKm[typeNft];

        if (bytes(nameReplaced).length == 0) nameReplaced = nameForType[typeNft];
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                                nameReplaced,
                            '", "description":"',
                                descriptionForType[typeNft],
                            '", "image": "',
                                string(abi.encodePacked(ipfsRoot,image)),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        bytes memory tempEmptyStringTest = bytes(super.tokenURI(tokenId));
        if (tempEmptyStringTest.length == 0) {
            return tokenURIForType(typeForId[tokenId], namesChangedForNFT[tokenId], tokenId);
        }
        else return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


    // rent
    uint256 public fixedAmountOwner = 0.001 ether;
    function setFixedAmountOwner(uint _fixedAmountOwner) public onlyOwner {
        fixedAmountOwner = _fixedAmountOwner;
    }

    uint256 public fixedAmountProject = 0.001 ether;
    function setFixedAmountProject(uint _fixedAmountProject) public onlyOwner {
        fixedAmountProject = _fixedAmountProject;
    }

//    contract size overload, need separate contract for rental
//    struct RentableItem {
//        bool rentable;
//        uint256 percentToShareWei;
//        address borrower;
//        uint256 borrowerChangedLatestTimestamp;
//        uint256 revenue;
//    }
//    mapping(uint => RentableItem) public rentables;
//
//    function setRentPercentToShareAndRentable(uint256 _tokenId, uint256 _percentToShareWei, bool _rentable) public {
//        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Caller is not token owner nor approved");
//        require(!inAppPurchaseBlackListWallet[msg.sender] && !inAppPurchaseBlackListTokenId[_tokenId], "DexGoNFT: wallet or tokenId blacklisted");
//
//        rentables[_tokenId].percentToShareWei = _percentToShareWei;
//        rentables[_tokenId].rentable = _rentable;
//    }
//
//
//    function allRentablesRentable() public view returns (RentableItem [] memory, uint) {
//        RentableItem [] memory rentablesReturn = new RentableItem[](_tokenIdCounter.current());
//        uint256 rentablesReturnCount;
//        for (uint i; i < _tokenIdCounter.current(); i++) {
//            if (rentables[i].rentable == true) {
//                rentablesReturn[rentablesReturnCount] = rentables[i];
//                rentablesReturnCount++;
//            }
//        }
//        return (rentablesReturn, rentablesReturnCount);
//    }
//    function allRentablesRentableAndFree() public view returns (RentableItem [] memory, uint) {
//        RentableItem [] memory rentablesReturn = new RentableItem[](_tokenIdCounter.current());
//        uint256 rentablesReturnCount;
//        for (uint i; i < _tokenIdCounter.current(); i++) {
//            if (rentables[i].rentable == true && rentables[i].borrower == address (0)) {
//                rentablesReturn[rentablesReturnCount] = rentables[i];
//                rentablesReturnCount++;
//            }
//        }
//        return (rentablesReturn, rentablesReturnCount);
//    }
//
//    event UpdateRentable(uint256 indexed tokenId, address indexed user, bool isRented);
//
//    function rent(uint256 _tokenId) public payable {
//        require(msg.value == fixedAmountOwner + fixedAmountProject, "Incorrect fixed amount");
//        require(rentables[_tokenId].borrower == address(0), "Already rented");
//        require(rentables[_tokenId].rentable, "Renting disabled for this NFT");
//        require(!inAppPurchaseBlackListWallet[msg.sender] && !inAppPurchaseBlackListTokenId[_tokenId], "DexGoNFT: wallet or tokenId blacklisted");
//        payable(ownerOf(_tokenId)).transfer(fixedAmountOwner);
//
//        _distributeMoney(msg.sender, fixedAmountProject);
//
//        rentables[_tokenId].borrower = msg.sender;
//        rentables[_tokenId].borrowerChangedLatestTimestamp = block.timestamp;
//        emit UpdateRentable(_tokenId, msg.sender, true);
//    }
//
//    uint public minRentalTimeInSeconds = 120;
//    function setMinRentalTimeInSeconds(uint _minRentalTimeInSeconds) public onlyOwner {
//        minRentalTimeInSeconds = _minRentalTimeInSeconds;
//    }
//
//    function rentReturn(uint256 _tokenId) public {
//        require(_isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == rentables[_tokenId].borrower, "Caller is not token owner nor approved or not borrower");
//        require(block.timestamp - rentables[_tokenId].borrowerChangedLatestTimestamp > minRentalTimeInSeconds, "Minimal rent time isn't reached");
//
//        rentables[_tokenId].borrower == address(0);
//        rentables[_tokenId].borrowerChangedLatestTimestamp = block.timestamp;
//        emit UpdateRentable(_tokenId, rentables[_tokenId].borrower, false);
//    }


    uint public nameChangeFee = 0.001 ether;
    function setNameChangeFee(uint _nameChangeFee) public onlyOwner {
        nameChangeFee = _nameChangeFee;
    }
    mapping(uint => string) public namesChangedForNFT;
    function setNameForNFT(uint256 _tokenId, string memory _name) public payable {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not token owner nor approved");
        require(msg.value == nameChangeFee, "Incorrect amount");
        _distributeMoney(msg.sender, nameChangeFee);
        namesChangedForNFT[_tokenId] = _name;
    }

    // repair
    //a standard repair lasts 2 days and costs $5. You can order an accelerated repair for 2 hours and $20
    //each repair decrease maximum kilometers on 1%

    mapping(uint256 => uint256) kmLeavesForId;
    function setKmForId(uint256 tokenId, uint256 km) public {
        require(msg.sender == gameServer || msg.sender == owner() || msg.sender == accountTeam1 || msg.sender == accountTeam2,'DexGoNFT: only server account can change km');
        kmLeavesForId[tokenId] = km;
    }
    function getKmLeavesForId(uint256 tokenId) public view returns (uint256) {
        return kmLeavesForId[tokenId];
    }
    uint256 public fixedRepairAmountProject = 0.001 ether;
    function setFixedRepairAmountProject(uint _fixedRepairAmountProject) public onlyOwner {
        fixedRepairAmountProject = _fixedRepairAmountProject;
    }
    mapping(uint256 => uint256) public repairFinishTime;
    function getRepairFinishTime(uint tokenId) public view returns (uint) {
        return repairFinishTime[tokenId];
    }
    function setRepairFinishTime(uint tokenId, uint timestamp) public onlyOwner {
        repairFinishTime[tokenId] = timestamp;
    }
    mapping(uint256 => uint256) public repairCount;
    function getRepairCount(uint tokenId) public view returns (uint) {
        return repairCount[tokenId];
    }
    function setRepairCount(uint tokenId, uint count) public onlyOwner {
        repairCount[tokenId] = count;
    }
    function repair(uint256 _tokenId, bool isSpeedUp) public payable {
        if (isSpeedUp) {
            require(msg.value == fixedRepairAmountProject * 4, "Incorrect amount");
            _distributeMoney(msg.sender, msg.value);
            repairFinishTime[_tokenId] = block.timestamp + 60 * 60 * 2; // 2 hours
        } else {
            require(msg.value == fixedRepairAmountProject, "Incorrect amount");
            _distributeMoney(msg.sender, msg.value);
            repairFinishTime[_tokenId] = block.timestamp + 60 * 60 * 24 * 2; // 2 days
        }
        repairCount[_tokenId] = repairCount[_tokenId] + 1;
        kmLeavesForId[_tokenId] = priceInitialForType[typeForId[_tokenId]] * repairCount[_tokenId] / 100;
        latestPurchaseTime[msg.sender] = block.timestamp;
    }

}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IHandshakeLevels {
    function getFullList(address wallet) external view returns (uint);
    function getHandshakes(address wallet) external view returns (address[] memory, uint);
    function getPercentPerLevelWei(uint8 position) external view returns (uint);
    function getPercentPerInvitationBonusWei() external view returns (uint);
    function setHandshake(address wallet, address referrer) external returns (uint,uint, bool, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}