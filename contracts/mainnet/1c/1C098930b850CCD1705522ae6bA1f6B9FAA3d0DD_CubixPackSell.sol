/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *
 * Cubix NFTs
 * URL: cubixpro.io/
 *
 */
pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function mint(address reciever, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
}

interface ERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract CubixPackSell {
    using SafeMath for uint256;
    struct UserStruct {
        address id;
        address parentId;
        uint256 level;
        uint256 income;
        uint256 businessIncome;
        uint256 createdDate;
    }

    struct PackStruct {
        uint256 id;
        uint256 price;
        uint256 nfts;
        uint256 sportId;
        uint256 buyLimit;
    }

    struct Limits {
        uint256 targets;
        uint256 directCommision;
    }

    uint256 public currentId = 0;
    uint256 private maxLoopCounter = 500;
    address payable public ownerAddress;

    mapping(uint256 => uint256) public packBought;
    mapping(uint256 => Limits) public levelsMap;
    mapping(uint256 => PackStruct) public packsMap;
    mapping(address => UserStruct) public usersMap;
    mapping(address => uint256) public deposit;
    mapping(address => uint256) public depositOfCubix;

    mapping(address => mapping(uint256 => uint256)) public levelWiseProfitMap;
    ERC20 usdt;
    ERC20 cubixToken;
    ERC721 nft;

    uint256 public totalNFTs = 0;
    uint256 maxLevel = 14;
    address[] public partners;
    uint256[] public partnersPercentage;

    event ChangeLevel(address indexed _address, uint256 Level);

    event RegUserEvent(
        address indexed userAddress,
        uint256 indexed userId,
        address referrer,
        uint256 packId,
        uint256 businessIncome,
        uint256 Time
    );
    event NFTMintEvent(
        address indexed userAddress,
        uint256 indexed nftId,
        uint256 packId,
        uint256 Time
    );
    event RefProfitForLevelEvent(
        address indexed profitFrom,
        uint256 totalIncome,
        uint256 businessIncome,
        address userAddress,
        uint256 level,
        uint256 amount,
        uint256 packId,
        uint256 percentage,
        uint256 incomeType
    );
    event BuyPackEvent(
        address indexed userAddress,
        uint256 packId,
        uint256 businessIncome,
        uint256 Time
    );
    event ClaimEvent(
        address indexed userAddress,
        uint256 amont,
        uint256 Time
    );

    constructor(address _nftAddress, address _usdtAddress) {
        ownerAddress = payable(msg.sender);
        nft = ERC721(_nftAddress);
        usdt = ERC20(_usdtAddress);
        
        levelsMap[1] = Limits(30000000, 14);
        levelsMap[2] = Limits(5000000000, 17);
        levelsMap[3] = Limits(10000000000, 20);
        levelsMap[4] = Limits(20000000000, 22);
        levelsMap[5] = Limits(40000000000, 24);
        levelsMap[6] = Limits(80000000000, 26);
        levelsMap[7] = Limits(160000000000, 28);
        levelsMap[8] = Limits(320000000000, 30);
        levelsMap[9] = Limits(640000000000, 32);
        levelsMap[10] = Limits(1280000000000, 33);
        levelsMap[11] = Limits(2560000000000, 34);
        levelsMap[12] = Limits(5120000000000, 35);
        levelsMap[13] = Limits(10240000000000, 36);
        levelsMap[14] = Limits(20480000000000, 37);

        UserStruct memory userStruct;
        currentId = currentId.add(1);
        userStruct = UserStruct({
            id: ownerAddress,
            createdDate: block.timestamp,
            parentId: address(0),
            level: 1,
            income: 0,
            businessIncome: 0
        });
        usersMap[ownerAddress] = userStruct;
        
        // partners starts
        partners.push(msg.sender);
        partnersPercentage.push(90);
        
        partners.push(address(0xE6601baa84f06657D10859c578986f934B6fFBf6));
        partnersPercentage.push(2);

        partners.push(address(0x87Fc196600Eb3dCc76d8bBf0Db8c56156E8E2396));
        partnersPercentage.push(2);
        
        partners.push(address(0x2c52Cb271244Bfb480ecED76c84D712FdE5aC957));
        partnersPercentage.push(2);

        partners.push(address(0x066f129d4168e43121136649E5dbf8EEfEf2eCe9));
        partnersPercentage.push(2);
        
        partners.push(address(0x3e8Ab1bbc3042041D6Cd32466928245bf1bfb316));
        partnersPercentage.push(2);
        // partners ends

        emit RegUserEvent(
            msg.sender,
            currentId,
            address(0),
            6,
            userStruct.businessIncome,
            block.timestamp
        );
        packsMap[1] = PackStruct({
            id: 1,
            price: 30000000,
            nfts: 1,
            sportId: 1,
            buyLimit: 10500
        });
        packsMap[2] = PackStruct({
            id: 2,
            price: 150000000,
            nfts: 6,
            sportId: 1,
            buyLimit: 71500
        });
        packsMap[3] = PackStruct({
            id: 3,
            price: 250000000,
            nfts: 11,
            sportId: 1,
            buyLimit: 51000
        });
        packsMap[4] = PackStruct({
            id: 4,
            price: 500000000,
            nfts: 25,
            sportId: 1,
            buyLimit: 40000
        });
        packsMap[5] = PackStruct({
            id: 5,
            price: 1000000000,
            nfts: 57,
            sportId: 1,
            buyLimit: 10000
        });
        packsMap[6] = PackStruct({
            id: 6,
            price: 2500000000,
            nfts: 153,
            sportId: 1,
            buyLimit: 5000
        });
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Only owner');
        _;
    }
    modifier onlyFounder() {
        require(msg.sender == ownerAddress, 'Only onlyFounder');
        _;
    }

