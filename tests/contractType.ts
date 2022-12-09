import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

//done
describe("🏭 Contracts Deployment", function () {

  async function deployLockFixture() {
  
    const [account1, account2] = await ethers.getSigners();


    //a standalone contract 🥚
    const _ERC1155 = await ethers.getContractFactory("MyToken1155");
    const ERC1155 = await _ERC1155.deploy("NFT1155");
    //a standalone contract
    const _ERC20 = await ethers.getContractFactory("MyToken20");
    const ERC20 = await _ERC20.deploy();

     //a standalone contract
     const _ERC721 = await ethers.getContractFactory("MyToken721");
     const ERC721 = await _ERC721.deploy('ARC','NFT','https://github.io/');

    //a standalone contract 🥚
    const _ContractType = await ethers.getContractFactory("ContractType1");
    const ContractType = await _ContractType.deploy();

    console.log('ContractType address ====>',ContractType.address)

    return { ERC1155, ERC20, ERC721,ContractType,account1,account2};
  }

  describe("🌟 Check addr 🌟", function () {

    it("✨ Master address should be owner ✨",async()=>{
      const { account1,ContractType, ERC1155, ERC20, ERC721} = await loadFixture(deployLockFixture);
      expect( await ContractType.verifyByAddress(ERC20.address)).to.be.equal('20');
      expect( await ContractType.verifyByAddress(ERC721.address)).to.be.equal('721');
      expect( await ContractType.verifyByAddress(ERC1155.address)).to.be.equal('1155');
    })

  });


});
