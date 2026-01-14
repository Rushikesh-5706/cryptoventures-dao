// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICVGovernance {
    enum ProposalState { Pending, Active, Defeated, Queued, Executed }
    enum ProposalType { HighConviction, Experimental, Operational }

    function getVotingPower(address user) external view returns (uint256);
    function getProposalState(uint256 proposalId) external view returns (ProposalState);
}
