// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

// ####BPPG#&&&&############BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5
// ##BPYP5YGGGBBB#######BBGGGGGBGPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555555555555555555555555555555555PPPPPPPPPPPPPPPPP5
// BBG?J#GP&B5G#@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPPPPPP5YYYJYYYYJJJJJJJJJJJJJJYYYYYYYYYYY555555555YYYYY55PPPPP5
// &&B?Y##B##BYB#&@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPB#PPP5555555YYY55PPP55555555PGGBBGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55YJJPPPP5
// &&B?Y###&#B5PBGG#@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPGG5555555555YYYJJJJJJJJ?JJJ????JYPBBPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPP5?YPPP5
// #&B?5#BB##B5Y5PP5G#@@@@@@@@@@@&&&&@&BGPPPPPPPPPPGGPP5YYJJJJJJJJJJJJJ????JJ?77JJJJJJJ???YBBPPPPPPPPPPPPPPPPPGPPP5PPPPPPPPPPPPGGPPPPPPPPPPPPPPPPP5??5PP5
// ~!P?5BBB##BBBYJ5PPB5B&@@&&@@@@@@@@@@@@#GPPPPPPPB5JJJJJJ????????JJJ?7777?JJJ??JJJJJJJJJJ7?GBPPPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPP5PPPPGBPPPPPPPPJJY5PP5
// #7.!G&####BYG&BYYYP55B#&@@@@@@@@@@@@@@@@#GPPPPBY?JJJJJJ???????JJJJJ?????JJJJJJJJJJJJJJJJ?7PBPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGP?Y55PP5
// PY???JP#@#B5PPGBBPYJ5PGGB&@@@@@@@@@@@@@@@@#GG#YJJJJJJJJJJ???JJJJJJ???????JJJJJJJJYJJYJJJ55?5GPPPPPPPPPPPPPPPP5PPPPPGBPPPPPPPPPPPPPPPPPPPPPPPPBG?555PP5
// !!!????!Y&&BGBGP5B#GYY5PPPG&@@@@@@@@@@@@@@&B#GP5YYJJJJJJJJJJJJJJJJJJ?JJJJYYJJJJJJYYYYY5PPPPYPGPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPY?555PP5
// ^^^!???P?~Y&&###BP5G#PJY5P5PP#@@@@@@@@@@@@###BGGPPP55YYJJJ?JJJJJJYYYJJJJJYJ????JJJJY5PPPPPB#GGYPPPPPPPPPPP555PPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPY?555PP5
// ^^^!??~^?5J~5&&###BG5GBPYY5P55G&@@@@@@@@@&######BBGGGPP5PP555YYY555PYYYYYJ?JYY5P5JJ555PPPB####Y7?????????JJ?????????77??????YJ?????????77????????????7
// ^^^!??~^^^55!!J#&&###55GBB#5Y5PGG#@@@@@@@@&&#######B#BBGGBGPPPGGP5PPGGGY7!!JPGP5YYJYYYPPP####&G??J?JJ???YGGY??????J?~~7J???JGGJ?J????J?~!????J??J??JJ?
// ^^^!?7^^^^^!?PJ!?#&###GP5G#BYJ5PP5G#@@@@@&&@&######BB###B#GPPPBBG5555?YJ??J?YP?!!?YJJJGGG####&#J??J??JJ????????????JJJJ?????????J?????JJJ???J???J??JJ?
// J7^~??^^^^^::^75Y!J#&#[email protected]@@&@@@&######B###GGB#GPGGPPPP5J?JPPG5J55YY5P5PPGBB#####&YJ?J??J???????????????????????J??J????5BJ????J???77JJJ?
// :?5J??^^^^^^:.:^75J7?G&####G5PBB5JY5P55B&&&@@@&#####B###BGB##BPPPPP55P5YYY5JJ75GPPPPPPPGB#####&BY??JJ????????????????????????J??J????JYJ????J??????JJ?
// ^::7???^^^^!!~:.!GJ5Y~7P&&BGYP5P#BG#B5PBB&&@@@@#####B####B#####GPPYJ5PP5Y555YJ5GPPPPPPG#######&&#Y7!7J??????????????????????????J???????????J??????JJ?
// ??!^??5P!^^!!!!~~!::?5Y77G&#GG#G5PB&PJYP5&&&@@@&####B#####B######GGPPPPP55Y5PGPPPPPPPG########&&&B??????????????????????J???????J?????????????J????JJ?
// 777???^^Y5~!!!!!!!^..^~J5?7G&#B##BP5GB5YYB&&&@@@####B#####B########BGPPPPPPPP5GGPPPPG#########&&&&P7?J??????????????JJJ?????????J?????????????J????JJ?
// 7777??7~.!557!!!7P7!^.::~YY?7YB##B#[email protected]&&&&&&####################BBGPPPPPY5GPGGB##BBBBBBB#&&&&#Y7J????????????????????????J????????JJ????J?????JJ?
// 7777????7~:!JPY7!!!!JY^:.!YJP7~JB&#&[email protected]&&@@@&#######################BBGGPPPPPPPPPP55GBBB#&##&@&G7?J?JJ?????????YJ???????5Y??J??????77J??J??????JJ?
// 777?????7?7!!^7GJ!!!JJ!!~?Y:~Y5J!J#&B5#B5P&&#&&@@&###########BBBBBGGPPPPP55555555555555GBBBB#&##&@&#J7??????JJYY55P#GPPPPP5YPY!?JJJJJJJ7?JJJJ??????JJ?
// 777?????7777?7^^?PJ!!!!!!!~:.:^?PJ~?#&##[email protected]&&@&&&&#&&&&&&#&###BBBBBBGP555555555555555PGBBBB#&###&@@&B7?Y5PGGGPP555P55PP5YY5G#BGJ?JJJJJJJJ?JJJ??????JJ?
// 7?77???7777777?7^^JPY!!!!!!!~:.:^!YY!JB&#[email protected]&@@@@@@@&&&&##&&&&&##BBBBBBGPP55555555555PBBBBBB#&###&&@&&####BBBGPPPP5PPPGGGGPYY##P^^^^^^^^^^^^^^~?!!?~^^^
// .^!7?777J?7?77?5PJ~:JPJ?!!^^~!~:::^7Y5!?B#@&@&@@@@@@@@@&#####&&&#BBBBBBBBGGPPPPPPPGBBBBBBBB&&&&&&&@@@@#GGGGGGBBB#BGGGPPPPBBB57:::::::~7::::::~?~~?^:::
// ?..:!7??5?7~77?PPP?~~^!PP!:^^~!!~^.:^!YY7?B&&&@@@@@@&&&&&######&&##BBBBBBGBBBBBBBBBBBBBBBB#######&&&&&&&&####GP5YY5PPGPP5J!^!Y::^::::!?::::::~?~!?~:::
// ^.~^.~!7777!7!!7?57??7~^75P7^!!!!!~::^!JBPB&@@@@@&&&&&@@@&&&&##&#&&#BBBBBGBBBBBBBBBBBBB#####&&&@@@@&#BGPYJJJJJY55JJ7~~^::::::^:::::::::::::::~?^!?^:::
//    :~?::~J?777777J77!777~:!5J77?J5PGGBB#BB&&@@@&@@@@@@@@@@&&&&##&#####BBBGBB####&&&&@@@&&@@&##BP5J??77?J5P5YJ7~^:::::::::::::::::::::::::::::~?^!?^:::
//     ^?!^.:~7?7777!!777?JJYJY#BBBBBBBBBBB##&&@@@@@@@@@@@@&&&&###B#####&&&&#&&&&&&&##BBGP5YJJ?7??JJYYPB#&Y~^::::::::::::::::::::::::::::::::::::?~!?^:::
// ^   ^7 ?B~.^7???77~^5GGBBBBBBGBBBBBBB#&&&&&&&&&&&####[email protected]@G:::::::::::::::::::::!7::::::::::::::^^^:!?^:::
//     ~7 .: .^^^!?JP?J###BBBBBBBBBBBBBBBBBBBGGPPP555YYYYJJJJJJ?????77777??JJ5PGGGGP5Y55YYJJ7     ^[email protected]@G::::::::::::::::::::::::::::::::::::^~^::^7^:::
//     !!      :^^^J&J7JP#&&&&&&&##BGGPPPP5YYJJJJJJ?????77777!!7?77??JYY555YJ?!~^:....??????7     [email protected]&Y^::::::::::::::::::::::::::::::::::::::7??7::::
//     !~  :.    .^::!777?JJJJJJJJJJJJJJ?J5Y?????YP5??~^^~~!!7?75J~~~::..   .     .  .??????7      :[email protected]#::::::^::^^:::::::::::::::::::::::::::::7??!::::
//     7: .Y^     :~: .~7?7777!777777777!^[email protected]??:7??7!^77 :?.         .    .    7?????7       [email protected]::::::::::::::::::::::::::::::::::::::::!??~::::
//     .          . . .^!~7777?777!!7777?7~:[email protected]@B7!7&&&@@@@@#B#GYJ7^:    .   ..   .??????7       ^[email protected]#^:::::::::::::::::::::::::::::::::::::::~?7:::::
//    :!               .J.~?77777?7^777777??:^B77&@&?: ...:^?5PGGB#&&@@&BY7:.   .    ^???????...     !#@&!!!!!~!~!!!!!!!77!!!!!!!~!~!!7!~!7!777!~7J?!!!!!
//    ^?             .:^^~7777777!!77?Y??7!:~GJ7?&@#:       !??77??!.^!7J#@&!   .    .??5G7:!YJ  : .~7#@@#GP5Y5B&BPBBPP5P5GBGBG5GBB#&#B#BB#GPGGBGP5GGPGBG
//    ^?.          .^^^~7?77777!!77777J?~::JG?!?J&@#.   ..  :?57!??~     .P&#^   .  . :J&&GP#@!:PJ  7J&@@@PG5G##G5PPPG555G5GBPBGY5BG#&BPG#5PPY5YYPGPJGG#P
//    ^?.        .^^:7???7777!!7!777?7~^[email protected]@#^ ..  !P&@@@@#5:  ..  :&&J   ...  ?&@@@@@@@@Y  .7?#@#@@&#GPGGGGBGPPPYGPGBGGG55BBBBBGBG5PP5555P5J5GGBP
//    ~?:      :^^^!?Y?7777!!777!7?7^~YYY77!!!J&@@@@7.   [email protected]@@#G&@@@G^  ..  #@5       [email protected]@@@5Y&@@@[email protected][email protected]@@5PPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGJ?5PPPP
//    ~?:    :^^^!7?77777!!7777??7^^[email protected]@&@@5:  [email protected]@@B7:[email protected]@@@B   .  [email protected] [email protected]@@G ~&@@@@7:[email protected]:[email protected]@&YPPPPPPPPGBPPPPPPPPPP5PPPPPPPPPPPPPPPJ?5PPPP
//    !?^ .^^:^!??7?J7!!77777?7!^:?B?!?7!!!!~7&@[email protected]#G7 .#@@@[email protected]@@@&.  .  [email protected]   ..  [email protected]@@P:[email protected]@@@&JJJ??#B^&@@B?5PPPPYP5PGY5PGGGPPPP5PPBPGGGGBBGBBPGY?YGP55
//    7?~^:..~7?777?Y777777?7!:~?5P7!!Y7!!^:[email protected]@[email protected]&B?^ [email protected]@@&[email protected]@@@@7  .   [email protected]    .. [email protected]@@@#@@@@Y^::^??&P^@@@P?YYP55JGGB#YY#BB#PPPYJPGY5#B#GP&@B55B5?5BBJ?
//    7?!:.77?77777!77!77?7!^~5P?!!!!!!~~..:^7&@B^B&&J~  [email protected]@@@@@#G7  ..   [email protected]      .JG#@@&BY^  . ~?J&[email protected]@@P?JPPPPP555PPPGGBGPPPPPPPP555GBBGGBBBGJ?5P5P5
//  .^??^~??7777!!77777?7~:75Y?!!!!!!~:.^:^^[email protected]@[email protected]@5^ .  !5PP57:   ..    [email protected]&:       !77JJ?.      [email protected][email protected]@@Y?5PPPPPGPPPPPPPPPPPPPPPPPPPP555PPPPPGJ?PBGPP
// ~~^?????JJ?!!777777!~:755!!!!!!!~:.:^^^7YG&PP&&&@@5^    :?????!. ..     [email protected]&:       :?????.      !?Y#@&&#B5GGPP5555PPPPPPGGBGPGGGGGGBGBYJJPPGP55J?G&&P5
// .:!??77YBBY77777?7:.^JG!!!!!!!~^..^^~7YG###&BPB#@@B^     7????!         ~&&^        ^^7??: .    !?G&#B5PG5B#[email protected]&YYP#G5BGBB#B#PP5#5P5BYBPYPJ?5PPYG
// !????777777777?7^:YYY?!!!!!!~:.::^~?PGB##B###[email protected]@@~     :????!         ^&&^          !??....   7?G#5PPYY55P5Y5PPGGG5Y5PY555G55PG5P5PBPJPG5PPGG??PGPPP
// ?????7777777?7^~7PY!!!!!!!^:.:^^~?5B##B####BPJJ5&@@J      .???:         :@@?       .. ~?~ . .  .?J&#B#####B##BB####BB#B#############B#BB####B#G??B###G
// 7????7777?7!^:YP?!!!!!!!~:.:^^~?P#&#B####BPJJY5PB&@#.      :!~ .       ..?Y^      .   ~?..  .. :[email protected]########BB################B####B&&#######P?JB###B
// 7????77?7^.:~5P!!55?!!~^::?!:75B&#&&#GBB5JYBBYYG#&@@7         . .     .          ..^  .: .   . [email protected]&#BB######BBBB#####BB#####&&BB#####@@BB#####P?JBB##B
// 77????7^.7J55J!!!!7!::.::^~?5B###B###G5JY5PPPGG#&&@@B.         .~.    .   . ::  . :?.    .   ..?&####BBBBBB###BB##############BB#######BB#####5?5####B
// 77???^:^YP!!!!!!!~^..^^^~?PB#######B5JYPPPPPB#&@@##@@7   ...^^.?G!....YY...:?B7::.!B^.:.     .~G&B#####BBBBBBBB###############BB##############Y?P####B
// ??7??JPJ!^^!!!!~:.::^^~75B#B#####B5YY5P5PPG#&@@@@&[email protected]@#~  ^7PBBB#@BBBBB&@###B#@@##&&@&&#&?:   :G&B#############################BB#####BB#######5JG####B
// ~::??PG^^^^!!~^^..^~!JG##B####BG5JYBPJ5GB#&@@@@@@@&#&@G!  ~B&&&@@&#&&B&@&##BB&&[email protected]   .5&GG##########&#########BB#######BB##############Y?GB###B
// .!5???7^^^^~:.:::^J5G#######B5JY55PGP5B#&@@@@@@@@@&#[email protected]@B?: .:[email protected]::[email protected]:.YB . ^#!      ^[email protected]###################BB########B##############Y?BB###B
// Y?!?7^^^^^^::^^^!5G######BBPYJ5PPPPGB#@@@@@@@@@@@@&@@@@@&Y^    :P!     PJ    ^~   :J~    [email protected]&B################################B#####BB#######Y?B####B
// ^^~?7^^^^^^^^^~JG########PYJ5PPPPGB#@@@@@@@@@@@@@@@&&#&@@@B!.  .^.     ^. .  .    .!   .:[email protected]@####BB################BB######BBB#BB#####BB######5?G####B
// !^~?7^^^^^^^7YB##&####BPYYGGPPGBB&@@@@@@@@@@@@@@@@@###BB&@@@#Y~           .           .^[email protected]@########B####B############BB####&#BBB###BB####B###5?GBBB#B
// 7^~?!^^^^!?YB#######G5YYYP&&&##&@@@@@@@@@@@@@@@@&BPB#BBGGBB#@@@BJ^.       .          :!J#@&BB##BBBBBB#B########BBB########B###BBB#B#BB#B####B#P?BBB##B
// ^^~?!^^~75P#######B5J55PPPB&#&@@@@@@@@@@@@@@@@&BP5GGP555555PB#&B&@#57:            .^7YB&&#GGBBBGGGGGBBBBBBBBBBBBBBBGBBBBBBBGGBBGGBBBBBBBBBBBBB5JGBBBBG
// ^^~?!~JPBBB#####G5JJ5PPPPB#&@@@@@@@@@@@@@@@@&G5555555555PGGGP&@BYJY#@&#P5J?J7!?JY5GB&&&@#GBBBBBBBB#BBBBBBBBBBGBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBB5?PBBBBG
// ^^~?JG&G#BB###GYJJ5Y5PGG#&@@@@@@@@@@@@@@@@#BB55555555PPPBBG5J#@&J^ .:^?PGB#&&&&&&BPP7:[email protected]@&BBBBBBBB#BGBBBBBBBBGBBBBBBBGGBBBBBBBBBGBBBBBBBBBBBBBP?YBBBBG
// ~7Y?P##B#BBBPYJYY555BB#&@@@@@@@@@@@@@@@@#PGGG5555555G#[email protected]@5?~       ...:::..     :[email protected]@#BBBBBBBBGPGBBBBBBBBBBBBBBBGGB&BBBBBBBGBGPBBBBBBBBBBG?JBBBBG
// PGB?PB##&#BYJYPPPPGG#&&@@@@@@@@@@@@@@@#P55P555555PPGBGGGB#B&@@G??~                     [email protected]&#BGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBG?JBBBBG
// GGP?P###&#B55PPPGB#@@@&@@@@@@@@@@@@@#P5555555Y5Y5PPPG#&&@@@@&P???~                     .?#@@@#BGGGBGPGBGBBBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBGJJGBBBG
// BB5?P#B#@#BPPPGB#@@@@@&@@@@@@@@@@&#PYY5PGGGBBBBBBB#&@@@@&#B5J!^:^                       :5&@@@@&#GPPPGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5?PBBBG
// GBP?5##&@@&BBB&@@@@@@&@@@@@@@@@@&B#BB#@@@@@@@@@@@@&&#GP5J?!^.                            .!YP&@@@@&#BBGP5Y55555PPPPPPPPGGGGGGGGGBBBBBBBBBBBBBBBG?YBBBG
// B#BGB###&&&#&@@@@@@@@&@@@@@&@@@@@@@@@&&&#BP5JYYYYJJ?7!~^:.                                   :!?YP#&@@@@@@@@@@@@&&&#BBBBBGGBBBBGGBBBBBBBBBBBBBBBYJBBBG
// ##########&@@@@@@@@@@&&&@@@@&#G5YYYJJJJ?77!!!~~^::..                                               :~7J5PGB###B55PPGB&&&@@@@@@@&#BGBBBBBBBBBBBBBBGBBBG
// BBBBBBBB#&@&&&&&&&&&@@@@@BPYJ?????7!~^:..                                                                  ...       ..:~!?J55G&@&GGGGGGGGGGGGGGGGGGGG


