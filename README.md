# CryptoVentures DAO Governance

CryptoVentures DAO is a decentralized investment protocol that allows ETH holders to collectively manage a shared treasury through on‑chain governance.  
Members stake ETH to gain voting power, propose investments, vote, delegate votes, and securely execute approved proposals through a timelocked treasury.

This system is inspired by production governance models used by protocols like Compound, Aave, and MakerDAO.

---

## Governance Architecture

The DAO is built around four core components:

- **Users (DAO Members)** – Stake ETH, vote, delegate, and create proposals  
- **CVGovernorV2** – Manages proposals, voting, quorum, approval logic  
- **CVTimelock** – Enforces execution delays for security  
- **CVTreasury** – Holds and releases DAO funds  

### Flow of Control

```mermaid
graph TD
    U[User Wallets]
    G[Governor]
    T[Timelock]
    R[Treasury]

    U -->|Stake / Vote / Propose| G
    G -->|Queue Approved Proposal| T
    T -->|After Delay| G
    G -->|Execute| R
    R -->|ETH Transfer| Recipient
```

---

## Proposal Lifecycle

Every proposal follows a strict state machine:

```
Pending → Active → Queued → Executed
                  ↘
                   Defeated
```

- **Pending** – Created but voting not started  
- **Active** – Voting open  
- **Queued** – Approved, waiting in timelock  
- **Executed** – Funds released  
- **Defeated** – Failed quorum or approval  

---

## Roles

| Role | Purpose |
|------|--------|
| Proposer | Can create proposals |
| Executor | Can queue & execute proposals |
| Guardian | Can cancel malicious proposals |

Roles are enforced on‑chain via `CVRoles`.

---

## Setup Instructions
## Dockerized One-Command Local Blockchain (Recommended)

This project includes a prebuilt Docker image that runs a fully configured Hardhat blockchain with funded accounts.  
This avoids all local Hardhat issues and guarantees the same environment used during testing.

### Step A — Start the blockchain

Open a terminal and run:

```bash
docker pull rushi5706/cryptoventures-dao
docker run --rm -p 8545:8545 rushi5706/cryptoventures-dao:latest
```

You should see output like:

```bash
Started HTTP and WebSocket JSON-RPC server at http://0.0.0.0:8545/
Account #0: ...
Account #1: ...
```

Leave this terminal running.

Step B — Verify the blockchain is live

Open a second terminal and run:

```bash
curl -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Expected output:

```bash
{"jsonrpc":"2.0","id":1,"result":"0x7a69"}
```

This confirms the Docker blockchain is working.

Step C — Deploy the DAO

In the project folder:

```bash
cp .env.example .env
npx hardhat run scripts/deploy.ts --network localhost
```

This deploys all governance, treasury, timelock, and role contracts.

Step D — Seed test state

```bash
npx hardhat run scripts/seed.ts --network localhost
```

This creates:

Members

Stakes

Delegations

Proposals

Votes

Step E — Run all tests

```bash
npx hardhat test
```

All tests must pass.


---

### 1️⃣ Install Dependencies

```bash
git clone https://github.com/Rushikesh-5706/cryptoventures-dao.git
cd cryptoventures-dao
npm install
```

---

### 2️⃣ Configure Environment

Copy the example environment:

```bash
cp .env.example .env
```

`.env.example` already contains everything required for local execution.

---

### 3️⃣ Start Local Blockchain

```bash
npx hardhat node
```

---

### 4️⃣ Deploy the DAO

In a new terminal:

```bash
npx hardhat run scripts/deploy.ts --network localhost
```

This deploys:
- CVRoles
- CVTreasury
- CVConfig
- CVTimelock
- CVGovernorV2

---

### 5️⃣ Seed Test Data

```bash
npx hardhat run scripts/seed.ts --network localhost
```

This creates:
- Multiple DAO members
- Stakes
- Sample proposals
- Votes & delegations

---

### 6️⃣ Run the Test Suite

```bash
npx hardhat test
```

All governance, quorum, delegation, timelock, and treasury tests must pass.

---

## Verification Screenshots

### Compile
![Compile](screenshots/1_compile.png)

This shows all Solidity contracts compiling successfully.

---

### Tests
![Tests](screenshots/2_tests.png)

All governance, delegation, timelock, and edge‑case tests passing.

---

### Gas Report
![Gas](screenshots/3_gas.png)

Gas usage for key DAO functions such as proposal creation, voting, and execution.

---

### Docker
![Docker](screenshots/4_docker.png)

DAO running inside a Docker container exposing the Hardhat RPC.

---

## Usage Examples

### Deposit ETH

```solidity
await governor.deposit({ value: ethers.parseEther("10") });
```

---

### Create Proposal

```solidity
await governor.createProposal(
  recipient,
  ethers.parseEther("1"),
  0  // High‑conviction fund
);
```

---

### Vote

```solidity
await governor.vote(1, true);
```

---

### Delegate Voting Power

```solidity
await governor.delegate(alice.address);
```

---

### Queue & Execute

```solidity
await governor.queue(1);
await time.increase(3 * 24 * 3600);
await governor.execute(1);
```

---

## Design Decisions

- **Quadratic voting** reduces whale dominance  
- **Delegation** enables passive members to participate  
- **Timelock** protects against governance attacks  
- **Multi‑fund treasury** separates risk tiers  

---

## Docker

The DAO runs inside a reproducible Docker container exposing port `8545` for RPC access.

---

## Demo

    https://drive.google.com/file/d/1VwERekxw3hSO8TgNAkd6kEXN93T3JNbc/view?usp=sharing

A full walkthrough video demonstrates:
- Deposits
- Proposals
- Voting
- Delegation
- Timelock execution
