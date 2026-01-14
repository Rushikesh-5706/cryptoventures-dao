// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CVStake.sol";
import "./CVDelegation.sol";
import "./CVTimelock.sol";
import "../treasury/CVTreasury.sol";
import "../access/CVRoles.sol";

contract CVGovernance is CVStake, CVDelegation {
    enum ProposalType { HighConviction, Experimental, Operational }
    enum ProposalState { Pending, Active, Defeated, Queued, Executed }

    struct Proposal {
        address proposer;
        address target;
        uint256 amount;
        ProposalType pType;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 start;
        uint256 end;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    CVTreasury public treasury;
    CVTimelock public timelock;
    CVRoles public roles;

    event ProposalCreated(uint256 indexed id, address indexed proposer);
    event VoteCast(uint256 indexed id, address indexed voter, bool support);
    event Executed(uint256 indexed id);

    constructor(address payable _treasury, address _timelock, address _roles) {
        treasury = CVTreasury(payable(_treasury));
        timelock = CVTimelock(_timelock);
        roles = CVRoles(_roles);
    }

    function createProposal(address target, uint256 amount, ProposalType pType) external {
        require(stake[msg.sender] > 0, "No stake");
        proposalCount++;
        proposals[proposalCount] = Proposal(
            msg.sender, target, amount, pType, 0, 0, block.timestamp, block.timestamp + 3 days, false
        );
        emit ProposalCreated(proposalCount, msg.sender);
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.start && block.timestamp <= p.end, "Voting closed");
        require(!voted[id][msg.sender], "Already voted");

        uint256 power = stake[msg.sender];
        address del = delegateTo[msg.sender];
        if (del != address(0)) {
            power += stake[del];
        }

        if (support) p.forVotes += power;
        else p.againstVotes += power;

        voted[id][msg.sender] = true;
        emit VoteCast(id, msg.sender, support);
    }

    function queue(uint256 id, uint256 delay) external {
        Proposal storage p = proposals[id];
        require(p.forVotes > p.againstVotes, "Not passed");
        timelock.queue(id, delay);
    }

    function execute(uint256 id) external {
        require(timelock.ready(id), "Not ready");
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        p.executed = true;
        treasury.transferOut(CVTreasury.FundType(uint256(p.pType)), payable(p.target), p.amount);
        emit Executed(id);
    }
}
