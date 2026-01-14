// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../access/CVRoles.sol";
import "./CVTimelock.sol";

/**
 * @title CVCancel
 * @notice Allows guardians to cancel queued proposals
 */
contract CVCancel {
    CVRoles public roles;
    CVTimelock public timelock;

    constructor(address r, address t) {
        roles = CVRoles(r);
        timelock = CVTimelock(t);
    }

    function cancel(uint256 id) external {
        require(roles.hasRole(roles.GUARDIAN_ROLE(), msg.sender), "Not guardian");
        timelock.cancel(id);
    }
}
