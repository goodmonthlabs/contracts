require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY
INFURA_API_KEY = process.env.INFURA_API_KEY

GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY
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
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: "IBTHHRT9WKMDNDGWC7AWPY1T9C8ASTCRN5",
  },
};
