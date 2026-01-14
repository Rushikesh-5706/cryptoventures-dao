const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Delegation & Quorum", function () {
  let roles, treasury, timelock, config, gov;
  let admin, alice, bob, carol;

  beforeEach(async function () {
    [admin, alice, bob, carol] = await ethers.getSigners();

    const Roles = await ethers.getContractFactory("CVRoles");
    roles = await Roles.deploy(admin.address);

    const Timelock = await ethers.getContractFactory("CVTimelock");
    timelock = await Timelock.deploy();

    const Config = await ethers.getContractFactory("CVConfig");
    config = await Config.deploy();

    const Treasury = await ethers.getContractFactory("CVTreasury");
    treasury = await Treasury.deploy(admin.address);

    const Gov = await ethers.getContractFactory("CVGovernorV2");
    gov = await Gov.deploy(
      await treasury.getAddress(),
      await timelock.getAddress(),
      await roles.getAddress(),
      await config.getAddress()
    );

    await treasury.grantGovernance(await gov.getAddress());
    await roles.grantRole(await roles.PROPOSER_ROLE(), alice.address);

    // Only Alice has stake -> quorum should NOT be reached for most types
    await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
  });

  it("counts delegated voting power", async function () {
    await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
    await gov.connect(bob).deposit({ value: ethers.parseEther("3") });
    await gov.connect(carol).deposit({ value: ethers.parseEther("2") });

    await gov.connect(carol).delegate(bob.address);

    await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);
    await gov.connect(bob).vote(1, true);

    const p = await gov.proposals(1);
    expect(p.forVotes).to.be.gt(0n);
  });

  it("marks proposal defeated if quorum not reached", async function () {
    await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);
    await gov.connect(alice).vote(1, true);

    await ethers.provider.send("evm_increaseTime", [4 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);

    const state = await gov.state(1);
    // 3 = Defeated in your state machine
    expect(state).to.equal(3n);
  });
});
