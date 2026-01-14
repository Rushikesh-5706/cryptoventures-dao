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

  await roles.grantRole(await roles.PROPOSER_ROLE(), alice.address);
  await roles.grantRole(await roles.EXECUTOR_ROLE(), admin.address);
  await roles.grantRole(await roles.GUARDIAN_ROLE(), admin.address);

  console.log("Roles:", await roles.getAddress());
  console.log("Timelock:", await timelock.getAddress());
  console.log("Treasury:", await treasury.getAddress());
  console.log("Governor:", await gov.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
