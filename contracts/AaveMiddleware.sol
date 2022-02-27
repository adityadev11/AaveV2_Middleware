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
import "./Price.sol";

/// @title A contract for managing Aave positions. Acts as a middleware
/// @author Aditya Choudhary
/// @notice Does 4 basic operations of Deposit, Withdraw, Borrow and Repay for both ERC20 and ETH.
///@dev Maintains User's Balance on contract to make sure withdrawal is not made for amount greated than deposited.

contract AaveMiddleware {
  using SafeERC20 for IERC20;

  address wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04; //Mainnet
  address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Weth on Ethereum
  mapping(address => uint256) UserDeposit;

  modifier hasSuppliedEth(address _userAddr) {
    require(
      UserDeposit[_userAddr] > 0,
      "Error! User hasn't made a Deposit yet"
    );
    _;
  }

  function getLendingPoolAddress() public view returns (address) {
    return
      ILendingPoolAddressesProvider(
        address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5)
      ).getLendingPool(); //Mainnet
  }

  function depositToken(uint256 _amount, address _tokenAddr) external {
    IERC20 erc20Token = IERC20(_tokenAddr);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);

    erc20Token.safeTransferFrom(msg.sender, address(this), _amount); //Assuming the User has already Approved this amount using approve() function

    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.deposit(_tokenAddr, _amount, address(this), 0); //The referral program is currently inactive and you can pass 0 as thereferralCode.
  }

  function withdrawToken(uint256 _amount, address _tokenAddr) external {
    ILendingPool LendingPool = ILendingPool(address(getLendingPoolAddress()));
    LendingPool.withdraw(_tokenAddr, _amount, msg.sender); //Amount Withdrawn to the user
  }

  function borrowToken(uint256 _amount, address _tokenAddr) external {
    IERC20 erc20Token = IERC20(_tokenAddr);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    LendingPool.borrow(_tokenAddr, _amount, 2, 0, address(this)); //Amount borrowed. Will be received by the contract
    erc20Token.safeTransfer(msg.sender, _amount); //Transferring the borrowed funds to the user
  }

  function repayToken(uint256 _amount, address _tokenAddr) external {
    IERC20 erc20Token = IERC20(_tokenAddr);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    erc20Token.safeTransferFrom(msg.sender, address(this), _amount); //Assuming the User has already Approved this amount using approve() function
    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.repay(_tokenAddr, _amount, 2, address(this)); //Amount borrowed
  }

  function depositEth() external payable {
    address _LendingPoolAddress = getLendingPoolAddress();
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    wethGateway.depositETH{ value: msg.value }(
      _LendingPoolAddress,
      address(this),
      0
    );
    UserDeposit[msg.sender] += msg.value;
  }

  function withdrawEth(uint256 _amount) external {
    address _LendingPoolAddress = getLendingPoolAddress();
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    address aWethAddress = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e; //AWeth contract on Mainnet
    IERC20 erc20Token = IERC20(aWethAddress);
    erc20Token.safeApprove(wethGatewayAddress, _amount);
    wethGateway.withdrawETH(_LendingPoolAddress, _amount, msg.sender);
  }

  function borrowEth(uint256 _amount) external payable {
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
    Iweth weth = Iweth(wethAddress);
    weth.deposit{ value: msg.value }();

    IERC20 erc20Token = IERC20(wethAddress);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.repay(wethAddress, _amount, 1, address(this)); //Amount borrowed
  }

  function leverageEth(uint256 _amount)
    external
    payable
    hasSuppliedEth(msg.sender)
  {
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);
    (
      uint256 collateral,
      uint256 debt,
      uint256 maxBorrow,
      uint256 liqThreshold,
      uint256 ltv,
      uint256 hFactor
    ) = LendingPool.getUserAccountData(address(this));

    require(
      _amount <= maxBorrow,
      "Requested Amount is more than borrow allowance"
    );

    console.log("Borrowing..");

    LendingPool.borrow(wethAddress, _amount, 2, 0, address(this)); //Amount borrowed. Will be received by the contract

    Iweth weth = Iweth(wethAddress);
    weth.withdraw(_amount);

    console.log(
      "Successfully Borrowed! Contract balance-",
      address(this).balance
    );
    console.log("Depositing..");
    IWETHGateway wethGateway = IWETHGateway(wethGatewayAddress);
    wethGateway.depositETH{ value: address(this).balance }(
      _LendingPoolAddress,
      address(this),
      0
    );
    console.log("Successfully Deposited!");
  }

  function leverageToken(uint256 _amount, address _tokenAddr) external {
    PriceConsumerV3 x = new PriceConsumerV3();
    uint256 price = uint256(x.getLatestPrice());
    console.log(
      "Amount requested in Eth",
      (_amount * price) / 1000000000000000000
    );

    IERC20 erc20Token = IERC20(_tokenAddr);
    address _LendingPoolAddress = getLendingPoolAddress();
    ILendingPool LendingPool = ILendingPool(_LendingPoolAddress);

    (
      uint256 collateral,
      uint256 debt,
      uint256 maxBorrow,
      uint256 liqThreshold,
      uint256 ltv,
      uint256 hFactor
    ) = LendingPool.getUserAccountData(address(this));
    require(
      ((_amount * price) / 1000000000000000000) <= maxBorrow,
      "Error! Amount greater than allowed to borrow"
    );

    LendingPool.borrow(_tokenAddr, _amount, 2, 0, address(this)); //Amount borrowed. Will be received by the contract

    erc20Token.safeApprove(_LendingPoolAddress, _amount);
    LendingPool.deposit(_tokenAddr, _amount, address(this), 0);
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
