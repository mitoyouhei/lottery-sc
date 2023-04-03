const { ethers, network } = require("hardhat");

const networkVrfConfigMap = {
  "mumbai": {
    keyHash: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", // 500 gwei
    subId: 3873,
    minimumRequestConfirmations: 3,
    callbackGasLimit: 2500000,
    numWords: 1,
    VRFCoordinatorV2InterfaceAddress: "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed"
  }
}

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
