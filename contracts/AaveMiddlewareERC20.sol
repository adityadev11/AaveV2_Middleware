//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";

/// @title A contract for managing Aave positions. Acts as a middleware
/// @author Aditya Choudhary
/// @notice Does 4 basic operations of Deposit, Withdraw, Borrow and Repay for both ERC20 and ETH.
///@dev Maintains User's Balance on contract to make sure withdrawal is not made for amount greated than deposited. 

contract AaveMiddleware{

    mapping (address=>uint) ownerBalance;       //State Varaible to store User Balance on our Contract

    modifier hasSufficientBalance(address _owner,uint _amount){
        require(ownerBalance[_owner]>=_amount);
        _;
    }

    function getLendingPoolAddress() internal view returns(address){
        address  _LendingPoolAddressProviderAddr=0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5; //Mainnet
        ILendingPoolAddressesProvider LendingAddProvider = ILendingPoolAddressesProvider(_LendingPoolAddressProviderAddr);
        address LendingPoolAddress=LendingAddProvider.getLendingPool();
        return LendingPoolAddress;
    }

    function depositToken(uint _amount) external {
        address DaiAddress="0x6B175474E89094C44Da98b954EedeAC495271d0F"; //DAI on Ethereum. Re-initiated in all functions to avoid gas cost associated with state varaibles.
        IERC20 erc20Token=IERC20(DaiAddress);    
        address _LendingPoolAddress=getLendingPoolAddress();
        ILendingPool LendingPool=ILendingPool(_LendingPoolAddress);
        ecr20Token.transferFrom(msg.sender,address(this),_amount);      //Assuming the User has already Approved this amount using approve() function
        ownerBalance[msg.sender]+=_amount;
        //erc20Token.deposit{value: amt}();
        erc20Token.approve(_LendingPoolAddress,_amount);
        LendingPool.deposit(DaiAddress,_amount,address(this),0); //The referral program is currently inactive and you can pass 0 as thereferralCode.
    }

    function withdrawToken(uint _amount) external hasSufficientBalance{
        address DaiAddress="0x6B175474E89094C44Da98b954EedeAC495271d0F"; //DAI on Ethereum
        IERC20 erc20Token=IERC20(DaiAddress);    
        address _LendingPoolAddress=getLendingPoolAddress();
        ILendingPool LendingPool=ILendingPool(_LendingPoolAddress);
        LendingPool.withdraw(DaiAddress,_amount,msg.sender);     //Amount Withdrawn to the user
        ownerBalance[msg.sender]-=_amount;
    }
    function borrowToken(uint _amount) external hasSufficientBalance{
        address DaiAddress="0x6B175474E89094C44Da98b954EedeAC495271d0F"; //DAI on Ethereum
        IERC20 erc20Token=IERC20(DaiAddress);    
        address _LendingPoolAddress=getLendingPoolAddress();
        ILendingPool LendingPool=ILendingPool(_LendingPoolAddress);
        LendingPool.borrow(DaiAddress,_amount,1,0,address(this));     //Amount borrowed. Will be received by the contract
        erc20Token.transfer(msg.sender, _amount);                       //Transferring the borrowed funds to the user
        ownerBalance[msg.sender]-=_amount;                              //Assuming For now that the Collateralization Ratio is 1:1
    }
    function repayToken(uint _amount) external {
        address DaiAddress="0x6B175474E89094C44Da98b954EedeAC495271d0F"; //DAI on Ethereum
        IERC20 erc20Token=IERC20(DaiAddress);    
        address _LendingPoolAddress=getLendingPoolAddress();
        ILendingPool LendingPool=ILendingPool(_LendingPoolAddress);
        ecr20Token.transferFrom(msg.sender,address(this),_amount);      //Assuming the User has already Approved this amount using approve() function
        erc20Token.approve(_LendingPoolAddress,_amount);
        LendingPool.repay(DaiAddress,_amount,1,address(this));     //Amount borrowed
        ownerBalance[msg.sender]+=_amount;
        
    }

}