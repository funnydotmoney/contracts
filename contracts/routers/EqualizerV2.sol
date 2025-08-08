// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { SolidlyV2Router, ISolidlyV2Factory } from "./SolidlyV2.sol";
import { IUniV2Factory } from "../diamond/interfaces/IUniV2Factory.sol";

interface IEqualizerV2Factory is ISolidlyV2Factory {
	function getPair(address token0, address token1, bool stable) external view returns (address payable);
}

contract EqualizerV2Factory is IUniV2Factory {
	IEqualizerV2Factory private factory;

	constructor(address _factory) {
		factory = IEqualizerV2Factory(_factory);
	}

	function getPair(
		address tokenA,
		address tokenB
	) external view override returns (address pair) {
		return factory.getPair(tokenA, tokenB, false);
	}

	function createPair(
		address token0,
		address token1
	) external override returns (address) {
		return factory.createPair(token0, token1, false);
	}
}

interface IEqualizerV2Router {
	function weth() external view returns (address);
}

contract EqualizerV2Router is SolidlyV2Router {

	constructor(address router) SolidlyV2Router(router) {
		_factory = new EqualizerV2Factory(address(_router.factory()));
	}

	function WETH() external view override returns (address) {
		return IEqualizerV2Router(address(_router)).weth();
	}

}