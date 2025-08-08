// SPDX-License-Identifier: UNKNOWN
pragma solidity >=0.5.0;

import { IUniV2Router } from "../diamond/interfaces/IUniV2Router.sol";
import { IUniV2Factory } from "../diamond/interfaces/IUniV2Factory.sol";

import { Token } from "../Token.sol";

interface ITraderJoeV1Router {
	function factory() external pure returns (address);
	function WAVAX() external pure returns (address);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function addLiquidityAVAX(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountAVAXMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountAVAX,
			uint256 liquidity
		);

	function swapExactAVAXForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForAVAX(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

contract TraderJoeV1Router is IUniV2Router {

	ITraderJoeV1Router private _router;

	constructor(address router) {
		_router = ITraderJoeV1Router(router);
	}

	function WETH() external view override returns (address) {
		return _router.WAVAX();
	}

	function factory() external view override returns (IUniV2Factory) {
		return IUniV2Factory(_router.factory());
	}

	function getAmountOut(
		uint amountIn,
		address tokenIn,
		address tokenOut
	) external view override returns (uint) {
		address[] memory path = new address[](2);
		path[0] = tokenIn;
		path[1] = tokenOut;
		return _router.getAmountsOut(amountIn, path)[1];
	}

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable override returns (uint[] memory) {
		return _router.swapExactAVAXForTokens{ value: msg.value }(amountOutMin, path, to, deadline);
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
		return _router.swapExactTokensForAVAX(amountIn, amountOutMin, path, to, deadline);
	}
}