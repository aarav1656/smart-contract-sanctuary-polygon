// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../Interfaces/IDistinctNFT.sol";
import "./utils/Whitelist.sol";
import "./utils/DistinctTreasuryNode.sol";
import "./utils/DistinctMarketFee.sol";
import "./utils/AdminAuth.sol";

// import "hardhat/console.sol";

contract DistinctMarketplace is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    DistinctMarketFee,
    AdminAuth,
    Whitelist
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    IERC20Upgradeable public WETH;
    IERC20Upgradeable public USDT;

    address Treasury;

    IDistinctNFT private DistinctNFT;
    CountersUpgradeable.Counter private _saleIdTracker;

    uint256 public constant BASIS_POINT = 10000;
    uint256 public constant PLATFORM_FEE = 1000;

    enum SaleType {
        Drop,
        Auction,
        Direct
    }

    enum SaleStatus {
        closed,
        open,
        cancel
    }

    struct ReserveSaleItem {
        uint256 priceInWETH;
        uint256 priceInUSDT;
        mapping(address => uint256) buyersToAmount;
        uint256 amount;
    }

    struct ReserveSale {
        address seller;
        uint256[] tokenIds;
        mapping(uint256 => ReserveSaleItem) dropItems;
        SaleType saleType;
        SaleStatus status;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => ReserveSale) public reserveSale;

    uint256 public maxTimelimit;

    modifier validateInputs(uint256 startTime, uint256 endTime) {
        require(
            startTime > block.timestamp,
            "Distinct: Start time less than current time"
        );
        require(
            startTime < endTime,
            "Distinct: Start time greater than end time"
        );
        _;
    }

    modifier onlyAdmin() {
        require(DistinctNFT.isAdmin(_msgSender()), "Distinct: Not Admin");
        _;
    }

    modifier onlyOperator() {
        require(DistinctNFT.isOperator(_msgSender()), "Distinct: Not Operator");
        _;
    }

    modifier timeLimitExceeds(uint256 saleId) {
        uint256 deadline = block.timestamp + maxTimelimit;
        require(
            deadline < reserveSale[saleId].startTime,
            "DistinctMarket: time over"
        );
        _;  
    }

    modifier validateSaleId(uint256 saleId) {
        require(
            reserveSale[saleId].status == SaleStatus.open,
            "Distinct: Sale not open"
        );
        _;
    }
    modifier onlyDropSale(uint256 saleId) {
        require(
            reserveSale[saleId].saleType == SaleType.Drop,
            "Distinct: not Drop sale"
        );
        _;
    }

    modifier onlyAuctionSale(uint256 saleId) {
        require(
            reserveSale[saleId].saleType == SaleType.Drop,
            "Distinct: not Auction sale"
        );
        _;
    }

    modifier onlyDirectSale(uint256 saleId) {
        require(
            reserveSale[saleId].saleType == SaleType.Drop,
            "Distinct: not Direct sale"
        );
        _;
    }

    modifier onlySeller(uint256 saleId) {
        require(
            reserveSale[saleId].seller == _msgSender(),
            "Distinct: not seller"
        );
        _;
    }

    

    event SaleCreated(uint256 dropId);
    event DropItemsPurchased(uint256 dropId);
    event SaleUpdated(uint256 dropId);

    function initialize(
        address _distinctNFT,
        address _weth,
        address _usdt,
        uint256 primarySaleFee,
        uint256 secondarySaleFee
    ) external initializer {
        DistinctNFT = IDistinctNFT(_distinctNFT);
        _DistinctMarketFee_initialize(primarySaleFee, secondarySaleFee);
        // _initializeDistinctTreasuryNode();
        WETH = IERC20Upgradeable(_weth);
        USDT = IERC20Upgradeable(_usdt);
        maxTimelimit = 300;
    }

    function createSale(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256[] memory priceInWETH,
        uint256[] memory priceInUSDT,
        uint256 startTime,
        uint256 endTime
    ) external validateInputs(startTime, endTime) {
        require(
            tokenIds.length == amounts.length &&
                amounts.length == priceInWETH.length &&
                priceInWETH.length == priceInUSDT.length,
            "Distinct: ids, amounts and price length mismatch"
        );

        require(DistinctNFT.isOperator(_msgSender()), "Distinct: only Operator");

        uint256 numberOftokenIds = tokenIds.length;

        _saleIdTracker.increment();
        uint256 saleId = _saleIdTracker.current();

        DistinctNFT.safeBatchTransferFrom(
            _msgSender(),
            address(this),
            tokenIds,
            amounts,
            abi.encodePacked("Distinct: Transfer")
        );

        reserveSale[saleId].startTime = startTime;
        reserveSale[saleId].endTime = endTime;
        reserveSale[saleId].saleType = SaleType.Drop;
        reserveSale[saleId].status = SaleStatus.open;
        reserveSale[saleId].seller = _msgSender();

        for (uint256 i = 0; i < numberOftokenIds; i++) {
            reserveSale[saleId].tokenIds.push(tokenIds[i]);
            reserveSale[saleId].dropItems[tokenIds[i]].amount = amounts[i];
            reserveSale[saleId]
                .dropItems[tokenIds[i]]
                .priceInWETH = priceInWETH[i];
            reserveSale[saleId]
                .dropItems[tokenIds[i]]
                .priceInUSDT = priceInUSDT[i];
        }

        emit SaleCreated(saleId);
    }

    function updateSale(
        uint256 saleId,
        uint256[] memory tokenIds,
        uint256[] memory priceInWETH,
        uint256[] memory priceInUSDT,
        uint256 startTime,
        uint256 endTime
    )
        external
        validateSaleId(saleId)
        validateInputs(startTime, endTime)
        onlySeller(saleId)
        allowedByAdmin(Functionalities.UpdateSale)
    {
        require(
            tokenIds.length == priceInWETH.length &&
                priceInWETH.length == priceInUSDT.length,
            "Distinct: ids and price length mismatch"
        );
        uint256 numberOftokenIds = tokenIds.length;

        reserveSale[saleId].startTime = startTime;
        reserveSale[saleId].endTime = endTime;

        for (uint256 i = 0; i < numberOftokenIds; i++) {
            reserveSale[saleId]
                .dropItems[tokenIds[i]]
                .priceInWETH = priceInWETH[i];
            reserveSale[saleId]
                .dropItems[tokenIds[i]]
                .priceInUSDT = priceInUSDT[i];
        }
        emit SaleUpdated(saleId);
    }

    function buyDropItems(
        uint256 saleId,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address tokenReceiver,
        address paymentToken
    ) external onlyDropSale(saleId) onlyWhitelisted(saleId) {
        ReserveSale storage drop = reserveSale[saleId];

        require(
            tokenIds.length == amounts.length,
            "Distinct: ids and amounts length mismatch"
        );

        require(
            drop.startTime <= block.timestamp,
            "Distinct: Sale not started"
        );
        require(drop.endTime >= block.timestamp, "Distinct: Sale ended");

        require(
            _isUSDT(paymentToken) || _isWETH(paymentToken),
            "Distinct: not WETH or USDT"
        );

        (
            uint256 totalSellerRevenue,
            uint256 totalDistinctFee
        ) = _getSellerRevenueAndDistinctFeeTotal(
                drop,
                _msgSender(),
                tokenIds,
                amounts,
                paymentToken
            );

        // console.log(totalDistinctFee, totalSellerRevenue);
        if (totalSellerRevenue > 0) {
            IERC20Upgradeable(paymentToken).safeTransferFrom(
                _msgSender(),
                drop.seller,
                totalSellerRevenue
            );
        }
        if (totalDistinctFee > 0) {
            IERC20Upgradeable(paymentToken).safeTransferFrom(
                _msgSender(),
                address(this),
                totalDistinctFee
            );
        }

        DistinctNFT.safeBatchTransferFrom(
            address(this),
            tokenReceiver,
            tokenIds,
            amounts,
            abi.encodePacked("Distinct: Transfer")
        );

        emit DropItemsPurchased(saleId);
    }

    function updateAdminPermissions(Functionalities functionality, bool value) external onlyAdmin() {
        _updateProperties(functionality, value);
    }

    function isDropSale(uint256 saleId)
        external
        view
        onlyDropSale(saleId)
        returns (bool)
    {
        return true;
    }


    function updateTimelimit(uint256 _maxTimelimit) external onlyAdmin{
        maxTimelimit = _maxTimelimit;
    }

    function getPriceOfDropItems(
        bool allItems,
        uint256 dropId,
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory, uint256[] memory) {
        if (allItems) {
            return _getItemsPrice(dropId, reserveSale[dropId].tokenIds);
        }
        require(tokenIds.length > 0, "DistinctMarket: Need tokenIds");
        return _getItemsPrice(dropId, tokenIds);
    }

    function joinWhitelist(uint256 saleId)
        external
        validateSaleId(saleId)
        timeLimitExceeds(saleId)
    {
        _joinWhitelist(_msgSender(), saleId);
    }

    function _isUSDT(address paymentToken) internal view returns (bool) {
        return IERC20Upgradeable(paymentToken) == USDT;
    }

    function _isWETH(address paymentToken) internal view returns (bool) {
        return IERC20Upgradeable(paymentToken) == WETH;
    }

    function _getSellerRevenueAndDistinctFeeTotal(
        ReserveSale storage drop,
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address paymentToken
    ) internal returns (uint256 totalSellerRevenue, uint256 totalDistinctFee) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ReserveSaleItem storage dropItem = drop.dropItems[tokenIds[i]];
            require(
                dropItem.amount >= amounts[i],
                "Distinct: Item not available"
            );
            dropItem.buyersToAmount[account] += amounts[i];
            dropItem.amount -= amounts[i];

            uint256 itemsPrice;
            if (_isUSDT(paymentToken))
                itemsPrice = dropItem.priceInUSDT * amounts[i];
            if (_isWETH(paymentToken))
                itemsPrice = dropItem.priceInWETH * amounts[i];

            (uint256 distinctFee, uint256 ownerRevenue) = _distributeFunds(
                address(DistinctNFT),
                IERC20Upgradeable(paymentToken),
                tokenIds[i],
                drop.seller,
                itemsPrice
            );
            totalSellerRevenue += ownerRevenue;
            totalDistinctFee += distinctFee;
        }
    }

    function getSaleInfo(uint256 saleId)
        external
        view
        returns (
            address seller,
            SaleType saleType,
            SaleStatus status,
            uint256[] memory Nft,
            uint256 startTime,
            uint256 endTime
        )
    {
        return _getSaleInfo(saleId);
    }

    function _getSaleInfo(uint256 saleId)
        internal
        view
        returns (
            address,
            SaleType,
            SaleStatus,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        require(_saleExists(saleId), "Distinct: Sale does not exists");
        ReserveSale storage sale = reserveSale[saleId];

        return (
            sale.seller,
            sale.saleType,
            sale.status,
            sale.tokenIds,
            sale.startTime,
            sale.endTime
        );
    }

    function _saleExists(uint256 saleId) internal view returns (bool) {
        return reserveSale[saleId].seller != address(0);
    }

    function getItemsAmount(uint256 saleId)
        external
        view
        returns (uint256[] memory amounts)
    {
        return _getItemsAmount(saleId);
    }

    function _getItemsAmount(uint256 saleId)
        internal
        view
        returns (uint256[] memory amounts)
    {
        ReserveSale storage sale = reserveSale[saleId];
        uint256 numberOftokenIds = sale.tokenIds.length;
        amounts = new uint256[](numberOftokenIds);

        for (uint256 i = 0; i < numberOftokenIds; i++) {
            amounts[i] = sale.dropItems[sale.tokenIds[i]].amount;
        }
    }

    function _getItemsPrice(uint256 saleId, uint256[] memory tokenIds)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 numberOftokenIds = tokenIds.length;
        ReserveSale storage sale = reserveSale[saleId];

        uint256[] memory priceInUSDT = new uint256[](numberOftokenIds);
        uint256[] memory priceInWETH = new uint256[](numberOftokenIds);

        for (uint256 i = 0; i < numberOftokenIds; i++) {
            priceInWETH[i] = sale.dropItems[tokenIds[i]].priceInWETH;
            priceInUSDT[i] = sale.dropItems[tokenIds[i]].priceInUSDT;
        }
        return (priceInUSDT, priceInWETH);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
    {}
}

