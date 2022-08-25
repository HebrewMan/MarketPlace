import { ethers } from "hardhat";

async function main() {

  const Factory = await ethers.getContractFactory("TokenAirdropFactory");
  const factory = await Factory.deploy();

  await factory.deployed();

  console.log(`Token Airdrop Factory address is: ${factory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

