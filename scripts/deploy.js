const { ethers, network } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts...");
  console.log("Network:", network.name);
  console.log("Account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const FundMe = await ethers.getContractFactory("FundMe");
  const fundMe = await FundMe.deploy();

  console.log("FundMe address:", fundMe.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
