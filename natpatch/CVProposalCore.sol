// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVProposalCore
 * @notice Defines the base proposal data model
 */
contract CVProposalCore {

    /**
     * @notice Lifecycle states of a proposal
     */
    enum ProposalState { Pending, Active, Defeated, Queued, Executed }

    /**
     * @notice Proposal metadata and vote tracking
     */
    struct Proposal {
        address proposer;
        address target;
        uint256 amount;
        uint8 pType;
        uint256 start;
        uint256 end;
        uint256 forVotes;
        uint256 againstVotes;
        bool queued;
        bool executed;
        bool cancelled;
    }
}
