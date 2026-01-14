// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CVRoles
 * @notice Centralized role registry for DAO governance
 * @dev Enforces separation of proposer, executor, and guardian powers
 */
contract CVRoles is AccessControl {

    /// @notice May create proposals
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    /// @notice May queue and execute approved proposals
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @notice May cancel malicious proposals
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /**
     * @notice Initializes all DAO governance roles
     * @param admin Address receiving all initial roles
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PROPOSER_ROLE, admin);
        _grantRole(EXECUTOR_ROLE, admin);
        _grantRole(GUARDIAN_ROLE, admin);
    }
}
