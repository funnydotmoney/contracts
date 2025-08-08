// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IUniV2Router } from "../diamond/interfaces/IUniV2Router.sol";
import { IUniV2Factory } from "../diamond/interfaces/IUniV2Factory.sol";

import { Token } from "../Token.sol";

interface ISolidlyV2Factory {
	function pairFor(address token0, address token1, bool stable) external view returns (address payable);
	function createPair(address token0, address token1, bool stable) external returns (address);
}

interface ISolidlyV2Router {
	function wETH() external view returns (address);

	function factory() external view returns (ISolidlyV2Factory);

	struct route {
		address from;
		address to;
		bool stable;
	}

	function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

	function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
	 external payable returns (uint[] memory amounts);

	function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external returns (uint[] memory amounts);
}

contract SolidlyV2Factory is IUniV2Factory {
	ISolidlyV2Factory internal factory;

	constructor(address _factory) {
		factory = ISolidlyV2Factory(_factory);
	}

	function getPair(
		address tokenA,
		address tokenB
	) external view override returns (address pair) {
		return factory.pairFor(tokenA, tokenB, false);
	}

	function createPair(
		address token0,
		address token1
	) external override returns (address) {
		return factory.createPair(token0, token1, false);
	}
}

contract SolidlyV2Router is IUniV2Router {

	ISolidlyV2Router internal _router;
	IUniV2Factory internal _factory;

	constructor(address router) {
		_router = ISolidlyV2Router(router);
		_factory = new SolidlyV2Factory(address(_router.factory()));
	}

	function routify(address[] memory path) internal pure returns (ISolidlyV2Router.route[] memory) {
		ISolidlyV2Router.route[] memory route = new ISolidlyV2Router.route[](1);
		route[0] = ISolidlyV2Router.route(path[0], path[1], false);
		return route;
	}

	function WETH() external view virtual override returns (address) {
		return _router.wETH();
	}

	function factory() external view virtual override returns (IUniV2Factory) {
		return _factory;
	}

	function getAmountOut(
		uint amountIn,
		address tokenIn,
		address tokenOut
	) external view override returns (uint) {
		(uint amount,) = _router.getAmountOut(amountIn, tokenIn, tokenOut);
		return amount;
	}

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable override returns (uint[] memory) {
		return _router.swapExactETHForTokens{ value: msg.value }(amountOutMin, routify(path), to, deadline);
	}

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external override returns (uint[] memory) {
		Token(path[0]).transferFrom(msg.sender, address(this), amountIn);
		Token(path[0]).approve(address(_router), amountIn);
		return _router.swapExactTokensForETH(amountIn, amountOutMin, routify(path), to, deadline);
	}
}