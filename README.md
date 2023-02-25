# CakeApp Contracts

CakeApp (trycake.xyz) is a smart-contract deployer and management platform for brands looking to onboard to web3.

The CAKE721 contract attempts to provide clients as much optionality as it relates to the kinds of applications they wish to build atop one or many NFT collections. It is the first of many future contracts that brands can leverage within CakeApp to grow their business and presence in the web3 world.

# Diamond Pattern Test Instructions

To see an example of how we may implement a Cake Diamon Contract that includes ERC721A-Upgradeable contract standard as a Facet, follow these steps:

install top-level packages:
`npm install`

start a localhost network using hardhat:
`npx hardhat node`

compile contracts:
`npx hardhat compile`

run deploy script referencing localhost network:
`npx hardhat run --network localhost scripts/deploy.js`

update `diamondAddress` variable inside `test/deployedDiamondTest.js` based on output from previous command

update `walletPrivateKey` and `walletAddress` variable inside `test/deployedDiamondTest.js` based on output from `npx hardhat node`
