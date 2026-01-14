// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVEvents
 * @notice Central event declarations
 */
library CVEvents {
    event Delegated(address indexed from, address indexed to);
    event ProposalCancelled(uint256 indexed id);
}
