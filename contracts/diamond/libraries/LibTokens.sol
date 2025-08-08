// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

library LibTokens {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.tokens.storage");

	struct TeamAllocation {
		uint16 percentage;
		uint8 beneficiary;
	}

	enum LpStrategy {
		Burn,
		Vest
	}

	struct Storage {
		mapping(address => TeamAllocation) _unused_teamAllocMap;
		mapping(address => address) creatorMap;
		mapping(address => LpStrategy) lpStrategyMap;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}
}
