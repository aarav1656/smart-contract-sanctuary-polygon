/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// File: browser/xen-matic.sol

/**
 *Submitted for verification at BscScan.com on 2022-10-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity 0.8.17;

interface IXEN1{
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IXEN2{
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract GET{
    IXEN1 private constant xen = IXEN1(0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e);

    constructor() {
        xen.approve(msg.sender,~uint256(0));
    }
    
    function claimRank(uint256 term) public {
        xen.claimRank(term);
    }

    function claimMintReward() public {
        xen.claimMintReward();
        selfdestruct(payable(tx.origin));
    }
}
/// @author 捕鲸船社区 加入社区添加微信:Whaler_man 关注推特 @Whaler_DAO
contract GETXEN {
    mapping (address=>mapping (uint256=>address[])) public userContracts;
    IXEN2 private constant xen = IXEN2(0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e);
  //  address private constant whaler = 0xa546dEe1fD598a34573319EaE22D688F827BeC4C;

    function claimRank(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            GET get = new GET();
            get.claimRank(term);
            userContracts[user][term].push(address(get));
        }
    }

    function claimMintReward(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            uint256 count = userContracts[user][term].length;
            address get = userContracts[user][term][count - 1];
            GET(get).claimMintReward();
            address owner = tx.origin;
            uint256 balance = xen.balanceOf(get);
         //   xen.transferFrom(get, whaler, balance * 10 / 100);
            xen.transferFrom(get, owner, balance);
            userContracts[user][term].pop();
        }
    }
}