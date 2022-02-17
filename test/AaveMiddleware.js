const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Aave Middleware", function () {
  let Aave;
  let hardhatAave;
  beforeEach(async () => {
    Aave = await ethers.getContractFactory("AaveMiddleware");
    hardhatAave = await Aave.deploy();
  });
  it("Should return Lending Pool Address", async function () {
    const result = await hardhatAave.getLendingPoolAddress();
    //console.log(result);
    expect(result).to.be.a("string");
    expect(result).to.equal("0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9");
  });
  describe("Eth Functions", function () {
    it("Should deposit eth to aave", async function () {
      const [owner] = await ethers.getSigners();
      //var res = await hardhatAave.depositEth();
      var res = await hardhatAave.connect(owner).depositEth({
        value: ethers.utils.parseEther("0.10"),
      });
      console.log(res);
    });
    // it("Should withdraw eth from aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.withdrawEth(10000); //Amount in wei
    //   console.log(res);
    // });
    // it("Should borrow eth from aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.borrowEth(10000); //Amount in wei
    //   console.log(res);
    // });
    // it("Should repay eth to aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.repayEth();
    //   console.log(res);
    // });
  });
});
