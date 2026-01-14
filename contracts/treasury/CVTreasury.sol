// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CVTreasury is AccessControl, ReentrancyGuard {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    enum FundType { HighConviction, Experimental, Operational }

    mapping(FundType => uint256) public balances;

    event FundsDeposited(address indexed from, uint256 amount);
    event FundsAllocated(FundType indexed toFund, uint256 amount);
    event FundsTransferred(FundType indexed fund, address indexed to, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    receive() external payable {
        balances[FundType.HighConviction] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function grantGovernance(address gov) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GOVERNANCE_ROLE, gov);
    }

    function allocate(FundType toFund, uint256 amount) external onlyRole(GOVERNANCE_ROLE) {
        require(balances[FundType.HighConviction] >= amount, "Insufficient main fund");
        balances[FundType.HighConviction] -= amount;
        balances[toFund] += amount;
        emit FundsAllocated(toFund, amount);
    }

    function transferOut(FundType fund, address payable to, uint256 amount) external nonReentrant onlyRole(GOVERNANCE_ROLE) {
        require(balances[fund] >= amount, "Insufficient fund");
        balances[fund] -= amount;
        (bool ok,) = to.call{value: amount}("");
        require(ok, "Transfer failed");
        emit FundsTransferred(fund, to, amount);
    }
}
