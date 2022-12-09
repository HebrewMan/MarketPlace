import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";


describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {
  
    const [account1, account2] = await ethers.getSigners();

    //a standalone contract 🥚
    const _ERC1155 = await ethers.getContractFactory("MyToken1155");
    const ERC1155 = await _ERC1155.deploy("NFT1155");
    //a standalone contract
    const _ERC20 = await ethers.getContractFactory("MyToken20");
    const ERC20 = await _ERC20.deploy();

    //a standalone contract 🥚
    const master = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const cashier = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(master,cashier);

    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚
    const _StrategyManage = await ethers.getContractFactory("StrategyManage");
    const StrategyManage = await _StrategyManage.deploy();

    //only StrategyManage can call this contract. --------> StrategyManage
    const _Vault:any = await ethers.getContractFactory("Vault");
    const Vault = await _Vault.deploy(StrategyManage.address);

    //ArcGovernance control this contract 🧭 
    //only StrategyManage can call this contract. --------> StrategyManage
    const _OrdersManage = await ethers.getContractFactory("OrdersManage");
    const OrdersManage = await _OrdersManage.deploy(StrategyManage.address);

    //ArcGovernance control this contract 🧭 
    //Strategys contract depends on that. --------> BasicTrade 🌊
    const _TradeProxy = await ethers.getContractFactory("TradeProxy");
    const TradeProxy = await _TradeProxy.deploy();

    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚
    //Need to pass in 3 parameters (vault orders proxy)
    const _StrategyConfig = await ethers.getContractFactory("StrategyConfig");
    const StrategyConfig = await _StrategyConfig.deploy(Vault.address,OrdersManage.address,TradeProxy.address);

    //Strategy contract No.1 🐬
    const _BasicTrade:any = await ethers.getContractFactory("BasicTrade");
    const BasicTrade = await _BasicTrade.deploy(StrategyManage.address);

    return { account1, account2,ERC1155,ERC20,ArcGovernance,Vault,OrdersManage,TradeProxy,StrategyManage,StrategyConfig,BasicTrade};
  }

  describe("🌟 Deployment 🌟", function () {

    it("✨ Users balanceOf ✨",async()=>{
      // const { tokenA, tokenB ,account1,account2} = await loadFixture(deployLockFixture);
      // expect(await tokenA.connect(account2).balanceOf(account1.address)).to.be.equal(100000000/2);
    })

    it("✨ Check token allowance ✨", async()=>{
    })  

    it("✨ Should set the right account1 ✨", async function () {
    
    });

  });

  describe("🌟 Lucks 🌟",()=>{

    it("✨ Order data should be right✨",async()=>{
   
    })

    it("✨ One user and one token ✨",async()=>{
    
    })

    it("✨ Two users and Two tokens ✨",async()=>{


    })
  })

  describe("🌟 Unlocks 🌟", function () {
 
      it("✨ Order does not exist ✨",async ()=>{
        // await expect(timeLock.unlock(0)).to.be.reverted;
      })

      it("✨ Error index ✨",async ()=>{
        // await expect(timeLock.unlock(1)).to.be.reverted;
      })

      it("✨ Unlock time not reached ✨",async()=>{
   
        // await expect(timeLock.unlock(0)).to.be.rejectedWith("Arc:unlock time not reached");
      })

      it("✨ The order has already been claimed ✨",async()=>{
        // const { tokenA,timeLock,lockedTime} = await loadFixture(deployLockFixture);

        // await expect(timeLock.unlock(0)).to.be.rejectedWith("claimed");
      })

      it("✨ Valut and user assets should be right ✨",async()=>{
     
      })

  });
  describe("🌟 Events 🌟", function () {


    it("✨ Should emit an event on UnLock ✨", async function () {
      // const { tokenA,account1,timeLock,lockedTime} = await loadFixture(deployLockFixture);
      //   await timeLock.lock(tokenA.address,1000,lockedTime);

      //   const unlockTime = (await time.latest()) +3600;
      //   await time.increaseTo(unlockTime); 
      //   //UnLock(msg.sender, order.tokenAddr, order.lockAmount);
      //   await expect(timeLock.unlock(0)).to.emit(timeLock, "UnLock")
      //   .withArgs(account1.address,tokenA.address,1000,anyValue); // We accept any value as `when` arg
    });
  });
});
