import { ethers } from "hardhat";
import fs from "fs";

async function main() {
  const [admin, alice, bob] = await ethers.getSigners();

  const addresses = JSON.parse(fs.readFileSync("deployments/localhost.json", "utf8"));

  const gov = await ethers.getContractAt("CVGovernorV2", addresses.governor);
  const treasury = await ethers.getContractAt("CVTreasury", addresses.treasury);

  await admin.sendTransaction({ to: addresses.treasury, value: ethers.parseEther("20") });

  await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
  await gov.connect(bob).deposit({ value: ethers.parseEther("3") });

  await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);
  await gov.connect(alice).vote(1, true);
  await gov.connect(bob).vote(1, true);

  console.log("Seeded DAO state");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

