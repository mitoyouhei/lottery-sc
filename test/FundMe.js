const { expect, assert } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("FundMe contract", function () {
  async function deployTokenFixture() {
    const FundMe = await ethers.getContractFactory("FundMe");
    const [owner] = await ethers.getSigners();

    const hardhatFundMe = await FundMe.deploy();

    await hardhatFundMe.deployed();

    return { FundMe, hardhatFundMe, owner };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { hardhatFundMe, owner } = await loadFixture(deployTokenFixture);

      expect(await hardhatFundMe.getOwner()).to.equal(owner.address);
    });

    it("Updates the amount funded data structure", async () => {
      const { hardhatFundMe, owner } = await loadFixture(deployTokenFixture);

      const fundValue = 10;
      await hardhatFundMe.fund({ value: fundValue });
      const response = await hardhatFundMe.getAddressToAmountFunded(
        owner.address
      );
      assert.equal(response.toString(), fundValue.toString());
    });
  });
});
