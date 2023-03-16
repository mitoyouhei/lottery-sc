const { ethers, network, upgrades } = require("hardhat");

// TODO: real goerli address, and address management
const originalAddress = '0x0Fcb48a255bC37c508d1093731320bd40d4B3288';
const mumbaiTestNetAddress = '0x7e9BA8A648B3850b87Be4e3956F9388950c3d86A';
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts...");
  console.log("Network:", network.name);
  console.log("Account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // 原始部署
  // const Casino = await ethers.getContractFactory("Casino");
  // const casino = await Casino.deploy();

  // 第一次部署
  // const Casino = await ethers.getContractFactory("Casino");
  // const casino = await upgrades.deployProxy(Casino,{ initializer: 'init' })

  // 后续部署
  const Casino = await ethers.getContractFactory("Casino");
  const casino = await upgrades.upgradeProxy(mumbaiTestNetAddress, Casino);
  console.log(mumbaiTestNetAddress," box(proxy) address");

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
