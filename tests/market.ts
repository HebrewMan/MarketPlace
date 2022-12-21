import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {

    const [account1, account2,account3] = await ethers.getSigners();

    const addr0 = '0x0000000000000000000000000000000000000000';

    //a standalone contract 🥚
    const _ERC1155 = await ethers.getContractFactory("MyToken1155");
    const ERC1155 = await _ERC1155.deploy("NFT1155");
    //a standalone contract
    const _ERC20 = await ethers.getContractFactory("MyToken20");
    const ERC20 = await _ERC20.deploy();

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address,account2.address);

    console.log('ArcGovernance address =====>',ArcGovernance.address);

    //ArcGovernance control this contract 🧭 
    //a standalone contract 🥚
    //-------- addStrategist deleteStrategist -------
    const _StrategyManage = await ethers.getContractFactory("StrategyManage");
    const StrategyManage = await _StrategyManage.deploy();

    //** need add straegyer */

    //only StrategyManage can call this contract. --------> StrategyManage
    const _Vault = await ethers.getContractFactory("Vault");
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
    const _BasicTrade = await ethers.getContractFactory("BasicTrade");
    const BasicTrade = await _BasicTrade.deploy(StrategyConfig.address);

    //approve actions
    await ERC20.approve(Vault.address,'100000000000000000000000');
    await ERC1155.setApprovalForAll(Vault.address,true);

    await StrategyManage.addStrategist(BasicTrade.address);//1

    return { account1, account2,account3,addr0,ERC1155,ERC20,ArcGovernance,Vault,OrdersManage,TradeProxy,StrategyManage,StrategyConfig,BasicTrade};
  }


  describe("🌟 ArcGuarder SetGovernance 🌟", function () {

    it("✨Account1 SetGovernance should be success ✨",async()=>{
      const { StrategyManage,ArcGovernance,BasicTrade} = await loadFixture(deployLockFixture);

      await StrategyManage.setGovernance(ArcGovernance.address);
      const addr = await StrategyManage.governance();

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
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(100);
    })

    it("✨ Check token allowance ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,Vault} = await loadFixture(deployLockFixture);
      expect(await ERC20.allowance(account1.address,Vault.address)).to.be.equal('100000000000000000000000');
      expect(await ERC1155.isApprovedForAll(account1.address,Vault.address)).to.be.equal(true);
    })

  });

  describe("🌟 Proxy contract addOrder() 🌟", function () {
    it("✨ When user add order after check user's balance Users and vault balances ✨", async () => {
      const { ERC20, ERC1155 ,account1,TradeProxy,BasicTrade,Vault} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      await TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);
      expect(await ERC1155.balanceOf(Vault.address,1)).to.be.equal(10);
    })

    it("✨ Check current order is should be 1 ✨", async () => {
      const { ERC20, ERC1155 ,account1,TradeProxy,BasicTrade,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      await TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);
      expect(await OrdersManage.currentId()).to.be.equal(1);

    })

    //must proxy \ Strategy...

  });

  describe("🌟 Proxy contract cancelOrder() 🌟", function () {

    it("✨ Only order's owner call do that ✨", async () => {
      const { ERC20, ERC1155 ,account1,TradeProxy,BasicTrade,OrdersManage,addr0} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);

      expect(await OrdersManage.currentId()).to.be.equal(1);

      TradeProxy.cancelOrder(strategy,1);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      const order = await OrdersManage.getOrder(1);
      expect(order.strategy).to.be.equal(addr0);
      expect(order.seller).to.be.equal(addr0);
      expect(order.nft).to.be.equal(addr0);
      expect(order.payment).to.be.equal(addr0);
      expect(order.tokenId).to.be.equal(0);
      expect(order.amount).to.be.equal(0);
      expect(order.price).to.be.equal(0);
      expect(order.endAt).to.be.equal(0);
      
    })

    it("✨ The current ID is 2 after the user cancels the order ✨", async () => {
      const { ERC20, ERC1155 ,account1,TradeProxy,BasicTrade,OrdersManage,addr0} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address];
      TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);

      expect(await OrdersManage.currentId()).to.be.equal(1);

      TradeProxy.cancelOrder(strategy,1);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      const order = await OrdersManage.getOrder(1);
      expect(order.strategy).to.be.equal(addr0);
      expect(order.seller).to.be.equal(addr0);
      expect(order.nft).to.be.equal(addr0);
      expect(order.payment).to.be.equal(addr0);
      expect(order.tokenId).to.be.equal(0);
      expect(order.amount).to.be.equal(0);
      expect(order.price).to.be.equal(0);
      expect(order.endAt).to.be.equal(0);

      TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await OrdersManage.currentId()).to.be.equal(2);
      
    })

    it("✨ Only order's owner call do that ✨", async () => {
      const { ERC20, ERC1155 ,account1,TradeProxy,BasicTrade,OrdersManage,addr0,account2} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      TradeProxy.addOrder(strategy,nft,payment,1,10,1,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);

      expect(await OrdersManage.currentId()).to.be.equal(1);
      await expect( TradeProxy.connect(account2).cancelOrder(strategy,1)).to.be.revertedWith("OrdersManage:Not seller!");
    })

  });
  describe("🌟 Proxy contract buyOrder() 🌟", function () {
    it("✨ account 1 places an order account 2 buys and checks their respective balances ✨", async () => {

      const { ERC20, ERC1155 ,account1,account2,TradeProxy,BasicTrade,Vault,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      await TradeProxy.addOrder(strategy,nft,payment,1,10,100,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);

      ERC20.transfer(account2.address,1000);
      ERC20.connect(account2).approve(BasicTrade.address,'100000000000000000000000');

      await TradeProxy.connect(account2).buyOrder(strategy,1,10);

      console.log('=================');
      console.log(await ERC20.balanceOf(Vault.address));

      expect(await ERC20.balanceOf(Vault.address)).to.be.equal(3);
      expect(await ERC20.balanceOf(account2.address)).to.be.equal(0);

      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);
      expect(await ERC1155.balanceOf(account2.address,1)).to.be.equal(10);
      expect(await ERC1155.balanceOf(Vault.address,1)).to.be.equal(0);

      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);
      expect(await ERC1155.balanceOf(account2.address,1)).to.be.equal(10);
      expect(await ERC1155.balanceOf(Vault.address,1)).to.be.equal(0);

    })

    it("✨ when there are two buyers checks their respective balances ✨", async () => {

      const { ERC20, ERC1155 ,account1,account2,account3,TradeProxy,BasicTrade,Vault} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      TradeProxy.addOrder(strategy,nft,payment,1,10,1000,0);
      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);

      await ERC20.transfer(account2.address,10000);
      await ERC20.transfer(account3.address,10000);
      //buyer must be approve BasicTrade address.
      await ERC20.connect(account2).approve(BasicTrade.address,'100000000000000000000000');
      await ERC20.connect(account3).approve(BasicTrade.address,'100000000000000000000000');

      await TradeProxy.connect(account2).buyOrder(strategy,1,5);
      await TradeProxy.connect(account3).buyOrder(strategy,1,5);

      console.log('=================');
      console.log(await ERC20.balanceOf(Vault.address));

      expect(await ERC20.balanceOf(Vault.address)).to.be.equal(30);
      expect(await ERC20.balanceOf(account2.address)).to.be.equal(5000);
      expect(await ERC20.balanceOf(account3.address)).to.be.equal(5000);

      expect(await ERC1155.balanceOf(account1.address,1)).to.be.equal(90);
      expect(await ERC1155.balanceOf(account2.address,1)).to.be.equal(5);
      expect(await ERC1155.balanceOf(account3.address,1)).to.be.equal(5);
      expect(await ERC1155.balanceOf(Vault.address,1)).to.be.equal(0);

    })

  });
  
  describe("🌟 Proxy contract bidOrder() 🌟", function () {

    it("✨ nothing will happen ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,TradeProxy,BasicTrade,Vault,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      await TradeProxy.addOrder(strategy,nft,payment,1,10,100,0);
      await TradeProxy.bidOrder(strategy,1,10);
    })

  });
  describe("🌟 Proxy contract cancelBid() 🌟", function () {

    it("✨ nothing will happen ✨", async () => {
      const { ERC20, ERC1155 ,account1,account2,TradeProxy,BasicTrade,Vault,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,nft,payment] = [BasicTrade.address,ERC1155.address,ERC20.address,ERC20.address];
      await TradeProxy.addOrder(strategy,nft,payment,1,10,100,0);
      await TradeProxy.cancelBid(strategy,1);
    })

  });
 
});
