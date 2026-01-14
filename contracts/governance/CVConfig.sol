// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CVConfig {
    struct TypeConfig {
        uint256 quorum;
        uint256 approval;
        uint256 timelock;
    }

    mapping(uint8 => TypeConfig) private _configs;

    constructor() {
        _configs[0] = TypeConfig(30, 60, 3 days);     // HighConviction
        _configs[1] = TypeConfig(20, 50, 1 days);    // Experimental
        _configs[2] = TypeConfig(10, 40, 6 hours);   // Operational
    }

    function get(uint8 pType) external view returns (uint256, uint256, uint256) {
        TypeConfig memory c = _configs[pType];
        return (c.quorum, c.approval, c.timelock);
    }
}
