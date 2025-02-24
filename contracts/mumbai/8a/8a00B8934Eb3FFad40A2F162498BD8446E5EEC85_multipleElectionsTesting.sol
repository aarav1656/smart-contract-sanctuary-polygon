/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 < 0.9.0;
contract multipleElectionsTesting{
    
    address public owner;
    enum Phase {reg,voting,done}
    Phase state;
    struct Election{
        string eid;
        string ename;
        string edesc;
        Candidate cands;
        mapping(address=>Voter) voters;
        Phase st;
        string winner;
    }
    struct Candidate{
        string[] cname;
        string[] cdesc;
        string[] candid;
        uint[] votecount;
    }
    struct Voter{
        bool voted;
        uint vote;
        bool isRegistered;
    }
    mapping(string=>Election) public elections;
    mapping (string=>Candidate) candidates;
    modifier OwnerOnly(){
        require(msg.sender == owner);       
        _;
    }
    modifier ValidState(Phase x){
        require(state==x);
        _;
    }
    string [] electionNames; 
    string [] electionDesc;
    constructor() {
        owner=msg.sender;
        state=Phase.reg;
    } 
    mapping(string => uint) forCandidateIds;
    function changeState(string memory _eid,Phase x) OwnerOnly public {
        elections[_eid].st = x;
    }
    function addElection(string memory _eid,string memory _ename,string memory _edesc , string[] memory _candidates,string [] memory _candidatesId , string[] memory _candidateDesc) public OwnerOnly {
        require(elections[_eid].st==Phase.reg);
        elections[_eid].eid=_eid;
        elections[_eid].ename=_ename;
        elections[_eid].edesc=_edesc;
        for(uint i=0;i<_candidates.length;i++){
            elections[_eid].cands.cname.push(_candidates[i]);
            elections[_eid].cands.candid.push(_candidatesId[i]);
            elections[_eid].cands.cdesc.push(_candidateDesc[i]);
            forCandidateIds[_candidatesId[i]]=i;
            }
        electionNames.push(_ename);
        electionDesc.push(_edesc);
    }
    // function voterRegistration(string memory _eid,address[] memory voter) public  {
    //     require(elections[_eid].st==Phase.reg);
    //     for(uint i=0;i<voter.length;i++){
    //         elections[_eid].voters[voter[i]].isRegistered=true;
    //     }
    // }
    function vote(string memory _eid,string memory _cid) public{
        require(elections[_eid].st==Phase.voting);
        // require(elections[_eid].voters[msg.sender].isRegistered);
        require(!elections[_eid].voters[msg.sender].voted);
        for(uint i=0;i<elections[_eid].cands.candid.length;i++){
            elections[_eid].cands.votecount.push(0);
        }
        elections[_eid].voters[msg.sender].vote=forCandidateIds[_cid];
        elections[_eid].cands.votecount[forCandidateIds[_cid]]+=1;
        elections[_eid].voters[msg.sender].voted=true;
    }
    function getvotecount(string memory _eid,string memory _cid) public view returns(uint) {
        return elections[_eid].cands.votecount[forCandidateIds[_cid]];
    }
    function getALlElections() public view returns(string[] memory , string [] memory ){
        return (electionNames,electionDesc);
    }
    function getCandidatesOfElection(string memory _eid) public view returns (string[] memory,string[] memory){
      string[] memory name = new string[](elections[_eid].cands.cname.length);
      string[] memory id = new string[](elections[_eid].cands.candid.length);
      for (uint i = 0; i < elections[_eid].cands.candid.length; i++) {
          name[i] = elections[_eid].cands.cname[i];
          id[i]=elections[_eid].cands.candid[i];
      }
      return (name,id);
    }
    function winningProposal(string memory _eid) public returns (string memory){
        require(elections[_eid].st==Phase.done);
        uint winningVoteCount = 0;
        for (uint i = 0; i < elections[_eid].cands.candid.length; i++) {
            if (elections[_eid].cands.votecount[i] > winningVoteCount) {}
                winningVoteCount = elections[_eid].cands.votecount[i];
                elections[_eid].winner = elections[_eid].cands.cname[i];
        }
        return(elections[_eid].winner);
    }
    function getWinner(string memory _eid) public view returns(string memory){
        require(elections[_eid].st==Phase.done);
        return elections[_eid].winner;
    }
}