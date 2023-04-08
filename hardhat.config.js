require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    ganache: {
      url: process.env.GANACHE_URL,
      accounts: [process.env.GANACHE_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.GOERLI_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
    mumbai: {
      url: process.env.MUMBAI_URL,
      accounts: [process.env.MUMBAI_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
    polygon: {
      url: process.env.POLYGON_URL,
      accounts: [process.env.POLYGON_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
  },
};
