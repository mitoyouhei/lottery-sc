require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
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
    goerli_test: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.GOERLI_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
    mumbai_test: {
      url: process.env.MUMBAI_URL,
      accounts: [process.env.MUMBAI_DEPLOY_ACCOUNT_PRIVATE_KEY],
    },
  },
};
