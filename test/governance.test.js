const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CryptoVentures DAO Governance", function () {
  let roles, treasury, timelock, config, gov;
  let admin, alice, bob;

  beforeEach(async function () {
    [admin, alice, bob] = await ethers.getSigners();

    const Roles = await ethers.getContractFactory("CVRoles");
    roles = await Roles.deploy(admin.address);
    await roles.waitForDeployment();

    const Timelock = await ethers.getContractFactory("CVTimelock");
    timelock = await Timelock.deploy();
    await timelock.waitForDeployment();

    const Config = await ethers.getContractFactory("CVConfig");
    config = await Config.deploy();
    await config.waitForDeployment();

    const Treasury = await ethers.getContractFactory("CVTreasury");
    treasury = await Treasury.deploy(admin.address);
    await treasury.waitForDeployment();

    const Gov = await ethers.getContractFactory("CVGovernorV2");
    gov = await Gov.deploy(
      await treasury.getAddress(),
      await timelock.getAddress(),
      await roles.getAddress(),
      await config.getAddress()
    );
    await gov.waitForDeployment();

    await treasury.grantGovernance(await gov.getAddress());

    await roles.grantRole(await roles.PROPOSER_ROLE(), alice.address);
    await roles.grantRole(await roles.EXECUTOR_ROLE(), admin.address);
    await roles.grantRole(await roles.GUARDIAN_ROLE(), admin.address);
  });

  it("allows staking, voting and proposal approval", async function () {
    await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
    await gov.connect(bob).deposit({ value: ethers.parseEther("3") });

    await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);

    await gov.connect(alice).vote(1, true);
    await gov.connect(bob).vote(1, true);

    const p = await gov.proposals(1);
    expect(p.forVotes).to.be.gt(0n);
  });
});
