// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVTimelock {
    mapping(uint256 => uint256) public unlockTime;

    event Queued(uint256 indexed proposalId, uint256 unlockTime);
    event Cancelled(uint256 indexed proposalId);

    function queue(uint256 proposalId, uint256 delay) external {
        unlockTime[proposalId] = block.timestamp + delay;
        emit Queued(proposalId, unlockTime[proposalId]);
    }

    function cancel(uint256 proposalId) external {
        unlockTime[proposalId] = 0;
        emit Cancelled(proposalId);
    }

    function ready(uint256 proposalId) external view returns (bool) {
        return unlockTime[proposalId] > 0 && block.timestamp >= unlockTime[proposalId];
    }
}
