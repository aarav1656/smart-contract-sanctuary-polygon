/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: GPL-3.0
// Solidity语言中，在编译器0.4.17版本之后，可以支持struct结构体的数据返回。
//在返回结构体的情况下，编码需要注意添加“pragma experimental ABIEncoderV2;”，
//需要注意的是结构体中也不能包含string/bytes等不定长数据类型，
//但是返回struct这种形式还处于试验阶段，稳定性安全性有待论证。
pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;

/// @title 委托投票
contract Ballot {
    uint public voteEnd;
    // 这里声明了一个新的复合类型用于稍后的变量
    // 它用来表示一个选民
    struct Voter {
        uint weight; // 计票的权重
        bool voted;  // 若为真，代表该人已投票
        address delegate; // 被委托人
        uint vote;   // 投票提案的索引
    }

    // 提案的类型
    struct Proposal {
        string name;   // 简称（最长32个字节）
        uint voteCount; // 得票数
    }

    address public chairperson;

    // 这声明了一个状态变量，为每个可能的地址存储一个 `Voter`。
    mapping(address => Voter) public voters;

    // 一个 `Proposal` 结构类型的动态数组
    Proposal[] public proposals;

    /// 为 `proposalNames` 中的每个提案，创建一个新的（投票）表决
    
    //修改，将候选人的名称修改为字符串数组
    //  constructor(string[] memory proposalNames) 
    constructor( uint _voteTime) {
        voteEnd = block.timestamp+ _voteTime;
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        //对于提供的每个提案名称，
        //创建一个新的 Proposal 对象并把它添加到数组的末尾。
        // for (uint i = 0; i < proposalNames.length; i++) {
        //     // `Proposal({...})` 创建一个临时 Proposal 对象，
        //     // `proposals.push(...)` 将其添加到 `proposals` 的末尾
        //     proposals.push(Proposal({
        //         name: proposalNames[i],
        //         voteCount: 0
        //     }));
        // }
    }
    // 添加候选人，Proposal对象。将其从构造函数中分离出来，
    // 我们可以进行随意的添加候选人，而不是只在部署合约的时候指定
    function addProposals(string[] memory proposalNames) public{
         
         require(
             msg.sender == chairperson,
             "Only chairpersion can add proposals!"
             );
             
         for(uint i=0;i<proposalNames.length;i++){

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
         }
    }

    // 授权 `voter` 对这个（投票）表决进行投票
    // 只有 `chairperson` 可以调用该函数。
    
    function giveRightToVote(address voter) public {
        // 若 `require` 的第一个参数的计算结果为 `false`，
        // 则终止执行，撤销所有对状态和以太币余额的改动。
        // 在旧版的 EVM 中这曾经会消耗所有 gas，但现在不会了。
        // 使用 require 来检查函数是否被正确地调用，是一个好习惯。
        // 你也可以在 require 的第二个参数中提供一个对错误情况的解释。
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(
            voters[voter].weight == 0,
            // 新增提示："The voter has been given right!"
            "The voter has been given right!"
        );
        require(
             block.timestamp<voteEnd,
             "time is over"
             );
        voters[voter].weight = 1;
        
    }

    /// 把你的投票委托到投票者 `to`。
    function delegate(address to) public {
        // 传引用
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // 委托是可以传递的，只要被委托者 `to` 也设置了委托。
        // 一般来说，这种循环委托是危险的。因为，如果传递的链条太长，
        // 则可能需消耗的gas要多于区块中剩余的（大于区块设置的gasLimit），
        // 这种情况下，委托不会被执行。
        // 而在另一些情况下，如果形成闭环，则会让合约完全卡住。
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // 不允许闭环委托
            require(to != msg.sender, "Found loop in delegation.");
        }

        // `sender` 是一个引用, 相当于对 `voters[msg.sender].voted` 进行修改
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // 若被委托者已经投过票了，直接增加得票数
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 若被委托者还没投票，增加委托者的权重
            delegate_.weight += sender.weight;
        }
    }

    /// 把你的票(包括委托给你的票)，
    /// 投给提案 `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev 结合之前所有的投票，计算出最终胜出的提案
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // 调用 winningProposal() 函数以获取提案数组中获胜者的索引，并以此返回获胜者的名称
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
        //修改 加上得票总数
        //voteCount_ = proposals[winningProposal()].voteCount;
    }
}