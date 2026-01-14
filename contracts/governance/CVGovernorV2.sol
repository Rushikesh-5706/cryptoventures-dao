// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CVStake.sol";
import "./CVDelegationFixed.sol";
import "./CVVotePower.sol";
import "./CVProposalCore.sol";
import "./CVQuorumLogic.sol";
import "./CVConfig.sol";
import "./CVTimelock.sol";
import "../treasury/CVTreasury.sol";
import "../access/CVRoles.sol";

contract CVGovernorV2 is CVStake, CVDelegationFixed, CVProposalCore {
    using CVVotePower for uint256;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;
    uint256 public proposalCount;

    CVConfig public config;
    CVTimelock public timelock;
    CVTreasury public treasury;
    CVRoles public roles;

    event ProposalCreated(uint256 indexed id, uint8 indexed pType, address proposer);
    event VoteCast(uint256 indexed id, address indexed voter, uint256 power, bool support);
    event Queued(uint256 indexed id, uint256 unlockTime);
    event Executed(uint256 indexed id);
    event Cancelled(uint256 indexed id);

    constructor(address payable t, address l, address r, address c) {
        treasury = CVTreasury(t);
        timelock = CVTimelock(l);
        roles = CVRoles(r);
        config = CVConfig(c);
    }

    function totalPower() public view returns (uint256) {
        return totalStake.power();
    }

    function votingPower(address user) public view returns (uint256) {
        uint256 base = stake[user].power();
        address d = delegateOf[user];
        if (d != address(0)) base += stake[d].power();
        return base;
    }

    function createProposal(address target, uint256 amount, uint8 pType) external {
        require(stake[msg.sender] > 0, "No stake");
        require(roles.hasRole(roles.PROPOSER_ROLE(), msg.sender), "No role");

        proposalCount++;
        proposals[proposalCount] = Proposal(
            msg.sender,
            target,
            amount,
            pType,
            block.timestamp,
            block.timestamp + 3 days,
            0,
            0,
            false,
            false,
            false
        );

        emit ProposalCreated(proposalCount, pType, msg.sender);
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.start && block.timestamp <= p.end, "Closed");
        require(!voted[id][msg.sender], "Voted");

        uint256 power = votingPower(msg.sender);
        require(power > 0, "No power");

        if (support) p.forVotes += power;
        else p.againstVotes += power;

        voted[id][msg.sender] = true;
        emit VoteCast(id, msg.sender, power, support);
    }

    function state(uint256 id) public view returns (ProposalState) {
        Proposal storage p = proposals[id];
        if (p.cancelled) return ProposalState.Defeated;
        if (p.executed) return ProposalState.Executed;
        if (block.timestamp < p.start) return ProposalState.Pending;
        if (block.timestamp <= p.end) return ProposalState.Active;
        if (p.queued) return ProposalState.Queued;

        (uint256 q, uint256 a, ) = config.get(p.pType);

        bool quorumOk = CVQuorumLogic.quorum(p.forVotes + p.againstVotes, totalPower(), q);
        bool approvalOk = CVQuorumLogic.approval(p.forVotes, p.againstVotes, a);

        if (quorumOk && approvalOk) return ProposalState.Queued;
        return ProposalState.Defeated;
    }

    function allocate(uint256 fund, uint256 amount) external {
        require(roles.hasRole(roles.EXECUTOR_ROLE(), msg.sender), "Not executor");
        treasury.allocate(CVTreasury.FundType(fund), amount);
    }

    function queue(uint256 id) external {
        require(state(id) == ProposalState.Queued, "Not approved");
        Proposal storage p = proposals[id];
        require(!p.queued, "Queued");

        (, , uint256 delay) = config.get(p.pType);
        timelock.queue(id, delay);
        p.queued = true;
        emit Queued(id, block.timestamp + delay);
    }

    function cancel(uint256 id) external {
        require(roles.hasRole(roles.GUARDIAN_ROLE(), msg.sender), "No guardian");
        proposals[id].cancelled = true;
        timelock.cancel(id);
        emit Cancelled(id);
    }

    function execute(uint256 id) external {
        require(roles.hasRole(roles.EXECUTOR_ROLE(), msg.sender), "No executor");
        require(timelock.ready(id), "Locked");

        Proposal storage p = proposals[id];
        require(!p.executed, "Done");
        require(!p.cancelled, "Cancelled");

        p.executed = true;
        treasury.transferOut(CVTreasury.FundType(p.pType), payable(p.target), p.amount);
        emit Executed(id);
    }
}