    function regUser(
        uint256 _packId,
        address referrer,
        bool isUsdt
    ) external payable {
        UserStruct memory parent = usersMap[referrer];
        PackStruct memory pack = packsMap[_packId];
        uint256 packBoughts = packBought[_packId];
        require(usersMap[msg.sender].id == address(0), 'User exist');
        require(parent.id != address(0), 'Invalid Referrer');
        require(pack.price != 0, 'Pack not exist');
        require(pack.buyLimit > packBoughts, 'Pack sold out');

        ERC20 tokenToConsider = usdt;
        if (!isUsdt) {
            tokenToConsider = cubixToken;
        }

        uint256 balance = tokenToConsider.balanceOf(msg.sender);
        uint256 allowance = tokenToConsider.allowance(
            msg.sender,
            address(this)
        );

        require(balance >= pack.price, 'Error: Insufficient Balance');
        require(allowance >= pack.price, 'Error: Allowance less than spending');

        UserStruct memory userStruct;
        currentId = currentId.add(1);
        userStruct = UserStruct({
            id: msg.sender,
            createdDate: block.timestamp,
            parentId: parent.id,
            level: 1,
            income: 0,
            businessIncome: 0
        });
        usersMap[msg.sender] = userStruct;

        // transfer all tokens to this contract.
        tokenToConsider.transferFrom(msg.sender, address(this), pack.price);
        payReferrals(msg.sender, pack, tokenToConsider, isUsdt);

        // add logic to distribute nfts here
        sendNFTs(msg.sender, _packId);
        packBought[_packId] = packBoughts.add(1);

        emit RegUserEvent(
            msg.sender,
            currentId,
            parent.id,
            _packId,
            usersMap[msg.sender].businessIncome,
            block.timestamp
        );
    }

