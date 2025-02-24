//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20_EXTENDED {
    function name() external returns (string memory);

    function decimals() external returns (uint);
}

interface IStaking {
    function stakeByAddressAdmin(
        address _address,
        uint256 _value
    ) external returns (bool);
}

contract PresaleReferralV3Upgradable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    string private tokenName;
    uint256 private tokenDecimals;
    uint256 private tokenSupply;
    address private tokenSeller;
    uint256 private tokenTax;

    address private tokenContract;
    address private stakingContract;
    address private USDContract;

    AggregatorV3Interface private priceFeedOracleAddress;

    uint256 private pricePerUSD;
    uint256 private minContributionUSD;
    bool private isBuyAndStake;
    bool private isPayReferral;
    uint256 private payReferralFee;

    uint256 private totalTokenSold;
    uint256 private totalETHRaised;
    uint256 private totalUSDRaised;

    event TokenPurchased(
        address indexed from,
        uint256 indexed tokenValue,
        uint256 indexed value,
        string currency
    );

    //Referral variables

    uint8 private MAX_REFEREE_BONUS_LEVEL;

    struct Account {
        address payable referrer;
        address payable parent;
        uint256 parentPaidCount;
        address[] referredAddresses;
        uint256 referredCount;
        uint256 totalBusinessETH;
        uint256 totalBusinessUSD;
        uint256 pendingRewardETH;
        uint256 pendingRewardUSD;
        uint256[] rewardClaimedETH;
        uint256[] rewardClaimedUSD;
        uint256[] rewardClaimedTimeStampETH;
        uint256[] rewardClaimedTimeStampUSD;
    }

    event RegisteredReferer(address indexed referee, address indexed referrer);

    event RegisteredDownline(address indexed referee, address indexed referrer);

    event RegisteredParent(
        address indexed referee,
        address indexed referrer,
        address indexed parent
    );

    event RegisterRefererFailed(
        address indexed referee,
        address indexed referrer,
        string indexed reason
    );

    event RegisterPrentFailed(
        address indexed referee,
        address indexed referrer,
        string indexed reason
    );

    event ReferralIncomeGenerated(
        address indexed from,
        address indexed to,
        uint256 indexed amount,
        uint256 level,
        string currency
    );

    event ReferralIncomeClaimed(
        address indexed from,
        uint256 indexed amountETH,
        uint256 indexed amountUSD
    );

    uint256[] private levelRate;
    uint256 private referralBonus;
    uint256 private levelDecimals;
    address payable private defaultReferrer;
    mapping(address => Account) internal accounts;

    uint256 private totalRewardDistributedETH;
    uint256 private totalRewardDistributedUSD;
    uint256 private totalPendingRewardsETH;
    uint256 private totalPendingRewardsUSD;
    uint256 private minReferredCount;
    uint256 private maxReferredCount;

    address payable private adminAddress;
    address private DFMTContract;

    //Reward Info
    address private rewardOwner;
    address private rewardTokenContract;
    uint256 private rewardPerUSD;

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddress || msg.sender == owner(),
            "You are not admin."
        );
        _;
    }

    //Referral Functions

    function getTotalRewardDistributedETH() external view returns (uint256) {
        return totalRewardDistributedETH;
    }

    function getTotalRewardDistributedUSD() external view returns (uint256) {
        return totalRewardDistributedUSD;
    }

    function getMaxBonusLevels() external view returns (uint8) {
        return MAX_REFEREE_BONUS_LEVEL;
    }

    function setMaxBonusLevels(uint8 _value) external onlyAdmin returns (bool) {
        MAX_REFEREE_BONUS_LEVEL = _value;
        return true;
    }

    function getLevelDecimals() external view returns (uint256) {
        return levelDecimals;
    }

    function setLevelDecimals(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        levelDecimals = _value;
        return true;
    }

    function getLevelRefferalBonus() external view returns (uint256) {
        return referralBonus;
    }

    function setLevelRefferalBonus(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        referralBonus = _value;
        return true;
    }

    function getLevelRates() external view returns (uint256[] memory) {
        return levelRate;
    }

    function setLevelRate(
        uint256[] calldata _value
    ) external onlyAdmin returns (bool) {
        levelRate = _value;
        return true;
    }

    function getDefaultReferrer() public view returns (address) {
        return defaultReferrer;
    }

    function setDefaultReferrer(address payable _address) public onlyAdmin {
        defaultReferrer = _address;
    }

    function getMinReferredCount() external view returns (uint256) {
        return minReferredCount;
    }

    function setMinReferredCount(uint256 _value) external onlyAdmin {
        minReferredCount = _value;
    }

    function getMaxReferredCount() external view returns (uint256) {
        return maxReferredCount;
    }

    function setMaxReferredCount(uint256 _value) external onlyAdmin {
        maxReferredCount = _value;
    }

    function sum(uint256[] memory data) internal pure returns (uint256) {
        uint256 S;
        for (uint256 i; i < data.length; i++) {
            S += data[i];
        }
        return S;
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function hasReferrer(address addr) public view returns (bool) {
        return accounts[addr].referrer != address(0);
    }

    function AccountMap(address addr) external view returns (Account memory) {
        return accounts[addr];
    }

    function isCircularReference(
        address referrer,
        address referee
    ) internal view returns (bool) {
        require(referrer != address(0), "Address cannot be 0x0.");
        address parent = referrer;

        for (uint256 i; i < levelRate.length; i++) {
            if (parent == referee) {
                return true;
            }

            parent = accounts[parent].referrer;
        }

        return false;
    }

    function getReferredCount(
        address _address
    ) external view returns (uint256) {
        return _getReferredCount(_address);
    }

    function _getReferredCount(
        address _address
    ) private view returns (uint256 referredCount) {
        referredCount = accounts[_address].referredAddresses.length;
    }

    function _addReferrer(
        address _address,
        address _referrer
    ) private returns (bool) {
        address payable referrer = payable(_referrer);

        if (_referrer != defaultReferrer) {
            require(
                _getReferredCount(_referrer) <= maxReferredCount,
                "Referrer max referred count exceeded. Please choose another referrer."
            );
        }

        if (referrer == address(0)) {
            emit RegisterRefererFailed(
                _address,
                referrer,
                "Referrer cannot be 0x0 address"
            );
            return false;
        } else if (isCircularReference(referrer, _address)) {
            emit RegisterRefererFailed(
                _address,
                referrer,
                "Referee cannot be one of referrer or parent uplines"
            );
            return false;
        } else if (accounts[_address].referrer != address(0)) {
            emit RegisterRefererFailed(
                _address,
                referrer,
                "Address have been registered upline and parent"
            );
            return false;
        }

        Account storage userAccount = accounts[_address];
        Account storage parentAccount = accounts[referrer];

        userAccount.referrer = referrer;

        parentAccount.referredAddresses.push(_address);
        emit RegisteredReferer(_address, referrer);

        return true;
    }

    function _removeReferrer(address _referee) private {
        Account storage refereeAccount = accounts[_referee];
        Account storage referrerAccount = accounts[refereeAccount.referrer];

        refereeAccount.referrer = payable(address(0));

        address[] storage referredAddresses = referrerAccount.referredAddresses;
        uint8 referredLength = uint8(referredAddresses.length);

        for (uint8 i; i < referredLength; i++) {
            if (referredAddresses[i] == _referee) {
                referredAddresses[i] = referredAddresses[referredLength - 1];
                referredAddresses.pop();
                break;
            }
        }
    }

    function _addParent(
        address _address,
        address _parent
    ) private returns (bool) {
        address payable parent = payable(_parent);

        if (parent == address(0)) {
            emit RegisterRefererFailed(
                _address,
                parent,
                "Parent cannot be 0x0 address"
            );
            return false;
        } else if (isCircularReference(parent, _address)) {
            emit RegisterRefererFailed(
                _address,
                parent,
                "parent cannot be one of referrer or parent uplines"
            );
            return false;
        } else if (accounts[_address].parent != address(0)) {
            emit RegisterRefererFailed(
                _address,
                parent,
                "Address have been registered upline"
            );
            return false;
        }

        Account storage userAccount = accounts[_address];

        userAccount.parent = parent;
        emit RegisteredParent(_address, userAccount.referrer, parent);

        return true;
    }

    function ChangeReferrerAdmin(
        address _referee,
        address payable _referrer
    ) external onlyAdmin returns (bool) {
        _removeReferrer(_referee);
        _addReferrer(_referee, _referrer);
        return true;
    }

    function RemoveReferrerAdmin(
        address _referee
    ) external onlyAdmin returns (bool) {
        _removeReferrer(_referee);
        return true;
    }

    function payReferralInETH(
        uint256 value,
        address _referee
    ) private returns (uint256) {
        Account memory userAccount = accounts[_referee];
        uint256 totalReferal;

        for (uint256 i; i < levelRate.length; i++) {
            address payable referrer = userAccount.referrer;
            address payable parent = userAccount.parent;

            Account storage referrerAccount = accounts[userAccount.referrer];
            Account storage parentAccount = accounts[userAccount.parent];

            if (referrer == address(0)) {
                break;
            }

            uint256 c = value.mul(levelRate[i]).div(levelDecimals);

            if (
                referrer != parent &&
                parent != address(0) &&
                userAccount.parentPaidCount == 0 &&
                i == 0
            ) {
                userAccount.parentPaidCount = 1;
                parentAccount.pendingRewardETH += c.div(2);
                c = c.div(2);
            }

            referrerAccount.pendingRewardETH += c;
            referrerAccount.totalBusinessETH += value;
            totalReferal += c;

            emit ReferralIncomeGenerated(_referee, referrer, c, i + 1, "ETH");

            userAccount = referrerAccount;
        }

        totalPendingRewardsETH += totalReferal;
        return totalReferal;
    }

    function payReferralInUSD(
        uint256 value,
        address _referee
    ) private returns (uint256) {
        Account memory userAccount = accounts[_referee];
        uint256 totalReferal;

        for (uint256 i; i < levelRate.length; i++) {
            address payable referrer = userAccount.referrer;
            address payable parent = userAccount.parent;

            Account storage referrerAccount = accounts[userAccount.referrer];
            Account storage parentAccount = accounts[userAccount.parent];

            if (referrer == address(0)) {
                break;
            }

            uint256 c = value.mul(levelRate[i]).div(levelDecimals);

            if (
                referrer != parent &&
                parent != address(0) &&
                userAccount.parentPaidCount == 0 &&
                i == 0
            ) {
                userAccount.parentPaidCount = 1;
                parentAccount.pendingRewardUSD += c.div(2);
                c = c.div(2);
            }

            referrerAccount.pendingRewardUSD += c;
            referrerAccount.totalBusinessUSD += value;
            totalReferal += c;

            emit ReferralIncomeGenerated(_referee, referrer, c, i + 1, "USD");

            userAccount = referrerAccount;
        }

        totalPendingRewardsUSD += totalReferal;
        return totalReferal;
    }

    function getTotalPendingRewardETH() external view returns (uint256) {
        return totalPendingRewardsETH;
    }

    function getTotalPendingRewardUSD() external view returns (uint256) {
        return totalPendingRewardsUSD;
    }

    function withdrawPendingReward() external returns (bool) {
        require(
            _getReferredCount(msg.sender) >= 3,
            "You don't have min no of referees."
        );

        Account storage accountMap = accounts[msg.sender];
        uint256 totalPendingRewardETH = accountMap.pendingRewardETH;
        uint256 totalPendingRewardUSD = accountMap.pendingRewardUSD;

        payable(msg.sender).transfer(totalPendingRewardETH);
        IERC20Upgradeable(USDContract).transfer(
            msg.sender,
            totalPendingRewardUSD
        );

        accountMap.pendingRewardETH = 0;
        accountMap.pendingRewardUSD = 0;

        accountMap.rewardClaimedETH.push(totalPendingRewardETH);
        accountMap.rewardClaimedUSD.push(totalPendingRewardUSD);

        accountMap.rewardClaimedTimeStampETH.push(_getCurrentTime());
        accountMap.rewardClaimedTimeStampUSD.push(_getCurrentTime());

        totalRewardDistributedETH += totalPendingRewardETH;
        totalRewardDistributedUSD += totalPendingRewardUSD;

        totalPendingRewardsETH -= totalPendingRewardETH;
        totalPendingRewardsUSD -= totalPendingRewardUSD;

        emit ReferralIncomeClaimed(
            msg.sender,
            totalPendingRewardETH,
            totalPendingRewardUSD
        );

        return true;
    }

    //Referral Functions END

    // Functions tokenContract

    function getTokenName() external view returns (string memory) {
        return tokenName;
    }

    function getTokenDecimals() external view returns (uint256) {
        return tokenDecimals;
    }

    function getTokenSupply() external view returns (uint256) {
        return tokenSupply;
    }

    function getSeller() external view returns (address) {
        return tokenSeller;
    }

    function getTokenTax() external view returns (uint256) {
        return tokenTax;
    }

    function getTokenContract() external view returns (address) {
        return tokenContract;
    }

    function setTokenContractAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        tokenContract = _address;
        tokenName = IERC20_EXTENDED(_address).name();
        tokenDecimals = IERC20_EXTENDED(_address).decimals();
        tokenSupply = IERC20Upgradeable(_address).totalSupply();

        return true;
    }

    // Functions USDContract

    function getUSDContract() external view returns (address) {
        return USDContract;
    }

    function setUSDContractAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        USDContract = _address;
        return true;
    }

    function getDFMTContract() external view returns (address) {
        return DFMTContract;
    }

    function setDFMTContractAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        DFMTContract = _address;
        return true;
    }

    function getStakingContract() external view returns (address) {
        return stakingContract;
    }

    function setStakingContractAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        stakingContract = _address;
        return true;
    }

    function getRewardTokenContract() external view returns (address) {
        return rewardTokenContract;
    }

    function setrewardTokenContractAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        rewardTokenContract = _address;
        return true;
    }

    function getRewardPerUSD() external view returns (uint256) {
        return rewardPerUSD;
    }

    function setRewardPerUSDAdmin(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        rewardPerUSD = _value;
        return true;
    }

    function getRewardContractOwner() external view returns (address) {
        return rewardOwner;
    }

    function setRewardContractOwner(
        address _address
    ) external onlyAdmin returns (bool) {
        rewardOwner = _address;
        return true;
    }

    // Functions chainlink price feed

    function getpriceFeedOracleAddress() external view returns (address) {
        return address(priceFeedOracleAddress);
    }

    function setpriceFeedOracleAddressAdmin(
        address _address
    ) external onlyAdmin returns (bool) {
        priceFeedOracleAddress = AggregatorV3Interface(_address);
        return true;
    }

    // Functions presale price & sale

    function getPricePerUSD() external view returns (uint256) {
        return pricePerUSD;
    }

    function setPricePerUSDAdmin(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        pricePerUSD = _value;
        return true;
    }

    function getMinContributionUSD() external view returns (uint256) {
        return minContributionUSD;
    }

    function setMinContributionUSDAdmin(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        minContributionUSD = _value;
        return true;
    }

    function isBuyAndStakeEnable() external view returns (bool) {
        return isBuyAndStake;
    }

    function setBuyAndStakeAdmin(bool _bool) external onlyAdmin returns (bool) {
        isBuyAndStake = _bool;
        return true;
    }

    function isPayReferralEnable() external view returns (bool) {
        return isPayReferral;
    }

    function setPayReferralAdmin(bool _bool) external onlyAdmin returns (bool) {
        isPayReferral = _bool;
        return true;
    }

    function getPayReferralFee() external view returns (uint256) {
        return payReferralFee;
    }

    function setPayReferralFeeAdmin(
        uint256 _value
    ) external onlyAdmin returns (bool) {
        payReferralFee = _value;
        return true;
    }

    function getTotalTokenSold() external view returns (uint256) {
        return totalTokenSold;
    }

    function getTotalETHRaised() external view returns (uint256) {
        return totalETHRaised;
    }

    function getTotalUSDRaised() external view returns (uint256) {
        return totalUSDRaised;
    }

    function _getCurrentTime() private view returns (uint256 currentTimeStamp) {
        currentTimeStamp = block.timestamp;
    }

    // Function make this smart contract to receive ethers.

    receive() external payable {
        _BuyWithETH(defaultReferrer, defaultReferrer, msg.sender, msg.value);
    }

    // Function getEthPrice in USD

    function getETH_USDPrice() public view returns (uint256 ETH_USD) {
        (, int ethPrice, , , ) = AggregatorV3Interface(priceFeedOracleAddress)
            .latestRoundData();
        ETH_USD = uint256(ethPrice) * (10 ** 10);
    }

    // Function getMinContibutionValue when buying with eth.

    function getMinContributionETH()
        public
        view
        returns (uint256 minETHRequired)
    {
        uint256 ethPrice = getETH_USDPrice();
        uint256 ratio = ethPrice / minContributionUSD;
        minETHRequired =
            ((1 * 10 ** tokenDecimals) * (10 ** tokenDecimals)) /
            ratio;
    }

    // Function getTokensValue when buy with ETH

    function _getTokensValueETH(
        uint256 _ethValue,
        uint256 _price
    ) private view returns (uint256 tokenValue) {
        uint256 ethPrice = getETH_USDPrice();

        uint256 ethValue = (_ethValue * ethPrice) / (10 ** tokenDecimals);
        tokenValue = ethValue * _price;
        tokenValue = tokenValue / (10 ** tokenDecimals);
    }

    function _BuyWithETH(
        address _referrer,
        address _parent,
        address _address,
        uint256 _value
    ) private {
        uint256 _msgValue = _value;

        require(
            _msgValue >= getMinContributionETH(),
            "ETH Value less then minimum buying eth value."
        );

        uint256 tokenValue = _getTokensValueETH(_msgValue, pricePerUSD);
        uint256 rewardValue = _getTokensValueETH(_msgValue, rewardPerUSD);

        IERC20Upgradeable(rewardTokenContract).transferFrom(
            rewardOwner,
            _address,
            rewardValue
        );

        uint256 payReferralValue = _msgValue.sub(
            _msgValue.mul(payReferralFee).div(100)
        );

        if (!hasReferrer(_address) && _referrer != address(0)) {
            _addReferrer(_address, _referrer);
        }

        if (_referrer != _parent && _referrer != address(0)) {
            _addParent(_address, _parent);
        }

        if (isBuyAndStake) {
            IStaking(stakingContract).stakeByAddressAdmin(_address, tokenValue);
            IERC20Upgradeable(tokenContract).transfer(
                stakingContract,
                tokenValue
            );
        } else {
            IERC20Upgradeable(tokenContract).transfer(_address, tokenValue);
        }

        if (isPayReferral) {
            payReferralInETH(payReferralValue, _address);
        }

        totalTokenSold += tokenValue;
        totalETHRaised += _msgValue;
        emit TokenPurchased(_address, tokenValue, _msgValue, "ETH");
    }

    function _BuyWithUSD(
        address _referrer,
        address _parent,
        address _address,
        uint256 _value,
        string memory _currency
    ) private whenNotPaused {
        require(
            _value >= minContributionUSD.mul(10 ** tokenDecimals),
            "Buying value less then minimum buying value."
        );

        uint256 tokenValue = (_value * pricePerUSD) / 10 ** tokenDecimals;
        uint256 rewardValue = (_value * rewardPerUSD) / 10 ** tokenDecimals;

        IERC20Upgradeable(rewardTokenContract).transferFrom(
            rewardOwner,
            _address,
            rewardValue
        );

        uint256 payReferralValue = _value.sub(
            _value.mul(payReferralFee).div(100)
        );

        if (!hasReferrer(_address) && _referrer != address(0)) {
            _addReferrer(_address, _referrer);
        }

        if (_referrer != _parent && _referrer != address(0)) {
            _addParent(_address, _parent);
        }

        if (isBuyAndStake) {
            IStaking(stakingContract).stakeByAddressAdmin(_address, tokenValue);
            IERC20Upgradeable(tokenContract).transfer(
                stakingContract,
                tokenValue
            );
        } else {
            IERC20Upgradeable(tokenContract).transfer(_address, tokenValue);
        }

        if (isPayReferral) {
            payReferralInUSD(payReferralValue, _address);
        }

        totalTokenSold += tokenValue;
        totalUSDRaised += _value;
        emit TokenPurchased(_address, tokenValue, _value, _currency);
    }

    // Function when someone buy with ETH

    function BuyWithETH(
        address[] calldata _address,
        address[] calldata _referrer,
        address[] calldata _parent,
        uint256[] calldata _value
    ) external payable whenNotPaused {
        uint256 _msgValue = msg.value;
        uint256 _totalMsgValue;
        uint8 length = uint8(_address.length);

        for (uint8 i; i < length; i++) {
            _BuyWithETH(_referrer[i], _parent[i], _address[i], _value[i]);
            _totalMsgValue += _value[i];
        }

        require(
            _totalMsgValue <= _msgValue,
            "Total amount is greater then msg.value."
        );
    }

    function BuyWithUSD(
        address[] calldata _address,
        address[] calldata _referrer,
        address[] calldata _parent,
        uint256[] calldata _value
    ) external whenNotPaused {
        uint8 length = uint8(_address.length);
        uint256 _totalMsgValue;

        for (uint8 i; i < length; i++) {
            _BuyWithUSD(
                _referrer[i],
                _parent[i],
                _address[i],
                _value[i],
                "USDT"
            );

            _totalMsgValue += _value[i];
        }

        IERC20Upgradeable(USDContract).transferFrom(
            msg.sender,
            address(this),
            _totalMsgValue
        );
    }

    function BuyWithDFMT(
        address[] calldata _address,
        address[] calldata _referrer,
        address[] calldata _parent,
        uint256[] calldata _value
    ) external whenNotPaused {
        uint8 length = uint8(_address.length);
        uint256 _totalMsgValue;

        for (uint8 i; i < length; i++) {
            _BuyWithUSD(
                _referrer[i],
                _parent[i],
                _address[i],
                _value[i],
                "DFMT"
            );

            _totalMsgValue += _value[i];
        }

        IERC20Upgradeable(DFMTContract).transferFrom(
            msg.sender,
            address(this),
            _totalMsgValue
        );
    }

    function BuyWithDFMTAdmin(
        address[] calldata _address,
        address[] calldata _referrer,
        address[] calldata _parent,
        uint256[] calldata _value
    ) external whenNotPaused onlyAdmin {
        uint8 length = uint8(_address.length);
        for (uint8 i; i < length; ++i) {
            _BuyWithUSD(
                _referrer[i],
                _parent[i],
                _address[i],
                _value[i],
                "DFMT by Admin"
            );
        }
    }

    function addReferrerAdmin(
        address[] calldata _referee,
        address[] calldata _referrer,
        address[] calldata _parent
    ) external whenNotPaused onlyAdmin {
        uint8 length = uint8(_referee.length);
        for (uint8 i; i < length; ++i) {
            _addReferrer(_referee[i], _referrer[i]);
            _addParent(_referee[i], _parent[i]);
        }
    }

    // Function initialize values or variables.

    function initialize() external initializer {
        priceFeedOracleAddress = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
        USDContract = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        tokenContract = 0x57735E902Acdde3545C1d50A9595fC55361a9036;

        tokenSeller = 0x5978bA97815CF69E37118A5a432560E791b78841;

        pricePerUSD = 3846153846150000000;
        minContributionUSD = 12;

        tokenName = IERC20_EXTENDED(tokenContract).name();
        tokenDecimals = IERC20_EXTENDED(tokenContract).decimals();
        tokenSupply = IERC20Upgradeable(tokenContract).totalSupply();

        isBuyAndStake = true;
        isPayReferral = true;
        payReferralFee = 33;

        //Referral Init

        defaultReferrer = payable(0x5978bA97815CF69E37118A5a432560E791b78841);
        MAX_REFEREE_BONUS_LEVEL = 8;
        levelDecimals = 100;
        referralBonus = 70;
        levelRate = [25, 11, 9, 8, 6, 4, 3, 4];
        minReferredCount = 3;
        maxReferredCount = 6;

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    function pauseAdmin() external onlyAdmin {
        _pause();
    }

    function unpauseAdmin() external onlyAdmin {
        _unpause();
    }

    function changeAdmin(address payable _address) external onlyAdmin {
        adminAddress = _address;
    }

    function getAdminAddress() external view returns (address) {
        return address(adminAddress);
    }

    // Function to with fund from this contract

    function sendNativeFundsAdmin(
        address _address,
        uint256 _value
    ) external onlyAdmin {
        payable(_address).transfer(_value);
    }

    function withdrawAdmin() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokenAdmin(
        address _tokenAddress,
        uint256 _value
    ) external onlyAdmin {
        IERC20Upgradeable(_tokenAddress).transfer(msg.sender, _value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
library SafeMathUpgradeable {
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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