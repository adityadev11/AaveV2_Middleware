//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILendingPool } from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import { IWETHGateway } from "@aave/protocol-v2/contracts/misc/interfaces/IWETHGateway.sol";
import { IStableDebtToken } from "@aave/protocol-v2/contracts/interfaces/IStableDebtToken.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Iweth.sol";

/// @title A contract for managing Aave positions. Acts as a middleware
/// @author Aditya Choudhary
/// @notice Does 4 basic operations of Deposit, Withdraw, Borrow and Repay for both ERC20 and ETH.
///@dev Maintains User's Balance on contract to make sure withdrawal is not made for amount greated than deposited.

contract AaveMiddleware {
  using SafeERC20 for IERC20;

  function getLendingPoolAddress() public view returns (address) {
    return
      ILendingPoolAddressesProvider(
        address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5)
      ).getLendingPool(); //Mainnet
  }

  function depositToken(uint256 _amount, address _tokenAddr) external {
    address TokenAddress = _tokenAddr; //Token Address on Mainnet. Re-initiated in all functions to avoid gas cost associated with state varaibles.
    IERC20 erc20Token = IERC20(TokenAddress);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);

    erc20Token.safeTransferFrom(msg.sender, address(this), _amount); //Assuming the User has already Approved this amount using approve() function

    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.deposit(TokenAddress, _amount, address(this), 0); //The referral program is currently inactive and you can pass 0 as thereferralCode.
    LendingPool.setUserUseReserveAsCollateral(_tokenAddr, true); //Not needed
  }

  function withdrawToken(uint256 _amount, address _tokenAddr) external {
    address TokenAddress = _tokenAddr; //Token Address on Mainnet
    ILendingPool LendingPool = ILendingPool(address(getLendingPoolAddress()));
    LendingPool.withdraw(TokenAddress, _amount, msg.sender); //Amount Withdrawn to the user
  }

  function borrowToken(uint256 _amount, address _tokenAddr) external {
    address TokenAddress = _tokenAddr; //Token Address on Mainnet
    IERC20 erc20Token = IERC20(TokenAddress);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    LendingPool.borrow(TokenAddress, _amount, 2, 0, address(this)); //Amount borrowed. Will be received by the contract
    erc20Token.safeTransfer(msg.sender, _amount); //Transferring the borrowed funds to the user
  }

  function repayToken(uint256 _amount, address _tokenAddr) external {
    address TokenAddress = _tokenAddr; //Token Address on Mainnet
    IERC20 erc20Token = IERC20(TokenAddress);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    erc20Token.safeTransferFrom(msg.sender, address(this), _amount); //Assuming the User has already Approved this amount using approve() function
    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.repay(TokenAddress, _amount, 1, address(this)); //Amount borrowed
  }

  function depositEth() external payable {
    address wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04; //Mainnet
    address _LendingPoolAddress = getLendingPoolAddress();
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    wethGateway.depositETH{ value: msg.value }(
      _LendingPoolAddress,
      address(this),
      0
    );
  }

  function withdrawEth(uint256 _amount) external {
    address wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04; //Mainnet
    address _LendingPoolAddress = getLendingPoolAddress();
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    address aWethAddress = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e; //AWeth contract on Mainnet
    IERC20 erc20Token = IERC20(aWethAddress);
    erc20Token.safeApprove(wethGatewayAddress, _amount);
    wethGateway.withdrawETH(_LendingPoolAddress, _amount, msg.sender);
  }

  function borrowEth(uint256 _amount) external payable {
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Weth on Ethereum
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    LendingPool.borrow(wethAddress, _amount, 1, 0, address(this)); //Amount borrowed. Will be received by the contract

    Iweth weth = Iweth(wethAddress);
    weth.withdraw(_amount);
    bool sent = payable(msg.sender).send(address(this).balance);
    console.log(sent);
  }

  function repayEth() external payable {
    uint256 _amount = msg.value;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Weth on Ethereum
    Iweth weth = Iweth(wethAddress);
    weth.deposit{ value: msg.value }();

    IERC20 erc20Token = IERC20(wethAddress);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.repay(wethAddress, _amount, 1, address(this)); //Amount borrowed
  }

  function leverage() external payable {
    console.log("Deposit");
    address wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04; //Mainnet
    address _LendingPoolAddress = getLendingPoolAddress();
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    wethGateway.depositETH{ value: msg.value }(
      _LendingPoolAddress,
      address(this),
      0
    );

    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);

    (
      uint256 a1,
      uint256 a2,
      uint256 a3,
      uint256 a4,
      uint256 a5,
      uint256 a6
    ) = LendingPool.getUserAccountData(address(this));
    console.log("totalCollateralETH         ", a1);
    console.log("totalDebtETH               ", a2);
    console.log("availableBorrowsETH        ", a3);
    console.log("currentLiquidationThreshold", a4);
    console.log("ltv                        ", a5);
    console.log("healthFactor               ", a6);
    uint256 count = 1;

    while (a3 > 0) {
      console.log("Borrow", count);
      address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Weth on Ethereum

      LendingPool.borrow(wethAddress, a3 + 10000000, 2, 0, address(this)); //Amount borrowed. Will be received by the contract

      Iweth weth = Iweth(wethAddress);
      weth.withdraw(a3);
      //console.log("Balance", address(this).balance);
      //bool sent = payable(msg.sender).send(address(this).balance);
      //console.log(sent);
      (a1, a2, a3, a4, a5, a6) = LendingPool.getUserAccountData(address(this));
      console.log("totalCollateralETH         ", a1);
      console.log("totalDebtETH               ", a2);
      console.log("availableBorrowsETH        ", a3);
      console.log("currentLiquidationThreshold", a4);
      console.log("ltv                        ", a5);
      console.log("healthFactor               ", a6);

      console.log("Deposit", count);
      wethGateway.depositETH{ value: (address(this).balance) }(
        _LendingPoolAddress,
        address(this),
        0
      );
      (a1, a2, a3, a4, a5, a6) = LendingPool.getUserAccountData(address(this));
      console.log("totalCollateralETH         ", a1);
      console.log("totalDebtETH               ", a2);
      console.log("availableBorrowsETH        ", a3);
      console.log("currentLiquidationThreshold", a4);
      console.log("ltv                        ", a5);
      console.log("healthFactor               ", a6);

      count++;
      console.log("Balance", address(this).balance);
    }
  }

  event ValueReceived(address user, uint256 amount); //Event for Receive

  receive() external payable {
    emit ValueReceived(msg.sender, msg.value);
  }

  event Log(string func, address sender, uint256 value, bytes data); //Event for Fallback

  fallback() external payable {
    emit Log("fallback", msg.sender, msg.value, msg.data);
  }
}
