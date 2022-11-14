require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY
MAINNET_PRIVATE_KEY=process.env.MAINNET_PRIVATE_KEY
INFURA_API_KEY = process.env.INFURA_API_KEY


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",  
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    hardhat: {      
      allowUnlimitedContractSize: true,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
      gasPrice: 20000000000,
      gas: 6000000,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [MAINNET_PRIVATE_KEY],
      gasPrice: 20000000000,
      gas: 6000000,
    }
  },
  etherscan: {
    apiKey: "IBTHHRT9WKMDNDGWC7AWPY1T9C8ASTCRN5",
  },
};
