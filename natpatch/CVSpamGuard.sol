// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVSpamGuard
 * @notice Prevents low-stake proposal spam
 */
contract CVSpamGuard {
    uint256 public minStake = 1 ether;
}
