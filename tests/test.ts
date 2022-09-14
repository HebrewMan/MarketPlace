import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";


describe("🏭 Contracts Deployment", function () {

  const allowanceAmount = "1000000000000000000000";

  async function deployLockFixture() {
    
    const lockedTime = 3600;

    const [owner, otherAccount] = await ethers.getSigners();

    const TokenA = await ethers.getContractFactory("Token");
    const tokenA = await TokenA.deploy();
    const tokenB = await TokenA.deploy();

    const TimeLock = await ethers.getContractFactory("TimeLock");
    const timeLock = await TimeLock.deploy();

    await tokenA.approve(timeLock.address,allowanceAmount);
    await tokenB.approve(timeLock.address,allowanceAmount);

    await tokenA.connect(otherAccount).approve(timeLock.address,allowanceAmount);
    await tokenB.connect(otherAccount).approve(timeLock.address,allowanceAmount);

    await tokenA.transfer(otherAccount.address,100000000/2);
    await tokenB.transfer(otherAccount.address,100000000/2);

    return { timeLock,lockedTime, owner, otherAccount ,tokenA,tokenB};
  }

  describe("🌟 Deployment 🌟", function () {

    it("✨ Users balanceOf ✨",async()=>{
      const { tokenA, tokenB ,owner,otherAccount} = await loadFixture(deployLockFixture);
      expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2);
      expect(await tokenB.balanceOf(owner.address)).to.be.equal(100000000/2);
      expect(await tokenA.connect(otherAccount).balanceOf(owner.address)).to.be.equal(100000000/2);
      expect(await tokenB.connect(otherAccount).balanceOf(owner.address)).to.be.equal(100000000/2);
    })

    it("✨ Check token allowance ✨", async()=>{
      const { tokenA, tokenB ,owner,timeLock,otherAccount} = await loadFixture(deployLockFixture);
      expect(await tokenA.allowance(owner.address,timeLock.address)).to.be.equal(allowanceAmount);
      expect(await tokenB.allowance(owner.address,timeLock.address)).to.be.equal(allowanceAmount);
      expect(await tokenA.connect(otherAccount).allowance(owner.address,timeLock.address)).to.be.equal(allowanceAmount);
      expect(await tokenB.connect(otherAccount).allowance(owner.address,timeLock.address)).to.be.equal(allowanceAmount);
    })  

    it("✨ Should set the right owner ✨", async function () {
      const { timeLock, owner } = await loadFixture(deployLockFixture);
      expect(await timeLock.owner()).to.equal(owner.address);
    });

  });

  describe("🌟 Lucks 🌟",()=>{

    it("✨ Order data should be right✨",async()=>{
      const { tokenA,timeLock} = await loadFixture(deployLockFixture);
      await timeLock.lock(tokenA.address,1000,60);
      const res = await timeLock.getOrder(0);
      expect(res.tokenAddr).to.be.equal(tokenA.address);
      expect(res.lockAmount).to.be.equal(1000);
      expect(res.startTime).to.be.equal((await time.latest()));
      expect(res.endTime).to.be.equal((await time.latest())+60);
      expect(res.isClaimed).to.be.equal(false);
    })

    it("✨ One user and one token ✨",async()=>{
      const { tokenA,owner,timeLock} = await loadFixture(deployLockFixture);
      await timeLock.lock(tokenA.address,1000,60);

      expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2-1000);
      expect(await timeLock.getUserOrderLength()).to.be.equal(1);
      expect(await timeLock.getTokensLength()).to.be.equal(1);

      expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(1000);
      expect(await timeLock.containsToken(tokenA.address)).to.be.equal(true);

    })

    it("✨ Two users and Two tokens ✨",async()=>{
      const { tokenA, tokenB ,owner,timeLock,otherAccount} = await loadFixture(deployLockFixture);
      await timeLock.lock(tokenA.address,1000,60);

      expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2-1000);
      expect(await timeLock.getUserOrderLength()).to.be.equal(1);
      expect(await timeLock.getTokensLength()).to.be.equal(1);

      expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(1000);
      expect(await timeLock.containsToken(tokenA.address)).to.be.equal(true);

      await timeLock.lock(tokenA.address,1000,60);

      expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2-2000);
      expect(await timeLock.getUserOrderLength()).to.be.equal(1*2);
      expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(1000*2);

      //user2 actions

      await timeLock.connect(otherAccount).lock(tokenA.address,1000,60);
      await timeLock.connect(otherAccount).lock(tokenB.address,1000,60);

      expect(await tokenA.connect(otherAccount).balanceOf(otherAccount.address)).to.be.equal(100000000/2-1000);
      expect(await tokenB.connect(otherAccount).balanceOf(otherAccount.address)).to.be.equal(100000000/2-1000);

      expect(await timeLock.connect(otherAccount).getUserOrderLength()).to.be.equal(2);
      expect(await timeLock.getTokensLength()).to.be.equal(2);

      expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(1000*3);
      expect(await timeLock.getTokenLockAmounts(tokenB.address)).to.be.equal(1000);
      expect(await timeLock.containsToken(tokenB.address)).to.be.equal(true);

    })
  })

  describe("🌟 Unlocks 🌟", function () {
 
      it("✨ Order does not exist ✨",async ()=>{
        const { timeLock } = await loadFixture(deployLockFixture);
        await expect(timeLock.unlock(0)).to.be.reverted;
      })

      it("✨ Error index ✨",async ()=>{
        const { tokenA,timeLock,lockedTime} = await loadFixture(deployLockFixture);
        await timeLock.lock(tokenA.address,1000,lockedTime);
        await expect(timeLock.unlock(1)).to.be.reverted;
      })

      it("✨ Unlock time not reached ✨",async()=>{
        const { tokenA,timeLock,lockedTime} = await loadFixture(deployLockFixture);
        await timeLock.lock(tokenA.address,1000,lockedTime);
        await expect(timeLock.unlock(0)).to.be.rejectedWith("Arc:unlock time not reached");
      })

      it("✨ The order has already been claimed ✨",async()=>{
        const { tokenA,timeLock,lockedTime} = await loadFixture(deployLockFixture);
        await timeLock.lock(tokenA.address,1000,lockedTime);

        const unlockTime = (await time.latest()) +3600;
        await time.increaseTo(unlockTime); 
        await timeLock.unlock(0);
        await expect(timeLock.unlock(0)).to.be.rejectedWith("claimed");
      })

      it("✨ Valut and user assets should be right ✨",async()=>{
        const { tokenA,owner,timeLock,lockedTime} = await loadFixture(deployLockFixture);
        await timeLock.lock(tokenA.address,1000,lockedTime);
        //before expiration
        expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2-1000);
        expect(await timeLock.getUserOrderLength()).to.be.equal(1);
        expect(await timeLock.getTokensLength()).to.be.equal(1);
  
        expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(1000);
        expect(await timeLock.containsToken(tokenA.address)).to.be.equal(true);
        expect((await timeLock.getOrder(0)).isClaimed).to.be.equal(false);

        const unlockTime = (await time.latest()) +3600;
        //after expiration
        await time.increaseTo(unlockTime); 
        
        await timeLock.unlock(0);

        expect(await tokenA.balanceOf(owner.address)).to.be.equal(100000000/2);
        expect(await timeLock.getUserOrderLength()).to.be.equal(1);
        expect(await timeLock.getTokensLength()).to.be.equal(1);
  
        expect(await timeLock.getTokenLockAmounts(tokenA.address)).to.be.equal(0);
        expect(await timeLock.containsToken(tokenA.address)).to.be.equal(true);
        expect((await timeLock.getOrder(0)).isClaimed).to.be.equal(true);
       
      })

  });
  describe("🌟 Events 🌟", function () {
    it("✨ Should emit an event on Lock ✨", async function () {
      
      const { tokenA,owner,timeLock,lockedTime} = await loadFixture(deployLockFixture);

      await timeLock.lock(tokenA.address,1000,lockedTime);

      await expect(timeLock.lock(tokenA.address,1000,180)).to.emit(timeLock, "Lock")
      .withArgs(owner.address,tokenA.address,1000, 180); // We accept any value as `when` arg
    });

    it("✨ Should emit an event on UnLock ✨", async function () {
      const { tokenA,owner,timeLock,lockedTime} = await loadFixture(deployLockFixture);
        await timeLock.lock(tokenA.address,1000,lockedTime);

        const unlockTime = (await time.latest()) +3600;
        await time.increaseTo(unlockTime); 
        //UnLock(msg.sender, order.tokenAddr, order.lockAmount);
        await expect(timeLock.unlock(0)).to.emit(timeLock, "UnLock")
        .withArgs(owner.address,tokenA.address,1000); // We accept any value as `when` arg
    });
  });
});
