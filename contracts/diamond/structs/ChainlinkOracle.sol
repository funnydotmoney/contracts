// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

struct ChainlinkOracle {
	address priceFeed;
	uint256 heartbeat;
}

struct ChainlinkOracleV2 {
	address priceFeed;
	address l2Seq;
	uint256 heartBeat;
}