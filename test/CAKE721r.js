const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("CAKE721r", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    
    const name = "TEST"
    const symbol = "TEST"
    const maxSupply = 10

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Contract = await ethers.getContractFactory("CAKE721r");
    const contract = await Contract.deploy(name, symbol, maxSupply);

    return { contract, owner, otherAccount };
  }

  describe("Deployment", function () {

    it.skip("Should Return a Contract Address", async function () {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      expect(contract.address).to.not.equal('');
    }); 
    
    it.skip("Should Return a List of Pusedo-Random TokenIds", async function () {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      const numTokens = 10
      const [owner] = await ethers.getSigners();

      await contract.mint(numTokens);

      for(i=0; i<numTokens; i++){
          tokenId = await contract.tokenOfOwnerByIndex(owner.address, i)
          console.log(`TokenId: ${tokenId}`)
      }

      expect(await contract.balanceOf(owner.address)).to.equal(numTokens);
    }); 
    
    it.skip("Should Return a List of Pusedo-Random TokenIds", async function () {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      const numTokens = 10
      const [owner] = await ethers.getSigners();

      await contract.mint(numTokens);

      for(i=0; i<numTokens; i++){
          tokenId = await contract.tokenOfOwnerByIndex(owner.address, i)
      }

      const totalSupply = await contract.totalSupply()

      expect(totalSupply).to.equal(numTokens);
    });

  });
});

  