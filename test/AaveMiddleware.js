const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Aave Middleware", function () {
  let Aave;
  let hardhatAave;
  let deployedContractAddress;

  // beforeEach(async () => {
  // Aave = await ethers.getContractFactory("AaveMiddleware");
  // hardhatAave = await Aave.deploy();
  // //console.log(hardhatAave.signer);
  // await hardhatAave.deployed();
  // //console.log(hardhatAave.address);
  // deployedContractAddress = hardhatAave.address;
  // });
  it("Should Deploy contract", async function () {
    Aave = await ethers.getContractFactory("AaveMiddleware");
    hardhatAave = await Aave.deploy();
    //console.log(hardhatAave.signer);
    await hardhatAave.deployed();
    //console.log(hardhatAave.address);
    deployedContractAddress = hardhatAave.address;
    console.log("Deployed Succefully!.. Address-", deployedContractAddress);
  });

  it("Should return Lending Pool Address", async function () {
    const result = await hardhatAave.getLendingPoolAddress();
    //console.log(result);
    expect(result).to.be.a("string");
    expect(result).to.equal("0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9");
  });
  describe("Eth Functions", async function () {
    const awethContractAddr = "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e"; //mainnet
    var awethContract;
    const abi = [
      "function balanceOf(address) view returns (uint)",

      "function approve(address to, uint amount)", //correct?
    ];

    const DaiContractAddr = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //mainnet
    const accountAddress = "0x535De4eB0f28eFc0332C5702F8002bBd33115270"; //Impersonating account
    var DaiContract;
    var testAccount;

    beforeEach(async () => {
      // impersonating the account.
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountAddress],
      });
      testAccount = await ethers.getSigner(accountAddress);
      DaiContract = new ethers.Contract(DaiContractAddr, abi, testAccount);
    });

    it("Should deposit eth to aave", async function () {
      console.log("Deployed contract address", deployedContractAddress);
      const owner = testAccount;
      console.log(owner.getAddress());
      awethContract = new ethers.Contract(awethContractAddr, abi, owner);
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance", bal);
      console.log("Initial Owner Eth Balance", await owner.getBalance());
      //var res = await hardhatAave.depositEth();
      var res = await hardhatAave.connect(owner).depositEth({
        value: ethers.utils.parseEther("20"),
      });
      //expect(res.receipt.status).to.equal(true);
      //console.log(res);
      console.log("Updated Owner Eth Balance", await owner.getBalance());
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance", bal);
    });

    it("Should withdraw eth from aave", async function () {
      console.log("Deployed contract address", deployedContractAddress);
      const owner = testAccount;
      awethContract = new ethers.Contract(awethContractAddr, abi, owner);
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
    it("Should Borrow DAI from aave", async function () {
      var amount = 1000000000;
      console.log(
        "Deployed contract address(Borrow Dai)",
        deployedContractAddress
      );
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old DAI Balance", bal);
      var res = await hardhatAave.connect(testAccount).borrowToken(amount);
      //expect(res.receipt.status).to.equal(true);
      //console.log(res);
      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New DAI balance", bal);
    });
    it("Should repay DAI to aave", async function () {
      console.log(
        "Deployed contract address(Repay Dai)",
        deployedContractAddress
      );
      var amount = 1000000000;
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old DAI Balance", bal);
      let tx = await DaiContract.connect(testAccount).approve(
        deployedContractAddress,
        amount
      );
      var res = await hardhatAave.connect(testAccount).repayToken(amount); //ethers.utils.parseEther("0.10")
      //expect(res.receipt.status).to.equal(true);
      //console.log(res);
      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New DAI balance", bal);
    });

    it("Should deposit DAI to aave", async function () {
      var amount = ethers.utils.parseEther("30000");
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old Dai Balance", bal);

      //const walletBalancePrior = await ethers.provider.getBalance(testAccount); //DaiContract.getBalance()?
      //console.log(walletBalancePrior);
      let tx = await DaiContract.connect(testAccount).approve(
        deployedContractAddress,
        amount
      );
      //var res = await hardhatAave.depositEth();
      var res = await hardhatAave.connect(testAccount).depositToken(amount); //ethers.utils.parseEther("0.10")
      //expect(res.receipt.status).to.equal(true);
      //console.log(res);

      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New Dai Balance", bal);
    });

    it("Should Withdraw DAI from aave", async function () {
      var amount = 1000000000;
      var bal = await DaiContract.balanceOf(accountAddress);
      console.log("Old Dai Balance", bal);
      var res = await hardhatAave.connect(testAccount).withdrawToken(amount); //ethers.utils.parseEther("0.10")
      //console.log(res);
      bal = await DaiContract.balanceOf(accountAddress);
      console.log("New Dai Balance", bal);
    });

    it("Should borrow eth from aave", async function () {
      const owner = testAccount;
      var bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Inital Aweth Balance(Borrow)", bal);

      console.log(
        "Initial Owner Eth Balance (Borrow)",
        await owner.getBalance()
      );

      var res = await hardhatAave.borrowEth(ethers.utils.parseEther("1")); //Amount in wei
      console.log(res);
      bal = await awethContract.balanceOf(deployedContractAddress);
      console.log("Updated Aweth Balance (Withdraw)", bal);
      console.log(
        "Updated Owner Eth Balance (Withdraw)",
        await owner.getBalance()
      );
    });

    // xit("Should repay eth to aave", async function () {
    //   const [owner] = await ethers.getSigners();
    //   var res = await hardhatAave.connect(owner).repayEth({
    //     value: ethers.utils.parseEther("1"),
    //   });
    //   console.log(res);
    // });
  });
});
