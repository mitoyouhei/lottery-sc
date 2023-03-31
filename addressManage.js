const { network } = require("hardhat");

const CONTRACT_ADDRESS_MAP = new Map([
  ['mumbai', '0x7e9BA8A648B3850b87Be4e3956F9388950c3d86A'],
  ['ganache', '0xEd539963c845dB3C3cE1cABcb2011021051443Cc'],
  ['goerli', '0x9D234F00B143AE3566570C09015815218DE0DEc5'],
]);

const getAddress = () => {
  const netWorkName = network.name;
  const address =  CONTRACT_ADDRESS_MAP.get(netWorkName);
  return address;
}

module.exports = {
  getAddress,
}