import "./Ownable.sol";
import "./Address.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./Treasury.sol";
import "./ERC2981.sol";

contract CryptoHatz is Ownable, ERC721, ERC2981 {
  using Address for address;
  using SafeCast for uint256;
  using Strings for uint256;

  // EVENTS ****************************************************
  event baseURISet(string _uri);

  // MEMBERS ****************************************************
  
  uint256 public immutable MAX_SUPPLY;

  // Number of currently supplied tokens
  uint256 public totalSupply = 0;

  string public baseURI;

  /* Mapping from owner to list of owned token IDs */
  mapping(address => mapping(uint256 => uint256)) public _ownedTokens;
  /* Mapping from token ID to index of the owner tokens list */
  mapping(uint256 => uint256) public _ownedTokensIndex;
  
  Treasury public royaltyRecipient;

  // CONSTRUCTOR **************************************************
  
  constructor(
    string memory _baseURI, 
    uint256 _MAX_SUPPLY
  )  
    ERC721("CryptoHatz by Boy George", "HATZ")
    {
    //Sets the max supply
    MAX_SUPPLY = _MAX_SUPPLY;

    baseURI = _baseURI;
    emit baseURISet(_baseURI);

    address[] memory royaltyPayees = new address[](1);

    royaltyPayees[0] = 0xaF019dE18D30c5e0c5e1596ebf81B793648B9356;

    uint256[] memory royaltyShares = new uint256[](1);
    royaltyShares[0] = 100;
    
    royaltyRecipient = new Treasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 700); // 7% royalties

  }

  // PUBLIC METHODS ****************************************************

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallett
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  //Returns the number of remaining tokens available for mint
  function totalLeftToMint() view external returns(uint256){
    return MAX_SUPPLY - totalSupply;
  }

  /**
  Batch transfers NFTs to users
  @param to : Array of to addresses
  @param tokenIds : Array of corresponding token ids
  @return true if batch transfer succeeds
  */
  function batchTransfer(address[] memory to, uint256[] memory tokenIds) external returns(bool){

    require(to.length > 0, "Minimum one entry");
    require(to.length == tokenIds.length, "Unequal length of to addresses and number of tokens");
    require(tokenIds.length <= balanceOf(msg.sender),"Not enough tokens owned");
    
    for(uint256 i = 0; i < to.length; i++){
      safeTransferFrom(
        msg.sender,
        to[i],
        tokenIds[i]
    );
    }
    return true;
  }

  // Lets owner of token to burn it
  function burn(uint256 tokenId) external {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner and not approved by owner");
    _burn(tokenId);
  }

  // OWNER METHODS *********************************************************

    /// @notice Allows the contract owner to mint NFTs to a user
    /// @param to address for the reserved NFTs to be minted to
    /// @param numberOfTokens number of NFTs to reserve
    function mint(address to, uint256 numberOfTokens) public onlyOwner {
    require(numberOfTokens > 0, "Minimum one token");
    require((totalSupply + numberOfTokens) <= MAX_SUPPLY, "Exceeds max supply limit");

    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }
    totalSupply = newId;
  }

  /// @notice Allows the contract owner to mint NFTs to CryptoQueenz holders or team members or promotional purposes
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function bulkMint(address[] memory to, uint256[] memory numberOfTokens) external onlyOwner {
    require(to.length > 0, "Minimum one entry");
    require(to.length == numberOfTokens.length, "Unequal length of to addresses and number of tokens");
    
    uint256 totalNumber;
    uint256 i;

    for(i = 0; i < numberOfTokens.length; i++){
      totalNumber += numberOfTokens[i];
    }

    require((totalSupply + totalNumber) <= MAX_SUPPLY,"Exceeds max supply limit");
    
    for(i = 0; i < to.length; i++){
      mint(to[i], numberOfTokens[i]);
    }
  }

  /**
  @param tokenId : The token id
  Fetches the token URI of token id = tokenId. It will return dummy URI if the base URI has not been set.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json") ) : '';
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
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

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

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
     * by default, can be overriden in child contracts.
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

    function transfer(
        address to,
        uint256 tokenId
    ) public virtual returns(bool){
        transferFrom(msg.sender, to, tokenId);
        return true;
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./PaymentSplitter.sol";

contract Treasury is PaymentSplitter {
  uint256 private _numberOfPayees;

  constructor(address[] memory payees, uint256[] memory shares_)
    payable
    PaymentSplitter(payees, shares_)
  {
    _numberOfPayees = payees.length;
  }

  function withdrawAll() external {
    require(address(this).balance > 0, "No balance to withdraw");

    for (uint256 i = 0; i < _numberOfPayees; i++) {
      release(payable(payee(i)));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC165.sol";
import "./IERC2981.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
contract ERC2981 is ERC165, IERC2981 {
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }

  RoyaltyInfo private _royalties;

  /// @dev Sets token royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function _setRoyalties(address recipient, uint256 value) internal {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  /// @inheritdoc	IERC2981
  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

import "./IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}