/**
 * @dev buyDropItems with royatly
 */
// function buyDropItems(
//         uint256 saleId,
//         uint256[] memory tokenIds,
//         uint256[] memory amounts,
//         address[] memory paymentTokens
//     ) external onlyDropSale(saleId) onlyWhitelisted(saleId){

//         ReserveSale storage drop = reserveSale[saleId];

//         require(drop.startTime < block.timestamp, 'Distinct: Sale not started');
//         require(drop.endTime > block.timestamp, 'Distinct: Sale ended');

//         uint256 numberOftokenIds = tokenIds.length;

//         uint256 totalInWETH = 0;
//         uint256 totalInUSDT = 0;
//         for (uint256 i = 0; i < numberOftokenIds; i++) {
//             ReserveSaleItem storage dropItem = drop.dropItems[tokenIds[i]];
//             require(
//                 dropItem.amount <= amounts[i],
//                 'Distinct: Item not available'
//             );
//             dropItem.buyersToAmount[_msgSender()] += amounts[i];
//             dropItem.amount -= amounts[i];

//             /**
//              * @dev Transfer token
//              */
//             uint256 price ;
//             IERC20Upgradeable payment;
//             if( paymentTokens[i] == address(WETH)) {
//                 price = dropItem.priceInWETH ;
//                 payment = WETH;
//             }
//             if( paymentTokens[i] == address(USDT)) {
//                 price = dropItem.priceInUSDT ;
//                 payment = USDT;

