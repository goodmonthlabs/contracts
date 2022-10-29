const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("CAKE721A", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    
    const name = "TEST"
    const symbol = "TEST"
    const maxSupply = 10

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Contract = await ethers.getContractFactory("CAKE721A");
    const contract = await Contract.deploy("CAKE", "CAKE", 10, 0, 0, 1667071242, 1667071242);

    return { contract, owner, otherAccount };
  }

  describe("Deployment", function () {

    it.skip("Should Return a Contract Address", async () => {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      const name = await contract.name()
      expect(name).to.equal('CAKE');
    }); 

    it.skip("Set Merkleroot for private mint", async () => {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      await contract.setMerkleroot("0xa645c2ad6d07684f6b06a4c1cb6cd9e70bcce6fe256ce6bd997150af0d73c9fa")
      const merkleroot = await contract.MERKLEROOT()
      expect(merkleroot).to.equal("0xa645c2ad6d07684f6b06a4c1cb6cd9e70bcce6fe256ce6bd997150af0d73c9fa")
    })

    it("Mint", async () => {
      const { contract } = await loadFixture(deployOneYearLockFixture);
      await contract.setMerkleroot("0xa645c2ad6d07684f6b06a4c1cb6cd9e70bcce6fe256ce6bd997150af0d73c9fa")     
      
      // compute proof offline
      proof = ["0x0334329dc89b931f74e4f1cc74a37a9f24e6bcf4637bfa519bdf52dc4a4ffc81",
      "0xa57d2faee7e110421a56977b75a6b670be5d080916decca93f2b0d6c2037faf2",
      "0x833a5e64df2a9f59f1ddb8f07dece5df2cd2ca75190f470e0992f1863ed74c2d",
      "0x10f8d80c548d3fb632124cd02f050757d4e7c8a7e3f56d54ec581851ce4364e0",
      "0xd7d612fafeb49945e3ea421720a5157616dce38e53dd0873288221d4d97de692",
      "0x0e31dfbbce44687da63825de6b4f7f6f78619d35b01fc1280ca914ca09e057b0",
      "0x1e4cb984f7ea4be53b1f2dbc8e29319acb2d7bd2b98c8da0f0fea34cb686a401",
      "0x8d3364a8ba45c8d262d19fdc488c56f4037ad81b32debd6d0de38280da145efc",
      "0x972ab3bd87060b3f56119282d88947306d75bb4688bc3e9401e87fa40b698e2a"]

      await contract.mint("0x29c6a598a3447F69ff52b9b96dadf630750886FD", 10, [])
      balanceOf = await contract.balanceOf("0x29c6a598a3447F69ff52b9b96dadf630750886FD")
      expect(balanceOf).to.equal(10)

      tokens = await contract.tokensOfOwner("0x29c6a598a3447F69ff52b9b96dadf630750886FD")
      console.log(tokens)
    })
  });
});

  