//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Mortgage/TokenInfo.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MarketEvents.sol";
import "./Verification.sol";
import "./ILazymint.sol";
import "./IVaultRewards.sol";
import "./IControl.sol";
//import "../Mortgage/IMortgageControl.sol";

/// @title A contract for selling single and batched NFTs
/// @notice This contract can be used for auctioning any NFTs, and accepts any ERC20 token as payment
contract NFTMarket is MarketEvents, verification, AccessControl, ReentrancyGuard {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    struct Localvars {
        string _uri;
        address _nftContractAddress;
        uint256 _tokenId;
        address _erc20Token;
        uint256 _buyNowPrice;
        address[] _feeRecipients;
        uint32[] _feePercentages;
        address _nftSeller;
        uint256 _amount;
        address _nftHighestBidder;
        bool lazymint;
        address feeVaultAddress;
        address lendersVault;
    }
    struct LocalMint{
        bool _status;
        uint256 pan;
        uint256 rewards; 
        uint256 lenders;
        uint256 sell;
        uint256 value;
        uint amount;
        uint256 _nftId;
    }

    ///@notice Each sell is unique to each NFT (contract + id pairing).
    ///@param ERC20Token The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
    struct Sells {
        uint256 buyNowPrice;
        address nftHighestBidder;
        address nftSeller;
        address ERC20Token;
        address[] feeRecipients;
        uint32[] feePercentages;
    }
     ///@notice Map each sell with the token ID
    mapping(address => mapping(uint256 => Sells)) public nftContractAuctions;

    mapping(address => bool) public mortgage;
    ///@notice If transfer fail save to withdraw later
    uint256 tokenToContract;

     //Change to mainnet multisig-wallet
    address public walletPanoram; 

    ///@notice Default values market fee
    uint256 public feeMarket = 75; //Equal 0.75%
    uint256 private feeLenders= 1800; //Equals 18%
    uint256 private feeRewards = 2200; //Equals 22%
    uint256 private feePanoram = 6000; //Equals 60%
    address public control;
    TokenInfo public tokenInfo;
    //address public mControl;
    bool paused = false;

    /*///////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier isPaused(){
        if(paused){
            revert("contract paused");
        }
        _;
    }

    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        if(
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller ==
                msg.sender){
            revert ("Initiated by the owner");
        }

        if (
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
            address(0)
        ) {
            if(
                msg.sender != IERC721(_nftContractAddress).ownerOf(_tokenId)){
                 revert ("Sender doesn't own NFT");
            }
        }
        _;
    }

    modifier onlyMortgage(){
        if(!mortgage[msg.sender]){
            revert("mortgage only");
        }
        _;
    }

    modifier validToken(address _token){
        if(!tokenInfo.getToken(_token)){
            revert("Token not support");
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              END MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _tokenInfo,address _control, address token, address _feeVaultAddress, address _lendersRewards, address _walletPanoram) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        tokenInfo = TokenInfo(_tokenInfo);
        walletPanoram = _walletPanoram;
        if(_control != address(0) && token != address(0)){
        if(!tokenInfo.getToken(token)){
            revert("Token not support");
        }
        control = _control;
        //mControl = _mControl;
        permissions(token,_lendersRewards,_feeVaultAddress);
        }else{
            revert ("address Zero");
        }
    } 

    /*///////////////////////////////////////////////////////////////
                    AUCTION/SELL CHECK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    ///@dev If the buy now price is set by the seller, check that the highest bid meets that price.
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId, uint256 amount)
        internal
        view
        returns (bool)
    {
        uint256 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        return
            amount >= buyNowPrice;
    }

    ///@dev Payment is accepted in the following scenarios:
    ///@dev (1) Sale already created - can accept Specified Token
    ///@dev (2) Sale not created - only Token accepted
    ///@dev (3) Cannot make a zero bid (Token amount)
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _ERC20Token,
        uint256 _tokenAmount
    ) internal view returns (bool _condition) {
            address ERC20Address = nftContractAuctions[
                _nftContractAddress][_tokenId].ERC20Token;
            if (ERC20Address == address(0)) {
                return false;
            }else if(msg.value == 0 &&
                    ERC20Address == _ERC20Token &&
                    _tokenAmount > 0){
                return true;
            }
    }

    /*///////////////////////////////////////////////////////////////
                                     END
                            AUCTION CHECK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                      TRANSFER NFTS TO CONTRACT
    //////////////////////////////////////////////////////////////*/

    function _transferNftToMarketContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        /* address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller; */
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
            IERC721(_nftContractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            if(
                IERC721(_nftContractAddress).ownerOf(_tokenId) != address(this)){
                revert ("nft transfer failed");
            }
        } else {
            if(
                IERC721(_nftContractAddress).ownerOf(_tokenId) != address(this)){
                revert ("Seller doesn't own NFT");
           }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                END
                      TRANSFER NFTS TO CONTRACT
    //////////////////////////////////////////////////////////////*/


    /*///////////////////////////////////////////////////////////////
                              SALES
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows for a standard sale mechanism.
    ///@dev For sale the min price must be 0
    ///@dev _isABidMade check if buyNowPrice is meet and conclude sale, otherwise reverse the early bid
    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        address _nftSeller,
        address[] calldata _feeRecipients,
        uint32[] calldata _feePercentages
    )
        external
        isPaused
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        validToken(_erc20Token)
        priceGreaterThanZero(_buyNowPrice)
    {
        Localvars memory vars;
       
        vars._nftContractAddress = _nftContractAddress;
        vars._tokenId = _tokenId;
        vars._erc20Token = _erc20Token;
        vars._buyNowPrice = _buyNowPrice;
        vars._feeRecipients = _feeRecipients;
        vars._feePercentages = _feePercentages;
        vars._nftSeller = _nftSeller;
        if (vars._erc20Token == address(0)) {
            revert("address zero");
        }

        nftContractAuctions[vars._nftContractAddress][vars._tokenId]
            .nftSeller = vars._nftSeller;
        nftContractAuctions[vars._nftContractAddress][vars._tokenId]
                .ERC20Token = vars._erc20Token;
        nftContractAuctions[vars._nftContractAddress][vars._tokenId]
            .feeRecipients = vars._feeRecipients;
        nftContractAuctions[vars._nftContractAddress][vars._tokenId]
            .feePercentages = vars._feePercentages;
        nftContractAuctions[vars._nftContractAddress][vars._tokenId]
            .buyNowPrice = vars._buyNowPrice;

        vars._uri = metadata(vars._nftContractAddress, vars._tokenId);

        _transferNftToMarketContract(vars._nftContractAddress, vars._tokenId);

        emit SaleCreated(
            vars._nftContractAddress,
            vars._tokenId,
            vars._nftSeller,
            vars._erc20Token,
           vars. _buyNowPrice,
           vars. _feeRecipients,
            vars._feePercentages
        );
        
        
        
    }

    function getSale(address collection, uint256 id) public view returns
    (uint256 _buyNowPrice,address _nftHighestBidder,address _nftSeller,address _ERC20Token,
    address[] memory _feeRecipients,uint32[] memory _feePercentages){
        _buyNowPrice = nftContractAuctions[collection][id].buyNowPrice;
        _nftHighestBidder = nftContractAuctions[collection][id].nftHighestBidder;
        _nftSeller = nftContractAuctions[collection][id].nftSeller;
        _ERC20Token = nftContractAuctions[collection][id].ERC20Token;
        _feeRecipients = nftContractAuctions[collection][id].feeRecipients;
        _feePercentages = nftContractAuctions[collection][id].feePercentages;
    }

    function getSalePrice(address collection, uint256 id) public view returns
    (uint256 _buyNowPrice){
        _buyNowPrice = nftContractAuctions[collection][id].buyNowPrice;
    }

    /*///////////////////////////////////////////////////////////////
                              END  SALES
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                              BID FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Buy NFT with ERC20 Token specified by the NFT seller.
    ///@notice Additionally, a buyer can pay the asking price to conclude a sale of an NFT.
    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount,
        uint256 _feeAmount,
        address _newOwner
    ) external isPaused validToken(_erc20Token) nonReentrant {
        uint256 pan;
        uint256 rewards;
        uint256 lenders;
        Localvars memory vars;
        vars._nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        if(msg.sender == vars._nftSeller){
            revert ("cannot buy your NFT");
        }
        if (_erc20Token != address(0)) {
            if(!IERC20(_erc20Token).transferFrom(msg.sender,address(this),_tokenAmount )){
                    revert("fail transfer");
                }
        }
        if(
            !_isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            )){
            revert("Buy to be in specified ERC20/BNB");
        }
        (pan, rewards, lenders) = calcFees(_feeAmount);
        vars._amount =_tokenAmount - _feeAmount;
        
        ///@dev Transfer buy fees to the vault
        if(!IERC20(_erc20Token).transfer(walletPanoram, pan)){
            revert("fail transfer");
        }
        (,vars.lendersVault,vars.feeVaultAddress) = tokenInfo.getVaultInfo(_erc20Token);
        IVaultRewards(vars.feeVaultAddress).deposit(rewards, _erc20Token);
        IVaultRewards(vars.lendersVault).deposit(lenders, _erc20Token);
       if (_isBuyNowPriceMet(_nftContractAddress, _tokenId,vars._amount)) {
            _transferNftAndPaySeller(_nftContractAddress, _tokenId, msg.sender, vars._amount, _newOwner);
       }else{
            revert("amount less than buy now");
       }

        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
    }

    /*///////////////////////////////////////////////////////////////
                        END BID FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                           RESET FUNCTIONS
   //////////////////////////////////////////////////////////////*/

    ///@notice Reset all auction related parameters for an NFT.
    ///@notice This effectively removes an NFT as an item up for auction
    function _resetSell(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        
        nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(
            0
        );
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(
            0
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = address(0);
    }
  

    /*///////////////////////////////////////////////////////////////
                        END RESET FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                    TRANSFER NFT, PAY SELLER & MARKET
    //////////////////////////////////////////////////////////////*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address buyer,
        uint256 amount,
        address _newOwner
    ) internal {
        Localvars memory vars;
        vars._nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        vars._nftHighestBidder = buyer;

        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            vars._nftSeller,
            amount
        );

        IERC721(_nftContractAddress).transferFrom(
                address(this),
                vars._nftHighestBidder,
                _tokenId
            );
        IControl(control).addRegistry(_nftContractAddress, _tokenId, _newOwner, uint32(block.timestamp));
        IControl(control).addQuantity(_newOwner, _nftContractAddress,1);
        IControl(control).removeQuantity(vars._nftSeller, _nftContractAddress,1);
        _resetSell(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            vars._nftSeller,
            vars._nftHighestBidder
        );
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _amount
    ) internal {
        uint256 feesPaid;
        uint256 minusSellFee = _getPortionOfBid(_amount, feeMarket);

        feesPaid = _payoutroyalties(_nftContractAddress, _tokenId, _amount);

        uint256 subtotal = minusSellFee + feesPaid;
        uint256 reward = _amount - subtotal;

        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            reward
        );
        ///@dev Transfer sell fees to the vault
        sendpayment(_nftContractAddress, _tokenId, minusSellFee);
    }

    function sendpayment(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 minusfee
    ) internal {
        uint256 amount = minusfee;
        minusfee = 0;
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(auctionERC20Token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(amount);
        IVaultRewards(feeVaultAddress).deposit(rewards, auctionERC20Token);
        IVaultRewards(lendersVault).deposit(lenders, auctionERC20Token);
        if(!IERC20(auctionERC20Token).transfer(walletPanoram, pan)){
            revert("fail transfer");
        }
    }

    function _payoutroyalties(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 subtotal
    ) internal returns (uint256) {
        uint256 feesPaid = 0;
        uint256 length = nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients
            .length;
        for (uint256 i = 0; i < length; i++) {
            uint256 fee = _getPortionOfBid(
                subtotal,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feeRecipients[i],
                fee
            );
        }
        return feesPaid;
    }

    ///@dev if the call failed, update their credit balance so they the seller can pull it later
    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if(!IERC20(auctionERC20Token).transfer(_recipient, _amount)){
            revert("fail transfer");
        }
    }

    /*///////////////////////////////////////////////////////////////
                      END TRANSFER NFT, PAY SELLER & MARKET
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                         WITHDRAW
    //////////////////////////////////////////////////////////////*/
    ///@dev Only the owner of the NFT can prematurely close the sale or auction.
    function withdrawSell(address _nftContractAddress, uint256 _tokenId)
        external isPaused
    {
        if(nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
                msg.sender){
           revert("cannot cancel an auction");
      }
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this)) {
                IERC721(_nftContractAddress).transferFrom(
                    address(this),
                    nftContractAuctions[_nftContractAddress][_tokenId]
                        .nftSeller,
                    _tokenId
                );
            }
            _resetSell(_nftContractAddress, _tokenId);

        emit AuctionWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                         END  & WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                          UPDATE SELLS
    //////////////////////////////////////////////////////////////*/
    function updateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newBuyNowPrice
    ) external isPaused priceGreaterThanZero(_newBuyNowPrice) {
        if(
            msg.sender !=
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller){
            revert ("Only nft seller");
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
    }
    /*///////////////////////////////////////////////////////////////
                        END UPDATE SELLS
    //////////////////////////////////////////////////////////////*/


     /*///////////////////////////////////////////////////////////////
                        UPDATE FEES
    //////////////////////////////////////////////////////////////*/

    function updateMortgage(address _newMortgage, bool _condition) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            mortgage[_newMortgage] = _condition;
    }


    function updateFeeMarket(uint256 _newfeeMarket) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            feeMarket = _newfeeMarket;
    }

    function updateFeeRewards(uint256 _newfeeRewards) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            feeRewards = _newfeeRewards;
    }

    function updateFeePanoram(uint256 _newfeePanoram) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            feePanoram = _newfeePanoram;
    }

    function updateFeeLenders(uint256 _newfeeLenders) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            feeLenders = _newfeeLenders;
    }

    function updateControl(address _newControl) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
            control = _newControl;
    }

    function updatePaused(bool _Status) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        paused = _Status;
    }

     function updatePanoramWallet(address _newWalletPanoram) public {
          if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
            walletPanoram = _newWalletPanoram;
    }

    function updateTokenInfo(address _tokenInfo) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        tokenInfo = TokenInfo(_tokenInfo);
    }

    function permissions(address _token, address _lenderRwards, address _rewards) public onlydev validToken(_token) {
        IERC20(_token).approve(_lenderRwards, 2**255);
        IERC20(_token).approve(_rewards, 2**255);
    }
    
     /*///////////////////////////////////////////////////////////////
                        END UPDATE FEES
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                        MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function mintingMortgage(address _collection, address _owner, address _user,uint256 _value) public isPaused onlyMortgage nonReentrant returns(uint256 _nftId){
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        _nftId = ILazyNFT(_collection).redeem(_owner, _value);
        addRegistry(_collection, _nftId, _user);
        emit NFTMinted(_collection, _nftId, _owner);
    }

    function mintingPresaleMortgage(address _collection, address _owner, address _user,uint256 _value) public isPaused onlyMortgage nonReentrant returns(uint256 _nftId){
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        _nftId = ILazyNFT(_collection).preSale(_owner, _value);
        addRegistry(_collection, _nftId, _user);
        emit NFTMinted(_collection, _nftId, _owner);
    }

    function minting(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_fee);
        uint256 sell = _value - _fee;
        IVaultRewards(feeVaultAddress).deposit(rewards, _token);
        IVaultRewards(lendersVault).deposit(lenders, _token);
        uint amount = pan + sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
        
        uint256 _nftId = ILazyNFT(_collection).redeem(_owner, sell);
        addRegistry(_collection, _nftId, _owner);

        emit NFTMinted(_collection, _nftId, _owner);
    }
    
    function batchmint(address _collection, address _owner, uint256 _amount ,uint256 _value, 
    uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        LocalMint memory locals;
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (locals.pan, locals.rewards, locals.lenders) = calcFees(_fee);
        locals.sell = _value - _fee;
        locals.value = locals.sell / _amount;
        IVaultRewards(feeVaultAddress).deposit(locals.rewards, _token);
        IVaultRewards(lendersVault).deposit(locals.lenders, _token);
        locals.amount = locals.pan + locals.sell;
        if(!IERC20(_token).transfer(walletPanoram, locals.amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
       
        for(uint256 i=1; i <= _amount;){
            locals._nftId = ILazyNFT(_collection).redeem(_owner, locals.value);
            addRegistry(_collection, locals._nftId, _owner);
            emit NFTMinted(_collection, locals._nftId, _owner);
            unchecked {
             ++i;
            }
        }
    }

    function presaleMint(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) public isPaused 
    validToken(_token) nonReentrant {
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_fee);
        uint256 sell = _value - _fee;
        IVaultRewards(feeVaultAddress).deposit(rewards, _token);
        IVaultRewards(lendersVault).deposit(lenders, _token);
        uint amount = pan + sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
       
        uint256 _nftId = ILazyNFT(_collection).preSale(_owner, sell);
        addRegistry(_collection, _nftId, _owner);

        emit NFTPresale(_collection, _nftId, _owner);
    }

    function presaleMintbatch(address _collection, address _owner, uint256 _amount ,uint256 _value, 
    uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        Localvars memory vars;
        LocalMint memory locals;
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        (,vars.lendersVault,vars.feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (locals.pan, locals.rewards, locals.lenders) = calcFees(_fee);
        locals.sell = _value - _fee;
        IVaultRewards(vars.feeVaultAddress).deposit(locals.rewards, _token);
        IVaultRewards(vars.lendersVault).deposit(locals.lenders, _token);
        uint amount = locals.pan + locals.sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
        for(uint256 i=1; i <= _amount;){
            uint256 _nftId = ILazyNFT(_collection).preSale(_owner, locals.sell);
            addRegistry(_collection, _nftId, _owner);
            emit NFTPresale(_collection, _nftId, _owner);
            unchecked {
             ++i;
            }
        }
    }

    function calcFees(uint256 _fee) internal view returns(uint256 panoram, uint256 rewards, uint256 lenders){
        rewards = _getPortionOfBid(_fee, feeRewards);
        panoram = _getPortionOfBid(_fee, feePanoram);
        lenders =   _getPortionOfBid(_fee, feeLenders);
        return (panoram,rewards, lenders);
    }

    function addRegistry(address _collection, uint256 _nftId, address _owner) internal {
        IControl(control).addCounter();
        IControl(control).addRegistry(_collection, _nftId, _owner, uint32(block.timestamp));
        IControl(control).addQuantity(_owner, _collection,1);
        IControl(control).addMinted(_owner,1);
    }

    fallback() external {
        //empty code
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TokenInfo is AccessControl {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    
    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23); 
    }

    struct Vaults{
        address lender;
        address lenderRewards;
        address rewards;
    }
    //registration and control of approved tokens
    mapping(address => bool) internal tokens;
    //save the token contract and the vault for it
    mapping(address => Vaults) internal vaultsInfo;
    //save the collection contract and the rental vault contract to be used for each collection
    mapping(address => address) internal collectionToVault;

    function addToken(address _token) public onlydev {
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlydev {
        tokens[_token] = false;
    }

    function getToken(address _token) public view returns(bool _ok){
        return tokens[_token];
    }

    function addVaultRegistry(address _token, address _lender,address _lenderRewards,address _rewards) public onlydev  {
        vaultsInfo[_token].lender = _lender;
        vaultsInfo[_token].lenderRewards = _lenderRewards;
        vaultsInfo[_token].rewards = _rewards;
    }

    function removeVaultRegistry(address _token) public onlydev  {
        vaultsInfo[_token].lender = address(0);
        vaultsInfo[_token].lenderRewards = address(0);
        vaultsInfo[_token].rewards = address(0);
    }

    function getVaultInfo(address _token) public view returns(address _lender, address _lenderRewards,address _rewards){
        return ( vaultsInfo[_token].lender,
        vaultsInfo[_token].lenderRewards,
        vaultsInfo[_token].rewards);
    }

    function addVaultRent(address _collection, address _vault) public onlydev {
        collectionToVault[_collection] = _vault;
    }

    function removeVaultRent(address _collection) public onlydev {
        collectionToVault[_collection] = address(0);
    }

    function getVaultRent(address _collection) public view returns(address _vault){
        return collectionToVault[_collection];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract verification {
    ///@dev Returns the percentage of the total bid (used to calculate fee payments)
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        if(_price <= 0) {
            revert ("Price cannot be 0");
        }
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    function metadata(address _nftcontract, uint256 _nftid)
        internal
        view
        returns (
            //bool _mint
            string memory
        )
    {
        return IERC721Metadata(_nftcontract).tokenURI(_nftid);
     
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface ILazyNFT is IERC165{
    
    function redeem(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function preSale(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory base);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory, uint256 _length);

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
     
    function getPrice() external view returns (uint256);
    
    function getPresale() external view returns (uint256);

    function getPresaleStatus() external view returns (bool);

    function nftValuation() external view returns (uint256 _nftValuation);

    function getValuation() external view returns (uint256 _valuation);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

///@dev Interface to access function from Control contract.
interface IControl {

   function getNFTInfo(address _collection, uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint32
        );

    function getNFTTotal(address _wallet) external view returns (uint256 _total);

    function getNFTMinted(address _wallet) external view returns (uint256 _minted);

    function getNFTQuantity(address _wallet, address _collection)external view returns (uint256 _quantity);

    function addRegistry(address _collection, uint256 _nftId, address _wallet,uint32 _timestamp) external;

    function removeRegistry(address _collection, uint256 _nftId) external;

    function addQuantity(address _wallet,address _collection,uint256 _amount) external;

    function removeQuantity(address _wallet,address _collection, uint256 _amount) external;

    function addMinted(address _wallet,uint256 _amount) external;

    function addCounter() external;

    function seeCounter() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRewards {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeDaily() external returns (uint256 tempRewards);

    function getLastCall() external view returns(uint256 _last);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract MarketEvents {
    /*///////////////////////////////////////////////////////////////
                              EVENTS            
    //////////////////////////////////////////////////////////////*/

    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint256 buyNowPrice,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );


    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftHighestBidder
    );

    event AuctionWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyNowPrice
    );

    event NFTTransferred(
        address nftContractAddress,
        uint256 tokenId,
        address nftHighestBidder
    );

    event NFTMinted(
        address nftContractAddress,
        uint256 tokenId,
        address wallet
    );

    event NFTPresale(
        address nftContractAddress,
        uint256 tokenId,
        address wallet
    );

    /*///////////////////////////////////////////////////////////////
                              END EVENTS            
    //////////////////////////////////////////////////////////////*/
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