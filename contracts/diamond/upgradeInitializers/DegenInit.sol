// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { DiamondInit } from "./DiamondInit.sol";
import { LibDegen } from "../libraries/LibDegen.sol";
import { Token } from "../../Token.sol";

contract DegenInit is DiamondInit {
	function init() public override {
		super.init();

		LibDegen.Storage storage s = LibDegen.store();

		s.creationPrice = 1;

		s.txFee = 10;
		s.launchFee = 20;

		Token blueprintToken = new Token();
		blueprintToken.emboss("", "", 1, address(this));
		s.blueprintToken = address(blueprintToken);
		s.tokenSupply = 1_000_000_000 ether;

		s.poolMCapThreshold = 25_000;
		s.poolBaseEther = 6000 ether;
	}
}
