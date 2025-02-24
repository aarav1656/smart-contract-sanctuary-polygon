// SPDX-License-Identifier: MIT


/***
 * 
 * 
 *░██████╗░░█████╗░██╗░░░░░░█████╗░██╗░░██╗██╗░░░██╗  ██╗░░░░░░█████╗░████████╗████████╗░█████╗░
 *██╔════╝░██╔══██╗██║░░░░░██╔══██╗╚██╗██╔╝╚██╗░██╔╝  ██║░░░░░██╔══██╗╚══██╔══╝╚══██╔══╝██╔══██╗
 *██║░░██╗░███████║██║░░░░░███████║░╚███╔╝░░╚████╔╝░  ██║░░░░░██║░░██║░░░██║░░░░░░██║░░░██║░░██║
 *██║░░╚██╗██╔══██║██║░░░░░██╔══██║░██╔██╗░░░╚██╔╝░░  ██║░░░░░██║░░██║░░░██║░░░░░░██║░░░██║░░██║
 *╚██████╔╝██║░░██║███████╗██║░░██║██╔╝╚██╗░░░██║░░░  ███████╗╚█████╔╝░░░██║░░░░░░██║░░░╚█████╔╝
 *░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ╚══════╝░╚════╝░░░░╚═╝░░░░░░╚═╝░░░░╚════╝░
 * 
 *
 * __
 *|__) |  _   _ |   _ |_   _  .  _    |    _  |_ |_  _  _
 *|__) | (_) (_ |( (_ | ) (_| | | )   |__ (_) |_ |_ (-' |  \/
 *                                                         /
 *     
 *
 *     ✅GalaxyLotto Lotto brings the traditional lottery industry 
 *       and improves it to launch it on the Blockchain 
 *       where anyone in the world can join and take advantage of its benefits.
 *
 *     ✅Each person who purchases their ticket will be contributing to bringing
 *       this wonderful ecosystem to life.
 *      
 *      Request more information through our Service Channels.
 *     	-Telegram : https://t.me/galaxylotto
 *      -Web Site : https://galaxylotto.app
 *      
 *      ****************
 *      * GALAXY LOTTO *
 *      ****************
 *
 *
 *
 */

pragma solidity ^0.8.11;


interface IERC20 {
   
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}

