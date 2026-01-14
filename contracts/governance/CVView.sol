// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CVGovernorV2.sol";

contract CVView {
    CVGovernorV2 public gov;

    constructor(address g) {
        gov = CVGovernorV2(g);
    }

    function proposalState(uint256 id) external view returns (CVGovernorV2.ProposalState) {
        return gov.state(id);
    }
}
