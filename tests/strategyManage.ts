import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {
  
    const [account1, account2] = await ethers.getSigners();

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address,account2.address);

    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚

    const _StrategyManage = await ethers.getContractFactory("StrategyManage");
    const StrategyManage = await _StrategyManage.deploy();

    return { account1, account2,ArcGovernance,StrategyManage};
  }


  describe("🌟 ArcGuarder SetGovernance 🌟", function () {

    it("✨Account1 SetGovernance should be success ✨",async()=>{
      const { StrategyManage,ArcGovernance} = await loadFixture(deployLockFixture);

      await StrategyManage.setGovernance(ArcGovernance.address);
      const addr = await StrategyManage.governance();

      expect(addr).to.be.equal(ArcGovernance.address);
    
    })
    it("✨Account2 SetGovernance should be error ✨",async()=>{
      const { StrategyManage,ArcGovernance,account2} = await loadFixture(deployLockFixture);
      await expect(StrategyManage.connect(account2).setGovernance(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')
    })

  });

  describe("🌟 AddStrategist and DeleteStrategist🌟", function () {

    it("✨Account1 AddStrategist should be success ✨",async()=>{
      const { StrategyManage,ArcGovernance,account2} = await loadFixture(deployLockFixture);

      StrategyManage.addStrategist(ArcGovernance.address);
      
      expect(await StrategyManage.checkAccess(ArcGovernance.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);


      StrategyManage.deleteStrategist(ArcGovernance.address);
      expect(await StrategyManage.checkAccess(ArcGovernance.address)).to.be.equal(false);

    })

    it("✨Account2 AddS trategist should be error ✨",async()=>{
      const { StrategyManage,ArcGovernance,account2} = await loadFixture(deployLockFixture);

      await expect(StrategyManage.connect(account2).addStrategist(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')

    })


  });


});
