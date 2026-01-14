// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVProposalState
 * @notice Computes proposal state from voting data
 */
library CVProposalState {

    function state(
        bool executed,
        uint256 start,
        uint256 end,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalPower,
        uint256 quorum,
        uint256 approval
    ) internal view returns (uint8) {
        if (executed) return 4;
        if (block.timestamp < start) return 0;
        if (block.timestamp <= end) return 1;

        uint256 participation = (forVotes + againstVotes) * 100 / totalPower;
        if (participation < quorum) return 2;

        uint256 yes = forVotes * 100 / (forVotes + againstVotes);
        if (yes < approval) return 2;

        return 3;
    }
}