contract GalaxyLotto {
    address payable public ownerAddress;

    //lotto contract
    IERC20 busd;
    uint256 public lastId = 1;
    uint256 public nftId = 1;

    //Nft contract
    uint256 public globalAmount = 0;
    uint256 nftBuyAmount = 50*1e6;
    uint256 secondNftBuyAmount = 200*1e6;
    uint256 DevEarningsPer = 1000;
    NftMintInterface NftMint;
    uint8 constant BonusLinesCount = 5;
    uint256[BonusLinesCount] public referralBonus = [2000, 1000, 600, 200, 200];
    uint16 constant percentDivider = 10000;
    uint256 public accumulatRoundID = 1;

    uint256[6] public accumulatedAmount = [
        500*1e6,
        200*1e6,
        100*1e6,
        100*1e6,
        100*1e6
    ];

    address[4] public adminsWalletAddress = [
        0xF335560fCaA0e8776B7CA1B11314A1F39d04C313,
        0x271f524CBD28D4638186974C6A934F4b3A230bbA,
        0x160537D74A5cF4Db5406D26a9332d7269feD12F0,
        0x1Ee6Bef4492Ea746A2875E81ac7b5e35485f28C9
    ];

    struct playerStruct {
        uint256 playerId;
        address referral;
        uint256 totalReferralCount;
        uint256 vipReferrals;
        uint256 totalReward;
        bool isUpgraded;
        uint256 levelEarnings;
        mapping(uint256 => uint256) referrals;
    }

    struct PlayerEarningsStruct
    {
        uint256 nft200EarningA;
        uint256 accumulatEdearningsA;
        uint256 directA;
        uint256 indirectA;

        uint256 nft200EarningW;
        uint256 accumulatEdearningsW;
        uint256 directW;
        uint256 indirectW;

        mapping(uint256 => uint256) referralE;
    }

    struct bet {
        uint256 gameId;
        uint256 nftId;
        bool isClaim;
        uint256[6] betsNumber;
        uint256 totalMatchNumber;
    }

    struct PlayerDailyRounds {
        uint256 referrers; // total referrals user has in a particular rounds
        uint256 totalReferralInsecondNft;
    }

    mapping(address => playerStruct) public player;
    mapping(address => PlayerEarningsStruct) public playerEarning;
    mapping(address => uint256) public getBetIdByWalletAddress;
    address public LottoGameAddress;

    mapping(uint256 => mapping(uint256 => address)) public round;
    mapping(address => mapping(uint256 => PlayerDailyRounds)) public plyrRnds_;


    event Register(uint256 playerId,address userAddress,address referral, uint256 time);
    event EarningEvent(uint256 referralAmount,address walletAddress,address referral,uint8 status,uint256 time);
    event ReferralDetails(address user,address referrer,uint256 roundId);

    constructor(address payable _ownerAddress) {
        busd = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        NftMint = NftMintInterface(0xF616117a36df000766c9D0B381cE025377DBeaA3);
        ownerAddress = _ownerAddress;
        player[ownerAddress].playerId = lastId;
        player[ownerAddress].referral = ownerAddress;

        emit Register(lastId, ownerAddress, address(0), block.timestamp);
        lastId++;
    }

    function setLottoGameAddress(address _gameAddress) external
    {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        LottoGameAddress = _gameAddress;     
    }

    function buyFirstNft(address _referral) public payable {
        IERC20(busd).transferFrom(msg.sender, address(this), nftBuyAmount);
        
        _setUpUpline(msg.sender, _referral);
        
        playerStruct storage _playerStruct = player[msg.sender];
        _referral = _playerStruct.referral;
        bool isNew = false;

        if (player[msg.sender].playerId == 0) {
            uint256 _lastId = lastId;
            _playerStruct.playerId = _lastId;
            player[_referral].totalReferralCount++;
            if(player[_referral].totalReferralCount==10)
            {
                playerEarning[_referral].indirectA += player[_referral].levelEarnings;
                player[_referral].levelEarnings = 0;
            }
            lastId++;
            emit Register(_lastId,msg.sender,_referral,block.timestamp);
            isNew = true;
        }

        if (player[_referral].isUpgraded) {
            plyrRnds_[_referral][accumulatRoundID].referrers++;
            emit ReferralDetails(msg.sender,_referral,accumulatRoundID);
            _highestReferrer(_referral);
        }

        globalAmount += 1.25*1e6;
        sendAccumulatedAmount();

        //referral distribution
        _refPayout(msg.sender, nftBuyAmount,isNew);
       
        uint256 DevEarnings = (nftBuyAmount * DevEarningsPer) / percentDivider;
        IERC20(busd).transfer(ownerAddress, DevEarnings);

        IERC20(busd).transfer(LottoGameAddress, 2375*1e4);

        NftMint.mintReward(msg.sender, nftBuyAmount);
    }

    function buySecondNft() public payable {
        IERC20(busd).transferFrom(
            msg.sender,
            address(this),
            secondNftBuyAmount
        );
        require(
            player[msg.sender].playerId>0,
            "You need to buy 50 USDT nft first"
        );
        require(
            !player[msg.sender].isUpgraded,
            "Allready bought this package"
        );
        address _referral = player[msg.sender].referral;
        if (player[_referral].isUpgraded == true ) {
            player[_referral].vipReferrals++;
            if (player[_referral].vipReferrals % 5 > 0) {
                playerEarning[_referral].nft200EarningA += secondNftBuyAmount;
                emit EarningEvent(secondNftBuyAmount,_referral,msg.sender,6, block.timestamp);
            }
            else {
            for (uint256 i = 0; i < 4; i++) {
                IERC20(busd).transfer(adminsWalletAddress[i], 50*1e6);
            }
        }
        }
        else{
            IERC20(busd).transfer(ownerAddress, secondNftBuyAmount);
        }

        NftMint.mintReward(msg.sender, secondNftBuyAmount);

        player[msg.sender].isUpgraded = true;
    }

    function _highestReferrer(address _referrer) private {
        address upline = _referrer;

        if (upline == address(0)) return;

        for (uint8 i = 0; i < 5; i++) {
            if (round[accumulatRoundID][i] == upline) break;

            if (round[accumulatRoundID][i] == address(0)) {
                round[accumulatRoundID][i] = upline;
                break;
            }

            if (
                plyrRnds_[_referrer][accumulatRoundID].referrers >
                plyrRnds_[round[accumulatRoundID][i]][accumulatRoundID]
                    .referrers
            ) {
                for (uint256 j = i + 1; j < 5; j++) {
                    if (round[accumulatRoundID][j] == upline) {
                        for (uint256 k = j; k <= 5; k++) {
                            round[accumulatRoundID][k] = round[
                                accumulatRoundID
                            ][k + 1];
                        }
                        break;
                    }
                }

                for (uint8 l = uint8(5 - 1); l > i; l--) {
                    round[accumulatRoundID][l] = round[accumulatRoundID][l - 1];
                }

                round[accumulatRoundID][i] = upline;

                break;
            }
        }
    }

    function _setUpUpline(address _addr, address _upline) private {
        require(player[_upline].playerId > 0, "Invalid referral");

        if (player[_addr].referral == address(0) && _upline != _addr) {
            player[_addr].referral = _upline;
            player[_addr].totalReferralCount++;
        }
    }

    function _refPayout(address _addr, uint256 _amount,bool isNew) private {
        address up = player[_addr].referral;

        for (uint8 i = 0; i < BonusLinesCount; i++) {
            if (up == address(0)) break;

            uint256 amount = (_amount * referralBonus[i]) / percentDivider;
            if(i==0){
                playerEarning[up].directA += amount;
            }
            else if(i>0 && player[up].totalReferralCount>=10)
            {
                playerEarning[up].indirectA += amount;
            }
            else if(i>0 && player[up].totalReferralCount<10)
            {
                player[up].levelEarnings += amount;
            }
            if(isNew)
            {
                player[up].referrals[i]++;
            }
            playerEarning[up].referralE[i] += amount;
            emit EarningEvent(amount, up, _addr,i, block.timestamp);

            up = player[up].referral;
        }
    }

    function sendAccumulatedAmount() internal {
        if (globalAmount >= 1000*1e6) {
            for (uint256 i = 0; i < 5; i++) {
                if (round[accumulatRoundID][i] != address(0)) {
                    playerEarning[round[accumulatRoundID][i]].accumulatEdearningsA += accumulatedAmount[i];
                    emit EarningEvent(accumulatedAmount[i], round[accumulatRoundID][i], address(0),7, block.timestamp);
                }
            }
            accumulatRoundID++;
            globalAmount = 0;
        }
    }

    function withdraw(uint256 activeId) external 
    {
        require(NftMint.ownerOf(activeId)==msg.sender,"You are not owner of active NFT");
        require((NftMint.getNftMintedDate(activeId)+365 days)>=block.timestamp,"Not active NFT");
        
        PlayerEarningsStruct storage _player = playerEarning[msg.sender];
        uint256 amount = _player.directA+ _player.indirectA + _player.nft200EarningA + _player.accumulatEdearningsA;
        busd.transfer(msg.sender, amount);
        _player.nft200EarningW += _player.nft200EarningA;
        _player.directW += _player.directA;
        _player.indirectW += _player.indirectA;
        _player.accumulatEdearningsW += _player.accumulatEdearningsA;

        _player.directA = _player.indirectA = _player.nft200EarningA = _player.accumulatEdearningsA = 0;

    }


    function setOwnerAddress(address payable _address) public {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        ownerAddress = _address;
    }

    function setNftAmount(uint256 amount) external {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        nftBuyAmount = amount;
    }

    function setAdminsWalletAddress(address walletAddress,uint8 index) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        adminsWalletAddress[index] = walletAddress;
    }

    function getHighestReferrer(uint256 roundId)
        external
        view
        returns (address[] memory _players, uint256[] memory counts)
    {
        _players = new address[](5);
        counts = new uint256[](5);

        for (uint8 i = 0; i < 5; i++) {
            _players[i] = round[roundId][i];
            counts[i] = plyrRnds_[_players[i]][roundId].referrers;
        }
        return (_players, counts);
    }

    function referralEarningInfo(address _addr)
        external
        view
        returns (
            uint256[5] memory referrals,
            uint256[5] memory referralE
        )
    {
        playerStruct storage _player = player[_addr];
        PlayerEarningsStruct storage _playerE = playerEarning[_addr];
        for (uint8 i = 0; i < 5; i++) {
            referrals[i] = _player.referrals[i];
            referralE[i] = _playerE.referralE[i];
        }

        return (referrals,referralE);
    }

    function getUpline(address _addr) external view returns(address)
    {
        return player[_addr].referral;
    }
}

// contract interface
interface NftMintInterface {
    // function definition of the method we want to interact with
    function mintReward(address to, uint256 nftPrice) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getNftMintedDate(uint256 nftId) external view returns (uint256);

    function getNftNftPrice(uint256 nftId) external view returns (uint256);
}