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

/**
 * @title CVGovernorV2
 * @author CryptoVentures DAO
 * @notice Core governance engine of CryptoVentures DAO
 *
 * @dev This contract coordinates:
 * - Proposal creation and lifecycle
 * - Stake-weighted voting with whale resistance
 * - Delegated voting
 * - Quorum and approval logic
 * - Timelock-based execution
 * - Treasury-controlled fund movement
 *
 * This is the single source of truth for governance state.
 */
contract CVGovernorV2 is CVStake, CVDelegationFixed, CVProposalCore {
    using CVVotePower for uint256;

    /// @notice All proposals indexed by ID
    mapping(uint256 => Proposal) public proposals;

    /// @notice Tracks if an address already voted on a proposal
    mapping(uint256 => mapping(address => bool)) public voted;

    /// @notice Total number of proposals created
    uint256 public proposalCount;

    /// @notice Configuration contract defining quorum, approval and timelock per proposal type
    CVConfig public config;

    /// @notice Timelock contract enforcing delayed execution
    CVTimelock public timelock;

    /// @notice Treasury holding DAO funds
    CVTreasury public treasury;

    /// @notice Role manager (proposer, executor, guardian, etc.)
    CVRoles public roles;

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(uint256 indexed id, uint8 indexed pType, address proposer);

    /// @notice Emitted when a vote is cast
    event VoteCast(uint256 indexed id, address indexed voter, uint256 power, bool support);

    /// @notice Emitted when a proposal is queued for execution
    event Queued(uint256 indexed id, uint256 unlockTime);

    /// @notice Emitted when a proposal is executed
    event Executed(uint256 indexed id);

    /// @notice Emitted when a proposal is cancelled by guardian
    event Cancelled(uint256 indexed id);

    /**
     * @param t Treasury address
     * @param l Timelock address
     * @param r Roles contract
     * @param c Config contract
     */
    constructor(address payable t, address l, address r, address c) {
        treasury = CVTreasury(t);
        timelock = CVTimelock(l);
        roles = CVRoles(r);
        config = CVConfig(c);
    }

    /**
     * @notice Returns total DAO voting power
     */
    function totalPower() public view override returns (uint256) {
        return totalStake.power();
    }

    /**
     * @notice Returns effective voting power of a user including delegated stake
     * @param user Address being queried
     */
    function votingPower(address user) public view override returns (uint256) {
        uint256 base = stake[user].power();
        address d = delegateOf[user];
        if (d != address(0)) base += stake[d].power();
        return base;
    }

    /**
     * @notice Creates a new proposal
     * @param target Recipient of funds if executed
     * @param amount ETH amount to transfer
     * @param pType Proposal type (determines quorum, approval, timelock)
     */
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

    /**
     * @notice Casts a vote on a proposal
     * @param id Proposal ID
     * @param support True = For, False = Against
     */
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

    /**
     * @notice Returns current lifecycle state of a proposal
     * @param id Proposal ID
     */
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

    /**
     * @notice Allocates funds to a treasury bucket
     * @param fund Fund type
     * @param amount Amount of ETH
     */
    function allocate(uint256 fund, uint256 amount) external {
        require(roles.hasRole(roles.EXECUTOR_ROLE(), msg.sender), "Not executor");
        treasury.allocate(CVTreasury.FundType(fund), amount);
    }

    /**
     * @notice Queues an approved proposal in the timelock
     * @param id Proposal ID
     */
    function queue(uint256 id) external {
        require(state(id) == ProposalState.Queued, "Not approved");
        Proposal storage p = proposals[id];
        require(!p.queued, "Queued");

        (, , uint256 delay) = config.get(p.pType);
        timelock.queue(id, delay);
        p.queued = true;
        emit Queued(id, block.timestamp + delay);
    }

    /**
     * @notice Cancels a queued proposal (guardian only)
     * @param id Proposal ID
     */
    function cancel(uint256 id) external {
        require(roles.hasRole(roles.GUARDIAN_ROLE(), msg.sender), "No guardian");
        proposals[id].cancelled = true;
        timelock.cancel(id);
        emit Cancelled(id);
    }

    /**
     * @notice Executes a queued proposal after timelock
     * @param id Proposal ID
     */
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

