// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./types/AccessControlled.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract FutToken is ERC20, ERC20Burnable, Pausable, ERC20Permit, AccessControlled {

    struct Fund {
        address fundAddress;
        uint256 lastWeek;
        uint256 startingBalance;
        mapping (uint256 => uint256) release; // week => amount
    }

    // Funds distribution
    bytes32 public constant PRIVATE_SALE = keccak256("Private Sale");
    bytes32 public constant PUBLIC_SALE = keccak256("Public Sale");
    bytes32 public constant STAKING_REWARDS = keccak256("Staking Rewards Issuance");
    bytes32 public constant GAMING_ISSUANCE = keccak256("Gaming Issuance");
    bytes32 public constant SOCCER_CLUBS = keccak256("Soccer Clubs");
    bytes32 public constant FUTSTER_TEAM = keccak256("Futster Team");
    bytes32 public constant PRE_LAUNCH_FUND = keccak256("Pre-Launch Fund");
    bytes32 public constant ADVISORS = keccak256("Advisors");

    // Address mapping
    mapping (bytes32 => Fund) public funds;

    // Setup
    uint256 startingDate;
    uint256 startingWeek;
        
    constructor(uint256 _startingWeek, address _authority, address _privateSale, address _publicSale, address _stakingRewards, address _gamingIssuance, address _soccerClubs, address _futsterTeam, address _preLaunchTeam, address _advisors) ERC20("Fut Token", "FUT") ERC20Permit("Fut Token") AccessControlled(IAuthority(_authority)) {
        require(_startingWeek > 0, "Starting week must be greater than 0");
        require(_privateSale != address(0), "Private sale address cannot be the zero address");
        require(_publicSale != address(0), "Public sale address cannot be the zero address");
        require(_stakingRewards != address(0), "Staking rewards address cannot be the zero address");
        require(_gamingIssuance != address(0), "Gaming issuance address cannot be the zero address");
        require(_soccerClubs != address(0), "Soccer clubs address cannot be the zero address");
        require(_futsterTeam != address(0), "Futster team address cannot be the zero address");
        require(_preLaunchTeam != address(0), "Pre-launch team address cannot be the zero address");
        require(_advisors != address(0), "Advisors address cannot be the zero address");

        startingDate = block.timestamp;
        startingWeek = _startingWeek;

         // Funds distribution addresses
        funds[PRIVATE_SALE].fundAddress = _privateSale;
        funds[PUBLIC_SALE].fundAddress = _publicSale;
        funds[STAKING_REWARDS].fundAddress = _stakingRewards;
        funds[GAMING_ISSUANCE].fundAddress = _gamingIssuance;
        funds[SOCCER_CLUBS].fundAddress = _soccerClubs;
        funds[FUTSTER_TEAM].fundAddress = _futsterTeam;
        funds[PRE_LAUNCH_FUND].fundAddress = _preLaunchTeam;
        funds[ADVISORS].fundAddress = _advisors;
        
        distributionSetup(); 
    }

    function pause() public onlyGovernor {
        _pause();
    }

    function unpause() public onlyGovernor {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {                
        if (from == funds[PRIVATE_SALE].fundAddress) {
            require(balanceOf(funds[PRIVATE_SALE].fundAddress) >= amount, "FUT: Not enough tokens in private sale fund");
            require(balanceOf(funds[PRIVATE_SALE].fundAddress) - amount >= funds[PRIVATE_SALE].startingBalance - getUnlockedBalance(PRIVATE_SALE, getCurrentWeek()), "Private Sale Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[PUBLIC_SALE].fundAddress) {
            require(balanceOf(funds[PUBLIC_SALE].fundAddress) >= amount, "FUT: Not enough tokens in public sale fund");
            require(balanceOf(funds[PUBLIC_SALE].fundAddress) - amount >= funds[PUBLIC_SALE].startingBalance - getUnlockedBalance(PUBLIC_SALE, getCurrentWeek()), "Public Sale Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[STAKING_REWARDS].fundAddress) {
            require(balanceOf(funds[STAKING_REWARDS].fundAddress) >= amount, "FUT: Not enough tokens in staking rewards fund");
            require(balanceOf(funds[STAKING_REWARDS].fundAddress) - amount >= funds[STAKING_REWARDS].startingBalance - getUnlockedBalance(STAKING_REWARDS, getCurrentWeek()), "Staking Rewards Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[GAMING_ISSUANCE].fundAddress) {
            require(balanceOf(funds[GAMING_ISSUANCE].fundAddress) >= amount, "FUT: Not enough tokens in gaming issuance fund");
            require(balanceOf(funds[GAMING_ISSUANCE].fundAddress) - amount >= funds[GAMING_ISSUANCE].startingBalance - getUnlockedBalance(GAMING_ISSUANCE, getCurrentWeek()), "Gaming Issuance Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[SOCCER_CLUBS].fundAddress) {
            require(balanceOf(funds[SOCCER_CLUBS].fundAddress) >= amount, "FUT: Not enough tokens in soccer clubs fund");
            require(balanceOf(funds[SOCCER_CLUBS].fundAddress) - amount >= funds[SOCCER_CLUBS].startingBalance - getUnlockedBalance(SOCCER_CLUBS, getCurrentWeek()), "Soccer Clubs Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[FUTSTER_TEAM].fundAddress) {
            require(balanceOf(funds[FUTSTER_TEAM].fundAddress) >= amount, "FUT: Not enough tokens in futster team fund");
            require(balanceOf(funds[FUTSTER_TEAM].fundAddress) - amount >= funds[FUTSTER_TEAM].startingBalance - getUnlockedBalance(FUTSTER_TEAM, getCurrentWeek()), "Futster Team Funds: Cannot transfer more than unlocked amount");
        } else if (from == funds[PRE_LAUNCH_FUND].fundAddress) {
            require(balanceOf(funds[PRE_LAUNCH_FUND].fundAddress) >= amount, "FUT: Not enough tokens in pre launch fund");
            require(balanceOf(funds[PRE_LAUNCH_FUND].fundAddress) - amount >= funds[PRE_LAUNCH_FUND].startingBalance - getUnlockedBalance(PRE_LAUNCH_FUND, getCurrentWeek()), "Pre-Launch Fund: Cannot transfer more than unlocked amount");
        } else if (from == funds[ADVISORS].fundAddress) {
            require(balanceOf(funds[ADVISORS].fundAddress) >= amount, "FUT: Not enough tokens in advisors fund");
            require(balanceOf(funds[ADVISORS].fundAddress) - amount >= funds[ADVISORS].startingBalance - getUnlockedBalance(ADVISORS, getCurrentWeek()), "Advisors Funds: Cannot transfer more than unlocked amount");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function getUnlockedBalance(bytes32 _fund, uint256 _week) public view returns (uint256) { 
        if (_week >= funds[_fund].lastWeek) {
            return funds[_fund].release[funds[_fund].lastWeek];
        } else {      
            uint256 unlocked = funds[_fund].release[_week];
            if (unlocked == 0 && _week > 1) {
                return getUnlockedBalance(_fund, _week - 1);
            } else {
                return unlocked;
            }
        }
    }

    function getCurrentUnlockedBalance(bytes32 _fund) public view returns (uint256) {        
        uint256 currentWeek = getCurrentWeek();
        uint256 unlocked = funds[_fund].release[currentWeek];
      
        if (unlocked == 0 && currentWeek > 1) {
            return getUnlockedBalance(_fund, currentWeek - 1);
        } else {
            return unlocked;
        }
    }

    function getFundAddress(bytes32 _fund) public view returns (address) {
        return funds[_fund].fundAddress;
    }

    function getFundLastWeek(bytes32 _fund) public view returns (uint256) {
        return funds[_fund].lastWeek;
    }

    function getFundStartingBalance(bytes32 _fund) public view returns (uint256) {
        return funds[_fund].startingBalance;
    }

    function getCurrentWeek() public view returns (uint256) {
        return (block.timestamp - startingDate) / 604800 + startingWeek;
    }

    function setStartingWeek(uint256 _startingWeek) public onlyGovernor {
        require(_startingWeek > 0, "FUT: Starting week must be greater than 0"); 
        startingWeek = _startingWeek;
    }

    function setPrivateSaleAddress(address _address) public {
        require(funds[PRIVATE_SALE].fundAddress == msg.sender, "Only private sale address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[PRIVATE_SALE].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setPublicSaleAddress(address _address) public {
        require(funds[PUBLIC_SALE].fundAddress == msg.sender, "Only public sale address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[PUBLIC_SALE].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setStakingRewardsAddress(address _address) public {
        require(funds[STAKING_REWARDS].fundAddress == msg.sender, "Only staking rewards address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[STAKING_REWARDS].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setGamingIssuanceAddress(address _address) public {
        require(funds[GAMING_ISSUANCE].fundAddress == msg.sender, "Only gaming issuance address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[GAMING_ISSUANCE].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setSoccerClubsAddress(address _address) public {
        require(funds[SOCCER_CLUBS].fundAddress == msg.sender, "Only soccer clubs address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[SOCCER_CLUBS].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setFutsterTeamAddress(address _address) public {
        require(funds[FUTSTER_TEAM].fundAddress == msg.sender, "Only futster team address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[FUTSTER_TEAM].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setPreLaunchFundAddress(address _address) public {
        require(funds[PRE_LAUNCH_FUND].fundAddress == msg.sender, "Only pre-launch fund address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[PRE_LAUNCH_FUND].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function setAdvisorsAddress(address _address) public {
        require(funds[ADVISORS].fundAddress == msg.sender, "Only advisors address can change the address");
        require(_address != address(0), "Address cannot be 0");
        require(funds[PRIVATE_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[PUBLIC_SALE].fundAddress != _address, "Address cannot be the same");
        require(funds[STAKING_REWARDS].fundAddress != _address, "Address cannot be the same");
        require(funds[GAMING_ISSUANCE].fundAddress != _address, "Address cannot be the same");
        require(funds[SOCCER_CLUBS].fundAddress != _address, "Address cannot be the same");
        require(funds[FUTSTER_TEAM].fundAddress != _address, "Address cannot be the same");
        require(funds[PRE_LAUNCH_FUND].fundAddress != _address, "Address cannot be the same");
        require(funds[ADVISORS].fundAddress != _address, "Address cannot be the same");

        funds[ADVISORS].fundAddress = _address;
        transfer(_address, balanceOf(msg.sender));
    }

    function distributionSetup() internal {
       
        // Funds last week changes
        funds[PRIVATE_SALE].lastWeek = 105;
        funds[PUBLIC_SALE].lastWeek = 1;
        funds[STAKING_REWARDS].lastWeek = 257;
        funds[GAMING_ISSUANCE].lastWeek = 289;
        funds[SOCCER_CLUBS].lastWeek = 289;
        funds[FUTSTER_TEAM].lastWeek = 209;
        funds[PRE_LAUNCH_FUND].lastWeek = 209;
        funds[ADVISORS].lastWeek = 157;

        // Funds distribution amounts
        _mint(funds[PRIVATE_SALE].fundAddress, 15_000_000 * 10 ** decimals());
        _mint(funds[PUBLIC_SALE].fundAddress, 33_000_000 * 10 ** decimals());
        _mint(funds[STAKING_REWARDS].fundAddress, 60_000_000 * 10 ** decimals());
        _mint(funds[GAMING_ISSUANCE].fundAddress, 60_000_000 * 10 ** decimals());
        _mint(funds[SOCCER_CLUBS].fundAddress, 36_000_000 * 10 ** decimals());
        _mint(funds[FUTSTER_TEAM].fundAddress, 66_000_000 * 10 ** decimals());
        _mint(funds[PRE_LAUNCH_FUND].fundAddress, 18_000_000 * 10 ** decimals());
        _mint(funds[ADVISORS].fundAddress, 12_000_000 * 10 ** decimals());

        // Starting Balance
        funds[PRIVATE_SALE].startingBalance = 15_000_000 * 10 ** decimals();
        funds[PUBLIC_SALE].startingBalance = 33_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].startingBalance = 60_000_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].startingBalance = 60_000_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].startingBalance = 36_000_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].startingBalance = 66_000_000 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].startingBalance = 18_000_000 * 10 ** decimals();
        funds[ADVISORS].startingBalance = 12_000_000 * 10 ** decimals();

        // PRIVATE_SALE Funds distribution unlock dates
        funds[PRIVATE_SALE].release[1] = 3_000_000 * 10 ** decimals();
        funds[PRIVATE_SALE].release[26] = 6_000_000 * 10 ** decimals();
        funds[PRIVATE_SALE].release[53] = 9_000_000 * 10 ** decimals();
        funds[PRIVATE_SALE].release[79] = 12_000_000 * 10 ** decimals();
        funds[PRIVATE_SALE].release[105] = 15_000_000 * 10 ** decimals();

        // PUBLIC_SALE Funds distribution unlock dates
        funds[PUBLIC_SALE].release[1] = 33_000_000 * 10 ** decimals();

        // STAKING_REWARDS Funds distribution unlock dates
        funds[STAKING_REWARDS].release[26] = 2_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[31] = 4_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[35] = 6_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[39] = 8_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[44] = 10_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[48] = 12_000_000 * 10 ** decimals();

        funds[STAKING_REWARDS].release[53] = 13_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[57] = 15_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[61] = 16_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[66] = 18_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[70] = 19_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[74] = 21_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[79] = 22_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[83] = 24_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[87] = 25_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[92] = 27_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[96] = 28_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[100] = 30_000_000 * 10 ** decimals();

        funds[STAKING_REWARDS].release[105] = 31_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[109] = 32_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[113] = 33_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[118] = 34_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[122] = 35_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[126] = 36_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[131] = 37_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[135] = 38_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[139] = 39_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[144] = 40_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[148] = 41_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[153] = 42_000_000 * 10 ** decimals();

        funds[STAKING_REWARDS].release[157] = 42_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[161] = 43_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[166] = 44_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[170] = 45_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[174] = 45_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[179] = 46_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[183] = 47_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[187] = 48_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[192] = 48_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[196] = 49_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[200] = 50_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[205] = 51_000_000 * 10 ** decimals();

        funds[STAKING_REWARDS].release[209] = 51_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[214] = 52_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[218] = 53_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[222] = 54_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[227] = 54_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[231] = 55_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[235] = 56_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[239] = 57_000_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[244] = 57_750_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[248] = 58_500_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[253] = 59_250_000 * 10 ** decimals();
        funds[STAKING_REWARDS].release[257] = 60_000_000 * 10 ** decimals();

        // GAMING_ISSUANCE Funds distribution unlock dates
        funds[GAMING_ISSUANCE].release[1] = 4_725_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[14] = 9_450_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[26] = 18_900_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[53] = 25_650_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[79] = 32_400_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[105] = 37_125_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[131] = 41_850_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[157] = 45_225_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[183] = 48_600_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[209] = 51_300_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[235] = 54_000_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[261] = 57_000_000 * 10 ** decimals();
        funds[GAMING_ISSUANCE].release[289] = 60_000_000 * 10 ** decimals();

        // SOCCER_CLUBS Funds distribution unlock dates
        funds[SOCCER_CLUBS].release[5] = 1_350_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[9] = 2_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[14] = 4_050_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[18] = 5_400_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[22] = 6_750_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[26] = 8_100_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[31] = 9_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[35] = 10_800_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[39] = 12_150_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[44] = 13_500_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[48] = 14_850_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[53] = 16_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[57] = 16_950_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[61] = 17_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[66] = 18_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[70] = 19_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[74] = 19_950_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[79] = 20_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[83] = 21_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[87] = 22_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[92] = 22_950_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[96] = 23_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[100] = 24_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[105] = 25_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[109] = 25_650_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[113] = 26_550_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[118] = 26_100_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[122] = 27_000_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[126] = 27_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[131] = 27_900_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[135] = 28_350_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[139] = 28_800_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[144] = 29_250_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[148] = 29_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[153] = 30_150_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[157] = 30_600_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[161] = 30_750_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[166] = 30_900_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[170] = 31_050_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[174] = 31_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[179] = 31_350_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[183] = 31_500_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[187] = 31_650_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[192] = 31_800_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[196] = 31_950_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[200] = 32_100_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[205] = 32_250_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[209] = 32_400_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[214] = 32_550_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[218] = 32_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[222] = 32_850_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[227] = 33_000_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[231] = 33_150_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[235] = 33_300_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[239] = 33_450_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[244] = 33_600_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[248] = 33_750_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[253] = 33_900_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[257] = 34_050_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[261] = 34_200_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[266] = 34_500_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[270] = 34_800_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[274] = 35_100_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[279] = 35_400_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[283] = 35_700_000 * 10 ** decimals();
        funds[SOCCER_CLUBS].release[289] = 36_000_000 * 10 ** decimals();

        // FUTSTER_TEAM Funds distribution unlock dates
        funds[FUTSTER_TEAM].release[1] = 13_200_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[26] = 19_800_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[53] = 26_400_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[79] = 33_000_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[105] = 39_600_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[131] = 46_200_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[157] = 52_800_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[183] = 59_400_000 * 10 ** decimals();
        funds[FUTSTER_TEAM].release[209] = 66_000_000 * 10 ** decimals();

        // PRE_LAUNCH_FUND Funds distribution unlock dates
        funds[PRE_LAUNCH_FUND].release[1] = 6_750_000 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[26] = 8_156_250 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[53] = 9_562_500 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[79] = 10_968_750 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[105] = 12_375_000 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[131] = 13_781_250 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[157] = 15_187_500 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[183] = 16_593_750 * 10 ** decimals();
        funds[PRE_LAUNCH_FUND].release[209] = 18_000_000 * 10 ** decimals();

        // ADVISORS Funds distribution unlock dates
        funds[ADVISORS].release[1] = 2_400_000 * 10 ** decimals();
        funds[ADVISORS].release[26] = 3_900_000 * 10 ** decimals();
        funds[ADVISORS].release[53] = 5_400_000 * 10 ** decimals();
        funds[ADVISORS].release[79] = 7_200_000 * 10 ** decimals();
        funds[ADVISORS].release[105] = 8_700_000 * 10 ** decimals();
        funds[ADVISORS].release[131] = 10_500_000 * 10 ** decimals();
        funds[ADVISORS].release[157] = 12_000_000 * 10 ** decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IAuthority.sol";

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract AccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority authority);
    event NewSigner(address signer, uint256 threshold);


    /* ========== STATE VARIABLES ========== */

    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        require(address(_authority) != address(0), "Authority cannot be zero address");
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
	_onlyGovernor();
	_;
    }

    modifier onlyGuardian {
	_onlyGuardian();
	_;
    }

    modifier onlyPolicy {
	_onlyPolicy();
	_;
    }

    modifier onlyVault {
	_onlyVault();
	_;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IAuthority _newAuthority) internal {
        require(authority == IAuthority(address(0)), "AUTHORITY_INITIALIZED");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        require(msg.sender == authority.governor(), "UNAUTHORIZED");
    }

    function _onlyGuardian() internal view {
        require(msg.sender == authority.guardian(), "UNAUTHORIZED");
    }

    function _onlyPolicy() internal view {
        require(msg.sender == authority.policy(), "UNAUTHORIZED");        
    }

    function _onlyVault() internal view {
        require(msg.sender == authority.vault(), "UNAUTHORIZED");                
    }

  
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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