//             }

//             uint256 totalPrice = price * amounts[i];
//             (address royalty_receiver,
//             uint256 royalty_fee,
//             uint256 amountToSeller) = _feeHandler(tokenIds[i], totalPrice);

//             if(payment == USDT) totalInUSDT += amountToSeller;
//             else totalInWETH += amountToSeller;

//             if(royalty_receiver!=address(0))
//                 payment.safeTransferFrom(_msgSender(), royalty_receiver, royalty_fee);
//         }

//         if(totalInUSDT != 0)
//             USDT.safeTransferFrom(_msgSender(), drop.seller, totalInUSDT);
//         if(totalInWETH != 0)
//             WETH.safeTransferFrom(_msgSender(), drop.seller, totalInWETH);

//         DistinctNFT.safeBatchTransferFrom(
//             address(this),
//             _msgSender(),
//             tokenIds,
//             amounts,
//             abi.encodePacked('Distinct: Transfer')
//         );
//         emit DropItemsPurchased(saleId);
//     }

/**
 * @notice buy drop Items with multiple payment tokens
 */

// function buyDropItems(
//         uint256 saleId,
//         uint256[] memory tokenIds,
//         uint256[] memory amounts,
//         address[] memory paymentTokens
//     ) external onlyDropSale(saleId) onlyWhitelisted(saleId){

