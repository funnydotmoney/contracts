// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibUtils } from "./LibUtils.sol";
import { LibDiamond } from "./LibDiamond.sol";

import { IUniV2Router } from "../interfaces/IUniV2Router.sol";
import { ChainlinkOracleV2, ChainlinkOracle } from "../structs/ChainlinkOracle.sol";

library LibDegen {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.degen.storage");

	event FeeTaken(address user, uint256 amount);

	struct Storage {
		uint256 proceeds;

		uint32 creationPrice;

		uint16 txFee;
		uint16 launchFee;

		address blueprintToken;
		uint256 tokenSupply;

		IUniV2Router router;
		ChainlinkOracle _unused_usdcOracle;

		uint256 poolBaseEther;
		uint32 poolMCapThreshold;

		address foundation;

		ChainlinkOracleV2 usdcOracle;

		address llamaVesting;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}

	function gatherProceeds(uint256 amount, address user) internal {
		LibDegen.store().proceeds += amount;
		emit FeeTaken(user, amount);
	}

	function calculateTxFee(uint256 eth) internal view returns (uint256) {
		return LibUtils.calculatePercentage(store().txFee, eth);
	}

	function deductTxFee(uint256 eth, address user) internal returns (uint256) {
		uint256 fee = calculateTxFee(eth);
		gatherProceeds(fee, user);
		return eth - fee;
	}
}
