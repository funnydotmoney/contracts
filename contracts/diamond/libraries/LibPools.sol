// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

library LibPools {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.pools.storage");

	struct Pool {
		uint256 fakeEth;
		uint256 ethReserve;
		uint256 tokenReserve;

		address token;
		address pair;

		uint16 sellPenalty;
		bool locked;
	}

	struct Storage {
		mapping(address => Pool) poolMap;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}
}
