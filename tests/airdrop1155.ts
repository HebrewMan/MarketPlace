import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { describe } from "mocha";

// const abiGreeterRouter = require('../artifacts/contracts/Greeter.sol/Greeter.json').abi;

describe("Airdrop1155", function () {

    let addr1;
    let addr2;
    let addr3;

    async function deployAirdrop() {

        // Contracts are deployed using the first signer/account by default
        const [partner,addr1,addr2,addr3] = await ethers.getSigners();

        const Airdrop = await ethers.getContractFactory("Airdrop1155Template");
        const airdrop = await Airdrop.deploy();

        return { partner, addr1, addr2,addr3};
    }


//   //将原始Greeter ABI转换为友好可读ABI
//   async function transferGreeterABIFixture() {
//     const iface = new ethers.utils.Interface(abiGreeterRouter);
//     //FormatTypes.full or FormatTypes.minimal
//     const abiGreeterHuman = iface.format(ethers.utils.FormatTypes.minimal);
//     return {abiGreeterHuman};
//   }





    describe("Add Users Rewards", function () {
        /**
         * 项目方检查
         * 创建
         * 追加（销毁状态下追加）
         */
        describe("Validations", function () {
            it("Should revert with the right error if called too soon", async function () {
                // const { lock } = await loadFixture(deployAirdrop);

                // await expect(lock.withdraw()).to.be.revertedWith("You can't withdraw yet");
            });
            it("Should revert with the right error if called from another account", async function () {

            });

            it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
           
      
            });
        });

        describe("Withdraw Rewards", function () {

            it("Should transfer the funds to the owner", async function () {
        

                // await time.increaseTo(unlockTime);

                // await expect(lock.withdraw()).to.changeEtherBalances(
                //     [owner, lock],
                //     [lockedAmount, -lockedAmount]
                // );
            });
        });

        describe("remove Users Rewards", function () {
            /**
             * 角色检查
             */
        });

        describe("withdraw Rewards", function () {
            /**
            * 数量检查，可领取数量
            * 是否到账
            * 提取成功后 池子余额 、用户余额变化
            */
        });

        describe("DestoryActivity", function () {
            /**
             * 项目方检查
             * 必须暂停之后才可以销毁
             * 销毁之后的活动是否存在
             * 销毁后 余额有没有到账
             */
        });

        describe("Activity Status", function () {
            describe("Open Activity", function () {
                it("Only partner can do this", async function () {
                 
                });
            });

            describe("Close Activity", function () {
                /**
                * 角色检查
                */
                it("Only partner can do this", async function () {
                
                });
            });
        });
    });
});