//         ReserveSale storage drop = reserveSale[saleId];

//         require(drop.startTime < block.timestamp, 'Distinct: Sale not started');
//         require(drop.endTime > block.timestamp, 'Distinct: Sale ended');

//         (
//             uint256 totalSellerRevenueInWETH,
//             uint256 totalSellerRevenueInUSDT,
//             uint256 totalDistinctFeeInWETH,
//             uint256 totalDistinctFeeInUSDT
//         ) = _getSellerRevenueAndDistinctFeeTotal(
//             drop,
//             _msgSender(),
//             tokenIds,
//             amounts
//             // paymentTokens
//         );

//         console.log(totalSellerRevenueInUSDT, totalSellerRevenueInWETH, totalDistinctFeeInUSDT, totalDistinctFeeInWETH);
//         console.log(_msgSender(),drop.seller);
//         // Transfer to seller
//         if(totalSellerRevenueInWETH > 0)
//             WETH.safeTransferFrom(_msgSender(), drop.seller, totalSellerRevenueInWETH);
//         if(totalSellerRevenueInUSDT > 0)
//             USDT.safeTransferFrom(_msgSender(), drop.seller, totalSellerRevenueInUSDT);

//         // Transfer to Treasury
//         if(totalDistinctFeeInUSDT > 0)
//             USDT.safeTransferFrom(_msgSender(), drop.seller, totalDistinctFeeInUSDT);
//         if(totalDistinctFeeInWETH > 0)
//             WETH.safeTransferFrom(_msgSender(), drop.seller, totalDistinctFeeInWETH);

//         DistinctNFT.safeBatchTransferFrom(
//             address(this),
//             _msgSender(),
//             tokenIds,
//             amounts,
//             abi.encodePacked('Distinct: Transfer')
//         );

//         emit DropItemsPurchased(saleId);
//     }

/**
 * @notice seller revenue
 */
