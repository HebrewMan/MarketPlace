import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { beforeEach, describe } from "mocha";

describe("Airdrop1155", function () {

    // beforeEach() //if you want deploy 2 contracts by loadFixture

    async function deployContracts() {
        const [owner,addr1,addr2,addr3] = await ethers.getSigners();

        const Airdrop = await ethers.getContractFactory("Airdrop1155Template");
        const airdrop = await Airdrop.deploy();

        const NFT1155 = await ethers.getContractFactory("MyToken1155");
        const nft1155 = await NFT1155.deploy();

        console.log("airdrop address 🏠:",airdrop.address);
        console.log("nft1155 address 🏠:",nft1155.address);
        return { owner,addr1, addr2,addr3,airdrop,nft1155 };

    }

    describe("🏭 NFT1155",async function () {

        it("Owner balanceOf should be right",async function(){

            const { nft1155 ,owner} = await loadFixture(deployContracts);

            const id2 = await nft1155.balanceOf(owner.address,2);
            const id3 = await nft1155.balanceOf(owner.address,3);
            const id4 = await nft1155.balanceOf(owner.address,4);
        
            expect(id2).to.be.equal(1);
            expect(id3).to.be.equal(1000000);
            expect(id4).to.be.equal(1000000);
        })

        it("should be approved to airdrop1155 address", async function () {
            const { nft1155,airdrop,owner} = await loadFixture(deployContracts);
            await nft1155.setApprovalForAll(airdrop.address,true);
            expect(await nft1155.isApprovedForAll(owner.address,airdrop.address)).to.be.equal(true);
        });
    });



    describe("🏭 Airdrop Activity",async function () {       
    
        describe("✨ Create Activity", function () {
            it("Partner address should be owner.address()", async function() {
                const { airdrop ,owner} = await loadFixture(deployContracts);
                await airdrop.init(owner.address);
                const _owner = await airdrop.partner();
                expect(_owner).to.be.equal(owner.address);
            });

            it("Only Partner", async function () {
                const { airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await nft1155.setApprovalForAll(airdrop.address,true);//approve
                await airdrop.init(owner.address);//init
                
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];

                await expect(airdrop.connect(addr1).addUsersRewards(0,nft1155.address,users,ids,amounts)).to.be.rejectedWith("ARC:DENIED");
            });
        });

        describe("✨ Add Users Rewards",async function () {

            it("current id should be 1", async function () {
                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
                expect(await airdrop.currentId()).to.be.equal(1);
            });
            it("Check users can claim balance",async ()=>{
                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
                const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
                const userBlance2 = await airdrop.getUserRewards(1,addr2.address);
                expect(Number(userBlance1[1])).to.be.equal(100);
                expect(Number(userBlance2[1])).to.be.equal(100);
            })

            it("Valut can destroy balance should be 200",async ()=>{
                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
                const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
                expect(Number(valutBalance[1])).to.be.equal(200);
            })
            //add 
            it("User can destroy balance should be 200",async ()=>{

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
                await airdrop.addUsersRewards(1,nft1155.address,users,ids,amounts);

                const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
                const userBlance2 = await airdrop.getUserRewards(1,addr2.address);
                expect(Number(userBlance1[1])).to.be.equal(200);
                expect(Number(userBlance2[1])).to.be.equal(200);


            })

            it("Valut can destroy balance should be 400",async ()=>{
                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [100,100];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
                await airdrop.addUsersRewards(1,nft1155.address,users,ids,amounts);

                const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
                expect(Number(valutBalance[1])).to.be.equal(400);
            })

        });

        describe("✨ remove Users Rewards",async function () {

            it("Remove:successful",async ()=>{

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                let amounts = [200,200];
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
    
                amounts = [100,100];
                //remove
                await airdrop.removeUsersRewards(1,users,ids,amounts);
    
                const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
                const userBlance2 = await airdrop.getUserRewards(1,addr2.address);
                const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
                expect(Number(valutBalance[1])).to.be.equal(200);
                expect(Number(userBlance1[1])).to.be.equal(100);
                expect(Number(userBlance2[1])).to.be.equal(100);

            })

            it("Remove:Fail. If user don't have rewards",async ()=>{

                let {airdrop,addr1,addr2,addr3,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                let users = [addr1.address,addr2.address];
                const ids = [3,3];
                let amounts = [200,200];
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);
    
                amounts = [100,100];
                users = [addr1.address,addr3.address];
                //remove
                await expect(airdrop.removeUsersRewards(1,users,ids,amounts)).to.be.rejectedWith("ARC:NO_REWARDS");

            })

            it("Remove:fail only partner",async ()=>{

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [200,200];
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                airdrop = airdrop.connect(addr1);
                const amounts2 = [100,100];
                await expect(airdrop.removeUsersRewards(1,users,ids,amounts2)).to.be.rejectedWith("ARC:DENIED");

            })
        });

        describe("✨ withdraw Rewards",async function () {
   
            it("Active status must be true",async()=>{

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address,addr1.address,addr2.address];
                const ids = [3,3,4,4];
                const amounts = [300,300,400,400];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                airdrop = airdrop.connect(addr1);
                await expect(airdrop.withdrawRewards(1,1)).to.be.rejectedWith("ARC:ACTIV_PAUSED");

            });


            it("Check user's assets", async function () {

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address,addr1.address,addr2.address];
                const ids = [3,3,4,4];
                const amounts = [300,300,400,400];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                await airdrop.openActivity(1);

                airdrop = airdrop.connect(addr1);

                //check user can claim amounts

                expect((await(airdrop.getUserRewards(1,addr1.address)))[1][0]).to.be.equal(300);
                expect((await(airdrop.getUserRewards(1,addr1.address)))[1][1]).to.be.equal(400);

                await airdrop.withdrawRewards(1,1);

                expect((await nft1155.balanceOf(addr1.address,3)).toNumber()).to.be.equal(300);
                expect((await nft1155.balanceOf(addr1.address,4)).toNumber()).to.be.equal(400);

                airdrop = airdrop.connect(addr2);
                await airdrop.withdrawRewards(1,1);

                expect((await nft1155.balanceOf(addr2.address,3)).toNumber()).to.be.equal(300);
                expect((await nft1155.balanceOf(addr2.address,4)).toNumber()).to.be.equal(400);
                 
            });

            it("Check valut assets", async function () {

                let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address,addr1.address,addr2.address];
                const ids = [3,3,4,4];
                const amounts = [300,300,400,400];            
    
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);


                //user claim before the valut asset id 3 balance shoule be 600
                expect((await(airdrop.getUserRewards(1,airdrop.address)))[1][0]).to.be.equal(600);

                await airdrop.openActivity(1);

                airdrop = airdrop.connect(addr1);
                await airdrop.withdrawRewards(1,1);

                //user claimed;
                expect((await(airdrop.getUserRewards(1,airdrop.address)))[1][0]).to.be.equal(300);
                expect((await(airdrop.getUserRewards(1,airdrop.address)))[1][1]).to.be.equal(400);
  
            });
        });

        describe("✨ Destory Activity", function () {
         
             it("The activity status must be stop -- false", async function () {

                let {airdrop,addr1,addr2,owner,nft1155} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [200,200];
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                expect((await airdrop.activities(1)).status).to.be.equal(false);
                await airdrop.destroyActivity(1);
                expect((await airdrop.activities(1)).isDestroy).to.be.equal(true);
                //destoried valut is undefined 
                    
                expect((await(airdrop.getUserRewards(1,airdrop.address)))[1][0]).to.be.equal(undefined);
            
            });

            it("Caller is must be partner",async ()=>{
                let {airdrop,addr1,addr2,owner,nft1155} = await loadFixture(deployContracts);
                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [200,200];
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                airdrop = airdrop.connect(addr1);
                await expect(airdrop.destroyActivity(1)).to.be.rejectedWith("ARC:DENIED");
            })

        });

        describe("✨ Activity Status", function () {
            it("Open and close activity status", async function () {
                let {airdrop,addr1,addr2,owner,nft1155} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [200,200];
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                await airdrop.openActivity(1);
                expect((await airdrop.activities(1)).status).to.be.equal(true);

                await airdrop.closeActivity(1);
                expect((await airdrop.activities(1)).status).to.be.equal(false);
            });

            it("Only owner:fail", async function () {

                let {airdrop,addr1,addr2,owner,nft1155} = await loadFixture(deployContracts);

                await airdrop.init(owner.address);//init
                await nft1155.setApprovalForAll(airdrop.address,true);//approve
    
                const users = [addr1.address,addr2.address];
                const ids = [3,3];
                const amounts = [200,200];
                await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

                airdrop = airdrop.connect(addr1);
                await expect(airdrop.openActivity(1)).to.be.rejectedWith("ARC:DENIED");
                await expect(airdrop.closeActivity(1)).to.be.rejectedWith("ARC:DENIED");
            
            });
        });
    });
});




// describe("remove Users Rewards",async function () {

//     let {airdrop,addr1,addr2,nft1155,owner} = await loadFixture(deployContracts);

//     await airdrop.init(owner.address);//init
//     await nft1155.setApprovalForAll(airdrop.address,true);//approve

//     const users = [addr1.address,addr2.address,addr1.address,addr2.address];
//     const ids = [3,3];
//     const amounts = [100,100];

//     await airdrop.addUsersRewards(0,nft1155.address,users,ids,amounts);

//     it("Check users can claim balance",async ()=>{
//         const userBlance1 = await airdrop.getUserRewards(1,addr1.address);
//         const userBlance2 = await airdrop.getUserRewards(1,addr2.address);
//         expect(userBlance1).to.be.equal(200);
//         expect(userBlance2).to.be.equal(200);
//     })

//     it("Check valut can destroy balance",async ()=>{
//         const valutBalance = await airdrop.getUserRewards(1,airdrop.address);
//         expect(valutBalance).to.be.equal(200);
//     })

//     /**
//      * 角色检查
//      */
// });
