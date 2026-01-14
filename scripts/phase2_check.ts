import { ethers } from "hardhat";

async function main() {
  const [admin, alice, bob] = await ethers.getSigners();

  const Roles = await ethers.getContractFactory("CVRoles");
  const roles = await Roles.deploy(admin.address);
  await roles.waitForDeployment();

  const Timelock = await ethers.getContractFactory("CVTimelock");
  const timelock = await Timelock.deploy();
  await timelock.waitForDeployment();

  const Config = await ethers.getContractFactory("CVConfig");
  const config = await Config.deploy();
  await config.waitForDeployment();

  const Treasury = await ethers.getContractFactory("CVTreasury");
  const treasury = await Treasury.deploy(admin.address);
  await treasury.waitForDeployment();

  const Gov = await ethers.getContractFactory("CVGovernorV2");
  const gov = await Gov.deploy(
    await treasury.getAddress(),
    await timelock.getAddress(),
    await roles.getAddress(),
    await config.getAddress()
  );
  await gov.waitForDeployment();

  await treasury.grantGovernance(await gov.getAddress());

  await admin.sendTransaction({ to: await treasury.getAddress(), value: ethers.parseEther("20") });

  await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
  await gov.connect(bob).deposit({ value: ethers.parseEther("3") });

  await roles.grantRole(await roles.PROPOSER_ROLE(), alice.address);
  await roles.grantRole(await roles.EXECUTOR_ROLE(), admin.address);
  await roles.grantRole(await roles.GUARDIAN_ROLE(), admin.address);

  await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);

  await gov.connect(alice).vote(1, true);
  await gov.connect(bob).vote(1, true);

  await ethers.provider.send("evm_increaseTime", [4 * 24 * 60 * 60]);
  await ethers.provider.send("evm_mine", []);

  await gov.allocate(2, ethers.parseEther("1"));

  await gov.queue(1);

  await ethers.provider.send("evm_increaseTime", [7 * 60 * 60]);
  await ethers.provider.send("evm_mine", []);

  await gov.execute(1);

  const bal = await ethers.provider.getBalance(bob.address);

  console.log("Bob received ETH:", ethers.formatEther(bal));
  console.log("Proposal state:", await gov.state(1));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
