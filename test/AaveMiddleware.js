const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Aave Middleware", function () {
  let Aave;
  let hardhatAave;
  let deployedContractAddress;
  let tokenAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //Dai token Address on Mainnet

  it("Should Deploy contract", async function () {
    Aave = await ethers.getContractFactory("AaveMiddleware");
    hardhatAave = await Aave.deploy();
    await hardhatAave.deployed();
    deployedContractAddress = hardhatAave.address;
    console.log("Deployed Succefully!.. Address-", deployedContractAddress);
  });

  it("Should return Lending Pool Address", async function () {
    const result = await hardhatAave.getLendingPoolAddress();
    //console.log(result);
    expect(result).to.be.a("string");
    expect(result).to.equal("0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9");
  });

  describe("Function  tests", async function () {
    const DaiContractAddr = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //mainnet
    var DaiContract;
    const awethContractAddr = "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e"; //mainnet
    var awethContract;
    const aDaiContractAddr = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
    var aDaiContract;
    const abi = [
      "function balanceOf(address) view returns (uint)",

      "function approve(address to, uint amount)", //correct?
    ];

    const accountAddress = "0x535De4eB0f28eFc0332C5702F8002bBd33115270"; //Impersonating account
    var testAccount;

    beforeEach(async () => {
      // impersonating the account.
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountAddress],
      });
      testAccount = await ethers.getSigner(accountAddress);
      DaiContract = new ethers.Contract(DaiContractAddr, abi, testAccount);
      awethContract = new ethers.Contract(awethContractAddr, abi, testAccount);
      aDaiContract = new ethers.Contract(aDaiContractAddr, abi, testAccount);
    });

    async function DisplayInitialAmounts() {
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Inital Dai Balance (User Account)  ", bal);
      bal = await aDaiContract.balanceOf(deployedContractAddress);
      console.log("Inital ADai Balance (Contract)     ", bal);
      console.log(
        "Initial Eth Balance (User Account) ",
        await testAccount.getBalance()
      );
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance (Contract)    ", bal);
      console.log("");
    }

    async function DisplayFinalAmounts() {
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Final Dai Balance (User Account)   ", bal);
      bal = await aDaiContract.balanceOf(deployedContractAddress);
      console.log("Final ADai Balance (Contract)      ", bal);
      console.log(
        "Final Eth Balance (User Account)   ",
        await testAccount.getBalance()
      );
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Final Aweth Balance (Contract)     ", bal);
    }

    //Function Tests
    it("Should deposit eth to aave", async function () {
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance", bal);
      console.log("Initial Owner Eth Balance", await testAccount.getBalance());

      var res = await hardhatAave.connect(testAccount).depositEth({
        value: ethers.utils.parseEther("20"),
      });
      //console.log(res);
      console.log("Updated Owner Eth Balance", await testAccount.getBalance());
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance", bal);
    });

    it("Should leverage eth ", async function () {
      //var amount = ethers.utils.parseEther("5");
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance", bal);
      console.log("Initial Owner Eth Balance", await testAccount.getBalance());
      var amount = ethers.utils.parseEther("10");
      var res = await hardhatAave.connect(testAccount).leverage(amount);
      //console.log(res);
      console.log("Updated Owner Eth Balance", await testAccount.getBalance());
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance", bal);
    });
    it("Should leverage eth again", async function () {
      //var amount = ethers.utils.parseEther("5");
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance", bal);
      console.log("Initial Owner Eth Balance", await testAccount.getBalance());
      var amount = ethers.utils.parseEther("3");
      var res = await hardhatAave.connect(testAccount).leverage(amount);
      //console.log(res);
      console.log("Updated Owner Eth Balance", await testAccount.getBalance());
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance", bal);
    });

    xit("Should withdraw eth from aave", async function () {
      const owner = testAccount;
      //awethContract = new ethers.Contract(awethContractAddr, abi, owner);
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance (Withdraw)", bal);
      console.log(
        "Initial Owner Eth Balance (Withdraw)",
        await owner.getBalance()
      );
      var res = await hardhatAave
        .connect(owner)
        .withdrawEth(ethers.utils.parseEther("1")); //Amount in wei
      //console.log(res);
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance (Withdraw)", bal);
      console.log(
        "Updated Owner Eth Balance (Withdraw)",
        await owner.getBalance()
      );
    });

    xit("Should deposit DAI to aave", async function () {
      var amount = ethers.utils.parseEther("300000");
      await DisplayInitialAmounts();

      let tx = await DaiContract.connect(testAccount).approve(
        deployedContractAddress,
        amount
      );
      var res = await hardhatAave
        .connect(testAccount)
        .depositToken(amount, tokenAddress);
      //console.log(res);
      await DisplayFinalAmounts();
    });

    xit("Should Borrow DAI from aave", async function () {
      var amount = ethers.utils.parseEther("10");
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old DAI Balance", bal);
      var res = await hardhatAave
        .connect(testAccount)
        .borrowToken(amount, tokenAddress);
      //console.log(res);
      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New DAI balance", bal);
    });

    xit("Should repay DAI to aave", async function () {
      var amount = ethers.utils.parseEther("10");
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old DAI Balance", bal);
      let tx = await DaiContract.connect(testAccount).approve(
        deployedContractAddress,
        amount
      );
      var res = await hardhatAave
        .connect(testAccount)
        .repayToken(amount, tokenAddress); //ethers.utils.parseEther("0.10")
      //console.log(res);
      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New DAI balance", bal);
    });

    xit("Should Deploy contract Again", async function () {
      Aave = await ethers.getContractFactory("AaveMiddleware");
      hardhatAave = await Aave.deploy();
      await hardhatAave.deployed();
      deployedContractAddress = hardhatAave.address;
      console.log(
        "Deployed Succefully Again!.. New Address-",
        deployedContractAddress
      );
    });

    xit("Should Withdraw DAI from aave", async function () {
      var amount = ethers.utils.parseEther("2000");
      await DisplayInitialAmounts();
      var res = await hardhatAave
        .connect(testAccount)
        .withdrawToken(amount, tokenAddress);
      //console.log(res);
      await DisplayFinalAmounts();
    });

    xit("Should borrow eth from aave", async function () {
      await DisplayInitialAmounts();
      var res = await hardhatAave
        .connect(testAccount)
        .borrowEth(ethers.utils.parseEther("1")); //Amount in wei
      //console.log(res);
      await DisplayFinalAmounts();
    });

    xit("Should repay eth to aave", async function () {
      await DisplayInitialAmounts();

      var res = await hardhatAave.connect(testAccount).repayEth({
        value: ethers.utils.parseEther("1"),
      });

      await DisplayFinalAmounts();
    });
  });
});