/**
 function _getSellerRevenueAndDistinctFeeTotal(
        ReserveSale storage drop,
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal returns (
        uint256 totalSellerRevenueInWETH,
        uint256 totalSellerRevenueInUSDT,
        uint256 totalDistinctFeeInWETH,
        uint256 totalDistinctFeeInUSDT
    ) {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ReserveSaleItem storage dropItem = drop.dropItems[tokenIds[i]];
            require(
                dropItem.amount >= amounts[i], 
                'Distinct: Item not available'
            );
            dropItem.buyersToAmount[account] += amounts[i];
            dropItem.amount -= amounts[i];

            // if( _isUSDT(USDT) ) {
                (
                    uint256 distinctFee,
                    uint256 ownerRevenue
                ) = _distributeFunds(
                    address(DistinctNFT),
                    USDT,
                    tokenIds[i],
                    drop.seller,
                    dropItem.priceInUSDT * amounts[i]
                );
                totalSellerRevenueInUSDT += ownerRevenue;
                totalDistinctFeeInUSDT += distinctFee;

                console.log(totalSellerRevenueInUSDT, ': totalSellerRevenueInUSDT');
                console.log(totalDistinctFeeInUSDT, ':totalDistinctFeeInUSDT');
                console.log(ownerRevenue);
                console.log(distinctFee);
            // }
            // if( !_isUSDT(USDT)) {
            //     (
            //         uint256 distinctFee,
            //         uint256 ownerRevenue
            //     ) = _distributeFunds(
            //         DistinctNFT,
            //         USDT,
            //         tokenIds[i],
            //         drop.seller,
            //         dropItem.priceInWETH * amounts[i]
            //     );
            //     totalSellerRevenueInWETH += ownerRevenue;
            //     totalDistinctFeeInWETH += distinctFee;
            // }
        }
    }
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
// import "./IWrappedAccessControl.sol";
interface IDistinctNFT is IERC1155Upgradeable {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function getCreator(uint256 tokenId) external view returns(address);
    function isAdmin(address account) external view returns (bool);
    function isOperator(address account) external view returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";


contract Whitelist is Initializable, ContextUpgradeable {

    function __Whitelist_init() internal onlyInitializing {

    }

    mapping(bytes32 => uint256) private whitelist;
    
    modifier onlyWhitelisted(uint256 saleId) {
        bytes32 caller = keccak256(abi.encode(_msgSender(), saleId));
        require(whitelist[caller] == saleId, 'Distinct:user not whitelisted');
        _;
    }

    event Whitelisted(address caller, uint256 saleId);

    function isWhitelisted(uint256 saleId, address account) external view returns(bool){
        bytes32 caller = keccak256(abi.encode(account, saleId));
        return whitelist[caller] == saleId;
    }

    function _joinWhitelist(address account,uint256 saleId) internal{
        bytes32 caller = keccak256(abi.encode(account, saleId));

        require(whitelist[caller] == 0, 'Distinct.Whitelist: Already whitelisted');
        whitelist[caller] = saleId;

        emit Whitelisted(account, saleId);
    }

    // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
    uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Wethio treasury contract.
 */
