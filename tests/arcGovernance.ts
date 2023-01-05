import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {
  
    const [account1, account2] = await ethers.getSigners();

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address,account2.address);

    console.log(ArcGovernance.address,'======')
    return { account1, account2,ArcGovernance};
  }

  describe("🌟 Check addr 🌟", function () {

    it("✨ Master address should be owner ✨",async()=>{
      const { account1,ArcGovernance} = await loadFixture(deployLockFixture);
      const addr = await ArcGovernance.getRoleAddress(1);
      console.log("ArcGovernance:",addr)
      expect(addr).to.be.equal(account1.address);
    })

    it("✨ Cashier address should be otherAccount ✨",async()=>{
      const { account2,ArcGovernance} = await loadFixture(deployLockFixture);
      const addr = await ArcGovernance.getRoleAddress(2);
      console.log("ArcGovernance:",addr)
      expect(addr).to.be.equal(account2.address);
    })

  });


});
