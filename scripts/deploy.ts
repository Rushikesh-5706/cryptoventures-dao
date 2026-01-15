import { ethers } from "hardhat";
import fs from "fs";

async function main() {
  const [admin, alice] = await ethers.getSigners();

  const Roles = await ethers.getContractFactory("contracts/access/CVRoles.sol:CVRoles");
  const roles = await Roles.deploy(admin.address);
  await roles.waitForDeployment();

  const Timelock = await ethers.getContractFactory("CVTimelock");
  const timelock = await Timelock.deploy();
  await timelock.waitForDeployment();

  const Config = await ethers.getContractFactory("CVConfig");
  const config = await Config.deploy();
  await config.waitForDeployment();

  const Treasury = await ethers.getContractFactory("contracts/treasury/CVTreasury.sol:CVTreasury");
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

  const data = {
    roles: await roles.getAddress(),
    timelock: await timelock.getAddress(),
    treasury: await treasury.getAddress(),
    governor: await gov.getAddress()
  };

  fs.writeFileSync("deployments/localhost.json", JSON.stringify(data, null, 2));

  console.log("Deployed and saved:", data);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

