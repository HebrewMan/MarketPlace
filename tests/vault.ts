import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {

    const [account1, account2, addr3, addr4, addr5] = await ethers.getSigners();

    //a standalone contract 🥚
    const _ERC1155 = await ethers.getContractFactory("MyToken1155");
    const ERC1155 = await _ERC1155.deploy("NFT1155");
    //a standalone contract
    const _ERC20 = await ethers.getContractFactory("MyToken20");
    const ERC20 = await _ERC20.deploy();

    const balance = await ERC20.balanceOf(account1.address);

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address, account2.address);

    console.log('ArcGovernance address =====>',ArcGovernance.address);
    
    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚
    //Need to pass in 3 parameters (vault orders proxy)
    const _StrategyConfig = await ethers.getContractFactory("StrategyConfig");
    const StrategyConfig = await _StrategyConfig.deploy(addr3.address, addr4.address, addr5.address);

    const _StrategyManage = await ethers.getContractFactory("StrategyManage");
    const StrategyManage = await _StrategyManage.deploy();


    //only StrategyManage can call this contract. --------> StrategyManage
    const _Vault = await ethers.getContractFactory("Vault");
    const Vault = await _Vault.deploy(StrategyManage.address);
    

    //approve actions
    await ERC20.approve(Vault.address,'100000000000000000000000');
    await ERC1155.setApprovalForAll(Vault.address,true);

    return { account1, account2, ArcGovernance, Vault, StrategyManage, ERC1155, ERC20 };
  }


  describe("🌟 ArcGuarder SetGovernance 🌟", function () {

    it("✨Account1 SetGovernance should be success ✨",async()=>{
      const { StrategyManage,ArcGovernance} = await loadFixture(deployLockFixture);

      await StrategyManage.setGovernance(ArcGovernance.address);
      const addr = await StrategyManage.governance();

      console.log('ArcGovernance address =====>',addr);

      expect(addr).to.be.equal(ArcGovernance.address);
    
    })
    it("✨Account2 SetGovernance should be error ✨",async()=>{
      const { StrategyManage,ArcGovernance,account2} = await loadFixture(deployLockFixture);
      await expect(StrategyManage.connect(account2).setGovernance(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')
    })

  });

  describe("🌟 Deployment 🌟", function () {

    it("✨ Users balances✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,Vault} = await loadFixture(deployLockFixture);
      expect(await ERC20.balanceOf(account1.address)).to.be.equal(100000000);
      expect(await ERC1155.isApprovedForAll(account1.address,Vault.address)).to.be.equal(true);
    })

    it("✨ Check token allowance ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,Vault} = await loadFixture(deployLockFixture);
      expect(await ERC20.allowance(account1.address,Vault.address)).to.be.equal('100000000000000000000000');
    })

  });

  describe("🌟 SetPaused() 🌟", () => {

    it("✨ Account 1 will succeed in doing this operation ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,Vault} = await loadFixture(deployLockFixture);
      Vault.setPaused(true);
      expect(await Vault.paused()).to.be.equal(true);
      Vault.setPaused(false)
      const res = await Vault.paused();
      expect(await Vault.paused()).to.be.equal(false);
    })

    it("✨ Account 2 will fail to do this operation ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,Vault} = await loadFixture(deployLockFixture);
      await expect( Vault.connect(account2).setPaused(true)).to.be.reverted;
    })
  })


  describe("🌟 Receiver() 🌟", function () {

    it("✨ Only strategists will call successfully ✨", async () => {
      // await expect(timeLock.unlock(0)).to.be.reverted;
      const { ERC20 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);

      Vault.receiver(ERC20.address,'100');
      expect(await ERC20.balanceOf(Vault.address)).to.be.equal('100');
    })

    it("✨ Account 2 will call failure ✨", async () => {
      const { ERC20 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);
      await expect(Vault.receiver(ERC20.address,'100')).to.be.reverted;
    })

  });
  describe("🌟 ReceiverNFT() 🌟", function () {


    it("✨ Only strategists will call successfully ✨", async () => {
      const { ERC1155 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);
  
      Vault.receiverNFT(ERC1155.address,3,100);

      expect(await ERC1155.balanceOf(Vault.address,3)).to.be.equal(100);
    })

    it("✨ Account 2 will call failure ✨", async () => {
      const { ERC1155 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);
      await expect(Vault.receiverNFT(ERC1155.address,3,100)).to.be.reverted;
    })

  });

  describe("🌟 Withdraw() 🌟", function () {

    it("✨ Withdraw 100 will call successfully ✨", async () => {
      const { ERC20 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);

      Vault.receiver(ERC20.address,'100');
      expect(await ERC20.balanceOf(Vault.address)).to.be.equal('100');

      Vault.withdraw(ERC20.address,'50');
      expect(await ERC20.balanceOf(Vault.address)).to.be.equal(50);

    })

    it("✨ Withdraw 101 will call failure ✨", async () => {
      const { ERC20 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);

      Vault.receiver(ERC20.address,'100');
      expect(await ERC20.balanceOf(Vault.address)).to.be.equal('100');

      await expect(Vault.withdraw(ERC20.address,'101')).to.be.revertedWith("Vault:Insufficient balance");
    })

  });


  describe("🌟 WithdrawNFT() 🌟", function () {


    it("✨ Only strategists will call successfully ✨", async () => {
      // await expect(timeLock.unlock(0)).to.be.reverted;

      const { ERC1155 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);
  
      Vault.receiverNFT(ERC1155.address,3,100);
      expect(await ERC1155.balanceOf(Vault.address,3)).to.be.equal(100);

      Vault.withdrawNFT(ERC1155.address,3,50);
      expect(await ERC1155.balanceOf(Vault.address,3)).to.be.equal(50);

    })

    it("✨ Account 2 will call failure ✨", async () => {

      const { ERC1155 ,account1,account2,Vault,StrategyManage} = await loadFixture(deployLockFixture);

      //set strategists
      StrategyManage.addStrategist(account1.address);
      expect(await StrategyManage.checkAccess(account1.address)).to.be.equal(true);
      expect(await StrategyManage.checkAccess(account2.address)).to.be.equal(false);
  
      Vault.receiverNFT(ERC1155.address,3,100);
      expect(await ERC1155.balanceOf(Vault.address,3)).to.be.equal(100);

      await expect(Vault.withdrawNFT(ERC1155.address,3,'101')).to.be.revertedWith("Vault:Insufficient balance");
      // await expect(timeLock.unlock(1)).to.be.reverted;
    })

  });

});
