import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("Airdrop1155", function () {

    // beforeEach() //if you want deploy 2 contracts;

    async function deployContracts() {
        const [owner,addr1,addr2,addr3] = await ethers.getSigners();

        const Airdrop = await ethers.getContractFactory("Airdrop1155Template");
        const airdrop = await Airdrop.deploy();

        const NFT721 = await ethers.getContractFactory("MyToken721");
        const nft721 = await NFT721.deploy();

        console.log("airdrop address 🏠:",airdrop.address);
        console.log("nft721 address 🏠:",nft721.address);
        return {owner,addr1, addr2,addr3,airdrop,nft721};

    }

});

