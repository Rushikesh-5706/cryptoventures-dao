const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Timelock & Execution", function () {
  let roles, treasury, timelock, config, gov;
  let admin, alice, bob;

  beforeEach(async function () {
    [admin, alice, bob] = await ethers.getSigners();

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
    await roles.grantRole(await roles.EXECUTOR_ROLE(), admin.address);
    await roles.grantRole(await roles.GUARDIAN_ROLE(), admin.address);

    await admin.sendTransaction({ to: await treasury.getAddress(), value: ethers.parseEther("10") });

    await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
    await gov.connect(bob).deposit({ value: ethers.parseEther("3") });

    await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);
    await gov.connect(alice).vote(1, true);
    await gov.connect(bob).vote(1, true);

    await ethers.provider.send("evm_increaseTime", [4 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);
  });

  it("cannot execute before timelock expires", async function () {
    await gov.queue(1);
    await expect(gov.execute(1)).to.be.reverted;
  });

  it("executes after timelock and transfers ETH", async function () {
    await gov.queue(1);

    await gov.allocate(2, ethers.parseEther("1"));

    await ethers.provider.send("evm_increaseTime", [7 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);

    const before = await ethers.provider.getBalance(bob.address);
    await gov.execute(1);
    const after = await ethers.provider.getBalance(bob.address);

    expect(after).to.be.gt(before);
  });
});
