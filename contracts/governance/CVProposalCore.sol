// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVProposalCore {
    enum ProposalState { Pending, Active, Defeated, Queued, Executed }

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
