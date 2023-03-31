const { ethers, network, upgrades } = require("hardhat");

// TODO: real goerli address, and address management
const originalAddress = '0x0Fa71a9Ba8dD2838A26f0290AC79251B1929890d'

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts...");
  console.log("Network:", network.name);
  console.log("Account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const FundMe = await ethers.getContractFactory("FundMe");
  // const fundMe = await FundMe.deploy();

  // console.log("FundMe address:", fundMe.address);

  const Casino = await ethers.getContractFactory("Casino");
  const casino = await upgrades.upgradeProxy(originalAddress, Casino);

  console.log(originalAddress," box(proxy) address");
  console.log(await upgrades.erc1967.getImplementationAddress(casino.address)," getImplementationAddress");
  console.log(await upgrades.erc1967.getAdminAddress(casino.address)," getAdminAddress");

  console.log("Casino address:", casino.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
