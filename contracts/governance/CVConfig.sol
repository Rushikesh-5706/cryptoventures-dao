// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVConfig
 * @notice Stores and manages governance parameters for each proposal risk tier
 * @dev Defines quorum, approval threshold, and timelock delay per proposal type
 */
contract CVConfig {

    /**
     * @notice Governance parameters for a proposal category
     * @dev Percentages are out of 100; timelock is in seconds
     */
    struct TypeConfig {
        uint256 quorum;      /// Minimum % of total voting power that must participate
        uint256 approval;    /// Minimum % of FOR votes required to pass
        uint256 timelock;    /// Delay before execution is allowed (seconds)
    }

    /// @notice Mapping of proposal type → its governance parameters
    mapping(uint8 => TypeConfig) private _configs;

    /**
     * @notice Emitted whenever a proposal type configuration is updated
     * @param pType Proposal category
     * @param quorum Required quorum percentage
     * @param approval Required approval percentage
     * @param timelock Execution delay in seconds
     */
    event ConfigUpdated(uint8 indexed pType, uint256 quorum, uint256 approval, uint256 timelock);

    /**
     * @notice Initializes default governance parameters
     * @dev
     * 0 = High-conviction investments  
     * 1 = Experimental bets  
     * 2 = Operational expenses  
     */
    constructor() {
        _configs[0] = TypeConfig(60, 70, 3 days);   // High-conviction investments
        _configs[1] = TypeConfig(40, 60, 1 days);   // Experimental bets
        _configs[2] = TypeConfig(20, 50, 6 hours);  // Operational spending
    }

    /**
     * @notice Returns the governance parameters for a proposal type
     * @param pType Proposal category identifier
     * @return quorum Percentage of total voting power required
     * @return approval Percentage of FOR votes required
     * @return timelock Execution delay in seconds
     */
    function get(uint8 pType)
        external
        view
        returns (uint256 quorum, uint256 approval, uint256 timelock)
    {
        TypeConfig memory c = _configs[pType];
        return (c.quorum, c.approval, c.timelock);
    }

    /**
     * @notice Updates governance parameters for a proposal type
     * @dev In production this should only be callable by DAO governance
     * @param pType Proposal category
     * @param quorum New quorum percentage
     * @param approval New approval percentage
     * @param timelock New execution delay (seconds)
     */
    function set(
        uint8 pType,
        uint256 quorum,
        uint256 approval,
        uint256 timelock
    ) external {
        _configs[pType] = TypeConfig(quorum, approval, timelock);
        emit ConfigUpdated(pType, quorum, approval, timelock);
    }
}

