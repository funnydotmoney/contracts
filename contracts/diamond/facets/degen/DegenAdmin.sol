// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibPools } from "../../libraries/LibPools.sol";
import { IUniV2Router } from "../../interfaces/IUniV2Router.sol";
import { ChainlinkOracleV2 } from "../../structs/ChainlinkOracle.sol";
import { Ownable } from "../../Ownable.sol";

contract DegenAdmin is Ownable {

	//////////////////////////////////// VIEWS ////////////////////////////////////

	function proceeds() external view returns (uint256) {
		return LibDegen.store().proceeds;
	}

	function state() external pure returns (LibDegen.Storage memory) {
		return LibDegen.store();
	}

	////////////////////////////////// FUNCTIONS //////////////////////////////////

	function purge(address token) external onlyOwner {
		// TODO
	}

	function reap() external {
		uint256 eth = LibDegen.store().proceeds;
		LibDegen.store().proceeds = 0;
		(bool sent,) = owner().call{ value: eth }("");
		require(sent);
	}

	/////////////////////////////////// SETTERS ///////////////////////////////////

	function setCreationPrice(uint32 price) external onlyOwner {
		LibDegen.store().creationPrice = price;
	}

	function setTxFee(uint16 fee) external onlyOwner {
		LibDegen.store().txFee = fee;
	}

	function setLaunchFee(uint16 fee) external onlyOwner {
		LibDegen.store().launchFee = fee;
	}

	function setVesting(address vesting) external onlyOwner {
		LibDegen.store().llamaVesting = vesting;
	}

	function setFoundation(address foundation) external onlyOwner {
		LibDegen.store().foundation = foundation;
	}

	function setRouter(address router) external onlyOwner {
		LibDegen.store().router = IUniV2Router(router);
	}

	function setUsdcOracle(ChainlinkOracleV2 calldata oracle) external onlyOwner {
		LibDegen.store().usdcOracle = oracle;
	}

	//////////////////////////////// POOL SETTERS /////////////////////////////////

	function setPoolMCapThreshold(uint32 threshold) external onlyOwner {
		LibDegen.store().poolMCapThreshold = threshold;
	}

	function setPoolBaseEther(uint256 baseEther) external onlyOwner {
		LibDegen.store().poolBaseEther = baseEther;
	}

}
