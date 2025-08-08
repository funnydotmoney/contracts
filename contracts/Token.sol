// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { ERC20 } from "solady/src/tokens/ERC20.sol";

contract Token is ERC20 {

	string private _name;
	string private _symbol;

	address internal diamond;
	bool internal launched = false;

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function emboss(string calldata n, string calldata s, uint256 supply, address d) external {
		require(totalSupply() == 0);
		diamond = d;

		_name = n;
		_symbol = s;

		_mint(msg.sender, supply);
	}

	function launch() external {
		require(msg.sender == diamond && launched == false);
		launched = true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
		if (!launched) {
			require(from == diamond || to == diamond, "transfer not allowed before launch");
		}
	}

}