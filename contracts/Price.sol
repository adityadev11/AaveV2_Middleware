// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  /**
   * Network: Mainnet
   * Aggregator: Dai/Eth
   * Address: 0x773616E4d11A78F511299002da57A0a94577F1f4
   */
  constructor() {
    priceFeed = AggregatorV3Interface(
      0x773616E4d11A78F511299002da57A0a94577F1f4
    );
  }

  /**
   * Returns the latest price
   */
  function getLatestPrice() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }
}
