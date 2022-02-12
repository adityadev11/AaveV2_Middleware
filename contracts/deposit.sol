//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";

contract AaveMiddleware{

    function getLendingPoolAddress() internal returns(address){
        string  _LendingPoolAddressProviderAddr="0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; //Mainnet
        ILendingPoolAddressesProvider LendingAddProvider = ILendingPoolAddressesProvider(_LendingPoolAddressProviderAddr);
        address LendingPoolAddress=LendingAddProvider.getLendingPool();
        return LendingPoolAddress;
    }

    function depositToken(uint _amount) payable{
        address DaiAddress="0x6B175474E89094C44Da98b954EedeAC495271d0F"; //DAI on Etherum
        IERC20 erc20Token=IERC20(DaiAddress);    
        address _LendingPoolAddress=getLendingPoolAddress();
        ILendingPool LendingPool=ILendingPool(_LendingPoolAddress);
        erc20Token.approve(_LendingPoolAddress,_amount);
        LendingPool.deposit(DaiAddress,_amount,address(this),0); //The referral program is currently inactive and you can pass 0 as thereferralCode.
    }
}