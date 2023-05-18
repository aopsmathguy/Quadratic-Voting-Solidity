// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {

    struct Voter {
        int votesLeft; // weight is accumulated by delegation
        bool recievedVotes;  // if true, that person already recievedVotes
        int[] votes;   // votes to each proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        int voteCount; // number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) private voters;

    Proposal[] public proposals;

    int initialVotes;
    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(string[] memory proposalNames, int iv) {
        chairperson = msg.sender;
        initialVotes = iv;
        voters[chairperson] = Voter({
            votesLeft : initialVotes,
            recievedVotes : true,
            votes : new int[](proposalNames.length)
        });

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveVotes(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].recievedVotes,
            "The voter already recieved votes."
        );
        require(voters[voter].votesLeft == 0);
        voters[voter] = Voter({
            votesLeft : initialVotes,
            recievedVotes : true,
            votes : new int[](proposals.length)
        });
    }

    /**
     * @dev Give your votes array (including votes delegated to you) to all proposals.
     * @param votesAll votes array
     */
    function voteAll(int[] calldata votesAll) public {
        Voter storage sender = voters[msg.sender];
        require(votesAll.length == proposals.length, "votes array length needs to be equal to proposals array length");
        int totalCost = 0;
        for(uint i = 0; i < votesAll.length; i++){
            totalCost += votesAll[i] ** 2;
        }
        require(totalCost <= initialVotes, "not enough votes");
        sender.votesLeft = initialVotes - totalCost;
        for(uint i = 0; i < votesAll.length; i++){
            proposals[i].voteCount += votesAll[i] - sender.votes[i];
            sender.votes[i] = votesAll[i];
        }
    }
    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal, int votes) public {
        Voter storage sender = voters[msg.sender];
        require(sender.votesLeft + sender.votes[proposal] ** 2 >= votes ** 2, "Not enough votes.");

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.                         
        proposals[proposal].voteCount += votes - sender.votes[proposal];
        sender.votesLeft += sender.votes[proposal] ** 2 - votes ** 2;
        sender.votes[proposal] = votes;
    }
    /** 
     * @dev returns the votes remaining
     * @return votesRemaining the number of votes the sender has left.
     */
    function getVotesRemaining() public view
            returns (int votesRemaining)
    {
        Voter storage sender = voters[msg.sender];
        votesRemaining = sender.votesLeft;
    }
    function getVotes() public view 
            returns (int[] memory votes)
    {
        Voter storage sender = voters[msg.sender];
        votes = sender.votes;
    }
    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        int winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}