// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../access/CVRoles.sol";
import "./CVTimelock.sol";

/**
 * @title CVGuardian
 * @notice Emergency governance breaker
 */
contract CVGuardian {
    CVRoles public roles;
    CVTimelock public timelock;

    constructor(address r, address t) {
        roles = CVRoles(r);
        timelock = CVTimelock(t);
    }

    /**
     * @notice Cancels a queued proposal
     */
    function cancel(uint256 id) external {
        require(roles.hasRole(roles.GUARDIAN_ROLE(), msg.sender), "Not guardian");
        timelock.cancel(id);
    }
}