abstract contract DistinctTreasuryNode is Initializable {
    using AddressUpgradeable for address;

    address private treasury;

    /**
     * @dev Called once after the initial deployment to set the Wethio treasury address.
     */
    function _initializeDistinctTreasuryNode(address _treasury)
        internal
        initializer
    {
        require(
            _treasury.isContract(),
            "DistinctTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    /**
     * @notice Returns the address of the Distinct treasury.
     */
    function getDistinctTreasury() public view returns (address) {
        return treasury;
    }

    /**
     * @notice Updates the address of the Wethio treasury.
     */
    function _updateDistinctTreasury(address _treasury) internal {
        require(
            _treasury.isContract(),
            "DistinctTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
    uint256[2000] private __gap;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Constants.sol";
import "../../Interfaces/IDistinctNFT.sol";
// import "hardhat/console.sol";
contract DistinctMarketFee is Constants, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private _primaryDistinctFeeBasisPoints;
    uint256 private _secondaryDistinctFeeBasisPoints;

    // mapping(uint256 => bool) private tokenIdToFirstSaleCompleted;

    event MarketFeesUpdated(
        uint256 primaryDistinctFeeBasisPoints,
        uint256 secondaryDistinctFeeBasisPoints
    );

    function _DistinctMarketFee_initialize(
        uint256 primaryDistinctFeeBasisPoints,
        uint256 secondaryDistinctFeeBasisPoints
    ) internal initializer {
        _primaryDistinctFeeBasisPoints = primaryDistinctFeeBasisPoints;
        _secondaryDistinctFeeBasisPoints = secondaryDistinctFeeBasisPoints;
    }

    function getFeeConfig()
        public
        view
        returns (
            uint256 primaryDistinctFeeBasisPoints,
            uint256 secondaryDistinctFeeBasisPoints
        )
    {
        return (
            _primaryDistinctFeeBasisPoints,
            _secondaryDistinctFeeBasisPoints
        );
    }

    function _getIsPrimary(
        address creator,
        address seller
    ) private pure returns (bool) {
        return creator == seller;
    }

    function _getFees(
        address distinctNft,
        uint256 tokenId,
        address seller,
        uint256 price
    )
        private
        view
        returns (
            uint256 distinctFee,
            address royaltyFeeTo,
            uint256 royaltyFee,
            address ownerRevenueTo,
            uint256 ownerRevenue
        )
    {
        (royaltyFeeTo, royaltyFee) = IDistinctNFT(distinctNft).royaltyInfo(tokenId, price);
        address creator = IDistinctNFT(distinctNft).getCreator(tokenId);

        uint256 distinctFeeBasisPoint;
        if (_getIsPrimary(creator, seller)) {
            distinctFeeBasisPoint = _primaryDistinctFeeBasisPoints;
            royaltyFeeTo = address(0);
            royaltyFee = 0;
        } else {
            distinctFeeBasisPoint = _secondaryDistinctFeeBasisPoints;
        }

        ownerRevenueTo = seller;

        distinctFee = (price * distinctFeeBasisPoint) / BASIS_POINTS;
        uint256 totalFee = distinctFee + royaltyFee;
        ownerRevenue = price - totalFee;
    }

    // function getFees(
    //     address distinctNft,
    //     uint256 tokenId,
    //     address seller,
    //     uint256 price
    // )
    //     public
    //     view
    //     returns (
    //         uint256 distinctFee,
    //         address royaltyFeeTo,
    //         uint256 royaltyFee,
    //         address ownerRevenueTo,
    //         uint256 ownerRevenue
    //     )
    // {
    //     return _getFees(distinctNft, tokenId, seller, price);
    // }

    function _distributeFunds(
        address distinctNft,
        IERC20Upgradeable paymentToken,
        uint256 tokenId,
        address seller,
        uint256 price
    ) internal returns (uint256 distinctFee, uint256 ownerRevenue) {
        address royaltyFeeTo;
        address ownerRevenueTo;

        uint256 royaltyFee;

        (
            distinctFee,
            royaltyFeeTo,
            royaltyFee,
            ownerRevenueTo,
            ownerRevenue
        ) = _getFees(distinctNft, tokenId, seller, price);

        // This must come after the `_getFees` call above as this state is considered in the function.
        // tokenIdToFirstSaleCompleted[tokenId] = true;

        if (royaltyFeeTo != address(0)) {
            paymentToken.safeTransferFrom(seller, royaltyFeeTo, royaltyFee);
        }
    }

    function _updateMarketFees(
        uint256 primaryDistinctFeeBasisPoints,
        uint256 secondaryDistinctFeeBasisPoints
    ) internal {
        require(
            primaryDistinctFeeBasisPoints < BASIS_POINTS,
            "DistinctMarketFee: Fees >= 100%"
        );
        require(
            secondaryDistinctFeeBasisPoints < BASIS_POINTS,
            "DistinctMarketFee: Fees >= 100%"
        );
        _primaryDistinctFeeBasisPoints = primaryDistinctFeeBasisPoints;
        _secondaryDistinctFeeBasisPoints = secondaryDistinctFeeBasisPoints;

        emit MarketFeesUpdated(
            primaryDistinctFeeBasisPoints,
            secondaryDistinctFeeBasisPoints
        );
    }

    uint256[1000] private ______gap;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

contract AdminAuth {

    enum Functionalities {
        UpdateSale
    }
    
    mapping(Functionalities => bool) isAllowed;

    modifier allowedByAdmin(Functionalities functionality) {
        require(isAllowed[functionality] == true, 'Distinct: not allowed by admin');
        _;
    }
    function _updateProperties(Functionalities functionality, bool value) internal {
        isAllowed[functionality] = value;
    }

    function getFunctionalities() external pure returns( Functionalities updateSale) {
        return Functionalities.UpdateSale;
    }
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
    uint256 internal constant BASIS_POINTS = 10000;
}