    function payReferrals(
        address userAddress,
        PackStruct memory pack,
        ERC20 tokenToConsider,
        bool isUsdt
    ) internal {
        UserStruct memory user = usersMap[userAddress];
        // increase self business income
        usersMap[user.id].businessIncome = user.businessIncome.add(
            packsMap[pack.id].price
        );
        uint256 loopCounter = 0;
        while (loopCounter < maxLoopCounter) {
            if (user.parentId == address(0)) {
                // root user
                payAdmin(pack.price, user.id, pack.id, tokenToConsider);
                break;
            }
            UserStruct memory parentUser = usersMap[user.parentId];
            // increase parnet user's business income
            usersMap[parentUser.id].businessIncome = parentUser.businessIncome.add(
                packsMap[pack.id].price
            );
            if (loopCounter == 0) {
                // direct income
                uint256 directIncome = (
                    packsMap[pack.id].price.mul(
                        levelsMap[parentUser.level].directCommision
                    )
                ).div(100);
                tokenToConsider.transfer(parentUser.id, directIncome);
                usersMap[parentUser.id].income = parentUser.income.add(
                    directIncome
                );
                pack.price = pack.price.sub(directIncome);
                afterSendingReferral(
                    user.id,
                    parentUser.id,
                    directIncome,
                    pack.id,
                    1,
                    levelsMap[parentUser.level].directCommision
                );
            } else {
                // indirect gap income and increase business income and level
                if (
                    levelsMap[parentUser.level].directCommision >=
                    levelsMap[user.level].directCommision
                ) {
                    uint256 gapPercentage = levelsMap[parentUser.level]
                        .directCommision
                        .sub(levelsMap[user.level].directCommision);
                    if (gapPercentage > 0) {
                        uint256 gapIncome = (
                            packsMap[pack.id].price.mul(gapPercentage)
                        ).div(100);
                        
                        usersMap[user.parentId].income = parentUser.income.add(
                            gapIncome
                        );

                        if (isUsdt) {
                            deposit[user.parentId] = deposit[user.parentId].add(
                                gapIncome
                            );                            
                        } else {
                            depositOfCubix[user.parentId] = depositOfCubix[user.parentId].add(
                                gapIncome
                            );
                        }
                        pack.price = pack.price.sub(gapIncome);
                        afterSendingReferral(
                            user.id,
                            parentUser.id,
                            gapIncome,
                            pack.id,
                            2,
                            gapPercentage
                        );
                    } else {
                        afterSendingReferral(
                            user.id,
                            parentUser.id,
                            0,
                            pack.id,
                            4,
                            0
                        );
                    }
                } else {
                    afterSendingReferral(user.id, parentUser.id, 0, pack.id, 4, 0);
                }
            }
            setNewLevel(user.id);
            user = usersMap[user.parentId];
            loopCounter = loopCounter.add(1);
        }
    }

    function afterSendingReferral(
        address userId,
        address parentUser,
        uint256 amount,
        uint256 packId,
        uint256 typeId,
        uint256 percentage
    ) internal {
        UserStruct memory user = usersMap[userId];
        UserStruct memory pUser = usersMap[parentUser];
        emit RefProfitForLevelEvent(
            user.id,
            pUser.income,
            pUser.businessIncome,
            parentUser,
            user.level,
            amount,
            packId,
            percentage,
            typeId
        );
    }

    function setNewLevel(address userId) internal {
        uint256 curLevel = usersMap[userId].level;
        while (curLevel <= maxLevel) {
            if (usersMap[userId].businessIncome < levelsMap[curLevel].targets) {
                break;
            } else {
                emit ChangeLevel(userId, curLevel);
                usersMap[userId].level = curLevel;
            }
            curLevel = curLevel.add(1);
        }
    }

    function payAdmin(
        uint256 amount,
        address userAddress,
        uint256 packId,
        ERC20 tokenToConsider
    ) internal {
        uint256 remainingAmount = amount;
        for (uint256 i = 0; i < partners.length; i++) {
            address partner = partners[i];
            uint256 percentage = partnersPercentage[i];
            uint256 portion = (packsMap[packId].price.mul(percentage)).div(100);
            if (portion > 0 && amount > 0) {
                if (partner != ownerAddress) {
                    tokenToConsider.transfer(partner, portion);
                }
                if (remainingAmount >= portion) {
                    remainingAmount = remainingAmount.sub((portion));
                }
            }
            
        }

        usersMap[ownerAddress].income = usersMap[ownerAddress].income.add(
            remainingAmount
        );
        if (remainingAmount > 0) {
            tokenToConsider.transfer(ownerAddress, remainingAmount);
        }
        setNewLevel(ownerAddress);
        afterSendingReferral(userAddress, ownerAddress, remainingAmount, packId, 3, 0);
    }

    function minNFT(address accountAddress, uint256 packId) internal {
        totalNFTs = totalNFTs.add(1);
        uint256 nftId = totalNFTs;
        nft.mint(accountAddress, nftId);
        emit NFTMintEvent(accountAddress, nftId, packId, block.timestamp);
    }

    function sendNFTs(address accountAddress, uint256 packId) internal {
        PackStruct memory pack = packsMap[packId];
        uint256 counter = 1;
        while (pack.nfts >= counter) {
            minNFT(accountAddress, pack.id);
            counter = counter.add(1);
        }
    }

    function setUSDTContractAddress(address usdtAddress) external onlyOwner {
        usdt = ERC20(usdtAddress);
    }

    function setCubixTokenContractAddress(address cubixTokenAddress)
        external
        onlyOwner
    {
        cubixToken = ERC20(cubixTokenAddress);
    }

