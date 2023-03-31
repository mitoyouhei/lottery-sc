const { ethers, network, upgrades } = require("hardhat");
const { getAddress } = require("../addressManage");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts...");
  console.log("Network: ", network.name);
  console.log("Account: ", deployer.address);
  console.log("Account balance: ", (await deployer.getBalance()).toString());

  // 原始部署
  // const Casino = await ethers.getContractFactory("Casino");
  // const casino = await Casino.deploy();

  const originalAddress = getAddress();
  const Casino = await ethers.getContractFactory("Casino");
  let casino;

  console.log('originalAddress', originalAddress);

  if(originalAddress) {
    // 后续部署
    console.log('Not first time deploy');
    casino = await upgrades.upgradeProxy(originalAddress, Casino);
  } else {
    // 第一次部署
    console.log('First time deploy');
    casino = await upgrades.deployProxy(Casino,{ initializer: 'init' });
  }

  console.log("ImplementationAddress: ", await upgrades.erc1967.getImplementationAddress(casino.address));
  console.log("AdminAddress: ", await upgrades.erc1967.getAdminAddress(casino.address));
  console.log("Casino address: ", casino.address);
  console.log("Contracts deployed");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
