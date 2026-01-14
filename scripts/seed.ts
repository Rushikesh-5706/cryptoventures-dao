import { ethers } from "hardhat";

async function main() {
  const [admin, alice, bob] = await ethers.getSigners();

  const gov = await ethers.getContractAt("CVGovernorV2", process.env.GOVERNOR!);
  const treasury = await ethers.getContractAt("CVTreasury", process.env.TREASURY!);

  await admin.sendTransaction({ to: treasury.target, value: ethers.parseEther("20") });

  await gov.connect(alice).deposit({ value: ethers.parseEther("5") });
  await gov.connect(bob).deposit({ value: ethers.parseEther("3") });

  await gov.connect(alice).createProposal(bob.address, ethers.parseEther("1"), 2);

  await gov.connect(alice).vote(1, true);
  await gov.connect(bob).vote(1, true);

  console.log("Seeded proposal, votes, and treasury");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
