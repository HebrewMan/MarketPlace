import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("Airdrop1155", function () {

    // beforeEach() //if you want deploy 2 contracts;

    async function deployContracts() {
        const [owner,addr1,addr2,addr3] = await ethers.getSigners();

        const Airdrop = await ethers.getContractFactory("Airdrop721Template");
        const airdrop = await Airdrop.deploy();

        const NFT721 = await ethers.getContractFactory("MyToken721");
        const nft721 = await NFT721.deploy();

        return {owner,addr1, addr2,addr3,airdrop,nft721};
    }

    describe("🏭 NFT721 Contract",async function () {

      it("Owner balanceOf should be 10",async function(){
        const { nft721 ,owner} = await loadFixture(deployContracts);
        expect(await nft721.balanceOf(owner.address)).to.be.equal(10);
      })

      it("Approve to airdrop721 contract",async function(){
        const { nft721 ,owner,airdrop} = await loadFixture(deployContracts);
        expect((await nft721.balanceOf(owner.address)).toNumber()).to.be.equal(10);

        await nft721.setApprovalForAll(airdrop.address,true);
        expect(await nft721.isApprovedForAll(owner.address,airdrop.address)).to.be.equal(true);
      })
  
    });

    describe("🏭 Airdrop Contract",async function () {       
    
      describe("✨ Create Activity", function () {
          it("Partner address should be owner.address()", async function() {
              const { airdrop ,owner} = await loadFixture(deployContracts);
              await airdrop.init(owner.address);
              expect(await airdrop.partner()).to.be.equal(owner.address);
          });

          it("Only Partner", async function () {
              const { airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await nft721.setApprovalForAll(airdrop.address,true);
              expect(await nft721.isApprovedForAll(owner.address,airdrop.address)).to.be.equal(true);

              await airdrop.init(owner.address);//init
              
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];

              await expect(airdrop.connect(addr1).addUsersRewards(0,nft721.address,users,ids,amounts)).to.be.rejectedWith("ARC:DENIED");
              await expect(airdrop.connect(addr1).addUsersRewards(1,nft721.address,users,[3,4],amounts)).to.be.rejectedWith("ARC:DENIED");
              await expect(airdrop.connect(addr1).removeUsersRewards(1,users,ids,amounts)).to.be.rejectedWith("ARC:DENIED");
              await expect(airdrop.connect(addr1).openActivity(1)).to.be.rejectedWith("ARC:DENIED");
              await expect(airdrop.connect(addr1).closeActivity(1)).to.be.rejectedWith("ARC:DENIED");
              await expect(airdrop.connect(addr1).destroyActivity(1)).to.be.rejectedWith("ARC:DENIED");

          });
      });

      describe("✨ Add Users Rewards",async function () {

          it("current id should be 1", async function () {
              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);
              expect(await airdrop.currentId()).to.be.equal(1);
          });
          it("Check users can claim NFT token ids",async ()=>{
              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);
              const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
              const userBlance2 = await airdrop.getUserRewards(1,addr2.address);

              expect((userBlance1[0])[0].toNumber()).to.be.equal(1);
              expect((userBlance2[0])[0].toNumber()).to.be.equal(2);
          })

          it("Check valut can claim NFT token ids",async ()=>{
              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);
              const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance[0].toString()).to.be.equal([1,2].toString());
              //keep add [3,4]
              await airdrop.addUsersRewards(1,nft721.address,users,[3,4],amounts);
              const valutBalance2 = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance2[0].toString()).to.be.equal([1,2,3,4].toString());

          })
          // add 
          it("Add:Fail. if the NFT id not belong to owner",async ()=>{

              let {airdrop,addr1,addr2,addr3,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
             
              await nft721.safeMint(addr3.address);
              const users = [addr1.address,addr2.address];
              const ids = [1,11];
              const amounts = [1,1];            
        
              await expect(airdrop.addUsersRewards(0,nft721.address,users,ids,amounts)).to.be.rejectedWith("ARC:NOT_OWNER");

          })

          it("Valut's balance should be 【1,2,3,4】",async ()=>{
              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);
              await airdrop.addUsersRewards(1,nft721.address,users,[3,4],amounts);

              const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance[0].toString()).to.be.equal([1,2,3,4].toString());
              
          })

      });

      describe("✨ remove Users Rewards",async function () {

          it("Remove:successful check users and valut balance is changed or not",async ()=>{

              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);
  
              //remove
              await airdrop.removeUsersRewards(1,[addr1.address],[1],[1]);
  
              const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
              const userBlance2 = await airdrop.getUserRewards(1,addr2.address);
              const valutBalance = await airdrop.getUserRewards(1,airdrop.address);

              expect(userBlance1[0].length).to.be.equal(0);
              expect(Number(userBlance2[0][0])).to.be.equal(2);
              expect(Number(valutBalance[0][0])).to.be.equal(2);
              expect(valutBalance[0]).to.be.length(1);

          })

      });

      describe("✨ withdraw Rewards",async function () {
 
          it("Active:Fail status must be true",async()=>{
              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address,addr1.address,addr2.address];
              const ids = [1,2,3,4];
              const amounts = [1,1,1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);

              airdrop = airdrop.connect(addr1);
              await expect(airdrop.withdrawRewards(1,1)).to.be.rejectedWith("ARC:ACTIV_PAUSED");

          });


          it("Check user's and valut assets", async function () {

              let {airdrop,addr1,addr2,nft721,owner} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address,addr1.address,addr2.address];
              const ids = [1,2,3,4];
              const amounts = [1,1,1,1];            
  
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);

              await airdrop.openActivity(1);

              //check user can claim amounts

              const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance[0].toString()).to.be.equal([1,2,3,4].toString());

              await airdrop.connect(addr1).withdrawRewards(1,1);

              expect((await nft721.balanceOf(addr1.address)).toNumber()).to.be.equal(2);
              expect((await nft721.ownerOf(1))).to.be.equal(addr1.address);
              expect((await nft721.ownerOf(3))).to.be.equal(addr1.address);

              //check valut
              const valutBalance2 = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance2[0].toString()).to.be.equal([4,2].toString());
              expect((await nft721.balanceOf(airdrop.address)).toNumber()).to.be.equal(2);

              await airdrop.connect(addr2).withdrawRewards(1,1);

              expect((await nft721.balanceOf(addr2.address)).toNumber()).to.be.equal(2);
              expect((await nft721.ownerOf(2))).to.be.equal(addr2.address);
              expect((await nft721.ownerOf(4))).to.be.equal(addr2.address);
              //check valut
              const valutBalance3 = await airdrop.getUserRewards(1,airdrop.address);
              expect(valutBalance3[0].toString()).to.be.equal([].toString());
              expect((await nft721.balanceOf(airdrop.address)).toNumber()).to.be.equal(0);

          });
      });

      describe("✨ Destory Activity", function () {
       
           it("The activity status must be stop -- false", async function () {

              let {airdrop,addr1,addr2,owner,nft721} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);

              expect((await airdrop.activities(1)).status).to.be.equal(false);
              await airdrop.destroyActivity(1);
              expect((await airdrop.activities(1)).isDestroy).to.be.equal(true);
          
          });

          it("Check valut assets", async function () {

            let {airdrop,addr1,addr2,owner,nft721} = await loadFixture(deployContracts);

            await airdrop.init(owner.address);//init
            await nft721.setApprovalForAll(airdrop.address,true);//approve

            const users = [addr1.address,addr2.address];
            const ids = [1,2];
            const amounts = [1,1];
            //current id should be 1
            await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);

            expect((await airdrop.activities(1)).status).to.be.equal(false);
            await airdrop.destroyActivity(1);
            expect((await airdrop.activities(1)).isDestroy).to.be.equal(true);
            const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
            expect(valutBalance[0].toString()).to.be.equal([].toString());

            //current id should be 2
            await airdrop.addUsersRewards(0,nft721.address,users,[3,4],amounts);
            expect(await airdrop.currentId()).to.be.equal(2);
            expect((await airdrop.activities(2)).isDestroy).to.be.equal(false);

            const valutBalance2 = await airdrop.getUserRewards(2,airdrop.address);
            expect(valutBalance2[0].toString()).to.be.equal([3,4].toString());
            expect((await nft721.balanceOf(airdrop.address)).toNumber()).to.be.equal(2);
            
        });

      });

      describe("✨ Activity Status", function () {
          it("Open and close activity status", async function () {
              let {airdrop,addr1,addr2,owner,nft721} = await loadFixture(deployContracts);

              await airdrop.init(owner.address);//init
              await nft721.setApprovalForAll(airdrop.address,true);//approve
  
              const users = [addr1.address,addr2.address];
              const ids = [1,2];
              const amounts = [1,1];
              await airdrop.addUsersRewards(0,nft721.address,users,ids,amounts);

              await airdrop.openActivity(1);
              expect((await airdrop.activities(1)).status).to.be.equal(true);

              await airdrop.closeActivity(1);
              expect((await airdrop.activities(1)).status).to.be.equal(false);
          });

      });
  });




});

