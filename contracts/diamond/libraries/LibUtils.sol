// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IAggregatorV3 } from "../interfaces/IAggregatorV3.sol";
import { ChainlinkOracleV2 } from "../structs/ChainlinkOracle.sol";

library LibUtils {

	function calculatePercentage(uint16 fee, uint256 amount) internal pure returns (uint256) {
		return amount * fee / 1000;
	}

	function ethToUsd(uint256 usdcEthPrice, uint256 amountEth) internal pure returns (uint256) {
		uint256 ethAmount = amountEth;
		return ((ethAmount * usdcEthPrice) / (10**(8+18)) / (10**18));
	}

	function usdToEth(uint256 usdcEthPrice, uint256 usdAmount) internal pure returns (uint256) {
		return ((10**18 * (10**8)) / usdcEthPrice) * usdAmount;
	}

	function getOraclePrice(ChainlinkOracleV2 storage oracle) internal view returns (uint256) {
		(
				uint80 roundID,
				int signedPrice,
				/*uint startedAt*/,
				uint timeStamp,
				uint80 answeredInRound
		) = IAggregatorV3(oracle.priceFeed).latestRoundData();

		// check for Chainlink oracle deviancies, force a revert if any are present. Helps prevent a LUNA like issue
		require(signedPrice > 0, "Negative Oracle Price");
		require(timeStamp >= block.timestamp - oracle.heartBeat, "Stale pricefeed");

		if (oracle.l2Seq != address(0)) {
			(
				/*uint80 roundID*/,
				int256 answer,
				uint256 startedAt,
				/*uint256 updatedAt*/,
				/*uint80 answeredInRound*/
			) = IAggregatorV3(oracle.l2Seq).latestRoundData();

			require(
				answer == 0 && block.timestamp - startedAt >= 3600,
				"Sequencer is down"
			);
		}

		require(answeredInRound >= roundID, "round not complete");

		return uint256(signedPrice);
	}

}
