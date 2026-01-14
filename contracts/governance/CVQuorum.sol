// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CVQuorum {
    function reached(uint256 votes, uint256 total, uint256 required) internal pure returns (bool) {
        if (total == 0) return false;
        return (votes * 100) / total >= required;
    }
}