    function setNFTContractAddress(address nftAddress) external onlyOwner {
        nft = ERC721(nftAddress);
    }

    function alreadyMintedNFT(uint256 _mintedNFT) external onlyOwner {
        totalNFTs = _mintedNFT;
    }

    function setMaxLoopConter(uint256 _maxLoopCounter) external onlyOwner {
        maxLoopCounter = _maxLoopCounter;
    }

    function changeOwnerAddress(address _ownerAddress, uint256 _percentage)
        external
        onlyOwner
    {
        delete usersMap[ownerAddress];
        ownerAddress = payable(_ownerAddress);
        partners[0] = _ownerAddress;
        partnersPercentage[0] = _percentage;
        UserStruct memory userStruct;
        userStruct = UserStruct({
            id: _ownerAddress,
            createdDate: block.timestamp,
            parentId: address(0),
            level: 1,
            income: 0,
            businessIncome: 0
        });
        usersMap[ownerAddress] = userStruct;
        emit RegUserEvent(
            _ownerAddress,
            1,
            address(0),
            6,
            userStruct.businessIncome,
            block.timestamp
        );
    }

    function addPartnerWithPercentage(
        address _partnerAddress,
        uint256 _percentage
    ) external onlyOwner {
        partners.push(_partnerAddress);
        partnersPercentage.push(_percentage);
    }

    function changePartnerWithPercentage(
        uint256 id,
        address _partnerAddress,
        uint256 _percentage
    ) external onlyOwner {
        partners[id] = _partnerAddress;
        partnersPercentage[id] = _percentage;
    }

    function buyPack(uint256 _packId, bool isUsdt) external payable {
        UserStruct memory user = usersMap[msg.sender];
        PackStruct memory pack = packsMap[_packId];
        uint256 packBoughts = packBought[_packId];
        require(user.id != address(0), 'User not registered yet');
        require(pack.price != 0, 'Pack not exist');
        ERC20 tokenToConsider = usdt;
        if (!isUsdt) {
            tokenToConsider = cubixToken;
        }
        // check approved amount and sent amount distribution logic
        uint256 balance = tokenToConsider.balanceOf(msg.sender);
        uint256 allowance = tokenToConsider.allowance(
            msg.sender,
            address(this)
        );
        require(balance >= pack.price, 'Error: Insufficient Balance');
        require(allowance >= pack.price, 'Error: Allowance less than spending');
        tokenToConsider.transferFrom(msg.sender, address(this), pack.price);

        payReferrals(msg.sender, pack, tokenToConsider, isUsdt);

        // add logic to distribute nfts here
        sendNFTs(msg.sender, _packId);
        packBought[_packId] = packBoughts.add(1);
        emit BuyPackEvent(
            msg.sender,
            _packId,
            usersMap[msg.sender].businessIncome,
            block.timestamp
        );
    }

    function addNewPack(
        uint256 id,
        uint256 _price,
        uint256 _nfts,
        uint256 _sportId,
        uint256 _buyLimit
    ) external onlyOwner {
        require(packsMap[id].price == 0, 'Pack already exist with id');
        packsMap[id] = PackStruct({
            id: id,
            price: _price,
            nfts: _nfts,
            sportId: _sportId,
            buyLimit: _buyLimit
        });
    }

    function updatePack(
        uint256 id,
        uint256 _price,
        uint256 _nfts,
        uint256 _sportId,
        uint256 _buyLimit
    ) external onlyOwner {
        require(packsMap[id].price != 0, 'Pack not exist');
        packsMap[id] = PackStruct({
            id: id,
            price: _price,
            nfts: _nfts,
            sportId: _sportId,
            buyLimit: _buyLimit
        });
    }

    function claimIncome(bool isUsdt) external payable {
        uint256 amount = deposit[msg.sender];
        if (!isUsdt) {
            amount = depositOfCubix[msg.sender];
        }
        require(amount > 0, 'No Deposit found for this user');
        ERC20 tokenToConsider = usdt;
        if (!isUsdt) {
            tokenToConsider = cubixToken;
        }
        tokenToConsider.transfer(msg.sender, amount);
        
        if (!isUsdt) {
            depositOfCubix[msg.sender] = 0;
        } else {
            deposit[msg.sender] = 0;
        }
        emit ClaimEvent(msg.sender, amount, block.timestamp);
    }
}