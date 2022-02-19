const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Aave Middleware", function () {
  let Aave;
  let hardhatAave;
  let deployedContractAddress;
  beforeEach(async () => {
    Aave = await ethers.getContractFactory("AaveMiddleware");
    hardhatAave = await Aave.deploy();
    //console.log(hardhatAave.signer);
    await hardhatAave.deployed();
    //console.log(hardhatAave.address);
    deployedContractAddress = hardhatAave.address;
  });
  it("Should return Lending Pool Address", async function () {
    const result = await hardhatAave.getLendingPoolAddress();
    //console.log(result);
    expect(result).to.be.a("string");
    expect(result).to.equal("0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9");
    console.log(deployedContractAddress);
  });
  describe("Eth Functions", function () {
    it("Should deposit eth to aave", async function () {
      console.log(deployedContractAddress);
      const [owner] = await ethers.getSigners();
      //var res = await hardhatAave.depositEth();
      var res = await hardhatAave.connect(owner).depositEth({
        value: ethers.utils.parseEther("0.10"),
      });
      //expect(res.receipt.status).to.equal(true);
      console.log(res);
    });

    it("Should withdraw eth from aave", async function () {
      console.log(deployedContractAddress);
      const [owner] = await ethers.getSigners();

      var res = await hardhatAave.connect(owner).withdrawEth(10000); //Amount in wei
      console.log(res);
    });

    // it("Should borrow eth from aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.borrowEth(10000); //Amount in wei
    //   console.log(res);
    // });

    // it("Should repay eth to aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.connect(owner).repayEth({
    //     value: ethers.utils.parseEther("0.01"),
    //   });
    //   console.log(res);
    // });
  });

  describe("ERC20 Functions", function () {
    const DaiContractAddr = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //mainnet
    const accountAddress = "0x535De4eB0f28eFc0332C5702F8002bBd33115270"; //Impersonating account
    var DaiContract;
    var testAccount;
    const abi = [
      "function balanceOf(address) view returns (uint)",

      "function approve(address to, uint amount)", //correct?
    ];
    beforeEach(async () => {
      // impersonating the account.
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountAddress],
      });
      testAccount = await ethers.getSigner(accountAddress);
      DaiContract = new ethers.Contract(DaiContractAddr, abi, testAccount);
    });

    it("Should deposit DAI to aave", async function () {
      var amount = 100000000000;
      //const walletBalancePrior = await ethers.provider.getBalance(testAccount); //DaiContract.getBalance()?
      //console.log(walletBalancePrior);
      let tx = await DaiContract.approve(deployedContractAddress, amount);
      //var res = await hardhatAave.depositEth();
      var res = await hardhatAave.connect(testAccount).depositToken(amount); //ethers.utils.parseEther("0.10")
      //expect(res.receipt.status).to.equal(true);
      console.log(res);
    });
  });
});
