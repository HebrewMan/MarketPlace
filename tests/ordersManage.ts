import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {

    const [account1, account2, addr3, addr4, addr5] = await ethers.getSigners();

    const addr0 = '0x0000000000000000000000000000000000000000';

      //a standalone contract 🥚
      const _ERC1155 = await ethers.getContractFactory("MyToken1155");
      const ERC1155 = await _ERC1155.deploy("NFT1155");
      //a standalone contract
      const _ERC20 = await ethers.getContractFactory("MyToken20");
      const ERC20 = await _ERC20.deploy();
  

    //a standalone contract 🥚
    const _ArcGovernance = await ethers.getContractFactory("ArcGovernance");
    const ArcGovernance = await _ArcGovernance.deploy(account1.address, account2.address);

    const _StrategyManage = await ethers.getContractFactory("StrategyManage");
    const StrategyManage = await _StrategyManage.deploy();

    await StrategyManage.addStrategist(account1.address);
    await StrategyManage.addStrategist(account2.address);

    const _OrdersManage = await ethers.getContractFactory("OrdersManage");
    const OrdersManage = await _OrdersManage.deploy(StrategyManage.address);
    
    return {account1, account2, addr3,addr0,ArcGovernance, StrategyManage,ERC20,ERC1155,OrdersManage};
  }


  describe("🌟 ArcGuarder SetGovernance 🌟", function () {

    it("✨Account1 SetGovernance should be success ✨",async()=>{
      const { StrategyManage,ArcGovernance} = await loadFixture(deployLockFixture);

      await StrategyManage.setGovernance(ArcGovernance.address);
      const addr = await StrategyManage.governance();

      console.log('    ArcGovernance address =====>',addr);

      expect(addr).to.be.equal(ArcGovernance.address);
    
    })
    it("✨Account2 SetGovernance should be error ✨",async()=>{
      const { StrategyManage,ArcGovernance,account2} = await loadFixture(deployLockFixture);
      await expect(StrategyManage.connect(account2).setGovernance(ArcGovernance.address)).rejectedWith('ArcGuarder:Denied')
    })

  });

  describe("🌟 addOrder() 🌟", () => {

    it("✨ Account 1 will succeed in doing this operation  ✨", async () => {

      const { account1,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      const order = await OrdersManage.getOrder(1);

      expect(order.strategy).to.be.equal(addr3.address);
      expect(order.seller).to.be.equal(account1.address);
      expect(order.nft).to.be.equal(ERC1155.address);
      expect(order.payment).to.be.equal(ERC20.address);
      expect(order.tokenId).to.be.equal(1);
      expect(order.amount).to.be.equal(10);
      expect(order.price).to.be.equal(1);
      expect(order.endAt).to.be.equal(0);
      
    })

    it("✨ Account 3 will fail to do this operation ✨", async () => {
      const { account1,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];
      await expect( OrdersManage.connect(addr3).addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt)).to.be.revertedWith("OrdersManage:No access!");

    })

  })


  describe("🌟 buyOrder() 🌟", function () {

    it("✨ Only strategists will call successfully ✨", async () => {

      const { account1,account2,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      await OrdersManage.connect(account2).buyOrder(1,5);

      const order = await OrdersManage.getOrder(1);

      expect(order.strategy).to.be.equal(addr3.address);
      expect(order.seller).to.be.equal(account1.address);
      expect(order.nft).to.be.equal(ERC1155.address);
      expect(order.payment).to.be.equal(ERC20.address);
      expect(order.tokenId).to.be.equal(1);
      expect(order.amount).to.be.equal(5);
      expect(order.price).to.be.equal(1);
      expect(order.endAt).to.be.equal(0);

      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);

      await OrdersManage.getOrder(2);

      expect(await OrdersManage.currentId()).to.be.equal(2);
      
    })

    it("✨ Order exists at the same time ✨", async () => {
      const { account1,account2,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      const order = await OrdersManage.getOrder(1);

      expect(order.strategy).to.be.equal(addr3.address);
      expect(order.seller).to.be.equal(account1.address);
      expect(order.nft).to.be.equal(ERC1155.address);
      expect(order.payment).to.be.equal(ERC20.address);
      expect(order.tokenId).to.be.equal(1);
      expect(order.amount).to.be.equal(10);
      expect(order.price).to.be.equal(1);
      expect(order.endAt).to.be.equal(0);


      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(2);

      await OrdersManage.connect(account2).buyOrder(2,5);

      const order2 = await OrdersManage.getOrder(2);

      expect(order2.strategy).to.be.equal(addr3.address);
      expect(order2.seller).to.be.equal(account1.address);
      expect(order2.nft).to.be.equal(ERC1155.address);
      expect(order2.payment).to.be.equal(ERC20.address);
      expect(order2.tokenId).to.be.equal(1);
      expect(order2.amount).to.be.equal(5);
      expect(order2.price).to.be.equal(1);
      expect(order2.endAt).to.be.equal(0);

      
    })

    it("✨ Account 3 will call failure ✨", async () => {
      const { account1,account2,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);

      await expect( OrdersManage.connect(addr3).buyOrder(1,5)).to.be.revertedWith("OrdersManage:No access!");
      
    })

    it("✨ This order is not existed ✨", async () => {
      const { account1,account2,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      await OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      await expect( OrdersManage.connect(account2).buyOrder(2,5)).to.be.revertedWith("OrdersManage:Not existed!");
      
    })


  });
  describe("🌟 cancalOrder() 🌟", function () {


    it("✨ Only seller will call successfully ✨", async () => {

      const { account1,addr3,ERC20,ERC1155,OrdersManage,addr0} = await loadFixture(deployLockFixture);

      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];
      OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);

      await OrdersManage.cancelOrder(1);
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

    it("✨ This order is not existed ✨", async () => {
      const { account1,addr3,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [addr3.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);
      await expect(OrdersManage.cancelOrder(2)).to.be.revertedWith("OrdersManage:Not existed!");
    })

    it("✨ If caller not seller will call failure ✨", async () => {

      const { account1,account2,ERC20,ERC1155,OrdersManage} = await loadFixture(deployLockFixture);
      let [strategy,seller,nft,payment,tokenId,amount,price,endAt] = [account2.address,account1.address,ERC1155.address,ERC20.address,1,10,1,0];

      OrdersManage.addOrder(strategy,seller,nft,payment,tokenId,amount,price,endAt);
      expect(await OrdersManage.currentId()).to.be.equal(1);
      await expect(OrdersManage.connect(account2).cancelOrder(1)).to.be.revertedWith("OrdersManage:Not seller!");
    
    })

   

  });

});
