// All the config in this file is from the url listed blow:
// https://docs.chain.link/vrf/v2/subscription/supported-networks

export const networkVrfConfigMap = {
  "mumbai": {
    keyHash: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", // 500 gwei
    subId: 3873,
    minimumRequestConfirmations: 3,
    callbackGasLimit: 2500000,
    numWords: 1,
    VRFCoordinatorV2InterfaceAddress: "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed"
  },
  "goerli": {
    keyHash: "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15", // 150 gwei
    subId: 3873,
    minimumRequestConfirmations: 3,
    callbackGasLimit: 150000,
    numWords: 1,
    VRFCoordinatorV2InterfaceAddress: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D"
  },
  "polygon": {
    keyHash: "0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93", // 200 gwei, 有更多可以选择
    subId: 123,// TODO
    minimumRequestConfirmations: 3,
    callbackGasLimit: 2500000,
    numWords: 1,
    VRFCoordinatorV2InterfaceAddress: "0xAE975071Be8F8eE67addBC1A82488F1C24858067"
  },
}