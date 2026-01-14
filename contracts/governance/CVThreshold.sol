// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CVThreshold {
    function passed(uint256 forVotes, uint256 againstVotes, uint256 required) internal pure returns (bool) {
        uint256 total = forVotes + againstVotes;
        if (total == 0) return false;
        return (forVotes * 100) / total >= required;
    }
}
