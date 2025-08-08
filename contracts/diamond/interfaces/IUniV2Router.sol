// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IUniV2Factory } from "./IUniV2Factory.sol";

interface IUniV2Router {
	function WETH() external view returns (address);

	function factory() external view returns (IUniV2Factory);

	function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount);

	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
	 external payable returns (uint[] memory amounts);

	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);
}