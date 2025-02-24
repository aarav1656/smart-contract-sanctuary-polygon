// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./PaymentComp.sol";
import "./OrderComp.sol";
import "./FeeComp.sol";
import "./TokenHelperComp.sol";
import "./VoucherComp.sol";
import "./MintComp.sol";
import "./CloneFactory.sol";
import "./IERC721Send.sol";
import "./IERC1155Send.sol";

// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Exchange is  OwnableUpgradeable, PaymentComp, OrderComp, TokenHelperComp, FeeComp, VoucherComp, MintComp, CloneFactory{
    event PaymentEvent(uint256 indexed orderId,address indexed user,uint256 amount);

    // constructor (address receiver, uint256 rate, address erc721, address erc1155) 
    // FeeComp(receiver,rate)
    // CloneFactory(erc721,erc1155)
    // {
    // }

    address public lzEndpoint;

     function initialize(address receiver, uint256 rate, address erc721, address erc1155) public initializer
    {
        __Ownable_init();
        __FeeComp_init(receiver,rate);
        
        __CloneFactory_init(erc721, erc1155);
    }

    function setFee( address receiver,uint256 rate) public onlyOwner{
        _setFee(receiver, rate);
    }
    
    function setLzEndpoint(address _lzEndpoint)public onlyOwner{

        lzEndpoint=_lzEndpoint;
    }

    function changeNftChain(uint256 tokentype,address token,address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId,uint _amount, address payable _refundAddress, address _zroPaymentAddress ,bytes memory _adapterParams) payable public {
        if (tokentype==0) {
            IERC721Send erc721 = IERC721Send(token);
        //  require(erc721.);
         
         erc721.sendFrom{value: msg.value}(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
            
        } else {
             IERC1155Send erc1155 = IERC1155Send(token);
        //  require(erc721.);
         
         
         erc1155.sendFrom{value: msg.value}(_from, _dstChainId, _toAddress, _tokenId, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
        }
        
    }

    function getEstimateSendFee(uint256 tokentype,address token,uint16 _dstChainId, bytes memory _toAddress, uint _tokenId,uint _amount, bool _useZro,bytes memory _adapterParams) public view  returns (uint nativeFee, uint zroFee){
                if (tokentype==0) {
                    IERC721Send erc721 = IERC721Send(token);
              
              (nativeFee,zroFee)= erc721.estimateSendFee(_dstChainId, _toAddress, _tokenId, _useZro, _adapterParams);
                } else {
                     IERC1155Send erc1155 = IERC1155Send(token);
               
              (nativeFee,zroFee)= erc1155.estimateSendFee(_dstChainId, _toAddress, _tokenId, _amount, _useZro, _adapterParams);
              
                }
              

               
    }

    

    function setVoucherIssuer(address newIssuer) public onlyOwner{
        _setIssuer(newIssuer);
    }

     function CloneERC721(string memory name_, string memory symbol_)external{
         address owner=super.owner();
         
         _CloneERC721(name_, symbol_,owner,lzEndpoint);
     }

       function CloneERC1155(string memory name_, string memory symbol_) external{
         address owner=super.owner();
         
         _CloneERC1155(name_, symbol_,owner,lzEndpoint);
     }

    // function for seller
    function createOrder(InputOrder memory order) public{
        if(order.asset.assetType == AssetType.ERC721){
            erc721ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId, order.asset.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        _crateOrder(_msgSender(), order);
    }

    function createOrderWithGift(InputOrder memory order,Asset memory gift) public{
        if(order.asset.assetType == AssetType.ERC721){
            erc721ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId, order.asset.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        // 是否持有赠品Token验证
        if(gift.assetType == AssetType.ERC721){
            erc721ResourcesVerify(gift.token, _msgSender(), gift.tokenId);
        }else if(gift.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(gift.token, _msgSender(), gift.tokenId, gift.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        _crateOrderWithGift(_msgSender(), order,gift);
    }

    // function for buyer,Only be used for FixedPrice orders 
    function buy(uint256 orderId, uint256 voucherId) public {
        // 验证交易订单有效性
        _verifyOrder(orderId);

        Order storage order = _orders[orderId];
        require(order.orderType == OrderType.FixedPrice, "buy: Only be used for FixedPrice orders");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(voucherId != 0){
            voucherAmount = _useVoucher(voucherId, orderId, order.price, _msgSender());
        }

        // 直接扣款，无需验证
        //erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);
        // 扣除资金
        _deduction(orderId, order.paymentToken, _msgSender() , order.price - voucherAmount);

        uint256 paymentId = _addPayment(orderId, _msgSender(), order.paymentToken, order.price - voucherAmount, voucherId, block.timestamp, PaymentStatus.Successful);

        // modify
        order.lastPayment = paymentId;
        order.payments.push(paymentId);

        _swap(orderId, paymentId);
    }

    // function for buyer, for FixedPrice and OpenForBids mode orders
    function makeOffer(uint256 orderId, uint256 amount, uint256 voucherId,uint256 endtime) public{
        _verifyOrder(orderId);
        Order storage order = _orders[orderId];

        require(order.orderType != OrderType.TimedAuction, "makeOffer: Cannot be used for TimedAuction orders");

        if (order.orderType ==  OrderType.OpenForBids){
            require(amount >= order.price, "makeOffer: Price is lower than the lowest price set by the seller");
        }

        // 验证购买人资金充足
        erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);

        uint256 paymentId = _addPayment(orderId, _msgSender(), order.paymentToken, amount, voucherId, endtime, PaymentStatus.Bidding);

        order.lastPayment = paymentId;
        order.payments.push(paymentId);
    }

    function auction(uint256 orderId, uint256 amount,uint256 voucherId) public{
        _verifyOrder(orderId);

        Order storage order = _orders[orderId];

        require(order.orderType == OrderType.TimedAuction, "auction: Only be used for TimedAuction orders");
        require(amount >= order.price, "auction: Price is lower than the lowest price set by the seller");

        require(_isHigherBid(order.lastPayment, amount), "auction: The bid is lower than the last time");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(voucherId != 0){
            voucherAmount = _useVoucher(voucherId, orderId, amount, _msgSender());
        }
        // 直接扣款，无需验证
        //erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);
        // 扣除资金
        _deduction(orderId, order.paymentToken, _msgSender(), amount - voucherAmount);

        // 返还上一次竞拍人资金
        if(order.lastPayment != 0){
            Payment storage lastPayment = _payments[order.lastPayment];
            lastPayment.paymentStatus = PaymentStatus.Failed;

            _refund(order.paymentToken, lastPayment.payor, lastPayment.amount);
        }

        uint256 paymentId = _addPayment(orderId, _msgSender(),order.paymentToken, amount - voucherAmount, voucherId, order.endTime, PaymentStatus.Bidding);

        order.lastPayment = paymentId;
        order.payments.push(paymentId);
    }

    // function for seller, for FixedPrice and OpenForBids mode order
    function accept(uint256 orderId, uint256 paymentId) public{
        _verifyOrder(orderId);

        Order memory order = _orders[orderId];
        Payment storage payment = _payments[order.lastPayment];

        require(_msgSender() == order.seller,"accept: You are not the seller");
        require(block.timestamp <= payment.endtime,"accept: offer has expired");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(payment.voucherId != 0){
            voucherAmount = _useVoucher(payment.voucherId, orderId, payment.amount, payment.payor);
        }
        // 扣款
        _deduction(orderId, order.paymentToken, payment.payor, payment.amount - voucherAmount);

        _swap(orderId, paymentId);
    }

    // function for buyer, when the auction is ended call this function
    function auctionConfirm(uint256 orderId) public{
        Order memory order = _orders[orderId];

        require(order.orderType == OrderType.TimedAuction, "auctionConfirm: Only be used for TimedAuction orders");

        // 判断订单状态是否正常可交易
        require(order.orderStatus == OrderStatus.Opened,"auctionConfirm: The order is closed");
        require(block.timestamp > order.endTime,"auctionConfirm: The auction has not ended yet");

        Payment storage payment = _payments[order.lastPayment];
        require(_msgSender() == payment.payor,"auctionConfirm: The last bidder is not you");

        _swap(orderId, order.lastPayment);
    }

    // function for seller, cancel the order before the order confirmed
    function cancel(uint256 orderId) public{
        Order memory order = _orders[orderId];

        require(order.seller == _msgSender(),"cancel: You are not the seller");
        require(order.orderStatus == OrderStatus.Opened,"cancel: The current state has no cancellation");

        if(order.orderType == OrderType.TimedAuction && order.lastPayment != 0){
            Payment storage lastPayment = _payments[order.lastPayment];
            lastPayment.paymentStatus = PaymentStatus.Failed;

            _refund(order.paymentToken, lastPayment.payor, lastPayment.amount);
        }

        _orderCancel(orderId);
    }

    function createVoucher(uint8 voucherType, uint256 id, address operator,uint256 value, uint256 startTime, uint256 endTime) public {
        _createVoucher(_msgSender(), voucherType, id, operator, value, startTime, endTime);
    }

    function voucherToUser(uint256 id, address user) public {
        _voucherToUser(_msgSender(), id, user);
    }

    function _swap(uint256 orderId,uint256 paymentId) internal{
        Order storage order = _orders[orderId];
        Payment storage payment = _payments[paymentId];
        
        // 资金分配
        _allocationFunds(orderId, payment.amount);
        
        if(order.asset.assetType == AssetType.ERC721){
            _erc721TransferFrom(order.asset.token, order.seller, payment.payor, order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            _erc1155TransferFrom(order.asset.token, order.seller, payment.payor, order.asset.tokenId, order.asset.value,"burble exchange");
        }

        // 如果订单有赠品，则赠送
        if(order.gift.token != address(0)){
            if(order.gift.assetType == AssetType.ERC721){
                _erc721TransferFrom(order.gift.token, order.seller, payment.payor, order.gift.tokenId);
            }else if(order.gift.assetType == AssetType.ERC1155){
                _erc1155TransferFrom(order.gift.token, order.seller, payment.payor, order.gift.tokenId, order.gift.value,"burble exchange gift");
            }
        }

        payment.paymentStatus = PaymentStatus.Successful;
        
        order.txPayment = order.lastPayment;
        _orderComplete(orderId);
    }

    // 扣款
    function _deduction(uint256 orderId,address token, address from, uint256 amount) internal{
        _erc20TransferFrom(token, from, address(this), amount);

        emit PaymentEvent(orderId, from, amount);
    }

    // 资金返还
    function _refund(address token,address lastByuer, uint256 amount) internal{
        _erc20Transfer(token,lastByuer,amount);
    }

    // 资金分配
    function _allocationFunds(uint256 orderId,uint256 txAmount) internal{
        Order memory order = _orders[orderId];

        uint256 totalFee;
        
        // 平台手续费
        address feeReceiver;
        uint256 feeRate;
        (feeReceiver,feeRate) = getFee();
        uint256 feeAmount = txAmount * feeRate / 10000;
        _erc20Transfer(order.paymentToken, feeReceiver, feeAmount);
        totalFee += feeAmount;

        // 版税
        address royaltyMaker;
        uint256 royaltyRate;
        (royaltyMaker,royaltyRate) = getRoyalty(order.asset.token, order.asset.tokenId);
        if (royaltyMaker != address(0)) {
            uint256 royaltyAmount = royaltyRate * txAmount / 10000;
            _erc20Transfer(order.paymentToken, royaltyMaker, royaltyAmount);
            totalFee += royaltyAmount;
        }

        // 剩余全部转给 卖家
        _erc20Transfer(order.paymentToken, order.seller, txAmount - totalFee);
    }

    function getMATIC(address getaddress,uint256 amount) public onlyOwner{
        payable(getaddress).transfer(amount);
    }
    function getMATICBalanceThisAddress() public view returns(uint256){
        return address(this).balance;
    }

    function changeBase7211155(address erc721adress, address erc1155address) public onlyOwner{
        changebase7211155(erc721adress, erc1155address);
    }
}