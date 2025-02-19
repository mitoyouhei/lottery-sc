const { ethers, network } = require("hardhat");
const { networkVrfConfigMap } = require("../vrf.config");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts...");
  console.log("Network:", network.name);
  console.log("Account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Casino = await ethers.getContractFactory("Casino");
  const vrfConfig = networkVrfConfigMap[network.name];
  console.log("VRF Config", vrfConfig);
  if(!vrfConfig) {
    console.log("Deploy failed: invalid VRF config");
    return;
  }

  const casino = await Casino.deploy(
    vrfConfig.keyHash,
    vrfConfig.subId,
    vrfConfig.minimumRequestConfirmations,
    vrfConfig.callbackGasLimit,
    vrfConfig.numWords,
    vrfConfig.VRFCoordinatorV2InterfaceAddress
  );
  console.log("Casino address:", casino.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
