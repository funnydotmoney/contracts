// SPDX-License-Identifier: UNKNOWN
pragma solidity >=0.5.0;

import { IUniV2Router } from "../diamond/interfaces/IUniV2Router.sol";
import { IUniV2Factory } from "../diamond/interfaces/IUniV2Factory.sol";

import { Token } from "../Token.sol";

interface IPancakeRouterV2 is IUniV2Router {
	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

contract PancakeV2Router is IUniV2Router {

	IPancakeRouterV2 private _router;

	constructor(address router) {
		_router = IPancakeRouterV2(router);
	}

	function WETH() external view override returns (address) {
		return _router.WETH();
	}

	function factory() external view override returns (IUniV2Factory) {
		return IUniV2Factory(_router.factory());
	}

	function getAmountOut(
		uint amountIn,
		address tokenIn,
		address tokenOut
	) external view override returns (uint amount) {
		address[] memory path = new address[](2);
		path[0] = tokenIn;
		path[1] = tokenOut;
		uint[] memory amounts = _router.getAmountsOut(amountIn, path);
		return amounts[1];
	}

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable override returns (uint[] memory amounts) {
		return _router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
	}

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external override returns (uint[] memory amounts) {
		Token(path[0]).transferFrom(msg.sender, address(this), amountIn);
		Token(path[0]).approve(address(_router), amountIn);
		return _router.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
	}
}