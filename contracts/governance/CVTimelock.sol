// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVTimelock
 * @notice Enforces mandatory execution delays for approved proposals
 * @dev Prevents immediate fund movement and allows emergency intervention
 */
contract CVTimelock {

    /// @notice Timestamp after which a proposal can be executed
    mapping(uint256 => uint256) public unlockTime;

    /// @notice Tracks cancelled proposals
    mapping(uint256 => bool) public cancelled;

    /**
     * @notice Queues a proposal for delayed execution
     * @dev Called by the Governor after a proposal is approved
     * @param id Proposal identifier
     * @param delay Number of seconds before execution becomes allowed
     */
    function queue(uint256 id, uint256 delay) external {
        require(unlockTime[id] == 0, "Already queued");
        unlockTime[id] = block.timestamp + delay;
    }

    /**
     * @notice Cancels a queued proposal
     * @dev Used by guardian in case of emergency
     * @param id Proposal identifier
     */
    function cancel(uint256 id) external {
        cancelled[id] = true;
    }

    /**
     * @notice Checks if a proposal is ready for execution
     * @param id Proposal identifier
     * @return True if timelock has expired and proposal is not cancelled
     */
    function ready(uint256 id) external view returns (bool) {
        return unlockTime[id] > 0 && block.timestamp >= unlockTime[id] && !cancelled[id];
    }
}

