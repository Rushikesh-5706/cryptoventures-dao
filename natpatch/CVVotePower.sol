// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CVVotePower
 * @notice Implements anti-whale square-root voting power
 */
library CVVotePower {

    /**
     * @dev Integer square root
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Converts stake into voting power
     */
    function power(uint256 stake) internal pure returns (uint256) {
        return sqrt(stake);
    }
}
