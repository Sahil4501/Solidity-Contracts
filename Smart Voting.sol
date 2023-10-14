// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SmartVoting {
    address public admin;
    string public winner;
    string public eventName;
    uint public totalVote;
    bool votingState;

    struct Candidate{
        string name;
        uint code;
        bool registered;
        address candidateAddress;
        uint votes;
    }
    struct Voter{
        bool registered;
        bool voted;
    }

    event success(string msg);
    Candidate[] candidateList;
    mapping(uint=>uint) candidates;
    mapping(address=>Voter) voterList;

    constructor(string memory _eventName){
        admin = msg.sender;
        eventName = _eventName;
        totalVote = 0;
        votingState=false;
    }

    function registerCandidates(string memory _name, uint _code, address _candidateAddress) public {
        require(msg.sender == admin, "Only admin can register Candidate!!");
        require(_candidateAddress != admin, "Admin cannot participate!!");
        require(candidates[_code] == 0, "Candidate already registered");
        Candidate memory candidate = Candidate({
            name: _name,
            code: _code,
            registered: true,
            votes: 0,
            candidateAddress: _candidateAddress
        });
        if(candidateList.length == 0){ //not pushing any candidate on location zero;
            candidateList.push();
        }
        candidates[_code] = candidateList.length;
        candidateList.push(candidate);
        emit success("Candidate registered!!");
    }

    function getAllCandidate() public view returns(Candidate[] memory list){
        return candidateList;
    }

    function whiteListAddress(address _voterAddress) public {
        require(_voterAddress != admin, "Admin cannot vote!!");
        require(msg.sender == admin, "Only admin can whitelist the addresses!!");
        require(voterList[_voterAddress].registered == false, "Voter already registered!!");
        Voter memory voter = Voter({
            registered: true,
            voted: false
        });

        voterList[_voterAddress] = voter;
        emit success("Voter registered!!");
    }
    function votingStatus() public view returns(bool){
        return votingState;
    }
    function startVoting() public {
        require(msg.sender == admin, "Only admin can start voting!!");
        votingState = true;
        emit success("Voting Started!!");
    }
    function stopVoting() public {
        require(msg.sender == admin, "Only admin can stop voting!!");
        votingState = false;
        emit success("Voting stopped!!");
    }
    function putVote(uint _code) public {
        require(votingState == true, "Voting not started yet or ended!!");
        require(msg.sender != admin, "Admin cannot vote!!");
        require(voterList[msg.sender].registered == true, "Voter not registered!!");
        require(voterList[msg.sender].voted == false, "Already voted!!");
        require(candidateList[candidates[_code]].registered == true, "Candidate not registered");

        candidateList[candidates[_code]].votes++;
        voterList[msg.sender].voted =true;

        uint candidateVotes = candidateList[candidates[_code]].votes;

        if(totalVote < candidateVotes){
            totalVote = candidateVotes;
            winner = candidateList[candidates[_code]].name;
        }
        emit success("Voted !!");
        
    }
    function getWinner() public view returns(string memory){
        require(msg.sender == admin, "Only admin can declare winner!!");
        return winner;
    }
}