# SECURITY — CryptoVentures DAO

This document outlines the threat model, attacker scenarios, and mitigations for the CryptoVentures DAO governance system.

## Assumptions

- Contracts run on EVM-compatible chain (local Hardhat for evaluation).
- Admin / deployer is a trusted bootstrapping actor only. Long-term control should be through governance.
- Off-chain components (CI, Docker registry, GitHub) are outside on-chain scope.

## High-level threat model

1. **Unauthorized fund withdrawal** — attacker obtains EXECUTOR_ROLE or breaks timelock.
2. **Proposal spam / DoS** — low-value accounts create many proposals to congest governance.
3. **Whale takeover** — a single large stakeholder determines outcomes.
4. **Reentrancy / unexpected external call** — treasury transfers call recipient fallback logic.
5. **Timelock manipulation / early execution** — bypassing the timelock window.
6. **Broken delegation accounting** — double-counting power or losing delegator votes.
7. **Insufficient testing for edge cases** — ties, zero-vote, insufficient quorum scenarios.

## Concrete attacker scenarios and mitigations

### Scenario 1 — Compromise of governance executor (role theft)
**Attacker**: obtains the private key of an executor and calls `execute` on queued proposals to drain funds.

**Mitigations**
- Least-privilege: EXECUTOR_ROLE should be a contract or multisig controlled key (not a single EOA).
- Timelock: queued proposals cannot be executed until timelock expires, allowing detection and guardian action.
- Guardian: dedicated GUARDIAN_ROLE can cancel malicious queued proposals.
- Monitoring & alerts: off-chain monitoring to detect suspicious queueing.

### Scenario 2 — Reentrancy during transferOut
**Attacker**: crafts a recipient contract with fallback that re-enters treasury.

**Mitigations**
- use `nonReentrant` on `transferOut` (already in place).
- Do external effects (call) after state updates: balances reduced before external call (already followed).
- Keep transfer logic minimal. Use `call` and require success.

### Scenario 3 — Whale control
**Attacker**: single large depositor influences votes.

**Mitigations**
- Square-root voting (`votingPower = sqrt(stake)`) reduces effective dominance of whales.
- Multi-tier approval: higher quorum and approval thresholds for high-conviction proposals.
- Delegation and social coordination: community can organize to counter large-stake votes.

### Scenario 4 — Proposal spam & DoS
**Attacker**: creates many proposals to increase gas costs for voters or flood UI.

**Mitigations**
- Minimum stake requirement (`CVSpamGuard.minStake = 1 ether`) to create proposals (configurable).
- Roles: PROPOSER_ROLE gate prevents arbitrary addresses from spamming (role assignment requires admin/governance).
- Off-chain UI filters and indexing to limit displayed proposals.

### Scenario 5 — Timelock bypass / early execution
**Attacker**: finds a path to execute before `timelock` expiry.

**Mitigations**
- Timelock contract enforces `unlockTime` logic and `ready` check.
- Governor checks timelock.ready() before execution.
- Tests include early-execution failure scenarios.

### Scenario 6 — Delegation abuse or double-counting
**Attacker**: delegate accumulates delegated power and votes multiple times.

**Mitigations**
- Each voter can vote only once per proposal using `voted` mapping.
- Delegated power is included only when delegate votes; original delegator's `voted` flag prevents double votes.
- Tests validate delegation flows and ensure no double counting.

## Operational recommendations

- **Role hygiene**: use multisigs for ADMIN / EXECUTOR / GUARDIAN in production.
- **Off-chain monitoring & alerting**: monitor queued proposals and large allocations during timelock.
- **Timelock window**: increase timelocks for very large transfers.
- **Security audit**: Before mainnet deploy, run Slither, MythX/Tenderly checks and a manual audit.
- **Upgradeability**: If adding upgradeability (proxy), ensure initialization guards and storage gaps.

## Responsible disclosure

If you find a vulnerability, please create an issue in the repo and contact the project admin off-chain. Do not publish exploit details until a fix is released.

