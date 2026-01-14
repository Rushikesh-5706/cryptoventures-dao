// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CVQuorumLogic {
    function quorum(uint256 votes, uint256 total, uint256 required) internal pure returns (bool) {
        return total > 0 && (votes * 100 / total) >= required;
    }

    function approval(uint256 yes, uint256 no, uint256 required) internal pure returns (bool) {
        uint256 total = yes + no;
        return total > 0 && (yes * 100 / total) >= required;
    }
}
