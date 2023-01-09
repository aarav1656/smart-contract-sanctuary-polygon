// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./UpperSkyPremiumWLNFT.sol";
import "./UpperSkyWLNFT.sol";
import "./UpperSkyWhitelist.sol";

error UpperSky__TransferFailed();
error UpperSky__NotEnoughMoneySent();
error UpperSky__CollectionSoldOut();
error UpperSky__NFTAlreadyMinted();
error UpperSky__NFTIndexDoesNotExist();
error UpperSky__StarTypeNotExists();
error UpperSky__PackTypeNotExists();
error UpperSky__StarTypeSoldOut();
error UpperSky__IncorrectNumStars();

contract UpperSky is ERC721URIStorage, Ownable {

    /// @notice Types
    enum ContractState {   
    INACTIVE,
    ACTIVE
    }

    enum WhitelistState {   
    INACTIVE,
    PHASE1,
    PHASE2
    }

    /// @notice Imported variables
    UpperSkyWhitelist UPPERSKYWHITELIST;

    /// @notice Contract variables
    ContractState s_contractState;
    WhitelistState s_whitelistState;

    /// @notice NFTS variables
    uint256 private s_tokenCounter;
    uint256 private s_superSmallTokenCounter;
    uint256 private s_smallTokenCounter;
    uint256 private s_mediumTokenCounter;
    uint256 private s_bigTokenCounter;
    uint256 private s_specialTokenCounter;
    uint256 private s_uriAddedCounter;
    uint256 private s_DISCOUNT_FACTOR;
    uint256 private immutable i_threshold0;
    uint256 private immutable i_threshold1;
    uint256 private immutable i_threshold2;
    uint256 private immutable i_threshold3;
    uint256 private s_mintFee_type0;
    uint256 private s_mintFee_type1;
    uint256 private s_mintFee_type2;
    uint256 private s_mintFee_type3;
    uint256 private s_mintFee_type4;
    uint256 private immutable i_MAX_STARS;

    /// @notice Events
    event NftMinted(uint256 tokenId, address owner);
    event PackMinted(uint256 packType, uint256 numStars);
    event FundsWithdrew(uint256 amount, address owner);

    /// @notice Mappings
    mapping(address => bool) private isAdmin;
    mapping(uint256 => string) private s_starTokenUris;

    /// @notice Modifiers
    modifier onlyAdmin {
        require(msg.sender == owner() || isAdmin[msg.sender]);
        _;
    }

    modifier onlyActive {
        require(s_contractState == ContractState.ACTIVE);
        _;
    }

    constructor(address _upperSkyWhitelist, uint256 threshold0, uint256 threshold1, uint256 threshold2, uint256 threshold3, uint256 mintFee_type0, uint256 mintFee_type1, uint256 mintFee_type2, uint256 mintFee_type3, uint256 mintFee_type4) ERC721("UpperSky by Quarktium", "USQ") {
        /**
        * Initialization of Contract Variables
        */
        s_contractState = ContractState.INACTIVE;
        s_whitelistState = WhitelistState.INACTIVE;

        /**
        * Initialization of Imported Variables
        */
        UPPERSKYWHITELIST = UpperSkyWhitelist(_upperSkyWhitelist);

        /**
        * Initialization of NFTs variables
        */
        s_tokenCounter = 0;
        s_uriAddedCounter = 0;
        s_superSmallTokenCounter = 0;
        s_smallTokenCounter = 0;
        s_mediumTokenCounter = 0;
        s_bigTokenCounter = 0;
        s_specialTokenCounter = 0;
        s_DISCOUNT_FACTOR = 10;
        i_MAX_STARS = 8912;
        i_threshold0 = threshold0;
        i_threshold1 = threshold1;
        i_threshold2 = threshold2;
        i_threshold3 = threshold3;
        s_mintFee_type0 = mintFee_type0;
        s_mintFee_type1 = mintFee_type1;
        s_mintFee_type2 = mintFee_type2;
        s_mintFee_type3 = mintFee_type3;
        s_mintFee_type4 = mintFee_type4;
    }

    //////////////////////
    //  Main Functions // 
    /////////////////////

    /**
    * @notice Function used to reserve a star for admins to specified address
    * @dev Only callable by Admins
    * - At the end, checks if token is lower or equal to 8912 to increase counter
    * if it is greater than 8912 means that you are minting a customed star (not avaliable for public)
    */
    function reserveStar(uint256 tokenId, address recipient) public onlyAdmin {
        if(_exists(tokenId)) {
            revert UpperSky__NFTAlreadyMinted();
        }

        if (tokenId < i_threshold0){ 
            s_superSmallTokenCounter += 1;
        } else if (tokenId < i_threshold1 && tokenId >= i_threshold0) {
            s_smallTokenCounter += 1;
        } else if (tokenId < i_threshold2 && tokenId >= i_threshold1) {
            s_mediumTokenCounter += 1;
        } else if (tokenId < i_threshold3 && tokenId >= i_threshold2) {
            s_bigTokenCounter += 1;
        } else if (tokenId < i_MAX_STARS && tokenId >= i_threshold3){
            s_specialTokenCounter += 1;
        }
        
        if (tokenId < i_MAX_STARS) {
        s_tokenCounter += 1; 
        }
        mintNFT(tokenId, recipient);
    }

    /**
    @notice Basic function for minting NFTs
    @dev This is an internal function called by other functions inside the contract
    */
    function mintNFT(uint256 tokenId, address recipient) internal {
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, s_starTokenUris[tokenId]);
        emit NftMinted(tokenId, recipient);
    }

    /**
    * @notice Function to mint a specific NFT type but not choosing specific Star Id
    * @dev 
    * - Check if Whitelist is Active, if so -> check that user is Whitelisted
    * - Check that contract is ACTIVE
    * - Check that sold out is not reached
    * - Call internal mintNFT function
    */
    function mintTypeStar(uint256 starType) onlyActive public payable {
        uint256 tokenId;
        if (starType == 0) {
            if (s_superSmallTokenCounter >= i_threshold0) {
            revert UpperSky__StarTypeSoldOut();
            }
            tokenId = s_superSmallTokenCounter;
        } else if (starType == 1) {
            if (s_smallTokenCounter >= i_threshold1 - i_threshold0) {
            revert UpperSky__StarTypeSoldOut();
            }
            tokenId = s_smallTokenCounter + i_threshold0;
        } else if (starType == 2) {
            if (s_mediumTokenCounter >= i_threshold2 - i_threshold1) {
            revert UpperSky__StarTypeSoldOut();
            }
            tokenId = s_mediumTokenCounter + i_threshold1;
        } else if (starType == 3) {
            if (s_bigTokenCounter >= i_threshold3 - i_threshold2) {
            revert UpperSky__StarTypeSoldOut();
            }
            tokenId = s_bigTokenCounter + i_threshold2;
        } else if (starType == 4) {
            if (s_specialTokenCounter >= i_MAX_STARS - i_threshold3) {
                revert UpperSky__StarTypeSoldOut();
            }
            tokenId = s_specialTokenCounter + i_threshold3;
        } else {
            revert UpperSky__StarTypeNotExists();
        }

        mintStar(tokenId, false);
    }

    /**
    * @notice Function to mint a UpperSky by choosing tokenId
    * @dev 
    * - Check if Whitelist is Active, if so -> check that user is Whitelisted (handleWhitelist)
    * - Check that contract is ACTIVE
    * - Check that NFT Id exists
    * - Check that sold out is not reached
    * - Check star price and its correspoding price
    * - Check that payment amount is > mintFee
    * - Update variables
    * - Call internal mintNFT function
    */
    function mintStar(uint256 tokenId, bool direct) onlyActive public payable {
        handleWhitelist(direct);

        if (tokenId >= i_MAX_STARS) {
            revert UpperSky__NFTIndexDoesNotExist();
        }
        if (s_tokenCounter >= i_MAX_STARS) {
            revert UpperSky__CollectionSoldOut();
        }
        if(_exists(tokenId)) {
            revert UpperSky__NFTAlreadyMinted();
        }

        if (tokenId < i_threshold0){ 
            if (msg.value < s_mintFee_type0) {
                revert UpperSky__NotEnoughMoneySent();
            }
            s_superSmallTokenCounter += 1;
        } else if (tokenId < i_threshold1 && tokenId >= i_threshold0) {
            if (msg.value < s_mintFee_type1) {
                revert UpperSky__NotEnoughMoneySent();
            }
            s_smallTokenCounter += 1;
        } else if (tokenId < i_threshold2 && tokenId >= i_threshold1) {
            if (msg.value < s_mintFee_type2) {
                revert UpperSky__NotEnoughMoneySent();
            }
            s_mediumTokenCounter += 1;
        } else if (tokenId < i_threshold3 && tokenId >= i_threshold2) {
            if (msg.value < s_mintFee_type3) {
                revert UpperSky__NotEnoughMoneySent();
            }
            s_bigTokenCounter += 1;
        } else {
            if (msg.value < s_mintFee_type4) {
                revert UpperSky__NotEnoughMoneySent();
            }
            s_specialTokenCounter += 1;
        }
        s_tokenCounter += 1; 
        mintNFT(tokenId, msg.sender);
    }

    /**
    * @notice Function used to buy a pack of stars and get a discount
    * @param packType is used to select Star type (1:super-small, 2:small, 3:medium, 4:big, 5:special)
    * @param numStars indicates de number of stars wanted to be minted
    * @dev 
    * - Check that contract is active
    * - Check that Whitelist is active and user is whitelisted (handleWhitelist)
    * - Check that if amount depending on packType is correctly selected
    * - Check if collection is sold out
    * - Check that payment is correct (applying 25% discount)
    * - Check that there are enough NFT types avaliable
    * - Set corresponding appliedFee and appliedTokenId
    * - Update counters
    * - Call mintFunction
    */
    function mintPack(uint256 packType, uint256 numStars) onlyActive public payable {
        handleWhitelist(false);

        if((packType != 4 || packType != 3) && (numStars < 5 || numStars > 30)){
            revert UpperSky__IncorrectNumStars();
        } else if ((packType == 2) && (numStars < 3 || numStars > 30)){
            revert UpperSky__IncorrectNumStars();
        } else {
            if(numStars < 2 || numStars > 30) {
            revert UpperSky__IncorrectNumStars();
            }
        }

        uint256 appliedFee;
        uint256 appliedTokenId;
        uint256 lastFactor = packType * numStars;

        if (s_tokenCounter >= i_MAX_STARS) {
            revert UpperSky__CollectionSoldOut();
        }
        if (packType == 0) { 
            if((s_superSmallTokenCounter + numStars) > i_threshold0) {
                revert UpperSky__StarTypeSoldOut();
            }
            appliedFee = s_mintFee_type0;
            if (msg.value < ((appliedFee - (appliedFee/s_DISCOUNT_FACTOR))*lastFactor)){
            revert UpperSky__NotEnoughMoneySent();
            } 
            appliedTokenId = s_superSmallTokenCounter;
            s_superSmallTokenCounter = s_superSmallTokenCounter + numStars;

        } else if(packType == 1) {
            if((s_smallTokenCounter + numStars) > (i_threshold1 - i_threshold0)) {
                revert UpperSky__StarTypeSoldOut();
            }
            appliedFee = s_mintFee_type1;
            if (msg.value < ((appliedFee - (appliedFee/s_DISCOUNT_FACTOR))*lastFactor)){
            revert UpperSky__NotEnoughMoneySent();
            }
            appliedTokenId = s_smallTokenCounter + i_threshold0;
            s_smallTokenCounter = s_smallTokenCounter + numStars;

        } else if(packType == 2) {
            if((s_mediumTokenCounter + numStars) > (i_threshold2 - i_threshold1)) {
                revert UpperSky__StarTypeSoldOut();
            }
            appliedFee = s_mintFee_type2;
            if (msg.value < ((appliedFee - (appliedFee/s_DISCOUNT_FACTOR))*lastFactor)){
            revert UpperSky__NotEnoughMoneySent();
            }
            appliedTokenId = s_mediumTokenCounter +i_threshold1;
            s_mediumTokenCounter = s_mediumTokenCounter + numStars;

        } else if(packType == 3) {
            if((s_bigTokenCounter + numStars) > (i_threshold3 - i_threshold2)) {
                revert UpperSky__StarTypeSoldOut();
            }
            appliedFee = s_mintFee_type3;
            if (msg.value < ((appliedFee - (appliedFee/s_DISCOUNT_FACTOR))*lastFactor)){
            revert UpperSky__NotEnoughMoneySent();
            }
            appliedTokenId = s_bigTokenCounter + i_threshold2;
            s_bigTokenCounter = s_bigTokenCounter + numStars;

        } else if(packType == 4) {
            if((s_specialTokenCounter + numStars) > (i_MAX_STARS - i_threshold3)) {
                revert UpperSky__StarTypeSoldOut();
            }
            appliedFee = s_mintFee_type4;
            if (msg.value < ((appliedFee - (appliedFee/s_DISCOUNT_FACTOR))*lastFactor)){
            revert UpperSky__NotEnoughMoneySent();
            }
            appliedTokenId = s_specialTokenCounter + i_threshold3;
            s_specialTokenCounter = s_specialTokenCounter + numStars;

        } else {
            revert UpperSky__PackTypeNotExists();
        }

        for(uint256 i=0; i < numStars; i++) {
            s_tokenCounter += 1;
            appliedTokenId += 1;
            mintNFT(appliedTokenId - 1, msg.sender);
        }
        emit PackMinted(packType, numStars);
    }

    /**
    * @notice Function used handle Whitelist permisions depending on each phase and type of whitelist
    */
    function handleWhitelist(bool direct) internal {
        if (direct == true) {
            if (s_whitelistState != WhitelistState.INACTIVE) {
                require(UPPERSKYWHITELIST.isPremiumWhitelisted(msg.sender) == true); 
            }
        } else {
            if (s_whitelistState == WhitelistState.PHASE1) {
                require(UPPERSKYWHITELIST.isSimpleWhitelisted_phase1(msg.sender) == true);
            } else if (s_whitelistState == WhitelistState.PHASE2) {
                require(UPPERSKYWHITELIST.isSimpleWhitelisted_phase2(msg.sender) == true);
            }
        } 
    }

    ////////////////////////////////////
    //  Contract Management Functions // 
    ///////////////////////////////////

    /**
    * @notice Function used to load token Uris
    * @param uris String that contains uris (noramlly the max is 200 calling this function
    * several times is needed)
    * @param first_index Used to indicate the index
    * @dev 
    * - Only callable by Admins 
    * - Check that param first_index is s_uriAddedCounter + 1 to assure that any token is without uri
    */
    function addUris(string[] memory uris, uint256 first_index) public onlyAdmin {
        if(s_uriAddedCounter != 0) {
        require(first_index == (s_uriAddedCounter));
        }
        for (uint256 i = 0; i < uris.length; i++){
            s_starTokenUris[first_index + i] = uris[i];
            s_uriAddedCounter += 1;
        }
    }

    /**
    * @notice Function used to add contract Admins
    * @dev Only callable by the Owner 
    */
    function addAdmin(address admin) public onlyOwner {
        isAdmin[admin] = true;
    }

    /**
    * @notice Function to withdraw funds
    * @dev 
    * - Only owner can withdraw funds
    * - Revert if transaction failed
    */
    function withdraw() public onlyAdmin {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) { 
            revert UpperSky__TransferFailed();
        }
        emit FundsWithdrew(amount, msg.sender);
    }

    /**
    * @notice Change contract state from Active to Inactive and viceversa
    * @dev Only callable by the Owner or an admin
    */
    function flipContractState() public onlyAdmin {
        if (s_contractState == ContractState.ACTIVE) {
        s_contractState = ContractState.INACTIVE;
        }else {
        s_contractState = ContractState.ACTIVE;
        }
    }

    /**
    * @notice Change whitelist state from Active to Inactive and viceversa
    * @dev Only callable by the Owner or an admin
    * @param state should be:
    *           0: INACTIVE
    *           1: PHASE1
    *           2: PHASE2
    */
    function flipWhitelistState(uint256 state) public onlyAdmin {
        if (state == 0) {
            s_whitelistState = WhitelistState.INACTIVE;
        } else if (state == 1) {
            s_whitelistState = WhitelistState.PHASE1;
        } else if (state == 2) {
            s_whitelistState = WhitelistState.PHASE2;
        }
    }


    //////////////////////////////////////////
    // MintFeeFunctions and DiscountFactor // 
    ////////////////////////////////////////
    
    /**
    * @notice Function used to change mintFee
    */
    function changeMintFee(uint256 newFee, uint256 typeStar) public onlyAdmin {
        if (typeStar == 0){
            s_mintFee_type0 = newFee;
        } else if(typeStar == 1){
            s_mintFee_type1 = newFee;
        } else if(typeStar == 2) {
            s_mintFee_type2 = newFee;
        } else if(typeStar == 3) {
            s_mintFee_type3 = newFee;
        } else if(typeStar == 4) {
            s_mintFee_type4 = newFee;
        } else {
            revert UpperSky__StarTypeNotExists();
        }
    }

    /**
    * @notice Function used to change discountFactor
    */
    function changeDiscountFactor(uint256 newDiscountFactor) public onlyAdmin {
        s_DISCOUNT_FACTOR = newDiscountFactor;
    }

     //////////////////////
    //  Getter Functions // 
    /////////////////////
    
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getUriAddedCounter() public view returns(uint256) {
        return s_uriAddedCounter;
    }

    function getSuperSmallTokenCounter() public view returns(uint256) {
        return s_superSmallTokenCounter;
    }

    function getSmallTokenCounter() public view returns(uint256) {
        return s_smallTokenCounter;
    }

    function getMediumTokenCounter() public view returns(uint256) {
        return s_mediumTokenCounter;
    }

    function getBigTokenCounter() public view returns(uint256) {
        return s_bigTokenCounter;
    }

    function getSpecialTokenCounter() public view returns(uint256) {
        return s_specialTokenCounter;
    }

    function getDiscountFactor() public view returns(uint256) {
        return s_DISCOUNT_FACTOR;
    }

    function getMintFee_type0() public view returns (uint256) {
        return s_mintFee_type0;
    }

    function getMintFee_type1() public view returns (uint256) {
        return s_mintFee_type1;
    }

    function getMintFee_type2() public view returns (uint256) {
        return s_mintFee_type2;
    }

    function getMintFee_type3() public view returns (uint256) {
        return s_mintFee_type3;
    }

    function getMintFee_type4() public view returns (uint256) {
        return s_mintFee_type4;
    }

    function getThreshold0() public view returns(uint256){
        return i_threshold0;
    }

    function getThreshold1() public view returns(uint256){
        return i_threshold1;
    }

    function getThreshold2() public view returns(uint256){
        return i_threshold2;
    }

    function getThreshold3() public view returns(uint256){
        return i_threshold3;
    }

    function getStarTokenUris(uint256 index) public view returns (string memory) {
        return s_starTokenUris[index];
    }
    
    function getMaxSupply() public view returns (uint256) {
        return i_MAX_STARS;
    }

    function getContractState() public view returns (ContractState) {
        return s_contractState;
    }

    function getWhitelistState() public view returns (WhitelistState) {
        return s_whitelistState;
    }

    function getisAdmin(address user) public view returns(bool) {
        return isAdmin[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

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
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error UpperSkyPremiumWL__TransferFailed();
error UpperSkyPremiumWL__NotEnoughMoneySent();

contract UpperSkyPremiumWLNFT is ERC721, Ownable {

    /// @notice Types
    enum ContractState {   
    ACTIVE,
    INACTIVE
    }

    /// @notice Contract variables
    ContractState private s_contractState;

    /// @notice NFT variables
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;
    uint256 private s_mintFee;

    /// @notice Events
    event NftMinted(address user, uint256 tokenId);
    event ContractStateFlipped(ContractState contractState);
    event FundsWithdrew(uint256 amount, address owner);

    /// @notice Mappings
    mapping(address => bool) private isAdmin;

    /// @notice Modifiers
    modifier onlyAdmin {
        require(msg.sender == owner() || isAdmin[msg.sender], "User not owner or admin.");
        _;
    }

    modifier onlyActive {
        require(s_contractState == ContractState.ACTIVE, "Contract INACTIVE.");
        _;
    }

    constructor() ERC721("UpperSkyPremiumWL", "MSPW") {
        s_contractState = ContractState.INACTIVE;
        s_tokenCounter = 0;
        s_mintFee = 50000000000000000;
    }

    ////////////////////////
    //  Main Functions // 
    //////////////////////

    /**
    * @notice Function used to reserve a NFT for admins to specified address
    * @dev Only callable by Admins
    */
    function reserveNFT(address recipient) public onlyAdmin {
        uint256 tokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(recipient, tokenId);
        emit NftMinted(recipient, tokenId);
    }

    /// @notice Function used to mintNFT
    function mintNFT() onlyActive public payable {
        if (msg.value < s_mintFee) {
            revert UpperSkyPremiumWL__NotEnoughMoneySent();
        }

        uint256 tokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(msg.sender, tokenId);
        emit NftMinted(msg.sender, tokenId);
    }

    /// @notice Function used to return TokenUri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    ////////////////////////////////////
    //  Contract Management Functions // 
    ///////////////////////////////////

    /**
    * @notice Change contract state from Active to Inactive and viceversa
    * @dev Only callable by the Owner or an admin
    */
    function flipContractState() public onlyAdmin {
        if (s_contractState == ContractState.ACTIVE) {
        s_contractState = ContractState.INACTIVE;
        }else {
        s_contractState = ContractState.ACTIVE;
        }
        emit ContractStateFlipped(s_contractState);
    }

    /// @notice Function used to changeMintFee
    function changeMintFee(uint256 newFee) public onlyAdmin {
        s_mintFee = newFee;
    }

    /**
    * @notice Function used to add contract Admins
    * @dev Only callable by the Owner 
    */
    function addAdmin(address admin) public onlyOwner {
        isAdmin[admin] = true;
    }

    /**
    * @notice Function to withdraw funds
    * @dev 
    * - Only owner can withdraw funds
    * - Revert if transaction failed
    */
    function withdraw() public onlyAdmin {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) { 
            revert UpperSkyPremiumWL__TransferFailed();
        }
        emit FundsWithdrew(amount, msg.sender);
    }

    ////////////////////////
    //  Getter Functions // 
    //////////////////////

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintFee() public view returns (uint256) {
        return s_mintFee;
    }

    function getContractState() public view returns (ContractState) {
        return s_contractState;
    }

    function getisAdmin(address user) public view returns(bool) {
        return isAdmin[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error UpperSkyWL__TransferFailed();
error UpperSkyWL__NotEnoughMoneySent();

contract UpperSkyWLNFT is ERC721, Ownable {

    /// @notice Types
    enum ContractState {   
    ACTIVE,
    INACTIVE
    }

    /// @notice Contract variables
    ContractState private s_contractState;

    /// @notice NFT variables
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;
    uint256 private s_mintFee;

    /// @notice Events
    event NftMinted(address user, uint256 tokenId);
    event ContractStateFlipped(ContractState contractState);
    event FundsWithdrew(uint256 amount, address owner);

    /// @notice Mappings
    mapping(address => bool) private isAdmin;

    /// @notice Modifiers
    modifier onlyAdmin {
        require(msg.sender == owner() || isAdmin[msg.sender], "User not owner or admin.");
        _;
    }

    modifier onlyActive {
        require(s_contractState == ContractState.ACTIVE, "Contract INACTIVE.");
        _;
    }

    constructor() ERC721("UpperSkyWL", "MSW") {
        s_contractState = ContractState.INACTIVE;
        s_tokenCounter = 0;
        s_mintFee = 10000000000000000;
    }

    ////////////////////////
    //  Main Functions // 
    //////////////////////

    /**
    * @notice Function used to reserve a NFT for admins to specified address
    * @dev Only callable by Admins
    */
    function reserveNFT(address recipient) public onlyAdmin {
        uint256 tokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(recipient, tokenId);
        emit NftMinted(recipient, tokenId);
    }

    /// @notice Function used to mintNFT
    function mintNFT() onlyActive public payable {
        if (msg.value < s_mintFee) {
            revert UpperSkyWL__NotEnoughMoneySent();
        }

        uint256 tokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(msg.sender, tokenId);
        emit NftMinted(msg.sender, tokenId);
    }

    /// @notice Function used to return TokenUri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    ////////////////////////////////////
    //  Contract Management Functions // 
    ///////////////////////////////////

    /**
    * @notice Change contract state from Active to Inactive and viceversa
    * @dev Only callable by the Owner or an admin
    */
    function flipContractState() public onlyAdmin {
        if (s_contractState == ContractState.ACTIVE) {
        s_contractState = ContractState.INACTIVE;
        }else {
        s_contractState = ContractState.ACTIVE;
        }
        emit ContractStateFlipped(s_contractState);
    }

    /// @notice Function used to changeMintFee
    function changeMintFee(uint256 newFee) public onlyAdmin {
        s_mintFee = newFee;
    }

    /**
    * @notice Function used to add contract Admins
    * @dev Only callable by the Owner 
    */
    function addAdmin(address admin) public onlyOwner {
        isAdmin[admin] = true;
    }

    /**
    * @notice Function to withdraw funds
    * @dev 
    * - Only owner can withdraw funds
    * - Revert if transaction failed
    */
    function withdraw() public onlyAdmin {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) { 
            revert UpperSkyWL__TransferFailed();
        }
        emit FundsWithdrew(amount, msg.sender);
    }

    ////////////////////////
    //  Getter Functions // 
    //////////////////////

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintFee() public view returns (uint256) {
        return s_mintFee;
    }

    function getContractState() public view returns (ContractState) {
        return s_contractState;
    }

    function getisAdmin(address user) public view returns(bool) {
        return isAdmin[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; 
import "./UpperSkyPremiumWLNFT.sol";
import "./UpperSkyWLNFT.sol";

contract UpperSkyWhitelist is Ownable{

    /// @notice ERC721 Tokens
    UpperSkyPremiumWLNFT PREMIUM_WHITELIST_NFT;
    UpperSkyWLNFT WHITELIST_NFT;
    IERC721Enumerable COLABO_NFT;

    /// @notice Contract variables
    address[] private colaboProjects;

    /// @notice Mappings
    mapping(address => bool) private isAdmin;
    mapping(address => bool) public isWhitelisted;

    /// @notice Contract variables
    event UserIsPremiumWL(address user);
    event UserIsSimpleWL(address user);
    event ColaboProjectAdded(address colaboProject);
    event ColaboProjectDeleted(address colaboProjects);
    
    /// @notice Modifiers
    modifier onlyAdmin {
        require(msg.sender == owner() || isAdmin[msg.sender], "User not owner or admin.");
        _;
    }

    constructor(address _upperSkyPremiumWLNFT, address _upperSkyWLNFT) {
        /**
        * Initialization of ERC721 Variables
        */
        PREMIUM_WHITELIST_NFT = UpperSkyPremiumWLNFT(_upperSkyPremiumWLNFT);
        WHITELIST_NFT = UpperSkyWLNFT(_upperSkyWLNFT);
    }

    //////////////////////
    //  Main Functions // 
    ////////////////////

    /**
    * @notice Function used to check if user is whitelisted on phase1
    * @dev User can be whitelisted if:
    *       1: Owns a PremiumWhitelistNFT
    *       2: Owns a normal WhitelistNFT
    */
    function isSimpleWhitelisted_phase1(address user) external returns(bool) {
        isColaboWhitelisted(user);
        require(PREMIUM_WHITELIST_NFT.balanceOf(user) > 0 || WHITELIST_NFT.balanceOf(user) > 0, "User is not whitelisted.");
        emit UserIsSimpleWL(user);
        return true;
    }

    /**
    * @notice Function used to check if user is whitelisted on phase2
    * @dev User can be whitelisted if:
    *       1: Owns a PremiumWhitelistNFT
    *       2: Owns a normal WhitelistNFT
    *       3: Owns a colabo project NFT
    *       4: Was manually whitelisted
    */
    function isSimpleWhitelisted_phase2(address user) external returns(bool) {
        isColaboWhitelisted(user);
        require(PREMIUM_WHITELIST_NFT.balanceOf(user) > 0 || WHITELIST_NFT.balanceOf(user) > 0 || isWhitelisted[user], "User is not whitelisted.");
        emit UserIsSimpleWL(user);
        return true;
    }

    /**
    * @notice Function used to check if user is Premium Whitelisted
    * @dev User can be whitelisted if:
    *       1: Owns a PremiumWhitelistNFT
    */
    function isPremiumWhitelisted(address user) external returns(bool) {
        require(PREMIUM_WHITELIST_NFT.balanceOf(user) > 0, "User is not whitelisted.");
        emit UserIsPremiumWL(user);
        return true;
    }

    /**
    * @notice Function used to check if user owns an NFT from a collection that is collaborating
    * @dev User can be whitelisted if:
    *       1: Owns a NFT from a collection that is collaborating
    */
    function isColaboWhitelisted(address user) internal {
        for( uint256 i = 0; i < colaboProjects.length; i++) {
            COLABO_NFT = IERC721Enumerable(colaboProjects[i]);
            if (COLABO_NFT.balanceOf(user) > 0) {
                isWhitelisted[user] = true;
            }
        }
    }

    /**
    * @notice Function used to add contract addresses of projects that are colaborating
    * @dev Only callable by Admins
    */
    function addColabo(address colaboProject) public onlyAdmin {
        colaboProjects.push(colaboProject);
        emit ColaboProjectAdded(colaboProject);
    }

    /**
    * @notice Function used to add contract addresses of projects that are colaborating using array
    * @dev Only callable by Admins
    */
    function addColabos(address[] memory addresses) public onlyAdmin {
        for (uint256 i = 0; i < addresses.length; ++i) {
			colaboProjects.push(addresses[i]);
            emit ColaboProjectAdded(addresses[i]);
        }
    }

    /**
    * @notice Function used to deletes contract addresses of projects that are colaborating
    * @dev Only callable by the Owner 
    */
    function deleteColabo(uint256 index) public onlyAdmin {
        address colaboProject = colaboProjects[index];
        require(index < colaboProjects.length, "Index out of bounds");
        for (uint i = index; i < colaboProjects.length - 1; i++){
            colaboProjects[i] = colaboProjects[i+1];
        }
        delete colaboProjects[colaboProjects.length-1];
        emit ColaboProjectDeleted(colaboProject);
    }

    /**
    * @notice Function used to "manually" add addresses to whitelist
    * @dev Only callable by Admins
    */
    function addUserToWhitelist(address[] memory wallets) public onlyAdmin {
		for (uint256 i = 0; i < wallets.length; ++i) {
			isWhitelisted[wallets[i]] = true;
        }
	}

    ////////////////////////////////////
    //  Contract Management Functions // 
    ///////////////////////////////////

    /**
    * @notice Function used to add contract Admins
    * @dev Only callable by the Owner 
    */
    function addAdmin(address admin) public onlyOwner {
        isAdmin[admin] = true;
    }

    ///////////////////////
    //  Getter Functions // 
    //////////////////////

    function getColaboProjects() public view returns(address[] memory) {
        return colaboProjects;
    }

    function getisAdmin(address user) public view returns(bool) {
        return isAdmin[user];
    }

    function getisWhitelisted(address user) public view returns(bool) {
        return isWhitelisted[user];
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