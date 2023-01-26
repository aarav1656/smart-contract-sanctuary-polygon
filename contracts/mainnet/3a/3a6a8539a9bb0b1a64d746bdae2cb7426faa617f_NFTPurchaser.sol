// SPDX-License-Identifier: --2020--DG--2023--

pragma solidity =0.8.17;

import "./EIP712MetaTransaction.sol";
import "./AccessController.sol";
import "./TransferHelper.sol";
import "./Interfaces.sol";

contract NFTPurchaser is
    AccessController,
    TransferHelper,
    EIP712MetaTransaction
{
    uint256 public saleCount;
    uint256 public saleFrame;
    uint256 public saleLimit;

    bool public allowChangeSaleLimit;

    mapping(address => uint256) public frames;
    mapping(address => address) public targets;

    // collectionAddress -> itemId -> buyLimit
    mapping(address => mapping(uint256 => uint256)) public buyLimit;

    // shineLevel -> paymentTokenAddress -> shinePrice
    mapping(uint256 => mapping(address => uint256)) public shinePrice;

    // collectionAddress -> itemId -> paymentTokenAddress -> buyingPrice
    mapping(address => mapping(uint256 => mapping(address => uint256))) public buyingPrice;

    event Buy(
        uint256 tokenId,
        uint256 buyCount,
        uint256 finalPrice,
        address indexed tokenOwner,
        address collectionAddress,
        address paymentTokenAddress,
        uint256 indexed shineLevel
    );

    event SupplyCheck(
        string rarity,
        uint256 maxSupply,
        uint256 price,
        address beneficiary,
        string indexed metadata,
        string indexed contentHash
    );

    constructor(
        address _accessoriesContract
    )
        EIP712Base(
            "NFTPurchaser",
            "v2.0"
        )
    {
        saleLimit = 500;
        saleFrame = 1 hours;

        allowChangeSaleLimit = true;
        targets[_accessoriesContract] = _accessoriesContract;
    }

    function changeShinePrice(
        uint256 _price,
        uint256 _shineLevel,
        address _paymentTokenAddress
    )
        external
        onlyCEO
    {
        shinePrice
            [_shineLevel]
            [_paymentTokenAddress] = _price;
    }

    function changeBuyingPrice(
        uint256 _price,
        uint256 _itemId,
        address _collectionAddress,
        address _paymentTokenAddress
    )
        external
        onlyCEO
    {
        buyingPrice
            [_collectionAddress]
            [_itemId]
            [_paymentTokenAddress] = _price;
    }

    function changeBuyLimits(
        uint256 _limit,
        uint256 _itemId,
        address _collectionAddress
    )
        external
        onlyCEO
    {
        buyLimit[_collectionAddress][_itemId] = _limit;
    }

    function changeSaleFrame(
        uint256 _newSaleFrame
    )
        external
        onlyCEO
    {
        saleFrame = _newSaleFrame;
    }

    function changeSaleLimit(
        uint256 _newSaleLimit
    )
        external
        onlyCEO
    {
        require(
            allowChangeSaleLimit == true,
            "NFTPurchaser: DISABLED"
        );

        saleLimit = _newSaleLimit;
    }

    function disabledSaleLimitChange()
        external
        onlyCEO
    {
        allowChangeSaleLimit = false;
    }

    function changeTargetContract(
        address _collectionAddress,
        address _accessoriesContract
    )
        external
        onlyCEO
    {
        targets[_collectionAddress] = _accessoriesContract;
    }

    function purchaseToken(
        uint256 _itemId,
        address _buyerAddress,
        address _collectionAddress,
        address _paymentTokenAddress,
        uint256 _shineLevel
    )
        external
    {
        require(
            saleLimit > saleCount,
            "NFTPurchaser: SOLD_OUT"
        );

        unchecked {
            saleCount =
            saleCount + 1;
        }

        require(
            buyLimit[_collectionAddress][_itemId] > 0,
            "NFTPurchaser: ITEM_LIMITED"
        );

        unchecked {
            buyLimit[_collectionAddress][_itemId] =
            buyLimit[_collectionAddress][_itemId] - 1;
        }

        require(
            canPurchaseAgain(_buyerAddress),
            "NFTPurchaser: COOL_DOWN_DETECTED"
        );

        uint256 itemPrice = buyingPrice
            [_collectionAddress][_itemId][_paymentTokenAddress];

        require(
            itemPrice > 0,
            "NFTPurchaser: UNPRICED_ITEM"
        );

        if (_shineLevel > 0) {

            uint256 extraPrice = shinePrice
                [_shineLevel][_paymentTokenAddress];

            require(
                extraPrice > 0,
                "NFTPurchaser: UNPRICED_SHINE"
            );

            itemPrice = itemPrice + extraPrice;
        }

        frames[_buyerAddress] = block.timestamp;

        safeTransferFrom(
            _paymentTokenAddress,
            msgSender(),
            ceoAddress,
            itemPrice
        );

        DGAccessories target = DGAccessories(
            targets[_collectionAddress]
        );

        uint256 newTokenId = target.encodeTokenId(
            _itemId,
            getSupply(
                _itemId,
                targets[_collectionAddress]
            ) + 1
        );

        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = _buyerAddress;

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = _itemId;

        target.issueTokens(
            beneficiaries,
            itemIds
        );

        emit Buy(
            newTokenId,
            saleCount,
            itemPrice,
            _buyerAddress,
            _collectionAddress,
            _paymentTokenAddress,
            _shineLevel
        );
    }

    function canPurchaseAgain(
        address _buyerAddress
    )
        public
        view
        returns (bool)
    {
        return block.timestamp - frames[_buyerAddress] > saleFrame;
    }

    function getSupply(
        uint256 _itemId,
        address _accessoriesContract
    )
        public
        returns (uint256)
    {
        (   string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash

        ) = DGAccessories(_accessoriesContract).items(_itemId);

        emit SupplyCheck(
            rarity,
            maxSupply,
            price,
            beneficiary,
            metadata,
            contentHash
        );

        return totalSupply;
    }
}