import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {
  
    const [account1, account2,addr3,addr4,addr5] = await ethers.getSigners();

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address,account2.address);

    console.log(ArcGovernance.address,"============");
    
    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚
    //Need to pass in 3 parameters (vault orders proxy)
    const _StrategyConfig = await ethers.getContractFactory("StrategyConfig");
    const StrategyConfig = await _StrategyConfig.deploy(addr3.address,addr4.address,addr5.address);

    return { account1, account2,addr3,addr4,addr5,ArcGovernance,StrategyConfig};
  }


  describe("🌟 Set functions 🌟", function () {

    it("✨ Check all config params ✨",async()=>{
      const { StrategyConfig,ArcGovernance,account2,addr3,addr4,addr5,} = await loadFixture(deployLockFixture);

      StrategyConfig.setFee(8);
      expect(await StrategyConfig.getFee()).to.be.equal(8);
      expect(await StrategyConfig.getVaultAddr()).to.be.equal(addr3.address);
      expect(await StrategyConfig.getOrdersAddr()).to.be.equal(addr4.address);
      expect(await StrategyConfig.getProxyAddr()).to.be.equal(addr5.address);

    })


    it("✨ Account1 set should be success ✨",async()=>{
      const { StrategyConfig,ArcGovernance,account2} = await loadFixture(deployLockFixture);

      StrategyConfig.setFee(8);
      StrategyConfig.setVaultAddr(ArcGovernance.address);
      StrategyConfig.setOrdersAddr(ArcGovernance.address);
      StrategyConfig.setProxyAddr(ArcGovernance.address);
      
      expect(await StrategyConfig.getVaultAddr()).to.be.equal(ArcGovernance.address);
      expect(await StrategyConfig.getOrdersAddr()).to.be.equal(ArcGovernance.address);
      expect(await StrategyConfig.getProxyAddr()).to.be.equal(ArcGovernance.address);

    })

    it("✨ Account2 set should be error ✨",async()=>{
      const { StrategyConfig,ArcGovernance,account2} = await loadFixture(deployLockFixture);

      await expect(StrategyConfig.connect(account2).setFee(8)).rejectedWith('ArcGuarder:Denied')
      await expect(StrategyConfig.connect(account2).setVaultAddr(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')
      await expect(StrategyConfig.connect(account2).setOrdersAddr(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')
      await expect(StrategyConfig.connect(account2).setProxyAddr(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')

    })

  });


  describe("🌟 Events 🌟", function () {


    it("✨ Should emit an event on UnLock ✨", async function () {
      // const { tokenA,owner,timeLock,lockedTime} = await loadFixture(deployLockFixture);
      //   await timeLock.lock(tokenA.address,1000,lockedTime);

      //   const unlockTime = (await time.latest()) +3600;
      //   await time.increaseTo(unlockTime); 
      //   //UnLock(msg.sender, order.tokenAddr, order.lockAmount);
      //   await expect(timeLock.unlock(0)).to.emit(timeLock, "UnLock")
      //   .withArgs(owner.address,tokenA.address,1000,anyValue); // We accept any value as `when` arg
    });
  });
});
