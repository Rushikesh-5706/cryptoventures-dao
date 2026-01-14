# Test Coverage Mapping – CryptoVentures DAO

This document maps each core requirement to the test that validates it.

## Governance & Voting
- Stake-based voting power → governance.test.js – "allows staking, voting and proposal approval"
- Whale resistance (sqrt power) → delegation.test.js – "counts delegated voting power"
- Single vote per proposal → governance.test.js – "prevents double voting"
- Voting window enforced → governance.test.js – "rejects votes outside window"

## Delegation
- Delegate voting power → delegation.test.js – "counts delegated voting power"
- Delegation included automatically → delegation.test.js – "counts delegated voting power"

## Quorum & Approval
- Quorum enforcement → delegation.test.js – "marks proposal defeated if quorum not reached"
- Approval threshold → governance.test.js – "allows staking, voting and proposal approval"

## Timelock
- Queue before execute → timelock.test.js – "cannot execute before timelock expires"
- Execute after delay → timelock.test.js – "executes after timelock and transfers ETH"

## Treasury
- Allocation between funds → edgecases.test.js – "fails if treasury lacks funds"
- Transfer out → timelock.test.js – "executes after timelock and transfers ETH"

## Safety
- Guardian cancel → edgecases.test.js – "guardian cancellation blocks execution"
- Prevent double execution → edgecases.test.js – "prevents double execution"
- Zero vote defeated → edgecases.test.js – "zero-vote proposal can never execute"
