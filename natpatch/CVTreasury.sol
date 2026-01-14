// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CVTreasury
 * @notice Holds and segregates DAO funds across risk-based investment tiers
 * @dev All fund movement is governed by CVGovernor via GOVERNANCE_ROLE
 */
contract CVTreasury is AccessControl, ReentrancyGuard {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /**
     * @notice Treasury fund categories
     * @dev HighConviction is the main pool
     */
    enum FundType { HighConviction, Experimental, Operational }

    /// @notice ETH balance for each fund type
    mapping(FundType => uint256) public balances;

    /// @notice Emitted when ETH is deposited
    event FundsDeposited(address indexed from, uint256 amount);

    /// @notice Emitted when ETH is allocated between funds
    event FundsAllocated(FundType indexed toFund, uint256 amount);

    /// @notice Emitted when ETH is transferred out
    event FundsTransferred(FundType indexed fund, address indexed to, uint256 amount);

    /**
     * @notice Creates the treasury
     * @param admin DAO administrator
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Accepts ETH into the DAO treasury
     * @dev Funds always enter the HighConviction pool
     */
    receive() external payable {
        balances[FundType.HighConviction] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Grants the governance contract permission to move funds
     * @param gov Governor contract address
     */
    function grantGovernance(address gov) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GOVERNANCE_ROLE, gov);
    }

    /**
     * @notice Moves ETH from the main fund into a sub-fund
     * @param toFund Destination fund
     * @param amount Amount to allocate
     */
    function allocate(FundType toFund, uint256 amount) external onlyRole(GOVERNANCE_ROLE) {
        require(balances[FundType.HighConviction] >= amount, "Insufficient main fund");
        balances[FundType.HighConviction] -= amount;
        balances[toFund] += amount;
        emit FundsAllocated(toFund, amount);
    }

    /**
     * @notice Transfers ETH out of the treasury
     * @param fund Source fund
     * @param to Recipient
     * @param amount Amount to transfer
     */
    function transferOut(
        FundType fund,
        address payable to,
        uint256 amount
    ) external nonReentrant onlyRole(GOVERNANCE_ROLE) {
        require(balances[fund] >= amount, "Insufficient fund");
        balances[fund] -= amount;
        (bool ok,) = to.call{value: amount}("");
        require(ok, "Transfer failed");
        emit FundsTransferred(fund, to, amount);
    }
}
